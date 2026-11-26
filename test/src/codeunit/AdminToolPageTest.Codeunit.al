namespace AdminToolbox.Test;

using AdminToolbox;
using System.TestLibraries.Utilities;

codeunit 51103 "Admin Tool Page Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure SetupPageCreatesSetupWithDefaultValuesOnOpen()
    var
        AdminToolboxSetup: Record "Admin Toolbox Setup";
        AdminToolboxSetupPage: TestPage "Admin Toolbox Setup";
    begin
        // [GIVEN] No setup record exists
        AdminToolboxSetup.DeleteAll(false);

        // [WHEN] The setup page is opened
        AdminToolboxSetupPage.OpenEdit();

        // [THEN] The setup record is created with the default retention values
        Assert.IsTrue(AdminToolboxSetup.Get(), 'The setup record should be created when the page opens.');
        Assert.AreEqual(30, AdminToolboxSetupPage."Backup Retention Days".AsInteger(), 'Unexpected default backup retention.');
        Assert.AreEqual(90, AdminToolboxSetupPage."Audit Log Retention Days".AsInteger(), 'Unexpected default audit log retention.');
        AdminToolboxSetupPage.Close();
    end;

    [Test]
    procedure AuditLogEntriesPageShowsLoggedOperation()
    var
        AuditLogMgt: Codeunit "Audit Log Mgt.";
        AuditLogEntries: TestPage "Audit Log Entries";
        EntryNo: Integer;
    begin
        // [GIVEN] A logged operation
        EntryNo := AuditLogMgt.StartOperation(Enum::"Audit Log Operation Type"::Delete, Database::"Admin Tool Test Buffer", 'Shown on the page', 'Page Test');

        // [WHEN] The audit log list is opened and positioned on the entry
        AuditLogEntries.OpenView();
        AuditLogEntries.GoToKey(EntryNo);

        // [THEN] The entry is shown with its data
        Assert.AreEqual('Shown on the page', AuditLogEntries.Description.Value(), 'Unexpected description on the page.');
        Assert.AreEqual('Page Test', AuditLogEntries."Triggered By".Value(), 'Unexpected triggered by on the page.');
        AuditLogEntries.Close();
    end;

    [Test]
    procedure TableBackupListShowsBackup()
    var
        TestBuffer: Record "Admin Tool Test Buffer";
        TableBackupMgt: Codeunit "Table Backup Mgt.";
        TableBackupList: TestPage "Table Backup List";
        EntryNo: Integer;
    begin
        // [GIVEN] A backup of the test table
        TestBuffer.DeleteAll(false);
        TestBuffer.Init();
        TestBuffer."No." := 'PG01';
        TestBuffer.Insert(false);
        EntryNo := TableBackupMgt.CreateBackup(Database::"Admin Tool Test Buffer", Enum::"Backup Type"::"JSON Export", Enum::"Backup Operation Type"::"Manual Backup", 'Shown in the backup list', false);

        // [WHEN] The backup list is opened and positioned on the entry
        TableBackupList.OpenView();
        TableBackupList.GoToKey(EntryNo);

        // [THEN] The backup is shown with its data
        Assert.AreEqual('Shown in the backup list', TableBackupList.Description.Value(), 'Unexpected description on the page.');
        Assert.AreEqual(1, TableBackupList."No. of Records".AsInteger(), 'Unexpected number of records on the page.');
        TableBackupList.Close();
    end;

    [Test]
    procedure DashboardPageOpens()
    var
        AdminToolboxDashboard: TestPage "Admin Toolbox Dashboard";
    begin
        // [WHEN/THEN] The dashboard calculates its statistics and opens without an error
        AdminToolboxDashboard.OpenView();
        AdminToolboxDashboard.Close();
    end;

    [Test]
    procedure TableEditorPageOpensForSuperUser()
    var
        TableEditor: TestPage "Table Editor";
    begin
        // [WHEN/THEN] The user running the tests has SUPER permissions, so the Table Editor opens
        TableEditor.OpenEdit();
        TableEditor.Close();
    end;
}
