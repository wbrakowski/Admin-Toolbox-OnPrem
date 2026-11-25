table 51003 "Temp Object in License"
{
    Caption = 'Temp Object in License';
    DataClassification = CustomerContent;
    DrillDownPageId = "Objects in License";
    LookupPageId = "Objects in License";

    fields
    {
        field(1; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            ToolTip = 'Specifies the value of the Object ID field.';
        }
        field(2; "Object Type"; Enum "Object Type")
        {
            Caption = 'Object Type';
            ToolTip = 'Specifies the value of the Object Type field.';
        }
        field(3; "Object Name"; Text[200])
        {
            Caption = 'Object Name';
            ToolTip = 'Specifies the value of the Object Name field.';
        }
        field(4; Used; Boolean)
        {
            Caption = 'Used';
            ToolTip = 'Specifies the value of the Used field.';
        }
    }
    keys
    {
        key(PK; "Object Type", "Object ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Object Type", "Object ID", "Object Name")
        {
        }
        fieldgroup(Brick; "Object Type", "Object ID", "Object Name")
        {
        }
    }
}