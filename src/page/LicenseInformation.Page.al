page 50002 "License Information"
{
    ApplicationArea = All;
    Caption = 'License Information';
    PageType = ListPart;
    SourceTable = "License Information";
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Text; Rec.Text)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportLicense)
            {
                ApplicationArea = All;
                Caption = 'Import License';
                Image = Import;
                Promoted = true;

                trigger OnAction()
                var
                    LicenseMgt: Codeunit "License Mgt.";
                begin
                    LicenseMgt.ImportLicense();
                end;
            }
        }
    }
}