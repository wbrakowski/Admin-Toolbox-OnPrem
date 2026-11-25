table 51100 "Admin Tool Test Buffer"
{
    Caption = 'Admin Tool Test Buffer';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            ToolTip = 'Specifies the number of the test buffer record.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the test buffer record.';
        }
        field(3; "Integer Value"; Integer)
        {
            Caption = 'Integer Value';
            ToolTip = 'Specifies an integer value used for round-trip testing.';
        }
        field(4; "Decimal Value"; Decimal)
        {
            Caption = 'Decimal Value';
            ToolTip = 'Specifies a decimal value used for round-trip testing.';
        }
        field(5; "Boolean Value"; Boolean)
        {
            Caption = 'Boolean Value';
            ToolTip = 'Specifies a boolean value used for round-trip testing.';
        }
        field(6; "Date Value"; Date)
        {
            Caption = 'Date Value';
            ToolTip = 'Specifies a date value used for round-trip testing.';
        }
        field(7; "Related No."; Code[20])
        {
            Caption = 'Related No.';
            TableRelation = "Admin Tool Test Buffer"."No.";
            ToolTip = 'Specifies a related test buffer record, used to test table relation checks.';
        }
        field(8; "Time Value"; Time)
        {
            Caption = 'Time Value';
            ToolTip = 'Specifies a time value used for round-trip testing.';
        }
        field(9; "DateTime Value"; DateTime)
        {
            Caption = 'DateTime Value';
            ToolTip = 'Specifies a date-time value used for round-trip testing.';
        }
        field(10; "Guid Value"; Guid)
        {
            Caption = 'Guid Value';
            ToolTip = 'Specifies a GUID value used for round-trip testing.';
        }
        field(11; "Related System ID"; Guid)
        {
            Caption = 'Related System ID';
            TableRelation = "Admin Tool Test Buffer".SystemId;
            ToolTip = 'Specifies a related test buffer record by SystemId, used to test GUID-based relation checks.';
        }
        field(12; "Operation Type Value"; Enum "Backup Operation Type")
        {
            Caption = 'Operation Type Value';
            ToolTip = 'Specifies an enum value used for round-trip testing of ordinal-based backup and restore.';
        }
        field(13; "Record ID Value"; RecordId)
        {
            Caption = 'Record ID Value';
            ToolTip = 'Specifies a RecordID value, used to test that an unsupported field type is skipped during restore.';
        }
        field(14; "Media Value"; Media)
        {
            Caption = 'Media Value';
            ToolTip = 'Specifies a Media value, used to test that a table with a Media field can still be backed up and restored.';
        }
        field(15; "Related PK No."; Code[20])
        {
            Caption = 'Related PK No.';
            TableRelation = "Admin Tool Test Buffer";
            ToolTip = 'Specifies a related test buffer record by primary key, used to test relation checks without an explicit target field.';
        }
        field(16; "Related Special PK No."; Code[20])
        {
            Caption = 'Related Special PK No.';
            TableRelation = "Admin Tool Test PK Target";
            ToolTip = 'Specifies a related test PK target record, used to test relation checks against a primary key whose name contains filter special characters.';
        }
        field(17; "Duration Value"; Duration)
        {
            Caption = 'Duration Value';
            ToolTip = 'Specifies a duration value used for round-trip testing.';
        }
        field(18; "Date Formula Value"; DateFormula)
        {
            Caption = 'Date Formula Value';
            ToolTip = 'Specifies a date formula value used for round-trip testing.';
        }
        field(19; "Option Value"; Option)
        {
            Caption = 'Option Value';
            OptionCaption = ' ,First,Second';
            OptionMembers = " ",First,Second;
            ToolTip = 'Specifies an option value used for round-trip testing.';
        }
        field(20; "Closing Date Value"; Date)
        {
            Caption = 'Closing Date Value';
            ToolTip = 'Specifies a closing date value used for round-trip testing.';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
