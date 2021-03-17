unit u_TimeZoneAPI_Test;

interface

uses
  TestFramework;

type
  TTimeZoneAPI = class(TTestCase)
  protected
    procedure SetUp; override;
  published
    procedure TestAPI;
    procedure BenchAPI;
  end;

implementation

uses
  Windows,
  SysUtils,
  DateUtils,
  Diagnostics,
  libtz,
  u_TimeZone_TestCases;

{ TTimeZoneAPI }

procedure TTimeZoneAPI.SetUp;
begin
  inherited SetUp;

  Check(LibTzInitialize, 'Library is not initialized!');
end;

procedure TTimeZoneAPI.TestAPI;
var
  I: Integer;
  VCtx: Pointer;
  VResult: Boolean;
  VUtcTime: TDateTime;
  VTzInfo: TTzInfo;
  VTzVersion: PTzVersionInfo;
begin
  VCtx := tz_ctx_new();
  try
    Assert(VCtx <> nil);
    for I := 0 to Length(cTestCases) - 1 do begin
      VUtcTime := ISO8601ToDate(cTestCases[I].UTC);

      VResult := tz_get_info(VCtx, cTestCases[I].X, cTestCases[I].Y, VUtcTime, @VTzInfo);
      tz_check_result(VCtx, VResult);

      CheckEqualsString(cTestCases[I].Name, string(VTzInfo.Name));
      CheckEquals(cTestCases[I].Offset, VTzInfo.Offset);
    end;
  finally
    tz_ctx_free(VCtx);
  end;

  VTzVersion := tz_get_version();

  OutputDebugString(
    PChar(
      'libtz v' + string(VTzVersion.Lib) + ', ' +
      'tzdb v' + string(VTzVersion.Data) + ', ' +
      'tzborder v' + string(VTzVersion.Border)
    )
  );
end;

procedure TTimeZoneAPI.BenchAPI;
const
  cBenchCount = 10000;
var
  I, J: Integer;
  VCtx: Pointer;
  VResult: Boolean;
  VUtcTime: TDateTime;
  VTzInfo: TTzInfo;
  VTime: TStopwatch;
begin
  VCtx := tz_ctx_new();
  try
    VTime := TStopwatch.Create;

    for J := 0 to cBenchCount - 1 do begin
      for I := 0 to Length(cBenchCases) - 1 do begin
        VUtcTime := ISO8601ToDate(cBenchCases[I].UTC);

        VTime.Start;
        VResult := tz_get_info(VCtx, cBenchCases[I].X, cBenchCases[I].Y, VUtcTime, @VTzInfo);
        VTime.Stop;

        tz_check_result(VCtx, VResult);
      end;
    end;

    OutputDebugString(PChar(IntToStr(VTime.ElapsedMilliseconds) + ' ms'));
  finally
    tz_ctx_free(VCtx);
  end;
end;

initialization
  RegisterTest(TTimeZoneAPI.Suite);

end.
