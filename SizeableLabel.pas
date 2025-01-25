unit SizeableLabel;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.WinXCtrls, Vcl.Menus;

type
  TVertLocation = (vlocTop, vlocBottom, vlocMiddle, vlocOther);
  THorzLocation = (hlocLeft, hlocRight, hlocMiddle, hlocOther);

  TSizeableLabel = class(TCustomControl)
  private
  const
    HandleWidth = 6;
    HandleHeight = 6;
    HalfHandleWidth = 3;
    HalfHandleHeight = 3;

    procedure HandleMouseEnter(Sender: TObject);
    procedure HandleMouseLeave(Sender: TObject);
    procedure HandleMouseMove(Sender: TObject;
                              Shift: TShiftState;
                              X, Y: Integer);
    procedure HandleMouseDown(Sender: TObject;
                              Button: TMouseButton;
                              Shift: TShiftState;
                              X, Y: Integer);
    procedure HandleMouseUp(Sender: TObject;
                            Button: TMouseButton;
                            Shift: TShiftState;
                            X, Y: Integer);
    function IsMouseInSizingHandle(X, Y: Integer): boolean;

  private
    FInSizingHandle: boolean;
    FResizeInProgress: boolean;
    FMoveInProgress: boolean;
    FResizeHorz: boolean;
    FResizeVert: boolean;
    FStartX: integer;
    FStartY: integer;
    FEditMode: boolean;
    FColor: TColor;
    FTextIsVertical: boolean;
    FHostedLabel: TLabel;

  protected
    procedure Paint; override;
    procedure Notification(AComponent: TComponent;
                           AOperation: TOperation); override;
  public
    property HostedLabel: TLabel read FHostedLabel;

    constructor Create(AOwner: TComponent; AText: string); reintroduce; overload;
    destructor Destroy; override;
    procedure SetEditMode(AEditMode: boolean);
    procedure SetColor(AColor: TColor);
    procedure SetTextVertical(ATextIsVertical: boolean);
  end;

//******************************************************************************
//******************************************************************************

implementation

//******************************************************************************

constructor TSizeableLabel.Create(AOwner: TComponent; AText: string);
begin
  inherited Create(AOwner);

  FHostedLabel := TLabel.Create(Self);
  FHostedLabel.Left := HandleWidth;
  FHostedLabel.Top := HandleHeight;
  FHostedLabel.Caption := ' ' + AText + ' ';
  FHostedLabel.Width := 90;
  FHostedLabel.Height := 15;
  FHostedLabel.Parent := Self;
  FHostedLabel.Visible := True;

  Width := HostedLabel.Width + (2 * HandleWidth);
  Height := HostedLabel.Height + (2 * HandleHeight);
  Color := clWhite;

  OnMouseDown := HandleMouseDown;
  OnMouseMove := HandleMouseMove;
  OnMouseUp := HandleMouseUp;
  OnMouseEnter := HandleMouseEnter;
  OnMouseLeave := HandleMouseLeave;

  FHostedLabel.OnMouseDown := HandleMouseDown;
  FHostedLabel.OnMouseMove := HandleMouseMove;
  FHostedLabel.OnMouseUp := HandleMouseUp;
  FHostedLabel.OnMouseEnter := HandleMouseEnter;
  FHostedLabel.OnMouseLeave := HandleMouseLeave;
end;

//******************************************************************************

destructor TSizeableLabel.Destroy;
begin
  inherited;
end;

//******************************************************************************

procedure TSizeableLabel.SetEditMode(AEditMode: boolean);
begin
  FEditMode := AEditMode;
  Invalidate;
end;

//******************************************************************************

function TSizeableLabel.IsMouseInSizingHandle(X, Y: Integer): boolean;
var
  HalfWidth: integer;
  HalfHeight: integer;
  InHorzRange: boolean;
  InVertRange: boolean;
  vertLocation: TVertLocation;
  horzLocation: THorzLocation;
begin
  InHorzRange := False;
  InVertRange := False;

  HalfWidth := Width DIV 2;
  HalfHeight := Height DIV 2;

  horzLocation := hlocOther;
  vertLocation := vlocOther;

  if X <= HalfWidth then
  begin
    // mouse in left half
    if X < HandleWidth then
    begin
      InHorzRange := True;
      horzLocation := hlocLeft;
    end else if X > (HalfWidth - HalfHandleWidth) then
    begin
      InHorzRange := True;
      horzLocation := hlocMiddle;
    end;
  end else
  begin
    // mouse in right half
    if X > (Width - HandleWidth) then
    begin
      InHorzRange := True;
      horzLocation := hlocRight;
    end else if X < (HalfWidth + HalfHandleWidth) then
    begin
      InHorzRange := True;
      horzLocation := hlocMiddle;
    end;
  end;

  if InHorzRange then
  begin
    if Y <= HalfHeight then
    begin
      // mouse in upper half
      if Y < HandleHeight then
      begin
        InVertRange := True;
        vertLocation := vlocTop;
      end else if Y > (HalfHeight - HalfHandleHeight) then
      begin
        InVertRange := True;
        vertLocation := vlocMiddle;
      end;
    end else
	begin
      // mouse in lower half
      if Y > (Height - HandleHeight) then
      begin
        InVertRange := True;
        vertLocation := vlocBottom;
      end else if Y < (HalfHeight + HalfHandleHeight) then
      begin
        InVertRange := True;
        vertLocation := vlocMiddle;
      end;
    end;
  end;

  if InHorzRange and InVertRange then
  begin
    Result := True;

    FResizeHorz := False;
    FResizeVert := False;

    if vertLocation = vlocMiddle then
    begin
      Screen.Cursor := crSizeWE;
      FResizeHorz := True;
    end else if horzLocation = hlocMiddle then
    begin
      Screen.Cursor := crSizeNS;
      FResizeVert := True;
    end else
    begin
      FResizeHorz := True;
      FResizeVert := True;

      if vertLocation = vlocTop then
      begin
        if horzLocation = hlocLeft then
        begin
          // top left
          Screen.Cursor := crSizeNWSE;
        end else
        begin
          // top right
          Screen.Cursor := crSizeNESW;
        end;
      end else
      begin
        if horzLocation = hlocLeft then
        begin
          // bottom left
          Screen.Cursor := crSizeNESW;
        end else
        begin
          // bottom right
          Screen.Cursor := crSizeNWSE;
        end;
      end;
    end;
  end else
  begin
    Result := False;
    Screen.Cursor := crDefault;
  end;
end;

//******************************************************************************

procedure TSizeableLabel.HandleMouseEnter(Sender: TObject);
begin
  FInSizingHandle := False;
  FResizeInProgress := False;
  FMoveInProgress := False;
  FResizeHorz := False;
  FResizeVert := False;
end;

//******************************************************************************

procedure TSizeableLabel.HandleMouseLeave(Sender: TObject);
begin
  FInSizingHandle := False;
  FResizeInProgress := False;
  FMoveInProgress := False;
  FResizeHorz := False;
  FResizeVert := False;
  Screen.Cursor := crDefault;
end;

//******************************************************************************

procedure TSizeableLabel.HandleMouseMove(Sender: TObject;
                                         Shift: TShiftState;
                                         X, Y: Integer);
var
  DeltaX: integer;
  DeltaY: integer;
  AbsDeltaX: integer;
  AbsDeltaY: integer;
begin
  if FEditMode then
  begin
    if not FResizeInProgress then
    begin
      FInSizingHandle := IsMouseInSizingHandle(X, Y);
    end;

    if ssLeft in Shift then
    begin
      DeltaX := X - FStartX;
      DeltaY := Y - FStartY;

      if FMoveInProgress then
      begin
        SetBounds(Left + DeltaX, Top + DeltaY, Width, Height);
      end else if FResizeInProgress then
      begin
        if FResizeHorz then
        begin
          if FStartX <= HandleWidth then
          begin
            AbsDeltaX := Abs(DeltaX);
            if DeltaX < 0 then
            begin
              // dragging left edge to left (increasing width and decreasing left)
              FHostedLabel.Width := FHostedLabel.Width + AbsDeltaX;
              SetBounds(Left - AbsDeltaX, Top, Width + AbsDeltaX, Height);
            end else
            begin
              // dragging left edge to right (decreasing width and increasing left)
              FHostedLabel.Width := FHostedLabel.Width - AbsDeltaX;
              SetBounds(Left + AbsDeltaX, Top, Width - AbsDeltaX, Height);
            end;
          end else
          begin
            FHostedLabel.Width := FHostedLabel.Width + DeltaX;
            Width := Width + DeltaX;
          end;
        end;

        if FResizeVert then
        begin
          if FStartY <= HandleHeight then
          begin
            AbsDeltaY := Abs(DeltaY);
            if DeltaY < 0 then
            begin
              // dragging top up (increasing height and decreasing top)
              FHostedLabel.Height := FHostedLabel.Height + AbsDeltaY;
              SetBounds(Left, Top - AbsDeltaY, Width, Height + AbsDeltaY);
            end else
            begin
              // dragging top down (decreasing height and increasing top)
              FHostedLabel.Height := FHostedLabel.Height - AbsDeltaY;
              SetBounds(Left, Top + AbsDeltaY, Width, Height - AbsDeltaY);
            end;
          end else
          begin
            FHostedLabel.Height := FHostedLabel.Height + DeltaY;
            Height := Height + DeltaY;
          end;
        end;

        FStartX := X;
        FStartY := Y;
      end;
    end;
  end else
  begin
    Inherited;
  end;
end;

//******************************************************************************

procedure TSizeableLabel.HandleMouseDown(Sender: TObject;
                                         Button: TMouseButton;
                                         Shift: TShiftState;
                                         X, Y: Integer);
begin
  if FEditMode then
  begin
    FInSizingHandle := IsMouseInSizingHandle(X, Y);

    FStartX := X;
    FStartY := Y;

    if FInSizingHandle then
    begin
      // start of resize
      FResizeInProgress := True;
    end else
    begin
      // start of move
      FMoveInProgress := True;
    end;
  end;
end;

//******************************************************************************

procedure TSizeableLabel.HandleMouseUp(Sender: TObject;
                                       Button: TMouseButton;
                                       Shift: TShiftState;
                                       X, Y: Integer);
begin
  if FEditMode and FResizeInProgress then
  begin
    FResizeInProgress := False;
    Screen.Cursor := crDefault;
  end;
end;

//******************************************************************************

procedure TSizeableLabel.Paint;
var
  HalfWidth: integer;
  HalfHeight: integer;
begin
  inherited;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  if FEditMode then
  begin
    // draw 8 sizing handles
    Canvas.Pen.Color := clBlue;
    Canvas.Brush.Color := clSkyBlue;

    HalfWidth := Width DIV 2;
    HalfHeight := Height DIV 2;

    // top left
    Canvas.Rectangle(0, 0, HandleWidth, HandleHeight);

    // top right
    Canvas.Rectangle(Width-HandleWidth, 0, Width, HandleHeight);

    // bottom right
    Canvas.Rectangle(Width-HandleWidth,
                     Height-HandleHeight,
                     Width,
                     Height);

    // bottom left
    Canvas.Rectangle(0,
                     Height-HandleHeight,
                     HandleWidth,
                     Height);

    // left leg
    Canvas.Rectangle(0,
                     HalfHeight-HalfHandleHeight,
                     HandleWidth,
                     HalfHeight+HalfHandleHeight);

    // top leg
    Canvas.Rectangle(HalfWidth-HalfHandleWidth,
                     0,
                     HalfWidth+HalfHandleWidth,
                     HandleHeight);

    // right leg
    Canvas.Rectangle(Width-HandleWidth,
                     HalfHeight-HalfHandleHeight,
                     Width,
                     HalfHeight+HalfHandleHeight);

    // bottom leg
    Canvas.Rectangle(HalfWidth-HalfHandleWidth,
                     Height-HandleHeight,
                     HalfWidth+HalfHandleWidth,
                     Height);
  end;
end;

//******************************************************************************

procedure TSizeableLabel.Notification(AComponent: TComponent;
                                      AOperation: TOperation);
begin
  inherited;

  if (AOperation = opRemove) and (AComponent = FHostedLabel) then
  begin
    FHostedLabel := nil;
  end;
end;

//******************************************************************************

procedure TSizeableLabel.SetColor(AColor: TColor);
begin
  Color := AColor;
  Invalidate;
end;

//******************************************************************************

procedure TSizeableLabel.SetTextVertical(ATextIsVertical: boolean);
begin
  FTextIsVertical := ATextIsVertical;
  if ATextIsVertical then
  begin
    // flip the width and height
    Height := FHostedLabel.Width + (2 * HandleWidth);
    Width := FHostedLabel.Height + (2 * HandleHeight);
  end;
end;

//******************************************************************************

end.
