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
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Object Type field.';
                }
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Object ID field.';
                }
                field("Object Name"; Rec."Object Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Object Name field.';
                }
                field(Used; Rec.Used)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Used field.';
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