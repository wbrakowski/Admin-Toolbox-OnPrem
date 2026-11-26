namespace AdminToolbox;

using Microsoft.Assembly.Comment;
using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Bank.Check;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.CashFlow.Worksheet;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Journal;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Task;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Absence;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Reconciliation;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Loaner;
using Microsoft.Service.Pricing;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Automation;
using System.Diagnostics;
using System.EMail;
using System.Environment;
using System.Environment.Configuration;
using System.Reflection;
using System.Security.AccessControl;
using System.Threading;
using System.Utilities;

codeunit 51000 "Admin Tool Mgt."
{
    Permissions = tabledata "Admin Toolbox Setup" = ri,
                  tabledata "Bank Account Ledger Entry" = imd,
                  tabledata "Cust. Ledger Entry" = imd,
                  tabledata "Detailed Cust. Ledg. Entry" = imd,
                  tabledata "Detailed Vendor Ledg. Entry" = imd,
                  tabledata "G/L Entry" = imd,
                  tabledata "G/L Entry - VAT Entry Link" = imd,
                  tabledata "G/L Register" = imd,
                  tabledata "Gen. Journal Line" = imd,
                  tabledata "Item Application Entry" = imd,
                  tabledata "Item Ledger Entry" = imd,
                  tabledata "Item Register" = imd,
                  tabledata "Job Ledger Entry" = imd,
                  tabledata "Purch. Cr. Memo Hdr." = imd,
                  tabledata "Purch. Cr. Memo Line" = imd,
                  tabledata "Purch. Inv. Header" = imd,
                  tabledata "Purch. Inv. Line" = imd,
                  tabledata "Purch. Rcpt. Header" = imd,
                  tabledata "Purch. Rcpt. Line" = imd,
                  tabledata "Purchase Header" = imd,
                  tabledata "Purchase Line" = imd,
                  tabledata "Record Deletion" = rim,
                  tabledata "Record Deletion Rel. Error" = rid,
                  tabledata "Return Receipt Header" = imd,
                  tabledata "Return Shipment Header" = imd,
                  tabledata "Sales Cr.Memo Header" = imd,
                  tabledata "Sales Cr.Memo Line" = imd,
                  tabledata "Sales Header" = imd,
                  tabledata "Sales Invoice Header" = imd,
                  tabledata "Sales Invoice Line" = imd,
                  tabledata "Sales Line" = imd,
                  tabledata "Sales Shipment Header" = imd,
                  tabledata "Sales Shipment Line" = imd,
                  tabledata "Value Entry" = imd,
                  tabledata "VAT Entry" = imd,
                  tabledata "Vendor Ledger Entry" = imd;

    procedure CalcRecordsInTable(TableNoToCheck: Integer): Integer
    var
        Field: Record Field;
        RecordRef: RecordRef;
        NoOfRecords: Integer;
    begin
        Field.SetRange(TableNo, TableNoToCheck);
        if not Field.IsEmpty() then begin
            RecordRef.Open(TableNoToCheck);
            RecordRef.ReadIsolation(IsolationLevel::ReadUncommitted);
            NoOfRecords := RecordRef.Count();
            RecordRef.Close();
            exit(NoOfRecords);
        end;
        exit(0);
    end;

    procedure CheckTableRelations()
    var
        RecordDeletion: Record "Record Deletion";
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
        ConfirmManagement: Codeunit "Confirm Management";
        UpdateDialog: Dialog;
        ProcessedCount: Integer;
        TotalCount: Integer;
        CheckingRelationsTxt: Label 'Checking table relations...\Table ID: #1#######\Table name: #2##################\Progress: #3##########', Comment = '%1 = Table ID, %2 = Table name, %3 = Progress in percent';
        CheckRelationsQst: Label 'Do you want to check the table relations of all listed tables?';
    begin
        if not ConfirmManagement.GetResponseOrDefault(CheckRelationsQst, false) then
            exit;

        UpdateDialog.Open(CheckingRelationsTxt);
        RecordDeletionRelError.DeleteAll(false);

        RecordDeletion.SetLoadFields("Table ID");
        RecordDeletion.SetAutoCalcFields("Table Name");
        TotalCount := RecordDeletion.Count();
        if RecordDeletion.FindSet() then
            repeat
                ProcessedCount += 1;
                UpdateDialog.Update(1, Format(RecordDeletion."Table ID"));
                UpdateDialog.Update(2, RecordDeletion."Table Name");
                UpdateDialog.Update(3, Format(ProcessedCount * 100 div TotalCount) + '%');
                CheckTableRelationsForTable(RecordDeletion."Table ID");
            until RecordDeletion.Next() = 0;

        UpdateDialog.Close();
    end;

    // internal (not local) so the test app can run the relation check for one table without the confirm dialog
    internal procedure CheckTableRelationsForTable(TableID: Integer)
    var
        TempRelationField: Record Field temporary;
        RecordRef: RecordRef;
    begin
        // Only normal tables: skips TableType MicrosoftGraph, CRM etc.
        if not IsNormalTable(TableID) then
            exit;

        CollectRelationFields(TableID, TempRelationField);
        if TempRelationField.IsEmpty() then
            exit;

        RecordRef.Open(TableID);
        CheckRelationsForFields(RecordRef, TempRelationField);
        RecordRef.Close();
    end;

    local procedure IsNormalTable(TableID: Integer): Boolean
    var
        TableMetadata: Record "Table Metadata";
    begin
        TableMetadata.SetRange(ID, TableID);
        TableMetadata.SetRange(TableType, TableMetadata.TableType::Normal);
        exit(not TableMetadata.IsEmpty());
    end;

    // Reads the field metadata once per table instead of once per record.
    local procedure CollectRelationFields(TableID: Integer; var TempRelationField: Record Field temporary)
    var
        Field: Record Field;
    begin
        Field.SetRange(TableNo, TableID);
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
        // System tables cannot be opened for every target type
        Field.SetFilter(RelationTableNo, '1..%1', SystemTableIdStart() - 1);

        // Avoids "Table connection for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used"
        if TableID in [5330, 7200] then
            Field.SetFilter("No.", '<> %1', 124);

        if Field.FindSet() then
            repeat
                TempRelationField := Field;
                TempRelationField.Insert(false);
            until Field.Next() = 0;
    end;

    local procedure CheckRelationsForFields(var RecordRef: RecordRef; var TempRelationField: Record Field temporary)
    begin
        if TempRelationField.FindSet() then
            repeat
                CheckRelationsForField(RecordRef, TempRelationField);
            until TempRelationField.Next() = 0;
    end;

    // Opens the related table and resolves the target field once per field, not once per record.
    local procedure CheckRelationsForField(var RecordRef: RecordRef; Field: Record Field)
    var
        RecordRef2: RecordRef;
        FieldRef: FieldRef;
        FieldRef2: FieldRef;
    begin
        // CRM, Graph and other non-normal related tables cannot be opened
        if not IsNormalTable(Field.RelationTableNo) then
            exit;

        RecordRef2.Open(Field.RelationTableNo);
        if not ResolveRelationFieldRef(Field, RecordRef2, FieldRef2) then begin
            RecordRef2.Close();
            exit;
        end;

        FieldRef := RecordRef.Field(Field."No.");
        if (FieldRef.Type() = FieldRef2.Type()) and (FieldRef.Length() = FieldRef2.Length()) then
            if RecordRef.FindSet() then
                repeat
                    CheckFieldRelationForRecord(RecordRef, FieldRef, RecordRef2, FieldRef2);
                until RecordRef.Next() = 0;

        RecordRef2.Close();
    end;

    local procedure ResolveRelationFieldRef(Field: Record Field; var RecordRef2: RecordRef; var FieldRef2: FieldRef): Boolean
    begin
        if Field.RelationFieldNo <> 0 then begin
            FieldRef2 := RecordRef2.Field(Field.RelationFieldNo);
            exit(true);
        end;
        exit(GetPrimaryKeyFieldRef(RecordRef2, FieldRef2));
    end;

    local procedure CheckFieldRelationForRecord(var RecordRef: RecordRef; var FieldRef: FieldRef; var RecordRef2: RecordRef; var FieldRef2: FieldRef)
    begin
        if IsBlankRelationValue(FieldRef) then
            exit;

        CheckRelationExists(RecordRef, FieldRef, RecordRef2, FieldRef2);
    end;

    local procedure IsBlankRelationValue(var FieldRef: FieldRef): Boolean
    var
        GuidValue: Guid;
    begin
        // An empty GUID is formatted as 00000000-0000-..., so it needs its own check
        if FieldRef.Type() = FieldType::GUID then begin
            GuidValue := FieldRef.Value();
            exit(IsNullGuid(GuidValue));
        end;

        exit((Format(FieldRef.Value()) = '') or (Format(FieldRef.Value()) = '0'));
    end;

    local procedure GetPrimaryKeyFieldRef(var RecordRef2: RecordRef; var FieldRef2: FieldRef): Boolean
    var
        PrimaryKeyRef: KeyRef;
    begin
        PrimaryKeyRef := RecordRef2.KeyIndex(1);
        // A composite primary key cannot be matched against a single value
        if PrimaryKeyRef.FieldCount() <> 1 then
            exit(false);

        FieldRef2 := PrimaryKeyRef.FieldIndex(1);
        exit(true);
    end;

    local procedure CheckRelationExists(var RecordRef: RecordRef; var FieldRef: FieldRef; var RecordRef2: RecordRef; var FieldRef2: FieldRef)
    var
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
        EntryNo: Integer;
        NotExistsTxt: Label 'The record %1 refers to the value ''%3'', which does not exist in field ''%2'' of table ''%4''.', Comment = '%1 = Primary key of the source record, %2 = Target field name, %3 = Field value, %4 = Target table name';
    begin
        FieldRef2.SetRange(FieldRef.Value());
        if RecordRef2.FindFirst() then
            exit;

        RecordDeletionRelError.SetRange("Table ID", RecordRef.Number());
        if RecordDeletionRelError.FindLast() then
            EntryNo := RecordDeletionRelError."Entry No." + 1
        else
            EntryNo := 1;

        RecordDeletionRelError.Init();
        RecordDeletionRelError."Table ID" := RecordRef.Number();
        RecordDeletionRelError."Entry No." := EntryNo;
        RecordDeletionRelError."Field No." := FieldRef.Number();
        RecordDeletionRelError.Error := CopyStr(StrSubstNo(NotExistsTxt, Format(RecordRef.GetPosition()), Format(FieldRef2.Name()), Format(FieldRef.Value()), Format(RecordRef2.Name())), 1, 250);
        RecordDeletionRelError.Insert(false);
    end;

    procedure ClearRecordsToDelete()
    var
        RecordDeletion: Record "Record Deletion";
        MarkDeletionRemovedMsg: Label 'The field %1 was cleared for all tables.', Comment = '%1 = FieldCaption of "Delete Records"';
    begin
        RecordDeletion.ModifyAll("Delete Records", false, false);
        Message(MarkDeletionRemovedMsg, RecordDeletion.FieldCaption("Delete Records"));
    end;

    procedure DeleteRecords()
    var
        RecordDeletion: Record "Record Deletion";
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
        RunTrigger: Boolean;
        UpdateDialog: Dialog;
        Selection: Integer;
        OptionsLbl: Label 'Delete records without running table triggers,Delete records and run table triggers';
    begin
        Selection := StrMenu(OptionsLbl, 1);
        if not ProcessDeletionSelection(Selection, RunTrigger) then
            exit;

        UpdateDialog.Open(GetDeletingRecordsText());

        ValidateRecordsMarkedForDeletion(RecordDeletion, UpdateDialog);
        CreateBackupsAndCommit(RecordDeletion, UpdateDialog);
        PerformDeletion(RecordDeletion, RecordDeletionRelError, RunTrigger, UpdateDialog);

        UpdateDialog.Close();
        ShowDeletionSuccessMessage(RecordDeletion);
    end;

    local procedure ProcessDeletionSelection(Selection: Integer; var RunTrigger: Boolean): Boolean
    begin
        case Selection of
            0: // Cancelled
                exit(false);
            1: // Without trigger
                Clear(RunTrigger);
            2: // With trigger
                RunTrigger := true;
        end;
        exit(true);
    end;

    local procedure GetDeletingRecordsText(): Text
    var
        DeletingRecordsTxt: Label 'Deleting records...\Table ID: #1#######', Comment = '%1 = Table ID';
    begin
        exit(DeletingRecordsTxt);
    end;

    local procedure ValidateRecordsMarkedForDeletion(var RecordDeletion: Record "Record Deletion"; var UpdateDialog: Dialog)
    var
        NoRecsFoundErr: Label 'No tables are marked for deletion. Select the field %1 for the tables whose records you want to delete, and then run this action again.',
                        Comment = '%1 = FieldCaption of "Delete Records"';
    begin
        RecordDeletion.SetRange("Delete Records", true);
        if RecordDeletion.IsEmpty() then begin
            UpdateDialog.Close();
            Error(NoRecsFoundErr, RecordDeletion.FieldCaption("Delete Records"));
        end;

        CheckTablesAreDeletable(RecordDeletion);
        ConfirmDeletion(RecordDeletion, UpdateDialog);
    end;

    // The backups are committed before the deletion, so they survive an error during the deletion.
    local procedure CreateBackupsAndCommit(var RecordDeletion: Record "Record Deletion"; var UpdateDialog: Dialog)
    var
        BackupCount: Integer;
        CancelledByUserErr: Label 'The operation was cancelled by the user.';
    begin
        if not CreateBackupsBeforeDeletion(RecordDeletion, UpdateDialog, BackupCount) then begin
            UpdateDialog.Close();
            Error(CancelledByUserErr);
        end;

        if BackupCount > 0 then
            Commit();
    end;

    local procedure SystemTableIdStart(): Integer
    begin
        exit(2000000000);
    end;

    // Tables of the Admin Toolbox itself (audit log, backups, deletion list) and the system tables are never deleted.
    internal procedure IsTableProtected(TableID: Integer): Boolean
    begin
        if TableID >= SystemTableIdStart() then
            exit(true);

        exit(TableID in [
            Database::"Admin Toolbox Setup", Database::"Audit Log Entry", Database::"Field Change History",
            Database::"Record Deletion", Database::"Record Deletion Rel. Error", Database::"Table Backup"]);
    end;

    local procedure CheckTablesAreDeletable(var RecordDeletion: Record "Record Deletion")
    var
        ProtectedTables: Text;
        ProtectedTablesErr: Label 'The following tables belong to the Admin Toolbox or to the system and cannot be deleted: %1.\\Clear the field %2 for these tables and try again.', Comment = '%1 = Table names, %2 = FieldCaption of "Delete Records"';
    begin
        RecordDeletion.SetRange("Delete Records", true);
        RecordDeletion.SetLoadFields("Table ID");
        if RecordDeletion.FindSet() then
            repeat
                if IsTableProtected(RecordDeletion."Table ID") then begin
                    if ProtectedTables <> '' then
                        ProtectedTables += ', ';
                    ProtectedTables += StrSubstNo('%1 %2', RecordDeletion."Table ID", GetTableCaption(RecordDeletion."Table ID"));
                end;
            until RecordDeletion.Next() = 0;
        RecordDeletion.SetLoadFields();

        if ProtectedTables <> '' then
            Error(ProtectedTablesErr, ProtectedTables, RecordDeletion.FieldCaption("Delete Records"));
    end;

    local procedure ConfirmDeletion(var RecordDeletion: Record "Record Deletion"; var UpdateDialog: Dialog)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        CancelledByUserErr: Label 'The operation was cancelled by the user.';
        DeleteRecordsQst: Label '%1 table(s) are marked for deletion. All records in these tables will be permanently deleted.\\Do you want to continue?', Comment = '%1 = No. of tables';
        ConfirmMessage: Text;
    begin
        ConfirmMessage := StrSubstNo(DeleteRecordsQst, RecordDeletion.Count());
        if not ConfirmManagement.GetResponseOrDefault(ConfirmMessage, false) then begin
            UpdateDialog.Close();
            Error(CancelledByUserErr);
        end;
    end;

    // internal (not local) so the test app can run the deletion without the StrMenu and confirm dialogs
    internal procedure PerformDeletion(var RecordDeletion: Record "Record Deletion"; var RecordDeletionRelError: Record "Record Deletion Rel. Error"; RunTrigger: Boolean; var UpdateDialog: Dialog)
    var
        AuditLogMgt: Codeunit "Audit Log Mgt.";
        RecordRef: RecordRef;
        AuditLogOperationType: Enum "Audit Log Operation Type";
        AuditLogStatus: Enum "Audit Log Status";
        RecordCount: Integer;
        TableAuditLogEntryNo: Integer;
        DeletedRecordsLbl: Label 'Deleted all records from table %1 (%2)', Comment = '%1 = Table ID, %2 = Record count';
    begin
        // Never touch tables that are not marked for deletion, even if the caller passes an unfiltered record
        RecordDeletion.SetRange("Delete Records", true);
        CheckTablesAreDeletable(RecordDeletion);
        if RecordDeletion.FindSet() then
            repeat
                UpdateDialog.Update(1, Format(RecordDeletion."Table ID"));
                RecordRef.Open(RecordDeletion."Table ID");

                RecordCount := RecordRef.Count();

                // Start audit log for this table deletion
                TableAuditLogEntryNo := AuditLogMgt.StartOperation(
                    AuditLogOperationType::Delete,
                    RecordDeletion."Table ID",
                    StrSubstNo(DeletedRecordsLbl, RecordDeletion."Table ID", RecordCount),
                    'Admin Toolbox - Delete Records');

                RecordRef.DeleteAll(RunTrigger);

                // Complete audit log for this table
                AuditLogMgt.CompleteOperation(TableAuditLogEntryNo, AuditLogStatus::Success, RecordCount, 0, '');

                RecordRef.Close();
                RecordDeletionRelError.SetRange("Table ID", RecordDeletion."Table ID");
                RecordDeletionRelError.DeleteAll(false);
            until RecordDeletion.Next() = 0;
    end;

    // internal (not local) so the test app can create the backups without the confirm dialogs.
    // Returns false if the user cancels because of tables with field types that cannot be backed up.
    internal procedure CreateBackupsBeforeDeletion(var RecordDeletion: Record "Record Deletion"; var UpdateDialog: Dialog; var BackupCount: Integer): Boolean
    var
        AdminToolboxSetup: Record "Admin Toolbox Setup";
        TableBackupMgt: Codeunit "Table Backup Mgt.";
        BackupOperationType: Enum "Backup Operation Type";
    begin
        BackupCount := 0;
        RecordDeletion.SetRange("Delete Records", true);
        CheckTablesAreDeletable(RecordDeletion);
        InitializeBackupSetup(AdminToolboxSetup);

        if not AdminToolboxSetup."Auto Backup Before Deletion" then
            exit(true);

        if not ConfirmBackupCreation(AdminToolboxSetup, UpdateDialog) then
            exit(true);

        if not ConfirmTablesWithUnsupportedFields(RecordDeletion, TableBackupMgt, UpdateDialog) then
            exit(false);

        BackupCount := CreateBackupsForTables(RecordDeletion, AdminToolboxSetup, TableBackupMgt, BackupOperationType);
        ShowBackupCompletionMessage(BackupCount);

        // Reopen the deletion dialog
        UpdateDialog.Open(GetDeletingRecordsText());
        exit(true);
    end;

    // One question for all flagged tables that contain field types that are skipped by the backup (BLOB, Media, RecordID, ...)
    local procedure ConfirmTablesWithUnsupportedFields(var RecordDeletion: Record "Record Deletion"; var TableBackupMgt: Codeunit "Table Backup Mgt."; var UpdateDialog: Dialog): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        AffectedTables: Text;
        UnsupportedFieldsQst: Label 'The following tables contain fields of a type that cannot be backed up (for example BLOB, Media or RecordID): %1.\\These fields are skipped in the backup and cannot be restored.\\Do you want to continue?', Comment = '%1 = Table names';
    begin
        if RecordDeletion.FindSet() then
            repeat
                if TableBackupMgt.TableHasUnsupportedFields(RecordDeletion."Table ID") then begin
                    if AffectedTables <> '' then
                        AffectedTables += ', ';
                    AffectedTables += StrSubstNo('%1 %2', RecordDeletion."Table ID", GetTableCaption(RecordDeletion."Table ID"));
                end;
            until RecordDeletion.Next() = 0;

        if AffectedTables = '' then
            exit(true);

        UpdateDialog.Close();
        exit(ConfirmManagement.GetResponseOrDefault(StrSubstNo(UnsupportedFieldsQst, AffectedTables), true));
    end;

    local procedure InitializeBackupSetup(var AdminToolboxSetup: Record "Admin Toolbox Setup")
    var
        BackupType: Enum "Backup Type";
    begin
        if not AdminToolboxSetup.Get() then begin
            AdminToolboxSetup.Init();
            AdminToolboxSetup."Auto Backup Before Deletion" := true;
            AdminToolboxSetup."Prompt for Backup" := true;
            AdminToolboxSetup."Auto Backup Type" := BackupType::"JSON Export";
            AdminToolboxSetup.Insert(true);
        end;
    end;

    local procedure ConfirmBackupCreation(var AdminToolboxSetup: Record "Admin Toolbox Setup"; var UpdateDialog: Dialog): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        BackupSkippedMsg: Label 'No backup was created. The records will be deleted without a backup.';
        CreateBackupQst: Label 'Do you want to create a backup of the tables before the records are deleted?\\A backup is recommended so that the data can be restored if needed.';
    begin
        if not AdminToolboxSetup."Prompt for Backup" then
            exit(true);

        UpdateDialog.Close();
        if not ConfirmManagement.GetResponseOrDefault(CreateBackupQst, true) then begin
            Message(BackupSkippedMsg);
            UpdateDialog.Open(GetDeletingRecordsText());
            exit(false);
        end;

        exit(true);
    end;

    local procedure CreateBackupsForTables(var RecordDeletion: Record "Record Deletion"; var AdminToolboxSetup: Record "Admin Toolbox Setup"; var TableBackupMgt: Codeunit "Table Backup Mgt."; BackupOperationType: Enum "Backup Operation Type"): Integer
    var
        BackupType: Enum "Backup Type";
        BackupCount: Integer;
        BackupTypeToUse: Enum "Backup Type";
        AutoBackupLbl: Label 'Auto backup before deletion of table %1', Comment = '%1 = Table ID';
    begin
        // Ensure a valid backup type is used (fallback to JSON Export if not set)
        BackupTypeToUse := AdminToolboxSetup."Auto Backup Type";
        // Check if BackupType is 0 (blank/unset) or invalid
        if BackupTypeToUse.AsInteger() = 0 then
            BackupTypeToUse := BackupType::"JSON Export";

        if RecordDeletion.FindSet() then
            repeat
                TableBackupMgt.CreateBackup(
                    RecordDeletion."Table ID",
                    BackupTypeToUse,
                    BackupOperationType::"Before Deletion",
                    StrSubstNo(AutoBackupLbl, RecordDeletion."Table ID"),
                    false);
                BackupCount += 1;
            until RecordDeletion.Next() = 0;

        exit(BackupCount);
    end;

    local procedure ShowBackupCompletionMessage(BackupCount: Integer)
    var
        BackupsCreatedMsg: Label '%1 backup(s) were created before deletion.', Comment = '%1 = No. of backups';
    begin
        if BackupCount > 0 then
            Message(BackupsCreatedMsg, BackupCount);
    end;

    local procedure ShowDeletionSuccessMessage(var RecordDeletion: Record "Record Deletion")
    var
        DeletionSuccessMsg: Label 'The records of %1 table(s) were deleted successfully.', Comment = '%1 = No. of tables';
    begin
        Message(DeletionSuccessMsg, RecordDeletion.Count());
    end;

    procedure InsertUpdateTables()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        RecordDeletion: Record "Record Deletion";
        UpdateDialog: Dialog;
        CurrRec, NoOfRecs : Integer;
        NoRecordFoundMsg: Label 'No records were found in table %1.', Comment = '%1 = Table Caption';
        ProcessingDataTxt: Label 'Updating the table list... @1@@@@@@';
        UpdateFinishedMsg: Label 'The table list was updated successfully (%1 tables).', Comment = '%1 = No. of tables';

    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        // Do not include system tables
        AllObjWithCaption.SetFilter("Object ID", '< %1', SystemTableIdStart());
        if AllObjWithCaption.FindSet() then begin
            UpdateDialog.Open(ProcessingDataTxt);
            NoOfRecs := AllObjWithCaption.Count();
            repeat
                CurrRec += 1;
                if NoOfRecs <= 100 then
                    UpdateDialog.Update(1, (CurrRec / NoOfRecs * 10000) div 1)
                else
                    if CurrRec mod (NoOfRecs div 100) = 0 then
                        UpdateDialog.Update(1, (CurrRec / NoOfRecs * 10000) div 1);

                RecordDeletion.Init();
                RecordDeletion."Table ID" := AllObjWithCaption."Object ID";
                RecordDeletion.Company := CopyStr(CompanyName(), 1, MaxStrLen(RecordDeletion.Company));
                if IsTableProtected(RecordDeletion."Table ID") then
                    continue;
                if not RecordDeletion.Insert(false) then
                    continue; // Ignore if already exists
            until AllObjWithCaption.Next() = 0;
            Message(UpdateFinishedMsg, CurrRec);
        end else
            Message(NoRecordFoundMsg, AllObjWithCaption.TableCaption());
    end;

    procedure OpenTable(TableId: Integer)
    var
        Url2Txt: Label '%1&table=%2', Comment = '%1 = Web URL, %2 = Table ID';
        UrlTxt: Label '%1/?table=%2', Comment = '%1 = Web URL, %2 = Table ID';
        WebUrl: Text;
    begin
        WebUrl := System.GetUrl(ClientType::Web);
        if WebUrl.Contains('?') then
            WebUrl := StrSubstNo(Url2Txt, WebUrl, TableId)
        else
            WebUrl := StrSubstNo(UrlTxt, WebUrl, TableId);
        Hyperlink(WebUrl);
    end;

    procedure PublishApp()
    var
        Selection: Integer;
        InstructionsLbl: Label 'Publishing an app requires the external deployer to be installed on the server instance. Select how you want to proceed.';
        OptionsLbl: Label 'Continue publishing (opens a new browser tab),Learn how to install the external deployer';
        PageUrlTxt: Label '%1/?page=%2', Comment = '%1 = Web URL, %2 = Page ID';
        WebUrl: Text;
    begin
        Selection := StrMenu(OptionsLbl, 1, InstructionsLbl);
        case Selection of
            1:
                begin
                    WebUrl := StrSubstNo(PageUrlTxt, System.GetUrl(ClientType::Web), 2507);
                    Hyperlink(WebUrl);
                end;
            2:
                OpenDeployerReadme();
            else
                exit;
        // Error(CancelledByUserErr);
        end;
    end;

    procedure SetSuggestedTable(TableID: Integer)
    var
        RecordDeletion: Record "Record Deletion";
    begin
        if IsTableProtected(TableID) then
            exit;

        if RecordDeletion.Get(TableID) then begin
            RecordDeletion."Delete Records" := true;
            RecordDeletion.Modify(false);
        end;
    end;

    procedure SuggestRecordsToDelete()
    var
        Selection: Integer;
        OptionsLbl: Label 'Suggest all transactional tables for deletion,Suggest unlicensed partner or custom tables for deletion';
    begin
        Selection := StrMenu(OptionsLbl, 1);
        case Selection of
            1: // Transactional
                SuggestTransactionalRecordsToDelete();
            2: // Unlicensed
                SuggestUnlicensedPartnerOrCustomRecordsToDelete();
        end;
    end;

    procedure SuggestUnlicensedPartnerOrCustomRecordsToDelete()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        PowershellMgt: Codeunit "Powershell Mgt.";
        RecsSuggestedCount: Integer;
        ImportCustLicenseQst: Label 'A developer license is currently imported. This function is intended for use with a customer license.\\Do you want to import a different license now?';
        ImportLicenseQst: Label 'A developer license is required to delete the marked unlicensed records.\\Do you want to import a different license now?';
        RecordsSuggestedMsg: Label '%1 unlicensed partner or custom tables were suggested for deletion.', Comment = '%1 = No. of suggested tables';
    begin
#if OnPrem
        PromptForLicenseImportIfDeveloperLicense(PowershellMgt, ImportCustLicenseQst);
#endif

        RecsSuggestedCount := SuggestUnlicensedCustomTables();

        Message(RecordsSuggestedMsg, RecsSuggestedCount);
#if OnPrem
        if ConfirmManagement.GetResponseOrDefault(ImportLicenseQst, false) then
            PowershellMgt.ImportLicense();
#endif
    end;

    local procedure PromptForLicenseImportIfDeveloperLicense(var PowershellMgt: Codeunit "Powershell Mgt."; PromptMessage: Text)
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if IsDeveloperLicense() then
            if ConfirmManagement.GetResponseOrDefault(PromptMessage, false) then
                PowershellMgt.ImportLicense();
    end;

    local procedure SuggestUnlicensedCustomTables(): Integer
    var
        RecordDeletion: Record "Record Deletion";
        RecsSuggestedCount: Integer;
    begin
        RecordDeletion.SetFilter("Table ID", '> %1', 49999);
        if RecordDeletion.FindSet(false) then
            repeat
                if ShouldSuggestTable(RecordDeletion."Table ID") then begin
                    SetSuggestedTable(RecordDeletion."Table ID");
                    RecsSuggestedCount += 1;
                end;
            until RecordDeletion.Next() = 0;
        exit(RecsSuggestedCount);
    end;

    local procedure ShouldSuggestTable(TableID: Integer): Boolean
    begin
        if IsRecordStandardTable(TableID) then
            exit(false);
        if IsRecordInLicense(TableID) then
            exit(false);
        exit(true);
    end;

    procedure ViewRecords(RecordDeletion: Record "Record Deletion")
    begin
        Hyperlink(GetUrl(ClientType::Current, CompanyName(), ObjectType::Table, RecordDeletion."Table ID"));
    end;

    internal procedure GetTableCaption(TableID: Integer): Text[249]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", TableID);
        if AllObjWithCaption.FindFirst() then
            exit(AllObjWithCaption."Object Caption");
        exit('');
    end;

#if OnPrem
    [Scope('OnPrem')]
    internal procedure IsDeveloperLicense(): Boolean
    var

        LicenseInformation: Record "License Information";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsOnPrem() then
            exit(false);
        LicenseInformation.SetFilter(Text, '@*solution developer*');
        exit(not LicenseInformation.IsEmpty());
    end;
#endif

    local procedure IsRecordInLicense(TableID: Integer): Boolean
    var
        LicensePermission: Record "License Permission";
    begin
        // LicensePermission.Get(LicensePermission."Object Type"::Table, TableID);
        if not LicensePermission.Get(LicensePermission."Object Type"::TableData, TableID) then
            exit(false);

        if (LicensePermission."Read Permission" = LicensePermission."Read Permission"::" ") and
            (LicensePermission."Insert Permission" = LicensePermission."Insert Permission"::" ") and
            (LicensePermission."Modify Permission" = LicensePermission."Modify Permission"::" ") and
            (LicensePermission."Delete Permission" = LicensePermission."Delete Permission"::" ") and
            (LicensePermission."Execute Permission" = LicensePermission."Execute Permission"::" ")
        then
            exit(false)
        else
            exit(true);
    end;

    local procedure IsRecordStandardTable(TableID: Integer): Boolean
    begin
        if IsGermanLocalization(TableID) then
            exit(true);

        if IsSpanishLocalization(TableID) then
            exit(true);

        if IsManufacturingTable(TableID) then
            exit(true);

        if IsMicrosoftLocalization(TableID) then
            exit(true);

        exit(false);
    end;

    local procedure IsGermanLocalization(TableID: Integer): Boolean
    begin
        // German localization (5005270 - 5005363)
        exit((TableID >= 5005270) and (TableID <= 5005363));
    end;

    local procedure IsSpanishLocalization(TableID: Integer): Boolean
    begin
        // Spanish localization (7000002 - 7000024)
        exit((TableID >= 7000002) and (TableID <= 7000024));
    end;

    local procedure IsManufacturingTable(TableID: Integer): Boolean
    begin
        // Manufacturing (99000750 - 99008535)
        exit((TableID >= Database::"Work Shift") and (TableID <= 99008535));
    end;

    local procedure IsMicrosoftLocalization(TableID: Integer): Boolean
    begin
        // Microsoft Localizations (100000 - 999999)
        exit((TableID >= 100000) and (TableID <= 999999));
    end;

    local procedure OpenDeployerReadme()
    begin
        Hyperlink('https://github.com/wbrakowski/Admin-Toolbox-OnPrem/blob/main/README.md#how-to-install-the-external-deployer');
    end;

    internal procedure OpenReadme()
    begin
        Hyperlink('https://github.com/wbrakowski/Admin-Tool-OnPrem/blob/main/README.md');
    end;

    internal procedure OpenTableEditor(TableNo: Integer)
    var
        TableEditor: Page "Table Editor";
    begin
        TableEditor.SetParameters(TableNo);
        TableEditor.Run();
    end;

#if OnPrem
    [Scope('OnPrem')]
    internal procedure ShowDevLicenseMessageIfNeeded()
    var
        AdminToolboxSetup: Record "Admin Toolbox Setup";
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        DevLicenseMsg: Label 'A developer license is currently active.';
    begin
        if not AdminToolboxSetup.Get() then
            exit;

        if AdminToolMgt.IsDeveloperLicense() and AdminToolboxSetup."Developer License Warning" then
            Message(DevLicenseMsg);
    end;
#endif

    local procedure SuggestTransactionalRecordsToDelete()
    var
        RecordDeletion: Record "Record Deletion";
        AfterSuggestionDeleteCount, BeforeSuggestionDeleteCount : Integer;
        RecordsWereSuggestedMsg: Label '%1 tables were suggested for deletion.', Comment = '%1 = No. of suggested tables';
    begin
        RecordDeletion.SetRange("Delete Records", true);
        BeforeSuggestionDeleteCount := RecordDeletion.Count();

        SuggestAnalysisAndApprovalTables();
        SuggestAssemblyTables();
        SuggestBankTables();
        SuggestCampaignAndCapacityTables();
        SuggestCashFlowTables();
        SuggestCostAndCreditTables();
        SuggestCustomerAndDimensionTables();
        SuggestEmployeeAndErrorTables();
        SuggestFATables();
        SuggestFinanceChargeTables();
        SuggestGLTables();
        SuggestICTables();
        SuggestIncomingAndInsuranceTables();
        SuggestInventoryTables();
        SuggestIssuedDocumentTables();
        SuggestItemTables();
        SuggestJobTables();
        SuggestLoanerAndMaintenanceTables();
        SuggestOpportunityAndOrderTables();
        SuggestPaymentTables();
        SuggestPlanningAndPostingTables();
        SuggestProductionTables();
        SuggestPurchaseTables();
        SuggestRegisteredAndReminderTables();
        SuggestRequisitionAndReservationTables();
        SuggestReturnTables();
        SuggestSalesTables();
        SuggestSegmentAndServiceTables();
        SuggestTimeSheetTables();
        SuggestTransferAndVATTables();
        SuggestWarehouseTables();
        SuggestMiscellaneousTables();

        RecordDeletion.SetRange("Delete Records", true);
        AfterSuggestionDeleteCount := RecordDeletion.Count();
        Message(RecordsWereSuggestedMsg, AfterSuggestionDeleteCount - BeforeSuggestionDeleteCount);
    end;

    local procedure SuggestAnalysisAndApprovalTables()
    begin
        SetSuggestedTable(Database::"Action Message Entry");
        SetSuggestedTable(Database::"Analysis View Budget Entry");
        SetSuggestedTable(Database::"Analysis View Entry");
        SetSuggestedTable(Database::"Analysis View");
        SetSuggestedTable(Database::"Approval Comment Line");
        SetSuggestedTable(Database::"Approval Entry");
    end;

    local procedure SuggestAssemblyTables()
    begin
        SetSuggestedTable(Database::"Assemble-to-Order Link");
        SetSuggestedTable(Database::"Assembly Comment Line");
        SetSuggestedTable(Database::"Assembly Header");
        SetSuggestedTable(Database::"Assembly Line");
        SetSuggestedTable(Database::"Avg. Cost Adjmt. Entry Point");
    end;

    local procedure SuggestBankTables()
    begin
        SetSuggestedTable(Database::"Bank Acc. Reconciliation Line");
        SetSuggestedTable(Database::"Bank Acc. Reconciliation");
        SetSuggestedTable(Database::"Bank Account Ledger Entry");
        SetSuggestedTable(Database::"Bank Account Statement Line");
        SetSuggestedTable(Database::"Bank Account Statement");
        SetSuggestedTable(Database::"Bank Stmt Multiple Match Line");
    end;

    local procedure SuggestCampaignAndCapacityTables()
    begin
        SetSuggestedTable(Database::"Campaign Entry");
        SetSuggestedTable(Database::"Capacity Ledger Entry");
    end;

    local procedure SuggestCashFlowTables()
    begin
        SetSuggestedTable(Database::"Cash Flow Manual Revenue");
        SetSuggestedTable(Database::"Cash Flow Manual Expense");
        SetSuggestedTable(Database::"Cash Flow Forecast Entry");
        SetSuggestedTable(Database::"Cash Flow Worksheet Line");
    end;

    local procedure SuggestCostAndCreditTables()
    begin
        SetSuggestedTable(Database::"Certificate of Supply");
        SetSuggestedTable(Database::"Change Log Entry");
        SetSuggestedTable(Database::"Check Ledger Entry");
        SetSuggestedTable(Database::"Comment Line");
        SetSuggestedTable(Database::"Contract Change Log");
        SetSuggestedTable(Database::"Contract Gain/Loss Entry");
        SetSuggestedTable(Database::"Contract/Service Discount");
        SetSuggestedTable(Database::"Cost Budget Entry");
        SetSuggestedTable(Database::"Cost Budget Register");
        SetSuggestedTable(Database::"Cost Entry");
        SetSuggestedTable(Database::"Cost Journal Line");
        SetSuggestedTable(Database::"Cost Register");
        SetSuggestedTable(Database::"Credit Trans Re-export History");
        SetSuggestedTable(Database::"Credit Transfer Entry");
        SetSuggestedTable(Database::"Credit Transfer Register");
    end;

    local procedure SuggestCustomerAndDimensionTables()
    begin
        SetSuggestedTable(Database::"Cust. Ledger Entry");
        SetSuggestedTable(Database::"Date Compr. Register");
        SetSuggestedTable(Database::"Detailed Cust. Ledg. Entry");
        SetSuggestedTable(Database::"Detailed Vendor Ledg. Entry");
        SetSuggestedTable(Database::"Dimension Set Entry");
        SetSuggestedTable(Database::"Dimension Set Tree Node");
        SetSuggestedTable(Database::"Direct Debit Collection Entry");
        SetSuggestedTable(Database::"Direct Debit Collection");
        SetSuggestedTable(Database::"Document Entry");
    end;

    local procedure SuggestEmployeeAndErrorTables()
    begin
        SetSuggestedTable(Database::"Email Item");
        SetSuggestedTable(Database::"Employee Absence");
        SetSuggestedTable(Database::"Error Buffer");
        SetSuggestedTable(Database::"Error Message");
        SetSuggestedTable(Database::"Error Message Register");
        SetSuggestedTable(Database::"Exch. Rate Adjmt. Reg.");
    end;

    local procedure SuggestFATables()
    begin
        SetSuggestedTable(Database::"FA G/L Posting Buffer");
        SetSuggestedTable(Database::"FA Ledger Entry");
        SetSuggestedTable(Database::"FA Register");
        SetSuggestedTable(Database::"Filed Contract Line");
        SetSuggestedTable(Database::"Filed Service Contract Header");
    end;

    local procedure SuggestFinanceChargeTables()
    begin
        SetSuggestedTable(Database::"Fin. Charge Comment Line");
        SetSuggestedTable(Database::"Finance Charge Memo Header");
        SetSuggestedTable(Database::"Finance Charge Memo Line");
    end;

    local procedure SuggestGLTables()
    begin
        SetSuggestedTable(Database::"G/L - Item Ledger Relation");
        SetSuggestedTable(Database::"G/L Budget Entry");
        SetSuggestedTable(Database::"G/L Budget Name");
        SetSuggestedTable(Database::"G/L Entry - VAT Entry Link");
        SetSuggestedTable(Database::"G/L Entry");
        SetSuggestedTable(Database::"G/L Register");
        SetSuggestedTable(Database::"Gen. Jnl. Allocation");
        SetSuggestedTable(Database::"Gen. Journal Line");
    end;

    local procedure SuggestICTables()
    begin
        SetSuggestedTable(Database::"Handled IC Inbox Jnl. Line");
        SetSuggestedTable(Database::"Handled IC Inbox Purch. Header");
        SetSuggestedTable(Database::"Handled IC Inbox Purch. Line");
        SetSuggestedTable(Database::"Handled IC Inbox Sales Header");
        SetSuggestedTable(Database::"Handled IC Inbox Sales Line");
        SetSuggestedTable(Database::"Handled IC Inbox Trans.");
        SetSuggestedTable(Database::"Handled IC Outbox Jnl. Line");
        SetSuggestedTable(Database::"Handled IC Outbox Purch. Hdr");
        SetSuggestedTable(Database::"Handled IC Outbox Purch. Line");
        SetSuggestedTable(Database::"Handled IC Outbox Sales Header");
        SetSuggestedTable(Database::"Handled IC Outbox Sales Line");
        SetSuggestedTable(Database::"Handled IC Outbox Trans.");
        SetSuggestedTable(Database::"IC Comment Line");
        SetSuggestedTable(Database::"IC Document Dimension");
        SetSuggestedTable(Database::"IC Inbox Jnl. Line");
        SetSuggestedTable(Database::"IC Inbox Purchase Header");
        SetSuggestedTable(Database::"IC Inbox Purchase Line");
        SetSuggestedTable(Database::"IC Inbox Sales Header");
        SetSuggestedTable(Database::"IC Inbox Sales Line");
        SetSuggestedTable(Database::"IC Inbox Transaction");
        SetSuggestedTable(Database::"IC Inbox/Outbox Jnl. Line Dim.");
        SetSuggestedTable(Database::"IC Outbox Jnl. Line");
        SetSuggestedTable(Database::"IC Outbox Purchase Header");
        SetSuggestedTable(Database::"IC Outbox Purchase Line");
        SetSuggestedTable(Database::"IC Outbox Sales Header");
        SetSuggestedTable(Database::"IC Outbox Sales Line");
        SetSuggestedTable(Database::"IC Outbox Transaction");
    end;

    local procedure SuggestIncomingAndInsuranceTables()
    begin
        SetSuggestedTable(Database::"Incoming Document");
        SetSuggestedTable(Database::"Ins. Coverage Ledger Entry");
        SetSuggestedTable(Database::"Insurance Register");
        SetSuggestedTable(Database::"Inter. Log Entry Comment Line");
        SetSuggestedTable(Database::"Interaction Log Entry");
        SetSuggestedTable(Database::"Internal Movement Header");
        SetSuggestedTable(Database::"Internal Movement Line");
    end;

    local procedure SuggestInventoryTables()
    begin
        SetSuggestedTable(Database::"Inventory Adjmt. Entry (Order)");
        SetSuggestedTable(Database::"Inventory Period Entry");
        SetSuggestedTable(Database::"Inventory Report Entry");
    end;

    local procedure SuggestIssuedDocumentTables()
    begin
        SetSuggestedTable(Database::"Issued Fin. Charge Memo Header");
        SetSuggestedTable(Database::"Issued Fin. Charge Memo Line");
        SetSuggestedTable(Database::"Issued Reminder Header");
        SetSuggestedTable(Database::"Issued Reminder Line");
    end;

    local procedure SuggestItemTables()
    begin
        SetSuggestedTable(Database::"Item Analysis View Budg. Entry");
        SetSuggestedTable(Database::"Item Analysis View Entry");
        SetSuggestedTable(Database::"Item Analysis View");
        SetSuggestedTable(Database::"Item Application Entry History");
        SetSuggestedTable(Database::"Item Application Entry");
        SetSuggestedTable(Database::"Item Budget Entry");
        SetSuggestedTable(Database::"Item Charge Assignment (Purch)");
        SetSuggestedTable(Database::"Item Charge Assignment (Sales)");
        SetSuggestedTable(Database::"Item Entry Relation");
        SetSuggestedTable(Database::"Item Journal Line");
        SetSuggestedTable(Database::"Item Ledger Entry");
        SetSuggestedTable(Database::"Item Register");
        SetSuggestedTable(Database::"Item Tracking Comment");
    end;

    local procedure SuggestJobTables()
    begin
        SetSuggestedTable(Database::"Job Entry No.");
        SetSuggestedTable(Database::"Job Journal Line");
        SetSuggestedTable(Database::"Job Ledger Entry");
        SetSuggestedTable(Database::"Job Planning Line Invoice");
        SetSuggestedTable(Database::"Job Planning Line");
        SetSuggestedTable(Database::"Job Queue Log Entry");
        SetSuggestedTable(Database::"Job Register");
        SetSuggestedTable(Database::"Job Task Dimension");
        SetSuggestedTable(Database::"Job Task");
        SetSuggestedTable(Database::"Job Usage Link");
        SetSuggestedTable(Database::"Job WIP Entry");
        SetSuggestedTable(Database::"Job WIP G/L Entry");
        SetSuggestedTable(Database::"Job WIP Total");
        SetSuggestedTable(Database::"Job WIP Warning");
    end;

    local procedure SuggestLoanerAndMaintenanceTables()
    begin
        SetSuggestedTable(Database::"Loaner Entry");
        SetSuggestedTable(Database::"Lot No. Information");
        SetSuggestedTable(Database::"Maintenance Ledger Entry");
        SetSuggestedTable(Database::"Maintenance Registration");
        SetSuggestedTable(Database::"My Notifications");
    end;

    local procedure SuggestOpportunityAndOrderTables()
    begin
        SetSuggestedTable(Database::"Opportunity Entry");
        SetSuggestedTable(Database::"Order Promising Line");
        SetSuggestedTable(Database::"Order Tracking Entry");
    end;

    local procedure SuggestPaymentTables()
    begin
        SetSuggestedTable(Database::"Payable Vendor Ledger Entry");
        SetSuggestedTable(Database::"Payment Application Proposal");
        SetSuggestedTable(Database::"Payment Export Data");
        SetSuggestedTable(Database::"Payment Jnl. Export Error Text");
        SetSuggestedTable(Database::"Payment Matching Details");
        SetSuggestedTable(Database::"Phys. Inventory Ledger Entry");
    end;

    local procedure SuggestPlanningAndPostingTables()
    begin
        SetSuggestedTable(Database::"Planning Assignment");
        SetSuggestedTable(Database::"Planning Component");
        SetSuggestedTable(Database::"Planning Error Log");
        SetSuggestedTable(Database::"Planning Routing Line");
        SetSuggestedTable(Database::"Post Value Entry to G/L");
        SetSuggestedTable(Database::"Posted Approval Comment Line");
        SetSuggestedTable(Database::"Posted Approval Entry");
        SetSuggestedTable(Database::"Posted Assemble-to-Order Link");
        SetSuggestedTable(Database::"Posted Assembly Header");
        SetSuggestedTable(Database::"Posted Assembly Line");
        SetSuggestedTable(Database::"Posted Invt. Pick Header");
        SetSuggestedTable(Database::"Posted Invt. Pick Line");
        SetSuggestedTable(Database::"Posted Invt. Put-away Header");
        SetSuggestedTable(Database::"Posted Invt. Put-away Line");
        SetSuggestedTable(Database::"Posted Payment Recon. Hdr");
        SetSuggestedTable(Database::"Posted Payment Recon. Line");
        SetSuggestedTable(Database::"Posted Whse. Receipt Header");
        SetSuggestedTable(Database::"Posted Whse. Receipt Line");
        SetSuggestedTable(Database::"Posted Whse. Shipment Header");
        SetSuggestedTable(Database::"Posted Whse. Shipment Line");
    end;

    local procedure SuggestProductionTables()
    begin
        SetSuggestedTable(Database::"Prod. Order Capacity Need");
        SetSuggestedTable(Database::"Prod. Order Comment Line");
        SetSuggestedTable(Database::"Prod. Order Comp. Cmt Line");
        SetSuggestedTable(Database::"Prod. Order Component");
        SetSuggestedTable(Database::"Prod. Order Line");
        SetSuggestedTable(Database::"Prod. Order Routing Line");
        SetSuggestedTable(Database::"Prod. Order Routing Personnel");
        SetSuggestedTable(Database::"Prod. Order Routing Tool");
        SetSuggestedTable(Database::"Prod. Order Rtng Comment Line");
        SetSuggestedTable(Database::"Prod. Order Rtng Qlty Meas.");
        SetSuggestedTable(Database::"Production Forecast Entry");
        SetSuggestedTable(Database::"Production Order");
    end;

    local procedure SuggestPurchaseTables()
    begin
        SetSuggestedTable(Database::"Purch. Comment Line Archive");
        SetSuggestedTable(Database::"Purch. Comment Line");
        SetSuggestedTable(Database::"Purch. Cr. Memo Hdr.");
        SetSuggestedTable(Database::"Purch. Cr. Memo Line");
        SetSuggestedTable(Database::"Purch. Inv. Header");
        SetSuggestedTable(Database::"Purch. Inv. Line");
        SetSuggestedTable(Database::"Purch. Rcpt. Header");
        SetSuggestedTable(Database::"Purch. Rcpt. Line");
        SetSuggestedTable(Database::"Purchase Header Archive");
        SetSuggestedTable(Database::"Purchase Header");
        SetSuggestedTable(Database::"Purchase Line Archive");
        SetSuggestedTable(Database::"Purchase Line");
    end;

    local procedure SuggestRegisteredAndReminderTables()
    begin
        SetSuggestedTable(Database::"Registered Invt. Movement Hdr.");
        SetSuggestedTable(Database::"Registered Invt. Movement Line");
        SetSuggestedTable(Database::"Registered Whse. Activity Hdr.");
        SetSuggestedTable(Database::"Registered Whse. Activity Line");
        SetSuggestedTable(Database::"Reminder Comment Line");
        SetSuggestedTable(Database::"Reminder Header");
        SetSuggestedTable(Database::"Reminder Line");
        SetSuggestedTable(Database::"Reminder/Fin. Charge Entry");
    end;

    local procedure SuggestRequisitionAndReservationTables()
    begin
        SetSuggestedTable(Database::"Requisition Line");
        SetSuggestedTable(Database::"Res. Capacity Entry");
        SetSuggestedTable(Database::"Res. Journal Line");
        SetSuggestedTable(Database::"Res. Ledger Entry");
        SetSuggestedTable(Database::"Reservation Entry");
        SetSuggestedTable(Database::"Resource Register");
    end;

    local procedure SuggestReturnTables()
    begin
        SetSuggestedTable(Database::"Return Receipt Header");
        SetSuggestedTable(Database::"Return Receipt Line");
        SetSuggestedTable(Database::"Return Shipment Header");
        SetSuggestedTable(Database::"Return Shipment Line");
        SetSuggestedTable(Database::"Returns-Related Document");
        SetSuggestedTable(Database::"Reversal Entry");
        SetSuggestedTable(Database::"Rounding Residual Buffer");
    end;

    local procedure SuggestSalesTables()
    begin
        SetSuggestedTable(Database::"Sales Comment Line Archive");
        SetSuggestedTable(Database::"Sales Comment Line");
        SetSuggestedTable(Database::"Sales Cr.Memo Header");
        SetSuggestedTable(Database::"Sales Cr.Memo Line");
        SetSuggestedTable(Database::"Sales Header Archive");
        SetSuggestedTable(Database::"Sales Header");
        SetSuggestedTable(Database::"Sales Invoice Header");
        SetSuggestedTable(Database::"Sales Invoice Line");
        SetSuggestedTable(Database::"Sales Line Archive");
        SetSuggestedTable(Database::"Sales Line");
        SetSuggestedTable(Database::"Sales Planning Line");
        SetSuggestedTable(Database::"Sales Shipment Header");
        SetSuggestedTable(Database::"Sales Shipment Line");
    end;

    local procedure SuggestSegmentAndServiceTables()
    begin
        SetSuggestedTable(Database::"Segment Criteria Line");
        SetSuggestedTable(Database::"Segment Header");
        SetSuggestedTable(Database::"Segment History");
        SetSuggestedTable(Database::"Segment Interaction Language");
        SetSuggestedTable(Database::"Segment Line");
        SetSuggestedTable(Database::"Serial No. Information");
        SetSuggestedTable(Database::"Service Comment Line");
        SetSuggestedTable(Database::"Service Contract Header");
        SetSuggestedTable(Database::"Service Contract Line");
        SetSuggestedTable(Database::"Service Cr.Memo Header");
        SetSuggestedTable(Database::"Service Cr.Memo Line");
        SetSuggestedTable(Database::"Service Document Log");
        SetSuggestedTable(Database::"Service Document Register");
        SetSuggestedTable(Database::"Service Header");
        SetSuggestedTable(Database::"Service Invoice Header");
        SetSuggestedTable(Database::"Service Invoice Line");
        SetSuggestedTable(Database::"Service Item Component");
        SetSuggestedTable(Database::"Service Item Line");
        SetSuggestedTable(Database::"Service Item Log");
        SetSuggestedTable(Database::"Service Item");
        SetSuggestedTable(Database::"Service Ledger Entry");
        SetSuggestedTable(Database::"Service Line Price Adjmt.");
        SetSuggestedTable(Database::"Service Line");
        SetSuggestedTable(Database::"Service Order Allocation");
        SetSuggestedTable(Database::"Service Register");
        SetSuggestedTable(Database::"Service Shipment Header");
        SetSuggestedTable(Database::"Service Shipment Item Line");
        SetSuggestedTable(Database::"Service Shipment Line");
    end;

    local procedure SuggestTimeSheetTables()
    begin
        SetSuggestedTable(Database::"Time Sheet Cmt. Line Archive");
        SetSuggestedTable(Database::"Time Sheet Comment Line");
        SetSuggestedTable(Database::"Time Sheet Detail Archive");
        SetSuggestedTable(Database::"Time Sheet Detail");
        SetSuggestedTable(Database::"Time Sheet Header Archive");
        SetSuggestedTable(Database::"Time Sheet Header");
        SetSuggestedTable(Database::"Time Sheet Line Archive");
        SetSuggestedTable(Database::"Time Sheet Line");
        SetSuggestedTable(Database::"Time Sheet Posting Entry");
        SetSuggestedTable(Database::"To-do");
        SetSuggestedTable(Database::"Tracking Specification");
    end;

    local procedure SuggestTransferAndVATTables()
    begin
        SetSuggestedTable(Database::"Transfer Header");
        SetSuggestedTable(Database::"Transfer Line");
        SetSuggestedTable(Database::"Transfer Receipt Header");
        SetSuggestedTable(Database::"Transfer Receipt Line");
        SetSuggestedTable(Database::"Transfer Shipment Header");
        SetSuggestedTable(Database::"Transfer Shipment Line");
        SetSuggestedTable(Database::"Unplanned Demand");
        SetSuggestedTable(Database::"Untracked Planning Element");
        SetSuggestedTable(Database::"Value Entry Relation");
        SetSuggestedTable(Database::"Value Entry");
        SetSuggestedTable(Database::"VAT Entry");
        SetSuggestedTable(Database::"VAT Rate Change Log Entry");
        SetSuggestedTable(Database::"VAT Registration Log");
        SetSuggestedTable(Database::"VAT Report Header");
        SetSuggestedTable(Database::"VAT Report Line");
        SetSuggestedTable(Database::"VAT Report Line Relation");
        SetSuggestedTable(Database::"VAT Report Error Log");
        SetSuggestedTable(Database::"Vendor Ledger Entry");
    end;

    local procedure SuggestWarehouseTables()
    begin
        SetSuggestedTable(Database::"Warehouse Activity Header");
        SetSuggestedTable(Database::"Warehouse Activity Line");
        SetSuggestedTable(Database::"Warehouse Entry");
        SetSuggestedTable(Database::"Warehouse Journal Line");
        SetSuggestedTable(Database::"Warehouse Receipt Header");
        SetSuggestedTable(Database::"Warehouse Receipt Line");
        SetSuggestedTable(Database::"Warehouse Register");
        SetSuggestedTable(Database::"Warehouse Request");
        SetSuggestedTable(Database::"Warehouse Shipment Header");
        SetSuggestedTable(Database::"Warehouse Shipment Line");
        SetSuggestedTable(Database::"Warranty Ledger Entry");
        SetSuggestedTable(Database::"Whse. Internal Pick Header");
        SetSuggestedTable(Database::"Whse. Internal Pick Line");
        SetSuggestedTable(Database::"Whse. Internal Put-away Header");
        SetSuggestedTable(Database::"Whse. Internal Put-away Line");
        SetSuggestedTable(Database::"Whse. Item Entry Relation");
        SetSuggestedTable(Database::"Whse. Item Tracking Line");
        SetSuggestedTable(Database::"Whse. Pick Request");
        SetSuggestedTable(Database::"Whse. Put-away Request");
        SetSuggestedTable(Database::"Whse. Worksheet Line");
    end;

    local procedure SuggestMiscellaneousTables()
    begin
        SetSuggestedTable(Database::Attachment);
        SetSuggestedTable(Database::Attendee);
        SetSuggestedTable(Database::Job);
        SetSuggestedTable(Database::Opportunity);
    end;
}
