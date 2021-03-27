page 51003 "Record Deletion"
{

    ApplicationArea = All;
    Caption = 'Tables';
    PageType = ListPart;
    SourceTable = "Record Deletion";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                }
                field("No. of Table Relation Errors"; Rec."No. of Table Relation Errors")
                {
                    ApplicationArea = All;
                }
                field("No. of Records"; Rec."No. of Records")
                {
                    ApplicationArea = All;
                }
                field("Delete Records"; Rec."Delete Records")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

}
