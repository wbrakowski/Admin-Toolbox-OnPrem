table 51015 "Audit Log Entry"
{
    Caption = 'Audit Log Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "Audit Log Entries";
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    LookupPageId = "Audit Log Entries";
    Permissions = tabledata "Field Change History" = RMD,
                  tabledata "Table Backup" = R;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the entry number of the audit log entry.';
        }
        field(2; "Operation Type"; Enum "Audit Log Operation Type")
        {
            Caption = 'Operation Type';
            ToolTip = 'Specifies the type of operation that was performed.';
        }
        field(3; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
            ToolTip = 'Specifies the ID of the table that was affected.';
        }
        field(4; "Table Name"; Text[249])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the name of the table that was affected.';
        }
        field(5; "Date Time"; DateTime)
        {
            Caption = 'Date Time';
            Editable = false;
            ToolTip = 'Specifies when the operation was performed.';
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            ToolTip = 'Specifies who performed the operation.';
        }
        field(7; Status; Enum "Audit Log Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies the status of the operation.';
        }
        field(8; "No. of Records Affected"; Integer)
        {
            Caption = 'No. of Records Affected';
            ToolTip = 'Specifies the number of records that were successfully affected by the operation.';
        }
        field(9; "No. of Records Failed"; Integer)
        {
            Caption = 'No. of Records Failed';
            ToolTip = 'Specifies the number of records that failed during the operation.';
        }
        field(10; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the operation.';
        }
        field(11; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            ToolTip = 'Specifies the error message if the operation failed.';
        }
        field(12; "Backup Created"; Boolean)
        {
            Caption = 'Backup Created';
            ToolTip = 'Specifies whether a backup was created before the operation.';
        }
        field(13; "Backup Entry No."; Integer)
        {
            Caption = 'Backup Entry No.';
            TableRelation = "Table Backup"."Entry No.";
            ToolTip = 'Specifies the entry number of the related backup.';
        }
        field(14; "Record ID"; RecordId)
        {
            Caption = 'Record ID';
            ToolTip = 'Specifies the record ID that was affected.';
        }
        field(15; "Primary Key Value"; Text[250])
        {
            Caption = 'Primary Key Value';
            ToolTip = 'Specifies the primary key value of the affected record.';
        }
        field(16; "Duration (ms)"; Integer)
        {
            Caption = 'Duration (ms)';
            ToolTip = 'Specifies the duration of the operation in milliseconds.';
        }
        field(17; "No. of Fields Changed"; Integer)
        {
            Caption = 'No. of Fields Changed';
            ToolTip = 'Specifies the number of fields that were changed during the operation.';
        }
        field(18; "Triggered By"; Text[100])
        {
            Caption = 'Triggered By';
            ToolTip = 'Specifies what triggered the operation (e.g., user action, automated process).';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(DateTime; "Date Time")
        {
        }
        key(TableID; "Table ID", "Date Time")
        {
        }
        key(UserID; "User ID", "Date Time")
        {
        }
        key(Status; Status, "Date Time")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Date Time", "Operation Type", "Table Name", Status)
        {
        }
        fieldgroup(Brick; "Entry No.", "Operation Type", "Table Name", "Date Time", Status)
        {
        }
    }

    trigger OnDelete()
    var
        FieldChangeHistory: Record "Field Change History";
    begin
        // Delete related field change history
        FieldChangeHistory.SetRange("Audit Log Entry No.", Rec."Entry No.");
        FieldChangeHistory.DeleteAll(false);
    end;

    procedure ViewFieldChanges()
    var
        FieldChangeHistory: Record "Field Change History";
        FieldChangeHistoryPage: Page "Field Change History";
    begin
        FieldChangeHistory.SetRange("Audit Log Entry No.", Rec."Entry No.");
        FieldChangeHistoryPage.SetTableView(FieldChangeHistory);
        FieldChangeHistoryPage.Run();
    end;

    procedure ViewRelatedBackup()
    var
        TableBackup: Record "Table Backup";
    begin
        if not Rec."Backup Created" then
            exit;

        if Rec."Backup Entry No." = 0 then
            exit;

        if TableBackup.Get(Rec."Backup Entry No.") then
            Page.Run(Page::"Table Backup Card", TableBackup);
    end;
}
