codeunit 51000 "Admin Tool Mgt."
{
    Permissions = TableData "17" = IMD, Tabledata "21" = IMD, Tabledata "25" = IMD, Tabledata "32" = IMD, Tabledata "36" = IMD,
                  Tabledata "37" = IMD, Tabledata "38" = IMD, Tabledata "39" = IMD, Tabledata "45" = IMD, Tabledata "46" = IMD,
                  Tabledata "81" = IMD, Tabledata "110" = IMD, TableData "111" = IMD, TableData "112" = IMD, TableData "113" = IMD,
                  TableData "114" = IMD, TableData "115" = IMD, TableData "120" = IMD, Tabledata "121" = IMD, Tabledata "122" = IMD,
                  Tabledata "123" = IMD, Tabledata "124" = IMD, Tabledata "125" = IMD, Tabledata "169" = IMD, Tabledata "253" = IMD,
                  Tabledata "254" = IMD, Tabledata "271" = IMD, Tabledata "339" = IMD, Tabledata "379" = IMD, Tabledata "380" = IMD,
                  Tabledata "5802" = IMD, tabledata "6650" = IMD, tabledata "6660" = IMD;


    procedure CalcRecordsInTable(TableNoToCheck: Integer): Integer
    var
        FieldRec: Record Field;
        RecRef: RecordRef;
        NoOfRecords: Integer;
    begin
        FieldRec.SetRange(TableNo, TableNoToCheck);
        if FieldRec.FindFirst() then begin
            RecRef.Open(TableNoToCheck);
            RecRef.LockTable();
            NoOfRecords := RecRef.Count();
            RecRef.Close();
            exit(NoOfRecords);
        end;
        exit(0);
    end;

    procedure CheckTableRelations();
    var
        Field, Field2 : Record Field;
        KeyRec: Record "Key";
        RecordDeletion: Record "Record Deletion";
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
        TableMetadata: Record "Table Metadata";
        RecRef, RecRef2 : RecordRef;
        FieldRef, FieldRef2 : FieldRef;
        SkipCheck: Boolean;
        Window: Dialog;
        EntryNo: Integer;
        NotExistsTxt: Label '%1 => %2 = ''%3'' does not exist in the ''%4'' table';
        CheckingRelationsTxt: Label 'Checking Relations Between Records!\Table: #1#######', Comment = '%1 = Table ID';
        CheckRelationsQst: Label 'Check Table Relations?';
    begin
        if not Confirm(CheckRelationsQst, false) then
            exit;

        Window.Open(CheckingRelationsTxt);

        RecordDeletionRelError.DeleteAll();

        if RecordDeletion.FindSet() then
            repeat
                Window.Update(1, Format(RecordDeletion."Table ID"));
                // Only allow "normal" tables to avoid errors, Skip TableType MicrosoftGraph and CRM etc.
                TableMetadata.SetRange(ID, RecordDeletion."Table ID");
                TableMetadata.SetRange(TableType, TableMetadata.TableType::Normal);
                if not TableMetadata.IsEmpty then begin
                    RecRef.Open(RecordDeletion."Table ID");
                    if RecRef.FindSet() then
                        repeat
                            Field.SetRange(TableNo, RecordDeletion."Table ID");
                            Field.SetRange(Class, Field.Class::Normal);
                            Field.SetFilter(RelationTableNo, '<>0');
                            if Field.FindSet() then
                                repeat
                                    FieldRef := RecRef.Field(Field."No.");
                                    if (Format(FieldRef.Value) <> '') and (FORMAT(FieldRef.Value) <> '0') then begin
                                        RecRef2.Open(Field.RelationTableNo);
                                        SkipCheck := false;
                                        if Field.RelationFieldNo <> 0 then begin
                                            FieldRef2 := RecRef2.Field(Field.RelationFieldNo)
                                        end else begin
                                            KeyRec.Get(Field.RelationTableNo, 1);  // PK
                                            Field2.SetRange(TableNo, Field.RelationTableNo);
                                            Field2.SetFilter(FieldName, CopyStr(KeyRec.Key, 1, 30));
                                            if Field2.FindFirst() then // No Match if Dual PK
                                                FieldRef2 := RecRef2.Field(Field2."No.")
                                            else
                                                SkipCheck := true;
                                        end;
                                        if (FieldRef.Type = FieldRef2.Type) and (FieldRef.Length = FieldRef2.Length) and (not SkipCheck) then begin
                                            FieldRef2.SetRange(FieldRef.Value);
                                            if not RecRef2.FindFirst() then begin
                                                RecordDeletionRelError.SetRange("Table ID", RecRef.Number);
                                                if RecordDeletionRelError.FindLast() then
                                                    EntryNo := RecordDeletionRelError."Entry No." + 1
                                                else
                                                    EntryNo := 1;
                                                RecordDeletionRelError.Init();
                                                RecordDeletionRelError."Table ID" := RecRef.Number;
                                                RecordDeletionRelError."Entry No." := EntryNo;
                                                RecordDeletionRelError."Field No." := FieldRef.Number;
                                                RecordDeletionRelError.Error := CopyStr(StrSubstNo(NotExistsTxt, Format(RecRef.GetPosition()), Format(FieldRef2.Name), Format(FieldRef.Value), Format(RecRef2.Name)), 1, 250);
                                                RecordDeletionRelError.Insert();
                                            end;
                                        end;
                                        RecRef2.Close();
                                    end;
                                until Field.Next() = 0;
                        until RecRef.Next() = 0;
                    RecRef.Close();
                end;
            until RecordDeletion.Next() = 0;
        Window.Close();
    end;

    procedure ClearRecordsToDelete();
    var
        RecordDeletion: Record "Record Deletion";
        MarkDeletionRemovedMsg: Label 'The checkbox %1 was succesfully reset for the tables.';
    begin
        RecordDeletion.ModifyAll("Delete Records", false);
        Message(MarkDeletionRemovedMsg, RecordDeletion.FieldCaption("Delete Records"));
    end;

    procedure DeleteRecords();
    var
        RecordDeletion: Record "Record Deletion";
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
        RecRef: RecordRef;
        RunTrigger: Boolean;
        Window: Dialog;
        Selection: Integer;
        DeleteRecordsQst: Label '%1 table(s) were marked for deletion. All records in these tables will be deleted. Continue?';
        Options: Label 'Delete records without deletion trigger: Record.Delete(false),Delete records with deletion trigger: Record.Delete(true)';
        DeletingRecordsTxt: Label 'Deleting Records!\Table: #1#######', Comment = '%1 = Table ID';
        NoRecsFoundErr: Label 'No tables were marked for deletion. Please make sure that you check the Field %1 in the tables where you want to delete records before you run this operation.';
        CancelledByUserErr: Label 'The operation was cancelled by the user.';
        DeletionSuccessMsg: Label 'The records from %1 table(s) were succesfully deleted.';
    begin
        Selection := StrMenu(Options, 1);
        case Selection of
            0: // Cancelled
               //     Error(CancelledByUserErr);
                exit;
            1: // Without trigger
                Clear(Runtrigger);
            2: // With trigger
                RunTrigger := true;
        end;

        Window.Open(DeletingRecordsTxt);

        RecordDeletion.SetRange("Delete Records", true);

        if RecordDeletion.Count() = 0 then
            Error(StrSubstNo(NoRecsFoundErr, RecordDeletion.FieldCaption("Delete Records")));

        if not Confirm(StrSubstNo(DeleteRecordsQst, RecordDeletion.Count()), false) then
            Error(CancelledByUserErr);

        if RecordDeletion.FindSet() then
            repeat
                Window.Update(1, Format(RecordDeletion."Table ID"));
                RecRef.Open(RecordDeletion."Table ID");
                RecRef.DeleteAll(RunTrigger);
                RecRef.Close();
                RecordDeletionRelError.SetRange("Table ID", RecordDeletion."Table ID");
                RecordDeletionRelError.DeleteAll();
            until RecordDeletion.Next() = 0;


        Window.Close();
        Message(StrSubstNo(DeletionSuccessMsg, RecordDeletion.Count()));
    end;

    procedure InsertUpdateTables();
    var
        AllObjWithCaption: Record AllObjWithCaption;
        RecordDeletion: Record "Record Deletion";
        Window: Dialog;
        CurrRec, NoOfRecs : Integer;
        UpdateFinishedMsg: Label '%1 tables have succesfully been updated.';
        NoRecordFoundMsg: Label 'No record could be found in table %1.';
        ProcessingDataTxt: Label 'Processing tables... @1@@@@@@';
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        // Do not include system tables
        AllObjWithCaption.SetFilter("Object ID", '< %1', 2000000001);
        if AllObjWithCaption.FindSet() then begin
            Window.Open(ProcessingDataTxt);
            NoOfRecs := AllObjWithCaption.Count();
            repeat
                CurrRec += 1;
                if NoOfRecs <= 100 then
                    Window.Update(1, (CurrRec / NoOfRecs * 10000) div 1)
                else
                    if CurrRec mod (NoOfRecs div 100) = 0 then
                        Window.Update(1, (CurrRec / NoOfRecs * 10000) div 1);

                RecordDeletion.Init();
                RecordDeletion."Table ID" := AllObjWithCaption."Object ID";
                RecordDeletion.Company := CompanyName;
                if RecordDeletion.Insert() then;
            until AllObjWithCaption.Next() = 0;
            Message(UpdateFinishedMsg, CurrRec);
        end else
            Message(NoRecordFoundMsg, AllObjWithCaption.TableCaption());
    end;

    procedure OpenTable(TableId: Integer)
    var
        WebUrl: Text;
    begin
        WebUrl := System.GetUrl(ClientType::Web);
        if WebUrl.Contains('?') then
            WebUrl := StrSubstNo('%1&table=%2', WebUrl, TableId)
        else
            WebUrl := StrSubstNo('%1/?table=%2', WebUrl, TableId);
        Hyperlink(WebUrl);
    end;

    procedure PublishApp()
    var
        WebUrl: Text;
        Selection: Integer;
        Options: Label 'Continue publishing app (a new tab will be opened),Learn how to install the external deployer';
        Instructions: Label 'The external deployer must be installed on the server instance to publish apps. Please select how you want to proceed.';
    begin
        Selection := StrMenu(Options, 1, Instructions);
        case Selection of
            1:
                begin
                    WebUrl := StrSubstNo('%1/?page=%2', System.GetUrl(ClientType::Web), 2507);
                    Hyperlink(WebUrl);
                end;
            2:
                begin
                    OpenDeployerReadme();
                end;
            else
                exit;
        // Error(CancelledByUserErr);
        end;
    end;

    procedure SetSuggestedTable(TableID: Integer);
    var
        RecordDeletion: Record "Record Deletion";
    begin
        if RecordDeletion.Get(TableID) then begin
            RecordDeletion."Delete Records" := true;
            RecordDeletion.Modify();
        end;
    end;

    procedure SuggestRecordsToDelete();
    var
        Selection: Integer;
        Options: Label 'Suggest all transactional records to delete,Suggest unlicensed partner or custom records to delete';
    begin
        Selection := StrMenu(Options, 1);
        case Selection of
            // 0: // Cancelled
            //     Error(CancelledByUserErr);
            1: // Transactional
                SuggestTransactionalRecordsToDelete();
            2: // Unlicensed
                SuggestUnlicensedPartnerOrCustomRecordsToDelete();
        end;
    end;

    procedure SuggestUnlicensedPartnerOrCustomRecordsToDelete();
    var
        RecordDeletion: Record "Record Deletion";
        RecsSuggestedCount: Integer;
        RecordsSuggestedMsg: Label '%1 unlicensed partner or custom records were suggested.', Comment = '%1 Number of unlicensed records';
        ImportLicenseQst: Label 'A developer license will be required to delete the marked unlicensed records. Do you want to import another license now?';
        ImportCustLicenseQst: Label 'It looks like a developer license is currently imported. The use of this function is intended for customer licenses. Do you want to import another license now?';
        PowershellMgt: Codeunit "Powershell Mgt.";
    begin
        if IsDeveloperLicense() then
            if Confirm(ImportCustLicenseQst, false) then
                PowershellMgt.ImportLicense();

        RecordDeletion.SetFilter("Table ID", '> %1', 49999);
        if RecordDeletion.FindSet(false) then
            repeat
                if not IsRecordStandardTable(RecordDeletion."Table ID") then
                    if not IsRecordInLicense(RecordDeletion."Table ID") then begin
                        SetSuggestedTable(RecordDeletion."Table ID");
                        RecsSuggestedCount += 1;
                    end;
            until RecordDeletion.Next() = 0;

        Message(RecordsSuggestedMsg, RecsSuggestedCount);
        if Confirm(ImportLicenseQst, false) then
            PowershellMgt.ImportLicense();
    end;

    procedure ViewRecords(RecordDeletion: Record "Record Deletion");
    begin
        Hyperlink(GetUrl(ClientType::Current, CompanyName, ObjectType::Table, RecordDeletion."Table ID"));
    end;

    internal procedure GetTableCaption(TableID: Integer): Text[249]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", TableID);
        AllObjWithCaption.FindFirst();
        exit(AllObjWithCaption."Object Caption");
    end;

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

    local procedure IsRecordInLicense(TableID: Integer): Boolean
    var
        LicensePermission: Record "License Permission";
    begin
        // LicensePermission.Get(LicensePermission."Object Type"::Table, TableID);
        LicensePermission.Get(LicensePermission."Object Type"::TableData, TableID);
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
        case true of
            //5005270 - 5005363 'de' localization
            (TableID >= 5005270) and (TableID <= 5005363):
                exit(true);
            //7000002 - 7000024 'es' localization
            (TableID >= 7000002) and (TableID <= 7000024):
                exit(true);
            //99000750 - 99008535
            (TableID >= Database::"Work Shift") and (TableID <= 99008535):
                exit(true);
            // Microsoft Localizations
            (TableID >= 100000) and (TableID <= 999999):
                exit(true);
        end;
        exit(false);
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

    internal procedure ShowDevLicenseMessageIfNeeded()
    var
        AdminToolSetup: Record "Admin Toolbox Setup";
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        DevLicenseMsg: Label 'Attention, the developer license is currently active.';
    begin
        if not AdminToolSetup.Get() then
            exit;

        if AdminToolMgt.IsDeveloperLicense() and AdminToolSetup."Developer License Warning" then
            Message(DevLicenseMsg);
    end;

    local procedure SuggestTransactionalRecordsToDelete()
    var
        RecordDeletion: Record "Record Deletion";
        AfterSuggestionDeleteCount, BeforeSuggestionDeleteCount : Integer;
        RecordsWereSuggestedMsg: Label '%1 records to delete were suggested.', Comment = '%1 = Number of suggested records';
    begin
        RecordDeletion.SetRange("Delete Records", true);
        BeforeSuggestionDeleteCount := RecordDeletion.Count();

        SetSuggestedTable(Database::"Action Message Entry");
        SetSuggestedTable(Database::"Analysis View Budget Entry");
        SetSuggestedTable(Database::"Analysis View Entry");
        SetSuggestedTable(Database::"Analysis View");
        SetSuggestedTable(Database::"Approval Comment Line");
        SetSuggestedTable(Database::"Approval Entry");
        SetSuggestedTable(Database::"Assemble-to-Order Link");
        SetSuggestedTable(Database::"Assembly Comment Line");
        SetSuggestedTable(Database::"Assembly Header");
        SetSuggestedTable(Database::"Assembly Line");
        SetSuggestedTable(Database::"Avg. Cost Adjmt. Entry Point");
        SetSuggestedTable(Database::"Bank Acc. Reconciliation Line");
        SetSuggestedTable(Database::"Bank Acc. Reconciliation");
        SetSuggestedTable(Database::"Bank Account Ledger Entry");
        SetSuggestedTable(Database::"Bank Account Ledger Entry");
        SetSuggestedTable(Database::"Bank Account Statement Line");
        SetSuggestedTable(Database::"Bank Account Statement");
        SetSuggestedTable(Database::"Bank Stmt Multiple Match Line");
        SetSuggestedTable(Database::"Campaign Entry");
        SetSuggestedTable(Database::"Capacity Ledger Entry");
        SetSuggestedTable(Database::"Cash Flow Manual Revenue");
        SetSuggestedTable(Database::"Cash Flow Manual Expense");
        SetSuggestedTable(Database::"Cash Flow Forecast Entry");
        SetSuggestedTable(Database::"Cash Flow Worksheet Line");
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
        SetSuggestedTable(Database::"Cust. Ledger Entry");
        SetSuggestedTable(Database::"Date Compr. Register");
        SetSuggestedTable(Database::"Detailed Cust. Ledg. Entry");
        SetSuggestedTable(Database::"Detailed Vendor Ledg. Entry");
        SetSuggestedTable(Database::"Dimension Set Entry");
        SetSuggestedTable(Database::"Dimension Set Tree Node");
        SetSuggestedTable(Database::"Direct Debit Collection Entry");
        SetSuggestedTable(Database::"Direct Debit Collection");
        // SetSuggestedTable(Database::"DO Payment Trans. Log Entry");
        SetSuggestedTable(Database::"Document Entry");
        SetSuggestedTable(Database::"Email Item");
        SetSuggestedTable(Database::"Employee Absence");
        SetSuggestedTable(Database::"Error Buffer");
        SetSuggestedTable(Database::"Error Message");
        SetSuggestedTable(Database::"Error Message Register");
        SetSuggestedTable(Database::"Exch. Rate Adjmt. Reg.");
        SetSuggestedTable(Database::"FA G/L Posting Buffer");
        SetSuggestedTable(Database::"FA Ledger Entry");
        SetSuggestedTable(Database::"FA Register");
        SetSuggestedTable(Database::"Filed Contract Line");
        SetSuggestedTable(Database::"Filed Service Contract Header");
        SetSuggestedTable(Database::"Fin. Charge Comment Line");
        SetSuggestedTable(Database::"Finance Charge Memo Header");
        SetSuggestedTable(Database::"Finance Charge Memo Line");
        SetSuggestedTable(Database::"G/L - Item Ledger Relation");
        SetSuggestedTable(Database::"G/L Budget Entry");
        SetSuggestedTable(Database::"G/L Budget Name");
        SetSuggestedTable(Database::"G/L Entry - VAT Entry Link");
        SetSuggestedTable(Database::"G/L Entry");
        SetSuggestedTable(Database::"G/L Register");
        SetSuggestedTable(Database::"Gen. Jnl. Allocation");
        SetSuggestedTable(Database::"Gen. Journal Line");
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
        SetSuggestedTable(Database::"Incoming Document");
        SetSuggestedTable(Database::"Ins. Coverage Ledger Entry");
        SetSuggestedTable(Database::"Insurance Register");
#pragma warning disable AL0432
        SetSuggestedTable(Database::"Integration Record");
        SetSuggestedTable(Database::"Integration Record Archive");
#pragma warning restore AL0432
        SetSuggestedTable(Database::"Inter. Log Entry Comment Line");
        SetSuggestedTable(Database::"Interaction Log Entry");
        SetSuggestedTable(Database::"Internal Movement Header");
        SetSuggestedTable(Database::"Internal Movement Line");
        SetSuggestedTable(Database::"Intrastat Jnl. Line");
        SetSuggestedTable(Database::"Inventory Adjmt. Entry (Order)");
        SetSuggestedTable(Database::"Inventory Period Entry");
        SetSuggestedTable(Database::"Inventory Report Entry");
        SetSuggestedTable(Database::"Issued Fin. Charge Memo Header");
        SetSuggestedTable(Database::"Issued Fin. Charge Memo Line");
        SetSuggestedTable(Database::"Issued Reminder Header");
        SetSuggestedTable(Database::"Issued Reminder Line");
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
        SetSuggestedTable(Database::"Job Entry No.");
        // SetSuggestedTable(Database::"Job G/L Account Price");
        // SetSuggestedTable(Database::"Job Item Price");
        SetSuggestedTable(Database::"Job Journal Line");
        SetSuggestedTable(Database::"Job Ledger Entry");
        SetSuggestedTable(Database::"Job Planning Line Invoice");
        SetSuggestedTable(Database::"Job Planning Line");
        SetSuggestedTable(Database::"Job Queue Log Entry");
        SetSuggestedTable(Database::"Job Register");
        // SetSuggestedTable(Database::"Job Resource Price");
        SetSuggestedTable(Database::"Job Task Dimension");
        SetSuggestedTable(Database::"Job Task");
        SetSuggestedTable(Database::"Job Task");
        SetSuggestedTable(Database::"Job Usage Link");
        SetSuggestedTable(Database::"Job WIP Entry");
        SetSuggestedTable(Database::"Job WIP G/L Entry");
        SetSuggestedTable(Database::"Job WIP Total");
        SetSuggestedTable(Database::"Job WIP Warning");
        SetSuggestedTable(Database::"Loaner Entry");
        SetSuggestedTable(Database::"Lot No. Information");
        SetSuggestedTable(Database::"Maintenance Ledger Entry");
        SetSuggestedTable(Database::"Maintenance Registration");
        SetSuggestedTable(Database::"My Notifications");
        SetSuggestedTable(Database::"Opportunity Entry");
        SetSuggestedTable(Database::"Order Promising Line");
        SetSuggestedTable(Database::"Order Tracking Entry");
        // SetSuggestedTable(Database::"Overdue Notification Entry");
        SetSuggestedTable(Database::"Payable Vendor Ledger Entry");
        SetSuggestedTable(Database::"Payment Application Proposal");
        SetSuggestedTable(Database::"Payment Export Data");
        SetSuggestedTable(Database::"Payment Jnl. Export Error Text");
        SetSuggestedTable(Database::"Payment Matching Details");
        SetSuggestedTable(Database::"Phys. Inventory Ledger Entry");
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
        // SetSuggestedTable(Database::"Posting Exch. Field");
        // SetSuggestedTable(Database::"Posting Exch.");
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
        SetSuggestedTable(Database::"Registered Invt. Movement Hdr.");
        SetSuggestedTable(Database::"Registered Invt. Movement Line");
        SetSuggestedTable(Database::"Registered Whse. Activity Hdr.");
        SetSuggestedTable(Database::"Registered Whse. Activity Line");
        SetSuggestedTable(Database::"Reminder Comment Line");
        SetSuggestedTable(Database::"Reminder Header");
        SetSuggestedTable(Database::"Reminder Line");
        SetSuggestedTable(Database::"Reminder/Fin. Charge Entry");
        SetSuggestedTable(Database::"Requisition Line");
        SetSuggestedTable(Database::"Res. Capacity Entry");
        SetSuggestedTable(Database::"Res. Journal Line");
        SetSuggestedTable(Database::"Res. Ledger Entry");
        SetSuggestedTable(Database::"Reservation Entry");
        SetSuggestedTable(Database::"Resource Register");
        SetSuggestedTable(Database::"Return Receipt Header");
        SetSuggestedTable(Database::"Return Receipt Line");
        SetSuggestedTable(Database::"Return Shipment Header");
        SetSuggestedTable(Database::"Return Shipment Line");
        SetSuggestedTable(Database::"Returns-Related Document");
        SetSuggestedTable(Database::"Reversal Entry");
        SetSuggestedTable(Database::"Rounding Residual Buffer");
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
        // SetSuggestedTable(Database::"Service E-Mail Queue");
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
        SetSuggestedTable(Database::Attachment);
        SetSuggestedTable(Database::Attendee);
        SetSuggestedTable(Database::Job);
        SetSuggestedTable(Database::Opportunity);

        // COSMO Tables
        // DMS
        // SetSuggestedTable(5306025); // CCS DMS Metadata 
        // SetSuggestedTable(5306030); // CCS DMS Document Entry

        // Mobile Solution
        // SetSuggestedTable(5307960); // MS - Mobile Scan Log Entry

        RecordDeletion.SetRange("Delete Records", true);
        AfterSuggestionDeleteCount := RecordDeletion.Count();
        Message(RecordsWereSuggestedMsg, AfterSuggestionDeleteCount - BeforeSuggestionDeleteCount);
    end;

    internal procedure UpdateTablesIfEmpty()
    var
        RecordDeletion: Record "Record Deletion";
        UpdateTablesQst: Label 'The overview of all tables is empty so so far. Do you want to get the current state of all tables in the database?';
    begin
        if not RecordDeletion.IsEmpty() then
            exit;

        // if Confirm(UpdateTablesQst, true) then
        InsertUpdateTables();
    end;

    internal procedure UserHasPermissions(): Boolean
    var
        AdminToolSetup: Record "Admin Toolbox Setup";
    begin
        exit(AdminToolSetup.ReadPermission());
    end;
}
