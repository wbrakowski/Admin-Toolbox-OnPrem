page 51005 "Admin Toolbox Setup"
{
    Caption = 'Admin Toolbox Setup';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Admin Toolbox Setup";
    AboutTitle = 'About Admin Toolbox Setup';
    AboutText = 'Setup additional functionalities of the Admin Toolbox. It only contains additional functionalities for OnPrem environments.';

    layout
    {
        area(Content)
        {

            group(License)
            {
                Caption = 'License';
                field(DeveloperLicense; DeveloperLicense)
                {
                    Caption = 'Developer License';
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies if the active license is a developer license.';
                    AboutTitle = 'Shows you information about the active license.';
                    AboutText = 'If a developer license was imported in the system, this field will be checked off.';
                    Visible = IsOnPrem;
                }
                field("Developer License Warning"; Rec."Developer License Warning")
                {
                    ToolTip = 'Specifies if a warning should be shown on opening the company when a developer license is active (only OnPrem).';
                    AboutTitle = 'Always be informed if a developer license is imported in systems where it should not be imported.';
                    AboutText = 'If enabled, a message will be shown OnCompanyOpen that the developer license is active. Enable this field in test environments to make sure that no developer license is wrongfully imported.';
                    ApplicationArea = All;
                    Editable = IsOnPrem;
                }
            }

        }
    }

    var
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        DeveloperLicense, DeveloperLicenseWarning, IsOnPrem : Boolean;


    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        MyNotification: Notification;
        OnPremMsg: Label 'It was detected that this is not an OnPrem environment. The Admin Tool Setup only contains additional functionalities for OnPrem environments.';
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        IsOnPrem := EnvironmentInformation.IsOnPrem();
        if not IsOnPrem then begin
            MyNotification.Message(OnPremMsg);
            MyNotification.Scope := NotificationScope::LocalScope;
            MyNotification.Send();
        end;
    end;

    trigger OnAfterGetRecord()
    begin
#if OnPrem
        DeveloperLicense := AdminToolMgt.IsDeveloperLicense();
#endif
    end;
}