page 51009 "Unlicensed Objects"
{
    ApplicationArea = All;
    Caption = 'Unlicensed Objects';
    Editable = false;
    PageType = List;
    SourceTable = "Temp Unlicensed Object";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Object Type"; Rec."Object Type")
                {
                }
                field("Object ID"; Rec."Object ID")
                {
                }
                field("Object Name"; Rec."Object Name")
                {
                }
            }
        }
    }
}