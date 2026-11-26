namespace AdminToolbox;

table 51000 "Admin Toolbox Setup"
{
    Caption = 'Admin Toolbox Setup';
    DataClassification = CustomerContent;
    Permissions = tabledata "Admin Toolbox Setup" = r;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
            NotBlank = true;
        }
        field(10; "Developer License Warning"; Boolean)
        {
            Caption = 'Developer License Warning';
            ToolTip = 'Specifies if a warning should be shown on opening the company when a developer license is active (only OnPrem).';
        }
        field(20; "Auto Backup Before Deletion"; Boolean)
        {
            Caption = 'Auto Backup Before Deletion';
            InitValue = true;
            ToolTip = 'Specifies if a backup should automatically be created before deleting records.';
        }
        field(21; "Prompt for Backup"; Boolean)
        {
            Caption = 'Prompt for Backup';
            InitValue = true;
            ToolTip = 'Specifies if the user should be asked before creating a backup when deleting records. If disabled, backups are created automatically without asking (if Auto Backup Before Deletion is enabled).';
        }
        field(22; "Auto Backup Type"; Enum "Backup Type")
        {
            Caption = 'Auto Backup Type';
            InitValue = "JSON Export";
            ToolTip = 'Specifies the type of backup to create automatically.';
        }
        field(23; "Backup Retention Days"; Integer)
        {
            Caption = 'Backup Retention Days';
            InitValue = 30;
            MinValue = 1;
            ToolTip = 'Specifies how many days to keep backups before they can be automatically deleted.';
        }
        field(24; "Audit Log Retention Days"; Integer)
        {
            Caption = 'Audit Log Retention Days';
            InitValue = 90;
            MinValue = 0;
            ToolTip = 'Specifies how many days to keep audit log entries before they can be automatically deleted. Set to 0 to keep audit logs indefinitely.';
        }
        field(33; "Enable Inline Documentation"; Boolean)
        {
            Caption = 'Enable Inline Documentation';
            InitValue = true;
            ToolTip = 'Specifies if inline documentation and help texts should be shown within pages. Provides context-sensitive guidance.';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetBackupRetentionDays(): Integer
    begin
        if not Get() then
            exit(30);
        exit("Backup Retention Days");
    end;

    procedure GetAutoBackupBeforeDeletion(): Boolean
    begin
        if not Get() then
            exit(true);
        exit("Auto Backup Before Deletion");
    end;

    procedure GetPromptForBackup(): Boolean
    begin
        if not Get() then
            exit(true);
        exit("Prompt for Backup");
    end;

    // A blank backup type in the setup falls back to JSON Export
    procedure GetAutoBackupType(): Enum "Backup Type"
    var
        BackupType: Enum "Backup Type";
    begin
        if not Get() then
            exit(BackupType::"JSON Export");
        if "Auto Backup Type".AsInteger() = 0 then
            exit(BackupType::"JSON Export");
        exit("Auto Backup Type");
    end;

    procedure GetAuditLogRetentionDays(): Integer
    begin
        if not Get() then
            exit(90);
        exit("Audit Log Retention Days");
    end;
}
