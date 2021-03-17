unit t_TimeZoneCtx;

interface

{$MINENUMSIZE 4}

type
  TTzInfo = record
    Name: PAnsiChar;
    Offset: TDateTime;
  end;
  PTzInfo = ^TTzInfo;

  TTzDoublePoint = record
    X: Double;
    Y: Double;
  end;
  PTzDoublePoint = ^TTzDoublePoint;

  TTzPolygon = record
    IsHole: LongBool;

    PointsCount: Integer;
    Points: PTzDoublePoint;
  end;
  PTzPolygon = ^TTzPolygon;

  TTzLocalTimeType = (
    lttStandard,
    lttDaylight,
    lttAmbiguous,
    lttInvalid
  );

  TTzPeriod = record
    Abbrv: PAnsiChar;
    Name: PAnsiChar;

    UtcOffset: TDateTime;

    StartsAt: TDateTime;
    EndsAt: TDateTime;

    TimeType: TTzLocalTimeType;
  end;
  PTzPeriod = ^TTzPeriod;

  TTzInfoFull = record
    PeriodsCount: Integer;
    Periods: PTzPeriod;

    PolygonsCount: Integer;
    Polygons: PTzPolygon;
  end;
  PTzInfoFull = ^TTzInfoFull;

  TTzVersionInfo = record
    Lib: PAnsiChar;
    Data: PAnsiChar;
    Border: PAnsiChar;
  end;
  PTzVersionInfo = ^TTzVersionInfo;

implementation

end.
