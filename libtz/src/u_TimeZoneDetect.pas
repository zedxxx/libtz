unit u_TimeZoneDetect;

interface

{$DEFINE USE_POINT_DETECT_LIB}
{$DEFINE SMALL_POINT}

uses
  t_TzTypes;

type
  TTimeZoneDetect = class
  private
    FPrevTzIndex: Integer;
    FPrevTzPolygonIndex: Integer;

    FLikelyZones: array of Integer;
    FLikelyZonesCount: Integer;

    FTestPoint: TTimeZonePoint;

    function IsTestPointInTimeZone(const ATimeZone: PTimeZoneInfo): Boolean;
    procedure FindLikelyZones(const ANode: PTimeZoneNode);
  public
    function LonLatToTzName(const ALon, ALat: Double): PAnsiChar;
    {$IFDEF DEBUG}
    function LonLatToTzNameOld(const ALon, ALat: Double): PAnsiChar;
    {$ENDIF}

    function GetTimeZoneInfo(const ATzName: PAnsiChar): PTimeZoneInfo;
  public
    constructor Create;
  end;

implementation

uses
  c_TzConst,
  u_TimeZoneTool;

{$IFDEF USE_POINT_DETECT_LIB}

{$LINK '.\obj\point_detect.o'}

function IsPointInRect(const APoint: TTimeZonePoint;
  const ARect: PTimeZoneBound): Boolean; cdecl; external name {$IFNDEF FPC}'_' + {$ENDIF}
  {$IFDEF SMALL_POINT}'is_point_in_rect_16'{$ELSE}'is_point_in_rect_32'{$ENDIF};

function IsPointInPolygon(const APoint: TTimeZonePoint; const ACount: Integer;
  const APolyPoints: PTimeZonePoint): Boolean; cdecl; external name {$IFNDEF FPC}'_' + {$ENDIF}
  {$IFDEF SMALL_POINT}'is_point_in_poly_16'{$ELSE}'is_point_in_poly_32'{$ENDIF};

{$ELSE}

function IsPointInRect(
  const APoint: TTimeZonePoint;
  const ARect: PTimeZoneBound
): Boolean;
begin
  Result := (
    (APoint.X <= ARect.Max.X) and
    (APoint.X >= ARect.Min.X) and
    (APoint.Y <= ARect.Max.Y) and
    (APoint.Y >= ARect.Min.Y)
  );
end;

function IsPointInPolygon(
  const APoint: TTimeZonePoint;
  const APolygonPointsCount: Integer;
  const APolygonFirstPoint: PTimeZonePoint
): Boolean;
var
  I: Integer;
  Y: Integer;
  P1, P2: PTimeZonePoint;
begin
  {$IFDEF DEBUG}
  Assert(APolygonPointsCount >= 3);
  {$ENDIF}
  Result := False;
  P1 := APolygonFirstPoint;
  P2 := P1;
  Inc(P2);
  Y := APoint.Y;
  for I := 1 to APolygonPointsCount - 1 do begin
    if (((P2.Y <= Y) and (Y < P1.Y)) or ((P1.Y <= Y) and (Y < P2.Y))) then begin
      if APoint.X > P2.X + (P1.X - P2.X) * (Y - P2.Y) / (P1.Y - P2.Y) then begin
        Result := not Result;
      end;
    end;
    P1 := P2;
    Inc(P2);
  end;
end;
{$ENDIF}

constructor TTimeZoneDetect.Create;
begin
  inherited Create;

  FPrevTzIndex := -1;
  FPrevTzPolygonIndex := -1;

  FLikelyZonesCount := 0;
  SetLength(FLikelyZones, Length(cTzNodeZoneInfo));
end;

function TTimeZoneDetect.IsTestPointInTimeZone(const ATimeZone: PTimeZoneInfo): Boolean;

  function _IsPointInPoly(const APoly: PTimeZonePolygon): Boolean;
  var
    I: Integer;
    VHole: PTimeZoneHole;
  begin
    Result := IsPointInPolygon(FTestPoint, APoly.PointsCount, APoly.FirstPoint);
    if not Result then begin
      Exit;
    end;

    VHole := APoly.FirstHole;
    for I := 0 to APoly.HolesCount - 1 do begin
      if
        IsPointInRect(FTestPoint, VHole.Bound) and
        IsPointInPolygon(FTestPoint, VHole.PointsCount, VHole.FirstPoint)
      then begin
        Result := False;
        Exit;
      end;
      Inc(VHole);
    end;
  end;

var
  I, J: Integer;
  VPolygon: PTimeZonePolygon;
begin
  Result := False;

  if not IsPointInRect(FTestPoint, ATimeZone.Bound) then begin
    Exit;
  end;

  J := FPrevTzPolygonIndex;
  if (J >= 0) and (J < ATimeZone.PolygonsCount) then begin
    VPolygon := ATimeZone.FirstPolygon;
    Inc(VPolygon, J);
    if _IsPointInPoly(VPolygon) then begin
      Result := True;
      Exit;
    end;
  end;

  VPolygon := ATimeZone.FirstPolygon;
  for I := 0 to ATimeZone.PolygonsCount - 1 do begin
    if I <> FPrevTzPolygonIndex then begin
      if _IsPointInPoly(VPolygon) then begin
        Result := True;
        FPrevTzPolygonIndex := I;
        Break;
      end;
    end;
    Inc(VPolygon);
  end;
end;

procedure TTimeZoneDetect.FindLikelyZones(const ANode: PTimeZoneNode);
var
  I: Integer;
begin
  if not IsPointInRect(FTestPoint, @ANode.Bound) then begin
    Exit;
  end;
  if ANode.ZoneInfoCount > 0 then begin
    {$IFDEF DEBUG}
    Assert(FLikelyZonesCount + ANode.ZoneInfoCount < Length(FLikelyZones));
    {$ENDIF}
    for I := 0 to ANode.ZoneInfoCount - 1 do begin
      FLikelyZones[FLikelyZonesCount] := ANode.FirstZoneInfoIndex + I;
      Inc(FLikelyZonesCount);
    end;
  end;
  for I := 0 to 3 do begin
    if ANode.SubNode[I] = nil then begin
      Break;
    end;
    FindLikelyZones(ANode.SubNode[I]);
  end;
end;

function TTimeZoneDetect.LonLatToTzName(const ALon, ALat: Double): PAnsiChar;
var
  I: Integer;
  VTzIndex: Integer;
begin
  Result := nil;

  FTestPoint.X := LonToFixed(ALon, cPrecision);
  FTestPoint.Y := LatToFixed(ALat, cPrecision);

  VTzIndex := FPrevTzIndex;
  if (VTzIndex >= 0) and (VTzIndex < Length(cTzNodeZoneInfo)) then begin
    if IsTestPointInTimeZone(cTzNodeZoneInfo[VTzIndex]) then begin
      Result := cTzNodeZoneInfo[VTzIndex].TZID;
      Exit;
    end;
  end;

  FLikelyZonesCount := 0;
  FindLikelyZones(cTzTreeRoot);

  for I := 0 to FLikelyZonesCount - 1 do begin
    VTzIndex := FLikelyZones[I];
    if VTzIndex = FPrevTzIndex then begin
      Continue;
    end;
    if IsTestPointInTimeZone(cTzNodeZoneInfo[VTzIndex]) then begin
      Result := cTzNodeZoneInfo[VTzIndex].TZID;
      FPrevTzIndex := VTzIndex;
      Break;
    end;
  end;
end;

{$IFDEF DEBUG}
function TTimeZoneDetect.LonLatToTzNameOld(const ALon, ALat: Double): PAnsiChar;
var
  I: Integer;
  VTzIndex: Integer;
begin
  Result := nil;

  FTestPoint.X := LonToFixed(ALon, cPrecision);
  FTestPoint.Y := LatToFixed(ALat, cPrecision);

  VTzIndex := FPrevTzIndex;
  if (VTzIndex >= 0) and (VTzIndex < Length(cTzInfo)) then begin
    if IsTestPointInTimeZone(cTzInfo[VTzIndex]) then begin
      Result := cTzInfo[VTzIndex].TZID;
      Exit;
    end;
  end;

  for I := 0 to Length(cTzInfo) - 1 do begin
    if I = FPrevTzIndex then begin
      Continue;
    end;
    if IsTestPointInTimeZone(cTzInfo[I]) then begin
      Result := cTzInfo[I].TZID;
      FPrevTzIndex := I;
      Break;
    end;
  end;
end;
{$ENDIF}

function TTimeZoneDetect.GetTimeZoneInfo(const ATzName: PAnsiChar): PTimeZoneInfo;
var
  I: Integer;
begin
  Result := nil;

  if ATzName = cTzNodeZoneInfo[FPrevTzIndex].TZID then begin
    Result := cTzNodeZoneInfo[FPrevTzIndex];
    Exit;
  end;

  for I := 0 to Length(cTzNodeZoneInfo) - 1 do begin
    if ATzName = cTzNodeZoneInfo[I].TZID then begin
      Result := cTzNodeZoneInfo[I];
      Break;
    end;
  end;
end;

{$IFDEF USE_POINT_DETECT_LIB}
initialization
  {$IFDEF SMALL_POINT}
  Assert(SizeOf(TTimeZonePoint) = 4);
  {$ELSE}
  Assert(SizeOf(TTimeZonePoint) = 8);
  {$ENDIF}
{$ENDIF}

end.
