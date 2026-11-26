namespace AdminToolbox.Test;

using AdminToolbox;

permissionset 51100 "Admin Tool Test"
{
    Assignable = true;
    Caption = 'Admin Toolbox Tests', Locked = true;

    Permissions =
        table "Admin Tool Test Buffer" = X,
        tabledata "Admin Tool Test Buffer" = RIMD,
        table "Admin Tool Test PK Target" = X,
        tabledata "Admin Tool Test PK Target" = RIMD,
        codeunit "Admin Tool Audit Log Test" = X,
        codeunit "Admin Tool Backup Commit Test" = X,
        codeunit "Admin Tool Backup Test" = X,
        codeunit "Admin Tool Deletion Test" = X,
        codeunit "Admin Tool Page Test" = X,
        codeunit "Admin Tool Setup Test" = X,
        codeunit "Admin Tool Table Editor Test" = X;
}
