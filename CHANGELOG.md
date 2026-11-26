# Changelog

All notable changes to the Admin Toolbox are documented in this file. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [29.0.0.0] - 2026-11-26

Release for Business Central 29 (platform 29.0, runtime 18.0).

### Added

- Automated test app `Admin-Toolbox Tests` (object IDs 51100 to 51149) with tests for backup and restore, record deletion, the table relation check, the audit log, the Table Editor logic, the setup and the main pages.
- Table Editor logic in its own codeunit `Table Editor Mgt.`. It checks the SUPER permission set, writes the audit log and can create a backup before records are deleted.
- Protection of the tables of the Admin Toolbox and of system tables. They cannot be deleted or changed by the record deletion or the Table Editor.
- Audit log entry for every table whose records are deleted by the record deletion.
- Filter dialog for the filter view of a backup. The backup of a table with field types that cannot be backed up (BLOB, Media, RecordID) requires a confirmation.
- Streaming JSON export of backups, which writes record by record instead of holding the whole table in memory.
- Table relation check that shows table name and percentage in the progress dialog.
- Changelog file `CHANGELOG.md`.

### Changed

- The table relation check follows the logic of the Record-Deletion-Tool. The field metadata is read once per table, the related table is opened once per field, and relations to system tables and to tables that cannot be opened are skipped.
- The dashboard reads the record counts with one query on the table information instead of one lookup per table. Opening the dashboard takes seconds instead of minutes on databases with many tables.
- Messages, confirmations, dialog texts and error messages are reworded for consistent and clearer wording, and typos are corrected. The German and Spanish translations are updated.
- The retention days of the setup are used by **Delete Old Backups** and **Delete Old Entries**.
- All objects are in the namespace `AdminToolbox`, including the DotNet declaration for the PowerShell Runner.
- The permissions of the dashboard no longer contain the unused table `Record Deletion`.
- The README names the source of the PowerShell Runner assembly for each Business Central version.
- The README is rewritten and all screenshots are renewed. The documentation of the backup types and the table relation check describes the actual behavior.
- The field **Compression Enabled** of the setup is obsolete and not used.

### Fixed

- Backup and restore store values independent of the language and region settings. Closing dates, durations, date formulas and options are restored correctly.
- Fields of type Blob, Media and RecordID are skipped during backup and restore instead of breaking the restore.
- The restore shows its result message once.
- The table relation check no longer reports empty GUID fields as missing records.
- The table relation check no longer fails for tables whose primary key name contains special characters such as parentheses or an ampersand.
- The corrupted symbol in the welcome text of the Admin Toolbox page is replaced.

## Earlier releases

- Table backup and restore with the backup types JSON Export, Snapshot and Full Backup.
- Audit log with field level change history.
- Admin Toolbox Dashboard.
- Table Editor with rename function and audit log integration.
- Automatic backups before deletion, which can be configured.
- Admin Toolbox Setup page with retention settings.
- Languages English, German and Spanish.
