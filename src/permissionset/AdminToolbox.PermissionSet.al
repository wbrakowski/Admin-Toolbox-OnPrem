permissionset 51000 "Admin Toolbox"
{
    Assignable = true;
    Caption = 'Admin Toolbox', Locked = true;
    Permissions =
        // Tables
        table "Admin Toolbox Setup" = X,
        tabledata "Admin Toolbox Setup" = RIMD,
        table "Audit Log Entry" = X,
        tabledata "Audit Log Entry" = RIMD,
        table "Field Change History" = X,
        tabledata "Field Change History" = RIMD,
        table "Record Deletion" = X,
        tabledata "Record Deletion" = RIMD,
        table "Record Deletion Rel. Error" = X,
        tabledata "Record Deletion Rel. Error" = RIMD,
        table "Table Backup" = X,
        tabledata "Table Backup" = RIMD,
        table "Temp Object in License" = X,
        tabledata "Temp Object in License" = RIMD,
        table "Temp Unlicensed Object" = X,
        tabledata "Temp Unlicensed Object" = RIMD,
        // Codeunits
        codeunit "Admin Tool Mgt." = X,
        codeunit "Audit Log Mgt." = X,
        codeunit "Event Subscribers" = X,
        codeunit "Powershell Mgt." = X,
        codeunit "Table Backup Mgt." = X,
        // Pages
        page "Admin Toolbox" = X,
        page "Admin Toolbox Dashboard" = X,
        page "Admin Toolbox Setup" = X,
        page AllObj = X,
        page "Audit Log Entries" = X,
        page "Audit Log Entry Card" = X,
        page "Create Table Backup" = X,
        page "Field Change History" = X,
        page "License Information" = X,
        page "License Permissions" = X,
        page "Objects in License" = X,
        page "Record Deletion" = X,
        page "Record Deletion Rel. Error" = X,
        page "Table Backup Card" = X,
        page "Table Backup FactBox" = X,
        page "Table Backup List" = X,
        page "Table Editor" = X,
        page "Unlicensed Objects" = X,
        // Reports
        report "Export Objects in License" = X,
        report "Export Unlicensed Objects" = X;
}
