page 51003 "Record Deletion"
{

    ApplicationArea = All;
    Caption = 'Tables';
    PageType = ListPart;
    SourceTable = "Record Deletion";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Table ID"; Rec."Table ID")
                {
                }
                field("Table Name"; Rec."Table Name")
                {
                }
                field(TableCaption; AdminToolMgt.GetTableCaption(Rec."Table ID"))
                {
                    Caption = 'Table Caption';
                    ToolTip = 'Specifies the caption of the table.';
                }
                field("No. of Table Relation Errors"; Rec."No. of Table Relation Errors")
                {
                }
#if OnPrem
                field("No. of Records"; Rec."No. of Records")
                {
                }
#endif
                field("Delete Records"; Rec."Delete Records")
                {
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(EditTable)
            {
                Caption = 'Edit Table';
                Image = EditLines;
                ToolTip = 'Opens the table editor where you can edit or delete selected records.';
                trigger OnAction()
                begin
                    AdminToolMgt.OpenTableEditor(Rec."Table ID");
                    CurrPage.Update(false);
                end;
            }
        }
    }

    internal procedure GetSelectedTableNo(): Integer
    begin
        exit(Rec."Table ID");
    end;



    var
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
}
