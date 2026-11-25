# Admin-Toolbox-OnPrem AI Coding Agent Instructions

## Project Overview

**Admin-Toolbox** is a Business Central OnPrem extension (BC 29, platform/application 29.0.0.0, runtime 18.0) providing powerful administrative tools for database management, license administration, backup/restore operations, and audit logging. This is NOT a SaaS app - it's specifically designed for OnPrem environments because it uses DotNet for PowerShell integration and accesses license information only available OnPrem.

**Critical**: This app handles destructive operations (delete/modify records). All changes must maintain safety features: automatic backups, audit logging, and user confirmations.

## Repository Layout

- **`app/`**: the main app (`app/app.json`, `app/src/...`, `app/Translations/`, `app/.netpackages/`), ID range 51000-51099, no namespaces. `internalsVisibleTo` lists the test app.
- **`test/`**: the separate AL test app "Admin-Toolbox Tests" (`test/app.json`, `test/src/...`), ID range 51100-51149, target OnPrem, depends on `app` and Microsoft's `Library Assert`.
- Both are sibling folders (neither is nested in the other), otherwise the AL compiler merges the test files into the main app project.
- Open both together via **`AdminTool.code-workspace`** (multi-root). The repository root is only a documentation/config folder in that workspace, it has no `app.json`.
- `powershellrunners/` holds the PowerShell Runner DLLs per BC version; the one used for compilation is copied to `app/.netpackages/` (`app/.vscode/settings.json` sets `al.assemblyProbingPaths`).
- A release copy of the compiled app (`Waldemar Brakowski_Admin-Toolbox_<version>.app`) is kept in the repository root. Replace it with the new build when the version changes. `app/*.app` and `test/*.app` are ignored.

## Architecture & Key Components

### Core Management Codeunits
- **AdminToolMgt (51000)**: Central business logic for record deletion, table relation validation, record counting
- **AuditLogMgt (51004)**: Comprehensive audit trail with field-level change tracking
- **TableBackupMgt (51003)**: Multi-strategy backup system (JSON Export, Snapshot, Full Backup)
- **PowershellMgt (51001)**: DotNet interop for license import using PowerShell Runner
- **EventSubscribers (51002)**: Developer license warnings on company open

### Data Flow Pattern
1. **User Action** → Page validates input
2. **Pre-Operation** → Backup created (if enabled in setup), Audit log entry started
3. **Operation** → RecordRef/FieldRef manipulation for dynamic table operations
4. **Post-Operation** → Audit log completed with field changes, notification to user
5. **Dashboard** → Shows aggregated activity and recent operations

### OnPrem-Specific Features
All license management features are conditionally compiled using `#if OnPrem` preprocessor directives. The app.json includes `"preprocessorSymbols": ["OnPrem"]` and `"target": "OnPrem"`.

**Pattern**: Wrap OnPrem-only code in preprocessor blocks:
```al
#if OnPrem
    // License import, DotNet PowerShell calls, etc.
#endif
```

## Critical Development Patterns

### RecordRef/FieldRef Dynamic Table Operations
The app heavily uses RecordRef and FieldRef for dynamic table manipulation since users can select any table. **Always use parentheses for built-in methods** (AL convention):

```al
// Correct pattern used throughout the codebase
RecordRef.Open(TableID);
for i := 1 to RecordRef.FieldCount() do begin
    FieldRef := RecordRef.FieldIndex(i);
    FieldValue := Format(FieldRef.Value());
    FieldName := FieldRef.Name();
end;
RecordRef.Close();
```

### Audit Logging Pattern
Every data modification must create an audit trail. Example from TableEditor:

```al
// 1. Start operation
AuditLogEntryNo := AuditLogMgt.StartOperation(
    AuditLogOperationType::Modify, 
    TableNo, 
    'Record modification', 
    'Table Editor'
);

// 2. Track field changes
AuditLogMgt.LogFieldChanges(AuditLogEntryNo, OldRecRef, NewRecRef);

// 3. Complete operation
AuditLogMgt.CompleteOperation(
    AuditLogEntryNo, 
    AuditLogStatus::Success, 
    NoOfRecordsAffected, 
    NoOfRecordsFailed, 
    ErrorMessage
);
```

### Backup Strategy Pattern
Three backup types with different use cases:
- **JSON Export**: Portable, cross-version, human-readable (default)
- **Snapshot**: Fast, table structure copy with all data
- **Full Backup**: Complete with metadata preservation

```al
// Always check setup before deletion operations
if AdminToolboxSetup."Auto Backup Before Deletion" then begin
    BackupEntryNo := TableBackupMgt.CreateBackup(
        TableID, 
        AdminToolboxSetup."Auto Backup Type",
        BackupOperationType::"Record Deletion",
        'Auto backup before deletion'
    );
end;
```

### Early Exit Pattern
The codebase consistently uses guard clauses to avoid nesting:

```al
// Standard pattern from AdminToolMgt
procedure CheckTableRelations()
begin
    if not ConfirmManagement.GetResponseOrDefault(CheckRelationsQst, false) then
        exit;
    
    if not RecordDeletion.FindSet() then
        exit;
    
    // Main logic without nesting
    repeat
        CheckTableRelationsForTable(RecordDeletion."Table ID");
    until RecordDeletion.Next() = 0;
end;
```

## Translation & Localization

- **Translations folder**: `app/Translations` contains `.xlf` files for German (de-DE) and Spanish (es-ES)
- **Generated file**: `Admin-Toolbox.g.xlf` is generated on every compilation and IS tracked in git, commit it together with the code. After moving or renaming a Label into another procedure its translation unit gets a new ID: carry the translation over to the new ID in both language files and delete the stale unit (LC0091 warns about missing translations)
- **app.json** includes `"features": ["TranslationFile"]`
- All user-facing text must have proper Labels with Comment parameters explaining placeholders

## PowerShell Runner Setup

**Critical for OnPrem functionality**: The correct PowerShell Runner DLL must be in `app/.netpackages`:
- Version-specific DLLs in `powershellrunners/` folder (15-20 and 29 `_Microsoft.Dynamics.Nav.PowerShellRunner.dll`)
- Copy the DLL matching the BC version to `app/.netpackages/` (currently `29_Microsoft.Dynamics.Nav.PowerShellRunner.dll`, taken from the BC 29 container); keep only one DLL there
- Referenced in `app/src/dotnet.al` with conditional compilation
- The test app needs no DLL (it does not use the DotNet type)

## Permission & Security

- **SUPER permission required**: All pages check for SUPER permissions
- **TableData permissions**: AdminToolMgt declares explicit IMD permissions for common BC tables
- Entry point checks: `UserPermissions.IsSuper(UserSecurityId())` before sensitive operations

## ID Ranges & Object Naming

- **ID Range**: 51000-51099 for the app, 51100-51149 for the test app (defined in the respective `app.json`)
- **Object prefixes**: "Admin Toolbox" or "Admin Tool"
- **Enum pattern**: Value 0 reserved for blank/unassigned (see BackupType enum)

## Development Workflow

### Mandatory Workflow for Every Change
1. **New branch first**: never change code on `main`. Create `feature/<short-name>` or `fix/<short-name>` from the up-to-date `main` before the first edit.
2. **Implement** the change in `app/` following the rules in this file.
3. **Tests are part of the change**: add or update automated tests in `test/` for every new or changed function (see "Automated Testing"). Changes without tests are not finished.
4. **Build and run the tests in the local container `bc29`** (BC 29) until all tests pass: build `app` and `test` with all analyzers (CodeCop, UICop, ApplicationCop, FormattingCop, LinterCop, TestAutomationCop), publish `app` first and then `test`, run all tests. A failing test is either a bug in the code (fix the code, keep the test) or a wrong test (fix the test); never delete or weaken a test just to get green.
5. **Pull request to `main`**: when all tests pass, commit, push the branch and create the pull request.
6. **Merge with a merge commit** (no squash, no rebase), then delete the feature branch locally and on the remote and build once more on the updated `main`.
7. Update this file and the README when structure, versions, conventions or features changed.

### Building & Testing in the Container
- Container: `bc29` (BC 29, Docker, instance `BC`, tenant `default`, user/password authentication). Start it if it is stopped. The Docker CLI needs `$env:DOCKER_HOST = 'npipe:////./pipe/docker_engine_windows'` in the session.
- Symbols: copy or download the BC 29 symbols into `app/.alpackages` and `test/.alpackages` (the test app additionally needs `Library Assert`). Before building `test`, put the freshly built app into `test/.alpackages`.
- Build with the AL extension (`al_build`) or with `alc.dll` directly (needs the .NET 10 runtime of the VS Code dotnet extension, pass the analyzers including `ALCops.Common.dll`, and `/assemblyprobingpaths:app\.netpackages` for the app).
- Publish through the development endpoint: `Publish-BcContainerApp -containerName bc29 -appFile <app> -useDevEndpoint -credential $cred -syncMode ForceSync -skipVerification` (server-side publishing fails because of the symbols of the development apps).
- Run the tests: `Run-TestsInBcContainer -containerName bc29 -credential $cred -extensionId <test app id> -detailed -usePublicWebBaseUrl` (the certificate does not match `localhost`). The output is written to the host, capture it with `Start-Transcript`. Test app id: `0453c3a7-6761-4154-908d-6c3322716a41`.
- Other apps are installed in `bc29` (e.g. Record-Deletion-Tool with similar object names in a namespace): that is no conflict, the objects differ in ID range and namespace.
- Outside the container, use `Publish-NAVApp` / `Install-NAVApp` as described in the README.

### Before Committing
1. **Compile**: both projects must compile without errors
2. **Business Linter**: Address all warnings in changed/new code (pre-existing warnings in untouched code may stay)
3. **All tests pass** in `bc29`, including the new ones
4. **Translation check**: Update the .xlf files if adding or moving user-facing text, commit the regenerated `Admin-Toolbox.g.xlf`
5. **Release copy**: when the version changed, replace `Waldemar Brakowski_Admin-Toolbox_<version>.app` in the repository root

## Code Quality Rules (Business Linter)

All new/modified code must address these warnings:
- **LC0001**: No empty procedures without comments
- **LC0036**: ToolTip must start with "Specifies"
- **LC0045**: Enum value 0 reserved for Empty Value
- **LC0050**: Fields need DataClassification
- **LC0077**: Always use parentheses for built-in methods (RecRef.Number(), FieldRef.Value())

## Dashboard & Reporting

The **Admin Toolbox Dashboard** page aggregates:
- Total backups and recent operations (last 24h)
- Last backup timestamp
- Audit logging status
- Quick links to detailed logs

Pattern: Use fact boxes and cues to surface critical information without drilling down.

## Common Pitfalls

1. **Forgetting audit logs**: Every modify/delete operation needs audit trail
2. **Missing backup confirmation**: Check setup before destructive operations
3. **OnPrem guard missing**: Don't expose license features in SaaS environments
4. **RecordRef not closed**: Always close RecordRef after use to avoid locks
5. **Missing parentheses**: Built-in methods require `()` even with no parameters
6. **Deep nesting**: Use early exits instead of nested if-then-else
7. **Generic field names**: Don't use company-specific prefixes
8. **No tests**: every new or changed function needs an automated test in `test/`
9. **Culture-dependent backup values**: never store values with plain `Format(...)`, see "Backup Format"
10. **Empty GUID as relation value**: an empty GUID is formatted as `00000000-...`, compare with `IsNullGuid()`, not with `''`

## Backup Format (`TableBackupMgt`)

- A backup is a JSON array with one object per record, stored in the Blob field `Backup Data`. All three backup types (JSON Export, Snapshot, Full Backup) use the same JSON; Snapshot only reserves a `Snapshot Table ID`.
- Only field types with a safe text representation are exported (`IsFieldTypeSupportedForBackup`): Integer, BigInteger, Decimal, Boolean, Date, Time, DateTime, GUID, Option/Enum, Text, Code, Duration, DateFormula. Blob, Media, MediaSet, RecordID and other types are skipped on backup and restore.
- Text and Code are written verbatim. Every other value is written culture-independent with `Format(Value, 0, 9)` (decimal with dot, date as `yyyy-MM-dd`, option and enum as ordinal). A closing date is written as `C` plus the normal date (`C2026-12-31`), because Format 9 drops the closing date flag.
- Restore parses with `Evaluate(..., 9)` first and falls back to the plain `Evaluate` for backups from before the culture-independent format. Known limitation: a legacy decimal such as `1.234` (meaning 1234 in a German session) is valid Format 9 and is read as 1.234; legacy option captions are not restored.
- Restore inserts record by record with `Insert(true)`; records that already exist count as failed, the restore carries on and reports a partial result.

## Key Files Reference

- `app/src/codeunit/AdminToolMgt.Codeunit.al` - Core business logic and table operations
- `app/src/codeunit/AuditLogMgt.Codeunit.al` - Audit logging patterns
- `app/src/codeunit/TableBackupMgt.Codeunit.al` - Backup strategy implementation
- `app/src/page/AdminToolbox.Page.al` - Main UI entry point with guided tour
- `app/src/page/TableEditor.Page.al` - Dynamic record editing example
- `app/src/table/AdminToolboxSetup.Table.al` - Configuration singleton pattern
- `app/src/dotnet.al` - DotNet assembly declarations with OnPrem conditionals
- `app/app.json` - Platform 29.0, runtime 18.0, target OnPrem, `internalsVisibleTo` the test app
- `test/src/codeunit/AdminTool*Test.Codeunit.al` - the automated tests (see below)
- `test/src/table/AdminToolTestBuffer.Table.al` - dummy table used by the tests (all field types)

## Automated Testing (AL Test Toolkit)

Tests live in the separate app under `test/` (IDs 51100-51149, target OnPrem, depends on `app` and `Library Assert`). Run them in the container `bc29` as described in the workflow above. The test codeunits use `Subtype = Test;` and `TestPermissions = Disabled;`.

| Codeunit | Content |
|---|---|
| 51100 `Admin Tool Backup Test` | all backup types, filtered backups, round trips for every supported field type (incl. enum, option, duration, date formula, closing date, Media field), culture-independent storage, legacy values, invalid/empty JSON, existing records on restore, view backup data, snapshot IDs |
| 51101 `Admin Tool Deletion Test` | `SetSuggestedTable`, `ClearRecordsToDelete`, `CalcRecordsInTable`, `GetTableCaption`, relation check (record, primary key, primary key name with special characters, GUID, standard tables related to system tables), `PerformDeletion` incl. audit log, `CreateBackupsBeforeDeletion` |
| 51102 `Admin Tool Audit Log Test` | start/complete operation, single record operation, field changes, backup link, cleanup of old entries incl. field change history |
| 51103 `Admin Tool Page Test` | setup page, audit log list, backup list, dashboard (TestPage) |
| 51104 `Admin Tool Backup Commit Test` | the two tests that need a `Commit()` (kept in a codeunit of their own) |

### Test conventions
- **`internal` test hooks**: public entry points hidden behind a dialog (`StrMenu`, confirm) are not called by tests. The core procedure is `internal` instead, with `internalsVisibleTo` in `app/app.json`: `TableBackupMgt.RestoreFromJSON`, `AdminToolMgt.CheckTableRelationsForTable`, `AdminToolMgt.PerformDeletion`, `AdminToolMgt.CreateBackupsBeforeDeletion`. Add a one-line comment why a procedure is `internal`.
- **The test runner rolls back per codeunit, not per test function.** Data of one test stays visible to the following tests of the same codeunit. Every test therefore starts by deleting what it depends on (e.g. `TestBuffer.DeleteAll(false)`) and must not depend on the order of the tests.
- **Safety guard for destructive procedures**: procedures that loop over flagged tables must only ever see the test table. Tests pass a `Record "Record Deletion"` filtered to the test table and assert `RecordCount = 1` first (`FlagOnlyTestBufferForDeletion`). `PerformDeletion` additionally sets the filter `Delete Records = true` itself. The audit log cleanup test aborts if real entries older than the cutoff exist.
- **UI in tests**: `Message` needs a `[MessageHandler]` (`[HandlerFunctions('MessageHandler')]` on the test), otherwise the test fails with "Unhandled UI: Message". A handler that is declared but not triggered also fails the test. `Dialog` variables passed to `PerformDeletion` must be opened in the test (`UpdateDialog.Open(...)`).
- **`asserterror` always with `Assert.ExpectedError`**. Error texts are English, so the tests assume an English session language.
- **`Commit()`**: CalcFields on a Blob field only sees committed rows. A test that calls `Commit()` needs `[TransactionModel(TransactionModel::AutoCommit)]`, cleans up its own rows and lives in `Admin Tool Backup Commit Test`, because the commit would also commit everything earlier tests of the codeunit left behind.
- New tests use the dummy tables `Admin Tool Test Buffer` / `Admin Tool Test PK Target` instead of real business tables. New test objects go into the permission set `Admin Tool Test`.
- Defects found by failing tests and fixed: empty GUID fields were reported as missing records, a filter error for primary key names with special characters (`( ) &`), closing dates were restored as normal dates. Fixed proactively after the `Record-Deletion-Tool`: culture-dependent backup values, Blob/Media/RecordID fields breaking a restore, a duplicate result message after restore.

### Deliberately NOT covered (discuss before adding tests for these)
- `InsertUpdateTables()`, `SuggestRecordsToDelete()` and the `Suggest...Tables` helpers: they scan every table of the environment or a long hard-coded list.
- `DeleteRecords()`, `CheckTableRelations()`, `RestoreBackup()`: thin dialog (`StrMenu`/confirm) wrappers around the tested building blocks.
- `IsDeveloperLicense`, `ShowDevLicenseMessageIfNeeded`, `SuggestUnlicensedPartnerOrCustomRecordsToDelete`, `IsRecordInLicense`, the license pages and the two license export reports: depend on the license installed in the environment.
- `PowershellMgt.ImportLicense`: needs the PowerShell Runner, a file upload and a server instance.
- `ExportBackupToFile`, `ImportBackupFromFile`, `ViewRecords`, `OpenTable`, `PublishApp`, `OpenReadme`: client file transfer and hyperlinks. Only the "no backup data" error guards are tested.
- The `Table Editor` page (`ModifyTableRecords`, `RenameTableRecords`, `DeleteTableRecords`, `CreateRecord`): the logic lives in the page behind `Confirm` dialogs and cannot be reached by tests. Moving it into a codeunit is a planned improvement.
- `FilterPageBuilder` dialogs on the pages.

## Testing Approach for Manual Checks

Since this handles production data:
1. **Always test in dev/test environment first**
2. **Verify backup creation** before destructive operations
3. **Check audit log entries** after operations
4. **Test restore functionality** from backups
5. **Validate table relations** before bulk deletions
