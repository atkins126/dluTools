unit dluMultiColsComboBox;

{$mode ObjFPC}{$H+}

interface
{
https://forum.lazarus.freepascal.org/index.php/topic,9397.msg46031.html#msg46031
}

uses Controls
   , StdCtrls
   , Classes
   , EditBtn;

type TDynStringArray = array of string;

{ TMultiColsComboBox }

 TMultiColsComboBox = class
   strict private
     fListBox    : TListBox;
     fEditButton : TEditButton;
     fSrcColParam: array of integer;
     fColCount   : integer;
     fColParam   : array of integer;
     fColValue   : TDynStringArray;
     function StringsToArray( const AStrings: TStrings ): TDynStringArray;
     procedure InitializePseudoCombo( AEditButton: TEditButton; const AColWidth: array of const;
                                      const AColValue: TDynStringArray );
     procedure PrepareColumnsWidth();
     procedure ButtonClick( Sender: TObject);
     procedure ListBox1Resize( Sender: TObject) ;
     procedure ListBoxExit( Sender: TObject);
     procedure ListBoxKeyPress( Sender: TObject; var Key: char) ;
     procedure ListBoxDrawItem( Control: TWinControl; Index: Integer; ARect: TRect; State: TOwnerDrawState) ;
   public
     constructor Create( AEditButton: TEditButton; const AColWidth: array of const; const AColValue: TDynStringArray ); overload;
     constructor Create( AEditButton: TEditButton; const AColWidth: array of const; AColValue: TStrings ); overload;
     destructor Destroy; override;
   end;


implementation

uses SysUtils;

{ TMultiColsComboBox }

constructor TMultiColsComboBox.Create( AEditButton: TEditButton; const AColWidth: array of const; const AColValue: TDynStringArray );
begin
   InitializePseudoCombo( AEditButton, AColWidth, AColValue );
end ;

constructor TMultiColsComboBox.Create( AEditButton: TEditButton; const AColWidth: array of const ; AColValue: TStrings) ;
begin
   InitializePseudoCombo( AEditButton, AColWidth, StringsToArray( AColValue ) );
end;

destructor TMultiColsComboBox.Destroy;
begin
   fListBox.Free;
   fEditButton.OnButtonClick := nil;
   inherited Destroy;
end;

function TMultiColsComboBox.StringsToArray(const AStrings: TStrings ): TDynStringArray;
  var i: integer;
begin
  SetLength( Result, AStrings.Count );
  for i:=0 to High( Result ) do Result[ i ] := AStrings[ i ];
end;

procedure TMultiColsComboBox.InitializePseudoCombo( AEditButton: TEditButton;
                                                  const AColWidth: array of const;
                                                  const AColValue: TDynStringArray );
  var i: integer;
begin
   Assert( Assigned( AEditButton ), 'Błąd 1' );
   fEditButton := AEditButton;
   fEditButton.ButtonCaption := '...';
   fEditButton.DirectInput   := false;
   fEditButton.ReadOnly      := false;
   fEditButton.OnButtonClick := @ButtonClick;

   fListBox := TListBox.Create( fEditButton );
   fListBox.SetBounds( fEditButton.Left,
                       fEditButton.Top + fEditButton.Height,
                       fEditButton.Width - fEditButton.Spacing - fEditButton.ButtonWidth,
                       100
                     );
   fListBox.Parent     := fEditButton.Parent;
   fListBox.Style      := lbOwnerDrawFixed;
   fListBox.Anchors    := [ akLeft, akRight, akTop ];
   fListBox.Visible    := false;
   fListBox.OnResize   := @ListBox1Resize;
   fListBox.OnExit     := @ListBoxExit;
   fListBox.OnKeyPress := @ListBoxKeyPress;
   fListBox.OnDrawItem := @ListBoxDrawItem;

   SetLength( fSrcColParam, Length( AColWidth ) );
   for i:=0 to Length( fSrcColParam )-1 do begin
      case TVarRec( AColWidth[i] ).VType of
        vtInteger:    fSrcColParam[ i ] := TVarRec( AColWidth[i] ).VInteger;
        vtExtended:   fSrcColParam[ i ] := - Round(100.0 * TVarRec( AColWidth[i] ).VExtended^ );   // by percent
      else
        raise Exception.CreateFmt( 'Bad parametr, pos. %d', [i] );
      end;
   end ;

   // prepare fColCount
   fColCount := Length( AColWidth ) + 1;

   // prepare fColParam table
   SetLength( fColParam, fColCount + 1 );
   PrepareColumnsWidth();

   // prepare fColValue table
   fColValue := AColValue;

   // dummy items
   for i:=1 to Length( fColValue ) div fColCount do fListBox.AddItem( '', nil );


end;

procedure TMultiColsComboBox.PrepareColumnsWidth;
  var i : integer;
begin
   fColParam[0] := 0;
   for i:=1 to fColCount-1 do begin
      if fSrcColParam[i-1] >= 0
         then fColParam[ i ] := fSrcColParam[i-1]
         else fColParam[ i ] := ( -fSrcColParam[i-1] * fListBox.Width) div 100;      // (by percent)
      fColParam[ i ] := fColParam[ i-1 ] + fColParam[ i ];
   end;
   fColParam[ fColCount ] := fListBox.Width;
end ;

procedure TMultiColsComboBox.ButtonClick( Sender: TObject) ;
begin
   fListBox.Visible := not fListBox.Visible;
   if fListBox.Visible then begin
      fListBox.SetFocus;
      fListBox.Selected[0] := true;
   end;
end;

procedure TMultiColsComboBox.ListBox1Resize( Sender: TObject) ;
begin
   PrepareColumnsWidth;
end ;

procedure TMultiColsComboBox.ListBoxExit( Sender: TObject) ;
begin
   fListBox.Visible :=  false;
end;

procedure TMultiColsComboBox.ListBoxKeyPress( Sender: TObject; var Key: char) ;
begin
   if Key = #27 then ListBoxExit( sender );
end;

procedure TMultiColsComboBox.ListBoxDrawItem( Control: TWinControl;
                                            Index  : Integer;
                                            ARect  : TRect;
                                            State  : TOwnerDrawState) ;
  var i : Integer;
      rc: TRect;
begin
   fListBox.Canvas.FillRect( ARect );
   rc := Rect( ARect.Left, ARect.Top, ARect.Left, ARect.Bottom );

   for i := 0 to fColCount-1 do begin
       rc.Left   := fColParam[  i  ] + 2;
       rc.Right  := fColParam[ i+1 ] - 2;

       //draw text
       fListBox.Canvas.TextRect( rc, rc.Left, rc.Top, fColValue[ Index * fColCount + i ] );

       // draw separator (line)
       if i > 0 then
          fListBox.Canvas.Line( rc.Left-2, rc.Top, rc.Left-2, rc.Bottom );
   end;

end;

end.

