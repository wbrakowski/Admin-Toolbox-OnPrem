namespace AdminToolbox;

using System.Reflection;
using System.Utilities;

codeunit 51003 "Table Backup Mgt."
{
    Permissions = tabledata "Table Backup" = rimd;

    procedure CreateBackup(TableID: Integer; BackupType: Enum "Backup Type"; OperationType: Enum "Backup Operation Type"; BackupDescription: Text[250]; ConfirmUnsupportedFields: Boolean): Integer
    var
        TableBackup: Record "Table Backup";
        RecordRef: RecordRef;
        ProgressDialog: Dialog;
        BackupTypeToUse: Enum "Backup Type";
    begin
        // AL does not short-circuit "and": the confirm has a side effect (a dialog), so it must only be called when requested.
        if ConfirmUnsupportedFields then
            if not ConfirmBackupWithUnsupportedFields(TableID) then
                exit(0);

        BackupTypeToUse := GetBackupTypeToUse(BackupType);

        TableBackup.Init();
        TableBackup."Table ID" := TableID;
        TableBackup."Backup Type" := BackupTypeToUse;
        TableBackup."Operation Type" := OperationType;
        TableBackup.Description := BackupDescription;
        TableBackup.Insert(true);

        RecordRef.Open(TableID);
        TableBackup."No. of Records" := RecordRef.Count();
        RecordRef.Close();

        OpenBackupProgressDialog(ProgressDialog, TableBackup, 'Converting data to backup format...');
        if BackupTypeToUse = BackupTypeToUse::Snapshot then
            AssignSnapshotTableId(TableBackup);
        ExportTableToJSON(TableBackup, ProgressDialog);
        CloseProgressDialogIfAllowed(ProgressDialog);

        TableBackup.Modify(true);
        exit(TableBackup."Entry No.");
    end;

    procedure CreateBackupWithFilter(TableID: Integer; BackupType: Enum "Backup Type"; OperationType: Enum "Backup Operation Type"; BackupDescription: Text[250]; FilterView: Text; ConfirmUnsupportedFields: Boolean): Integer
    var
        TableBackup: Record "Table Backup";
        RecordRef: RecordRef;
        ProgressDialog: Dialog;
        BackupTypeToUse: Enum "Backup Type";
    begin
        // AL does not short-circuit "and": the confirm has a side effect (a dialog), so it must only be called when requested.
        if ConfirmUnsupportedFields then
            if not ConfirmBackupWithUnsupportedFields(TableID) then
                exit(0);

        BackupTypeToUse := GetBackupTypeToUse(BackupType);

        TableBackup.Init();
        TableBackup."Table ID" := TableID;
        TableBackup."Backup Type" := BackupTypeToUse;
        TableBackup."Operation Type" := OperationType;
        TableBackup.Description := BackupDescription;
        TableBackup."Filter View" := CopyStr(FilterView, 1, MaxStrLen(TableBackup."Filter View"));
        TableBackup.Insert(true);

        RecordRef.Open(TableID);
        RecordRef.SetView(FilterView);
        TableBackup."No. of Records" := RecordRef.Count();
        RecordRef.Close();

        OpenBackupProgressDialog(ProgressDialog, TableBackup, 'Converting filtered data to backup format...');
        ExportTableToJSONWithFilter(TableBackup, FilterView, ProgressDialog);
        CloseProgressDialogIfAllowed(ProgressDialog);

        TableBackup.Modify(true);
        exit(TableBackup."Entry No.");
    end;

    /// <summary>
    /// Validates the view against the table and returns it, or an empty text if the view sets no filter (e.g. only a sort order).
    /// </summary>
    procedure NormalizeFilterView(TableID: Integer; FilterView: Text): Text
    var
        RecordRef: RecordRef;
    begin
        if FilterView = '' then
            exit('');

        RecordRef.Open(TableID);
        RecordRef.SetView(FilterView);
        if not RecordRef.HasFilter() then
            exit('');

        exit(FilterView);
    end;

    local procedure GetBackupTypeToUse(BackupType: Enum "Backup Type"): Enum "Backup Type"
    begin
        // Ensure a valid backup type is used (fallback to JSON Export if 0)
        if BackupType.AsInteger() = 0 then
            exit(BackupType::"JSON Export");
        exit(BackupType);
    end;

    local procedure OpenBackupProgressDialog(var ProgressDialog: Dialog; TableBackup: Record "Table Backup"; StatusText: Text)
    var
        CreatingBackupTxt: Label 'Creating Backup...\\Table ID: #1######\\Records: #2######\\Status: #3##################', Comment = '%1 = Table ID, %2 = No. of Records, %3 = Status';
    begin
        if not GuiAllowed() then
            exit;

        ProgressDialog.Open(CreatingBackupTxt);
        ProgressDialog.Update(1, TableBackup."Table ID");
        ProgressDialog.Update(2, TableBackup."No. of Records");
        ProgressDialog.Update(3, StatusText);
    end;

    local procedure CloseProgressDialogIfAllowed(var ProgressDialog: Dialog)
    begin
        if GuiAllowed() then
            ProgressDialog.Close();
    end;

    local procedure ExportTableToJSON(var TableBackup: Record "Table Backup"; var ProgressDialog: Dialog)
    var
        RecordRef: RecordRef;
    begin
        if GuiAllowed() then
            ProgressDialog.Update(3, 'Reading table data...');

        RecordRef.Open(TableBackup."Table ID");
        WriteTableToBackupBlob(TableBackup, RecordRef, ProgressDialog);
        RecordRef.Close();
    end;

    local procedure ExportTableToJSONWithFilter(var TableBackup: Record "Table Backup"; FilterView: Text; var ProgressDialog: Dialog)
    var
        RecordRef: RecordRef;
    begin
        if GuiAllowed() then
            ProgressDialog.Update(3, 'Reading filtered table data...');

        RecordRef.Open(TableBackup."Table ID");
        RecordRef.SetView(FilterView);
        WriteTableToBackupBlob(TableBackup, RecordRef, ProgressDialog);
        RecordRef.Close();
    end;

    local procedure WriteTableToBackupBlob(var TableBackup: Record "Table Backup"; var RecordRef: RecordRef; var ProgressDialog: Dialog)
    var
        OutStream: OutStream;
        WrittenChars: BigInteger;
    begin
        TableBackup."Backup Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        WrittenChars := WriteRecordsAsJSON(RecordRef, OutStream, ProgressDialog);

        TableBackup."Backup Size (KB)" := Round(WrittenChars / 1024, 0.01);
        TableBackup."File Name" := CopyStr(GetBackupFileName(TableBackup), 1, MaxStrLen(TableBackup."File Name"));

        if GuiAllowed() then
            ProgressDialog.Update(3, 'Backup completed');
    end;

    // Writes the JSON array record by record, so neither the whole array nor its text lives in memory.
    // The output is identical to JsonArray.WriteTo(). Returns the number of characters written.
    local procedure WriteRecordsAsJSON(var RecordRef: RecordRef; var OutStream: OutStream; var ProgressDialog: Dialog): BigInteger
    var
        TempExportField: Record Field temporary;
        JSONObject: JsonObject;
        CurrentRecord: Integer;
        RecordCount: Integer;
        WrittenChars: BigInteger;
        RecordJSONText: Text;
    begin
        CollectTableFields(RecordRef.Number(), TempExportField);
        RecordCount := RecordRef.Count();

        OutStream.WriteText('[');
        WrittenChars := 1;

        if RecordRef.FindSet() then
            repeat
                CurrentRecord += 1;
                UpdateProgressIfNeeded(ProgressDialog, CurrentRecord, RecordCount);

                JSONObject := ConvertRecordToJSON(RecordRef, TempExportField);
                JSONObject.WriteTo(RecordJSONText);
                if CurrentRecord > 1 then begin
                    OutStream.WriteText(',');
                    WrittenChars += 1;
                end;
                OutStream.WriteText(RecordJSONText);
                WrittenChars += StrLen(RecordJSONText);
            until RecordRef.Next() = 0;

        OutStream.WriteText(']');
        exit(WrittenChars + 1);
    end;

    // Loads the field metadata once per table instead of re-querying the Field system table for every data record.
    local procedure CollectTableFields(TableID: Integer; var TempCachedField: Record Field temporary)
    var
        Field: Record Field;
    begin
        Field.SetRange(TableNo, TableID);
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
        Field.SetLoadFields("No.", FieldName, Type);

        if Field.FindSet() then
            repeat
                TempCachedField := Field;
                TempCachedField.Insert(false);
            until Field.Next() = 0;
    end;

    local procedure UpdateProgressIfNeeded(var ProgressDialog: Dialog; CurrentRecord: Integer; RecordCount: Integer)
    var
        ProcessingRecordLbl: Label 'Processing record %1 of %2...', Comment = 'DEU="Verarbeite Datensatz %1 von %2...",ESP="Procesando registro %1 de %2...",PLACEHOLDER="%1 = Current record number, %2 = Total records"';
    begin
        if not GuiAllowed() then
            exit;

        if (CurrentRecord mod 100 = 0) or (CurrentRecord = RecordCount) then
            ProgressDialog.Update(3, StrSubstNo(ProcessingRecordLbl, CurrentRecord, RecordCount));
    end;

    local procedure ConvertRecordToJSON(var RecordRef: RecordRef; var TempExportField: Record Field temporary): JsonObject
    var
        JSONObject: JsonObject;
    begin
        if TempExportField.FindSet() then
            repeat
                AddRecordFieldToJSON(RecordRef, TempExportField, JSONObject);
            until TempExportField.Next() = 0;

        exit(JSONObject);
    end;

    local procedure AddRecordFieldToJSON(var RecordRef: RecordRef; Field: Record Field; var JSONObject: JsonObject)
    var
        FieldRef: FieldRef;
    begin
        // Only field types with a known-safe, round-trippable text representation are exported;
        // anything else (BLOB, Media, MediaSet, RecordID, ...) is skipped here and on restore.
        if not IsFieldTypeSupportedForBackup(Field.Type) then
            exit;

        FieldRef := RecordRef.Field(Field."No.");
        AddFieldToJSON(JSONObject, Field.FieldName, GetFieldValueAsText(FieldRef, Field.Type));
    end;

#pragma warning disable LC0010, LC0088
    local procedure IsFieldTypeSupportedForBackup(FieldType: Option): Boolean
    var
        Field: Record Field;
    begin
        exit(FieldType in [
            Field.Type::Integer, Field.Type::BigInteger, Field.Type::Decimal, Field.Type::Boolean,
            Field.Type::Date, Field.Type::Time, Field.Type::DateTime, Field.Type::GUID,
            Field.Type::Option, Field.Type::Text, Field.Type::Code,
            Field.Type::Duration, Field.Type::DateFormula]);
    end;
#pragma warning restore LC0010, LC0088

#pragma warning disable LC0010, LC0088
    local procedure GetFieldValueAsText(var FieldRef: FieldRef; FieldType: Option): Text
    var
        Field: Record Field;
    begin
        // Every non-text value is stored in the culture-invariant XML format (Format 9), so a backup created
        // under one regional setting can be restored under another. Text and Code are written verbatim.
        if FieldType in [Field.Type::Text, Field.Type::Code] then
            exit(Format(FieldRef.Value()));
        if FieldType = Field.Type::Date then
            exit(GetDateAsText(FieldRef));
        exit(Format(FieldRef.Value(), 0, 9));
    end;
#pragma warning restore LC0010, LC0088

    local procedure GetDateAsText(var FieldRef: FieldRef): Text
    var
        DateValue: Date;
    begin
        // Format 9 drops the closing date flag, so a closing date is stored as the prefix C plus the normal date.
        DateValue := FieldRef.Value();
        if DateValue = 0D then
            exit('');

        if DateValue <> NormalDate(DateValue) then
            exit(ClosingDatePrefixTok + Format(NormalDate(DateValue), 0, 9));
        exit(Format(DateValue, 0, 9));
    end;

    local procedure AddFieldToJSON(var JSONObject: JsonObject; FieldName: Text; FieldValue: Text)
    var
        JSONValue: JsonValue;
    begin
        JSONValue.SetValue(FieldValue);
        JSONObject.Add(FieldName, JSONValue);
    end;

    local procedure AssignSnapshotTableId(var TableBackup: Record "Table Backup")
    begin
        // Snapshots are stored as JSON like every other backup type; only the ID is reserved.
        TableBackup."Snapshot Table ID" := GetNextSnapshotTableId();
    end;

    procedure RestoreBackup(var TableBackup: Record "Table Backup")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        RestoreConfirmQst: Label 'Do you want to restore %1 records to table %2? This will INSERT the backed up records.\\Warning: This may create duplicate records if they still exist!', Comment = '%1 = No. of Records, %2 = Table ID';
    begin
        TableBackup.CalcFields("Table Name");
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(RestoreConfirmQst, TableBackup."No. of Records", TableBackup."Table Name"), false) then
            exit;

        // Every backup type is stored as JSON. RestoreFromJSON already reports the result to the user.
        RestoreFromJSON(TableBackup);

        TableBackup.Restored := true;
        TableBackup."Restore Date Time" := CurrentDateTime();
        TableBackup.Modify(true);
    end;

#pragma warning disable LC0010, LC0090
    // internal (not local) so the test app can exercise the restore logic without the interactive confirm dialog
    internal procedure RestoreFromJSON(var TableBackup: Record "Table Backup")
    var
        TempRestoreField: Record Field temporary;
        RecordRef: RecordRef;
        InStream: InStream;
        i: Integer;
        InsertedCount: Integer;
        FailedCount: Integer;
        JSONArray: JsonArray;
        JSONText: Text;
        ProgressDialog: Dialog;
        RestoringTxt: Label 'Restoring records...\\Processed: #1######\\Inserted: #2######\\Failed: #3######', Comment = '#1 = Processed count, #2 = Inserted count, #3 = Failed count';
        NoRecordsInBackupErr: Label 'No records found in backup data.';
    begin
        TableBackup.CalcFields("Backup Data", "Table Name");
        TableBackup."Backup Data".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(JSONText);

        if not JSONArray.ReadFrom(JSONText) then
            Error(InvalidJSONErr);

        if JSONArray.Count() = 0 then
            Error(NoRecordsInBackupErr);

        RecordRef.Open(TableBackup."Table ID");
        CollectTableFields(TableBackup."Table ID", TempRestoreField);

        if GuiAllowed() then
            InitializeProgressDialog(ProgressDialog, RestoringTxt);

        for i := 0 to JSONArray.Count() - 1 do
            ProcessRestoreRecord(RecordRef, TempRestoreField, JSONArray, i, InsertedCount, FailedCount, ProgressDialog);

        RecordRef.Close();

        if GuiAllowed() then
            FinalizeProgressDialog(ProgressDialog, JSONArray.Count(), InsertedCount, FailedCount);

        ValidateRestoreResult(InsertedCount, FailedCount, JSONArray.Count(), TableBackup."Table Name");
    end;
#pragma warning restore LC0010, LC0090

    local procedure InitializeProgressDialog(var ProgressDialog: Dialog; ProgressText: Text)
    begin
        ProgressDialog.Open(ProgressText);
        ProgressDialog.Update(1, 0);
        ProgressDialog.Update(2, 0);
        ProgressDialog.Update(3, 0);
    end;

    local procedure ProcessRestoreRecord(var RecordRef: RecordRef; var TempRestoreField: Record Field temporary; var JSONArray: JsonArray; Index: Integer; var InsertedCount: Integer; var FailedCount: Integer; var ProgressDialog: Dialog)
    var
        JSONToken: JsonToken;
    begin
        JSONArray.Get(Index, JSONToken);
        if not JSONToken.IsObject() then
            exit;

        if InsertRecordFromJSON(RecordRef, TempRestoreField, JSONToken.AsObject()) then
            InsertedCount += 1
        else
            FailedCount += 1;

        if GuiAllowed() and ((Index mod 10) = 0) then
            UpdateProgressDialog(ProgressDialog, Index + 1, InsertedCount, FailedCount);
    end;

    local procedure UpdateProgressDialog(var ProgressDialog: Dialog; Processed: Integer; Inserted: Integer; Failed: Integer)
    begin
        ProgressDialog.Update(1, Processed);
        ProgressDialog.Update(2, Inserted);
        ProgressDialog.Update(3, Failed);
    end;

    local procedure FinalizeProgressDialog(var ProgressDialog: Dialog; TotalCount: Integer; InsertedCount: Integer; FailedCount: Integer)
    begin
        UpdateProgressDialog(ProgressDialog, TotalCount, InsertedCount, FailedCount);
        ProgressDialog.Close();
    end;

    local procedure ValidateRestoreResult(InsertedCount: Integer; FailedCount: Integer; TotalCount: Integer; TableName: Text)
    var
        AllInsertFailedErr: Label 'No records could be inserted. All %1 attempts failed.', Comment = '%1 = Number of failed attempts';
        PartialRestoreMsg: Label 'Restored %1 of %2 records. %3 records failed to insert (possibly due to duplicates or validation errors).', Comment = '%1 = Inserted count, %2 = Total count, %3 = Failed count';
    begin
        if InsertedCount = 0 then
            Error(AllInsertFailedErr, FailedCount);

        if FailedCount > 0 then
            Message(PartialRestoreMsg, InsertedCount, TotalCount, FailedCount)
        else
            Message(BackupRestoredMsg, InsertedCount, TableName);
    end;

    local procedure InsertRecordFromJSON(var RecordRef: RecordRef; var TempRestoreField: Record Field temporary; JSONObject: JsonObject): Boolean
    begin
        RecordRef.Init();

        // A runtime error while assigning a field (e.g. a value rejected by the field) fails only this record, not the whole restore.
        if not TryPopulateRecordFieldsFromJSON(RecordRef, TempRestoreField, JSONObject) then
            exit(false);

        // Use Insert(true) to ensure system fields like SystemId are properly set
        exit(RecordRef.Insert(true));
    end;

    // A TryFunction is safe here: the field population is pure in-memory work, nothing is written to the database.
    [TryFunction]
    local procedure TryPopulateRecordFieldsFromJSON(var RecordRef: RecordRef; var TempRestoreField: Record Field temporary; JSONObject: JsonObject)
    begin
        PopulateRecordFieldsFromJSON(RecordRef, TempRestoreField, JSONObject);
    end;

    local procedure PopulateRecordFieldsFromJSON(var RecordRef: RecordRef; var TempRestoreField: Record Field temporary; JSONObject: JsonObject)
    begin
        if TempRestoreField.FindSet() then
            repeat
                SetFieldValueFromJSON(RecordRef, TempRestoreField, JSONObject);
            until TempRestoreField.Next() = 0;
    end;

    local procedure SetFieldValueFromJSON(var RecordRef: RecordRef; Field: Record Field; JSONObject: JsonObject)
    var
        JSONToken: JsonToken;
        FieldValue: Text;
    begin
        if not JSONObject.Get(Field.FieldName, JSONToken) then
            exit;

        if JSONToken.AsValue().IsNull() then
            exit;

        FieldValue := JSONToken.AsValue().AsText();
        if FieldValue = '' then
            exit;

        // A failed FieldRef.Value() call for an unsupported type can corrupt the whole record buffer,
        // so such values are never attempted at all.
        if not IsFieldTypeSupportedForBackup(Field.Type) then
            exit;

        AssignFieldValueToRecord(RecordRef, Field, FieldValue);
    end;

    local procedure AssignFieldValueToRecord(var RecordRef: RecordRef; Field: Record Field; FieldValue: Text)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(Field."No.");
        AssignFieldValue(FieldRef, FieldValue, Field.Type);
    end;

#pragma warning disable LC0010, LC0088
    local procedure AssignFieldValue(var FieldRef: FieldRef; FieldValue: Text; FieldType: Option)
    var
        Field: Record Field;
    begin
        case FieldType of
            Field.Type::Integer, Field.Type::BigInteger:
                AssignIntegerValue(FieldRef, FieldValue);
            Field.Type::Decimal:
                AssignDecimalValue(FieldRef, FieldValue);
            Field.Type::Boolean:
                AssignBooleanValue(FieldRef, FieldValue);
            Field.Type::Date:
                AssignDateValue(FieldRef, FieldValue);
            Field.Type::Time:
                AssignTimeValue(FieldRef, FieldValue);
            Field.Type::DateTime:
                AssignDateTimeValue(FieldRef, FieldValue);
            Field.Type::GUID:
                AssignGuidValue(FieldRef, FieldValue);
            Field.Type::Option:
                AssignOptionValue(FieldRef, FieldValue);
            Field.Type::Duration:
                AssignDurationValue(FieldRef, FieldValue);
            Field.Type::DateFormula:
                AssignDateFormulaValue(FieldRef, FieldValue);
            else
                AssignTextValue(FieldRef, FieldValue);
        end;
    end;
#pragma warning restore LC0010, LC0088

    // The Assign*Value procedures first parse the culture-invariant representation written by GetFieldValueAsText
    // (Format 9). The plain Evaluate is a fallback for backups created before invariant serialization existed.
    local procedure AssignIntegerValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        IntegerValue: Integer;
    begin
        if not Evaluate(IntegerValue, FieldValue, 9) then
            if not Evaluate(IntegerValue, FieldValue) then
                ErrorInvalidFieldValue(FieldRef, FieldValue);
        FieldRef.Value(IntegerValue);
    end;

    local procedure AssignDecimalValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        DecimalValue: Decimal;
    begin
        if not Evaluate(DecimalValue, FieldValue, 9) then
            if not Evaluate(DecimalValue, FieldValue) then
                ErrorInvalidFieldValue(FieldRef, FieldValue);
        FieldRef.Value(DecimalValue);
    end;

    local procedure AssignBooleanValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        BooleanValue: Boolean;
    begin
        if not Evaluate(BooleanValue, FieldValue, 9) then
            if not Evaluate(BooleanValue, FieldValue) then
                ErrorInvalidFieldValue(FieldRef, FieldValue);
        FieldRef.Value(BooleanValue);
    end;

    local procedure AssignDateValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        DateValue: Date;
    begin
        if CopyStr(FieldValue, 1, 1) = ClosingDatePrefixTok then
            if Evaluate(DateValue, CopyStr(FieldValue, 2), 9) then begin
                FieldRef.Value(ClosingDate(DateValue));
                exit;
            end;

        if not Evaluate(DateValue, FieldValue, 9) then
            if not Evaluate(DateValue, FieldValue) then
                ErrorInvalidFieldValue(FieldRef, FieldValue);
        FieldRef.Value(DateValue);
    end;

    local procedure AssignTimeValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        TimeValue: Time;
    begin
        if not Evaluate(TimeValue, FieldValue, 9) then
            if not Evaluate(TimeValue, FieldValue) then
                ErrorInvalidFieldValue(FieldRef, FieldValue);
        FieldRef.Value(TimeValue);
    end;

    local procedure AssignDateTimeValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        DateTimeValue: DateTime;
    begin
        if not Evaluate(DateTimeValue, FieldValue, 9) then
            if not Evaluate(DateTimeValue, FieldValue) then
                ErrorInvalidFieldValue(FieldRef, FieldValue);
        FieldRef.Value(DateTimeValue);
    end;

    local procedure AssignGuidValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        GuidValue: Guid;
    begin
        if not Evaluate(GuidValue, FieldValue, 9) then
            if not Evaluate(GuidValue, FieldValue) then
                ErrorInvalidFieldValue(FieldRef, FieldValue);
        FieldRef.Value(GuidValue);
    end;

    local procedure AssignDurationValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        DurationValue: Duration;
    begin
        if not Evaluate(DurationValue, FieldValue, 9) then
            if not Evaluate(DurationValue, FieldValue) then
                ErrorInvalidFieldValue(FieldRef, FieldValue);
        FieldRef.Value(DurationValue);
    end;

    local procedure AssignDateFormulaValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        DateFormulaValue: DateFormula;
    begin
        if not Evaluate(DateFormulaValue, FieldValue, 9) then
            if not Evaluate(DateFormulaValue, FieldValue) then
                ErrorInvalidFieldValue(FieldRef, FieldValue);
        FieldRef.Value(DateFormulaValue);
    end;

    local procedure AssignOptionValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        OptionOrdinal: Integer;
    begin
        // Options and enums are exported as their ordinal value, so assign it directly instead of matching a locale-dependent caption.
        // Backups from before that format hold the caption, which Evaluate resolves in the language of the session.
        if Evaluate(OptionOrdinal, FieldValue) then begin
            FieldRef.Value(OptionOrdinal);
            exit;
        end;

        if not Evaluate(FieldRef, FieldValue) then
            ErrorInvalidFieldValue(FieldRef, FieldValue);
    end;

    // The value cannot be converted: fail the record instead of restoring it with a default value.
    local procedure ErrorInvalidFieldValue(var FieldRef: FieldRef; FieldValue: Text)
    var
        InvalidFieldValueErr: Label 'The value ''%1'' cannot be converted for the field ''%2''.', Comment = '%1 = Value from the backup, %2 = Field Name';
    begin
        Error(InvalidFieldValueErr, FieldValue, FieldRef.Name());
    end;

    local procedure AssignTextValue(var FieldRef: FieldRef; FieldValue: Text)
    begin
        if FieldRef.Length() > 0 then
            FieldRef.Value(CopyStr(FieldValue, 1, FieldRef.Length()))
        else
            FieldRef.Value(FieldValue);
    end;

    procedure ExportBackupToFile(var TableBackup: Record "Table Backup")
    var
        InStream: InStream;
        FileName: Text;
    begin
        TableBackup.CalcFields("Backup Data", "Table Name");

        if not TableBackup."Backup Data".HasValue() then
            Error(NoBackupDataErr);

        FileName := GetBackupFileName(TableBackup);
        TableBackup."Backup Data".CreateInStream(InStream);

        DownloadFromStream(InStream, ExportBackupTxt, '', FileFilterTxt, FileName);
    end;

    procedure ViewBackupData(var TableBackup: Record "Table Backup")
    var
        InStream: InStream;
        JSONText: Text;
    begin
        TableBackup.CalcFields("Backup Data");

        if not TableBackup."Backup Data".HasValue() then
            Error(NoBackupDataErr);

        TableBackup."Backup Data".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(JSONText);

        Message(ViewBackupDataMsg, TableBackup."Entry No.", CopyStr(JSONText, 1, 1000));
    end;

    procedure DeleteSnapshotTable(SnapshotTableID: Integer)
    begin
        // Snapshots are stored as JSON, so there is no snapshot table to clean up.
        if SnapshotTableID = 0 then
            exit;
    end;

    local procedure ConfirmBackupWithUnsupportedFields(TableID: Integer): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        TableContainsUnsupportedFieldsQst: Label 'Table %1 %2 contains field type(s) that cannot be backed up (e.g. BLOB, Media, RecordID). They are skipped during backup and cannot be restored.\\Do you want to continue?', Comment = '%1 = Table ID, %2 = Table Name';
    begin
        if not TableHasUnsupportedFields(TableID) then
            exit(true);

        exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(TableContainsUnsupportedFieldsQst, TableID, GetTableCaption(TableID)), true));
    end;

    // internal (not local) so tests and the deletion can check tables without opening the confirm dialog
    internal procedure TableHasUnsupportedFields(TableID: Integer): Boolean
    var
        Field: Record Field;
    begin
        Field.SetRange(TableNo, TableID);
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
        Field.SetLoadFields(Type);

        if Field.FindSet() then
            repeat
                if not IsFieldTypeSupportedForBackup(Field.Type) then
                    exit(true);
            until Field.Next() = 0;

        exit(false);
    end;

    internal procedure GetTableCaption(TableID: Integer): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", TableID);
        AllObjWithCaption.SetLoadFields("Object Caption");
        if AllObjWithCaption.FindFirst() then
            exit(AllObjWithCaption."Object Caption");
        exit('');
    end;

    internal procedure CountOldBackups(DaysToKeep: Integer): Integer
    var
        TableBackup: Record "Table Backup";
    begin
        if DaysToKeep <= 0 then
            exit(0);

        TableBackup.SetFilter("Backup Date Time", '<%1', CreateDateTime(Today() - DaysToKeep, 0T));
        exit(TableBackup.Count());
    end;

    // Deletes the backups that are older than the given number of days and returns how many were deleted.
    procedure DeleteOldBackups(DaysToKeep: Integer): Integer
    var
        TableBackup: Record "Table Backup";
        DeletedCount: Integer;
    begin
        if DaysToKeep <= 0 then
            exit(0);

        TableBackup.SetFilter("Backup Date Time", '<%1', CreateDateTime(Today() - DaysToKeep, 0T));
        DeletedCount := TableBackup.Count();
        TableBackup.DeleteAll(true);
        exit(DeletedCount);
    end;

    local procedure GetNextSnapshotTableId(): Integer
    var
        TableBackup: Record "Table Backup";
    begin
        TableBackup.SetFilter("Snapshot Table ID", '<>0');
        TableBackup.SetLoadFields("Snapshot Table ID");
        if TableBackup.FindLast() then
            exit(TableBackup."Snapshot Table ID" + 1);
        exit(99000001); // Starting point for snapshot table IDs
    end;

    local procedure GetBackupFileName(TableBackup: Record "Table Backup"): Text
    var
        FileNameTxt: Label 'Backup_Table_%1_%2_%3.json', Comment = '%1 = Table ID, %2 = Table Name, %3 = DateTime';
        DateTimeText: Text;
    begin
        TableBackup.CalcFields("Table Name");
        DateTimeText := Format(TableBackup."Backup Date Time", 0, '<Year4><Month,2><Day,2>_<Hours24><Minutes,2><Seconds,2>');
        exit(StrSubstNo(FileNameTxt, TableBackup."Table ID", DelChr(TableBackup."Table Name", '=', ' /\*?<>|":'), DateTimeText));
    end;

    procedure ImportBackupFromFile(TableID: Integer): Integer
    var
        TableBackup: Record "Table Backup";
        InStream: InStream;
        OutStream: OutStream;
        FileName: Text;
        JSONText: Text;
    begin
        if not UploadIntoStream(ImportBackupTxt, '', FileFilterTxt, FileName, InStream) then
            exit(0);

        TableBackup.Init();
        TableBackup."Table ID" := TableID;
        TableBackup."Backup Type" := TableBackup."Backup Type"::"JSON Export";
        TableBackup."Operation Type" := TableBackup."Operation Type"::"Manual Backup";
        TableBackup.Description := CopyStr(StrSubstNo(ImportedFromFileTxt, FileName), 1, MaxStrLen(TableBackup.Description));
        TableBackup."File Name" := CopyStr(FileName, 1, MaxStrLen(TableBackup."File Name"));
        TableBackup.Insert(true);

        // Read and store the JSON
        InStream.ReadText(JSONText);
        TableBackup."Backup Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(JSONText);
        TableBackup."Backup Size (KB)" := Round(StrLen(JSONText) / 1024, 0.01);

        // Count records in JSON
        TableBackup."No. of Records" := CountRecordsInJSON(JSONText);
        TableBackup.Modify(true);

        Message(ImportSuccessMsg, TableBackup."No. of Records", FileName);
        exit(TableBackup."Entry No.");
    end;

    local procedure CountRecordsInJSON(JSONText: Text): Integer
    var
        JSONArray: JsonArray;
    begin
        if JSONArray.ReadFrom(JSONText) then
            exit(JSONArray.Count());
        exit(0);
    end;

    var
        BackupRestoredMsg: Label '%1 records have been restored to table %2.', Comment = '%1 = No. of Records, %2 = Table Name';
        ClosingDatePrefixTok: Label 'C', Locked = true;
        ExportBackupTxt: Label 'Export Backup';
        FileFilterTxt: Label 'JSON Files (*.json)|*.json|All Files (*.*)|*.*';
        ImportBackupTxt: Label 'Import Backup';
        ImportedFromFileTxt: Label 'Imported from file: %1', Comment = '%1 = File Name';
        ImportSuccessMsg: Label '%1 records were imported from file %2.', Comment = '%1 = Record Count, %2 = File Name';
        InvalidJSONErr: Label 'The backup data contains invalid JSON format.';
        NoBackupDataErr: Label 'No backup data found for this entry.';
        ViewBackupDataMsg: Label 'Backup Entry No.: %1\\Data Preview (first 1000 chars):\\%2', Comment = '%1 = Entry No., %2 = JSON Preview';
}
