program libtz_test;

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  u_TimeZone_Test in 'u_TimeZone_Test.pas',
  u_TimeZoneAPI_Test in 'u_TimeZoneAPI_Test.pas',
  u_TimeZone_TestCases in 'u_TimeZone_TestCases.pas',
  u_TimeZoneInfoWriter in 'u_TimeZoneInfoWriter.pas';

begin
  DUnitTestRunner.RunRegisteredTests;
end.

