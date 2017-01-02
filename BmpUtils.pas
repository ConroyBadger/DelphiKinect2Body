unit BmpUtils;

interface

uses
  Graphics, SysUtils, Classes, ExtCtrls;

procedure ClearBmp(Bmp:TBitmap;Color:TColor);
procedure ShowFrameRateOnBmp(Bmp:TBitmap;FrameRate:Single);
function  CreateBmpForPaintBox(PaintBox:TPaintBox):TBitmap;

implementation

function CreateBmpForPaintBox(PaintBox:TPaintBox):TBitmap;
begin
  Result:=TBitmap.Create;
  Result.Width:=PaintBox.Width;
  Result.Height:=PaintBox.Height;
  Result.PixelFormat:=pf24Bit;
end;

procedure ClearBmp(Bmp:TBitmap;Color:TColor);
begin
  Bmp.Canvas.Brush.Color:=Color;
  Bmp.Canvas.FillRect(Rect(0,0,Bmp.Width,Bmp.Height));
end;

procedure ShowFrameRateOnBmp(Bmp:TBitmap;FrameRate:Single);
begin
  with Bmp.Canvas do begin
    Font.Color:=clYellow;
    Font.Size:=8;
    Brush.Color:=clBlack;
    TextOut(5,Bmp.Height-15,FloatToStrF(FrameRate,ffFixed,9,3));
  end;
end;

end.
