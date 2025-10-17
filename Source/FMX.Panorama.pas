unit FMX.Panorama;

{ *****************************************************************************
  Copyright (C) 2019 by Thomas Dannert
  Author: Thomas Dannert <thomas@dannert.com>
  Website: www.dannert.com
{ *****************************************************************************
  Panorama3D for Delphi Firemonkey is free software: you can redistribute it
  and/or modify it under the terms of the GNU Lesser General Public License
  version 3as published by the Free Software Foundation and appearing in the
  included file.
  Panorama3D for Delphi Firemonkey is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  Lesser General Public License for more details.
  You should have received a copy of the GNU Lesser General Public License
  along with Dropbox Client Library. If not, see <http://www.gnu.org/licenses.
****************************************************************************** }

interface

uses
  System.Classes, System.Actions, System.Types, System.UITypes, System.UIConsts,
  System.Generics.Collections, System.Generics.Defaults, FMX.Controls, FMX.Types,
  FMX.Objects, FMX.Ani, FMX.Graphics, FMX.StdActns, FMX.Viewport3D,
  FMX.Controls3D, FMX.Objects3D, FMX.InertialMovement, FMX.MaterialSources,
  FMX.Types3D, FMX.Surfaces, FMX.Layers3D, System.Math.Vectors, System.RTLConsts;

{$SCOPEDENUMS ON}

type
  TCustomPanorama3D = class;

  TPanoPlacement = (TopLeft, TopCenter, TopRight, CenterLeft, CenterRight, BottomLeft, BottomCenter, BottomRight);

  TPanoController = class(TControl)
  private
    FPanorama: TCustomPanorama3D;
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
    procedure DoMouseLeave; override;
    procedure DoMouseEnter; override;
    function ArrowRect(const AArrow: Integer): TRectF;
    function FindArrow(X, Y: Single; var AArrow: Integer): Boolean;
  public
    constructor Create(APanorama: TCustomPanorama3D); reintroduce; virtual;
    destructor Destroy; override;
    procedure Paint; override;
    property Panorama: TCustomPanorama3D read FPanorama;
  end;

  TPanoRadar = class(TControl)
  private
    FPanorama: TCustomPanorama3D;
  public
    constructor Create(APanorama: TCustomPanorama3D); reintroduce; virtual;
    destructor Destroy; override;
    procedure Paint; override;
    property Panorama: TCustomPanorama3D read FPanorama;
  end;

  TPanScrollCalculations = class(TAniCalculations)
  private
    [Weak]
    FViewer: TCustomPanorama3D;
  protected
    procedure DoChanged; override;
    procedure DoStart; override;
    procedure DoStop; override;
  public
    constructor Create(AOwner: TPersistent); override;
    property Viewer: TCustomPanorama3D read FViewer;
  end;

  TPanoControlSettings = class(TPersistent)
  private
    FPanorama: TCustomPanorama3D;
    FDefault: TPanoPlacement;
    FPlacement: TPanoPlacement;
    FOffsetX: Integer;
    FOffsetY: Integer;
    FSize: Integer;
    FVisible: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetPlacement(const AValue: TPanoPlacement);
    procedure SetOffsetX(const AValue: Integer);
    procedure SetOffsetY(const AValue: Integer);
    procedure SetSize(const AValue: Integer);
    procedure SetVisible(const AValue: Boolean);
    function IsPlacementStored: Boolean;
  public
    constructor Create(APanorama: TCustomPanorama3D; ADefaultPlacement: TPanoPlacement);
    procedure Assign(Source: TPersistent); override;
    procedure Changed; virtual;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Placement: TPanoPlacement read FPlacement write SetPlacement stored IsPlacementStored;
    property OffsetX: Integer read FOffsetX write SetOffsetX default 32;
    property OffsetY: Integer read FOffsetY write SetOffsetY default 32;
    property Size: Integer read FSize write SetSize default 32;
    property Visible: Boolean read FVisible write SetVisible default True;
  end;

  TBitmapSurfaceBuf = class(TBitmapSurface)
  private
    FCapacity: Integer;
    procedure SetCapacity(const Value: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetSize(const AWidth, AHeight: Integer; const APixelFormat: TPixelFormat = TPixelFormat.None);
    property Capacity: Integer read FCapacity write SetCapacity;
  end;

  TSphere = class(TCustomMesh)
  private
    FSubdivisionsAxes: Integer;
    FSubdivisionsHeight: Integer;
    procedure SetSubdivisionsAxes(const Value: Integer);
    procedure SetSubdivisionsHeight(const Value: Integer);
  protected
    procedure RebuildMesh;
    function DoRayCastIntersect(const RayPos, RayDir: TPoint3D; var Intersection: TPoint3D): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property SubdivisionsAxes: Integer read FSubdivisionsAxes write SetSubdivisionsAxes default 16;
    property SubdivisionsHeight: Integer read FSubdivisionsHeight write SetSubdivisionsHeight default 12;
    property MaterialSource;
    property Cursor default crDefault;
    property DragMode default TDragMode.dmManual;
    property Position;
    property Scale;
    property RotationAngle;
    property Locked default False;
    property Width;
    property Height;
    property Depth;
    property Opacity nodefault;
    property Projection;
    property HitTest default True;
    property VisibleContextMenu default True;
    property TwoSide default False;
    property Visible default True;
    property ZWrite default True;
    property OnDragEnter;
    property OnDragLeave;
    property OnDragOver;
    property OnDragDrop;
    property OnDragEnd;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnKeyDown;
    property OnKeyUp;
    property OnRender;
  end;

  TCustomPanorama3D = class(TControl)
  private
    FAutoAnimate: Boolean;
    FFill: TBrush;
    FDown: Boolean;
    FDownX: Single;
    FDownY: Single;
    FStartY: Single;
    FLastDistance: Integer;
    FMove: Boolean;
    FMouseEvents: Boolean;
    FUpdate: Boolean;
    FViewPort: TViewport3D;
    FCamera: TCamera;
    FSkyBox: TSphere;
    FSkyMat: TTextureMaterialSource;
    FBitmap: TBitmap;
    FRadarCtrl: TControl;
    FRadar: TPanoControlSettings;
    FControllerCtrl: TControl;
    FController: TPanoControlSettings;
    FCenterDummy: TDummy;
    FRotateAnimation: TFloatAnimation;
    FAniCalculations: TAniCalculations;
    FOnChange: TNotifyEvent;
    FSurf: TBitmapSurfaceBuf;
    function GetPlaying: Boolean;
    procedure SetPlaying(const AValue: Boolean);
    function GetCameraX: Single;
    procedure SetCameraX(const AValue: Single);
    function GetCameraY: Single;
    procedure SetCameraY(const AValue: Single);
    function GetCameraZ: Single;
    procedure SetCameraZ(const AValue: Single);
    function GetZoom: Single;
    procedure SetZoom(const AValue: Single);
    procedure SetBitmap(const AValue: TBitmap);
    procedure SetFill(const AValue: TBrush);
    procedure SetRadar(const AValue: TPanoControlSettings);
    procedure SetController(const AValue: TPanoControlSettings);
    procedure DoViewportMouseLeave(Sender: TObject);
    procedure DoViewportMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure DoViewportMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure DoViewportMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure DoViewportMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure DoViewportGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure DoBitmapChanged(Sender: TObject);
    procedure DoFillChanged(Sender: TObject);
    //Animations and mouse events
    procedure DoUpdateAniCalculations(const AAniCalculations: TAniCalculations);
    procedure UpdateAniCalculations;
    //with this routine we stabilizes the z axis so that the camera does not tip over
    function GetNormalizedAngle: Single;
    function GetControlRect(ASettings: TPanoControlSettings): TRectF;
    procedure DoSettingsChanged(Sender: TObject);
    procedure Update;
    procedure FOnAniChanged(Sender: TObject);
  protected
    procedure DoRealign; override;
    procedure Loaded; override;
    procedure Resize; override;
    procedure StartScrolling;
    procedure StopScrolling;
    procedure ScrollingChanged;
    procedure AniMouseDown(const Touch: Boolean; const X, Y: Single); virtual;
    procedure AniMouseMove(const Touch: Boolean; const X, Y: Single); virtual;
    procedure AniMouseUp(const Touch: Boolean; const X, Y: Single); virtual;
    procedure KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState); override;
    procedure Changed; virtual;
    function GetViewWidth: Single;
    function GetViewHeight: Single;
    function GetDefaultSize: TSizeF; override;
    procedure Paint; override;
    property Bitmap: TBitmap read FBitmap write SetBitmap;
    property Camera: TCamera read FCamera;
    property CenterDummy: TDummy read FCenterDummy;
    property Viewport: TViewport3D read FViewport;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Load(Stream: TStream); overload;
    procedure Load(const FileName: string); overload;
    procedure Play;
    procedure Stop;
    procedure MoveLeft;
    procedure MoveRight;
    procedure MoveUp;
    procedure MoveDown;
    procedure ZoomAnimate(const Value: Single);
    property Radar: TPanoControlSettings read FRadar write SetRadar;
    property Controller: TPanoControlSettings read FController write SetController;
    property Playing: Boolean read GetPlaying write SetPlaying;
    property ViewWidth: Single read GetViewWidth;
    property ViewHeight: Single read GetViewHeight;
    property AutoAnimate: Boolean read FAutoAnimate write FAutoAnimate default True;
    property Fill: TBrush read FFill write SetFill;
    property CameraX: Single read GetCameraX write SetCameraX stored False;
    property CameraY: Single read GetCameraY write SetCameraY stored False;
    property CameraZ: Single read GetCameraZ write SetCameraZ stored False;
    property Zoom: Single read GetZoom write SetZoom stored False;
  end;

  TPanorama3D = class(TCustomPanorama3D)
  published
    property OnChange;
    property AutoAnimate;
    property Align;
    /// <summary>
    /// You need to perform the image reflection manually. Bitmap.FlipHorizontal;
    /// </summary>
    property Bitmap;
    property Fill;
    property Controller;
    property Radar;
    property CanFocus default True;
    property Cursor default crDefault;
    property DragMode default TDragMode.dmManual;
    property EnableDragHighlight default True;
    property HitTest;
    property Enabled;
    property Height;
    property Padding;
    property Opacity;
    property Margins;
    property PopupMenu;
    property Position;
    property Scale;
    property Size;
    property TabStop;
    property TabOrder;
    property TouchTargetExpansion;
    property Visible;
    property Width;
    property OnDragEnter;
    property OnDragLeave;
    property OnDragOver;
    property OnDragDrop;
    property OnDragEnd;
    property OnKeyDown;
    property OnKeyUp;
    property OnCanFocus;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnPainting;
    property OnPaint;
    property OnResize;
  end;


  TAnimatorHelper = class helper for TAnimator
    class procedure DetachPropertyAnimation(const Target: TFmxObject; const APropertyName: string);
  end;

var
  ARROW_LEFT: string = 'M63.007,8.985 C63.007,8.011 62.574,7.145 61.924,6.496 L61.924,6.496 L56.511,1.083 C55.862,0.433 54.887,0.000 54.021,0.000 L54.021,0.000 C53.155,0.000 ' + '52.181,0.433 51.531,1.083 L51.531,1.083 L1.083,51.531 C0.433,52.181 0.000,53.155 0.000,54.021 L0.000,54.021 ' + 'C0.000,54.887 0.433,55.862 1.083,56.511 L1.083,56.511 L51.531,106.960 C52.181,107.609 53.155,108.042 54.021,108.042 L54.021,108.042 C54.887,108.042 ' + '55.862,107.609 56.511,106.960 L56.511,106.960 L61.924,101.547 C62.574,100.897 ' + '63.007,99.923 63.007,99.057 L63.007,99.057 ' + 'C63.007,98.191 62.574,97.217 61.924,96.567 L61.924,96.567 L19.378,54.021 L61.924,11.475 C62.574,10.826 63.007,9.852 63.007,8.985 L63.007,8.985 Z';
  ARROW_RIGHT: string = 'M63.007,54.021 C63.007,53.155 62.574,52.181 61.924,51.531 L61.924,51.531 L11.475,1.083 C10.826,0.433 9.852,0.000 8.985,0.000 L8.985,0.000 C8.119,0.000 ' + '7.145,0.433 6.496,1.083 L6.496,1.083 L1.083,6.496 C0.433,7.145 0.000,8.119 0.000,8.985 L0.000,8.985 C0.000,9.852 0.433,10.826 1.083,11.475 L1.083,11.475 L43.628,54.021 L1.083,96.567 C0.433,97.217 0.000,98.191 0.000,99.057 L0.000,99.057 C0.000,100.031 ' + '0.433,100.897 1.083,101.547 L1.083,101.547 L6.496,106.960 C7.145,107.609 8.119,108.042 ' + '8.985,108.042 L8.985,108.042 C9.852,108.042 ' + '10.826,107.609 11.475,106.960 L11.475,106.960 L61.924,56.511 C62.574,55.862 63.007,54.887 63.007,54.021 L63.007,54.021 Z';
  ARROW_UP: string = 'M108.042,54.021 C108.042,53.155 107.609,52.181 106.960,51.531 L106.960,51.531 L56.511,1.083 C55.862,0.433 54.887,0.000 54.021,0.000 L54.021,0.000 ' + 'C53.155,0.000 52.181,0.433 51.531,1.083 L51.531,1.083 L1.083,51.531 C0.433,52.181 0.000,53.155 0.000,54.021 ' + 'L0.000,54.021 C0.000,54.887 0.433,55.862 1.083,56.511 L1.083,56.511 L6.496,61.924 C7.145,62.574 8.119,63.007 8.985,63.007 L8.985,63.007 C9.852,63.007 ' + '10.826,62.574 11.475,61.924 L11.475,61.924 L54.021,19.378 L96.567,61.924 C97.217,62.574 ' + '98.191,63.007 99.057,63.007 L99.057,63.007 ' + 'C100.031,63.007 100.897,62.574 101.547,61.924 L101.547,61.924 L106.960,56.511 C107.609,55.862 108.042,54.887 108.042,54.021 L108.042,54.021 Z';
  ARROW_DOWN: string = 'M108.042,8.985 C108.042,8.119 107.609,7.145 106.960,6.496 L106.960,6.496 L101.547,1.083 C100.897,0.433 99.923,0.000 99.057,0.000 L99.057,0.000 ' + 'C98.191,0.000 97.217,0.433 96.567,1.083 L96.567,1.083 L54.021,43.628 L11.475,1.083 C10.826,0.433 9.852,0.000 ' + '8.985,0.000 L8.985,0.000 C8.011,0.000 7.145,0.433 6.496,1.083 L6.496,1.083 L1.083,6.496 C0.433,7.145 0.000,8.119 0.000,8.985 L0.000,8.985 C0.000,9.852 ' + '0.433,10.826 1.083,11.475 L1.083,11.475 L51.531,61.924 C52.181,62.574 53.155,63.007 ' + '54.021,63.007 L54.021,63.007 C54.887,63.007 55.862,62.574 ' + '56.511,61.924 L56.511,61.924 L106.960,11.475 C107.609,10.826 108.042,9.852 108.042,8.985 L108.042,8.985 Z';
  BUTTON_PAUSE: string = 'M76.214,114.321 C76.214,116.270 74.699,117.786 72.750,117.786 L72.750,117.786 L45.036,117.786 C43.087,117.786 41.571,116.270 41.571,114.321 ' + 'L41.571,114.321 L41.571,51.964 C41.571,50.016 43.087,48.500 45.036,48.500 L45.036,48.500 L72.750,48.500 C74.699,48.500 76.214,50.016 76.214,51.964 L76.214,51.964 L76.214,114.321 Z M124.714,114.321 ' +
    'C124.714,116.270 123.199,117.786 121.250,117.786 L121.250,117.786 L93.536,117.786 C91.587,117.786 90.071,116.270 90.071,114.321 L90.071,114.321 L90.071,51.964 C90.071,50.016 91.587,48.500 ' + '93.536,48.500 L93.536,48.500 L121.250,48.500 C123.199,48.500 124.714,50.016 124.714,51.964 L124.714,51.964 L124.714,114.321 Z M166.286,83.143 C166.286,37.241 129.045,0.000 83.143,0.000 ' + 'L83.143,0.000 C37.241,0.000 0.000,37.241 0.000,83.143 L0.000,83.143 C0.000,129.045 37.241,166.286 83.143,166.286 L83.143,166.286 C129.045,166.286 166.286,129.045 166.286,83.143 L166.286,83.143 Z';
  BUTTON_PLAY: string = 'M83.000,0.000 C37.177,0.000 0.000,37.177 0.000,83.000 L0.000,83.000 C0.000,128.823 37.177,166.000 83.000,166.000 L83.000,166.000 C128.823,166.000 ' + '166.000,128.823 166.000,83.000 L166.000,83.000 C166.000,37.177 128.823,0.000 83.000,0.000 L83.000,0.000 Z M124.500,88.944 L65.708,123.527 C64.628,124.176 63.439,124.500 62.250,124.500 ' +
    'L62.250,124.500 C61.061,124.500 59.872,124.176 58.792,123.635 L58.792,123.635 C56.630,122.339 55.333,120.069 55.333,117.583 L55.333,117.583 L55.333,48.417 C55.333,45.931 56.630,43.661 58.792,42.365 ' + 'L58.792,42.365 C60.953,41.176 63.655,41.176 65.708,42.473 L65.708,42.473 L124.500,77.056 C126.661,78.245 127.958,80.514 127.958,83.000 L127.958,83.000 C127.958,85.486 126.661,87.755 ' + '124.500,88.944 L124.500,88.944 Z';

implementation

uses
  System.Math, FMX.Materials, System.SysUtils;

{ TPanoRadar }

constructor TPanoRadar.Create(APanorama: TCustomPanorama3D);
begin
  inherited Create(APanorama);
  FPanorama := APanorama;
end;

destructor TPanoRadar.Destroy;
begin
  inherited Destroy;
end;

procedure TPanoRadar.Paint;
begin
  const InnerRadius = 4;
  var R := LocalRect;
  var C := R.CenterPoint;
  //S := R.Width / 2;
  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := MakeColor(TAlphaColors.Black, 0.5);
  Canvas.FillEllipse(R, AbsoluteOpacity);
  R := RectF(C.X - InnerRadius, C.Y - InnerRadius, C.X + InnerRadius, C.Y + InnerRadius);
  Canvas.Fill.Color := TAlphaColors.White;
  Canvas.FillEllipse(R, AbsoluteOpacity);
  var S := (LocalRect.Width / 2) - 3;
  R := RectF(C.X - S, C.Y - S, C.X + S, C.Y + S);
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Dash := TStrokeDash.Solid;
  Canvas.Stroke.Thickness := 2;
  Canvas.Stroke.Color := TAlphaColors.White;
  Canvas.DrawEllipse(R, AbsoluteOpacity);

  var Path := TPathData.Create;
  try
    var StartAngle := FPanorama.CameraY - (FPanorama.ViewWidth / 2) - 90;
    if StartAngle < 0 then
      StartAngle := StartAngle + 360;
    var EndAngle := FPanorama.ViewWidth;
    var Radius := (LocalRect.Width / 2) - 6;
    var Thickness := Radius - 6;
    Path.AddArc(C, PointF(Radius, Radius), StartAngle, EndAngle);
    Path.AddArc(C, PointF(Radius - Thickness, Radius - Thickness), StartAngle + EndAngle, -EndAngle);
    Path.ClosePath;
    Canvas.Fill.Color := TAlphaColors.White;
    Canvas.FillPath(Path, AbsoluteOpacity);
  finally
    Path.Free;
  end
end;

{ TPanoController }

constructor TPanoController.Create(APanorama: TCustomPanorama3D);
begin
  inherited Create(APanorama);
  FPanorama := APanorama;
  TabStop := False;
  CanFocus := False;
  AutoCapture := True;
end;

destructor TPanoController.Destroy;
begin
  inherited Destroy;
end;

procedure TPanoController.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  inherited;
  if Button = TMouseButton.mbLeft then
  begin
    var Arrow: Integer;
    if FindArrow(X, Y, Arrow) then
    begin
      case Arrow of
        0:
          FPanorama.MoveUp;
        1:
          FPanorama.MoveDown;
        2:
          FPanorama.MoveLeft;
        3:
          FPanorama.MoveRight;
      else
        FPanorama.Playing := not FPanorama.Playing;
      end;
    end;
    Repaint;
  end;
end;

function TPanoController.ArrowRect(const AArrow: Integer): TRectF;
begin
  var R := LocalRect;
  var C := R.CenterPoint;
  var S := R.Width / 2;
  var V := S * 0.25;
  var P := C;
  case AArrow of
    0: //Up
      P := C - PointF(0, S * 0.7);
    1: //Down
      P := C + PointF(0, S * 0.7);
    2: //Left
      P := C - PointF(S * 0.7, 0);
    3: //Right
      P := C + PointF(S * 0.7, 0);
  else //Middle Button
    V := S * 0.35;
    P := C;
  end;
  Result := RectF(P.X - V, P.Y - V, P.X + V, P.Y + V);
end;

function TPanoController.FindArrow(X, Y: Single; var AArrow: Integer): Boolean;
begin
  Result := False;
  for var i := 0 to 4 do
  begin
    var R := ArrowRect(i);
    R.Inflate(5, 5); //Make a little bit larger for touch
    if R.Contains(PointF(X, Y)) then
    begin
      AArrow := i;
      Result := True;
      Break;
    end;
  end;
end;

procedure TPanoController.DoMouseLeave;
begin
  inherited;
  Repaint;
end;

procedure TPanoController.DoMouseEnter;
begin
  inherited;
  Repaint;
end;

procedure TPanoController.Paint;
begin
  Canvas.Fill.Kind := TBrushKind.Solid;
  if IsMouseOver then
    Canvas.Fill.Color := MakeColor(TAlphaColors.White, 0.8)
  else
    Canvas.Fill.Color := MakeColor(TAlphaColors.White, 0.5);

  var R := LocalRect;
  Canvas.FillEllipse(R, AbsoluteOpacity);

  var Path := TPathData.Create;
  try
    //Draw Arrow Up
    Path.Data := ARROW_UP;
    R := ArrowRect(0);
    Path.FitToRect(R);
    Canvas.Fill.Color := TAlphaColors.Black;
    Canvas.FillPath(Path, AbsoluteOpacity);
    //Draw Arrow Down
    Path.Data := ARROW_DOWN;
    R := ArrowRect(1);
    Path.FitToRect(R);
    Canvas.FillPath(Path, AbsoluteOpacity);
    //Draw Arrow Left
    Path.Data := ARROW_LEFT;
    R := ArrowRect(2);
    Path.FitToRect(R);
    Canvas.FillPath(Path, AbsoluteOpacity);
    //Draw Arrow Right
    Path.Data := ARROW_RIGHT;
    R := ArrowRect(3);
    Path.FitToRect(R);
    Canvas.FillPath(Path, AbsoluteOpacity);
    //Draw Play
    if FPanorama.Playing then
      Path.Data := BUTTON_PAUSE
    else
      Path.Data := BUTTON_PLAY;
    R := ArrowRect(4);
    Path.FitToRect(R);
    Canvas.FillPath(Path, AbsoluteOpacity);
  finally
    Path.Free;
  end
end;

{ TPanScrollCalculations }

constructor TPanScrollCalculations.Create(AOwner: TPersistent);
begin
  if AOwner is not TCustomPanorama3D then
    raise EArgumentException.Create('ArgumentInvalid');
  inherited Create(AOwner);
  FViewer := TCustomPanorama3D(AOwner);
end;

procedure TPanScrollCalculations.DoChanged;
begin
  inherited;
  if Assigned(FViewer) and (not (csDestroying in FViewer.ComponentState)) then
    FViewer.ScrollingChanged;
end;

procedure TPanScrollCalculations.DoStart;
begin
  inherited;
  if Assigned(FViewer) and (not (csDestroying in FViewer.ComponentState)) then
    FViewer.StartScrolling;
end;

procedure TPanScrollCalculations.DoStop;
begin
  inherited;
  if Assigned(FViewer) and (not (csDestroying in FViewer.ComponentState)) then
    FViewer.StopScrolling;
end;

{ TCustomPanorama3D }

constructor TCustomPanorama3D.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSurf := TBitmapSurfaceBuf.Create;
  FSurf.Capacity := 400 * 1024 * 1024;
  SetAcceptsControls(True);
  AutoCapture := True;
  Cursor := crDefault;
  HitTest := True;
  CanFocus := True;
  FStartY := 0;
  FAutoAnimate := True;
  FFill := TBrush.Create(TBrushKind.Solid, TAlphaColors.Black);
  FFill.OnChanged := DoFillChanged;
  FBitmap := TBitmap.Create;
  FBitmap.OnChange := DoBitmapChanged;
  FRotateAnimation := nil;
  FLastDistance := 0;
  FViewport := TViewport3D.Create(Self);
  FViewport.Parent := Self;
  FViewPort.Stored := False;
  FViewPort.Locked := True;
  FViewPort.Visible := False;
  FViewPort.HitTest := True;
  FViewport.Color := TAlphaColors.Null;
  FViewPort.UsingDesignCamera := False;
  FViewport.Touch.InteractiveGestures := [TInteractiveGesture.Zoom];
  FViewPort.OnMouseDown := DoViewportMouseDown;
  FViewPort.OnMouseMove := DoViewportMouseMove;
  FViewPort.OnMouseUp := DoViewportMouseUp;
  FViewPort.OnMouseLeave := DoViewportMouseLeave;
  FViewPort.OnMouseWheel := DoViewportMouseWheel;
  FViewport.OnGesture := DoViewportGesture;
  FViewPort.Multisample := TMultisample.FourSamples;

  FSkyBox := TSphere.Create(FViewport);
  FSkyBox.Parent := FViewport;
  FSkyBox.TwoSide := True;
  FSkyBox.SubDivisionsAxes := 100;
  FSkyBox.SubdivisionsHeight := 100;
  FSkyBox.Width := 1000;
  FSkyBox.Height := 1000;
  FSkyBox.Depth := 1000;
  FSkyBox.ZWrite := True;
  FSkyBox.Locked := True;
  FSkyBox.HitTest := False;
  FSkyBox.Stored := False;
  FSkyBox.Projection := TProjection.Camera;

  FSkyMat := TTextureMaterialSource.Create(FSkyBox);
  FSkyMat.Parent := FSkyBox;
  FSkyMat.Stored := False;
  FSkyBox.MaterialSource := FSkyMat;

  FCenterDummy := TDummy.Create(Self);
  FCenterDummy.Parent := FViewPort;
  FCenterDummy.Stored := False;
  FCenterDummy.Locked := True;
  FCenterDummy.Projection := TProjection.Camera;

  FCamera := TCamera.Create(Self);
  FCamera.Locked := True;
  FCamera.Stored := False;
  FCamera.Parent := FCenterDummy;
  FCamera.Target := FCenterDummy;
  FCamera.Position.Z := -100;
  FCamera.AngleOfView := 50;
  FCamera.Projection := TProjection.Camera;
  FCamera.ZWrite := True;
  FViewPort.Camera := FCamera;

  FRadar := TPanoControlSettings.Create(Self, TPanoPlacement.TopRight);
  FRadar.OnChange := DoSettingsChanged;
  FRadarCtrl := TPanoRadar.Create(Self);
  FRadarCtrl.Parent := Self;
  FRadarCtrl.Locked := True;
  FRadarCtrl.Stored := False;

  FController := TPanoControlSettings.Create(Self, TPanoPlacement.BottomRight);
  FController.OnChange := DoSettingsChanged;
  FControllerCtrl := TPanoController.Create(Self);
  FControllerCtrl.Parent := Self;
  FControllerCtrl.Locked := True;
  FControllerCtrl.Stored := False;

  UpdateAniCalculations;
end;

destructor TCustomPanorama3D.Destroy;
begin
  FreeAndNil(FRotateAnimation);
  FreeAndNil(FCamera);
  FreeAndNil(FCenterDummy);
  FreeAndNil(FSkyMat);
  FreeAndNil(FSkyBox);
  FreeAndNil(FViewport);
  FreeAndNil(FBitmap);
  FreeAndNil(FFill);
  FreeAndNil(FRadar);
  FreeAndNil(FController);
  FreeAndNil(FSurf);
  if Assigned(FAniCalculations) then
    FreeAndNil(FAniCalculations);
  inherited Destroy;
end;

procedure TCustomPanorama3D.SetRadar(const AValue: TPanoControlSettings);
begin
  FRadar.Assign(AValue);
end;

procedure TCustomPanorama3D.SetController(const AValue: TPanoControlSettings);
begin
  FController.Assign(AValue);
end;

procedure TCustomPanorama3D.DoSettingsChanged(Sender: TObject);
begin
  Realign;
end;

procedure TCustomPanorama3D.SetFill(const AValue: TBrush);
begin
  FFill.Assign(AValue);
end;

procedure TCustomPanorama3D.DoFillChanged(Sender: TObject);
begin
  Repaint;
end;

function TCustomPanorama3D.GetDefaultSize: TSizeF;
begin
  Result.cx := 200;
  Result.cy := 200;
end;

function TCustomPanorama3D.GetZoom: Single;
begin
  Result := (FCamera.AngleOfView - 25) * 2;
end;

procedure TCustomPanorama3D.SetZoom(const AValue: Single);
begin
  if AValue <> GetZoom then
  begin
    FCamera.AngleOfView := 25 + (AValue * 0.5);
    Changed;
  end;
end;

function TCustomPanorama3D.GetCameraX: Single;
begin
  Result := FCenterDummy.RotationAngle.X;
end;

procedure TCustomPanorama3D.SetCameraX(const AValue: Single);
begin
  if AValue <> GetCameraX then
  begin
    var Y := GetCameraY;
    FCenterDummy.ResetRotationAngle;
    FCenterDummy.RotationAngle.Z := 0;
    FCenterDummy.RotationAngle.Y := Y;
    FCenterDummy.RotationAngle.X := AValue;
    FCenterDummy.RotationAngle.Z := GetNormalizedAngle;
    Changed;
  end;
end;

function TCustomPanorama3D.GetCameraY: Single;
begin
  Result := FCenterDummy.RotationAngle.Y;
end;

procedure TCustomPanorama3D.SetCameraY(const AValue: Single);
begin
  var Y := DegNormalize(AValue + FStartY);
  if Y <> GetCameraY then
  begin
    var X := GetCameraX;
    FCenterDummy.ResetRotationAngle;
    FCenterDummy.RotationAngle.Z := 0;
    FCenterDummy.RotationAngle.Y := Y;
    FCenterDummy.RotationAngle.X := X;
    FCenterDummy.RotationAngle.Z := GetNormalizedAngle;
    Changed;
  end;
end;

function TCustomPanorama3D.GetCameraZ: Single;
begin
  Result := FCenterDummy.RotationAngle.Z;
end;

procedure TCustomPanorama3D.SetCameraZ(const AValue: Single);
begin
  if AValue <> GetCameraZ then
  begin
    FCenterDummy.RotationAngle.Z := AValue;
    Changed;
  end;
end;

function TCustomPanorama3D.GetPlaying: Boolean;
begin
  Result := Assigned(FRotateAnimation) and FRotateAnimation.Running;
end;

procedure TCustomPanorama3D.SetPlaying(const AValue: Boolean);
begin
  if AValue = GetPlaying then
    Exit;
  if AValue then
    Play
  else
    Stop;
end;

procedure TCustomPanorama3D.Play;
begin
  if Assigned(FRotateAnimation) and FRotateAnimation.Running then
    Exit;
  if not Assigned(FRotateAnimation) then
  begin
    FRotateAnimation := TFloatAnimation.Create(Self);
    FRotateAnimation.Parent := Self;
    FRotateAnimation.Stored := False;
    FRotateAnimation.AnimationType := TAnimationType.InOut;
    FRotateAnimation.Interpolation := TInterpolationType.Sinusoidal;
    FRotateAnimation.Loop := True;
    FRotateAnimation.Duration := 50;
    FRotateAnimation.AutoReverse := True;
    FRotateAnimation.PropertyName := 'CameraY';
    FRotateAnimation.StartValue := 0;
    FRotateAnimation.StopValue := 360;
  end;
  FStartY := CameraY;
  FRotateAnimation.Start;
end;

procedure TCustomPanorama3D.Stop;
begin
  if Assigned(FRotateAnimation) then
  begin
    FRotateAnimation.StopAtCurrent;
    FStartY := 0;
  end;
end;

procedure TCustomPanorama3D.FOnAniChanged(Sender: TObject);
begin
  //FViewPort.Repaint;
end;

procedure TCustomPanorama3D.DoUpdateAniCalculations(const AAniCalculations: TAniCalculations);
begin
  AAniCalculations.TouchTracking := [ttVertical, ttHorizontal];
  AAniCalculations.Animation := True;
  AAniCalculations.BoundsAnimation := False;
  AAniCalculations.AutoShowing := False;
  {$IF CompilerVersion < 37}
  AAniCalculations.Interval := 1;
  {$ENDIF}
  AAniCalculations.OnChanged := FOnAniChanged;
end;

procedure TCustomPanorama3D.UpdateAniCalculations;
begin
  if csDestroying in ComponentState then
    Exit;
  if FAniCalculations = nil then
    FAniCalculations := TPanScrollCalculations.Create(Self);
  FAniCalculations.BeginUpdate;
  try
    DoUpdateAniCalculations(FAniCalculations);
  finally
    FAniCalculations.EndUpdate;
  end;
end;

procedure TCustomPanorama3D.StartScrolling;
begin
  if Assigned(FViewport.Scene) then
    FViewport.Scene.ChangeScrollingState(FViewport, True);
end;

procedure TCustomPanorama3D.StopScrolling;
begin
  if Assigned(FViewport.Scene) then
    FViewport.Scene.ChangeScrollingState(nil, False);
end;

procedure TCustomPanorama3D.AniMouseDown(const Touch: Boolean; const X, Y: Single);
begin
  if not Assigned(FAniCalculations) then
    Exit;
  FAniCalculations.Averaging := Touch;
  FAniCalculations.MouseDown(X, Y);
end;

procedure TCustomPanorama3D.AniMouseMove(const Touch: Boolean; const X, Y: Single);
begin
  if not Assigned(FAniCalculations) then
    Exit;
  FAniCalculations.MouseMove(X, Y);
  if FAniCalculations.Moved then
    TPanScrollCalculations(FAniCalculations).Shown := True;
end;

procedure TCustomPanorama3D.AniMouseUp(const Touch: Boolean; const X, Y: Single);
begin
  if not Assigned(FAniCalculations) then
    Exit;
  FAniCalculations.MouseUp(X, Y);
  if (FAniCalculations.LowVelocity) or (not FAniCalculations.Animation) then
    TPanScrollCalculations(FAniCalculations).Shown := False;
end;

procedure TCustomPanorama3D.KeyDown(var Key: Word; var KeyChar: System.WideChar; Shift: TShiftState);
begin
  inherited;
  case Key of
    vkUp:
      MoveUp;
    vkDown:
      MoveDown;
    vkLeft:
      MoveLeft;
    vkRight:
      MoveRight;
    vkSpace:
      Playing := not Playing;
  end;
end;

function TCustomPanorama3D.GetNormalizedAngle: Single;

  function AngleOfPoints(AP1, AP2: TPointF): Single;
  begin
    var xDiff := AP2.X - AP1.X;
    var yDiff := AP2.Y - AP1.Y;
    Result := System.Math.ArcTan2(yDiff, xDiff) * (360 / PI);
    if Result < 0 then
      Result := 360 + Result;
  end;

begin
  var CP := FCamera.AbsoluteToLocal3D(FCenterDummy.LocalToAbsolute3D(Point3D(0, 0, 0)));
  var P1 := FCamera.LocalToAbsolute3D(Point3D(CP.X - 500, CP.Y, CP.Z));
  var P2 := FCamera.LocalToAbsolute3D(Point3D(CP.X + 500, CP.Y, CP.Z));
  var A := AngleOfPoints(PointF(P1.X, P1.Y), PointF(P2.X, P2.Y));
  Result := DegNormalize(CenterDummy.RotationAngle.Z - A);
  if Round(Result * 100) = 36000 then
    Result := 0;
end;

procedure TCustomPanorama3D.DoViewportMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  if WheelDelta > 0 then
    Zoom := Max(Zoom - 5, 0)
  else
    Zoom := Min(Zoom + 5, 100);
end;

procedure TCustomPanorama3D.ZoomAnimate(const Value: Single);
begin
  StopPropertyAnimation('Zoom');
  TAnimator.AnimateFloat(Self, 'Zoom', Value);
end;

procedure TCustomPanorama3D.DoViewportMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if not Assigned(FAniCalculations) then
    Exit;
  if TabStop and CanFocus then
    SetFocus;
  Stop;
  case Button of
    TMouseButton.mbLeft:
      begin
        FMouseEvents := True;
        FDown := True;
        FMove := (Button = TMouseButton.mbRight);
        FViewport.Cursor := crSize;
        var RayPos, RayDir: TVector3D;
        FCamera.Context.Pick(X, Y, TProjection.Screen, RayPos, RayDir);
        FDownX := X;
        FDownY := Y;
        var PT := TPointD.Create(FDownX, FDownY);
        FAniCalculations.ViewportPosition.SetLocation(PT);
        AniMouseDown(ssTouch in Shift, X, Y);
      end;
    TMouseButton.mbRight:
      begin
        StopPropertyAnimation('Zoom');
        if Zoom > 75 then
          TAnimator.AnimateFloat(Self, 'Zoom', 50)
        else if Zoom > 25 then
          TAnimator.AnimateFloat(Self, 'Zoom', 0)
        else
          TAnimator.AnimateFloat(Self, 'Zoom', 100);
      end;
  end;
end;

function TCustomPanorama3D.GetViewWidth: Single;
begin
  Result := 1;
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  var RayPos, RayDir: TVector3D;
  FCamera.Context.Pick(0, 0, TProjection.Camera, RayPos, RayDir);
  var P1 := TPoint3D(RayPos + RayDir * RayPos.Length);
  P1 := FCenterDummy.AbsoluteToLocal3D(P1);
  FCamera.Context.Pick(FViewport.Width, 0, TProjection.Camera, RayPos, RayDir);
  var P2 := TPoint3D(RayPos + RayDir * RayPos.Length);
  P2 := FCenterDummy.AbsoluteToLocal3D(P2);
  Result := P2.X - P1.X;
end;

function TCustomPanorama3D.GetViewHeight: Single;
begin
  Result := 1;
  if (csLoading in ComponentState) or (csDestroying in ComponentState) then
    Exit;
  var RayPos, RayDir: TVector3D;
  FCamera.Context.Pick(0, 0, TProjection.Camera, RayPos, RayDir);
  var P1 := TPoint3D(RayPos + RayDir * RayPos.Length);
  P1 := FCenterDummy.AbsoluteToLocal3D(P1);
  FCamera.Context.Pick(0, FViewport.Height, TProjection.Camera, RayPos, RayDir);
  var P2 := TPoint3D(RayPos + RayDir * RayPos.Length);
  P2 := FCenterDummy.AbsoluteToLocal3D(P2);
  Result := P2.Y - P1.Y;
end;

procedure TCustomPanorama3D.DoViewPortMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
begin
  var RayPos, RayDir: TVector3D;
  FCamera.Context.Pick(X, Y, TProjection.Camera, RayPos, RayDir);
  var P := TPoint3D(RayPos + RayDir * RayPos.Length);
  P := FCenterDummy.AbsoluteToLocal3D(P);
  if not Assigned(FAniCalculations) then
    Exit;
  FMouseEvents := True;
  if FAniCalculations.Down then
    AniMouseMove(ssTouch in Shift, X, Y);
end;

procedure TCustomPanorama3D.DoViewportGesture(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  if EventInfo.GestureID = igiZoom then
  begin
    if TInteractiveGestureFlag.gfBegin in EventInfo.Flags then
      FLastDistance := 0;
    if (not (TInteractiveGestureFlag.gfBegin in EventInfo.Flags)) and (not (TInteractiveGestureFlag.gfEnd in EventInfo.Flags)) then
    begin
      if EventInfo.Distance - FLastDistance > 0 then
        Zoom := Max(Zoom - 2, 0)
      else
        Zoom := Min(Zoom + 2, 100);
      FLastDistance := EventInfo.Distance;
    end;
  end;
end;

procedure TCustomPanorama3D.ScrollingChanged;
begin
  FUpdate := True;
  try
    var Y := DegNormalize(CameraY + (FAniCalculations.ViewportPosition.X - FDownX) * 0.1);
    var X := DegNormalize(CameraX - (FAniCalculations.ViewportPosition.Y - FDownY) * 0.1);
    FCenterDummy.ResetRotationAngle;
    FCenterDummy.RotationAngle.Z := 0;
    FCenterDummy.RotationAngle.Y := Y;
    FCenterDummy.RotationAngle.X := Min(180, Max(5, DegNormalize(X + 90))) - 90;
    var Z := GetNormalizedAngle;
    FCenterDummy.RotationAngle.Z := Z;
    FDownX := FAniCalculations.ViewportPosition.X;
    FDownY := FAniCalculations.ViewportPosition.Y;
    Changed;
  finally
    FUpdate := False;
  end;
end;

procedure TCustomPanorama3D.Resize;
begin
  inherited;
  Changed;
end;

procedure TCustomPanorama3D.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TCustomPanorama3D.DoViewportMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if not Assigned(FAniCalculations) then
    Exit;
  if FAniCalculations.Down then
  begin
    FMouseEvents := True;
    if Button = TMouseButton.mbLeft then
      AniMouseUp(ssTouch in Shift, X, Y);
    FDown := False;
  end;
  FViewport.Cursor := crDefault;
end;

procedure TCustomPanorama3D.DoViewportMouseLeave(Sender: TObject);
begin
  if not Assigned(FAniCalculations) then
    Exit;
  if FMouseEvents and FAniCalculations.Down then
  begin
    FAniCalculations.MouseLeave;
    if FAniCalculations.LowVelocity or not FAniCalculations.Animation then
      TPanScrollCalculations(FAniCalculations).Shown := False;
  end;
end;

procedure TCustomPanorama3D.Load(const FileName: string);
begin
  var Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Load(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TCustomPanorama3D.Loaded;
begin
  inherited;
  Realign;
end;

procedure TCustomPanorama3D.Paint;
begin
  Canvas.FillRect(LocalRect, 0, 0, [], 1, FFill);
end;

function TCustomPanorama3D.GetControlRect(ASettings: TPanoControlSettings): TRectF;
begin
  case ASettings.Placement of
    TPanoPlacement.TopLeft:
      Result.TopLeft := PointF(ASettings.OffsetX, ASettings.OffsetY);
    TPanoPlacement.TopCenter:
      Result.TopLeft := PointF((Width / 2) - (ASettings.Size / 2), ASettings.OffsetY);
    TPanoPlacement.TopRight:
      Result.TopLeft := PointF(Width - ASettings.OffsetX - ASettings.Size, ASettings.OffsetY);
    TPanoPlacement.CenterLeft:
      Result.TopLeft := PointF(ASettings.OffsetX, (Height / 2) - (ASettings.Size / 2));
    TPanoPlacement.CenterRight:
      Result.TopLeft := PointF(Width - ASettings.OffsetX - ASettings.Size, (Height / 2) - (ASettings.Size / 2));
    TPanoPlacement.BottomLeft:
      Result.TopLeft := PointF(ASettings.OffsetX, Height - ASettings.Size - ASettings.OffsetY);
    TPanoPlacement.BottomCenter:
      Result.TopLeft := PointF((Width / 2) - (ASettings.Size / 2), Height - ASettings.Size - ASettings.OffsetY);
    TPanoPlacement.BottomRight:
      Result.TopLeft := PointF(Width - ASettings.OffsetX - ASettings.Size, Height - ASettings.Size - ASettings.OffsetY);
  else
    Result.TopLeft := PointF(0, 0);
  end;
  Result.BottomRight := Result.TopLeft + PointF(ASettings.Size, ASettings.Size);
end;

procedure TCustomPanorama3D.DoRealign;
begin
  inherited;
  if FDisableAlign or (csDestroying in ComponentState) then
    Exit;
  FDisableAlign := True;
  try
    FViewPort.SetBounds(0, 0, Width, Height);
    if not FRadar.Visible then
      FRadarCtrl.Visible := False
    else
    begin
      var R := GetControlRect(FRadar);
      FRadarCtrl.SetBounds(R.Left, R.Top, R.Width, R.Height);
      FRadarCtrl.Visible := True;
    end;
    if not FController.Visible then
      FControllerCtrl.Visible := False
    else
    begin
      var R := GetControlRect(FController);
      FControllerCtrl.SetBounds(R.Left, R.Top, R.Width, R.Height);
      FControllerCtrl.Visible := True;
    end;
  finally
    FDisableAlign := False;
  end;
end;

procedure TCustomPanorama3D.MoveLeft;
begin
  Stop;
  TAnimator.DetachPropertyAnimation(Self, 'CameraY');
  //StopPropertyAnimation('CameraY');
  TAnimator.AnimateFloat(Self, 'CameraY', CameraY - 90, 1, TAnimationType.InOut, TInterpolationType.Cubic);
end;

procedure TCustomPanorama3D.MoveRight;
begin
  Stop;
  TAnimator.DetachPropertyAnimation(Self, 'CameraY');
  //StopPropertyAnimation('CameraY');
  TAnimator.AnimateFloat(Self, 'CameraY', CameraY + 90, 1, TAnimationType.InOut, TInterpolationType.Cubic);
end;

procedure TCustomPanorama3D.MoveUp;
begin
  Stop;
  TAnimator.DetachPropertyAnimation(Self, 'CameraX');
  //StopPropertyAnimation('CameraX');
  TAnimator.AnimateFloat(Self, 'CameraX', CameraX + 45, 1, TAnimationType.InOut, TInterpolationType.Cubic);
end;

procedure TCustomPanorama3D.MoveDown;
begin
  Stop;
  TAnimator.DetachPropertyAnimation(Self, 'CameraX');
  //StopPropertyAnimation('CameraX');
  TAnimator.AnimateFloat(Self, 'CameraX', CameraX - 45, 1, TAnimationType.InOut, TInterpolationType.Cubic);
end;

procedure TCustomPanorama3D.SetBitmap(const AValue: TBitmap);
begin
  FBitmap.Assign(AValue);
end;

procedure TCustomPanorama3D.Update;
begin
  FCenterDummy.ResetRotationAngle;
  FCenterDummy.RotationAngle.Z := 0;
  FCenterDummy.RotationAngle.Y := 270;
  FCenterDummy.RotationAngle.X := 0;
  FCenterDummy.RotationAngle.Z := GetNormalizedAngle;
  FCamera.Position.Z := -100;
  FCamera.Position.Y := 0;
  FCamera.Position.X := 0;

  if TTextureMaterial(FSkyMat.Material).Texture.IsEmpty then
    FViewPort.Visible := False
  else
  begin
    FViewPort.Visible := True;
    if not (csDesigning in ComponentState) and FAutoAnimate then
      Play;
  end;
  Repaint;
end;

procedure TCustomPanorama3D.Load(Stream: TStream);
begin
  if not Assigned(TTextureMaterial(FSkyMat.Material).Texture) then
    TTextureMaterial(FSkyMat.Material).Texture := TTexture.Create;

  if TBitmapCodecManager.LoadFromStream(Stream, FSurf, Min(8192, Canvas.GetAttribute(TCanvasAttribute.MaxBitmapSize))) then
  begin
    FSurf.Mirror;
    TTextureMaterial(FSkyMat.Material).Texture.Assign(FSurf);
  end
  else
    raise EBitmapLoadingFailed.Create('error surface load');

  Update;
end;

procedure TCustomPanorama3D.DoBitmapChanged(Sender: TObject);
begin
  FSkyMat.Texture.Assign(FBitmap);
  Update;
end;

{ TPanoControlSettings }

constructor TPanoControlSettings.Create(APanorama: TCustomPanorama3D; ADefaultPlacement: TPanoPlacement);
begin
  inherited Create;
  FPanorama := APanorama;
  FDefault := ADefaultPlacement;
  FPlacement := FDefault;
  FOffsetX := 32;
  FOffsetY := 32;
  FSize := 72;
  FVisible := True;
end;

procedure TPanoControlSettings.Assign(Source: TPersistent);
begin
  if Source is not TPanoControlSettings then
  begin
    inherited;
    Exit;
  end;
  FDefault := TPanoControlSettings(Source).FDefault;
  FPlacement := TPanoControlSettings(Source).FPlacement;
  FOffsetX := TPanoControlSettings(Source).FOffsetX;
  FOffsetY := TPanoControlSettings(Source).FOffsetY;
  FSize := TPanoControlSettings(Source).FSize;
  FVisible := TPanoControlSettings(Source).FVisible;
end;

procedure TPanoControlSettings.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPanoControlSettings.SetPlacement(const AValue: TPanoPlacement);
begin
  if AValue <> FPlacement then
  begin
    FPlacement := AValue;
    Changed;
  end;
end;

procedure TPanoControlSettings.SetOffsetX(const AValue: Integer);
begin
  if AValue <> FOffsetX then
  begin
    FOffsetX := Max(0, AValue);
    Changed;
  end;
end;

procedure TPanoControlSettings.SetOffsetY(const AValue: Integer);
begin
  if AValue <> FOffsetY then
  begin
    FOffsetY := Max(0, AValue);
    Changed;
  end;
end;

procedure TPanoControlSettings.SetSize(const AValue: Integer);
begin
  if AValue <> FSize then
  begin
    FSize := Max(48, AValue);
    Changed;
  end;
end;

procedure TPanoControlSettings.SetVisible(const AValue: Boolean);
begin
  if AValue <> FVisible then
  begin
    FVisible := AValue;
    Changed;
  end;
end;

function TPanoControlSettings.IsPlacementStored: Boolean;
begin
  Result := FPlacement <> FDefault;
end;

{ TSphere }

constructor TSphere.Create(AOwner: TComponent);
begin
  inherited;
  FSubdivisionsAxes := 16;
  FSubdivisionsHeight := 12;
  RebuildMesh;
end;

procedure TSphere.RebuildMesh;
var
  A, H, AA, HH: Integer;
  Theta, Phi: Single;
  DTheta, DPhi: Single;
  ThetaSin, ThetaCos: Double;
  PhiSin, PhiCos: Double;
  IdxCount: Integer;
  VerticesWidth: Integer;
begin
  VerticesWidth := (FSubdivisionsAxes + 1);
  Data.VertexBuffer.Length := (FSubdivisionsHeight + 1) * VerticesWidth - 1;
  Data.IndexBuffer.Length := (FSubdivisionsHeight - 2) * FSubdivisionsAxes * 6 + (FSubdivisionsAxes * 3) + (FSubdivisionsAxes * 3);
  DTheta := DegToRad(180) / FSubdivisionsHeight;
  DPhi := DegToRad(360) / FSubdivisionsAxes;
  IdxCount := 0;
  // fill indices
  Theta := -DegToRad(90);
  for H := 0 to FSubdivisionsHeight - 1 do
  begin
    Phi := 0;
    for A := 0 to FSubdivisionsAxes - 1 do
    begin
      SinCos(Theta, ThetaSin, ThetaCos);
      SinCos(Phi, PhiSin, PhiCos);
      Data.VertexBuffer.Vertices[A + (H * VerticesWidth)] := Point3D(ThetaCos * PhiCos * 0.5, ThetaSin * 0.5, ThetaCos * PhiSin * 0.5);
      Data.VertexBuffer.TexCoord0[A + (H * VerticesWidth)] := PointF(A / FSubdivisionsAxes, H / FSubdivisionsHeight);
      Data.VertexBuffer.Normals[A + (H * VerticesWidth)] := Point3D(ThetaCos * PhiCos, ThetaSin, ThetaCos * PhiSin).Normalize;
      if A = 0 then
      begin
        Data.VertexBuffer.Vertices[FSubdivisionsAxes + (H * VerticesWidth)] := Point3D(ThetaCos * PhiCos * 0.5, ThetaSin * 0.5, ThetaCos * PhiSin * 0.5);
        Data.VertexBuffer.TexCoord0[FSubdivisionsAxes + (H * VerticesWidth)] := PointF(1, H / FSubdivisionsHeight);
        Data.VertexBuffer.Normals[FSubdivisionsAxes + (H * VerticesWidth)] := Point3D(ThetaCos * PhiCos, ThetaSin, ThetaCos * PhiSin).Normalize;
      end;
      AA := A + 1;
      HH := H + 1;
      if H = 0 then
      begin
        Data.VertexBuffer.TexCoord0[A + (H * VerticesWidth)] := PointF((A + 0.5) / FSubdivisionsAxes, 0);
        Data.IndexBuffer.Indices[IdxCount + 0] := A;
        Data.IndexBuffer.Indices[IdxCount + 1] := AA + (HH * VerticesWidth);
        Data.IndexBuffer.Indices[IdxCount + 2] := A + (HH * VerticesWidth);
        IdxCount := IdxCount + 3;
      end
      else if H = FSubdivisionsHeight - 1 then
      begin
        Data.VertexBuffer.Vertices[A + (FSubdivisionsHeight * VerticesWidth)] := Point3D(0, 0.5, 0);
        Data.VertexBuffer.TexCoord0[A + (FSubdivisionsHeight * VerticesWidth)] := PointF((A + 0.5) / FSubdivisionsAxes, 1);
        Data.VertexBuffer.Normals[A + (FSubdivisionsHeight * VerticesWidth)] := Point3D(0, 1.0, 0);

        Data.IndexBuffer.Indices[IdxCount + 0] := A + (H * VerticesWidth);
        Data.IndexBuffer.Indices[IdxCount + 1] := AA + (H * VerticesWidth);
        Data.IndexBuffer.Indices[IdxCount + 2] := A + (HH * VerticesWidth);
        IdxCount := IdxCount + 3;
      end
      else
      begin
        Data.IndexBuffer.Indices[IdxCount + 0] := A + (H * VerticesWidth);
        Data.IndexBuffer.Indices[IdxCount + 1] := AA + (HH * VerticesWidth);
        Data.IndexBuffer.Indices[IdxCount + 2] := A + (HH * VerticesWidth);
        Data.IndexBuffer.Indices[IdxCount + 3] := A + (H * VerticesWidth);
        Data.IndexBuffer.Indices[IdxCount + 4] := AA + (H * VerticesWidth);
        Data.IndexBuffer.Indices[IdxCount + 5] := AA + (HH * VerticesWidth);
        IdxCount := IdxCount + 6;
      end;
      Phi := Phi + DPhi;
    end;
    Theta := Theta + DTheta;
  end;
end;

function TSphere.DoRayCastIntersect(const RayPos, RayDir: TPoint3D; var Intersection: TPoint3D): Boolean;
var
  NearIntersectionPoint, FarIntersectionPoint: TPoint3D;
  LRadius: Single;
begin
  // Calling inherited will search through the MeshData for intersection. This is
  // wasted effort for such a simple shape.
  Result := False;
  case WrapMode of
    TMeshWrapMode.Original:
      begin
        Result := RayCastEllipsoidIntersect(RayPos, RayDir, TPoint3D.Zero, 0.5 * Width, 0.5 * Height, 0.5 * Depth,
          NearIntersectionPoint, FarIntersectionPoint) > 0;
        if Result then
          Intersection := TPoint3D(LocalToAbsoluteVector(NearIntersectionPoint));
      end;
    TMeshWrapMode.Resize:
      begin
        Result := RayCastEllipsoidIntersect(RayPos, RayDir, TPoint3D.Zero, 0.5, 0.5, 0.5,
          NearIntersectionPoint, FarIntersectionPoint) > 0;
        if Result then
          Intersection := TPoint3D(LocalToAbsoluteVector(NearIntersectionPoint));
      end;
    TMeshWrapMode.Fit:
      begin
        LRadius := Min(0.5 * Width, 0.5 * Height);
        LRadius := Min(0.5 * Depth, LRadius);
        Result := RayCastEllipsoidIntersect(RayPos, RayDir, TPoint3D.Zero, LRadius, LRadius, LRadius,
          NearIntersectionPoint, FarIntersectionPoint) > 0;
        if Result then
          Intersection := TPoint3D(LocalToAbsoluteVector(NearIntersectionPoint));
      end;
    TMeshWrapMode.Stretch:
      begin
        Result := RayCastEllipsoidIntersect(RayPos, RayDir, TPoint3D.Zero, Width / 2, Height / 2, Depth / 2,
          NearIntersectionPoint, FarIntersectionPoint) > 0;
        if Result then
          Intersection := TPoint3D(LocalToAbsoluteVector(NearIntersectionPoint));
      end;
  end;
end;

procedure TSphere.SetSubdivisionsAxes(const Value: Integer);
begin
  if FSubdivisionsAxes <> Value then
  begin
    FSubdivisionsAxes := Value;
    if FSubdivisionsAxes < 3 then
      FSubdivisionsAxes := 3;
    if FSubdivisionsAxes > 500 then
      FSubdivisionsAxes := 500;
    RebuildMesh;
  end;
end;

procedure TSphere.SetSubdivisionsHeight(const Value: Integer);
begin
  if FSubdivisionsHeight <> Value then
  begin
    FSubdivisionsHeight := Value;
    if FSubdivisionsHeight < 2 then
      FSubdivisionsHeight := 2;
    if FSubdivisionsHeight > 500 then
      FSubdivisionsHeight := 500;
    RebuildMesh;
  end;
end;

{ TBitmapSurfaceBuf }

constructor TBitmapSurfaceBuf.Create;
begin
  inherited;
  FCapacity := 0;
end;

destructor TBitmapSurfaceBuf.Destroy;
begin
  inherited;
end;

procedure TBitmapSurfaceBuf.SetCapacity(const Value: Integer);
begin
  FCapacity := Value;
end;

type // hard hack
  TBitmapSurfacePrivate = class(TBitmapSurface)
  private
    FBits: Pointer;
    FPitch: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FPixelFormat: TPixelFormat;
    FBytesPerPixel: Integer;
  end;

procedure TBitmapSurfaceBuf.SetSize(const AWidth, AHeight: Integer; const APixelFormat: TPixelFormat);
var
  NumOfBytes: Integer;
begin
  with TBitmapSurfacePrivate(Self) do
  begin
    FPixelFormat := APixelFormat;
    if FPixelFormat = TPixelFormat.None then
      FPixelFormat := TPixelFormat.BGRA;

    FBytesPerPixel := PixelFormatBytes[FPixelFormat];

    FWidth := Max(AWidth, 0);
    FHeight := Max(AHeight, 0);
    FPitch := FWidth * FBytesPerPixel;
    NumOfBytes := FWidth * FHeight * FBytesPerPixel;

    if FCapacity = 0 then
    begin
      ReallocMem(FBits, NumOfBytes);
      FillChar(FBits^, NumOfBytes, 0);
    end
    else
    begin
      if FBits = nil then
      begin
        ReallocMem(FBits, FCapacity);
        FillChar(FBits^, FCapacity, 0);
      end;
    end;
  end;
end;

{ TAnimatorHelper }

class procedure TAnimatorHelper.DetachPropertyAnimation( const Target: TFmxObject; const APropertyName: string);
begin
  var i := Target.ChildrenCount - 1;
  while i >= 0 do
  begin
    if (Target.Children[i] is TCustomPropertyAnimation) and
      (CompareText(TCustomPropertyAnimation(Target.Children[i]).PropertyName, APropertyName) = 0)
    then
    begin
      var Anim := TFloatAnimation(Target.Children[i]);
      Anim.Parent := nil;
      Anim.Stop;
    end;
    if i > Target.ChildrenCount then
      i := Target.ChildrenCount;
    Dec(i);
  end;
end;

end.

