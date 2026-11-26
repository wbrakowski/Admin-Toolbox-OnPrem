namespace AdminToolbox;

using System.Reflection;
using System.Utilities;

page 51011 "Table Backup List"
{
    ApplicationArea = All;
    Caption = 'Table Backups';
    CardPageId = "Table Backup Card";
    Editable = false;
    PageType = List;
    SourceTable = "Table Backup";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                }
                field("Table ID"; Rec."Table ID")
                {
                }
                field("Table Name"; Rec."Table Name")
                {
                }
                field("Backup Type"; Rec."Backup Type")
                {
                }
                field("Operation Type"; Rec."Operation Type")
                {
                }
                field("Backup Date Time"; Rec."Backup Date Time")
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
                field("No. of Records"; Rec."No. of Records")
                {
                    Style = Strong;
                    StyleExpr = true;
                }
                field("Backup Size (KB)"; Rec."Backup Size (KB)")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Restored; Rec.Restored)
                {
                }
                field("Restore Date Time"; Rec."Restore Date Time")
                {
                }
                field("Company Name"; Rec."Company Name")
                {
                    Visible = false;
                }
            }
        }
        area(FactBoxes)
        {
            systempart(Links; Links)
            {
            }
            systempart(Notes; Notes)
            {
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateBackup)
            {
                Caption = 'Create Backup';
                Image = Export;
                ToolTip = 'Create a new backup of a table.';

                trigger OnAction()
                var
                    CreateBackupPage: Page "Create Table Backup";
                begin
                    CreateBackupPage.RunModal();
                    CurrPage.Update(false);
                end;
            }
            action(RestoreBackup)
            {
                Caption = 'Restore Backup';
                Enabled = Rec."Entry No." <> 0;
                Image = Import;
                ToolTip = 'Restore records from the selected backup.';

                trigger OnAction()
                begin
                    Rec.RestoreBackup();
                    CurrPage.Update(false);
                end;
            }
            action(ExportToFile)
            {
                Caption = 'Export to File';
                Enabled = Rec."Entry No." <> 0;
                Image = ExportFile;
                ToolTip = 'Export the backup data to a JSON file.';

                trigger OnAction()
                begin
                    Rec.ExportToFile();
                end;
            }
            action(ImportFromFile)
            {
                Caption = 'Import from File';
                Image = ImportExcel;
                ToolTip = 'Import backup data from a JSON file.';

                trigger OnAction()
                var
                    AllObjWithCaption: Record AllObjWithCaption;
                    TableBackupMgt: Codeunit "Table Backup Mgt.";
                begin
                    if Page.RunModal(Page::"Table Objects", AllObjWithCaption) = Action::LookupOK then begin
                        TableBackupMgt.ImportBackupFromFile(AllObjWithCaption."Object ID");
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(ViewData)
            {
                Caption = 'View Backup Data';
                Enabled = Rec."Entry No." <> 0;
                Image = View;
                ToolTip = 'Specifies that the backup data (first 1000 characters) will be displayed.';

                trigger OnAction()
                begin
                    Rec.ViewBackupData();
                end;
            }
            action(DeleteOldBackups)
            {
                Caption = 'Delete Old Backups';
                Image = Delete;
                ToolTip = 'Deletes the backups that are older than the backup retention set in the Admin Toolbox Setup.';

                trigger OnAction()
                var
                    AdminToolboxSetup: Record "Admin Toolbox Setup";
                    ConfirmManagement: Codeunit "Confirm Management";
                    TableBackupMgt: Codeunit "Table Backup Mgt.";
                    Days: Integer;
                    DeleteConfirmQst: Label 'This will delete %1 backup(s) older than %2 days. Continue?', Comment = '%1 = No. of backups, %2 = Days';
                    DeletedMsg: Label '%1 backup(s) have been deleted.', Comment = '%1 = No. of backups';
                    NoBackupsFoundMsg: Label 'No backups found older than %1 days.', Comment = '%1 = Days to keep';
                begin
                    Days := AdminToolboxSetup.GetBackupRetentionDays();

                    if TableBackupMgt.CountOldBackups(Days) = 0 then begin
                        Message(NoBackupsFoundMsg, Days);
                        exit;
                    end;

                    if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(DeleteConfirmQst, TableBackupMgt.CountOldBackups(Days), Days), false) then
                        exit;

                    Message(DeletedMsg, TableBackupMgt.DeleteOldBackups(Days));
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CreateBackup_Promoted; CreateBackup)
                {
                }
                actionref(RestoreBackup_Promoted; RestoreBackup)
                {
                }
                actionref(ExportToFile_Promoted; ExportToFile)
                {
                }
                actionref(ImportFromFile_Promoted; ImportFromFile)
                {
                }
                actionref(ViewData_Promoted; ViewData)
                {
                }
                actionref(DeleteOldBackups_Promoted; DeleteOldBackups)
                {
                }
            }
        }
    }
}
