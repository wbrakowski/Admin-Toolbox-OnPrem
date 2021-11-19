page 51002 "License Information"
{
    ApplicationArea = All;
    Caption = 'License Information';
    PageType = ListPart;
    SourceTable = "License Information";
    UsageCategory = Lists;
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Text; Rec.Text)
                {
                    Editable = false;
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Specifies the value of the Text field';
                }
            }
            field(DeveloperLicense; AdminToolMgt.IsDeveloperLicense())
            {
                Caption = 'Developer License';
                ApplicationArea = All;
                Editable = false;
                ToolTip = 'Specifies if the active license is a developer license.';
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
                PromotedOnly = true;
                ToolTip = 'Imports the selected license.';

                trigger OnAction()
                var
                    PowershellMgt: Codeunit "Powershell Mgt.";
                begin
                    PowershellMgt.ImportLicense();
                end;
            }
        }
    }
    var
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
}