page 51005 "Admin Toolbox Setup"
{
    AboutText = 'Setup additional functionalities of the Admin Toolbox. It only contains additional functionalities for OnPrem environments.';
    AboutTitle = 'About Admin Toolbox Setup';
    ApplicationArea = All;
    Caption = 'Admin Toolbox Setup';
    PageType = Card;
    SourceTable = "Admin Toolbox Setup";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(License)
            {
                Caption = 'License';
                field(DeveloperLicense; DeveloperLicense)
                {
                    AboutText = 'If a developer license was imported in the system, this field will be checked off.';
                    AboutTitle = 'Shows you information about the active license.';
                    Caption = 'Developer License';
                    Editable = false;
                    ToolTip = 'Specifies if the active license is a developer license.';
                    Visible = IsOnPrem;
                }
                field("Developer License Warning"; Rec."Developer License Warning")
                {
                    AboutText = 'If enabled, a message will be shown OnCompanyOpen that the developer license is active. Enable this field in test environments to make sure that no developer license is wrongfully imported.';
                    AboutTitle = 'Always be informed if a developer license is imported in systems where it should not be imported.';
                    Editable = IsOnPrem;
                }
            }
            group(Backup)
            {
                Caption = 'Backup Settings';
                field("Auto Backup Before Deletion"; Rec."Auto Backup Before Deletion")
                {
                    AboutText = 'Enable this to automatically create backups before deleting records. This provides a safety net to restore data if needed.';
                    AboutTitle = 'Automatic Backup Protection';
                }
                field("Prompt for Backup"; Rec."Prompt for Backup")
                {
                    AboutText = 'When enabled, users will be asked if they want to create a backup before deletion. When disabled, backups are created automatically without prompting.';
                    AboutTitle = 'Backup Confirmation Prompt';
                }
                field("Auto Backup Type"; Rec."Auto Backup Type")
                {
                    AboutText = 'Choose which type of backup should be created: JSON Export (fast, portable), Snapshot (table copy), or Full Backup (complete data).';
                    AboutTitle = 'Backup Type Selection';
                }
                field("Backup Retention Days"; Rec."Backup Retention Days")
                {
                    AboutText = 'Set how long backups should be kept. Older backups can be manually deleted from the Backup Management page.';
                    AboutTitle = 'Backup Retention Policy';
                }
            }
            group(AuditLog)
            {
                Caption = 'Audit Log Settings';
                field("Audit Log Retention Days"; Rec."Audit Log Retention Days")
                {
                    AboutText = 'Set how long audit log entries should be kept. Set to 0 to keep all audit logs. Older entries can be manually deleted from the Audit Log page.';
                    AboutTitle = 'Audit Log Retention Policy';
                }
            }
            group(UserInterface)
            {
                Caption = 'User Interface';
                InstructionalText = 'Configure how the Admin Toolbox interface displays help and documentation.';

                field("Enable Inline Documentation"; Rec."Enable Inline Documentation")
                {
                    AboutText = 'Shows helpful information boxes within pages to explain functions, warn about risks, and provide best practices.';
                    AboutTitle = 'Inline Documentation';
                }
            }
        }
    }

    var
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        DeveloperLicense, IsOnPrem : Boolean;

    trigger OnOpenPage()

    var
        EnvironmentInformation: Codeunit "Environment Information";
        MyNotification: Notification;
        OnPremMsg: Label 'It was detected that this is not an OnPrem environment. The Admin Tool Setup only contains additional functionalities for OnPrem environments.';
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert(false);
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