page 51017 "Field Change History"
{
    ApplicationArea = All;
    Caption = 'Field Change History';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Field Change History";

    layout
    {
        area(Content)
        {
            repeater(Changes)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
                field("Field No."; Rec."Field No.")
                {
                }
                field("Field Name"; Rec."Field Name")
                {
                }
                field("Field Caption"; Rec."Field Caption")
                {
                }
                field("Old Value"; Rec."Old Value")
                {
                    StyleExpr = OldValueStyle;
                }
                field("New Value"; Rec."New Value")
                {
                    StyleExpr = NewValueStyle;
                }
                field("Date Time"; Rec."Date Time")
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewAuditLog)
            {
                Caption = 'View Audit Log Entry';
                Image = View;
                ToolTip = 'Specifies that the related audit log entry will be opened.';

                trigger OnAction()
                begin
                    Rec.ViewAuditLogEntry();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        OldValueStyle := Format(PageStyle::Subordinate);
        NewValueStyle := Format(PageStyle::Attention);
    end;

    var
        NewValueStyle: Text;
        OldValueStyle: Text;
}
