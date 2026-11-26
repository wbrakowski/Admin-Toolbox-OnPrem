namespace AdminToolbox.Test;

using AdminToolbox;
using System.TestLibraries.Utilities;

codeunit 51106 "Admin Tool Setup Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure AccessorsReturnTheDefaultsWithoutASetupRecord()
    var
        AdminToolboxSetup: Record "Admin Toolbox Setup";
    begin
        // [GIVEN] No setup record
        AdminToolboxSetup.DeleteAll(false);

        // [WHEN/THEN] The accessors return the defaults of the setup table
        Assert.AreEqual(30, AdminToolboxSetup.GetBackupRetentionDays(), 'Unexpected default backup retention.');
        Assert.AreEqual(90, AdminToolboxSetup.GetAuditLogRetentionDays(), 'Unexpected default audit log retention.');
        Assert.IsTrue(AdminToolboxSetup.GetAutoBackupBeforeDeletion(), 'Automatic backups are on by default.');
        Assert.IsTrue(AdminToolboxSetup.GetPromptForBackup(), 'The backup prompt is on by default.');
        Assert.AreEqual(Enum::"Backup Type"::"JSON Export".AsInteger(), AdminToolboxSetup.GetAutoBackupType().AsInteger(), 'JSON Export is the default backup type.');
    end;

    [Test]
    procedure AccessorsReturnTheValuesOfTheSetupRecord()
    var
        AdminToolboxSetup: Record "Admin Toolbox Setup";
    begin
        // [GIVEN] A setup record with non-default values
        AdminToolboxSetup.DeleteAll(false);
        AdminToolboxSetup.Init();
        AdminToolboxSetup."Backup Retention Days" := 7;
        AdminToolboxSetup."Audit Log Retention Days" := 0;
        AdminToolboxSetup."Auto Backup Before Deletion" := false;
        AdminToolboxSetup."Prompt for Backup" := false;
        AdminToolboxSetup."Auto Backup Type" := Enum::"Backup Type"::Snapshot;
        AdminToolboxSetup.Insert(false);

        // [WHEN/THEN] The accessors return these values
        Assert.AreEqual(7, AdminToolboxSetup.GetBackupRetentionDays(), 'Unexpected backup retention.');
        Assert.AreEqual(0, AdminToolboxSetup.GetAuditLogRetentionDays(), 'Unexpected audit log retention.');
        Assert.IsFalse(AdminToolboxSetup.GetAutoBackupBeforeDeletion(), 'Automatic backups should be off.');
        Assert.IsFalse(AdminToolboxSetup.GetPromptForBackup(), 'The backup prompt should be off.');
        Assert.AreEqual(Enum::"Backup Type"::Snapshot.AsInteger(), AdminToolboxSetup.GetAutoBackupType().AsInteger(), 'Unexpected backup type.');
    end;

    [Test]
    procedure AutoBackupTypeFallsBackToJsonExportWhenBlank()
    var
        AdminToolboxSetup: Record "Admin Toolbox Setup";
        BlankBackupType: Enum "Backup Type";
    begin
        // [GIVEN] A setup record with a blank backup type
        AdminToolboxSetup.DeleteAll(false);
        AdminToolboxSetup.Init();
        AdminToolboxSetup."Auto Backup Type" := BlankBackupType;
        AdminToolboxSetup.Insert(false);

        // [WHEN/THEN] JSON Export is used
        Assert.AreEqual(Enum::"Backup Type"::"JSON Export".AsInteger(), AdminToolboxSetup.GetAutoBackupType().AsInteger(), 'A blank backup type should fall back to JSON Export.');
    end;
}
