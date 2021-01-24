unit u_TimeZoneDetect;

interface

uses
  t_TzTypes;

type
  TFixedPoint = record
    X: Integer;
    Y: Integer;
  end;
  PFixedPoint = ^TFixedPoint;

  TArrayOfInteger = array of Integer;

  TTimeZoneDetect = class
  private
    FPrevTzIndex: Integer;
    FPrevTzPolygonIndex: Integer;

    FLikelyZones: TArrayOfInteger;
    FLikelyZonesCount: Integer;

    FTestPoint: TFixedPoint;
    FTestPointPtr: PFixedPoint;

    class function IsPointInRect(
      const APoint: PFixedPoint;
      const ARect: PTimeZoneBound
    ): Boolean; inline;

    class function IsPointInPolygon(
      const APoint: PFixedPoint;
      const APolygonPointsCount: Integer;
      const APolygonFirstPoint: PTimeZonePoint
    ): Boolean;

    function IsPointInTimeZone(
      const APoint: PFixedPoint;
      const ATimeZone: PTimeZoneInfo
    ): Boolean;

    procedure FindLikelyZones(
      const ANode: PTimeZoneNode;
      const APoint: PFixedPoint
    );
  public
    function LonLatToTzName(const ALon, ALat: Double): PAnsiChar;
    function LonLatToTzNameOld(const ALon, ALat: Double): PAnsiChar;
  public
    constructor Create;
  end;


implementation

uses
  c_TzConst,
  u_TimeZoneTool;

constructor TTimeZoneDetect.Create;
begin
  inherited Create;

  FPrevTzIndex := -1;
  FPrevTzPolygonIndex := -1;

  FLikelyZonesCount := 0;
  SetLength(FLikelyZones, Length(cTzNodeZoneInfo));

  FTestPointPtr := @FTestPoint;
end;

class function TTimeZoneDetect.IsPointInRect(
  const APoint: PFixedPoint;
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

class function TTimeZoneDetect.IsPointInPolygon(
  const APoint: PFixedPoint;
  const APolygonPointsCount: Integer;
  const APolygonFirstPoint: PTimeZonePoint
): Boolean;
var
  I: Integer;
  VPrevPoint: PTimeZonePoint;
  VCurrPoint: PTimeZonePoint;
begin
  Result := False;
  if APolygonPointsCount < 3 then begin
    Exit;
  end;
  VPrevPoint := APolygonFirstPoint;
  VCurrPoint := VPrevPoint;
  Inc(VCurrPoint);
  for I := 1 to APolygonPointsCount - 1 do begin
    if (((VCurrPoint.Y <= APoint.Y) and (APoint.Y < VPrevPoint.Y)) or
        ((VPrevPoint.Y <= APoint.Y) and (APoint.Y < VCurrPoint.Y))) and
        (APoint.X > (VPrevPoint.X - VCurrPoint.X) * (APoint.Y - VCurrPoint.Y) / (VPrevPoint.Y - VCurrPoint.Y) + VCurrPoint.X) then
    begin
      Result := not Result;
    end;
    VPrevPoint := VCurrPoint;
    Inc(VCurrPoint);
  end;
end;

function TTimeZoneDetect.IsPointInTimeZone(
  const APoint: PFixedPoint;
  const ATimeZone: PTimeZoneInfo
): Boolean;

  function _IsPointInPoly(const APoly: PTimeZonePolygon): Boolean;
  var
    I: Integer;
    VHole: PTimeZoneHole;
  begin
    Result := IsPointInPolygon(APoint, APoly.PointsCount, APoly.FirstPoint);
    if Result then begin
      VHole := APoly.FirstHole;
      for I := 0 to APoly.HolesCount - 1 do begin
        if
          IsPointInRect(APoint, VHole.Bound) and
          IsPointInPolygon(APoint, VHole.PointsCount, VHole.FirstPoint)
        then begin
          Result := False;
          Exit;
        end;
        Inc(VHole);
      end;
    end;
  end;

var
  I, J: Integer;
  VPolygon: PTimeZonePolygon;
begin
  Result := False;

  if not IsPointInRect(APoint, ATimeZone.Bound) then begin
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

procedure TTimeZoneDetect.FindLikelyZones(
  const ANode: PTimeZoneNode;
  const APoint: PFixedPoint
);
var
  I: Integer;
begin
  if IsPointInRect(APoint, @ANode.Bound) then begin
    if ANode.ZoneInfoCount > 0 then begin
      Assert(FLikelyZonesCount + ANode.ZoneInfoCount < Length(FLikelyZones));
      for I := 0 to ANode.ZoneInfoCount - 1 do begin
        FLikelyZones[FLikelyZonesCount] := ANode.FirstZoneInfoIndex + I;
        Inc(FLikelyZonesCount);
      end;
    end;
    for I := 0 to 3 do begin
      if ANode.SubNode[I] = nil then begin
        Break;
      end;
      FindLikelyZones(ANode.SubNode[I], APoint);
    end;
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
    if IsPointInTimeZone(FTestPointPtr, cTzNodeZoneInfo[VTzIndex]) then begin
      Result := cTzNodeZoneInfo[VTzIndex].TZID;
      Exit;
    end;
  end;

  FLikelyZonesCount := 0;

  FindLikelyZones(cTzTreeRoot, FTestPointPtr);

  for I := 0 to FLikelyZonesCount - 1 do begin
    VTzIndex := FLikelyZones[I];
    if VTzIndex = FPrevTzIndex then begin
      Continue;
    end;
    if IsPointInTimeZone(FTestPointPtr, cTzNodeZoneInfo[VTzIndex]) then begin
      Result := cTzNodeZoneInfo[VTzIndex].TZID;
      FPrevTzIndex := VTzIndex;
      Break;
    end;
  end;
end;

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
    if IsPointInTimeZone(FTestPointPtr, cTzInfo[VTzIndex]) then begin
      Result := cTzInfo[VTzIndex].TZID;
      Exit;
    end;
  end;

  for I := 0 to Length(cTzInfo) - 1 do begin
    if I = FPrevTzIndex then begin
      Continue;
    end;
    if IsPointInTimeZone(FTestPointPtr, cTzInfo[I]) then begin
      Result := cTzInfo[I].TZID;
      FPrevTzIndex := I;
      Break;
    end;
  end;
end;

end.
