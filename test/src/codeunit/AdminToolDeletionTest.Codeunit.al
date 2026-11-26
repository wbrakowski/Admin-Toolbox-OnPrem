namespace AdminToolbox.Test;

using AdminToolbox;
using Microsoft.Sales.Document;
using System.Reflection;
using System.TestLibraries.Utilities;

codeunit 51101 "Admin Tool Deletion Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        ConfirmReply: Boolean;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        // The messages shown by the code under test are not part of these tests
    end;

    [Test]
    procedure SetSuggestedTableMarksExistingEntryForDeletion()
    var
        RecordDeletion: Record "Record Deletion";
    begin
        // [GIVEN] A Record Deletion entry exists for the test table, not yet marked for deletion
        DeleteRecordDeletionEntry(Database::"Admin Tool Test Buffer");
        CreateRecordDeletionEntry(Database::"Admin Tool Test Buffer");

        // [WHEN] The table is suggested for deletion
        AdminToolMgt.SetSuggestedTable(Database::"Admin Tool Test Buffer");

        // [THEN] The entry is marked for deletion
        Assert.IsTrue(RecordDeletion.Get(Database::"Admin Tool Test Buffer"), 'Record Deletion entry should exist.');
        Assert.IsTrue(RecordDeletion."Delete Records", 'Delete Records should be set to true.');
    end;

    [Test]
    procedure SetSuggestedTableDoesNothingWithoutExistingEntry()
    var
        RecordDeletion: Record "Record Deletion";
    begin
        // [GIVEN] No Record Deletion entry exists for the test table
        DeleteRecordDeletionEntry(Database::"Admin Tool Test Buffer");

        // [WHEN] The table is suggested for deletion
        AdminToolMgt.SetSuggestedTable(Database::"Admin Tool Test Buffer");

        // [THEN] No entry was created
        Assert.IsFalse(RecordDeletion.Get(Database::"Admin Tool Test Buffer"), 'No Record Deletion entry should have been created.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ClearRecordsToDeleteClearsAllFlags()
    var
        RecordDeletion: Record "Record Deletion";
    begin
        // [GIVEN] The test table is marked for deletion
        DeleteRecordDeletionEntry(Database::"Admin Tool Test Buffer");
        CreateRecordDeletionEntry(Database::"Admin Tool Test Buffer");
        FlagRecordDeletionEntry(Database::"Admin Tool Test Buffer");

        // [WHEN] All records to delete flags are cleared
        AdminToolMgt.ClearRecordsToDelete();

        // [THEN] The flag is cleared and no entry remains marked for deletion
        Assert.IsTrue(RecordDeletion.Get(Database::"Admin Tool Test Buffer"), 'Record Deletion entry should still exist.');
        Assert.IsFalse(RecordDeletion."Delete Records", 'Delete Records should be cleared.');
        RecordDeletion.SetRange("Delete Records", true);
        Assert.IsTrue(RecordDeletion.IsEmpty(), 'No Record Deletion entry should be marked for deletion.');
    end;

    [Test]
    procedure CalcRecordsInTableReturnsRecordCount()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        // [GIVEN] Two records in the test table
        TestBuffer.DeleteAll(false);
        InsertTestBufferRecord('R001');
        InsertTestBufferRecord('R002');

        // [WHEN/THEN] The record count matches, and an unknown table has no records
        Assert.AreEqual(2, AdminToolMgt.CalcRecordsInTable(Database::"Admin Tool Test Buffer"), 'Unexpected record count.');
        Assert.AreEqual(0, AdminToolMgt.CalcRecordsInTable(1999999999), 'An unknown table should have no records.');
    end;

    [Test]
    procedure GetTableCaptionReturnsCaptionForKnownTableAndBlankForUnknownTable()
    begin
        // [WHEN/THEN] The caption of a known table is returned, an unknown table yields an empty text
        Assert.AreEqual('Admin Tool Test Buffer', AdminToolMgt.GetTableCaption(Database::"Admin Tool Test Buffer"), 'Unexpected table caption.');
        Assert.AreEqual('', AdminToolMgt.GetTableCaption(1999999999), 'An unknown table should have no caption.');
    end;

    [Test]
    procedure CheckTableRelationsForTableDetectsMissingRelatedRecord()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
    begin
        // [GIVEN] One record with a blank, one with a valid and one with a dangling self-reference
        TestBuffer.DeleteAll(false);
        ClearRelationErrors();

        InsertTestBufferRecordWithRelation('C001', '');
        InsertTestBufferRecordWithRelation('C002', 'C001');
        InsertTestBufferRecordWithRelation('C003', 'MISSING');

        // [WHEN] Table relations are checked for the test table
        AdminToolMgt.CheckTableRelationsForTable(Database::"Admin Tool Test Buffer");

        // [THEN] Only the dangling reference is reported as a relation error
        RecordDeletionRelError.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        Assert.RecordCount(RecordDeletionRelError, 1);
        Assert.IsTrue(RecordDeletionRelError.FindFirst(), 'A relation error should have been recorded.');
        Assert.AreEqual(TestBuffer.FieldNo("Related No."), RecordDeletionRelError."Field No.", 'Unexpected field reported in the relation error.');
    end;

    [Test]
    procedure CheckTableRelationsForTableDetectsMissingPrimaryKeyRelation()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
    begin
        // [GIVEN] Records with a blank, a valid and a dangling relation to the primary key (no explicit target field)
        TestBuffer.DeleteAll(false);
        ClearRelationErrors();

        InsertTestBufferRecordWithPrimaryKeyRelation('K001', '');
        InsertTestBufferRecordWithPrimaryKeyRelation('K002', 'K001');
        InsertTestBufferRecordWithPrimaryKeyRelation('K003', 'MISSING');

        // [WHEN] Table relations are checked for the test table
        AdminToolMgt.CheckTableRelationsForTable(Database::"Admin Tool Test Buffer");

        // [THEN] Only the dangling reference is reported as a relation error
        RecordDeletionRelError.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        Assert.RecordCount(RecordDeletionRelError, 1);
        Assert.IsTrue(RecordDeletionRelError.FindFirst(), 'A relation error should have been recorded.');
        Assert.AreEqual(TestBuffer.FieldNo("Related PK No."), RecordDeletionRelError."Field No.", 'Unexpected field reported in the relation error.');
    end;

    [Test]
    procedure CheckTableRelationsForTableHandlesPrimaryKeyNameWithSpecialCharacters()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TestPKTarget: Record "Admin Tool Test PK Target";
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
    begin
        // [GIVEN] A target table whose primary key field name contains ( ) &, with one record
        TestBuffer.DeleteAll(false);
        TestPKTarget.DeleteAll(false);
        ClearRelationErrors();

        TestPKTarget.Init();
        TestPKTarget."Code & No. (Key)" := 'P001';
        TestPKTarget.Insert(false);

        // [GIVEN] Test buffer records with a blank, a valid and a dangling relation to that table
        InsertTestBufferRecordWithSpecialPKRelation('S001', '');
        InsertTestBufferRecordWithSpecialPKRelation('S002', 'P001');
        InsertTestBufferRecordWithSpecialPKRelation('S003', 'MISSING');

        // [WHEN] Table relations are checked for the test table
        AdminToolMgt.CheckTableRelationsForTable(Database::"Admin Tool Test Buffer");

        // [THEN] Only the dangling reference is reported as a relation error
        RecordDeletionRelError.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        Assert.RecordCount(RecordDeletionRelError, 1);
        Assert.IsTrue(RecordDeletionRelError.FindFirst(), 'A relation error should have been recorded.');
        Assert.AreEqual(TestBuffer.FieldNo("Related Special PK No."), RecordDeletionRelError."Field No.", 'Unexpected field reported in the relation error.');
    end;

    [Test]
    procedure CheckTableRelationsForTableDetectsMissingGuidRelation()
    var
        TestBufferA: Record "Admin Tool Test Buffer";
        TestBufferB: Record "Admin Tool Test Buffer";
        TestBufferC: Record "Admin Tool Test Buffer";
        TestBufferD: Record "Admin Tool Test Buffer";
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
    begin
        // [GIVEN] Records with a valid GUID reference, a dangling one and a blank one
        TestBufferA.DeleteAll(false);
        ClearRelationErrors();

        TestBufferA.Init();
        TestBufferA."No." := 'G001';
        TestBufferA.Insert(false);

        TestBufferB.Init();
        TestBufferB."No." := 'G002';
        TestBufferB."Related System ID" := TestBufferA.SystemId;
        TestBufferB.Insert(false);

        TestBufferC.Init();
        TestBufferC."No." := 'G003';
        TestBufferC."Related System ID" := CreateGuid();
        TestBufferC.Insert(false);

        TestBufferD.Init();
        TestBufferD."No." := 'G004';
        TestBufferD.Insert(false);

        // [WHEN] Table relations are checked for the test table
        AdminToolMgt.CheckTableRelationsForTable(Database::"Admin Tool Test Buffer");

        // [THEN] Only the dangling GUID reference is reported as a relation error
        RecordDeletionRelError.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        Assert.RecordCount(RecordDeletionRelError, 1);
        Assert.IsTrue(RecordDeletionRelError.FindFirst(), 'A relation error should have been recorded.');
        Assert.AreEqual(TestBufferA.FieldNo("Related System ID"), RecordDeletionRelError."Field No.", 'Unexpected field reported in the relation error.');
    end;

    [Test]
    procedure CheckTableRelationsForTableRunsForStandardTablesRelatedToEachSystemTable()
    var
        Field: Record Field;
        TableMetadata: Record "Table Metadata";
        SourceTableIds: Dictionary of [Integer, Integer];
        SourceTableId: Integer;
    begin
        // [GIVEN] For every system table that standard tables relate to, one normal standard table with such a relation
        Field.SetRange(TableNo, 1, 49999);
        Field.SetFilter(RelationTableNo, '>=%1', 2000000000);
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
        Field.SetLoadFields(TableNo, RelationTableNo);
        Assert.IsTrue(Field.FindSet(), 'Expected standard tables with relations to system tables.');
        repeat
            if SourceTableIds.ContainsKey(Field.RelationTableNo) then
                continue;
            TableMetadata.SetRange(ID, Field.TableNo);
            TableMetadata.SetRange(TableType, TableMetadata.TableType::Normal);
            if TableMetadata.IsEmpty() then
                continue;
            SourceTableIds.Add(Field.RelationTableNo, Field.TableNo);
        until Field.Next() = 0;

        // [WHEN/THEN] The relation check runs for all of them without a runtime error
        foreach SourceTableId in SourceTableIds.Values() do
            AdminToolMgt.CheckTableRelationsForTable(SourceTableId);
    end;

    [Test]
    procedure PerformDeletionDeletesFlaggedRecordsClearsRelationErrorsAndLogsTheDeletion()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        RecordDeletion: Record "Record Deletion";
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
        StaleRelError: Record "Record Deletion Rel. Error";
        AuditLogEntry: Record "Audit Log Entry";
        UpdateDialog: Dialog;
    begin
        // [GIVEN] Two records in the test table, flagged for deletion, plus a stale relation error entry
        TestBuffer.DeleteAll(false);
        InsertTestBufferRecord('P001');
        InsertTestBufferRecord('P002');
        FlagOnlyTestBufferForDeletion(RecordDeletion);
        ClearRelationErrors();

        StaleRelError.Init();
        StaleRelError."Table ID" := Database::"Admin Tool Test Buffer";
        StaleRelError."Entry No." := 1;
        StaleRelError.Insert(false);

        AuditLogEntry.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        AuditLogEntry.DeleteAll(false);

        // [WHEN] Deletion is performed (with the progress dialog that DeleteRecords opens)
        UpdateDialog.Open('Deleting #1#######');
        AdminToolMgt.PerformDeletion(RecordDeletion, RecordDeletionRelError, false, UpdateDialog);
        UpdateDialog.Close();

        // [THEN] The flagged table's records and its relation errors are gone
        Assert.IsTrue(TestBuffer.IsEmpty(), 'Test buffer records should have been deleted.');
        RecordDeletionRelError.Reset();
        RecordDeletionRelError.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        Assert.IsTrue(RecordDeletionRelError.IsEmpty(), 'Relation errors for the deleted table should have been cleared.');

        // [THEN] The deletion is logged as a successful Delete operation with the number of deleted records
        Assert.RecordCount(AuditLogEntry, 1);
        Assert.IsTrue(AuditLogEntry.FindFirst(), 'An audit log entry should exist.');
        Assert.AreEqual(Enum::"Audit Log Operation Type"::Delete.AsInteger(), AuditLogEntry."Operation Type".AsInteger(), 'Unexpected operation type in the audit log.');
        Assert.AreEqual(Enum::"Audit Log Status"::Success.AsInteger(), AuditLogEntry.Status.AsInteger(), 'Unexpected status in the audit log.');
        Assert.AreEqual(2, AuditLogEntry."No. of Records Affected", 'Unexpected number of deleted records in the audit log.');
    end;

    [Test]
    procedure PerformDeletionLeavesRecordsOfUnflaggedTablesUntouched()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TestPKTarget: Record "Admin Tool Test PK Target";
        RecordDeletion: Record "Record Deletion";
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
        UpdateDialog: Dialog;
    begin
        // [GIVEN] Records in two tables, only one of them flagged for deletion
        TestBuffer.DeleteAll(false);
        TestPKTarget.DeleteAll(false);
        InsertTestBufferRecord('U001');
        TestPKTarget.Init();
        TestPKTarget."Code & No. (Key)" := 'U001';
        TestPKTarget.Insert(false);
        FlagOnlyTestBufferForDeletion(RecordDeletion);

        // [WHEN] Deletion is performed (with the progress dialog that DeleteRecords opens)
        UpdateDialog.Open('Deleting #1#######');
        AdminToolMgt.PerformDeletion(RecordDeletion, RecordDeletionRelError, false, UpdateDialog);
        UpdateDialog.Close();

        // [THEN] Only the flagged table was emptied
        Assert.IsTrue(TestBuffer.IsEmpty(), 'The flagged table should be empty.');
        Assert.IsFalse(TestPKTarget.IsEmpty(), 'The unflagged table must not be touched.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    procedure CreateBackupsBeforeDeletionCreatesBackupForFlaggedTable()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        RecordDeletion: Record "Record Deletion";
        TableBackup: Record "Table Backup";
        UpdateDialog: Dialog;
        BackupCount: Integer;
        BackupCountBefore: Integer;
    begin
        // [GIVEN] Automatic backups without prompt, and a record in the test table flagged for deletion
        //         (the table has a Media field, so the user is asked once about the fields that cannot be backed up and agrees)
        ConfirmReply := true;
        SetupAutoBackup(true, false, Enum::"Backup Type"::"JSON Export");
        TestBuffer.DeleteAll(false);
        InsertTestBufferRecord('B001');
        FlagOnlyTestBufferForDeletion(RecordDeletion);

        TableBackup.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        BackupCountBefore := TableBackup.Count();

        // [WHEN] Backups are created for the flagged table
        UpdateDialog.Open('Deleting #1#######');
        Assert.IsTrue(AdminToolMgt.CreateBackupsBeforeDeletion(RecordDeletion, UpdateDialog, BackupCount), 'The deletion should not be cancelled.');
        UpdateDialog.Close();

        // [THEN] Exactly one new backup of the table exists, created for the deletion
        Assert.AreEqual(1, BackupCount, 'Unexpected number of created backups.');
        Assert.AreEqual(BackupCountBefore + 1, TableBackup.Count(), 'Expected exactly one new backup to be created.');
        Assert.IsTrue(TableBackup.FindLast(), 'A backup should have been created.');
        Assert.AreEqual(Enum::"Backup Operation Type"::"Before Deletion".AsInteger(), TableBackup."Operation Type".AsInteger(), 'Unexpected operation type of the backup.');
        Assert.AreEqual(1, TableBackup."No. of Records", 'Unexpected number of backed up records.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CreateBackupsBeforeDeletionCancelsWhenUserDeclinesTablesWithUnsupportedFields()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        RecordDeletion: Record "Record Deletion";
        TableBackup: Record "Table Backup";
        UpdateDialog: Dialog;
        BackupCount: Integer;
    begin
        // [GIVEN] Automatic backups without prompt, a flagged table with a Media field, and a user who declines
        ConfirmReply := false;
        SetupAutoBackup(true, false, Enum::"Backup Type"::"JSON Export");
        TestBuffer.DeleteAll(false);
        InsertTestBufferRecord('B051');
        FlagOnlyTestBufferForDeletion(RecordDeletion);

        TableBackup.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        TableBackup.DeleteAll(false);

        // [WHEN] Backups are created for the flagged table
        UpdateDialog.Open('Deleting #1#######');
        Assert.IsFalse(AdminToolMgt.CreateBackupsBeforeDeletion(RecordDeletion, UpdateDialog, BackupCount), 'Declining the question should cancel the deletion.');

        // [THEN] No backup was created
        Assert.AreEqual(0, BackupCount, 'No backup should be counted.');
        Assert.IsTrue(TableBackup.IsEmpty(), 'No backup should be created when the user cancels.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CreateBackupsBeforeDeletionDoesNotAskForTablesWithoutUnsupportedFields()
    var
        TestPKTarget: Record "Admin Tool Test PK Target";
        RecordDeletion: Record "Record Deletion";
        TableBackup: Record "Table Backup";
        UpdateDialog: Dialog;
        BackupCount: Integer;
    begin
        // [GIVEN] Automatic backups without prompt and a flagged table that has only supported field types (no Confirm handler: a question would fail the test)
        SetupAutoBackup(true, false, Enum::"Backup Type"::"JSON Export");
        TestPKTarget.DeleteAll(false);
        TestPKTarget.Init();
        TestPKTarget."Code & No. (Key)" := 'B061';
        TestPKTarget.Insert(false);
        DeleteRecordDeletionEntry(Database::"Admin Tool Test PK Target");
        CreateRecordDeletionEntry(Database::"Admin Tool Test PK Target");
        FlagRecordDeletionEntry(Database::"Admin Tool Test PK Target");
        RecordDeletion.SetRange("Table ID", Database::"Admin Tool Test PK Target");
        RecordDeletion.SetRange("Delete Records", true);
        Assert.RecordCount(RecordDeletion, 1);

        // [WHEN] Backups are created for the flagged table
        UpdateDialog.Open('Deleting #1#######');
        Assert.IsTrue(AdminToolMgt.CreateBackupsBeforeDeletion(RecordDeletion, UpdateDialog, BackupCount), 'The deletion should not be cancelled.');
        UpdateDialog.Close();

        // [THEN] The backup was created without any question
        TableBackup.SetRange("Table ID", Database::"Admin Tool Test PK Target");
        Assert.AreEqual(1, BackupCount, 'Unexpected number of created backups.');
        Assert.IsFalse(TableBackup.IsEmpty(), 'A backup should have been created.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    procedure CreateBackupsBeforeDeletionUsesJsonExportWhenBackupTypeIsBlank()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        RecordDeletion: Record "Record Deletion";
        TableBackup: Record "Table Backup";
        BlankBackupType: Enum "Backup Type";
        UpdateDialog: Dialog;
        BackupCount: Integer;
    begin
        // [GIVEN] Automatic backups with a blank backup type in the setup
        ConfirmReply := true;
        SetupAutoBackup(true, false, BlankBackupType);
        TestBuffer.DeleteAll(false);
        InsertTestBufferRecord('B101');
        FlagOnlyTestBufferForDeletion(RecordDeletion);

        // [WHEN] Backups are created for the flagged table
        UpdateDialog.Open('Deleting #1#######');
        AdminToolMgt.CreateBackupsBeforeDeletion(RecordDeletion, UpdateDialog, BackupCount);
        UpdateDialog.Close();

        // [THEN] JSON Export is used
        TableBackup.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        Assert.IsTrue(TableBackup.FindLast(), 'A backup should have been created.');
        Assert.AreEqual(Enum::"Backup Type"::"JSON Export".AsInteger(), TableBackup."Backup Type".AsInteger(), 'A blank backup type should fall back to JSON Export.');
    end;

    [Test]
    procedure CreateBackupsBeforeDeletionCreatesNoBackupWhenAutoBackupIsDisabled()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        RecordDeletion: Record "Record Deletion";
        TableBackup: Record "Table Backup";
        UpdateDialog: Dialog;
        BackupCount: Integer;
    begin
        // [GIVEN] Automatic backups are disabled and a record is flagged for deletion
        SetupAutoBackup(false, false, Enum::"Backup Type"::"JSON Export");
        TestBuffer.DeleteAll(false);
        InsertTestBufferRecord('B201');
        FlagOnlyTestBufferForDeletion(RecordDeletion);

        TableBackup.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        TableBackup.DeleteAll(false);

        // [WHEN] Backups are created for the flagged table
        Assert.IsTrue(AdminToolMgt.CreateBackupsBeforeDeletion(RecordDeletion, UpdateDialog, BackupCount), 'The deletion should not be cancelled.');

        // [THEN] No backup was created
        Assert.AreEqual(0, BackupCount, 'No backup should be counted.');
        Assert.IsTrue(TableBackup.IsEmpty(), 'No backup should be created when automatic backups are disabled.');
    end;

    [Test]
    procedure IsTableProtectedReturnsTrueForOwnAndSystemTables()
    begin
        // [WHEN/THEN] The tables of the Admin Toolbox itself and the system tables are protected from deletion
        Assert.IsTrue(AdminToolMgt.IsTableProtected(Database::"Record Deletion"), 'Record Deletion should be protected.');
        Assert.IsTrue(AdminToolMgt.IsTableProtected(Database::"Record Deletion Rel. Error"), 'Record Deletion Rel. Error should be protected.');
        Assert.IsTrue(AdminToolMgt.IsTableProtected(Database::"Table Backup"), 'Table Backup should be protected.');
        Assert.IsTrue(AdminToolMgt.IsTableProtected(Database::"Audit Log Entry"), 'Audit Log Entry should be protected.');
        Assert.IsTrue(AdminToolMgt.IsTableProtected(Database::"Field Change History"), 'Field Change History should be protected.');
        Assert.IsTrue(AdminToolMgt.IsTableProtected(Database::"Admin Toolbox Setup"), 'Admin Toolbox Setup should be protected.');
        Assert.IsTrue(AdminToolMgt.IsTableProtected(2000000000), 'System tables should be protected.');
    end;

    [Test]
    procedure IsTableProtectedReturnsFalseForOtherTables()
    begin
        // [WHEN/THEN] Ordinary tables are not protected
        Assert.IsFalse(AdminToolMgt.IsTableProtected(Database::"Admin Tool Test Buffer"), 'The test buffer should not be protected.');
        Assert.IsFalse(AdminToolMgt.IsTableProtected(Database::"Sales Header"), 'Sales Header should not be protected.');
        Assert.IsFalse(AdminToolMgt.IsTableProtected(1999999999), 'The last ID below the system range should not be protected.');
    end;

    [Test]
    procedure SetSuggestedTableIgnoresProtectedTable()
    var
        RecordDeletion: Record "Record Deletion";
    begin
        // [GIVEN] A Record Deletion entry for one of the tables of the Admin Toolbox
        DeleteRecordDeletionEntry(Database::"Table Backup");
        CreateRecordDeletionEntry(Database::"Table Backup");

        // [WHEN] The protected table is suggested for deletion
        AdminToolMgt.SetSuggestedTable(Database::"Table Backup");

        // [THEN] It is not flagged
        Assert.IsTrue(RecordDeletion.Get(Database::"Table Backup"), 'Record Deletion entry should still exist.');
        Assert.IsFalse(RecordDeletion."Delete Records", 'A protected table must never be flagged for deletion.');
    end;

    [Test]
    procedure PerformDeletionErrorsWhenProtectedTableIsFlagged()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        RecordDeletion: Record "Record Deletion";
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
        UpdateDialog: Dialog;
        ErrorText: Text;
    begin
        // [GIVEN] A deletable table and a protected table are both flagged (the flag is set directly, bypassing SetSuggestedTable)
        TestBuffer.DeleteAll(false);
        InsertTestBufferRecord('X001');
        DeleteRecordDeletionEntry(Database::"Admin Tool Test Buffer");
        CreateRecordDeletionEntry(Database::"Admin Tool Test Buffer");
        FlagRecordDeletionEntry(Database::"Admin Tool Test Buffer");
        DeleteRecordDeletionEntry(Database::"Table Backup");
        CreateRecordDeletionEntry(Database::"Table Backup");
        FlagRecordDeletionEntry(Database::"Table Backup");

        // The record is limited to the two tables above, so the code under test can never reach other tables
        RecordDeletion.SetFilter("Table ID", '%1|%2', Database::"Admin Tool Test Buffer", Database::"Table Backup");
        Assert.RecordCount(RecordDeletion, 2);

        // [WHEN] Deletion is performed
        UpdateDialog.Open('Deleting #1#######');
        asserterror AdminToolMgt.PerformDeletion(RecordDeletion, RecordDeletionRelError, false, UpdateDialog);
        ErrorText := GetLastErrorText();

        // [THEN] The error names the protected table only (asserterror rolls the writes back, the error text is the only observable result)
        Assert.ExpectedError('belong to the Admin Toolbox or to the system and cannot be deleted');
        Assert.IsTrue(ErrorText.Contains('Table Backup'), 'The error should list the protected table.');
        Assert.IsFalse(ErrorText.Contains('Admin Tool Test Buffer'), 'The error should not list the deletable table.');
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := ConfirmReply;
    end;

    local procedure SetupAutoBackup(AutoBackup: Boolean; PromptForBackup: Boolean; BackupType: Enum "Backup Type")
    var
        AdminToolboxSetup: Record "Admin Toolbox Setup";
    begin
        if not AdminToolboxSetup.Get() then begin
            AdminToolboxSetup.Init();
            AdminToolboxSetup.Insert(false);
        end;
        AdminToolboxSetup."Auto Backup Before Deletion" := AutoBackup;
        AdminToolboxSetup."Prompt for Backup" := PromptForBackup;
        AdminToolboxSetup."Auto Backup Type" := BackupType;
        AdminToolboxSetup.Modify(false);
    end;

    // Flags only the test table and filters the passed record to it, so the code under test can never touch real tables.
    local procedure FlagOnlyTestBufferForDeletion(var RecordDeletion: Record "Record Deletion")
    begin
        DeleteRecordDeletionEntry(Database::"Admin Tool Test Buffer");
        CreateRecordDeletionEntry(Database::"Admin Tool Test Buffer");
        FlagRecordDeletionEntry(Database::"Admin Tool Test Buffer");

        RecordDeletion.Reset();
        RecordDeletion.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        RecordDeletion.SetRange("Delete Records", true);
        Assert.RecordCount(RecordDeletion, 1);
    end;

    local procedure ClearRelationErrors()
    var
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
    begin
        RecordDeletionRelError.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        RecordDeletionRelError.DeleteAll(false);
    end;

    local procedure FlagRecordDeletionEntry(TableID: Integer)
    var
        RecordDeletion: Record "Record Deletion";
    begin
        Assert.IsTrue(RecordDeletion.Get(TableID), 'Record Deletion entry should exist before flagging it.');
        RecordDeletion."Delete Records" := true;
        RecordDeletion.Modify(false);
    end;

    local procedure CreateRecordDeletionEntry(TableID: Integer)
    var
        RecordDeletion: Record "Record Deletion";
    begin
        RecordDeletion.Init();
        RecordDeletion."Table ID" := TableID;
        RecordDeletion.Insert(false);
    end;

    local procedure DeleteRecordDeletionEntry(TableID: Integer)
    var
        RecordDeletion: Record "Record Deletion";
    begin
        if RecordDeletion.Get(TableID) then
            RecordDeletion.Delete(false);
    end;

    local procedure InsertTestBufferRecord(BufferNo: Code[20])
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        TestBuffer.Init();
        TestBuffer."No." := BufferNo;
        TestBuffer.Insert(false);
    end;

    local procedure InsertTestBufferRecordWithRelation(BufferNo: Code[20]; RelatedNo: Code[20])
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        TestBuffer.Init();
        TestBuffer."No." := BufferNo;
        TestBuffer."Related No." := RelatedNo;
        TestBuffer.Insert(false);
    end;

    local procedure InsertTestBufferRecordWithPrimaryKeyRelation(BufferNo: Code[20]; RelatedPKNo: Code[20])
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        TestBuffer.Init();
        TestBuffer."No." := BufferNo;
        TestBuffer."Related PK No." := RelatedPKNo;
        TestBuffer.Insert(false);
    end;

    local procedure InsertTestBufferRecordWithSpecialPKRelation(BufferNo: Code[20]; RelatedSpecialPKNo: Code[20])
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        TestBuffer.Init();
        TestBuffer."No." := BufferNo;
        TestBuffer."Related Special PK No." := RelatedSpecialPKNo;
        TestBuffer.Insert(false);
    end;
}
