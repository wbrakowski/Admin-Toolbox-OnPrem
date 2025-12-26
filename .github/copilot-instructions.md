# Admin-Toolbox-OnPrem AI Coding Agent Instructions

## Project Overview

**Admin-Toolbox** is a Business Central OnPrem extension providing powerful administrative tools for database management, license administration, backup/restore operations, and audit logging. This is NOT a SaaS app - it's specifically designed for OnPrem environments because it uses DotNet for PowerShell integration and accesses license information only available OnPrem.

**Critical**: This app handles destructive operations (delete/modify records). All changes must maintain safety features: automatic backups, audit logging, and user confirmations.

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

- **Translations folder**: Contains `.xlf` files for German (de-DE) and Spanish (es-ES)
- **Generated file**: `Admin-Toolbox.g.xlf` is auto-generated during compilation (often in .gitignore)
- **app.json** includes `"features": ["TranslationFile"]`
- All user-facing text must have proper Labels with Comment parameters explaining placeholders

## PowerShell Runner Setup

**Critical for OnPrem functionality**: The correct PowerShell Runner DLL must be in `.netpackages` folder:
- Version-specific DLLs in `powershellrunners/` folder (15-20_Microsoft.Dynamics.Nav.PowerShellRunner.dll)
- Copy appropriate version to `.netpackages/Microsoft.Dynamics.Nav.PowerShellRunner.dll`
- Referenced in `dotnet.al` with conditional compilation

## Permission & Security

- **SUPER permission required**: All pages check for SUPER permissions
- **TableData permissions**: AdminToolMgt declares explicit IMD permissions for common BC tables
- Entry point checks: `UserPermissions.IsSuper(UserSecurityId())` before sensitive operations

## ID Ranges & Object Naming

- **ID Range**: 51000-51099 (defined in app.json)
- **Object prefixes**: "Admin Toolbox" or "Admin Tool"
- **Enum pattern**: Value 0 reserved for blank/unassigned (see BackupType enum)

## Development Workflow

### Building & Testing
```powershell
# Compile the app in VS Code with AL Language extension
# Publish to BC server
Publish-NAVApp -ServerInstance YourServerInstance -Path "path\to\app.app" -SkipVerification

# Install on company
Install-NAVApp -ServerInstance YourServerInstance -Name "Admin-Toolbox"
```

### Before Committing
1. **Compile**: Project must compile without errors
2. **Business Linter**: Address all warnings in changed/new code
3. **Test destructive operations**: Verify backup/restore and audit logging work
4. **Translation check**: Update .xlf files if adding user-facing text

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

## Key Files Reference

- `src/codeunit/AdminToolMgt.Codeunit.al` - Core business logic and table operations
- `src/codeunit/AuditLogMgt.Codeunit.al` - Audit logging patterns
- `src/codeunit/TableBackupMgt.Codeunit.al` - Backup strategy implementation
- `src/page/AdminToolbox.Page.al` - Main UI entry point with guided tour
- `src/page/TableEditor.Page.al` - Dynamic record editing example
- `src/table/AdminToolboxSetup.Table.al` - Configuration singleton pattern
- `dotnet.al` - DotNet assembly declarations with OnPrem conditionals

## Testing Approach

Since this handles production data:
1. **Always test in dev/test environment first**
2. **Verify backup creation** before destructive operations
3. **Check audit log entries** after operations
4. **Test restore functionality** from backups
5. **Validate table relations** before bulk deletions
