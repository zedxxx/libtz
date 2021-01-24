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
    for I := 0 to Length(cTestCases) - 1 do begin
      VTzName := VTzDetect.LonLatToTzName(cTestCases[I].X, cTestCases[I].Y);
      CheckEqualsString(cTestCases[I].Name, string(VTzName));

      VTzName := VTzDetect.LonLatToTzNameOld(cTestCases[I].X, cTestCases[I].Y);
      CheckEqualsString(cTestCases[I].Name, string(VTzName));
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
begin
  VCtx := TTimeZoneCtx.Create;
  try
    for I := 0 to Length(cTestCases) - 1 do begin
      VUtcTime := ISO8601ToDate(cTestCases[I].UTC);

      VCtx.GetInfo(cTestCases[I].X, cTestCases[I].Y, VUtcTime, @VTzInfo);

      CheckEqualsString(cTestCases[I].Name, string(VTzInfo.Name));
      CheckEquals(cTestCases[I].Offset, VTzInfo.Offset);
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
        OutputDebugString(PChar(ATzName + ' --> ' + ATzID));
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

  for I := 0 to Length(cTzInfo) - 1 do begin
    VTzName := string(cTzInfo[I].TZID);
    VTzBundled := TBundledTimeZone.GetTimeZone(VTzName);
    VTzID := VTzBundled.ID;
    if (VTzID <> VTzName) and not _IsAlias(VTzName, VTzID) then begin
      Assert(False);
    end;
  end;
end;

initialization
  RegisterTest(TTimeZoneTest.Suite);

end.
