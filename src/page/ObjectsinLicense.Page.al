page 51008 "Objects in License"
{
    ApplicationArea = All;
    Caption = 'Objects in License';
    Editable = false;
    PageType = List;
    SourceTable = "Temp Object in License";
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
            Filters = where(Used = const(true));
            OrderBy = ascending("Object Type", "Object ID");
            SharedLayout = true;
        }
        view(FreeObjects)
        {
            Caption = 'Free Objects';
            Filters = where(Used = const(false));
            OrderBy = ascending("Object Type", "Object ID");
            SharedLayout = true;
        }
    }
}