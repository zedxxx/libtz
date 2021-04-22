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
  IOUtils,
  Diagnostics,
  libtz,
  u_TimeZone_TestCases,
  u_TimeZoneInfoWriter;

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
  VTzInfoFull: TTzInfoFull;
  VTzVersion: PTzVersionInfo;
begin
  VCtx := tz_ctx_new();
  try
    Assert(VCtx <> nil);
    for I := 0 to Length(GTestCases) - 1 do begin
      VUtcTime := ISO8601ToDate(GTestCases[I].UTC);

      VResult := tz_get_info(VCtx, GTestCases[I].X, GTestCases[I].Y, VUtcTime, @VTzInfo);
      tz_check_result(VCtx, VResult);

      CheckEqualsString(GTestCases[I].Name, string(VTzInfo.Name));
      CheckEquals(GTestCases[I].Offset, VTzInfo.Offset);

      VResult := tz_get_info_full(VCtx, GTestCases[I].X, GTestCases[I].Y, VUtcTime, @VTzInfoFull);
      tz_check_result(VCtx, VResult);

      CheckEquals(GTestCases[I].PeriodsCount, VTzInfoFull.PeriodsCount);

      if I = 0 then begin
        TFile.WriteAllText(
          ExtractFilePath(ParamStr(0)) + 'TestCase' + IntToStr(I) + '.kml',
          CreateTzInfoWriter().ToKml(@VTzInfoFull),
          TEncoding.UTF8
        )
      end;
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
      for I := 0 to Length(GBenchCases) - 1 do begin
        VUtcTime := ISO8601ToDate(GBenchCases[I].Utc);

        VTime.Start;
        VResult := tz_get_info(VCtx, GBenchCases[I].X, GBenchCases[I].Y, VUtcTime, @VTzInfo);
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
