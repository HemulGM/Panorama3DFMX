program PanoDemo;

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {FormMain},
  FMX.Panorama in '..\Source\FMX.Panorama.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
