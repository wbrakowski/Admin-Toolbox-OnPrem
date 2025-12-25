page 51016 "Audit Log Entry Card"
{
    ApplicationArea = All;
    Caption = 'Audit Log Entry';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Audit Log Entry";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Entry No."; Rec."Entry No.")
                {
                }
                field("Operation Type"; Rec."Operation Type")
                {
                    Style = StrongAccent;
                }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyle;
                }
                field("Date Time"; Rec."Date Time")
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
                field("Triggered By"; Rec."Triggered By")
                {
                }
            }
            group(TableInfo)
            {
                Caption = 'Table Information';

                field("Table ID"; Rec."Table ID")
                {
                }
                field("Table Name"; Rec."Table Name")
                {
                }
                field("Primary Key Value"; Rec."Primary Key Value")
                {
                }
            }
            group(Results)
            {
                Caption = 'Results';

                field("No. of Records Affected"; Rec."No. of Records Affected")
                {
                    Style = Strong;
                }
                field("No. of Records Failed"; Rec."No. of Records Failed")
                {
                    StyleExpr = FailedStyle;
                }
                field("No. of Fields Changed"; Rec."No. of Fields Changed")
                {
                }
                field("Duration (ms)"; Rec."Duration (ms)")
                {
                }
            }
            group(BackupInfo)
            {
                Caption = 'Backup Information';
                Visible = Rec."Backup Created";

                field("Backup Created"; Rec."Backup Created")
                {
                }
                field("Backup Entry No."; Rec."Backup Entry No.")
                {
                }
            }
            group(Details)
            {
                Caption = 'Details';

                field(Description; Rec.Description)
                {
                    MultiLine = true;
                }
                field("Error Message"; Rec."Error Message")
                {
                    MultiLine = true;
                    Style = Unfavorable;
                    Visible = Rec.Status = Rec.Status::Failed;
                }
            }
            part(FieldChanges; "Field Change History")
            {
                Caption = 'Field Changes';
                SubPageLink = "Audit Log Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewBackup)
            {
                Caption = 'View Related Backup';
                Enabled = Rec."Backup Created";
                Image = Archive;
                ToolTip = 'Specifies that the backup created before this operation will be opened.';

                trigger OnAction()
                begin
                    Rec.ViewRelatedBackup();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Success:
                StatusStyle := Format(PageStyle::Favorable);
            Rec.Status::Failed:
                StatusStyle := Format(PageStyle::Unfavorable);
            else
                StatusStyle := Format(PageStyle::Standard);
        end;

        if Rec."No. of Records Failed" > 0 then
            FailedStyle := Format(PageStyle::Unfavorable)
        else
            FailedStyle := Format(PageStyle::Standard);
    end;

    var
        FailedStyle: Text;
        StatusStyle: Text;
}
