namespace AdminToolbox.Test;

using AdminToolbox;
using System.TestLibraries.Utilities;

codeunit 51100 "Admin Tool Backup Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TableBackupMgt: Codeunit "Table Backup Mgt.";
        LastMessage: Text;
        ConfirmReply: Boolean;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        LastMessage := Message;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := ConfirmReply;
    end;

    [Test]
    procedure CreateBackupStoresExpectedRecordCountAndData()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        EntryNo: Integer;
    begin
        // [GIVEN] Three records in the source table
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('T001', 'First', 1, 1.1, true, 20260101D);
        CreateTestBufferRecord('T002', 'Second', 2, 2.2, false, 20260102D);
        CreateTestBufferRecord('T003', 'Third', 3, 3.3, true, 20260103D);

        // [WHEN] A JSON export backup is created for the table
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Unit test backup', false);

        // [THEN] The backup entry reflects the source data
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        Assert.AreEqual(3, TableBackup."No. of Records", 'Unexpected number of backed up records.');
        Assert.AreEqual(Enum::"Backup Type"::"JSON Export".AsInteger(), TableBackup."Backup Type".AsInteger(), 'Unexpected backup type.');
        Assert.AreEqual(Database::"Admin Tool Test Buffer", TableBackup."Table ID", 'Unexpected table ID.');

        TableBackup.CalcFields("Backup Data");
        Assert.IsTrue(TableBackup."Backup Data".HasValue(), 'Backup Data blob should not be empty.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure CreateBackupFallsBackToJsonExportForBlankBackupType()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        BlankBackupType: Enum "Backup Type";
        EntryNo: Integer;
    begin
        // [GIVEN] A record in the source table and a blank backup type
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('T010', 'Blank type', 1, 1, true, 20260101D);

        // [WHEN] A backup is created with the blank backup type
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", BlankBackupType, Enum::"Backup Operation Type"::"Manual Backup", 'Blank type backup', false);

        // [THEN] JSON Export is used
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        Assert.AreEqual(Enum::"Backup Type"::"JSON Export".AsInteger(), TableBackup."Backup Type".AsInteger(), 'A blank backup type should fall back to JSON Export.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BackupAndRestoreRoundTripRestoresAllFields()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        EntryNo: Integer;
    begin
        // [GIVEN] Two records in the source table
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('T101', 'Alpha', 10, 10.5, true, 20260201D);
        CreateTestBufferRecord('T102', 'Beta', 20, 20.75, false, 20260202D);

        // [GIVEN] A JSON export backup of the source table
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Round-trip test backup', false);

        // [GIVEN] All source records have been deleted
        TestBuffer.DeleteAll(false);
        Assert.IsTrue(TestBuffer.IsEmpty(), 'Test buffer should be empty before restore.');

        // [WHEN] The backup is restored directly (bypassing the interactive confirm dialog)
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        TableBackupMgt.RestoreFromJSON(TableBackup);

        // [THEN] Both records are restored with their original field values and the user is told so
        Assert.AreEqual('2 records have been restored to table Admin Tool Test Buffer.', LastMessage, 'Unexpected result message.');
        Assert.AreEqual(2, TestBuffer.Count(), 'Unexpected number of restored records.');

        Assert.IsTrue(TestBuffer.Get('T101'), 'Record T101 should exist after restore.');
        Assert.AreEqual('Alpha', TestBuffer.Description, 'Description does not match for T101.');
        Assert.AreEqual(10, TestBuffer."Integer Value", 'Integer Value does not match for T101.');
        Assert.AreEqual(10.5, TestBuffer."Decimal Value", 'Decimal Value does not match for T101.');
        Assert.IsTrue(TestBuffer."Boolean Value", 'Boolean Value does not match for T101.');
        Assert.AreEqual(20260201D, TestBuffer."Date Value", 'Date Value does not match for T101.');

        Assert.IsTrue(TestBuffer.Get('T102'), 'Record T102 should exist after restore.');
        Assert.AreEqual('Beta', TestBuffer.Description, 'Description does not match for T102.');
        Assert.AreEqual(20, TestBuffer."Integer Value", 'Integer Value does not match for T102.');
        Assert.AreEqual(20.75, TestBuffer."Decimal Value", 'Decimal Value does not match for T102.');
        Assert.IsFalse(TestBuffer."Boolean Value", 'Boolean Value does not match for T102.');
        Assert.AreEqual(20260202D, TestBuffer."Date Value", 'Date Value does not match for T102.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure CreateBackupWithFilterOnlyBacksUpMatchingRecords()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        FilterView: Text;
        EntryNo: Integer;
    begin
        // [GIVEN] Three records, only some of which match a filter on Integer Value
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('F001', 'First', 1, 1.1, true, 20260101D);
        CreateTestBufferRecord('F002', 'Second', 2, 2.2, false, 20260102D);
        CreateTestBufferRecord('F003', 'Third', 3, 3.3, true, 20260103D);

        TestBuffer.SetFilter("Integer Value", '>%1', 1);
        FilterView := TestBuffer.GetView(false);

        // [WHEN] A filtered JSON export backup is created
        EntryNo := TableBackupMgt.CreateBackupWithFilter(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Filtered backup', FilterView, false);

        // [THEN] Only the records matching the filter were backed up, and the filter is stored
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        Assert.AreEqual(2, TableBackup."No. of Records", 'Unexpected number of backed up records for the filtered backup.');
        Assert.AreEqual(FilterView, TableBackup."Filter View", 'The filter view should be stored with the backup.');

        TestBuffer.SetRange("Integer Value");
        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure CreateBackupWithFilterForSnapshotTypeDoesNotAssignSnapshotTableId()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        EntryNo: Integer;
    begin
        // [GIVEN] A record and a filtered snapshot backup request
        CreateTestBufferRecord('F101', 'First', 1, 1.1, true, 20260101D);
        TestBuffer.SetFilter("Integer Value", '>=%1', 1);

        // [WHEN] A filtered snapshot backup is created
        EntryNo := TableBackupMgt.CreateBackupWithFilter(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::Snapshot, Enum::"Backup Operation Type"::"Manual Backup", 'Filtered snapshot', TestBuffer.GetView(false), false);

        // [THEN] The backup is stored as a snapshot without a snapshot table ID, as filtered snapshots always were
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        Assert.AreEqual(Enum::"Backup Type"::Snapshot.AsInteger(), TableBackup."Backup Type".AsInteger(), 'Unexpected backup type.');
        Assert.AreEqual(0, TableBackup."Snapshot Table ID", 'A filtered snapshot should not reserve a snapshot table ID.');

        TestBuffer.SetRange("Integer Value");
        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure CreateBackupWithSnapshotTypeAssignsSnapshotTableId()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        EntryNo: Integer;
    begin
        // [GIVEN] A record in the source table
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('S001', 'Snap', 1, 1.1, true, 20260101D);

        // [WHEN] A snapshot backup is created
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::Snapshot, Enum::"Backup Operation Type"::"Manual Backup", 'Snapshot backup', false);

        // [THEN] A snapshot table ID is assigned and the record count is correct
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        Assert.AreEqual(Enum::"Backup Type"::Snapshot.AsInteger(), TableBackup."Backup Type".AsInteger(), 'Unexpected backup type.');
        Assert.AreNotEqual(0, TableBackup."Snapshot Table ID", 'Snapshot Table ID should have been assigned.');
        Assert.AreEqual(1, TableBackup."No. of Records", 'Unexpected number of backed up records.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure CreateBackupWithSnapshotTypeIncrementsSnapshotTableId()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        FirstEntryNo: Integer;
        SecondEntryNo: Integer;
        FirstSnapshotId: Integer;
    begin
        // [GIVEN] A record in the source table
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('S101', 'Snap1', 1, 1.1, true, 20260101D);

        // [WHEN] Two snapshot backups are created in sequence
        FirstEntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::Snapshot, Enum::"Backup Operation Type"::"Manual Backup", 'Snapshot 1', false);
        SecondEntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::Snapshot, Enum::"Backup Operation Type"::"Manual Backup", 'Snapshot 2', false);

        // [THEN] The second snapshot gets the next sequential snapshot table ID
        Assert.IsTrue(TableBackup.Get(FirstEntryNo), 'First backup entry should exist.');
        FirstSnapshotId := TableBackup."Snapshot Table ID";
        Assert.IsTrue(TableBackup.Get(SecondEntryNo), 'Second backup entry should exist.');
        Assert.AreEqual(FirstSnapshotId + 1, TableBackup."Snapshot Table ID", 'Snapshot Table ID should increment sequentially.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure CreateBackupWithFullBackupTypeStoresExpectedData()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        EntryNo: Integer;
    begin
        // [GIVEN] A record in the source table
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('F201', 'Full', 1, 1.1, true, 20260101D);

        // [WHEN] A full backup is created
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"Full Backup", Enum::"Backup Operation Type"::"Manual Backup", 'Full backup', false);

        // [THEN] The backup entry reflects the source data
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        Assert.AreEqual(Enum::"Backup Type"::"Full Backup".AsInteger(), TableBackup."Backup Type".AsInteger(), 'Unexpected backup type.');
        Assert.AreEqual(1, TableBackup."No. of Records", 'Unexpected number of backed up records.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BackupAndRestoreRoundTripRestoresTimeDateTimeAndGuidFields()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        ExpectedGuid: Guid;
        ExpectedDateTime: DateTime;
        EntryNo: Integer;
    begin
        // [GIVEN] A record using Time, DateTime and Guid fields
        TestBuffer.DeleteAll(false);
        ExpectedGuid := CreateGuid();
        ExpectedDateTime := CreateDateTime(20260301D, 083000T);

        TestBuffer.Init();
        TestBuffer."No." := 'T201';
        TestBuffer."Time Value" := 083000T;
        TestBuffer."DateTime Value" := ExpectedDateTime;
        TestBuffer."Guid Value" := ExpectedGuid;
        TestBuffer.Insert(false);

        // [GIVEN] A JSON export backup of the source table and the source record deleted afterwards
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Time/DateTime/Guid backup', false);
        TestBuffer.DeleteAll(false);

        // [WHEN] The backup is restored directly
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        TableBackupMgt.RestoreFromJSON(TableBackup);

        // [THEN] Time, DateTime and Guid values are restored correctly
        Assert.IsTrue(TestBuffer.Get('T201'), 'Record T201 should exist after restore.');
        Assert.AreEqual(083000T, TestBuffer."Time Value", 'Time Value does not match.');
        Assert.AreEqual(ExpectedDateTime, TestBuffer."DateTime Value", 'DateTime Value does not match.');
        Assert.AreEqual(ExpectedGuid, TestBuffer."Guid Value", 'Guid Value does not match.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BackupAndRestoreRoundTripRestoresEnumFieldAsOrdinal()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        EntryNo: Integer;
    begin
        // [GIVEN] A record with a non-default enum value
        TestBuffer.DeleteAll(false);
        TestBuffer.Init();
        TestBuffer."No." := 'E001';
        TestBuffer."Operation Type Value" := Enum::"Backup Operation Type"::"Before Deletion";
        TestBuffer.Insert(false);

        // [GIVEN] A JSON export backup of the source table and the source record deleted afterwards
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Enum round-trip test backup', false);
        TestBuffer.DeleteAll(false);

        // [WHEN] The backup is restored directly
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        TableBackupMgt.RestoreFromJSON(TableBackup);

        // [THEN] The enum value is restored via its ordinal, not its (locale-dependent) caption
        Assert.IsTrue(TestBuffer.Get('E001'), 'Record E001 should exist after restore.');
        Assert.AreEqual(Enum::"Backup Operation Type"::"Before Deletion".AsInteger(), TestBuffer."Operation Type Value".AsInteger(), 'Operation Type Value does not match after restore.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BackupAndRestoreRoundTripSucceedsForTableWithMediaField()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        EntryNo: Integer;
    begin
        // [GIVEN] Two records in a table with a Media field; a Media value must neither be exported nor break the restore
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('MD01', 'MediaTest1', 1, 1.1, true, 20260101D);
        CreateTestBufferRecord('MD02', 'MediaTest2', 2, 2.2, false, 20260102D);

        // [WHEN] A JSON export backup is created and restored
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Media field backup', false);
        TestBuffer.DeleteAll(false);

        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        TableBackupMgt.RestoreFromJSON(TableBackup);

        // [THEN] Both records were restored
        Assert.AreEqual(2, TestBuffer.Count(), 'Both records should have been restored despite the table having a Media field.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RestoreFromJSONSkipsUnsupportedFieldTypeButStillRestoresTheRecord()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        OutStream: OutStream;
        JSONText: Text;
    begin
        // [GIVEN] A backup with a value for an unsupported field type (RecordID) next to a valid value
        TestBuffer.DeleteAll(false);
        JSONText := '[{"No.":"RID01","Description":"Should still be restored","Record ID Value":"not-a-valid-recordid"}]';

        TableBackup.Init();
        TableBackup."Table ID" := Database::"Admin Tool Test Buffer";
        TableBackup."Backup Type" := TableBackup."Backup Type"::"JSON Export";
        TableBackup."No. of Records" := 1;
        TableBackup.Insert(true);
        TableBackup."Backup Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(JSONText);
        TableBackup.Modify(true);

        // [WHEN] The backup is restored
        TableBackupMgt.RestoreFromJSON(TableBackup);

        // [THEN] The record was restored, the unsupported field type is simply skipped
        Assert.IsTrue(TestBuffer.Get('RID01'), 'Record should be restored even though it has a value for an unsupported field type.');
        Assert.AreEqual('Should still be restored', TestBuffer.Description, 'Other fields on the record should still be restored correctly.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RestoreFromJSONKeepsExistingRecordAndInsertsTheNewOne()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        OutStream: OutStream;
        JSONText: Text;
    begin
        // [GIVEN] A backup with one record that already exists in the table and one new record
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('D001', 'Existing', 1, 1, true, 20260101D);
        JSONText := '[{"No.":"D001","Description":"Duplicate"},{"No.":"D002","Description":"New"}]';

        TableBackup.Init();
        TableBackup."Table ID" := Database::"Admin Tool Test Buffer";
        TableBackup."Backup Type" := TableBackup."Backup Type"::"JSON Export";
        TableBackup."No. of Records" := 2;
        TableBackup.Insert(true);
        TableBackup."Backup Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(JSONText);
        TableBackup.Modify(true);

        // [WHEN] The backup is restored (the duplicate only counts as failed, the restore carries on)
        TableBackupMgt.RestoreFromJSON(TableBackup);

        // [THEN] The existing record is untouched, the new record was inserted and the partial result is reported
        Assert.AreEqual('Restored 1 of 2 records. 1 records failed to insert (possibly due to duplicates or validation errors).', LastMessage, 'Unexpected result message.');
        Assert.AreEqual(2, TestBuffer.Count(), 'Expected the existing and the new record.');
        Assert.IsTrue(TestBuffer.Get('D001'), 'The existing record should still exist.');
        Assert.AreEqual('Existing', TestBuffer.Description, 'The existing record must not be overwritten by the restore.');
        Assert.IsTrue(TestBuffer.Get('D002'), 'The new record should have been inserted.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure RestoreFromJSONErrorsForInvalidJSON()
    var
        TableBackup: Record "Table Backup";
        OutStream: OutStream;
    begin
        // [GIVEN] A backup whose data is not valid JSON
        TableBackup.Init();
        TableBackup."Table ID" := Database::"Admin Tool Test Buffer";
        TableBackup.Insert(true);
        TableBackup."Backup Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('this is not json');
        TableBackup.Modify(true);

        // [WHEN/THEN] The restore raises the specific invalid JSON error
        asserterror TableBackupMgt.RestoreFromJSON(TableBackup);
        Assert.ExpectedError('The backup data contains invalid JSON format.');
    end;

    [Test]
    procedure RestoreFromJSONErrorsForEmptyJSONArray()
    var
        TableBackup: Record "Table Backup";
        OutStream: OutStream;
    begin
        // [GIVEN] A backup with an empty JSON array
        TableBackup.Init();
        TableBackup."Table ID" := Database::"Admin Tool Test Buffer";
        TableBackup.Insert(true);
        TableBackup."Backup Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('[]');
        TableBackup.Modify(true);

        // [WHEN/THEN] The restore raises the specific "no records" error
        asserterror TableBackupMgt.RestoreFromJSON(TableBackup);
        Assert.ExpectedError('No records found in backup data.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BackupAndRestoreRoundTripPreservesLocaleSensitiveValues()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        ExpectedGuid: Guid;
        ExpectedDateTime: DateTime;
        EntryNo: Integer;
    begin
        // [GIVEN] A record whose values render differently depending on the regional settings
        TestBuffer.DeleteAll(false);
        ExpectedGuid := CreateGuid();
        ExpectedDateTime := CreateDateTime(20261231D, 235958T);

        TestBuffer.Init();
        TestBuffer."No." := 'L001';
        TestBuffer."Decimal Value" := -1234567.89;
        TestBuffer."Date Value" := 20260201D;
        TestBuffer."Time Value" := 134507T;
        TestBuffer."DateTime Value" := ExpectedDateTime;
        TestBuffer."Guid Value" := ExpectedGuid;
        TestBuffer.Insert(false);

        // [GIVEN] A JSON export backup of the source table and the source record deleted afterwards
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Locale round-trip backup', false);
        TestBuffer.DeleteAll(false);

        // [WHEN] The backup is restored directly
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        TableBackupMgt.RestoreFromJSON(TableBackup);

        // [THEN] Every locale-sensitive value is restored unchanged
        Assert.IsTrue(TestBuffer.Get('L001'), 'Record L001 should exist after restore.');
        Assert.AreEqual(-1234567.89, TestBuffer."Decimal Value", 'Decimal Value does not match.');
        Assert.AreEqual(20260201D, TestBuffer."Date Value", 'Date Value does not match.');
        Assert.AreEqual(134507T, TestBuffer."Time Value", 'Time Value does not match.');
        Assert.AreEqual(ExpectedDateTime, TestBuffer."DateTime Value", 'DateTime Value does not match.');
        Assert.AreEqual(ExpectedGuid, TestBuffer."Guid Value", 'Guid Value does not match.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BackupAndRestoreRoundTripRestoresDurationDateFormulaOptionAndClosingDate()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        ExpectedDateFormula: DateFormula;
        ExpectedDuration: Duration;
        InStream: InStream;
        EntryNo: Integer;
        JSONText: Text;
    begin
        // [GIVEN] A record with Duration, DateFormula, Option and closing date values
        TestBuffer.DeleteAll(false);
        ExpectedDuration := 90061000; // 1 day, 1 hour, 1 minute, 1 second
        Evaluate(ExpectedDateFormula, '<1M-CM>');

        TestBuffer.Init();
        TestBuffer."No." := 'X001';
        TestBuffer."Duration Value" := ExpectedDuration;
        TestBuffer."Date Formula Value" := ExpectedDateFormula;
        TestBuffer."Option Value" := TestBuffer."Option Value"::Second;
        TestBuffer."Closing Date Value" := ClosingDate(20261231D);
        TestBuffer.Insert(false);

        // [GIVEN] A JSON export backup of the source table and the source record deleted afterwards
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Special types backup', false);
        TestBuffer.DeleteAll(false);

        // [THEN] The closing date is stored as the prefix C plus the invariant normal date
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        TableBackup.CalcFields("Backup Data");
        TableBackup."Backup Data".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(JSONText);
        Assert.IsTrue(JSONText.Contains('"Closing Date Value":"C2026-12-31"'), 'A closing date should be stored with the prefix C. JSON: ' + JSONText);

        // [WHEN] The backup is restored directly
        TableBackupMgt.RestoreFromJSON(TableBackup);

        // [THEN] All four values are restored unchanged, the closing date keeps its closing flag
        Assert.IsTrue(TestBuffer.Get('X001'), 'Record X001 should exist after restore.');
        Assert.AreEqual(ExpectedDuration, TestBuffer."Duration Value", 'Duration Value does not match.');
        Assert.AreEqual(Format(ExpectedDateFormula, 0, 9), Format(TestBuffer."Date Formula Value", 0, 9), 'Date Formula Value does not match.');
        Assert.AreEqual(TestBuffer."Option Value"::Second, TestBuffer."Option Value", 'Option Value does not match.');
        Assert.AreEqual(ClosingDate(20261231D), TestBuffer."Closing Date Value", 'Closing Date Value does not match.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure CreateBackupStoresValuesInCultureInvariantFormat()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        InStream: InStream;
        JSONText: Text;
        EntryNo: Integer;
    begin
        // [GIVEN] A record with a decimal (fraction and thousands), a date and a boolean value
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('I001', 'Invariant', 7, 1234567.89, true, 20260201D);

        // [WHEN] A JSON export backup is created
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Invariant format backup', false);

        // [THEN] The stored JSON uses the culture-invariant representation (Format 9), not the user's regional format
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        TableBackup.CalcFields("Backup Data");
        TableBackup."Backup Data".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(JSONText);

        Assert.IsTrue(JSONText.Contains('"Decimal Value":"1234567.89"'), 'Decimal should be stored with a dot and without group separators. JSON: ' + JSONText);
        Assert.IsTrue(JSONText.Contains('"Date Value":"2026-02-01"'), 'Date should be stored as yyyy-MM-dd. JSON: ' + JSONText);
        Assert.IsTrue(JSONText.Contains('"Boolean Value":"true"'), 'Boolean should be stored as the invariant literal true. JSON: ' + JSONText);

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure CreateBackupWritesValidJSONArrayWithOneObjectPerRecord()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        InStream: InStream;
        JSONArray: JsonArray;
        JSONToken: JsonToken;
        JSONText: Text;
        EntryNo: Integer;
    begin
        // [GIVEN] Three records, one with characters that must be escaped inside the JSON
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('S901', 'Plain', 1, 1, true, 20260101D);
        CreateTestBufferRecord('S902', 'With "quotes", comma and ] bracket', 2, 2, false, 20260102D);
        CreateTestBufferRecord('S903', 'Third', 3, 3, true, 20260103D);

        // [WHEN] A JSON export backup is created
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'JSON array backup', false);

        // [THEN] The stored text is a valid JSON array with exactly one object per record
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        TableBackup.CalcFields("Backup Data");
        TableBackup."Backup Data".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(JSONText);

        Assert.IsTrue(JSONArray.ReadFrom(JSONText), 'Backup data should be a valid JSON array. JSON: ' + JSONText);
        Assert.AreEqual(3, JSONArray.Count(), 'Unexpected number of JSON objects.');
        JSONArray.Get(1, JSONToken);
        Assert.IsTrue(JSONToken.IsObject(), 'Array entries should be JSON objects.');
        Assert.AreEqual('S902', GetJSONObjectText(JSONToken, 'No.'), 'The second array entry should be the second record.');
        Assert.AreEqual('With "quotes", comma and ] bracket', GetJSONObjectText(JSONToken, 'Description'), 'Special characters should survive the JSON round trip.');
        Assert.IsTrue(TableBackup."Backup Size (KB)" > 0, 'Backup size should be set.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure CreateBackupOfEmptyTableWritesEmptyJSONArray()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        InStream: InStream;
        JSONText: Text;
        EntryNo: Integer;
    begin
        // [GIVEN] An empty source table
        TestBuffer.DeleteAll(false);

        // [WHEN] A JSON export backup is created
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Empty table backup', false);

        // [THEN] The stored text is an empty JSON array
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        TableBackup.CalcFields("Backup Data");
        TableBackup."Backup Data".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(JSONText);
        Assert.AreEqual('[]', JSONText, 'An empty table should be stored as an empty JSON array.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RestoreFromJSONStillReadsLegacyRegionalValues()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        OutStream: OutStream;
        JSONText: Text;
    begin
        // [GIVEN] A backup written before invariant serialization: "Yes" is rejected by the invariant (Format 9)
        // parser and only readable through the fallback; like the ExpectedError texts in this suite it assumes an English session language.
        TestBuffer.DeleteAll(false);
        JSONText := '[{"No.":"LEG01","Description":"Legacy","Integer Value":"42","Decimal Value":"42","Boolean Value":"Yes"}]';

        TableBackup.Init();
        TableBackup."Table ID" := Database::"Admin Tool Test Buffer";
        TableBackup."Backup Type" := TableBackup."Backup Type"::"JSON Export";
        TableBackup."No. of Records" := 1;
        TableBackup.Insert(true);
        TableBackup."Backup Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(JSONText);
        TableBackup.Modify(true);

        // [WHEN] The legacy backup is restored
        TableBackupMgt.RestoreFromJSON(TableBackup);

        // [THEN] The values are restored, "Yes" via the legacy fallback
        Assert.IsTrue(TestBuffer.Get('LEG01'), 'Legacy record should be restored.');
        Assert.AreEqual(42, TestBuffer."Integer Value", 'Integer Value does not match.');
        Assert.AreEqual(42, TestBuffer."Decimal Value", 'Decimal Value does not match.');
        Assert.IsTrue(TestBuffer."Boolean Value", 'Boolean Value "Yes" should be restored via the legacy fallback.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ViewBackupDataSucceedsWhenBackupDataExists()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        EntryNo: Integer;
    begin
        // [GIVEN] A backup with data
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('V001', 'View', 1, 1.1, true, 20260101D);
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'View backup', false);

        // [WHEN/THEN] Viewing the backup data does not raise an error
        Assert.IsTrue(TableBackup.Get(EntryNo), 'Backup entry should exist.');
        TableBackupMgt.ViewBackupData(TableBackup);

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure DeleteSnapshotTableDoesNotErrorForAnyId()
    begin
        // [WHEN/THEN] Deleting a snapshot table never errors, regardless of the ID (no-op cleanup)
        TableBackupMgt.DeleteSnapshotTable(0);
        TableBackupMgt.DeleteSnapshotTable(99000001);
    end;

    [Test]
    procedure DeletingBackupEntryWithSnapshotTableIdDoesNotError()
    var
        TableBackup: Record "Table Backup";
    begin
        // [GIVEN] A backup entry that reserved a snapshot table ID
        TableBackup.Init();
        TableBackup."Table ID" := Database::"Admin Tool Test Buffer";
        TableBackup."Snapshot Table ID" := 99000001;
        TableBackup.Insert(true);

        // [WHEN/THEN] Deleting the entry (OnDelete calls DeleteSnapshotTable) works
        TableBackup.Delete(true);
        Assert.IsFalse(TableBackup.Get(TableBackup."Entry No."), 'The backup entry should be deleted.');
    end;

    [Test]
    procedure NormalizeFilterViewKeepsViewWithFilter()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        FilterView: Text;
    begin
        // [GIVEN] A view that filters on Integer Value
        TestBuffer.SetFilter("Integer Value", '>%1', 1);
        FilterView := TestBuffer.GetView(false);

        // [WHEN/THEN] The view is returned unchanged
        Assert.AreEqual(FilterView, TableBackupMgt.NormalizeFilterView(Database::"Admin Tool Test Buffer", FilterView), 'A view with a filter should be returned unchanged.');
    end;

    [Test]
    procedure NormalizeFilterViewReturnsEmptyForViewWithoutFilter()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        // [WHEN/THEN] A sort-only view, as returned by the filter page for an untouched filter, and an empty view both normalize to an empty text
        Assert.AreEqual('', TableBackupMgt.NormalizeFilterView(Database::"Admin Tool Test Buffer", TestBuffer.GetView(false)), 'A sort-only view should be normalized to an empty text.');
        Assert.AreEqual('', TableBackupMgt.NormalizeFilterView(Database::"Admin Tool Test Buffer", ''), 'An empty view should stay empty.');
    end;

    [Test]
    procedure TableHasUnsupportedFieldsDetectsBlobAndMediaFields()
    begin
        // [WHEN/THEN] Tables with a Blob field (Table Backup) or a Media field (test buffer) are detected, a table with only supported types is not
        Assert.IsTrue(TableBackupMgt.TableHasUnsupportedFields(Database::"Table Backup"), 'Table Backup has a Blob field.');
        Assert.IsTrue(TableBackupMgt.TableHasUnsupportedFields(Database::"Admin Tool Test Buffer"), 'The test buffer has a Media field.');
        Assert.IsFalse(TableBackupMgt.TableHasUnsupportedFields(Database::"Admin Tool Test PK Target"), 'The PK target table has only supported field types.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CreateBackupReturnsZeroWhenUserDeclinesUnsupportedFields()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        EntryNo: Integer;
    begin
        // [GIVEN] A table with a Media field and a user who declines the question about the fields that cannot be backed up
        ConfirmReply := false;
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('U001', 'Unsupported', 1, 1, true, 20260101D);
        TableBackup.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        TableBackup.DeleteAll(false);

        // [WHEN] A backup is requested with the confirmation
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Declined', true);

        // [THEN] No backup was created
        Assert.AreEqual(0, EntryNo, 'Declining the question should return 0.');
        Assert.IsTrue(TableBackup.IsEmpty(), 'No backup should be created.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CreateBackupWithFilterCreatesBackupWhenUserAcceptsUnsupportedFields()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        EntryNo: Integer;
    begin
        // [GIVEN] A table with a Media field and a user who accepts
        ConfirmReply := true;
        TestBuffer.DeleteAll(false);
        CreateTestBufferRecord('U101', 'Accepted', 1, 1, true, 20260101D);

        // [WHEN] A filtered backup is requested with the confirmation
        EntryNo := TableBackupMgt.CreateBackupWithFilter(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Accepted', TestBuffer.GetView(false), true);

        // [THEN] The backup was created
        Assert.AreNotEqual(0, EntryNo, 'Accepting the question should create the backup.');
    end;

    [Test]
    procedure CreateBackupDoesNotAskForTablesWithoutUnsupportedFields()
    var
        TestPKTarget: Record "Admin Tool Test PK Target";
        EntryNo: Integer;
    begin
        // [GIVEN] A table with only supported field types (no Confirm handler: a question would fail the test)
        TestPKTarget.DeleteAll(false);
        TestPKTarget.Init();
        TestPKTarget."Code & No. (Key)" := 'U201';
        TestPKTarget.Insert(false);

        // [WHEN/THEN] A backup is created with the confirmation without any question
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test PK Target", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'No question', true);
        Assert.AreNotEqual(0, EntryNo, 'The backup should be created.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RestoreFromJSONFailsOnlyTheRecordWithAnUnparseableValue()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        OutStream: OutStream;
    begin
        // [GIVEN] A backup with one record whose Integer Value cannot be converted and one valid record
        TestBuffer.DeleteAll(false);
        TableBackup.Init();
        TableBackup."Table ID" := Database::"Admin Tool Test Buffer";
        TableBackup.Insert(true);
        TableBackup."Backup Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('[{"No.":"BAD01","Integer Value":"abc"},{"No.":"OK01","Integer Value":"5"}]');
        TableBackup.Modify(true);

        // [WHEN] The backup is restored
        TableBackupMgt.RestoreFromJSON(TableBackup);

        // [THEN] The broken record is not restored with a default value, it counts as failed; the valid record is restored
        Assert.AreEqual('Restored 1 of 2 records. 1 records failed to insert (possibly due to duplicates or validation errors).', LastMessage, 'Unexpected result message.');
        Assert.IsFalse(TestBuffer.Get('BAD01'), 'The record with the unparseable value must not be restored.');
        Assert.IsTrue(TestBuffer.Get('OK01'), 'The valid record should be restored.');
        Assert.AreEqual(5, TestBuffer."Integer Value", 'Unexpected Integer Value.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure RestoreFromJSONErrorsWhenNoRecordCanBeRestored()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        OutStream: OutStream;
    begin
        // [GIVEN] A backup whose only record has an unparseable value
        TestBuffer.DeleteAll(false);
        TableBackup.Init();
        TableBackup."Table ID" := Database::"Admin Tool Test Buffer";
        TableBackup.Insert(true);
        TableBackup."Backup Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('[{"No.":"BAD02","Decimal Value":"not a number"}]');
        TableBackup.Modify(true);

        // [WHEN/THEN] The restore raises the specific error
        asserterror TableBackupMgt.RestoreFromJSON(TableBackup);
        Assert.ExpectedError('No records could be inserted. All 1 attempts failed.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RestoreFromJSONReadsLegacyOptionCaption()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackup: Record "Table Backup";
        OutStream: OutStream;
    begin
        // [GIVEN] A backup from before the ordinal format: the option is stored as its caption (assumes an English session language)
        TestBuffer.DeleteAll(false);
        TableBackup.Init();
        TableBackup."Table ID" := Database::"Admin Tool Test Buffer";
        TableBackup.Insert(true);
        TableBackup."Backup Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('[{"No.":"LEGO1","Option Value":"Second"}]');
        TableBackup.Modify(true);

        // [WHEN] The backup is restored
        TableBackupMgt.RestoreFromJSON(TableBackup);

        // [THEN] The caption is resolved to the option
        Assert.IsTrue(TestBuffer.Get('LEGO1'), 'The record should be restored.');
        Assert.AreEqual(TestBuffer."Option Value"::Second, TestBuffer."Option Value", 'The option caption should be restored.');

        TestBuffer.DeleteAll(false);
    end;

    [Test]
    procedure DeleteOldBackupsDeletesOnlyBackupsOlderThanTheGivenDays()
    var
        TableBackup: Record "Table Backup";
        OldEntryNo: Integer;
        RecentEntryNo: Integer;
    begin
        // [GIVEN] No backup older than the cutoff exists, so the test can never delete real backups
        Assert.AreEqual(0, TableBackupMgt.CountOldBackups(30), 'Aborting: backups older than the cutoff already exist in this environment.');

        // [GIVEN] A backup 60 days old and a recent backup
        OldEntryNo := CreateBackupEntry(CreateDateTime(Today() - 60, 120000T));
        RecentEntryNo := CreateBackupEntry(CurrentDateTime());
        Assert.AreEqual(1, TableBackupMgt.CountOldBackups(30), 'The old backup should be counted.');

        // [WHEN] Backups older than 30 days are deleted
        Assert.AreEqual(1, TableBackupMgt.DeleteOldBackups(30), 'Exactly the old backup should be deleted.');

        // [THEN] The old backup is gone, the recent one remains
        Assert.IsFalse(TableBackup.Get(OldEntryNo), 'The old backup should be deleted.');
        Assert.IsTrue(TableBackup.Get(RecentEntryNo), 'The recent backup must be kept.');
    end;

    [Test]
    procedure DeleteOldBackupsKeepsEverythingForZeroDays()
    var
        TableBackup: Record "Table Backup";
        EntryNo: Integer;
    begin
        // [GIVEN] A 400 days old backup
        EntryNo := CreateBackupEntry(CreateDateTime(Today() - 400, 120000T));

        // [WHEN/THEN] With 0 days nothing is counted or deleted
        Assert.AreEqual(0, TableBackupMgt.CountOldBackups(0), 'Nothing should be counted for 0 days.');
        Assert.AreEqual(0, TableBackupMgt.DeleteOldBackups(0), 'Nothing should be deleted for 0 days.');
        Assert.IsTrue(TableBackup.Get(EntryNo), 'The backup must be kept.');

        // The test runner rolls back only after the whole codeunit, so the old entry must not stay behind
        TableBackup.Delete(false);
    end;

    [Test]
    procedure GetTableCaptionReturnsCaptionOrBlank()
    begin
        // [WHEN/THEN] The caption of a known table is returned, an unknown table yields an empty text
        Assert.AreEqual('Admin Tool Test Buffer', TableBackupMgt.GetTableCaption(Database::"Admin Tool Test Buffer"), 'Unexpected table caption.');
        Assert.AreEqual('', TableBackupMgt.GetTableCaption(1999999999), 'An unknown table should have no caption.');
    end;

    local procedure CreateBackupEntry(BackupDateTime: DateTime): Integer
    var
        TableBackup: Record "Table Backup";
    begin
        TableBackup.Init();
        TableBackup."Table ID" := Database::"Admin Tool Test Buffer";
        TableBackup.Insert(true);
        TableBackup."Backup Date Time" := BackupDateTime;
        TableBackup.Modify(false);
        exit(TableBackup."Entry No.");
    end;

    local procedure GetJSONObjectText(JSONToken: JsonToken; PropertyName: Text): Text
    var
        PropertyToken: JsonToken;
    begin
        JSONToken.AsObject().Get(PropertyName, PropertyToken);
        exit(PropertyToken.AsValue().AsText());
    end;

    local procedure CreateTestBufferRecord(No: Code[20]; Description: Text[100]; IntegerValue: Integer; DecimalValue: Decimal; BooleanValue: Boolean; DateValue: Date)
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        TestBuffer.Init();
        TestBuffer."No." := No;
        TestBuffer.Description := Description;
        TestBuffer."Integer Value" := IntegerValue;
        TestBuffer."Decimal Value" := DecimalValue;
        TestBuffer."Boolean Value" := BooleanValue;
        TestBuffer."Date Value" := DateValue;
        TestBuffer.Insert(false);
    end;
}
