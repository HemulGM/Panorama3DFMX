unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Panorama,
  FMX.Controls.Presentation, FMX.StdCtrls;

type
  TFormMain = class(TForm)
    ToolBar1: TToolBar;
    ButtonOpen: TButton;
    OpenDialog: TOpenDialog;
    Panorama3D: TPanorama3D;
    procedure ButtonOpenClick(Sender: TObject);
  private
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.fmx}

procedure TFormMain.ButtonOpenClick(Sender: TObject);
begin
  OpenDialog.Filter := TBitmapCodecManager.GetFilterString;
  if OpenDialog.Execute then
    Panorama3D.Load(OpenDialog.Filename);
end;

end.

