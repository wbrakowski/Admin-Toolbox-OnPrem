codeunit 51004 "Audit Log Mgt."
{
    Permissions = tabledata "Audit Log Entry" = RIMD,
                  tabledata "Field Change History" = RIMD;

    procedure StartOperation(OperationType: Enum "Audit Log Operation Type"; TableID: Integer; Description: Text[250]; TriggeredBy: Text[100]): Integer
    var
        AuditLogEntry: Record "Audit Log Entry";
    begin
        AuditLogEntry.Init();
        AuditLogEntry."Operation Type" := OperationType;
        AuditLogEntry."Table ID" := TableID;
        AuditLogEntry."Date Time" := CurrentDateTime();
        AuditLogEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(AuditLogEntry."User ID"));
        AuditLogEntry.Status := AuditLogEntry.Status::"In Progress";
        AuditLogEntry.Description := Description;
        AuditLogEntry."Triggered By" := TriggeredBy;
        AuditLogEntry.Insert(true);

        exit(AuditLogEntry."Entry No.");
    end;

    procedure CompleteOperation(EntryNo: Integer; Status: Enum "Audit Log Status"; NoOfRecordsAffected: Integer; NoOfRecordsFailed: Integer; ErrorMessage: Text[2048])
    var
        AuditLogEntry: Record "Audit Log Entry";
    begin
        if not AuditLogEntry.Get(EntryNo) then
            exit;

        AuditLogEntry.Status := Status;
        AuditLogEntry."No. of Records Affected" := NoOfRecordsAffected;
        AuditLogEntry."No. of Records Failed" := NoOfRecordsFailed;
        AuditLogEntry."Error Message" := ErrorMessage;
        AuditLogEntry."Duration (ms)" := CurrentDateTime() - AuditLogEntry."Date Time";
        AuditLogEntry.Modify(true);
    end;

    procedure LogSingleRecordOperation(OperationType: Enum "Audit Log Operation Type"; RecRef: RecordRef; Description: Text[250]; TriggeredBy: Text[100]): Integer
    var
        AuditLogEntry: Record "Audit Log Entry";
    begin
        AuditLogEntry.Init();
        AuditLogEntry."Operation Type" := OperationType;
        AuditLogEntry."Table ID" := RecRef.Number();
        AuditLogEntry."Date Time" := CurrentDateTime();
        AuditLogEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(AuditLogEntry."User ID"));
        AuditLogEntry.Status := AuditLogEntry.Status::Success;
        AuditLogEntry."No. of Records Affected" := 1;
        AuditLogEntry.Description := Description;
        AuditLogEntry."Triggered By" := TriggeredBy;
        AuditLogEntry."Record ID" := RecRef.RecordId();
        AuditLogEntry."Primary Key Value" := GetPrimaryKeyValue(RecRef);
        AuditLogEntry.Insert(true);

        exit(AuditLogEntry."Entry No.");
    end;

    procedure LogFieldChange(AuditLogEntryNo: Integer; RecRef: RecordRef; FieldNo: Integer; OldValue: Text[2048]; NewValue: Text[2048])
    var
        FieldChangeHistory: Record "Field Change History";
        FieldRef: FieldRef;
    begin
        if OldValue = NewValue then
            exit;

        FieldRef := RecRef.Field(FieldNo);

        FieldChangeHistory.Init();
        FieldChangeHistory."Audit Log Entry No." := AuditLogEntryNo;
        FieldChangeHistory."Table ID" := RecRef.Number();
        FieldChangeHistory."Field No." := FieldNo;
        FieldChangeHistory."Field Name" := CopyStr(FieldRef.Name(), 1, MaxStrLen(FieldChangeHistory."Field Name"));
        FieldChangeHistory."Field Caption" := CopyStr(FieldRef.Caption(), 1, MaxStrLen(FieldChangeHistory."Field Caption"));
        FieldChangeHistory."Old Value" := OldValue;
        FieldChangeHistory."New Value" := NewValue;
        FieldChangeHistory."Date Time" := CurrentDateTime();
        FieldChangeHistory."User ID" := CopyStr(UserId(), 1, MaxStrLen(FieldChangeHistory."User ID"));
        FieldChangeHistory."Record ID" := RecRef.RecordId();
        FieldChangeHistory."Primary Key Value" := GetPrimaryKeyValue(RecRef);
        FieldChangeHistory.Insert(true);

        // Update field change counter in audit log
        UpdateFieldChangeCount(AuditLogEntryNo);
    end;

    procedure LogFieldChanges(AuditLogEntryNo: Integer; OldRecRef: RecordRef; NewRecRef: RecordRef)
    var
        NewFieldRef: FieldRef;
        OldFieldRef: FieldRef;
        i: Integer;
        NewValue: Text[2048];
        OldValue: Text[2048];
    begin
        if OldRecRef.Number() <> NewRecRef.Number() then
            exit;

        for i := 1 to OldRecRef.FieldCount() do begin
            OldFieldRef := OldRecRef.FieldIndex(i);
            NewFieldRef := NewRecRef.FieldIndex(i);

            // Skip system fields and flowfields
            if (OldFieldRef.Class() = FieldClass::Normal) and (OldFieldRef.Type() <> FieldType::Blob) then begin
                OldValue := CopyStr(Format(OldFieldRef.Value()), 1, MaxStrLen(OldValue));
                NewValue := CopyStr(Format(NewFieldRef.Value()), 1, MaxStrLen(NewValue));

                if OldValue <> NewValue then
                    LogFieldChange(AuditLogEntryNo, NewRecRef, OldFieldRef.Number(), OldValue, NewValue);
            end;
        end;
    end;

    procedure LinkBackupToAuditLog(AuditLogEntryNo: Integer; BackupEntryNo: Integer)
    var
        AuditLogEntry: Record "Audit Log Entry";
    begin
        if not AuditLogEntry.Get(AuditLogEntryNo) then
            exit;

        AuditLogEntry."Backup Created" := true;
        AuditLogEntry."Backup Entry No." := BackupEntryNo;
        AuditLogEntry.Modify(true);
    end;

    local procedure UpdateFieldChangeCount(AuditLogEntryNo: Integer)
    var
        AuditLogEntry: Record "Audit Log Entry";
        FieldChangeHistory: Record "Field Change History";
    begin
        if not AuditLogEntry.Get(AuditLogEntryNo) then
            exit;

        FieldChangeHistory.SetRange("Audit Log Entry No.", AuditLogEntryNo);
        AuditLogEntry."No. of Fields Changed" := FieldChangeHistory.Count();
        AuditLogEntry.Modify(true);
    end;

    local procedure GetPrimaryKeyValue(RecRef: RecordRef): Text[250]
    var
        FieldRef: FieldRef;
        i: Integer;
        KeyRef: KeyRef;
        PrimaryKeyValue: Text[250];
    begin
        KeyRef := RecRef.KeyIndex(1); // Primary key

        for i := 1 to KeyRef.FieldCount() do begin
            FieldRef := KeyRef.FieldIndex(i);
            if PrimaryKeyValue <> '' then
                PrimaryKeyValue += ', ';
            PrimaryKeyValue += Format(FieldRef.Value());
        end;

        exit(CopyStr(PrimaryKeyValue, 1, MaxStrLen(PrimaryKeyValue)));
    end;

    procedure DeleteOldAuditLogs(DaysToKeep: Integer)
    var
        AuditLogEntry: Record "Audit Log Entry";
        CutoffDate: DateTime;
        DeletedCount: Integer;
        DateFormulaLbl: Label '<-%1D>', Locked = true;
        AuditEntriesDeletedMsg: Label '%1 old audit log entries were deleted.', Comment = '%1 = Number of deleted entries';
    begin
        if DaysToKeep <= 0 then
            exit;

        CutoffDate := CreateDateTime(CalcDate(StrSubstNo(DateFormulaLbl, DaysToKeep), Today()), 0T);

        AuditLogEntry.SetFilter("Date Time", '<%1', CutoffDate);
        if AuditLogEntry.FindSet() then begin
            repeat
                AuditLogEntry.Delete(true); // This will also delete field change history via OnDelete trigger
                DeletedCount += 1;
            until AuditLogEntry.Next() = 0;

            Message(AuditEntriesDeletedMsg, DeletedCount);
        end;
    end;
}
