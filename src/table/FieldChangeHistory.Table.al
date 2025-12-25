table 51016 "Field Change History"
{
    Caption = 'Field Change History';
    DataClassification = CustomerContent;
    InherentEntitlements = RX;
    InherentPermissions = RX;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the entry number.';
        }
        field(2; "Audit Log Entry No."; Integer)
        {
            AllowInCustomizations = AsReadOnly;
            Caption = 'Audit Log Entry No.';
            TableRelation = "Audit Log Entry"."Entry No.";
        }
        field(3; "Table ID"; Integer)
        {
            AllowInCustomizations = AsReadOnly;
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(4; "Table Name"; Text[249])
        {
            AllowInCustomizations = AsReadOnly;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Field No."; Integer)
        {
            AllowInCustomizations = AsReadOnly;
            Caption = 'Field No.';
            ToolTip = 'Specifies the field number.';
        }
        field(6; "Field Name"; Text[30])
        {
            AllowInCustomizations = AsReadOnly;
            Caption = 'Field Name';
            ToolTip = 'Specifies the field name.';
        }
        field(7; "Field Caption"; Text[80])
        {
            AllowInCustomizations = AsReadOnly;
            Caption = 'Field Caption';
            ToolTip = 'Specifies the field caption.';
        }
        field(8; "Old Value"; Text[2048])
        {
            AllowInCustomizations = AsReadOnly;
            Caption = 'Old Value';
            ToolTip = 'Specifies the old value before the change.';
        }
        field(9; "New Value"; Text[2048])
        {
            AllowInCustomizations = AsReadOnly;
            Caption = 'New Value';
            ToolTip = 'Specifies the new value after the change.';
        }
        field(10; "Date Time"; DateTime)
        {
            Caption = 'Date Time';
            Editable = false;
            ToolTip = 'Specifies when the change was made.';
        }
        field(11; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ToolTip = 'Specifies who made the change.';
        }
        field(12; "Record ID"; RecordId)
        {
            AllowInCustomizations = AsReadOnly;
            Caption = 'Record ID';
        }
        field(13; "Primary Key Value"; Text[250])
        {
            AllowInCustomizations = AsReadOnly;
            Caption = 'Primary Key Value';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(AuditLog; "Audit Log Entry No.", "Field No.")
        {
        }
        key(TableField; "Table ID", "Field No.", "Date Time")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Field Caption", "Date Time", "User ID")
        {
        }
        fieldgroup(Brick; "Field Caption", "Old Value", "New Value")
        {
        }
    }

    procedure ViewAuditLogEntry()
    var
        AuditLogEntry: Record "Audit Log Entry";
    begin
        if AuditLogEntry.Get(Rec."Audit Log Entry No.") then
            Page.Run(Page::"Audit Log Entry Card", AuditLogEntry);
    end;
}
