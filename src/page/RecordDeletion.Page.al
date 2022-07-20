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
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the table.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the table.';
                }
                field(TableCaption; AdminToolMgt.GetTableCaption(Rec."Table ID"))
                {
                    Caption = 'Table Caption';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the caption of the table.';
                }
                field("No. of Table Relation Errors"; Rec."No. of Table Relation Errors")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the no. of table relation errors that were detected when running the table relation check.';
                }
#if OnPrem
                field("No. of Records"; Rec."No. of Records")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total no. of records in the table.';
                }
#endif
                field("Delete Records"; Rec."Delete Records")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that this table was marked for deletion.';
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
                ApplicationArea = All;
                Caption = 'Edit Table';
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
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
