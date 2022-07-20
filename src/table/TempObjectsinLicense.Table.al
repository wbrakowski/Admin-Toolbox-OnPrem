table 51003 "Temp Object in License"
{
    Caption = 'Temp Object in License';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Object ID"; Integer)
        {
            Caption = 'Object ID';
            DataClassification = CustomerContent;
        }

        field(2; "Object Type"; Option)
        {
            Caption = 'Object Type';
            DataClassification = CustomerContent;
            OptionCaption = ',Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,,,,,PageExtension,TableExtension,Enum,EnumExtension,,,PermissionSet,PermissionSetExtension,ReportExtension';
            OptionMembers = ,"Table",,"Report",,"Codeunit","XMLport",MenuSuite,"Page","Query",,,,,"PageExtension","TableExtension","Enum","EnumExtension",,"PermissionSet","PermissionSetExtension","ReportExtension";
        }
        field(3; "Object Name"; Text[200])
        {
            Caption = 'Object Name';
            DataClassification = CustomerContent;
        }
        field(4; Used; Boolean)
        {
            Caption = 'Used';
            DataClassification = CustomerContent;
        }

    }
    keys
    {
        key(PK; "Object Type", "Object ID")
        {
            Clustered = true;
        }
    }
}