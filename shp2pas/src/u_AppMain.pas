unit u_AppMain;

interface

procedure RunProgram;

implementation

uses
  SysUtils,
  Argumentparser,
  i_TzReader,
  i_TzWriter,
  i_TzCoordConverter,
  u_TzWriterMulti,
  u_TzReaderFromShp,
  u_TzCoordConverter;

type
  TArgumentsRec = record
    ShpFile: string;
    Precision: Integer;
    OutputPath: TTzWriterPath;
    procedure Init;
  end;

{ TArgumentsRec }

procedure TArgumentsRec.Init;
var
  I: TTzWriterType;
begin
  ShpFile := '';
  Precision := 0;
  for I := Low(TTzWriterType) to High(TTzWriterType) do begin
    OutputPath[I] := '';
  end;
end;

function DoReadCmdLineArguments: TArgumentsRec;
var
  VParser: TArgumentParser;
  VParseResult: TParseResult;
begin
  Result.Init;

  VParser := TArgumentParser.Create;
  try
    VParser.AddArgument('--shp', saStore);
    VParser.AddArgument('--out-kml', saStore);
    VParser.AddArgument('--out-pas', saStore);
    VParser.AddArgument('--precision', saStore);

    VParseResult := VParser.ParseArgs;
    try
      if VParseResult.HasArgument('shp') then begin
        Result.ShpFile := VParseResult.GetValue('shp');
      end else begin
        raise Exception.Create('"--shp" argument is not found!');
      end;

      if VParseResult.HasArgument('out-kml') then begin
        Result.OutputPath[tzwKml] := VParseResult.GetValue('out-kml');
      end;

      if VParseResult.HasArgument('out-pas') then begin
        Result.OutputPath[tzwPas] := VParseResult.GetValue('out-pas');
      end;

      if VParseResult.HasArgument('precision') then begin
        Result.Precision := StrToInt(VParseResult.GetValue('precision'));
      end else begin
        raise Exception.Create('"--precision" argument is not found!');
      end;
    finally
      VParseResult.Free;
    end;
  finally
    VParser.Free;
  end;
end;

procedure RunProgram;
var
  VArgs: TArgumentsRec;
  VTzReader: ITzReader;
  VTzWriter: ITzWriter;
  VTzCoordConverter: ITzCoordConverter;
begin
  VArgs := DoReadCmdLineArguments;
  VTzCoordConverter := TTzCoordConverter.Create(VArgs.Precision);

  VTzWriter :=
    TTzWriterMulti.Create(
      VArgs.OutputPath,
      VTzCoordConverter
    );

  VTzReader :=
    TTzReaderFromShp.Create(
      VArgs.ShpFile,
      VTzCoordConverter,
      VTzWriter
    );

  VTzReader.Run;
end;

end.

