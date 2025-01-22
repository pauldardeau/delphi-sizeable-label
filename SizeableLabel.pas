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
    InSizingHandle: boolean;
    ResizeInProgress: boolean;
    MoveInProgress: boolean;
    ResizeHorz: boolean;
    ResizeVert: boolean;
    StartX: integer;
    StartY: integer;
    EditMode: boolean;
    Color: TColor;
    TextIsVertical: boolean;

  protected
    procedure Paint; override;
  public
    HostedLabel: TLabel;

    constructor Create(AOwner: TComponent; Text: string); reintroduce; overload;
    destructor Destroy; override;
    procedure SetEditMode(AEditMode: boolean);
    procedure SetColor(AColor: TColor);
    procedure SetTextVertical(ATextIsVertical: boolean);
  end;

//******************************************************************************
//******************************************************************************

implementation

//******************************************************************************

constructor TSizeableLabel.Create(AOwner: TComponent; Text: string);
begin
  inherited Create(AOwner);

  HostedLabel := TLabel.Create(AOwner);
  HostedLabel.Left := HandleWidth;
  HostedLabel.Top := HandleHeight;
  HostedLabel.Caption := ' ' + Text + ' ';
  HostedLabel.Width := 90;
  HostedLabel.Height := 15;
  HostedLabel.Parent := Self;
  HostedLabel.Visible := true;

  InSizingHandle := false;
  ResizeInProgress := false;
  MoveInProgress := false;
  ResizeHorz := false;
  ResizeVert := false;
  Width := HostedLabel.Width + (2 * HandleWidth);
  Height := HostedLabel.Height + (2 * HandleHeight);
  EditMode := false;
  Color := clWhite;
  TextIsVertical := false;

  Self.OnMouseDown := Self.HandleMouseDown;
  Self.OnMouseMove := Self.HandleMouseMove;
  Self.OnMouseUp := Self.HandleMouseUp;
  Self.OnMouseEnter := Self.HandleMouseEnter;
  Self.OnMouseLeave := Self.HandleMouseLeave;

  HostedLabel.OnMouseDown := Self.HandleMouseDown;
  HostedLabel.OnMouseMove := Self.HandleMouseMove;
  HostedLabel.OnMouseUp := Self.HandleMouseUp;
  HostedLabel.OnMouseEnter := Self.HandleMouseEnter;
  HostedLabel.OnMouseLeave := Self.HandleMouseLeave;
end;

//******************************************************************************

destructor TSizeableLabel.Destroy;
begin
  if HostedLabel <> nil then
  begin
    HostedLabel.Free;
    HostedLabel := nil;
  end;

  inherited;
end;

//******************************************************************************

procedure TSizeableLabel.SetEditMode(AEditMode: boolean);
begin
  EditMode := AEditMode;
  Self.Invalidate;
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
  InHorzRange := false;
  InVertRange := false;

  HalfWidth := Width DIV 2;
  HalfHeight := Height DIV 2;

  horzLocation := hlocOther;
  vertLocation := vlocOther;

  if X <= HalfWidth then
  begin
    // mouse in left half
    if X < HandleWidth then
    begin
      InHorzRange := true;
      horzLocation := hlocLeft;
    end else if X > (HalfWidth - HalfHandleWidth) then
    begin
      InHorzRange := true;
      horzLocation := hlocMiddle;
    end;
  end else
  begin
    // mouse in right half
    if X > (Width - HandleWidth) then
    begin
      InHorzRange := true;
      horzLocation := hlocRight;
    end else if X < (HalfWidth + HalfHandleWidth) then
    begin
      InHorzRange := true;
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
        InVertRange := true;
        vertLocation := vlocTop;
      end else if Y > (HalfHeight - HalfHandleHeight) then
      begin
        InVertRange := true;
        vertLocation := vlocMiddle;
      end;
    end else begin
      // mouse in lower half
      if Y > (Height - HandleHeight) then
      begin
        InVertRange := true;
        vertLocation := vlocBottom;
      end else if Y < (HalfHeight + HalfHandleHeight) then
      begin
        InVertRange := true;
        vertLocation := vlocMiddle;
      end;
    end;
  end;

  if InHorzRange and InVertRange then
  begin
    result := true;

    ResizeHorz := false;
    ResizeVert := false;

    if vertLocation = vlocMiddle then
    begin
      Screen.Cursor := crSizeWE;
      ResizeHorz := true;
    end else if horzLocation = hlocMiddle then
    begin
      Screen.Cursor := crSizeNS;
      ResizeVert := true;
    end else
    begin
      ResizeHorz := true;
      ResizeVert := true;

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
    result := false;
    Screen.Cursor := crDefault;
  end;
end;

//******************************************************************************

procedure TSizeableLabel.HandleMouseEnter(Sender: TObject);
begin
  InSizingHandle := false;
  ResizeInProgress := false;
  MoveInProgress := false;
  ResizeHorz := false;
  ResizeVert := false;
end;

//******************************************************************************

procedure TSizeableLabel.HandleMouseLeave(Sender: TObject);
begin
  InSizingHandle := false;
  ResizeInProgress := false;
  MoveInProgress := false;
  ResizeHorz := false;
  ResizeVert := false;
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
  if EditMode then
  begin
    if not ResizeInProgress then
    begin
      InSizingHandle := Self.IsMouseInSizingHandle(X, Y);
    end;

    if ssLeft in Shift then
    begin
      DeltaX := X - StartX;
      DeltaY := Y - StartY;

      if MoveInProgress then
      begin
        Self.SetBounds(Self.Left + DeltaX,
                       Self.Top + DeltaY,
                       Self.Width,
                       Self.Height);
      end else if ResizeInProgress then
      begin
        if ResizeHorz then
        begin
          if StartX <= HandleWidth then
          begin
            AbsDeltaX := Abs(DeltaX);
            if DeltaX < 0 then
            begin
              // dragging left edge to left (increasing width and decreasing left)
              HostedLabel.Width := HostedLabel.Width + AbsDeltaX;
              Self.SetBounds(Self.Left - AbsDeltaX,
                             Self.Top,
                             Self.Width + AbsDeltaX,
                             Self.Height);
            end else
            begin
              // dragging left edge to right (decreasing width and increasing left)
              HostedLabel.Width := HostedLabel.Width - AbsDeltaX;
              Self.SetBounds(Self.Left + AbsDeltaX,
                             Self.Top,
                             Self.Width - AbsDeltaX,
                             Self.Height);
            end;
          end else
          begin
            HostedLabel.Width := HostedLabel.Width + DeltaX;
            Self.Width := Self.Width + DeltaX;
          end;
        end;

        if ResizeVert then
        begin
          if StartY <= HandleHeight then
          begin
            AbsDeltaY := Abs(DeltaY);
            if DeltaY < 0 then
            begin
              // dragging top up (increasing height and decreasing top)
              HostedLabel.Height := HostedLabel.Height + AbsDeltaY;
              Self.SetBounds(Self.Left,
                             Self.Top - AbsDeltaY,
                             Self.Width,
                             Self.Height + AbsDeltaY);
            end else
            begin
              // dragging top down (decreasing height and increasing top)
              HostedLabel.Height := HostedLabel.Height - AbsDeltaY;
              Self.SetBounds(Self.Left,
                             Self.Top + AbsDeltaY,
                             Self.Width,
                             Self.Height - AbsDeltaY);
            end;
          end else
          begin
            HostedLabel.Height := HostedLabel.Height + DeltaY;
            Self.Height := Self.Height + DeltaY;
          end;
        end;

        StartX := X;
        StartY := Y;
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
  if EditMode then
  begin
    InSizingHandle := Self.IsMouseInSizingHandle(X, Y);

    StartX := X;
    StartY := Y;

    if InSizingHandle then
    begin
      // start of resize
      ResizeInProgress := true;
    end else
    begin
      // start of move
      MoveInProgress := true;
    end;
  end;
end;

//******************************************************************************

procedure TSizeableLabel.HandleMouseUp(Sender: TObject;
                                       Button: TMouseButton;
                                       Shift: TShiftState;
                                       X, Y: Integer);
begin
  if EditMode and ResizeInProgress then
  begin
    ResizeInProgress := false;
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
  Canvas.Brush.Color := Self.Color;
  Canvas.FillRect(ClientRect);

  if EditMode then
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

procedure TSizeableLabel.SetColor(AColor: TColor);
begin
  Self.Color := AColor;
  Self.Invalidate;
end;

//******************************************************************************

procedure TSizeableLabel.SetTextVertical(ATextIsVertical: boolean);
begin
  Self.TextIsVertical := ATextIsVertical;
  if ATextIsVertical then
  begin
    // flip the width and height
    Height := HostedLabel.Width + (2 * HandleWidth);
    Width := HostedLabel.Height + (2 * HandleHeight);
  end;
end;

//******************************************************************************

end.