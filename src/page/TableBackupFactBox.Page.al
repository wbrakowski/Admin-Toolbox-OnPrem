page 51014 "Table Backup FactBox"
{
    ApplicationArea = All;
    Caption = 'Table Backups';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Table Backup";

    layout
    {
        area(Content)
        {
            repeater(Backups)
            {
                field("Table ID"; Rec."Table ID")
                {
                }
                field("Table Name"; Rec."Table Name")
                {
                }
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
                field("Backup Date Time"; Rec."Backup Date Time")
                {
                    StyleExpr = BackupDateStyle;
                }
                field("No. of Records"; Rec."No. of Records")
                {
                    StyleExpr = RecordCountStyle;
                }
                field("Backup Type"; Rec."Backup Type")
                {
                    Visible = false;
                }
                field("Operation Type"; Rec."Operation Type")
                {
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewBackup)
            {
                Caption = 'View Backup';
                Image = View;
                ToolTip = 'Specifies that the backup card will be opened to view details.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Table Backup Card", Rec);
                end;
            }
            action(RestoreBackup)
            {
                Caption = 'Restore';
                Image = Restore;
                ToolTip = 'Restores the data from this backup.';

                trigger OnAction()
                var
                    ConfirmManagement: Codeunit "Confirm Management";
                    ConfirmMsg: Label 'Do you want to restore the backup for table %1 (%2)?\This will restore %3 records from %4.', Comment = '%1 = Table ID, %2 = Table Name, %3 = Record Count, %4 = Backup Date';
                    BackupRestoredMsg: Label 'Backup restored successfully.';
                    ConfirmText: Text;
                begin
                    ConfirmText := StrSubstNo(ConfirmMsg, Rec."Table ID", Rec."Table Name", Rec."No. of Records", Rec."Backup Date Time");
                    if not ConfirmManagement.GetResponseOrDefault(ConfirmText, false) then
                        exit;

                    Rec.RestoreBackup();
                    Message(BackupRestoredMsg);
                end;
            }
            action(Refresh)
            {
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refreshes the backup list.';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStyles();
    end;

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey("Table ID", "Backup Date Time");
        Rec.Ascending(false);
    end;

    procedure SetTableFilter(TableID: Integer)
    begin
        Rec.Reset();
        Rec.SetRange("Table ID", TableID);
        Rec.SetCurrentKey("Table ID", "Backup Date Time");
        Rec.Ascending(false);
        CurrPage.Update(false);
    end;

    local procedure SetStyles()
    var
        DaysOld: Integer;
    begin
        // Style for backup date - warn if very old
        DaysOld := Today() - Rec."Backup Date Time".Date();
        if DaysOld > 90 then
            BackupDateStyle := Format(PageStyle::Attention)
        else
            if DaysOld > 30 then
                BackupDateStyle := Format(PageStyle::Ambiguous)
            else
                BackupDateStyle := Format(PageStyle::Favorable);

        // Style for record count - highlight large backups
        if Rec."No. of Records" > 10000 then
            RecordCountStyle := Format(PageStyle::Strong)
        else
            if Rec."No. of Records" > 1000 then
                RecordCountStyle := Format(PageStyle::Favorable)
            else
                RecordCountStyle := Format(PageStyle::Standard);
    end;

    var
        BackupDateStyle: Text;
        RecordCountStyle: Text;
}
