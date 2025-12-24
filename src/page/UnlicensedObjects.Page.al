page 51009 "Unlicensed Objects"
{
    ApplicationArea = All;
    Caption = 'Unlicensed Objects';
    PageType = List;
    SourceTable = "Temp Unlicensed Object";
    UsageCategory = Lists;
    Editable = false;

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