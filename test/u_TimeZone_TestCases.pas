unit u_TimeZone_TestCases;

interface

type
  TTestCase = record
    X             : Double;
    Y             : Double;
    Name          : string;
    Utc           : string;
    Offset        : TDateTime;
    PeriodsCount  : Integer;
    PolygonsCount : Integer;
    HolesCount    : Integer;
  end;

var
  GTestCases: TArray<TTestCase>;
  GBenchCases: TArray<TTestCase>;

implementation

type
  TDoublePoint = record
    X: Double;
    Y: Double;
  end;

function _T(const APoint: TDoublePoint; const AName, AUtc: string;
  AOffset: TDateTime; APeriodsCount, APolygonsCount, AHolesCount: Integer): TTestCase;
begin
  Result.X := APoint.X;
  Result.Y := APoint.Y;
  Result.Name := AName;
  Result.Utc := AUtc;
  Result.Offset := AOffset;
  Result.PeriodsCount := APeriodsCount;
  Result.PolygonsCount := APolygonsCount;
  Result.HolesCount := AHolesCount;
end;

procedure InitTestCases;
const
  BY  : TDoublePoint = (X: 31.33025104; Y: 52.49264110);
  RU1 : TDoublePoint = (X: 37.60018283; Y: 55.74956315);
  RU2 : TDoublePoint = (X: 31.54877597; Y: 52.47811065);
  UH  : TDoublePoint = (X: 37.79879504; Y: 42.90417866);
begin
  GTestCases := [
    _T(BY, 'Europe/Minsk', '2010-01-01T12:00:00', 2/24, 5, 1, 1),
    _T(BY, 'Europe/Minsk', '2011-01-01T12:00:00', 2/24, 3, 1, 1),
    _T(BY, 'Europe/Minsk', '2011-03-28T12:00:00', 3/24, 3, 1, 1),
    _T(BY, 'Europe/Minsk', '2012-01-01T12:00:00', 3/24, 1, 1, 1),

    _T(RU1, 'Europe/Moscow', '2020-02-02T12:00:00', 3/24, 1, 1, 1),
    _T(RU2, 'Europe/Moscow', '2020-02-02T12:00:00', 3/24, 1, 1, 1),

    _T(UH, '', '2020-02-02T12:00:00', 3/24, 1, 1, 1) // Uninhabited (Black Sea)
  ];
end;

procedure InitBenchCases;
begin
  GBenchCases := [
    GTestCases[0]
  ];
end;

initialization
  InitTestCases;
  InitBenchCases;

end.
