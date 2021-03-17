library libtz;

{$MODE DELPHI}
{$H+}

uses
  Windows,
  u_AppMain in 'src\u_AppMain.pas',
  t_TimeZoneCtx in 'src\t_TimeZoneCtx.pas',
  u_TimeZoneCtx in 'src\u_TimeZoneCtx.pas',
  u_TimeZoneDetect in 'src\u_TimeZoneDetect.pas',
  u_TimeZoneTool in 'src\u_TimeZoneTool.pas';

exports
  tz_ctx_new,
  tz_ctx_free,
  tz_get_info,
  tz_get_info_full,
  tz_get_error,
  tz_get_version,
  tz_get_precision;

begin
  IsMultiThread := True;
  DisableThreadLibraryCalls(HInstance);
end.

