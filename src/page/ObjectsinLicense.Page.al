page 51008 "Objects in License"
{
    ApplicationArea = All;
    Caption = 'Objects in License';
    PageType = List;
    SourceTable = "Temp Object in License";
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
                field(Used; Rec.Used)
                {
                }
            }
        }
    }

    views
    {
        view(UsedObjects)
        {
            Caption = 'Used Objects';
            OrderBy = ascending("Object Type", "Object ID");
            Filters = where(Used = const(true));
            SharedLayout = true;
        }
        view(FreeObjects)
        {
            Caption = 'Free Objects';
            OrderBy = ascending("Object Type", "Object ID");
            Filters = where(Used = const(false));
            SharedLayout = true;
        }
    }
}