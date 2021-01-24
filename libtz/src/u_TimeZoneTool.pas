unit u_TimeZoneTool;

interface

function LonToFixed(const AValue: Double; const APrecision: Integer): Integer; inline;
function LatToFixed(const AValue: Double; const APrecision: Integer): Integer; inline;

function FixedToLon(const AValue: Integer; const APrecision: Integer): Double; inline;
function FixedToLat(const AValue: Integer; const APrecision: Integer): Double; inline;

function DoubleToFixed(const AValue: Double; const AScale, APrecision: Integer): Integer; inline;
function FixedToDouble(const AValue: Integer; const AScale, APrecision: Integer): Double; inline;

implementation

function DoubleToFixed(const AValue: Double; const AScale, APrecision: Integer): Integer;
begin
  Result := Trunc( (1 shl (APrecision - 1) - 1) * AValue / AScale );
end;

function FixedToDouble(const AValue: Integer; const AScale, APrecision: Integer): Double;
begin
  Result := Int64(AValue) * AScale / (1 shl (APrecision - 1) - 1);
end;

function LonToFixed(const AValue: Double; const APrecision: Integer): Integer;
begin
  Result := DoubleToFixed(AValue, 180, APrecision);
end;

function LatToFixed(const AValue: Double; const APrecision: Integer): Integer;
begin
  Result := DoubleToFixed(AValue, 90, APrecision);
end;

function FixedToLon(const AValue: Integer; const APrecision: Integer): Double;
begin
  Result := FixedToDouble(AValue, 180, APrecision);
end;

function FixedToLat(const AValue: Integer; const APrecision: Integer): Double;
begin
  Result := FixedToDouble(AValue, 90, APrecision);
end;

end.
