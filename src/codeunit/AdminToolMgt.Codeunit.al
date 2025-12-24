codeunit 51000 "Admin Tool Mgt."
{
    Permissions = tabledata "G/L Entry" = IMD, tabledata "Cust. Ledger Entry" = IMD, tabledata "Vendor Ledger Entry" = IMD, tabledata "Item Ledger Entry" = IMD, tabledata "Sales Header" = IMD,
                  tabledata "Sales Line" = IMD, tabledata "Purchase Header" = IMD, tabledata "Purchase Line" = IMD, tabledata "G/L Register" = IMD, tabledata "Item Register" = IMD,
                  tabledata "Gen. Journal Line" = IMD, tabledata "Sales Shipment Header" = IMD, tabledata "Sales Shipment Line" = IMD, tabledata "Sales Invoice Header" = IMD, tabledata "Sales Invoice Line" = IMD,
                  tabledata "Sales Cr.Memo Header" = IMD, tabledata "Sales Cr.Memo Line" = IMD, tabledata "Purch. Rcpt. Header" = IMD, tabledata "Purch. Rcpt. Line" = IMD, tabledata "Purch. Inv. Header" = IMD,
                  tabledata "Purch. Inv. Line" = IMD, tabledata "Purch. Cr. Memo Hdr." = IMD, tabledata "Purch. Cr. Memo Line" = IMD, tabledata "Job Ledger Entry" = IMD, tabledata "G/L Entry - VAT Entry Link" = IMD,
                  tabledata "VAT Entry" = IMD, tabledata "Bank Account Ledger Entry" = IMD, tabledata "Item Application Entry" = IMD, tabledata "Detailed Cust. Ledg. Entry" = IMD, tabledata "Detailed Vendor Ledg. Entry" = IMD,
                  tabledata "Value Entry" = IMD, tabledata "Return Shipment Header" = IMD, tabledata "Return Receipt Header" = IMD, tabledata "Record Deletion" = RIM, tabledata "Record Deletion Rel. Error" = RID,
                  tabledata "Admin Toolbox Setup" = R;


    procedure CalcRecordsInTable(TableNoToCheck: Integer): Integer
    var
        Field: Record Field;
        RecordRef: RecordRef;
        NoOfRecords: Integer;
    begin
        Field.SetRange(TableNo, TableNoToCheck);
        if not Field.IsEmpty() then begin
            RecordRef.Open(TableNoToCheck);
            RecordRef.ReadIsolation(IsolationLevel::UpdLock);
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
        CheckingRelationsTxt: Label 'Checking Relations Between Records!\Table: #1#######', Comment = '%1 = Table ID';
        CheckRelationsQst: Label 'Check Table Relations?';
    begin
        if not ConfirmManagement.GetResponseOrDefault(CheckRelationsQst, false) then
            exit;

        UpdateDialog.Open(CheckingRelationsTxt);
        RecordDeletionRelError.DeleteAll(false);

        if RecordDeletion.FindSet() then
            repeat
                UpdateDialog.Update(1, Format(RecordDeletion."Table ID"));
                CheckTableRelationsForTable(RecordDeletion."Table ID");
            until RecordDeletion.Next() = 0;

        UpdateDialog.Close();
    end;

    local procedure CheckTableRelationsForTable(TableID: Integer)
    var
        TableMetadata: Record "Table Metadata";
        RecordRef: RecordRef;
    begin
        // Only allow "normal" tables to avoid errors, Skip TableType MicrosoftGraph and CRM etc.
        TableMetadata.SetRange(ID, TableID);
        TableMetadata.SetRange(TableType, TableMetadata.TableType::Normal);
        if TableMetadata.IsEmpty() then
            exit;

        RecordRef.Open(TableID);
        if RecordRef.FindSet() then
            repeat
                CheckRecordRelations(RecordRef);
            until RecordRef.Next() = 0;
        RecordRef.Close();
    end;

    local procedure CheckRecordRelations(var RecordRef: RecordRef)
    var
        Field: Record Field;
    begin
        Field.SetRange(TableNo, RecordRef.Number());
        Field.SetRange(Class, Field.Class::Normal);
        Field.SetRange(ObsoleteState, Field.ObsoleteState::No);
        Field.SetFilter(RelationTableNo, '<>0');

        // Next 4 lines look funny but are needed to avoid this error:
        // "Table connection for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used"
        if RecordRef.Number() = 5330 then
            Field.SetFilter("No.", '<> %1', 124)
        else
            if RecordRef.Number() = 7200 then
                Field.SetFilter("No.", '<> %1', 124);

        if Field.FindSet() then
            repeat
                CheckFieldRelation(RecordRef, Field);
            until Field.Next() = 0;
    end;

    local procedure CheckFieldRelation(var RecordRef: RecordRef; Field: Record Field)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecordRef.Field(Field."No.");
        if (Format(FieldRef.Value()) <> '') and (Format(FieldRef.Value()) <> '0') then
            ValidateFieldRelation(RecordRef, FieldRef, Field);
    end;

    local procedure ValidateFieldRelation(var RecordRef: RecordRef; var FieldRef: FieldRef; Field: Record Field)
    var
        RecordRef2: RecordRef;
        FieldRef2: FieldRef;
        FieldRefInitialized: Boolean;
    begin
        RecordRef2.Open(Field.RelationTableNo);
        FieldRefInitialized := false;

        if Field.RelationFieldNo <> 0 then begin
            FieldRef2 := RecordRef2.Field(Field.RelationFieldNo);
            FieldRefInitialized := true;
        end else
            FieldRefInitialized := GetPrimaryKeyFieldRef(Field.RelationTableNo, RecordRef2, FieldRef2);

        if FieldRefInitialized then
            if (FieldRef.Type() = FieldRef2.Type()) and (FieldRef.Length() = FieldRef2.Length()) then
                CheckRelationExists(RecordRef, FieldRef, RecordRef2, FieldRef2);

        RecordRef2.Close();
    end;

    local procedure GetPrimaryKeyFieldRef(TableNo: Integer; var RecordRef2: RecordRef; var FieldRef2: FieldRef): Boolean
    var
        Field2: Record Field;
        KeyRec: Record "Key";
        CouldNotGetKeyErr: Label 'Could not get key for table %1', Comment = '%1 = Table ID';
    begin
        if not KeyRec.Get(TableNo, 1) then  // PK
            Error(CouldNotGetKeyErr, TableNo);

        Field2.SetRange(TableNo, TableNo);
        Field2.SetFilter(FieldName, CopyStr(KeyRec.Key, 1, 30));
        if Field2.FindFirst() then begin // No Match if Dual PK
            FieldRef2 := RecordRef2.Field(Field2."No.");
            exit(true);
        end;
        exit(false);
    end;

    local procedure CheckRelationExists(var RecordRef: RecordRef; var FieldRef: FieldRef; var RecordRef2: RecordRef; var FieldRef2: FieldRef)
    var
        RecordDeletionRelError: Record "Record Deletion Rel. Error";
        EntryNo: Integer;
        NotExistsTxt: Label '%1 => %2 = ''%3'' does not exist in the ''%4'' table', Comment = '%1 = Source Table Name, %2 = Source Field Name, %3 = Field Value, %4 = Target Table Name';
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
        MarkDeletionRemovedMsg: Label 'The checkbox %1 was succesfully reset for the tables.', Comment = '%1 = FieldCaption of "Delete Records"';
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
        OptionsLbl: Label 'Delete records without deletion trigger: Record.Delete(false),Delete records with deletion trigger: Record.Delete(true)';
    begin
        Selection := StrMenu(OptionsLbl, 1);
        if not ProcessDeletionSelection(Selection, RunTrigger) then
            exit;

        UpdateDialog.Open(GetDeletingRecordsText());

        ValidateRecordsMarkedForDeletion(RecordDeletion, UpdateDialog);
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
        DeletingRecordsTxt: Label 'Deleting Records!\Table: #1#######', Comment = '%1 = Table ID';
    begin
        exit(DeletingRecordsTxt);
    end;

    local procedure ValidateRecordsMarkedForDeletion(var RecordDeletion: Record "Record Deletion"; var UpdateDialog: Dialog)
    var
        NoRecsFoundErr: Label 'No tables were marked for deletion. Please make sure that you check the Field %1 in the tables where you want to delete records before you run this operation.',
                        Comment = '%1 = FieldCaption of "Delete Records"';
    begin
        RecordDeletion.SetRange("Delete Records", true);
        if RecordDeletion.IsEmpty() then begin
            UpdateDialog.Close();
            Error(NoRecsFoundErr, RecordDeletion.FieldCaption("Delete Records"));
        end;

        ConfirmDeletion(RecordDeletion, UpdateDialog);
    end;

    local procedure ConfirmDeletion(var RecordDeletion: Record "Record Deletion"; var UpdateDialog: Dialog)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        DeleteRecordsQst: Label '%1 table(s) were marked for deletion. All records in these tables will be deleted. Continue?', Comment = '%1 = No. of tables';
        CancelledByUserErr: Label 'The operation was cancelled by the user.';
        ConfirmMessage: Text;
    begin
        ConfirmMessage := StrSubstNo(DeleteRecordsQst, RecordDeletion.Count());
        if not ConfirmManagement.GetResponseOrDefault(ConfirmMessage, false) then begin
            UpdateDialog.Close();
            Error(CancelledByUserErr);
        end;
    end;

    local procedure PerformDeletion(var RecordDeletion: Record "Record Deletion"; var RecordDeletionRelError: Record "Record Deletion Rel. Error"; RunTrigger: Boolean; var UpdateDialog: Dialog)
    var
        RecordRef: RecordRef;
    begin
        if RecordDeletion.FindSet() then
            repeat
                UpdateDialog.Update(1, Format(RecordDeletion."Table ID"));
                RecordRef.Open(RecordDeletion."Table ID");
                RecordRef.DeleteAll(RunTrigger);
                RecordRef.Close();
                RecordDeletionRelError.SetRange("Table ID", RecordDeletion."Table ID");
                RecordDeletionRelError.DeleteAll(false);
            until RecordDeletion.Next() = 0;
    end;

    local procedure ShowDeletionSuccessMessage(var RecordDeletion: Record "Record Deletion")
    var
        DeletionSuccessMsg: Label 'The records from %1 table(s) were succesfully deleted.', Comment = '%1 = No. of tables';
    begin
        Message(DeletionSuccessMsg, RecordDeletion.Count());
    end;

    procedure InsertUpdateTables()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        RecordDeletion: Record "Record Deletion";
        UpdateDialog: Dialog;
        CurrRec, NoOfRecs : Integer;
        NoRecordFoundMsg: Label 'No record could be found in table %1.', Comment = '%1 = Table Caption';
        ProcessingDataTxt: Label 'Processing tables... @1@@@@@@';
        UpdateFinishedMsg: Label '%1 tables have succesfully been updated.', Comment = '%1 = No. of tables';
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        // Do not include system tables
        AllObjWithCaption.SetFilter("Object ID", '< %1', 2000000001);
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
                RecordDeletion.Insert(false); // Ignore if already exists
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
        InstructionsLbl: Label 'The external deployer must be installed on the server instance to publish apps. Please select how to proceed.';
        OptionsLbl: Label 'Continue publishing app (a new tab will be opened),Learn how to install the external deployer';
        WebUrl: Text;
        PageUrlTxt: Label '%1/?page=%2', Comment = '%1 = Web URL, %2 = Page ID';
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
        if RecordDeletion.Get(TableID) then begin
            RecordDeletion."Delete Records" := true;
            RecordDeletion.Modify(false);
        end;
    end;

    procedure SuggestRecordsToDelete()
    var
        Selection: Integer;
        OptionsLbl: Label 'Suggest all transactional records to delete,Suggest unlicensed partner or custom records to delete';
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
        PowershellMgt: Codeunit "Powershell Mgt.";
        ConfirmManagement: Codeunit "Confirm Management";
        RecsSuggestedCount: Integer;
        ImportCustLicenseQst: Label 'It looks like a developer license is currently imported. The use of this function is intended for customer licenses. Do you want to import another license now?';
        ImportLicenseQst: Label 'A developer license will be required to delete the marked unlicensed records. Do you want to import another license now?';
        RecordsSuggestedMsg: Label '%1 unlicensed partner or custom records were suggested.', Comment = '%1 Number of unlicensed records';
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
        DevLicenseMsg: Label 'Attention, the developer license is currently active.';
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
        RecordsWereSuggestedMsg: Label '%1 records to delete were suggested.', Comment = '%1 = Number of suggested records';
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
