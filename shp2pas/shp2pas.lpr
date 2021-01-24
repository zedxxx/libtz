program shp2pas;

{$MODE DELPHI}{$H+}

uses
  SysUtils,
  ArgumentParser in 'lib\ArgumentParser.pas',
  libshp in 'lib\libshp.pas',
  u_AppMain in 'src\u_AppMain.pas',
  t_TzTypes in 'src\t_TzTypes.pas',
  i_TzReader in 'src\i_TzReader.pas',
  i_TzWriter in 'src\i_TzWriter.pas',
  i_TzCoordConverter in 'src\i_TzCoordConverter.pas',
  u_TzCoordConverter in 'src\u_TzCoordConverter.pas',
  u_TzReaderFromShp in 'src\u_TzReaderFromShp.pas',
  u_TzWriterMulti in 'src\u_TzWriterMulti.pas',
  u_TzWriterBase in 'src\u_TzWriterBase.pas',
  u_TzWriterToKml in 'src\u_TzWriterToKml.pas',
  u_TzWriterToPas in 'src\u_TzWriterToPas.pas';

begin
  try
    RunProgram;
  except
    on E: Exception do begin
      Writeln(E.ClassName + ': ' + E.Message);
      ReadLn;
    end;
  end;
end.

