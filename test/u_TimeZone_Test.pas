unit u_TimeZone_Test;

interface

uses
  TestFramework;

type
  TTimeZoneTest = class(TTestCase)
  published
    procedure TestTimeZoneCtx;
    procedure TestTimeZoneDetect;
    procedure TestTimeZoneName;
  end;

implementation

uses
  Windows,
  Types,
  SysUtils,
  DateUtils,
  Math,
  TZDB,
  c_TzConst,
  t_TimeZoneCtx,
  u_TimeZoneCtx,
  u_TimeZoneDetect,
  u_TimeZone_TestCases;

{ TTimeZoneTest }

procedure TTimeZoneTest.TestTimeZoneDetect;
var
  I: Integer;
  VTzName: PAnsiChar;
  VTzDetect: TTimeZoneDetect;
begin
  VTzDetect := TTimeZoneDetect.Create;
  try
    for I := 0 to Length(GTestCases) - 1 do begin
      VTzName := VTzDetect.LonLatToTzName(GTestCases[I].X, GTestCases[I].Y);
      CheckEqualsString(GTestCases[I].Name, string(VTzName));

      {$IFDEF DEBUG}
      VTzName := VTzDetect.LonLatToTzNameOld(GTestCases[I].X, GTestCases[I].Y);
      CheckEqualsString(GTestCases[I].Name, string(VTzName));
      {$ENDIF}
    end;
  finally
    VTzDetect.Free;
  end;
end;

procedure TTimeZoneTest.TestTimeZoneCtx;
var
  I: Integer;
  VCtx: TTimeZoneCtx;
  VUtcTime: TDateTime;
  VTzInfo: TTzInfo;
  VTzInfoFull: TTzInfoFull;
begin
  VCtx := TTimeZoneCtx.Create;
  try
    for I := 0 to Length(GTestCases) - 1 do begin
      VUtcTime := ISO8601ToDate(GTestCases[I].Utc);

      VCtx.GetInfo(GTestCases[I].X, GTestCases[I].Y, VUtcTime, @VTzInfo);

      CheckEqualsString(GTestCases[I].Name, string(VTzInfo.Name));
      CheckEquals(GTestCases[I].Offset, VTzInfo.Offset);

      VCtx.GetInfoFull(GTestCases[I].X, GTestCases[I].Y, VUtcTime, @VTzInfoFull);

      CheckEquals(GTestCases[I].PeriodsCount, VTzInfoFull.PeriodsCount);
    end;
  finally
    VCtx.Free;
  end;
end;

procedure TTimeZoneTest.TestTimeZoneName;
var
  VAliases: TStringDynArray;

  function _IsAlias(const ATzName, ATzID: string): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to Length(VAliases) - 1 do begin
      if VAliases[I] = ATzName then begin
        Result := True;
        Break;
      end;
    end;
  end;

var
  I: Integer;
  VTzName, VTzID: string;
  VTzBundled: TBundledTimeZone;
begin
  VAliases := TBundledTimeZone.KnownAliases;

  for I := 0 to Length(cTzNodeZoneInfo) - 1 do begin
    VTzName := string(cTzNodeZoneInfo[I].TZID);
    VTzBundled := TBundledTimeZone.GetTimeZone(VTzName);
    VTzID := VTzBundled.ID;
    if VTzID <> VTzName then begin
      Check( _IsAlias(VTzName, VTzID) );
      OutputDebugString(PChar('Alias: ' + VTzName + ' --> ' + VTzID));
    end;
  end;
end;

initialization
  RegisterTest(TTimeZoneTest.Suite);

end.
