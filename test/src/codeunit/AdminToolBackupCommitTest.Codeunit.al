codeunit 51104 "Admin Tool Backup Commit Test"
{
    // These tests need a Commit (CalcFields on a Blob field only sees committed rows). A Commit also
    // commits everything earlier tests of the same codeunit left behind, so they live in a codeunit of their own.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TableBackupMgt: Codeunit "Table Backup Mgt.";

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ViewBackupDataErrorsWhenNoBackupDataExists()
    var
        TableBackup: Record "Table Backup";
    begin
        // [GIVEN] A backup entry without any backup data
        TableBackup.Init();
        TableBackup."Table ID" := Database::"Admin Tool Test Buffer";
        TableBackup.Insert(true);
        // CalcFields on a Blob field requires the row to be committed, not just visible in this transaction
        Commit();

        // [WHEN/THEN] Viewing the backup data raises the specific "no backup data" error
        asserterror TableBackupMgt.ViewBackupData(TableBackup);
        Assert.ExpectedError('No backup data found for this entry.');

        TableBackup.Delete(false);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ExportBackupToFileErrorsWhenNoBackupDataExists()
    var
        TableBackup: Record "Table Backup";
    begin
        // [GIVEN] A backup entry without any backup data
        TableBackup.Init();
        TableBackup."Table ID" := Database::"Admin Tool Test Buffer";
        TableBackup.Insert(true);
        // CalcFields on a Blob field requires the row to be committed, not just visible in this transaction
        Commit();

        // [WHEN/THEN] Exporting to file raises the specific "no backup data" error (the real client download is not exercised in automated tests)
        asserterror TableBackupMgt.ExportBackupToFile(TableBackup);
        Assert.ExpectedError('No backup data found for this entry.');

        TableBackup.Delete(false);
    end;
}
