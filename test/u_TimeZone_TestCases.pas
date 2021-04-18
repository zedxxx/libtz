unit u_TimeZone_TestCases;

interface

type
  TTestCase = record
    X      : Double;
    Y      : Double;
    Name   : string;
    UTC    : string;
    Offset : TDateTime;
  end;
  PTestCase = ^TTestCase;

const
  cUTCDefault = '2020-02-02T12:00:00Z';

  cTestCases: array [0..3] of TTestCase = (
    (X: 31.33025104; Y: 52.49264110; Name: 'Europe/Minsk'; UTC: cUTCDefault; Offset: 3/24),
    (X: 37.60018283; Y: 55.74956315; Name: 'Europe/Moscow'; UTC: cUTCDefault; Offset: 3/24),
    (X: 31.54877597; Y: 52.47811065; Name: 'Europe/Moscow'; UTC: cUTCDefault; Offset: 3/24),
    (X: 37.79879504; Y: 42.90417866; Name: ''; UTC: cUTCDefault; Offset: 3/24)
  );

  cBenchCases: array [0..1] of PTestCase = (
    @cTestCases[0], @cTestCases[0]
  );

implementation

end.
