program Kinect2Test;

uses
  Vcl.Forms,
  Main in 'Main.pas' {MainFrm},
  Kinect2Dll in 'Kinect2Dll.pas',
  Kinect2U in 'Kinect2U.pas',
  BmpUtils in 'BmpUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainFrm, MainFrm);
  Application.Run;
end.
