page 51018 "Admin Toolbox Dashboard"
{
    ApplicationArea = All;
    Caption = 'Admin Toolbox Dashboard';
    InherentEntitlements = X;
    InherentPermissions = X;
    PageType = Card;
    Permissions = tabledata "Admin Toolbox Setup" = R,
tabledata "Record Deletion" = R,
                  tabledata "Table Backup" = R;
    RefreshOnActivate = true;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            cuegroup(TableStatistics)
            {
                Caption = 'Table Statistics';
                ShowCaption = true;

                field("Tables with Data"; TablesWithData)
                {
                    Caption = 'Tables with Data';
                    StyleExpr = StatisticsStyle;
                    ToolTip = 'Specifies the number of tables that contain at least one record. Click to view all tables with data.';

                    trigger OnDrillDown()
                    var
                        RecordDeletion: Record "Record Deletion";
                    begin
                        RecordDeletion.SetFilter("No. of Records", '>0');
                        Page.Run(Page::"Record Deletion", RecordDeletion);
                    end;
                }
                field("Tables > 1000 Records"; TablesOver1000)
                {
                    Caption = 'Tables > 1,000 Records';
                    StyleExpr = Tables1000Style;
                    ToolTip = 'Specifies the number of tables that contain more than 1,000 records. Click to view these medium-sized tables.';

                    trigger OnDrillDown()
                    var
                        RecordDeletion: Record "Record Deletion";
                    begin
                        RecordDeletion.SetFilter("No. of Records", '>1000');
                        Page.Run(Page::"Record Deletion", RecordDeletion);
                    end;
                }
                field("Tables > 100000 Records"; TablesOver100000)
                {
                    Caption = 'Tables > 100,000 Records';
                    StyleExpr = Tables100000Style;
                    ToolTip = 'Specifies the number of tables that contain more than 100,000 records. Click to view these large tables.';

                    trigger OnDrillDown()
                    var
                        RecordDeletion: Record "Record Deletion";
                    begin
                        RecordDeletion.SetFilter("No. of Records", '>100000');
                        Page.Run(Page::"Record Deletion", RecordDeletion);
                    end;
                }
            }

            cuegroup(Statistics)
            {
                Caption = 'Operations Statistics';
                ShowCaption = true;

                field("Total Backups"; TotalBackups)
                {
                    Caption = 'Total Backups';
                    StyleExpr = StatisticsStyle;
                    ToolTip = 'Specifies the total number of table backups that have been created. Click to view all backups.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Table Backup List");
                    end;
                }
                field("Audit Log Entries"; AuditLogEntries)
                {
                    Caption = 'Audit Log Entries';
                    StyleExpr = StatisticsStyle;
                    ToolTip = 'Specifies the total number of audit log entries. Click to view audit logs.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Audit Log Entries");
                    end;
                }
                field("Recent Operations"; RecentOperations)
                {
                    Caption = 'Recent Operations (24h)';
                    StyleExpr = RecentStyle;
                    ToolTip = 'Specifies the number of operations performed in the last 24 hours.';

                    trigger OnDrillDown()
                    var
                        AuditLogEntry: Record "Audit Log Entry";
                    begin
                        AuditLogEntry.SetFilter("Date Time", '>=%1', CreateDateTime(Today() - 1, 0T));
                        Page.Run(Page::"Audit Log Entries", AuditLogEntry);
                    end;
                }
            }

            group(QuickInfo)
            {
                Caption = 'Quick Information';
                ShowCaption = true;

                field(LastBackupInfo; LastBackupText)
                {
                    Caption = 'Last Backup';
                    Editable = false;
                    ToolTip = 'Specifies when the last backup was created. Regular backups are recommended before any data operations.';
                }
                field(AuditStatusInfo; AuditStatusText)
                {
                    Caption = 'Audit Logging';
                    Editable = false;
                    StyleExpr = AuditStatusStyle;
                    ToolTip = 'Specifies if audit logging is enabled. When enabled, all operations are tracked for compliance and review.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenToolbox)
            {
                Caption = 'Admin Toolbox';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Specifies the main Admin Toolbox page with all available tools and operations.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Admin Toolbox");
                end;
            }
            action(Setup)
            {
                Caption = 'Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Specifies the Admin Toolbox Setup to configure automatic backups, audit logging, user mode, and retention policies.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Admin Toolbox Setup");
                end;
            }
            action(RefreshDashboard)
            {
                Caption = 'Refresh';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Specifies that all statistics and information on the dashboard will be refreshed. This will reload all data from the database.';

                trigger OnAction()
                var
                    DashboardDataRefreshedMsg: Label 'Dashboard data has been refreshed.';
                begin
                    DataLoaded := false; // Reset cache
                    UpdateDashboardData();
                    CurrPage.Update(false);
                    Message(DashboardDataRefreshedMsg);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not DataLoaded then
            UpdateDashboardData()
        else
            UpdateStyles(); // Only update styles when data is already loaded
    end;

    trigger OnAfterGetCurrRecord()
    begin
        // Only update styles, don't reload all data
        if DataLoaded then
            UpdateStyles();
    end;

    local procedure UpdateDashboardData()
    var
        AdminToolboxSetup: Record "Admin Toolbox Setup";
        AuditLogEntry: Record "Audit Log Entry";
        TableBackup: Record "Table Backup";
        ProgressDialog: Dialog;
        LoadingMsg: Label 'Loading Dashboard Data... @1@@@@@@';
    begin
        if GuiAllowed() then
            ProgressDialog.Open(LoadingMsg);

        CalculateTableStatistics(ProgressDialog);
        CalculateBackupStatistics(TableBackup);
        CalculateAuditLogStatistics(AuditLogEntry);
        UpdateQuickInfo(AdminToolboxSetup);
        UpdateLastBackupInfo(TableBackup);
        UpdateStyles();

        DataLoaded := true;

        if GuiAllowed() then
            ProgressDialog.Close();
    end;

    local procedure CalculateTableStatistics(var ProgressDialog: Dialog)
    var
        RecordDeletion: Record "Record Deletion";
        CurrRec: Integer;
        NoOfRecs: Integer;
        TableCount: Integer;
    begin
        RecordDeletion.SetLoadFields("Table ID");
        TableCount := 0;
        TablesOver1000 := 0;
        TablesOver100000 := 0;
        NoOfRecs := RecordDeletion.Count();
        CurrRec := 0;

        if RecordDeletion.FindSet() then
            repeat
                CurrRec += 1;
                UpdateProgress(ProgressDialog, CurrRec, NoOfRecs);

                RecordDeletion.CalcFields("No. of Records");
                if RecordDeletion."No. of Records" > 0 then
                    TableCount += 1;
                if RecordDeletion."No. of Records" > 1000 then
                    TablesOver1000 += 1;
                if RecordDeletion."No. of Records" > 100000 then
                    TablesOver100000 += 1;
            until RecordDeletion.Next() = 0;
        TablesWithData := TableCount;
    end;

    local procedure UpdateProgress(var ProgressDialog: Dialog; CurrRec: Integer; NoOfRecs: Integer)
    begin
        if not GuiAllowed() then
            exit;

        if NoOfRecs <= 100 then
            ProgressDialog.Update(1, (CurrRec / NoOfRecs * 10000) div 1)
        else
            if CurrRec mod (NoOfRecs div 100) = 0 then
                ProgressDialog.Update(1, (CurrRec / NoOfRecs * 10000) div 1);
    end;

    local procedure CalculateBackupStatistics(var TableBackup: Record "Table Backup")
    begin
        TableBackup.SetLoadFields("Entry No.");
        TotalBackups := TableBackup.Count();
    end;

    local procedure CalculateAuditLogStatistics(var AuditLogEntry: Record "Audit Log Entry")
    begin
        AuditLogEntry.SetLoadFields("Entry No.");
        AuditLogEntries := AuditLogEntry.Count();

        AuditLogEntry.Reset();
        AuditLogEntry.SetLoadFields("Entry No.");
        AuditLogEntry.SetFilter("Date Time", '>=%1', CreateDateTime(Today() - 1, 0T));
        RecentOperations := AuditLogEntry.Count();
    end;

    local procedure UpdateQuickInfo(var AdminToolboxSetup: Record "Admin Toolbox Setup")
    begin
        if not AdminToolboxSetup.Get() then
            AdminToolboxSetup.Init();

        AuditStatusText := 'Active ✓';
    end;

    local procedure UpdateLastBackupInfo(var TableBackup: Record "Table Backup")
    begin
        TableBackup.SetCurrentKey("Backup Date Time");
        TableBackup.Ascending(false);
        if TableBackup.FindFirst() then
            LastBackupText := Format(TableBackup."Backup Date Time", 0, '<Day,2>.<Month,2>.<Year4> <Hours24>:<Minutes,2>')
        else
            LastBackupText := 'No backups created yet';
    end;

    local procedure UpdateStyles()
    begin
        // Statistics style
        StatisticsStyle := Format(PageStyle::Standard);

        // Table size statistics
        if TablesOver1000 > 50 then
            Tables1000Style := Format(PageStyle::Ambiguous)
        else
            Tables1000Style := Format(PageStyle::Standard);

        if TablesOver100000 > 10 then
            Tables100000Style := Format(PageStyle::Attention)
        else
            if TablesOver100000 > 5 then
                Tables100000Style := Format(PageStyle::Ambiguous)
            else
                Tables100000Style := Format(PageStyle::Standard);

        // Audit Status
        if AuditStatusText.Contains('Enabled') then
            AuditStatusStyle := Format(PageStyle::Favorable)
        else
            AuditStatusStyle := Format(PageStyle::Attention);

        // Recent operations style
        if RecentOperations > 50 then
            RecentStyle := Format(PageStyle::Attention)
        else
            if RecentOperations > 10 then
                RecentStyle := Format(PageStyle::Ambiguous)
            else
                RecentStyle := Format(PageStyle::Favorable);
    end;

    var

        // Caching
        DataLoaded: Boolean;
        AuditLogEntries: Integer;
        RecentOperations: Integer;
        TablesOver1000: Integer;
        TablesOver100000: Integer;
        // Statistics
        TablesWithData: Integer;
        TotalBackups: Integer;
        AuditStatusStyle: Text;
        AuditStatusText: Text;

        // Quick Info
        LastBackupText: Text;
        RecentStyle: Text;

        // Styles
        StatisticsStyle: Text;
        Tables1000Style: Text;
        Tables100000Style: Text;
}
