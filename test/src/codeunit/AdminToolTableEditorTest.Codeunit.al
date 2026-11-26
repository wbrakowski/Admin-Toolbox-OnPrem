namespace AdminToolbox.Test;

using AdminToolbox;
using System.TestLibraries.Utilities;

codeunit 51105 "Admin Tool Table Editor Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TableEditorMgt: Codeunit "Table Editor Mgt.";

    [Test]
    procedure CountRecordsCountsTheViewOrTheWholeTable()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        // [GIVEN] Three records, two of them in a view
        TestBuffer.DeleteAll(false);
        InsertTestBufferRecord('CNT1', 'x');
        InsertTestBufferRecord('CNT2', 'x');
        InsertTestBufferRecord('OTHER', 'x');

        // [WHEN/THEN] The view is counted, a blank view counts the whole table, no table counts nothing
        Assert.AreEqual(2, TableEditorMgt.CountRecords(Database::"Admin Tool Test Buffer", GetViewFor('CNT*')), 'Unexpected number of records in the view.');
        Assert.AreEqual(3, TableEditorMgt.CountRecords(Database::"Admin Tool Test Buffer", ''), 'Unexpected number of records in the table.');
        Assert.AreEqual(0, TableEditorMgt.CountRecords(0, ''), 'No table has no records.');
    end;

    [Test]
    procedure ModifyRecordsChangesOnlyTheRecordsOfTheViewAndLogsEveryChange()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        AuditLogEntry: Record "Audit Log Entry";
        FieldChangeHistory: Record "Field Change History";
        ModifiedCount: Integer;
    begin
        // [GIVEN] Three records with the same description and no audit log entries for the test table
        TestBuffer.DeleteAll(false);
        ClearAuditLog();
        InsertTestBufferRecord('ED01', 'Old');
        InsertTestBufferRecord('ED02', 'Old');
        InsertTestBufferRecord('ED03', 'Old');

        // [WHEN] The description of two of them is modified
        ModifiedCount := TableEditorMgt.ModifyRecords(Database::"Admin Tool Test Buffer", GetViewFor('ED01|ED02'), TestBuffer.FieldNo(Description), 'New', false, false);

        // [THEN] Only those two are changed
        Assert.AreEqual(2, ModifiedCount, 'Unexpected number of modified records.');
        Assert.AreEqual('New', GetDescription('ED01'), 'ED01 should be modified.');
        Assert.AreEqual('New', GetDescription('ED02'), 'ED02 should be modified.');
        Assert.AreEqual('Old', GetDescription('ED03'), 'ED03 is not in the view and must not change.');

        // [THEN] One bulk modify entry with two logged field changes exists
        AuditLogEntry.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        Assert.RecordCount(AuditLogEntry, 1);
        Assert.IsTrue(AuditLogEntry.FindFirst(), 'An audit log entry should exist.');
        Assert.AreEqual(Enum::"Audit Log Operation Type"::"Bulk Modify".AsInteger(), AuditLogEntry."Operation Type".AsInteger(), 'Unexpected operation type.');
        Assert.AreEqual(Enum::"Audit Log Status"::Success.AsInteger(), AuditLogEntry.Status.AsInteger(), 'Unexpected status.');
        Assert.AreEqual(2, AuditLogEntry."No. of Records Affected", 'Unexpected number of affected records.');
        FieldChangeHistory.SetRange("Audit Log Entry No.", AuditLogEntry."Entry No.");
        Assert.RecordCount(FieldChangeHistory, 2);
    end;

    [Test]
    procedure ModifyRecordsWithValidateSetsTheValue()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        // [GIVEN] A record
        TestBuffer.DeleteAll(false);
        ClearAuditLog();
        InsertTestBufferRecord('ED11', 'Old');

        // [WHEN] The Integer Value is modified with the validate trigger
        TableEditorMgt.ModifyRecords(Database::"Admin Tool Test Buffer", GetViewFor('ED11'), TestBuffer.FieldNo("Integer Value"), '42', false, true);

        // [THEN] The value is set
        Assert.IsTrue(TestBuffer.Get('ED11'), 'The record should exist.');
        Assert.AreEqual(42, TestBuffer."Integer Value", 'The Integer Value should be modified.');
    end;

    [Test]
    procedure ModifyRecordsDoesNothingAndLogsNothingWhenTheViewMatchesNoRecord()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        AuditLogEntry: Record "Audit Log Entry";
    begin
        // [GIVEN] A record that is not in the view
        TestBuffer.DeleteAll(false);
        ClearAuditLog();
        InsertTestBufferRecord('ED21', 'Old');

        // [WHEN/THEN] Nothing is modified and no audit log entry is created
        Assert.AreEqual(0, TableEditorMgt.ModifyRecords(Database::"Admin Tool Test Buffer", GetViewFor('NOMATCH'), TestBuffer.FieldNo(Description), 'New', false, false), 'No record should be modified.');
        Assert.AreEqual('Old', GetDescription('ED21'), 'The record must not change.');
        AuditLogEntry.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        Assert.IsTrue(AuditLogEntry.IsEmpty(), 'Nothing should be logged.');
    end;

    [Test]
    procedure FieldIndexInPrimaryKeyReturnsPositionOrMinusOne()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        // [WHEN/THEN] The primary key field has index 1, other fields are not part of the key
        Assert.AreEqual(1, TableEditorMgt.FieldIndexInPrimaryKey(Database::"Admin Tool Test Buffer", TestBuffer.FieldNo("No.")), 'No. is the first key field.');
        Assert.AreEqual(-1, TableEditorMgt.FieldIndexInPrimaryKey(Database::"Admin Tool Test Buffer", TestBuffer.FieldNo(Description)), 'Description is not part of the key.');
    end;

    [Test]
    procedure RenameRecordsRenamesThePrimaryKeyAndLogsTheChange()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        AuditLogEntry: Record "Audit Log Entry";
        FieldChangeHistory: Record "Field Change History";
    begin
        // [GIVEN] A record
        TestBuffer.DeleteAll(false);
        ClearAuditLog();
        InsertTestBufferRecord('ED30', 'Rename me');

        // [WHEN] The primary key is renamed
        Assert.AreEqual('[RNEW]', TableEditorMgt.GetRenamePreview(Database::"Admin Tool Test Buffer", TestBuffer.FieldNo("No."), 'RNEW'), 'Unexpected rename preview.');
        Assert.AreEqual(1, TableEditorMgt.RenameRecords(Database::"Admin Tool Test Buffer", GetViewFor('ED30'), TestBuffer.FieldNo("No."), 'RNEW'), 'One record should be renamed.');

        // [THEN] The record has the new key and the rename is logged
        Assert.IsFalse(TestBuffer.Get('ED30'), 'The old key should be gone.');
        Assert.IsTrue(TestBuffer.Get('RNEW'), 'The new key should exist.');
        Assert.AreEqual('Rename me', TestBuffer.Description, 'The other fields must be kept.');
        AuditLogEntry.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        Assert.RecordCount(AuditLogEntry, 1);
        Assert.IsTrue(AuditLogEntry.FindFirst(), 'An audit log entry should exist.');
        FieldChangeHistory.SetRange("Audit Log Entry No.", AuditLogEntry."Entry No.");
        FieldChangeHistory.SetRange("Field No.", TestBuffer.FieldNo("No."));
        Assert.RecordCount(FieldChangeHistory, 1);
    end;

    [Test]
    procedure DeleteRecordsDeletesOnlyTheViewAndLogsABulkDelete()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        AuditLogEntry: Record "Audit Log Entry";
    begin
        // [GIVEN] Three records, two of them in the view
        TestBuffer.DeleteAll(false);
        ClearAuditLog();
        InsertTestBufferRecord('DEL1', 'x');
        InsertTestBufferRecord('DEL2', 'x');
        InsertTestBufferRecord('KEEP', 'x');

        // [WHEN] The records of the view are deleted without backup
        Assert.AreEqual(2, TableEditorMgt.DeleteRecords(Database::"Admin Tool Test Buffer", GetViewFor('DEL*'), false, false, false), 'Two records should be deleted.');

        // [THEN] Only those are gone and the deletion is logged
        Assert.AreEqual(1, TestBuffer.Count(), 'Only the record outside the view should remain.');
        Assert.IsTrue(TestBuffer.Get('KEEP'), 'The record outside the view must remain.');
        AuditLogEntry.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        Assert.RecordCount(AuditLogEntry, 1);
        Assert.IsTrue(AuditLogEntry.FindFirst(), 'An audit log entry should exist.');
        Assert.AreEqual(Enum::"Audit Log Operation Type"::"Bulk Delete".AsInteger(), AuditLogEntry."Operation Type".AsInteger(), 'Unexpected operation type.');
        Assert.AreEqual(2, AuditLogEntry."No. of Records Affected", 'Unexpected number of deleted records in the audit log.');
        Assert.IsFalse(AuditLogEntry."Backup Created", 'No backup was requested.');
    end;

    [Test]
    procedure DeleteRecordsWithBackupCreatesAFilteredBackupAndLinksItToTheAuditLog()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        AuditLogEntry: Record "Audit Log Entry";
        TableBackup: Record "Table Backup";
    begin
        // [GIVEN] Automatic backups with JSON Export and records, two of them in the view
        SetupAutoBackup(true, false);
        TestBuffer.DeleteAll(false);
        ClearAuditLog();
        TableBackup.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        TableBackup.DeleteAll(false);
        InsertTestBufferRecord('BAK1', 'x');
        InsertTestBufferRecord('BAK2', 'x');
        InsertTestBufferRecord('KEEP', 'x');

        // [WHEN] The records of the view are deleted with a backup
        Assert.AreEqual(2, TableEditorMgt.DeleteRecords(Database::"Admin Tool Test Buffer", GetViewFor('BAK*'), false, true, false), 'Two records should be deleted.');

        // [THEN] A backup of exactly the two records was created before the deletion
        Assert.RecordCount(TableBackup, 1);
        Assert.IsTrue(TableBackup.FindFirst(), 'A backup should exist.');
        Assert.AreEqual(Enum::"Backup Operation Type"::"Before Deletion".AsInteger(), TableBackup."Operation Type".AsInteger(), 'Unexpected operation type of the backup.');
        Assert.AreEqual(2, TableBackup."No. of Records", 'Only the records of the view should be backed up.');
        Assert.AreNotEqual('', TableBackup."Filter View", 'The filter of the view should be stored with the backup.');

        // [THEN] The audit log entry points to the backup
        AuditLogEntry.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        Assert.IsTrue(AuditLogEntry.FindFirst(), 'An audit log entry should exist.');
        Assert.IsTrue(AuditLogEntry."Backup Created", 'The audit log entry should show that a backup was created.');
        Assert.AreEqual(TableBackup."Entry No.", AuditLogEntry."Backup Entry No.", 'The audit log entry should point to the backup.');
    end;

    [Test]
    procedure DeleteRecordsErrorsForTablesOfTheAdminToolbox()
    begin
        // [WHEN/THEN] The records of a protected table cannot be deleted with the Table Editor
        asserterror TableEditorMgt.DeleteRecords(Database::"Table Backup", '', false, false, false);
        Assert.ExpectedError('belongs to the Admin Toolbox or to the system and its records cannot be deleted');
    end;

    [Test]
    procedure ModifyRenameAndCreateErrorForTablesOfTheAdminToolbox()
    begin
        // [WHEN/THEN] The records of a protected table cannot be changed with the Table Editor either
        asserterror TableEditorMgt.ModifyRecords(Database::"Audit Log Entry", '', 1, '1', false, false);
        Assert.ExpectedError('belongs to the Admin Toolbox or to the system and its records cannot be changed');

        asserterror TableEditorMgt.RenameRecords(Database::"Audit Log Entry", '', 1, '1');
        Assert.ExpectedError('belongs to the Admin Toolbox or to the system and its records cannot be changed');

        asserterror TableEditorMgt.CreateRecord(Database::"Audit Log Entry", '');
        Assert.ExpectedError('belongs to the Admin Toolbox or to the system and its records cannot be changed');
    end;

    [Test]
    procedure RenameErrorsForAFieldThatIsNotPartOfThePrimaryKey()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        // [WHEN/THEN] Rename and preview need a primary key field
        asserterror TableEditorMgt.RenameRecords(Database::"Admin Tool Test Buffer", '', TestBuffer.FieldNo(Description), 'x');
        Assert.ExpectedError('is not part of the primary key of table');

        asserterror TableEditorMgt.GetRenamePreview(Database::"Admin Tool Test Buffer", TestBuffer.FieldNo(Description), 'x');
        Assert.ExpectedError('is not part of the primary key of table');
    end;

    [Test]
    procedure CreateRecordInsertsARecordFromThePrimaryKeyFilterAndLogsIt()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        AuditLogEntry: Record "Audit Log Entry";
        View: Text;
    begin
        // [GIVEN] No records and a view with a constant value on the primary key
        TestBuffer.DeleteAll(false);
        ClearAuditLog();
        TestBuffer.SetRange("No.", 'NEW01');
        View := TestBuffer.GetView(false);

        // [WHEN] The record is created
        Assert.IsTrue(TableEditorMgt.GetCreateRecordPreview(Database::"Admin Tool Test Buffer", View).Contains('NEW01'), 'The preview should show the key value.');
        TableEditorMgt.CreateRecord(Database::"Admin Tool Test Buffer", View);

        // [THEN] The record exists and the creation is logged
        TestBuffer.Reset();
        Assert.IsTrue(TestBuffer.Get('NEW01'), 'The record should be created.');
        AuditLogEntry.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        Assert.RecordCount(AuditLogEntry, 1);
        Assert.IsTrue(AuditLogEntry.FindFirst(), 'An audit log entry should exist.');
        Assert.AreEqual(Enum::"Audit Log Operation Type"::Insert.AsInteger(), AuditLogEntry."Operation Type".AsInteger(), 'Unexpected operation type.');
        Assert.AreEqual('NEW01', AuditLogEntry."Primary Key Value", 'Unexpected primary key value in the audit log.');
    end;

    [Test]
    procedure CreateRecordErrorsWithoutAConstantPrimaryKeyFilter()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        // [WHEN/THEN] A blank view cannot be used to create a record
        TestBuffer.DeleteAll(false);
        asserterror TableEditorMgt.CreateRecord(Database::"Admin Tool Test Buffer", '');
        Assert.ExpectedError('Filter each primary key field with a constant value. Only then a new record can be created using those values.');
    end;

    [Test]
    procedure CreateRecordErrorsWhenTheRecordAlreadyExists()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        View: Text;
    begin
        // [GIVEN] A record and a view with its primary key
        TestBuffer.DeleteAll(false);
        InsertTestBufferRecord('NEW02', 'x');
        TestBuffer.SetRange("No.", 'NEW02');
        View := TestBuffer.GetView(false);

        // [WHEN/THEN] The record is not created a second time
        asserterror TableEditorMgt.CreateRecord(Database::"Admin Tool Test Buffer", View);
        Assert.ExpectedError('A record with these primary key values already exists.');
    end;

    [Test]
    procedure ConfirmBackupBeforeDeletionReturnsFalseWhenAutoBackupIsDisabled()
    begin
        // [GIVEN] Automatic backups are disabled
        SetupAutoBackup(false, false);

        // [WHEN/THEN] No backup is wanted and nothing is asked
        Assert.IsFalse(TableEditorMgt.ConfirmBackupBeforeDeletion(Database::"Admin Tool Test Buffer"), 'No backup should be created.');
    end;

    [Test]
    procedure ConfirmBackupBeforeDeletionReturnsTrueWithoutQuestionsForTablesWithSupportedFieldsOnly()
    begin
        // [GIVEN] Automatic backups without prompt and a table without unsupported field types (a question would fail the test: no Confirm handler)
        SetupAutoBackup(true, false);

        // [WHEN/THEN] A backup is wanted
        Assert.IsTrue(TableEditorMgt.ConfirmBackupBeforeDeletion(Database::"Admin Tool Test PK Target"), 'A backup should be created.');
    end;

    [Test]
    procedure CheckSuperPermissionSucceedsForASuperUser()
    begin
        // [WHEN/THEN] The user running the tests has SUPER permissions, so the Table Editor may be used
        TableEditorMgt.CheckSuperPermission();
    end;

    local procedure SetupAutoBackup(AutoBackup: Boolean; PromptForBackup: Boolean)
    var
        AdminToolboxSetup: Record "Admin Toolbox Setup";
    begin
        if not AdminToolboxSetup.Get() then begin
            AdminToolboxSetup.Init();
            AdminToolboxSetup.Insert(false);
        end;
        AdminToolboxSetup."Auto Backup Before Deletion" := AutoBackup;
        AdminToolboxSetup."Prompt for Backup" := PromptForBackup;
        AdminToolboxSetup."Auto Backup Type" := AdminToolboxSetup."Auto Backup Type"::"JSON Export";
        AdminToolboxSetup.Modify(false);
    end;

    local procedure ClearAuditLog()
    var
        AuditLogEntry: Record "Audit Log Entry";
    begin
        AuditLogEntry.SetRange("Table ID", Database::"Admin Tool Test Buffer");
        AuditLogEntry.DeleteAll(false);
    end;

    local procedure GetViewFor(NoFilter: Text): Text
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        TestBuffer.SetFilter("No.", NoFilter);
        exit(TestBuffer.GetView(false));
    end;

    local procedure GetDescription(No: Code[20]): Text
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        Assert.IsTrue(TestBuffer.Get(No), 'The record should exist.');
        exit(TestBuffer.Description);
    end;

    local procedure InsertTestBufferRecord(No: Code[20]; Description: Text[100])
    var
        TestBuffer: Record "Admin Tool Test Buffer";
    begin
        TestBuffer.Init();
        TestBuffer."No." := No;
        TestBuffer.Description := Description;
        TestBuffer.Insert(false);
    end;
}
