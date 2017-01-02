unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Samples.Spin, AprSpin;

type
  TMainFrm = class(TForm)
    StatusBar: TStatusBar;
    PaintBox: TPaintBox;
    Timer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure VersionBtnClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);

  private
    Bmp : TBitmap;
    procedure UpdateMulti;
    procedure UpdateNormal;

  public

  end;

var
  MainFrm: TMainFrm;

implementation

{$R *.dfm}

uses
  Kinect2DLL, Kinect2U, BmpUtils;

procedure TMainFrm.FormCreate(Sender: TObject);
begin
//  Left:=-2880;
  ClientWidth:=COLOR_W;
  ClientHeight:=COLOR_H+StatusBar.Height;

  PaintBox.Width:=COLOR_W;
  PaintBox.Height:=COLOR_H;

  Bmp:=CreateBmpForPaintBox(PaintBox);
  Bmp.PixelFormat:=pf32Bit;

  Kinect2:=TKinect2.Create;

  if FileExists(FullDLLName) then begin
    Kinect2.StartUp;
    if Kinect2.DllLoaded then begin
      StatusBar.Panels[0].Text:='Library version #'+Kinect2.DLLVersion+' loaded';
      if Kinect2.AbleToStartColorStream then begin
        if Kinect2.AbleToStartBodyStream then begin
          StatusBar.Panels[1].Text:='Kinect ready';
          Timer.Enabled:=True;
        end;
      end
      else StatusBar.Panels[1].Text:='Kinect not ready';
    end
    else StatusBar.Panels[0].Text:='Library not loaded';
  end
  else StatusBar.Panels[0].Text:=FullDLLName+' not found';
end;

procedure TMainFrm.UpdateMulti;
begin
  if Kinect2.AbleToUpdateMultiFrame then begin
    Kinect2.DrawColorBmp(Bmp);
    Kinect2.DrawBodies(Bmp);
    ShowFrameRateOnBmp(Bmp,Kinect2.MeasuredFPS);
    PaintBox.Canvas.Draw(0,0,Bmp);
  end;
  Kinect2.DoneMultiFrame;
end;

procedure TMainFrm.UpdateNormal;
begin
//Kinect2.UpdateBody;
  if Kinect2.AbleToUpdateBody then begin
//    Kinect2.SyncBodyData;
  end;

  if Kinect2.AbleToGetColorFrame then begin
    Kinect2.DrawColorBmp(Bmp);
    Kinect2.DrawBodies(Bmp);
    ShowFrameRateOnBmp(Bmp,Kinect2.MeasuredFPS);
    PaintBox.Canvas.Draw(0,0,Bmp);
  end;
  Kinect2.DoneColor;
end;

procedure TMainFrm.TimerTimer(Sender: TObject);
begin
  UpdateNormal;
end;

procedure TMainFrm.VersionBtnClick(Sender: TObject);
begin
  Caption:=KinectVersionString;
end;

end.
