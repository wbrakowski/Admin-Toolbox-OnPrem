#if OnPrem
page 51002 "License Information"
{
    ApplicationArea = All;
    Caption = 'License Information';
    Editable = true;
    PageType = ListPart;
    SourceTable = "License Information";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Text; Rec.Text)
                {
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies the value of the Text field.';
                }
            }

            field(DeveloperLicense; DeveloperLicense)
            {
                Caption = 'Developer License';
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
                Caption = 'Import License';
                Image = Import;
                ToolTip = 'Imports the selected license.';

                trigger OnAction()
                var
                    PowershellMgt: Codeunit "Powershell Mgt.";
                begin
                    PowershellMgt.ImportLicense();
                end;
            }
            action(ExportObjects)
            {
                Caption = 'Export Used and Unused Objects in License';
                Image = Export;
                RunObject = report "Export Objects in License";
                ToolTip = 'Creates a list with all used and unused objects in the license.';
            }
            action(ExportUnlicensedObjects)
            {
                Caption = 'Export Unlicensed Objects';
                Image = Export;
                RunObject = report "Export Unlicensed Objects";
                ToolTip = 'Creates a list with all unlicensed objects.';
            }
        }
    }
    var
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        DeveloperLicense: Boolean;

    trigger OnAfterGetRecord()
    begin
        DeveloperLicense := AdminToolMgt.IsDeveloperLicense();
    end;
}
#endif