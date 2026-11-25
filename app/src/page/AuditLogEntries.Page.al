page 51015 "Audit Log Entries"
{
    ApplicationArea = All;
    Caption = 'Audit Log Entries';
    CardPageId = "Audit Log Entry Card";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Audit Log Entry";
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(Entries)
            {
                field("Entry No."; Rec."Entry No.")
                {
                }
                field("Date Time"; Rec."Date Time")
                {
                    StyleExpr = DateTimeStyle;
                }
                field("Operation Type"; Rec."Operation Type")
                {
                    StyleExpr = OperationStyle;
                }
                field("Table ID"; Rec."Table ID")
                {
                }
                field("Table Name"; Rec."Table Name")
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyle;
                }
                field("No. of Records Affected"; Rec."No. of Records Affected")
                {
                    StyleExpr = AffectedRecordsStyle;
                }
                field("No. of Records Failed"; Rec."No. of Records Failed")
                {
                    StyleExpr = FailedRecordsStyle;
                }
                field("No. of Fields Changed"; Rec."No. of Fields Changed")
                {
                }
                field("Backup Created"; Rec."Backup Created")
                {
                }
                field("Duration (ms)"; Rec."Duration (ms)")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Triggered By"; Rec."Triggered By")
                {
                }
            }
        }
        area(FactBoxes)
        {
            part(FieldChanges; "Field Change History")
            {
                Caption = 'Field Changes';
                SubPageLink = "Audit Log Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewFieldChanges)
            {
                Caption = 'View Field Changes';
                Image = Change;
                ToolTip = 'Specifies that all field changes for this audit log entry will be shown.';

                trigger OnAction()
                begin
                    Rec.ViewFieldChanges();
                end;
            }
            action(ViewBackup)
            {
                Caption = 'View Related Backup';
                Enabled = Rec."Backup Created";
                Image = Archive;
                ToolTip = 'Specifies that the backup created before this operation will be opened.';

                trigger OnAction()
                begin
                    Rec.ViewRelatedBackup();
                end;
            }
            action(ExportToExcel)
            {
                Caption = 'Export to Excel';
                Image = ExportToExcel;
                ToolTip = 'Exports the audit log entries to Excel.';

                trigger OnAction()
                var
                    AuditLogEntry: Record "Audit Log Entry";
                begin
                    AuditLogEntry.Copy(Rec);
                    CurrPage.SetSelectionFilter(AuditLogEntry);
                    ExportAuditLogToExcel(AuditLogEntry);
                end;
            }
            action(DeleteOldEntries)
            {
                Caption = 'Delete Old Entries';
                Image = Delete;
                ToolTip = 'Deletes audit log entries older than a specified number of days.';

                trigger OnAction()
                var
                    AuditLogMgt: Codeunit "Audit Log Mgt.";
                    ConfirmManagement: Codeunit "Confirm Management";
                    DaysToKeep: Integer;
                    AskDaysQst: Label 'How many days of audit log do you want to keep?';
                    DeleteConfirmQst: Label 'Keep audit logs for %1 days and delete older entries?', Comment = '%1 = Days to keep';
                    ConfirmText: Text;
                begin
                    if not ConfirmManagement.GetResponseOrDefault(AskDaysQst, true) then
                        exit;

                    DaysToKeep := 90; // Default
                    ConfirmText := StrSubstNo(DeleteConfirmQst, DaysToKeep);
                    if ConfirmManagement.GetResponseOrDefault(ConfirmText, false) then
                        AuditLogMgt.DeleteOldAuditLogs(DaysToKeep);
                end;
            }
        }
        area(Navigation)
        {
            action(FilterByTable)
            {
                Caption = 'Filter by Table';
                Image = FilterLines;
                ToolTip = 'Filters the audit log by the selected table.';

                trigger OnAction()
                begin
                    Rec.SetRange("Table ID", Rec."Table ID");
                end;
            }
            action(FilterByUser)
            {
                Caption = 'Filter by User';
                Image = User;
                ToolTip = 'Filters the audit log by the selected user.';

                trigger OnAction()
                begin
                    Rec.SetRange("User ID", Rec."User ID");
                end;
            }
            action(ClearFilters)
            {
                Caption = 'Clear Filters';
                Image = ClearFilter;
                ToolTip = 'Clears all filters.';

                trigger OnAction()
                begin
                    Rec.Reset();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStyles();
    end;

#pragma warning disable LC0010
    local procedure SetStyles()
    var
        DaysOld: Integer;
    begin
        // DateTime Style
        DaysOld := Today() - Rec."Date Time".Date();
        if DaysOld > 30 then
            DateTimeStyle := Format(PageStyle::Subordinate)
        else
            DateTimeStyle := Format(PageStyle::Standard);

        // Operation Style
        case Rec."Operation Type" of
            Rec."Operation Type"::Delete, Rec."Operation Type"::"Bulk Delete":
                OperationStyle := Format(PageStyle::Attention);
            Rec."Operation Type"::Modify, Rec."Operation Type"::"Bulk Modify":
                OperationStyle := Format(PageStyle::Ambiguous);
            else
                OperationStyle := Format(PageStyle::Favorable);
        end;

        // Status Style
        case Rec.Status of
            Rec.Status::Success:
                StatusStyle := Format(PageStyle::Favorable);
            Rec.Status::Failed:
                StatusStyle := Format(PageStyle::Unfavorable);
            Rec.Status::"Partially Failed":
                StatusStyle := Format(PageStyle::Attention);
            else
                StatusStyle := Format(PageStyle::Standard);
        end;

        // Records Style
        if Rec."No. of Records Affected" > 1000 then
            AffectedRecordsStyle := Format(PageStyle::Strong)
        else
            if Rec."No. of Records Affected" > 100 then
                AffectedRecordsStyle := Format(PageStyle::Favorable)
            else
                AffectedRecordsStyle := Format(PageStyle::Standard);

        if Rec."No. of Records Failed" > 0 then
            FailedRecordsStyle := Format(PageStyle::Unfavorable)
        else
            FailedRecordsStyle := Format(PageStyle::Standard);
    end;
#pragma warning restore LC0010

    local procedure ExportAuditLogToExcel(var AuditLogEntry: Record "Audit Log Entry")
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
    begin
        // Headers
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn('Entry No.', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Date Time', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Operation', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Table ID', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Table Name', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('User', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Status', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Records Affected', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Records Failed', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Fields Changed', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Duration (ms)', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Description', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('Error Message', false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);

        // Data
        if AuditLogEntry.FindSet() then
            repeat
                TempExcelBuffer.NewRow();
                TempExcelBuffer.AddColumn(AuditLogEntry."Entry No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                TempExcelBuffer.AddColumn(Format(AuditLogEntry."Date Time"), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(Format(AuditLogEntry."Operation Type"), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(AuditLogEntry."Table ID", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                AuditLogEntry.CalcFields("Table Name");
                TempExcelBuffer.AddColumn(AuditLogEntry."Table Name", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(AuditLogEntry."User ID", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(Format(AuditLogEntry.Status), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(AuditLogEntry."No. of Records Affected", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                TempExcelBuffer.AddColumn(AuditLogEntry."No. of Records Failed", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                TempExcelBuffer.AddColumn(AuditLogEntry."No. of Fields Changed", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                TempExcelBuffer.AddColumn(AuditLogEntry."Duration (ms)", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Number);
                TempExcelBuffer.AddColumn(AuditLogEntry.Description, false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
                TempExcelBuffer.AddColumn(AuditLogEntry."Error Message", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            until AuditLogEntry.Next() = 0;

        TempExcelBuffer.CreateNewBook('Audit Log');
        TempExcelBuffer.WriteSheet('Audit Log', CompanyName(), UserId());
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.OpenExcel();
    end;

    var
        AffectedRecordsStyle: Text;
        DateTimeStyle: Text;
        FailedRecordsStyle: Text;
        OperationStyle: Text;
        StatusStyle: Text;
}
