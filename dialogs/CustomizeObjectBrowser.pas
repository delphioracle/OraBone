unit CustomizeObjectBrowser;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Grids, BCDialogs.Dlg, Vcl.Buttons, ActnList, ValEdit, Vcl.Themes, Vcl.ExtCtrls, System.Actions, Vcl.ComCtrls,
  Vcl.ToolWin, BCControls.ToolBar, Vcl.ImgList, BCControls.ImageList;

type
  TCustomizeObjectBrowserDialog = class(TDialog)
    ActionList: TActionList;
    BottomPanel: TPanel;
    CancelButton: TButton;
    MoveDownAction: TAction;
    MoveUpAction: TAction;
    OKAction: TAction;
    OKButton: TButton;
    Separator1Panel: TPanel;
    Separator2Panel: TPanel;
    TopPanel: TPanel;
    ValueListEditor: TValueListEditor;
    ImageList: TBCImageList;
    ToolBar: TBCToolBar;
    MoveUpToolButton: TToolButton;
    MoveDownToolButton: TToolButton;
    procedure FormDestroy(Sender: TObject);
    procedure MoveDownActionExecute(Sender: TObject);
    procedure MoveUpActionExecute(Sender: TObject);
    procedure OKActionExecute(Sender: TObject);
    procedure ValueListEditorClick(Sender: TObject);
    procedure ValueListEditorDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
  private
    { Private declarations }
    FInMouseClick: Boolean;
    procedure FillValueList;
    procedure WriteIniFile;
  public
    { Public declarations }
    function Open: Boolean;
  end;

function CustomizeObjectBrowserDialog: TCustomizeObjectBrowserDialog;

implementation

{$R *.dfm}

uses
  Winapi.UxTheme, System.Math, BigIni, BCCommon.StyleUtils, BCCommon.FileUtils;

const
  TXT_MARG: TPoint = (x: 4; y: 2);
  BTN_WIDTH = 12;
  CELL_PADDING = 4;

var
  FCustomizeObjectBrowserDialog: TCustomizeObjectBrowserDialog;

function CustomizeObjectBrowserDialog: TCustomizeObjectBrowserDialog;
begin
  if not Assigned(FCustomizeObjectBrowserDialog) then
    Application.CreateForm(TCustomizeObjectBrowserDialog, FCustomizeObjectBrowserDialog);
  Result := FCustomizeObjectBrowserDialog;
  SetStyledFormSize(Result);
end;

procedure TCustomizeObjectBrowserDialog.FormDestroy(Sender: TObject);
begin
  FCustomizeObjectBrowserDialog := nil;
end;

procedure TCustomizeObjectBrowserDialog.MoveDownActionExecute(Sender: TObject);
begin
  if ValueListEditor.Row < ValueListEditor.RowCount - 1 then
  begin
    ValueListEditor.Strings.Exchange(ValueListEditor.Row - 1, ValueListEditor.Row);
    ValueListEditor.Row := ValueListEditor.Row + 1;
  end;
end;

procedure TCustomizeObjectBrowserDialog.MoveUpActionExecute(Sender: TObject);
begin
  if ValueListEditor.Row - 1 > 0 then
  begin
    ValueListEditor.Strings.Exchange(ValueListEditor.Row - 1, ValueListEditor.Row - 2);
    ValueListEditor.Row := ValueListEditor.Row - 1;
  end;
end;

procedure TCustomizeObjectBrowserDialog.ValueListEditorClick(Sender: TObject);
var
  where: TPoint;
  ACol, ARow: integer;
  Rect, btnRect: TRect;
  s: TSize;
begin
  //Again, check to avoid recursion:
  if not FInMouseClick then
  begin
    FInMouseClick := true;
    try
      //Get clicked coordinates and cell:
      where := Mouse.CursorPos;
      where := ValueListEditor.ScreenToClient(where);
      ValueListEditor.MouseToCell(where.x, where.y, ACol, ARow);
      if ARow > 0 then
      begin
        //Get buttonrect for clicked cell:
        //btnRect := GetBtnRect(ACol, ARow, false);
        s.cx := GetSystemMetrics(SM_CXMENUCHECK);
        s.cy := GetSystemMetrics(SM_CYMENUCHECK);
        Rect := ValueListEditor.CellRect(ACol, ARow);
        btnRect.Top := Rect.Top + (Rect.Bottom - Rect.Top - s.cy) div 2;
        btnRect.Bottom := btnRect.Top + s.cy;
        btnRect.Left := Rect.Left + CELL_PADDING;
        btnRect.Right := btnRect.Left + s.cx;

        InflateRect(btnrect, 2, 2);  //Allow 2px 'error-range'...

        //Check if clicked inside buttonrect:
        if PtInRect(btnRect, where) then
          if ACol = 1 then
          begin
            if ValueListEditor.Cells[ACol, ARow] = 'True' then
              ValueListEditor.Cells[ACol, ARow] := 'False'
            else
              ValueListEditor.Cells[ACol, ARow] := 'True'
          end;
      end;
    finally
      FInMouseClick := false;
    end;
  end;
  ValueListEditor.Repaint;
end;

procedure TCustomizeObjectBrowserDialog.ValueListEditorDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  h: HTHEME;
  s: TSize;
  r, header, LRect: TRect;
  LStyles: TCustomStyleServices;
  LColor: TColor;
  LDetails: TThemedElementDetails;

  function Checked(ARow: Integer): Boolean;
  begin
    if ValueListEditor.Cells[1, ARow] = 'True' then
      Result := True
    else
      Result := False
  end;
begin
  LStyles := StyleServices;

  if ARow = 0 then
  begin
    if not LStyles.GetElementColor(LStyles.GetElementDetails(thHeaderItemNormal), ecTextColor, LColor) or (LColor = clNone) then
      LColor := LStyles.GetSystemColor(clWindowText);
    header := Rect;
    if Assigned(TStyleManager.ActiveStyle) then
      if TStyleManager.ActiveStyle.Name <> 'Windows' then
        Dec(header.Left, 1);
    Inc(header.Right, 1);
    Inc(header.Bottom, 1);
    ValueListEditor.Canvas.Brush.Color := LStyles.GetSystemColor(ValueListEditor.FixedColor);
    ValueListEditor.Canvas.Font.Color := LColor;
    ValueListEditor.Canvas.FillRect(header);
    ValueListEditor.Canvas.Brush.Style := bsClear;

    if UseThemes then
    begin
      LStyles.DrawElement(ValueListEditor.Canvas.Handle, StyleServices.GetElementDetails(thHeaderItemNormal), header);

      LDetails := LStyles.GetElementDetails(thHeaderItemNormal);

      Inc(header.Left, 4);
      Dec(header.Right, 1);
      Dec(header.Bottom, 1);
      if ACol = 0 then
        LStyles.DrawText(ValueListEditor.Canvas.Handle,
          LDetails, ValueListEditor.Cells[ACol, ARow], header,
          [tfSingleLine, tfVerticalCenter])
      else
        LStyles.DrawText(ValueListEditor.Canvas.Handle,
          LDetails, ValueListEditor.Cells[ACol, ARow], header,
          [tfCenter, tfSingleLine, tfVerticalCenter]);
    end;
  end;

  if (ARow > 0) then
  begin
    if not LStyles.GetElementColor(LStyles.GetElementDetails(tgCellNormal), ecTextColor, LColor) or  (LColor = clNone) then
      LColor := LStyles.GetSystemColor(clWindowText);
    //get and set the backgroun color
    ValueListEditor.Canvas.Brush.Color := LStyles.GetStyleColor(scListView);
    ValueListEditor.Canvas.Font.Color := LColor;

    if UseThemes and (gdSelected in State) then
    begin
       ValueListEditor.Canvas.Brush.Color := LStyles.GetSystemColor(clHighlight);
       ValueListEditor.Canvas.Font.Color := LStyles.GetSystemColor(clHighlightText);
    end
    else
    if not UseThemes and (gdSelected in State) then
    begin
      ValueListEditor.Canvas.Brush.Color := clHighlight;
      ValueListEditor.Canvas.Font.Color := clHighlightText;
    end;
    ValueListEditor.Canvas.FillRect(Rect);
    ValueListEditor.Canvas.Brush.Style := bsClear;
    // draw selected
    if UseThemes and (gdSelected in State) then
    begin
      LRect := Rect;
      Dec(LRect.Left, 1);
      Inc(LRect.Right, 2);
      LDetails := LStyles.GetElementDetails(tgCellSelected);
      LStyles.DrawElement(ValueListEditor.Canvas.Handle, LDetails, LRect);
    end;
    s.cx := GetSystemMetrics(SM_CXMENUCHECK);
    s.cy := GetSystemMetrics(SM_CYMENUCHECK);
    if (ACol = 1) and UseThemes then
    begin
      h := OpenThemeData(ValueListEditor.Handle, 'BUTTON');
      if h <> 0 then
        try
          GetThemePartSize(h,
            ValueListEditor.Canvas.Handle,
            BP_CHECKBOX,
            CBS_CHECKEDNORMAL,
            nil,
            TS_DRAW,
            s);
          r.Top := Rect.Top + (Rect.Bottom - Rect.Top - s.cy) div 2;
          r.Bottom := r.Top + s.cy;
          r.Left := Rect.Left + CELL_PADDING;
          r.Right := r.Left + s.cx;

          if Checked(ARow) then
            LDetails := LStyles.GetElementDetails(tbCheckBoxcheckedNormal)
          else
            LDetails := LStyles.GetElementDetails(tbCheckBoxUncheckedNormal);

          LStyles.DrawElement(ValueListEditor.Canvas.Handle, LDetails, r);
        finally
          CloseThemeData(h);
        end;
    end
    else
    if (ACol = 1) then
    begin
      r.Top := Rect.Top + (Rect.Bottom - Rect.Top - s.cy) div 2;
      r.Bottom := r.Top + s.cy;
      r.Left := Rect.Left + CELL_PADDING;
      r.Right := r.Left + s.cx;
      DrawFrameControl(ValueListEditor.Canvas.Handle,
        r,
        DFC_BUTTON,
        IfThen(Checked(ARow), DFCS_CHECKED, DFCS_BUTTONCHECK));
    end;

    LRect := Rect;
    Inc(LRect.Left, 4);
    if (gdSelected in State) then
      LDetails := LStyles.GetElementDetails(tgCellSelected)
    else
      LDetails := LStyles.GetElementDetails(tgCellNormal);

    if not LStyles.GetElementColor(LDetails, ecTextColor, LColor) or (LColor = clNone) then
      LColor := LStyles.GetSystemColor(clWindowText);

    ValueListEditor.Canvas.Font.Color := LColor;

    if (ACol = 1) then
    begin
      Inc(LRect.Left, 20);
      LStyles.DrawText(ValueListEditor.Canvas.Handle,
        LDetails,
        ValueListEditor.Cells[ACol, ARow],
        LRect,
        [tfSingleLine, tfVerticalCenter, tfEndEllipsis])
    end
    else
      LStyles.DrawText(ValueListEditor.Canvas.Handle,
        LDetails,
        ValueListEditor.Cells[ACol, ARow],
        LRect,
        [tfSingleLine, tfVerticalCenter]);
  end;
end;

procedure TCustomizeObjectBrowserDialog.FillValueList;
var
  i: Integer;
  TreeObjects: TStrings;
begin
  { read from ini }
  TreeObjects := TStringList.Create;
  try
    with TBigIniFile.Create(GetINIFilename) do
    try
      ReadSectionValues('CustomizeObjectTree', TreeObjects);
    finally
      Free;
    end;

    if TreeObjects.Count = 0 then
      Exit;

    ValueListEditor.Strings.Clear;
    for i := 0 to TreeObjects.Count - 1 do
      ValueListEditor.Strings.Add(TreeObjects.Strings[i]);

  finally
    TreeObjects.Free;
  end;
end;

procedure TCustomizeObjectBrowserDialog.WriteIniFile;
var
  i: Integer;
  Section: string;
begin
  with TBigIniFile.Create(GetINIFilename) do
  try
    Section := 'CustomizeObjectTree';
    EraseSection(Section);
    for i := 1 to ValueListEditor.RowCount - 1 do
      WriteString(Section, ValueListEditor.Keys[i], ValueListEditor.Values[ValueListEditor.Keys[i]]);
  finally
    Free;
  end;
end;

procedure TCustomizeObjectBrowserDialog.OKActionExecute(Sender: TObject);
begin
  WriteIniFile;

  ModalResult := mrOk;
end;

function TCustomizeObjectBrowserDialog.Open: Boolean;
begin
  FInMouseClick := False;

  FillValueList;

  Result := ShowModal = mrOk;
end;

end.
