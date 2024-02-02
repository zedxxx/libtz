program Test;

{$IFDEF CONSOLE_TESTRUNNER}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IFDEF TESTINSIGHT}
  TestInsight.Client,
  TestInsight.DUnit,
  {$ENDIF}
  DUnitTestRunner,
  u_TimeZone_Test in 'u_TimeZone_Test.pas',
  u_TimeZoneAPI_Test in 'u_TimeZoneAPI_Test.pas',
  u_TimeZone_TestCases in 'u_TimeZone_TestCases.pas',
  u_TimeZoneInfoWriter in 'u_TimeZoneInfoWriter.pas';

{$IFDEF TESTINSIGHT}
function IsTestInsightRunning: Boolean;
begin
  with TTestInsightRestClient.Create as ITestInsightClient do begin
    StartedTesting(0);
    Result := not HasError;
  end;
end;

procedure RunTests;
begin
  if IsTestInsightRunning then begin
    TestInsight.DUnit.RunRegisteredTests;
  end else begin
    DUnitTestRunner.RunRegisteredTests;
  end;
end;

{$ELSE}
procedure RunTests;
begin
  DUnitTestRunner.RunRegisteredTests;
end;
{$ENDIF}

begin
  RunTests;
end.

