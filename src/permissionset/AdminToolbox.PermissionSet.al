permissionset 51000 "Admin Toolbox"
{
    Assignable = true;
    Caption = 'Admin Toolbox', Locked = true;

    Permissions =
        // Codeunits
        codeunit "Admin Tool Mgt." = X,
        codeunit "Event Subscribers" = X,
        codeunit "Powershell Mgt." = X,
        // Pages
        page "Admin Toolbox" = X,
        page "Admin Toolbox Setup" = X,
        page AllObj = X,
        page "License Information" = X,
        page "License Permissions" = X,
        page "Objects in License" = X,
        page "Record Deletion" = X,
        page "Record Deletion Rel. Error" = X,
        page "Table Editor" = X,
        page "Unlicensed Objects" = X,
        // Reports
        report "Export Objects in License" = X,
        report "Export Unlicensed Objects" = X,
        // Tables
        table "Admin Toolbox Setup" = X,
        tabledata "Admin Toolbox Setup" = RIMD,
        table "Record Deletion" = X,
        tabledata "Record Deletion" = RIMD,
        table "Record Deletion Rel. Error" = X,
        tabledata "Record Deletion Rel. Error" = RIMD,
        table "Temp Object in License" = X,
        tabledata "Temp Object in License" = RIMD,
        table "Temp Unlicensed Object" = X,
        tabledata "Temp Unlicensed Object" = RIMD;
}
