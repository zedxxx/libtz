unit u_TimeZoneCtx;

interface

{$IFDEF FPC}
  {$MODESWITCH UnicodeStrings}
{$ENDIF}

uses
  TZDB,
  t_TimeZoneCtx,
  u_TimeZoneDetect;

type
  TTzInfoFullInternal = record
    Periods: array of TTzPeriod;
    PeriodsPtr: array of PTzPeriod;

    PeriodsStr: array of record
      Abbrv : AnsiString;
      Name  : AnsiString;
    end;

    Polygons: array of TTzPolygon;
    PolygonsPtr: array of PTzPolygon;

    PolygonsInternal: array of record
      IsHole : Boolean;
      Points : array of TTzDoublePoint;
    end;

    procedure SetPeriodsCount(const AValue: Integer);
    procedure SetPolygonsCount(const AValue: Integer);

    procedure ToTzInfoFull(const AInfo: PTzInfoFull);
  end;

  TTimeZoneCtx = class
  private
    FTzDetect: TTimeZoneDetect;

    FTzName: PAnsiChar;
    FTzBundled: TBundledTimeZone;

    FErrorMessage: UTF8String;

    FTzInfoFull: TTzInfoFullInternal;

    class function OffsetFromLongitude(const ALon: Double): TDateTime; static;
  public
    procedure SetError(const AMsg: UTF8String);
    function GetError: PAnsiChar;

    procedure GetInfo(
      const ALon, ALat: Double;
      const AUtcTime: TDateTime;
      const AInfo: PTzInfo
    );

    procedure GetInfoFull(
      const ALon, ALat: Double;
      const AUtcTime: TDateTime;
      const AInfo: PTzInfoFull
    );
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils,
  DateUtils,
  {$IFNDEF FPC}
  TimeSpan,
  {$ENDIF}
  Math,
  t_TzTypes,
  c_TzConst,
  u_TimeZoneTool;

{ TTimeZoneCtx }

constructor TTimeZoneCtx.Create;
begin
  inherited Create;

  FTzName := nil;
  FTzBundled := nil;
  FErrorMessage := '';

  FTzDetect := TTimeZoneDetect.Create;
end;

destructor TTimeZoneCtx.Destroy;
begin
  FTzName := nil;
  FTzBundled := nil;
  FErrorMessage := '';

  FreeAndNil(FTzDetect);

  inherited Destroy;
end;

procedure TTimeZoneCtx.GetInfoFull(const ALon, ALat: Double;
  const AUtcTime: TDateTime; const AInfo: PTzInfoFull);

  procedure AddPeriod(
    const APeriodIndex: Integer;
    const AAbbrv, AName: string;
    const AUtcOffset, AStartsAt, AEndsAt: TDateTime;
    const ATimeType: TTzLocalTimeType
  );
  begin
    with FTzInfoFull.PeriodsStr[APeriodIndex] do begin
      Abbrv := AnsiString(AAbbrv);
      Name  := AnsiString(AName);
    end;

    with FTzInfoFull.Periods[APeriodIndex] do begin
      UtcOffset := AUtcOffset;
      StartsAt  := AStartsAt;
      EndsAt    := AEndsAt;
      TimeType  := ATimeType;
    end;
  end;

  procedure AddPoly(
    const APolyIndex: Integer;
    const APointsCount: Integer;
    const APoints: PTimeZonePoint;
    const AIsHole: Boolean
  );
  var
    I: Integer;
    VFixedPoint: PTimeZonePoint;
    VFloatPoint: PTzDoublePoint;
  begin
    FTzInfoFull.PolygonsInternal[APolyIndex].IsHole := AIsHole;
    SetLength(FTzInfoFull.PolygonsInternal[APolyIndex].Points, APointsCount);

    if APointsCount = 0 then begin
      Exit;
    end;

    VFixedPoint := APoints;
    VFloatPoint := @FTzInfoFull.PolygonsInternal[APolyIndex].Points[0];

    for I := 0 to APointsCount - 1 do begin
      VFloatPoint.X := FixedToLon(VFixedPoint.X, cPrecision);
      VFloatPoint.Y := FixedToLat(VFixedPoint.Y, cPrecision);

      Inc(VFixedPoint);
      Inc(VFloatPoint);
    end;
  end;

var
  I, J, K: Integer;
  VTzName: PAnsiChar;
  VTzInfo: PTimeZoneInfo;
  VTzPoly: PTimeZonePolygon;
  VTzHole: PTimeZoneHole;
  VTzBundled: TBundledTimeZone;
  VTzYearSegment: TYearSegment;
  VTzYearSegmentArray: TYearSegmentArray;
begin
  FillChar(AInfo^, SizeOf(TTzInfoFull), 0);

  VTzName := FTzDetect.LonLatToTzName(ALon, ALat);

  if VTzName = nil then begin
    FTzInfoFull.SetPeriodsCount(1);
    AddPeriod(0, '', '', OffsetFromLongitude(ALon), 0, 0, TTzLocalTimeType(lttStandard));

    FTzInfoFull.SetPolygonsCount(0);
  end else begin
    // Periods

    VTzBundled := TBundledTimeZone.GetTimeZone(string(VTzName));

    VTzYearSegmentArray := VTzBundled.GetYearBreakdown(
      YearOf(VTzBundled.ToLocalTime(AUtcTime))
    );

    FTzInfoFull.SetPeriodsCount(Length(VTzYearSegmentArray));

    for I := 0 to Length(VTzYearSegmentArray) - 1 do begin
      VTzYearSegment := VTzYearSegmentArray[I];
      AddPeriod(
        I,
        VTzBundled.GetAbbreviation(VTzYearSegment.StartsAt),
        VTzYearSegment.DisplayName,
        {$IFDEF FPC}
        VTzYearSegment.UtcOffset / 3600 / 24,
        {$ELSE}
        VTzYearSegment.UtcOffset.TotalHours / 24,
        {$ENDIF}
        VTzYearSegment.StartsAt,
        VTzYearSegment.EndsAt,
        TTzLocalTimeType(VTzYearSegment.LocalType)
      );
    end;

    // Polygons

    VTzInfo := FTzDetect.GetTimeZoneInfo(VTzName);
    Assert(VTzInfo <> nil);

    K := VTzInfo.PolygonsCount;
    VTzPoly := VTzInfo.FirstPolygon;

    for I := 0 to VTzInfo.PolygonsCount - 1 do begin
      Inc(K, VTzPoly.HolesCount);
      Inc(VTzPoly);
    end;

    FTzInfoFull.SetPolygonsCount(K);

    K := 0;
    VTzPoly := VTzInfo.FirstPolygon;

    for I := 0 to VTzInfo.PolygonsCount - 1 do begin
      AddPoly(K, VTzPoly.PointsCount, VTzPoly.FirstPoint, False);
      Inc(K);
      VTzHole := VTzPoly.FirstHole;
      for J := 0 to VTzPoly.HolesCount - 1 do begin
        AddPoly(K, VTzHole.PointsCount, VTzHole.FirstPoint, True);
        Inc(K);
        Inc(VTzHole);
      end;
      Inc(VTzPoly);
    end;
  end;

  FTzInfoFull.ToTzInfoFull(AInfo);
end;

procedure TTimeZoneCtx.GetInfo(const ALon, ALat: Double;
  const AUtcTime: TDateTime; const AInfo: PTzInfo);
var
  VTzLocalTime: TDateTime;
begin
  AInfo.Name := FTzDetect.LonLatToTzName(ALon, ALat);

  if AInfo.Name = nil then begin
    FTzName := nil;
    AInfo.Offset := OffsetFromLongitude(ALon);
    Exit;
  end;

  if FTzName <> AInfo.Name then begin
    FTzName := AInfo.Name;
    FTzBundled := TBundledTimeZone.GetTimeZone(string(FTzName));
  end;
  Assert(FTzBundled <> nil);

  VTzLocalTime := FTzBundled.ToLocalTime(AUtcTime);
  {$IFDEF FPC}
  AInfo.Offset := FTzBundled.GetUtcOffset(VTzLocalTime) / 3600 / 24;
  {$ELSE}
  AInfo.Offset := FTzBundled.GetUtcOffset(VTzLocalTime).TotalHours / 24;
  {$ENDIF}
end;

class function TTimeZoneCtx.OffsetFromLongitude(const ALon: Double): TDateTime;
var
  VPosNo: Double;
  VHours: Double;
  VDirection: Integer;
begin
  if ALon < 0 then begin
    VDirection := -1;
  end else begin
    VDirection := 1;
  end;

  VPosNo := Sqrt(Power(ALon, 2));
  if VPosNo <= 7.5 then begin
    Result := 0;
    Exit;
  end;

  VPosNo := VPosNo - 7.5;
  VHours := VPosNo / 15;
  if FMod(VPosNo, 15) > 0 then begin
    VHours := VHours + 1;
  end;

  Result := VDirection * Floor(VHours) / 24;
end;

function TTimeZoneCtx.GetError: PAnsiChar;
begin
  Result := PAnsiChar(FErrorMessage);
end;

procedure TTimeZoneCtx.SetError(const AMsg: UTF8String);
begin
  FErrorMessage := AMsg;
end;

{ TTzInfoFullInternal }

procedure TTzInfoFullInternal.SetPeriodsCount(const AValue: Integer);
var
  I: Integer;
begin
  SetLength(Periods, AValue);
  SetLength(PeriodsPtr, AValue);
  for I := 0 to AValue - 1 do begin
    PeriodsPtr[I] := @Periods[I];
  end;
  SetLength(PeriodsStr, AValue);
end;

procedure TTzInfoFullInternal.SetPolygonsCount(const AValue: Integer);
var
  I: Integer;
begin
  SetLength(Polygons, AValue);
  SetLength(PolygonsPtr, AValue);
  for I := 0 to AValue - 1 do begin
    PolygonsPtr[I] := @Polygons[I];
  end;
  SetLength(PolygonsInternal, AValue);
end;

procedure TTzInfoFullInternal.ToTzInfoFull(const AInfo: PTzInfoFull);
var
  I: Integer;
begin
  for I := 0 to Length(PeriodsStr) - 1 do begin
    Periods[I].Abbrv := PAnsiChar(PeriodsStr[I].Abbrv);
    Periods[I].Name  := PAnsiChar(PeriodsStr[I].Name);
  end;

  AInfo.PeriodsCount  := Length(PeriodsPtr);
  if AInfo.PeriodsCount > 0 then begin
    AInfo.Periods := PeriodsPtr[0];
  end;

  AInfo.PolygonsCount := Length(PolygonsPtr);
  if AInfo.PolygonsCount > 0 then begin
    AInfo.Polygons := PolygonsPtr[0];
  end;

  for I := 0 to AInfo.PolygonsCount - 1 do begin
    Polygons[I].IsHole := PolygonsInternal[I].IsHole;
    Polygons[I].PointsCount := Length(PolygonsInternal[I].Points);
    if Polygons[I].PointsCount > 0 then begin
      Polygons[I].Points := @PolygonsInternal[I].Points[0];
    end;
  end;
end;

end.
