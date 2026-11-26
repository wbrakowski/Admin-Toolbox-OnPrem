namespace AdminToolbox;

using System.Security.User;
using System.Utilities;

codeunit 51005 "Table Editor Mgt."
{
    Permissions = tabledata "Admin Toolbox Setup" = r;

    procedure CheckSuperPermission()
    var
        UserPermissions: Codeunit "User Permissions";
        SuperRequiredErr: Label 'You need SUPER permissions to use the Table Editor.';
    begin
        if not UserPermissions.IsSuper(UserSecurityId()) then
            Error(SuperRequiredErr);
    end;

    procedure CountRecords(TableNo: Integer; FilterView: Text): Integer
    var
        RecordRef: RecordRef;
        NoOfRecords: Integer;
    begin
        if TableNo = 0 then
            exit(0);

        RecordRef.Open(TableNo);
        RecordRef.SetView(FilterView);
        NoOfRecords := RecordRef.Count();
        RecordRef.Close();
        exit(NoOfRecords);
    end;

    procedure ModifyRecords(TableNo: Integer; FilterView: Text; FieldNumber: Integer; FieldValue: Text; UseTableTrigger: Boolean; UseValidateTrigger: Boolean): Integer
    var
        AuditLogMgt: Codeunit "Audit Log Mgt.";
        FieldRef: FieldRef;
        ValueFieldRef: FieldRef;
        OldRecordRef: RecordRef;
        RecordRef: RecordRef;
        ValueRecordRef: RecordRef;
        AuditLogOperationType: Enum "Audit Log Operation Type";
        AuditLogStatus: Enum "Audit Log Status";
        AuditLogEntryNo: Integer;
        ModifiedCount: Integer;
        NewValue: Variant;
        ModifyDescriptionLbl: Label 'Modified field %1 to value %2', Comment = '%1 = Field Name, %2 = Field Value';
        TableEditorLbl: Label 'Table Editor';
    begin
        CheckSuperPermission();
        CheckTableIsEditable(TableNo);

        ValueRecordRef.Open(TableNo);
        ValueFieldRef := ValueRecordRef.Field(FieldNumber);
        Evaluate(ValueFieldRef, FieldValue);
        NewValue := ValueFieldRef.Value();

        RecordRef.Open(TableNo);
        RecordRef.SetView(FilterView);
        if not RecordRef.FindSet(true) then begin
            RecordRef.Close();
            ValueRecordRef.Close();
            exit(0);
        end;

        AuditLogEntryNo := AuditLogMgt.StartOperation(
            AuditLogOperationType::"Bulk Modify",
            TableNo,
            CopyStr(StrSubstNo(ModifyDescriptionLbl, ValueFieldRef.Name(), FieldValue), 1, 250),
            TableEditorLbl);

        repeat
            OldRecordRef := RecordRef.Duplicate();
            FieldRef := RecordRef.Field(FieldNumber);
            if UseValidateTrigger then
                FieldRef.Validate(NewValue)
            else
                FieldRef.Value(NewValue);
            RecordRef.Modify(UseTableTrigger);

            AuditLogMgt.LogFieldChanges(AuditLogEntryNo, OldRecordRef, RecordRef);
            ModifiedCount += 1;
        until RecordRef.Next() = 0;

        AuditLogMgt.CompleteOperation(AuditLogEntryNo, AuditLogStatus::Success, ModifiedCount, 0, '');
        RecordRef.Close();
        ValueRecordRef.Close();
        exit(ModifiedCount);
    end;

    procedure FieldIndexInPrimaryKey(TableNo: Integer; FieldNumber: Integer): Integer
    var
        RecordRef: RecordRef;
        PrimaryKeyRef: KeyRef;
        i: Integer;
    begin
        RecordRef.Open(TableNo);
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        for i := 1 to PrimaryKeyRef.FieldCount() do
            if FieldNumber = PrimaryKeyRef.FieldIndex(i).Number() then begin
                RecordRef.Close();
                exit(i);
            end;
        RecordRef.Close();
        exit(-1);
    end;

    local procedure CheckTableIsEditable(TableNo: Integer)
    var
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        ProtectedTableChangeErr: Label 'Table %1 %2 belongs to the Admin Toolbox or to the system and its records cannot be changed.', Comment = '%1 = Table ID, %2 = Table Name';
    begin
        if AdminToolMgt.IsTableProtected(TableNo) then
            Error(ProtectedTableChangeErr, TableNo, AdminToolMgt.GetTableCaption(TableNo));
    end;

    local procedure GetPrimaryKeyIndexOrError(TableNo: Integer; FieldNumber: Integer): Integer
    var
        IndexInPrimaryKey: Integer;
        FieldNotInPrimaryKeyErr: Label 'The field %1 is not part of the primary key of table %2.', Comment = '%1 = Field No., %2 = Table ID';
    begin
        IndexInPrimaryKey := FieldIndexInPrimaryKey(TableNo, FieldNumber);
        if IndexInPrimaryKey < 1 then
            Error(FieldNotInPrimaryKeyErr, FieldNumber, TableNo);
        exit(IndexInPrimaryKey);
    end;

    // Shows the user which primary key values the rename will use
    procedure GetRenamePreview(TableNo: Integer; FieldNumber: Integer; FieldValue: Text): Text
    var
        RecordRef: RecordRef;
        ValueFieldRef: FieldRef;
        IndexInPrimaryKey: Integer;
        PrimaryKeyRef: KeyRef;
        i: Integer;
        Preview: Text;
    begin
        IndexInPrimaryKey := GetPrimaryKeyIndexOrError(TableNo, FieldNumber);

        RecordRef.Open(TableNo);
        ValueFieldRef := RecordRef.Field(FieldNumber);
        Evaluate(ValueFieldRef, FieldValue);

        PrimaryKeyRef := RecordRef.KeyIndex(1);
        for i := 1 to PrimaryKeyRef.FieldCount() do
            if i = IndexInPrimaryKey then
                Preview += '[' + Format(ValueFieldRef) + '], '
            else
                Preview += '"' + PrimaryKeyRef.FieldIndex(i).Name() + '", ';
        RecordRef.Close();
        exit(DelStr(Preview, StrLen(Preview) - 1));
    end;

    procedure RenameRecords(TableNo: Integer; FilterView: Text; FieldNumber: Integer; FieldValue: Text): Integer
    var
        AuditLogMgt: Codeunit "Audit Log Mgt.";
        ValueFieldRef: FieldRef;
        PKFieldRef: array[16] of FieldRef;
        OldRecordRef: RecordRef;
        RecordRef: RecordRef;
        RenamedRecordRef: RecordRef;
        ValueRecordRef: RecordRef;
        AuditLogOperationType: Enum "Audit Log Operation Type";
        AuditLogStatus: Enum "Audit Log Status";
        AuditLogEntryNo: Integer;
        IndexInPrimaryKey: Integer;
        NoOfPrimaryKeys: Integer;
        RenamedCount: Integer;
        PrimaryKeyRef: KeyRef;
        i: Integer;
        Position: Text;
        Positions: List of [Text];
        RenameDescriptionLbl: Label 'Renamed field %1 to value %2', Comment = '%1 = Field Name, %2 = New Value';
        TableEditorLbl: Label 'Table Editor';
    begin
        CheckSuperPermission();
        CheckTableIsEditable(TableNo);
        IndexInPrimaryKey := GetPrimaryKeyIndexOrError(TableNo, FieldNumber);

        ValueRecordRef.Open(TableNo);
        ValueFieldRef := ValueRecordRef.Field(FieldNumber);
        Evaluate(ValueFieldRef, FieldValue);

        RecordRef.Open(TableNo);
        RecordRef.SetView(FilterView);
        if not RecordRef.FindSet(true) then begin
            RecordRef.Close();
            ValueRecordRef.Close();
            exit(0);
        end;

        PrimaryKeyRef := RecordRef.KeyIndex(1);
        NoOfPrimaryKeys := PrimaryKeyRef.FieldCount();
        for i := 1 to NoOfPrimaryKeys do
            PKFieldRef[i] := PrimaryKeyRef.FieldIndex(i);

        // Collect the positions first: a renamed record can sort behind the current position and would be visited twice
        repeat
            Positions.Add(RecordRef.GetPosition());
        until RecordRef.Next() = 0;

        AuditLogEntryNo := AuditLogMgt.StartOperation(
            AuditLogOperationType::"Bulk Modify",
            TableNo,
            CopyStr(StrSubstNo(RenameDescriptionLbl, ValueFieldRef.Name(), FieldValue), 1, 250),
            TableEditorLbl);

        foreach Position in Positions do begin
            RecordRef.SetPosition(Position);
            if RecordRef.Find('=') then begin
                OldRecordRef := RecordRef.Duplicate();
                RenamedRecordRef := RecordRef.Duplicate();

                PKFieldRef[IndexInPrimaryKey].Value(ValueFieldRef.Value());
                ExecuteRename(RenamedRecordRef, PKFieldRef, NoOfPrimaryKeys);

                AuditLogMgt.LogFieldChanges(AuditLogEntryNo, OldRecordRef, RenamedRecordRef);
                RenamedCount += 1;
            end;
        end;

        AuditLogMgt.CompleteOperation(AuditLogEntryNo, AuditLogStatus::Success, RenamedCount, 0, '');
        RecordRef.Close();
        ValueRecordRef.Close();
        exit(RenamedCount);
    end;

    local procedure ExecuteRename(var RenamedRecordRef: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        // Handle different numbers of primary key fields by delegating to specific procedures
        if NoOfPrimaryKeys <= 8 then
            ExecuteRenameUpTo8Keys(RenamedRecordRef, PKFieldRef, NoOfPrimaryKeys)
        else
            ExecuteRenameUpTo16Keys(RenamedRecordRef, PKFieldRef, NoOfPrimaryKeys);
    end;

    local procedure ExecuteRenameUpTo8Keys(var RenamedRecordRef: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        if NoOfPrimaryKeys <= 4 then
            ExecuteRename1To4Keys(RenamedRecordRef, PKFieldRef, NoOfPrimaryKeys)
        else
            ExecuteRename5To8Keys(RenamedRecordRef, PKFieldRef, NoOfPrimaryKeys);
    end;

    local procedure ExecuteRename1To4Keys(var RenamedRecordRef: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        case NoOfPrimaryKeys of
            1:
                RenamedRecordRef.Rename(PKFieldRef[1].Value());
            2:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value());
            3:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value());
            4:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value());
        end;
    end;

    local procedure ExecuteRename5To8Keys(var RenamedRecordRef: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        case NoOfPrimaryKeys of
            5:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value());
            6:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value());
            7:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value());
            8:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value());
        end;
    end;

    local procedure ExecuteRenameUpTo16Keys(var RenamedRecordRef: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        if NoOfPrimaryKeys <= 12 then
            ExecuteRename9To12Keys(RenamedRecordRef, PKFieldRef, NoOfPrimaryKeys)
        else
            ExecuteRename13To16Keys(RenamedRecordRef, PKFieldRef, NoOfPrimaryKeys);
    end;

    local procedure ExecuteRename9To12Keys(var RenamedRecordRef: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        case NoOfPrimaryKeys of
            9:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value());
            10:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value());
            11:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value(), PKFieldRef[11].Value());
            12:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value(), PKFieldRef[11].Value(), PKFieldRef[12].Value());
        end;
    end;

    local procedure ExecuteRename13To16Keys(var RenamedRecordRef: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        case NoOfPrimaryKeys of
            13:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value(), PKFieldRef[11].Value(), PKFieldRef[12].Value(), PKFieldRef[13].Value());
            14:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value(), PKFieldRef[11].Value(), PKFieldRef[12].Value(), PKFieldRef[13].Value(), PKFieldRef[14].Value());
            15:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value(), PKFieldRef[11].Value(), PKFieldRef[12].Value(), PKFieldRef[13].Value(), PKFieldRef[14].Value(), PKFieldRef[15].Value());
            16:
                RenamedRecordRef.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value(), PKFieldRef[11].Value(), PKFieldRef[12].Value(), PKFieldRef[13].Value(), PKFieldRef[14].Value(), PKFieldRef[15].Value(), PKFieldRef[16].Value());
        end;
    end;

    // Returns true if a backup should be created before the deletion. Cancels with an error if the user declines
    // the backup of a table with field types that cannot be backed up.
    procedure ConfirmBackupBeforeDeletion(TableNo: Integer): Boolean
    var
        AdminToolboxSetup: Record "Admin Toolbox Setup";
        ConfirmManagement: Codeunit "Confirm Management";
        TableBackupMgt: Codeunit "Table Backup Mgt.";
        CancelledByUserErr: Label 'The operation was cancelled by the user.';
        CreateBackupQst: Label 'Do you want to create a backup of the selected records before they are deleted?\\A backup is recommended so that the data can be restored if needed.';
        UnsupportedFieldsQst: Label 'Table %1 %2 contains fields of a type that cannot be backed up (for example BLOB, Media or RecordID). These fields are skipped in the backup and cannot be restored.\\Do you want to continue?', Comment = '%1 = Table ID, %2 = Table Name';
    begin
        if not AdminToolboxSetup.GetAutoBackupBeforeDeletion() then
            exit(false);

        if AdminToolboxSetup.GetPromptForBackup() then
            if not ConfirmManagement.GetResponseOrDefault(CreateBackupQst, true) then
                exit(false);

        if TableBackupMgt.TableHasUnsupportedFields(TableNo) then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(UnsupportedFieldsQst, TableNo, TableBackupMgt.GetTableCaption(TableNo)), true) then
                Error(CancelledByUserErr);

        exit(true);
    end;

    // Deletes the records of the view (or of the whole table if the view is blank) and returns how many were deleted.
    // CommitPerRecord keeps the transactions short on large tables.
    procedure DeleteRecords(TableNo: Integer; FilterView: Text; UseTableTrigger: Boolean; CreateBackup: Boolean; CommitPerRecord: Boolean): Integer
    var
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        AuditLogMgt: Codeunit "Audit Log Mgt.";
        RecordRef: RecordRef;
        AuditLogOperationType: Enum "Audit Log Operation Type";
        AuditLogStatus: Enum "Audit Log Status";
        AuditLogEntryNo: Integer;
        BackupEntryNo: Integer;
        DeletedCount: Integer;
        NoOfRecords: Integer;
        DeleteDescriptionLbl: Label 'Deleted %1 record(s)', Comment = '%1 = No. of records';
        ProtectedTableErr: Label 'Table %1 %2 belongs to the Admin Toolbox or to the system and its records cannot be deleted.', Comment = '%1 = Table ID, %2 = Table Name';
        TableEditorLbl: Label 'Table Editor';
    begin
        CheckSuperPermission();
        if AdminToolMgt.IsTableProtected(TableNo) then
            Error(ProtectedTableErr, TableNo, AdminToolMgt.GetTableCaption(TableNo));

        RecordRef.Open(TableNo);
        RecordRef.SetView(FilterView);
        NoOfRecords := RecordRef.Count();
        if NoOfRecords = 0 then begin
            RecordRef.Close();
            exit(0);
        end;

        if CreateBackup then
            BackupEntryNo := CreateBackupBeforeDeletion(TableNo, FilterView);

        AuditLogEntryNo := AuditLogMgt.StartOperation(
            AuditLogOperationType::"Bulk Delete",
            TableNo,
            CopyStr(StrSubstNo(DeleteDescriptionLbl, NoOfRecords), 1, 250),
            TableEditorLbl);
        if BackupEntryNo <> 0 then
            AuditLogMgt.LinkBackupToAuditLog(AuditLogEntryNo, BackupEntryNo);

        DeletedCount := DeleteRecordsOfView(RecordRef, NoOfRecords, UseTableTrigger, CommitPerRecord);

        case DeletedCount of
            NoOfRecords:
                AuditLogStatus := AuditLogStatus::Success;
            0:
                AuditLogStatus := AuditLogStatus::Failed;
            else
                AuditLogStatus := AuditLogStatus::"Partially Failed";
        end;
        AuditLogMgt.CompleteOperation(AuditLogEntryNo, AuditLogStatus, DeletedCount, NoOfRecords - DeletedCount, '');
        RecordRef.Close();
        exit(DeletedCount);
    end;

    local procedure DeleteRecordsOfView(var RecordRef: RecordRef; NoOfRecords: Integer; UseTableTrigger: Boolean; CommitPerRecord: Boolean): Integer
    var
        ProgressDialog: Dialog;
        CurrentRecord: Integer;
        DeletedCount: Integer;
        ProcessingDataTxt: Label 'Deleting records... @1@@@@@@';
    begin
        if GuiAllowed() then
            ProgressDialog.Open(ProcessingDataTxt);

        if RecordRef.FindSet() then
            repeat
                CurrentRecord += 1;
                UpdateDeleteProgress(ProgressDialog, CurrentRecord, NoOfRecords);
                if not RecordRef.Delete(UseTableTrigger) then
                    continue;

                DeletedCount += 1;
                if CommitPerRecord then
                    Commit(); // To avoid long transactions
            until RecordRef.Next() = 0;

        if GuiAllowed() then
            ProgressDialog.Close();
        exit(DeletedCount);
    end;

    local procedure CreateBackupBeforeDeletion(TableNo: Integer; FilterView: Text): Integer
    var
        AdminToolboxSetup: Record "Admin Toolbox Setup";
        TableBackupMgt: Codeunit "Table Backup Mgt.";
        BackupOperationType: Enum "Backup Operation Type";
        NormalizedView: Text;
        AutoBackupLbl: Label 'Backup before deletion in the Table Editor (table %1)', Comment = '%1 = Table ID';
    begin
        NormalizedView := TableBackupMgt.NormalizeFilterView(TableNo, FilterView);
        if NormalizedView = '' then
            exit(TableBackupMgt.CreateBackup(TableNo, AdminToolboxSetup.GetAutoBackupType(), BackupOperationType::"Before Deletion", CopyStr(StrSubstNo(AutoBackupLbl, TableNo), 1, 250), false));

        exit(TableBackupMgt.CreateBackupWithFilter(TableNo, AdminToolboxSetup.GetAutoBackupType(), BackupOperationType::"Before Deletion", CopyStr(StrSubstNo(AutoBackupLbl, TableNo), 1, 250), NormalizedView, false));
    end;

    local procedure UpdateDeleteProgress(var ProgressDialog: Dialog; CurrentRecord: Integer; NoOfRecords: Integer)
    begin
        if not GuiAllowed() then
            exit;

        if NoOfRecords <= 100 then
            ProgressDialog.Update(1, (CurrentRecord / NoOfRecords * 10000) div 1)
        else
            if CurrentRecord mod (NoOfRecords div 100) = 0 then
                ProgressDialog.Update(1, (CurrentRecord / NoOfRecords * 10000) div 1);
    end;

    // Describes the record that CreateRecord inserts. Errors if the view does not set a constant value on each primary key field.
    procedure GetCreateRecordPreview(TableNo: Integer; FilterView: Text): Text
    var
        RecordRef: RecordRef;
        PrimaryKeyRef: KeyRef;
        i: Integer;
        Preview: Text;
        FilterTableOnEachPKFieldErr: Label 'Filter each primary key field with a constant value. Only then a new record can be created using those values.';
        RecordAlreadyExistsErr: Label 'A record with these primary key values already exists.';
    begin
        RecordRef.Open(TableNo);
        RecordRef.SetView(FilterView);

        Preview := 'Rec.Init();\';
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        for i := 1 to PrimaryKeyRef.FieldCount() do begin
            if PrimaryKeyRef.FieldIndex(i).GetFilter() = '' then
                Error(FilterTableOnEachPKFieldErr);
            Preview += 'Rec."' + PrimaryKeyRef.FieldIndex(i).Name() + '" := [' + Format(PrimaryKeyRef.FieldIndex(i).GetRangeMin()) + '];\';
        end;
        if not RecordRef.IsEmpty() then
            Error(RecordAlreadyExistsErr);

        Preview += 'Rec.Insert(false);\\';
        RecordRef.Close();
        exit(Preview);
    end;

    // Inserts one record whose primary key values come from the constant filters of the view
    procedure CreateRecord(TableNo: Integer; FilterView: Text)
    var
        AuditLogMgt: Codeunit "Audit Log Mgt.";
        NewRecordRef: RecordRef;
        RecordRef: RecordRef;
        PrimaryKeyRef: KeyRef;
        i: Integer;
        CreateDescriptionLbl: Label 'Created a record in the Table Editor';
        TableEditorLbl: Label 'Table Editor';
    begin
        CheckSuperPermission();
        CheckTableIsEditable(TableNo);
        GetCreateRecordPreview(TableNo, FilterView);

        RecordRef.Open(TableNo);
        RecordRef.SetView(FilterView);
        NewRecordRef.Open(TableNo);
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        for i := 1 to PrimaryKeyRef.FieldCount() do
            NewRecordRef.Field(PrimaryKeyRef.FieldIndex(i).Number()).Value(PrimaryKeyRef.FieldIndex(i).GetRangeMin());

        NewRecordRef.Init();
        NewRecordRef.Insert(false);
        AuditLogMgt.LogSingleRecordOperation(Enum::"Audit Log Operation Type"::Insert, NewRecordRef, CopyStr(CreateDescriptionLbl, 1, 250), TableEditorLbl);

        RecordRef.Close();
        NewRecordRef.Close();
    end;
}
