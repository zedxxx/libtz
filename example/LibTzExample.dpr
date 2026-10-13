program LibTzExample;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{$APPTYPE CONSOLE}

uses
  SysUtils,
  libtz;

var
  VCtx: Pointer;
  VOk: Boolean;
  VUtcTime: TDateTime;
  VTzInfo: TTzInfo;
  VTzInfoFull: TTzInfoFull;
  VTzVersion: PTzVersionInfo;
begin
  // Load libtz.dll and resolve all exported functions.
  // Must be called once before using any other API function.
  if not LibTzInitialize then begin
    raise Exception.Create('libtz is not initialized!');
  end;

  // Print library, time zone database and border data versions.
  VTzVersion := tz_get_version();
  Writeln(
    'libtz v' + string(VTzVersion.Lib) + ', ' +
    'tzdb v' + string(VTzVersion.Data) + ', ' +
    'tzborder v' + string(VTzVersion.Border)
  );

  // Create a context. It holds the last error message
  // and must be passed to all other API calls.
  VCtx := tz_ctx_new();
  try
    // Moment in time (UTC) for which the time zone info is requested
    VUtcTime := EncodeDate(2024, 7, 1) + EncodeTime(12, 0, 0, 0);

    // Find the time zone by coordinates (longitude, latitude, in degrees)
    // and get its short info: name and UTC offset at the given moment.
    VOk := tz_get_info(VCtx, 139.6917, 35.6895, VUtcTime, @VTzInfo);

    // Raises ELibTzError with the library's error message if VOk = False
    tz_check_result(VCtx, VOk);

    Writeln('Time zone: ', string(VTzInfo.Name));  // e.g. "Asia/Tokyo"
    // Offset is a TDateTime fraction of a day, convert it to hours
    Writeln('UTC offset, hours: ', FloatToStr(VTzInfo.Offset * 24));

    // Get the full info for the same point: time zone periods
    // (standard/daylight transitions) and the zone border polygons.
    VOk := tz_get_info_full(VCtx, 139.6917, 35.6895, VUtcTime, @VTzInfoFull);
    tz_check_result(VCtx, VOk);

    // Number of periods (Periods) and border polygons (Polygons) returned
    Writeln('Periods count: ', VTzInfoFull.PeriodsCount);
    Writeln('Polygons count: ', VTzInfoFull.PolygonsCount);
  finally
    // Release the context
    tz_ctx_free(VCtx);
  end;
end.
