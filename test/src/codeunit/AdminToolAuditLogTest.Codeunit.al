namespace AdminToolbox.Test;

using AdminToolbox;
using System.TestLibraries.Utilities;

codeunit 51102 "Admin Tool Audit Log Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        AuditLogMgt: Codeunit "Audit Log Mgt.";

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual('1 old audit log entries were deleted.', Message, 'Unexpected cleanup message.');
    end;

    [Test]
    procedure StartOperationCreatesInProgressEntry()
    var
        AuditLogEntry: Record "Audit Log Entry";
        EntryNo: Integer;
    begin
        // [WHEN] An operation is started
        EntryNo := AuditLogMgt.StartOperation(Enum::"Audit Log Operation Type"::Modify, Database::"Admin Tool Test Buffer", 'Test start', 'Audit Test');

        // [THEN] An entry in progress with the given data and the current user exists
        Assert.IsTrue(AuditLogEntry.Get(EntryNo), 'The audit log entry should exist.');
        Assert.AreEqual(Enum::"Audit Log Operation Type"::Modify.AsInteger(), AuditLogEntry."Operation Type".AsInteger(), 'Unexpected operation type.');
        Assert.AreEqual(Database::"Admin Tool Test Buffer", AuditLogEntry."Table ID", 'Unexpected table ID.');
        Assert.AreEqual(Enum::"Audit Log Status"::"In Progress".AsInteger(), AuditLogEntry.Status.AsInteger(), 'A started operation should be in progress.');
        Assert.AreEqual('Test start', AuditLogEntry.Description, 'Unexpected description.');
        Assert.AreEqual('Audit Test', AuditLogEntry."Triggered By", 'Unexpected triggered by.');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(AuditLogEntry."User ID")), AuditLogEntry."User ID", 'Unexpected user ID.');
        Assert.AreNotEqual(0DT, AuditLogEntry."Date Time", 'The start time should be set.');
    end;

    [Test]
    procedure CompleteOperationStoresResultAndDuration()
    var
        AuditLogEntry: Record "Audit Log Entry";
        EntryNo: Integer;
    begin
        // [GIVEN] A started operation
        EntryNo := AuditLogMgt.StartOperation(Enum::"Audit Log Operation Type"::Delete, Database::"Admin Tool Test Buffer", 'Test complete', 'Audit Test');

        // [WHEN] The operation is completed as partially failed
        AuditLogMgt.CompleteOperation(EntryNo, Enum::"Audit Log Status"::"Partially Failed", 5, 2, 'Some error');

        // [THEN] The result is stored with a non-negative duration
        Assert.IsTrue(AuditLogEntry.Get(EntryNo), 'The audit log entry should exist.');
        Assert.AreEqual(Enum::"Audit Log Status"::"Partially Failed".AsInteger(), AuditLogEntry.Status.AsInteger(), 'Unexpected status.');
        Assert.AreEqual(5, AuditLogEntry."No. of Records Affected", 'Unexpected number of affected records.');
        Assert.AreEqual(2, AuditLogEntry."No. of Records Failed", 'Unexpected number of failed records.');
        Assert.AreEqual('Some error', AuditLogEntry."Error Message", 'Unexpected error message.');
        Assert.IsTrue(AuditLogEntry."Duration (ms)" >= 0, 'The duration should not be negative.');
    end;

    [Test]
    procedure CompleteOperationIgnoresUnknownEntry()
    var
        AuditLogEntry: Record "Audit Log Entry";
    begin
        // [WHEN/THEN] Completing an entry that does not exist neither errors nor creates an entry
        AuditLogMgt.CompleteOperation(-1, Enum::"Audit Log Status"::Success, 1, 0, '');
        Assert.IsFalse(AuditLogEntry.Get(-1), 'No entry may be created for an unknown entry number.');
    end;

    [Test]
    procedure LogSingleRecordOperationStoresRecordAndPrimaryKey()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        AuditLogEntry: Record "Audit Log Entry";
        RecordRef: RecordRef;
        EntryNo: Integer;
    begin
        // [GIVEN] A record in the test table
        TestBuffer.DeleteAll(false);
        TestBuffer.Init();
        TestBuffer."No." := 'A001';
        TestBuffer.Insert(false);
        RecordRef.GetTable(TestBuffer);

        // [WHEN] A single record operation is logged
        EntryNo := AuditLogMgt.LogSingleRecordOperation(Enum::"Audit Log Operation Type"::Insert, RecordRef, 'Single record', 'Audit Test');

        // [THEN] The entry is successful and identifies the record
        Assert.IsTrue(AuditLogEntry.Get(EntryNo), 'The audit log entry should exist.');
        Assert.AreEqual(Enum::"Audit Log Status"::Success.AsInteger(), AuditLogEntry.Status.AsInteger(), 'A single record operation is logged as successful.');
        Assert.AreEqual(1, AuditLogEntry."No. of Records Affected", 'Exactly one record is affected.');
        Assert.AreEqual(Database::"Admin Tool Test Buffer", AuditLogEntry."Table ID", 'Unexpected table ID.');
        Assert.AreEqual(Format(TestBuffer.RecordId()), Format(AuditLogEntry."Record ID"), 'Unexpected record ID.');
        Assert.AreEqual('A001', AuditLogEntry."Primary Key Value", 'Unexpected primary key value.');
    end;

    [Test]
    procedure LogFieldChangeIgnoresUnchangedValue()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        FieldChangeHistory: Record "Field Change History";
        RecordRef: RecordRef;
        EntryNo: Integer;
    begin
        // [GIVEN] A started operation and a record
        EntryNo := AuditLogMgt.StartOperation(Enum::"Audit Log Operation Type"::Modify, Database::"Admin Tool Test Buffer", 'Unchanged', 'Audit Test');
        TestBuffer.DeleteAll(false);
        TestBuffer.Init();
        TestBuffer."No." := 'A101';
        TestBuffer.Insert(false);
        RecordRef.GetTable(TestBuffer);

        // [WHEN] A field change with identical old and new value is logged
        AuditLogMgt.LogFieldChange(EntryNo, RecordRef, TestBuffer.FieldNo(Description), 'Same', 'Same');

        // [THEN] Nothing is stored
        FieldChangeHistory.SetRange("Audit Log Entry No.", EntryNo);
        Assert.IsTrue(FieldChangeHistory.IsEmpty(), 'An unchanged value must not be logged.');
    end;

    [Test]
    procedure LogFieldChangeStoresChangeAndUpdatesFieldCounter()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        FieldChangeHistory: Record "Field Change History";
        AuditLogEntry: Record "Audit Log Entry";
        RecordRef: RecordRef;
        EntryNo: Integer;
    begin
        // [GIVEN] A started operation and a record
        EntryNo := AuditLogMgt.StartOperation(Enum::"Audit Log Operation Type"::Modify, Database::"Admin Tool Test Buffer", 'Changed', 'Audit Test');
        TestBuffer.DeleteAll(false);
        TestBuffer.Init();
        TestBuffer."No." := 'A201';
        TestBuffer.Insert(false);
        RecordRef.GetTable(TestBuffer);

        // [WHEN] A field change is logged
        AuditLogMgt.LogFieldChange(EntryNo, RecordRef, TestBuffer.FieldNo(Description), 'Old text', 'New text');

        // [THEN] The change is stored with field name, values and record
        FieldChangeHistory.SetRange("Audit Log Entry No.", EntryNo);
        Assert.RecordCount(FieldChangeHistory, 1);
        Assert.IsTrue(FieldChangeHistory.FindFirst(), 'The field change should exist.');
        Assert.AreEqual(Database::"Admin Tool Test Buffer", FieldChangeHistory."Table ID", 'Unexpected table ID.');
        Assert.AreEqual(TestBuffer.FieldNo(Description), FieldChangeHistory."Field No.", 'Unexpected field number.');
        Assert.AreEqual('Description', FieldChangeHistory."Field Name", 'Unexpected field name.');
        Assert.AreEqual('Old text', FieldChangeHistory."Old Value", 'Unexpected old value.');
        Assert.AreEqual('New text', FieldChangeHistory."New Value", 'Unexpected new value.');
        Assert.AreEqual('A201', FieldChangeHistory."Primary Key Value", 'Unexpected primary key value.');

        // [THEN] The change counter of the audit log entry is updated
        Assert.IsTrue(AuditLogEntry.Get(EntryNo), 'The audit log entry should exist.');
        Assert.AreEqual(1, AuditLogEntry."No. of Fields Changed", 'Unexpected number of changed fields.');
    end;

    [Test]
    procedure LogFieldChangesLogsOnlyChangedFields()
    var
        OldTestBuffer: Record "Admin Tool Test Buffer";
        NewTestBuffer: Record "Admin Tool Test Buffer";
        FieldChangeHistory: Record "Field Change History";
        OldRecordRef: RecordRef;
        NewRecordRef: RecordRef;
        EntryNo: Integer;
    begin
        // [GIVEN] A started operation and two versions of a record differing in two fields
        EntryNo := AuditLogMgt.StartOperation(Enum::"Audit Log Operation Type"::"Bulk Modify", Database::"Admin Tool Test Buffer", 'Compare', 'Audit Test');
        OldTestBuffer.Init();
        OldTestBuffer."No." := 'A301';
        OldTestBuffer.Description := 'Old';
        OldTestBuffer."Integer Value" := 1;
        NewTestBuffer := OldTestBuffer;
        NewTestBuffer.Description := 'New';
        NewTestBuffer."Decimal Value" := 5;
        OldRecordRef.GetTable(OldTestBuffer);
        NewRecordRef.GetTable(NewTestBuffer);

        // [WHEN] The field changes are logged
        AuditLogMgt.LogFieldChanges(EntryNo, OldRecordRef, NewRecordRef);

        // [THEN] Exactly the two changed fields are stored
        FieldChangeHistory.SetRange("Audit Log Entry No.", EntryNo);
        Assert.RecordCount(FieldChangeHistory, 2);
        FieldChangeHistory.SetRange("Field No.", OldTestBuffer.FieldNo(Description));
        Assert.RecordCount(FieldChangeHistory, 1);
        FieldChangeHistory.SetRange("Field No.", OldTestBuffer.FieldNo("Decimal Value"));
        Assert.RecordCount(FieldChangeHistory, 1);
    end;

    [Test]
    procedure LogFieldChangesIgnoresRecordsOfDifferentTables()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TestPKTarget: Record "Admin Tool Test PK Target";
        FieldChangeHistory: Record "Field Change History";
        OldRecordRef: RecordRef;
        NewRecordRef: RecordRef;
        EntryNo: Integer;
    begin
        // [GIVEN] A started operation and records of two different tables
        EntryNo := AuditLogMgt.StartOperation(Enum::"Audit Log Operation Type"::Modify, Database::"Admin Tool Test Buffer", 'Different tables', 'Audit Test');
        OldRecordRef.GetTable(TestBuffer);
        NewRecordRef.GetTable(TestPKTarget);

        // [WHEN] The field changes are logged
        AuditLogMgt.LogFieldChanges(EntryNo, OldRecordRef, NewRecordRef);

        // [THEN] Nothing is stored
        FieldChangeHistory.SetRange("Audit Log Entry No.", EntryNo);
        Assert.IsTrue(FieldChangeHistory.IsEmpty(), 'Records of different tables must not be compared.');
    end;

    [Test]
    procedure LinkBackupToAuditLogStoresBackupReference()
    var
        AuditLogEntry: Record "Audit Log Entry";
        EntryNo: Integer;
    begin
        // [GIVEN] A started operation
        EntryNo := AuditLogMgt.StartOperation(Enum::"Audit Log Operation Type"::Delete, Database::"Admin Tool Test Buffer", 'With backup', 'Audit Test');

        // [WHEN] A backup is linked to it
        AuditLogMgt.LinkBackupToAuditLog(EntryNo, 4711);

        // [THEN] The reference is stored
        Assert.IsTrue(AuditLogEntry.Get(EntryNo), 'The audit log entry should exist.');
        Assert.IsTrue(AuditLogEntry."Backup Created", 'Backup Created should be set.');
        Assert.AreEqual(4711, AuditLogEntry."Backup Entry No.", 'Unexpected backup entry number.');
    end;

    [Test]
    procedure DeletingAuditLogEntryDeletesItsFieldChangeHistory()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        AuditLogEntry: Record "Audit Log Entry";
        FieldChangeHistory: Record "Field Change History";
        RecordRef: RecordRef;
        EntryNo: Integer;
    begin
        // [GIVEN] An audit log entry with one logged field change
        EntryNo := AuditLogMgt.StartOperation(Enum::"Audit Log Operation Type"::Modify, Database::"Admin Tool Test Buffer", 'To delete', 'Audit Test');
        TestBuffer.DeleteAll(false);
        TestBuffer.Init();
        TestBuffer."No." := 'A401';
        TestBuffer.Insert(false);
        RecordRef.GetTable(TestBuffer);
        AuditLogMgt.LogFieldChange(EntryNo, RecordRef, TestBuffer.FieldNo(Description), 'A', 'B');

        // [WHEN] The entry is deleted
        Assert.IsTrue(AuditLogEntry.Get(EntryNo), 'The audit log entry should exist.');
        AuditLogEntry.Delete(true);

        // [THEN] Its field change history is gone as well
        FieldChangeHistory.SetRange("Audit Log Entry No.", EntryNo);
        Assert.IsTrue(FieldChangeHistory.IsEmpty(), 'The field change history should be deleted with the entry.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure DeleteOldAuditLogsDeletesOldEntriesWithHistoryAndKeepsRecentOnes()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        AuditLogEntry: Record "Audit Log Entry";
        FieldChangeHistory: Record "Field Change History";
        RecordRef: RecordRef;
        OldEntryNo: Integer;
        RecentEntryNo: Integer;
    begin
        // [GIVEN] No entry older than the cutoff exists, so the test can never delete real audit data
        AuditLogEntry.SetFilter("Date Time", '<%1', CreateDateTime(CalcDate('<-30D>', Today()), 0T));
        Assert.IsTrue(AuditLogEntry.IsEmpty(), 'Aborting: audit log entries older than the cutoff already exist in this environment.');
        AuditLogEntry.Reset();

        // [GIVEN] An entry 60 days old with a field change, and a recent entry
        OldEntryNo := AuditLogMgt.StartOperation(Enum::"Audit Log Operation Type"::Modify, Database::"Admin Tool Test Buffer", 'Old entry', 'Audit Test');
        Assert.IsTrue(AuditLogEntry.Get(OldEntryNo), 'The audit log entry should exist.');
        AuditLogEntry."Date Time" := CreateDateTime(Today() - 60, 120000T);
        AuditLogEntry.Modify(false);

        TestBuffer.DeleteAll(false);
        TestBuffer.Init();
        TestBuffer."No." := 'A501';
        TestBuffer.Insert(false);
        RecordRef.GetTable(TestBuffer);
        AuditLogMgt.LogFieldChange(OldEntryNo, RecordRef, TestBuffer.FieldNo(Description), 'A', 'B');

        RecentEntryNo := AuditLogMgt.StartOperation(Enum::"Audit Log Operation Type"::Modify, Database::"Admin Tool Test Buffer", 'Recent entry', 'Audit Test');

        // [WHEN] Entries older than 30 days are deleted
        AuditLogMgt.DeleteOldAuditLogs(30);

        // [THEN] The old entry and its field change history are gone, the recent entry remains
        Assert.IsFalse(AuditLogEntry.Get(OldEntryNo), 'The old audit log entry should be deleted.');
        FieldChangeHistory.SetRange("Audit Log Entry No.", OldEntryNo);
        Assert.IsTrue(FieldChangeHistory.IsEmpty(), 'The field change history of the old entry should be deleted.');
        Assert.IsTrue(AuditLogEntry.Get(RecentEntryNo), 'The recent audit log entry must be kept.');
    end;

    [Test]
    procedure DeleteOldAuditLogsKeepsEverythingForZeroDays()
    var
        AuditLogEntry: Record "Audit Log Entry";
        EntryNo: Integer;
    begin
        // [GIVEN] An old entry
        EntryNo := AuditLogMgt.StartOperation(Enum::"Audit Log Operation Type"::Modify, Database::"Admin Tool Test Buffer", 'Old entry', 'Audit Test');
        Assert.IsTrue(AuditLogEntry.Get(EntryNo), 'The audit log entry should exist.');
        AuditLogEntry."Date Time" := CreateDateTime(Today() - 400, 120000T);
        AuditLogEntry.Modify(false);

        // [WHEN] Cleaning up with 0 days to keep (audit logs are kept indefinitely)
        AuditLogMgt.DeleteOldAuditLogs(0);

        // [THEN] The entry is still there
        Assert.IsTrue(AuditLogEntry.Get(EntryNo), 'With 0 days to keep nothing may be deleted.');

        // The test runner rolls back only after the whole codeunit, so the old entry must not stay behind
        AuditLogEntry.Delete(false);
    end;
}
