page 51004 "Table Editor"
{
    AboutText = 'This table editor can modify or delete selected records.';
    AboutTitle = 'About Table Editor';
    AccessByPermission = tabledata "Item Ledger Entry" = MD;
    AdditionalSearchTerms = 'Debug';
    ApplicationArea = All;
    Caption = 'Table Editor';
    PageType = Card;
    Permissions = tabledata "Reservation Entry" = IMD;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(TableSettings)
            {
                Caption = 'Table';

                field(TableNoField; TableNo)
                {
                    BlankZero = true;
                    Caption = 'ID';
                    TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
                    ToolTip = 'Specifies the ID of the table where you want to modify or delete records.';

                    trigger OnValidate()
                    begin
                        ClearTableVariables();
                        GetTableCaption();
                        UpdateTableNoOfRecords();
                    end;
                }
                field(TableCaptionField; TableCaption)
                {
                    Caption = 'Caption';
                    Editable = false;
                    ToolTip = 'Specifies the caption of the table where you want to modify or delete records.';
                }
                field(UseTableTriggerField; UseTableTrigger)
                {
                    AboutText = 'Enable this field if you want to use the table triggers when modifying or deleting records.';
                    AboutTitle = 'Do you want to use table triggers?';
                    Caption = 'Use Trigger';
                    Enabled = not RenameRequired;
                    ToolTip = 'Specifies if you want to run the trigger of the table that you want to modify or delete.';
                }
                field(CustomTableViewField; CustomTableView)
                {
                    AboutText = 'Select all the records that you want to modify or delete';
                    AboutTitle = 'Record Selection';
                    Caption = 'View';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the selected records.';

                    trigger OnAssistEdit()
                    begin
                        GetTableFilter();
                    end;
                }
                field(CustomTableNoOfRecordsField; TableNoOfRecords)
                {
                    AboutText = 'Shows how many records you selected in the previous field.';
                    AboutTitle = 'No. of your selected records';
                    Caption = 'Records in Filter';
                    Editable = false;
                    ToolTip = 'Specifies the no. of records that you selected.';

                    trigger OnDrillDown()
                    begin
                        ShowCustomTable();
                    end;
                }
            }
            group(FieldSettings)
            {
                Caption = 'Field';

                field(FieldNumberField; FieldNumber)
                {
                    AboutText = 'Select the field if you want to modify a field for the selected records';
                    AboutTitle = 'Field selector';
                    BlankZero = true;
                    Caption = 'No.';
                    ToolTip = 'Specifies field no. that you want to modify.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(OnLookupFieldNumber(Text));
                    end;

                    trigger OnValidate()
                    begin
                        GetFieldNameAndCaption();
                        RenameRequired := FieldIndexInPrimaryKey() > 0;
                    end;
                }
                field(FieldValueField; FieldValue)
                {
                    AboutText = 'This is the value that the field will have for the selected records after modifying them.';
                    AboutTitle = 'Choose the new value';
                    Caption = 'Value';
                    ToolTip = 'Specifies the value that the field should have after modifying it.';

                    trigger OnValidate()
                    begin
                        OnValidateFieldValue();
                    end;
                }
                field(UseValidateTriggerField; UseValidateTrigger)
                {
                    AboutText = 'Enable this field if you want to use the OnValidate Trigger of the field when modifying the records.';
                    AboutTitle = 'Enable OnValidateTrigger';
                    Caption = 'Validate';
                    Enabled = not RenameRequired;
                    ToolTip = 'Specifies if you want to use the OnValidate trigger of the field.';
                }
                field(FieldNameField; FieldName)
                {
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies name of the selected field.';
                }
                field(FieldCaptionField; FieldCaption)
                {
                    Caption = 'Caption';
                    Editable = false;
                    ToolTip = 'Specifies caption of the selected field.';
                }
                field(FieldTypeNameField; FieldTypeName)
                {
                    Caption = 'Type';
                    Editable = false;
                    ToolTip = 'Specifies the value of the Type field.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteRecordsAction)
            {
                AboutText = 'This will delete all the records that you selected in the field "View"';
                AboutTitle = 'Delete Records';
                Caption = 'Delete Table Records';
                Ellipsis = true;
                Enabled = TableNo > 0;
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Deletes the selected records.';

                trigger OnAction()
                begin
                    DeleteTableRecords();
                end;
            }
            action(ModifyRecordsAction)
            {
                AboutText = 'This will modify all the records that you selected in the field "View"';
                AboutTitle = 'Modify Records';
                Caption = 'Modify Table Records';
                Ellipsis = true;
                Enabled = FieldNumber > 0;
                Image = Apply;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Modifies the selected records.';

                trigger OnAction()
                begin
                    if RenameRequired then
                        RenameTableRecords()
                    else
                        ModifyTableRecords();
                end;
            }
            action(CreateRecordAction)
            {
                Caption = 'Create Record';
                Enabled = TableNo > 0;
                Image = Add;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Executes the Create Record action.';

                trigger OnAction()
                begin
                    CreateRecord();
                end;
            }
            action(FindLongestValueAction)
            {
                Caption = 'Find Longest Value';
                Enabled = (TableNo > 0) and (FieldNumber > 0);
                Image = Find;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Finds the longest value of a field in the table.';

                trigger OnAction()
                begin
                    FindLongestValue();
                end;
            }
        }
    }

    var
        RenameRequired: Boolean;
        UseTableTrigger, UseValidateTrigger : Boolean;
        FieldNumber, TableNo, TableNoOfRecords : Integer;
        CreateRecord2Qst: Label 'Proceed?';
        CreateRecordQst: Label 'Do you want to create a new record in table %1?', Comment = '%1 = Table Caption';
        DeleteRecordsQst: Label 'Do you want to delete %1 records from table %2?', Comment = '%1 = No. of Records, %2 = Table Caption';
        DeleteWithTriggerQst: Label 'Records will be deleted using DeleteAll(%1).\\Proceed?', Comment = '%1 = UseTrigger (Boolean)';
        DoneMsg: Label 'Done.';
        FilterTableOnEachPKFieldMsg: Label 'Filter each primary key field with a constant value. Only then a new record can be created using those values.';
        MaxLengthMsg: Label 'Longest value has %1 characters.\%2', Comment = '%1 = No. of characters, %2 = Value';
        ModifyRecordsQst: Label 'Do you want to modify %1 records in table %2?', Comment = '%1 = No. of Records, %2 = Table Caption';
        ModifyRecordsWithoutValidateQst: Label '"%1" := [%2];\Modify(%3);\\Proceed?', Comment = '%1 = Field Name, %2 = Field Value, %3 = UseTrigger (Boolean)';
        ModifyRecordsWithValidateQst: Label 'Validate("%1", [%2]);\Modify(%3);\\Proceed?', Comment = '%1 = Field Name, %2 = Field Value, %3 = UseTrigger (Boolean)';
        NoRecordsFoundMsg: Label 'No records found.';
        RenameRecords2Qst: Label 'Rename(%1);\\Proceed?', Comment = '%1 = Primary Key Fields';
        RenameRecordsQst: Label 'Do you want to rename %1 records in table %2?', Comment = '%1 = No. of Records, %2 = Table Caption';
        CustomTableView, TableCaption : Text;
        FieldCaption, FieldName, FieldTypeName, FieldValue : Text;

    trigger OnOpenPage()
    begin
        UpdateTableNoOfRecords();
    end;

    local procedure ClearTableVariables()
    begin
        Clear(TableCaption);
        Clear(CustomTableView);
        Clear(TableNoOfRecords);
    end;

    local procedure GetTableCaption()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", TableNo);
        if not AllObjWithCaption.FindFirst() then
            TableCaption := '';
        TableCaption := AllObjWithCaption."Object Caption";
    end;

    local procedure GetTableFilter()
    var
        RecordRef: RecordRef;
        FilterPageBuilder: FilterPageBuilder;
        i: Integer;
    begin
        GetTableCaption();

        RecordRef.Open(TableNo);

        FilterPageBuilder.AddTable(TableCaption, TableNo);
        if CustomTableView <> '' then
            FilterPageBuilder.SetView(TableCaption, CustomTableView)
        else
            for i := 1 to RecordRef.KeyIndex(1).FieldCount() do
                FilterPageBuilder.AddField(TableCaption, RecordRef.KeyIndex(1).FieldIndex(i));

        if FilterPageBuilder.RunModal() then
            CustomTableView := FilterPageBuilder.GetView(TableCaption, false);
        RecordRef.SetView(CustomTableView);

        TableNoOfRecords := RecordRef.Count();
        RecordRef.Close();
    end;

    local procedure CreateRecord()
    var
        RecordRef: RecordRef;
        RecordRef2: RecordRef;
        i: Integer;
        PrimaryKeyRef: KeyRef;
        s: Text;
    begin
        RecordRef.Open(TableNo);
        RecordRef2.Open(TableNo);
        RecordRef.SetView(CustomTableView);
        TableNoOfRecords := RecordRef.Count();
        if not RecordRef.IsEmpty() then
            Error(FilterTableOnEachPKFieldMsg);

        s := 'Rec.Init();\';
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        for i := 1 to PrimaryKeyRef.FieldCount() do begin
            if PrimaryKeyRef.FieldIndex(i).GetFilter() = '' then
                Error(FilterTableOnEachPKFieldMsg);
            RecordRef2.Field(PrimaryKeyRef.FieldIndex(i).Number()).Value := PrimaryKeyRef.FieldIndex(i).GetRangeMin();
            s += 'Rec."' + PrimaryKeyRef.FieldIndex(i).Name() + '" := [' + Format(PrimaryKeyRef.FieldIndex(i).GetRangeMin()) + '];\';
        end;
        s += 'Rec.Insert(false);\\';

        if not Confirm(CreateRecordQst, false, TableCaption) then
            Error('');
        if not Confirm(s + CreateRecord2Qst, false) then
            Error('');

        // TODO: Bind locally defined codeunit with manual subscriber to codeunit 423 "Change Log Management", EventPublisher OnAfterIsAlwaysLoggedTable(TableID: Integer; var AlwaysLogTable: Boolean),
        //       set AlwaysLogTable := true in order to log all changes

        RecordRef2.Init();
        RecordRef2.Insert(false);
        TableNoOfRecords := RecordRef.Count();
        Message(DoneMsg);
        RecordRef.Close();
    end;

    local procedure DeleteTableRecords()
    var
        RecordRef: RecordRef;
        UpdateDialog: Dialog;
        CurrRec, NoOfRecs : Integer;
        ProcessingDataTxt: Label 'Processing tables... @1@@@@@@';
    begin
        RecordRef.Open(TableNo);
        RecordRef.SetView(CustomTableView);
        TableNoOfRecords := RecordRef.Count();
        if not Confirm(DeleteRecordsQst, false, TableNoOfRecords, TableCaption) then
            Error('');
        if not Confirm(DeleteWithTriggerQst, false, Format(UseTableTrigger, 0, 9)) then
            Error('');
        if RecordRef.FindSet() then begin
            UpdateDialog.Open(ProcessingDataTxt);
            NoOfRecs := RecordRef.Count();
            repeat
                CurrRec += 1;
                UpdateDeleteProgress(UpdateDialog, CurrRec, NoOfRecs);
                if RecordRef.Delete(UseTableTrigger) then begin
                    Commit(); // To avoid long transactions
                    TableNoOfRecords := RecordRef.Count();
                end;
            until RecordRef.Next() = 0;
        end;
        TableNoOfRecords := RecordRef.Count();
        Message(DoneMsg);
        RecordRef.Close();
    end;

    local procedure UpdateDeleteProgress(var UpdateDialog: Dialog; CurrRec: Integer; NoOfRecs: Integer)
    begin
        if NoOfRecs <= 100 then
            UpdateDialog.Update(1, (CurrRec / NoOfRecs * 10000) div 1)
        else
            if CurrRec mod (NoOfRecs div 100) = 0 then
                UpdateDialog.Update(1, (CurrRec / NoOfRecs * 10000) div 1);
    end;

    local procedure ShowCustomTable()
    var
        PageManagement: Codeunit "Page Management";
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableNo);
        RecordRef.SetView(CustomTableView);
        PageManagement.PageRun(RecordRef);
        RecordRef.Close();
    end;

    // local procedure ClearFieldVariables()
    // begin
    //     Clear(FieldNumber);
    //     Clear(FieldName);
    //     Clear(FieldCaption);
    //     Clear(FieldValue);
    //     Clear(FieldTypeName);
    // end;

    local procedure OnLookupFieldNumber(var Text: Text): Boolean
    var
        FieldRec: Record Field;
        FieldsLookup: Page "Fields Lookup";
    begin
        FieldRec.SetRange(TableNo, TableNo);
        FieldRec.SetFilter(ObsoleteState, '<> %1', FieldRec.ObsoleteState::Removed);
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetFilter(Type, '<> %1 & <> %2 & <> %3', FieldRec.Type::BLOB, FieldRec.Type::Media, FieldRec.Type::MediaSet);

        if Text <> '' then
            FieldRec.SetFilter("No.", Text);
        if FieldRec.FindFirst() then; // Find first record if available for lookup positioning
        FieldRec.SetRange("No.");

        FieldsLookup.LookupMode(true);
        FieldsLookup.SetTableView(FieldRec);
        FieldsLookup.SetRecord(FieldRec);
        if FieldsLookup.RunModal() = Action::LookupOK then begin
            FieldsLookup.GetRecord(FieldRec);
            Text := Format(FieldRec."No.");
            exit(true);
        end;
        exit(false);
    end;

    local procedure GetFieldNameAndCaption()
    var
        FieldRec: Record Field;
    begin
        Clear(FieldName);
        Clear(FieldCaption);
        Clear(FieldValue);
        Clear(FieldTypeName);
        if FieldNumber = 0 then
            exit;
        FieldRec.SetRange(TableNo, TableNo);
        FieldRec.SetRange("No.", FieldNumber);
        if not FieldRec.FindFirst() then
            exit;
        FieldName := FieldRec.FieldName;
        FieldCaption := FieldRec."Field Caption";
        FieldTypeName := FieldRec."Type Name";
    end;

    local procedure OnValidateFieldValue()
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
    begin
        if FieldNumber = 0 then begin
            Clear(FieldValue);
            exit;
        end;

        RecordRef.Open(TableNo);
        FieldRef := RecordRef.Field(FieldNumber);
        Evaluate(FieldRef, FieldValue);
        FieldValue := Format(FieldRef);
    end;

    local procedure ModifyTableRecords()
    var
        AuditLogMgt: Codeunit "Audit Log Mgt.";
        RecordRef: RecordRef;
        RecordRef2: RecordRef;
        OldRecordRef: RecordRef;
        FieldRef: FieldRef;
        FieldRef2: FieldRef;
        AuditLogEntryNo: Integer;
        AuditLogOperationType: Enum "Audit Log Operation Type";
        AuditLogStatus: Enum "Audit Log Status";
        ModifiedCount: Integer;
        TableEditorLbl: Label 'Table Editor';
        ModifyDescriptionLbl: Label 'Modified field %1 to value %2', Comment = '%1 = Field Name, %2 = Field Value';
    begin
        RecordRef2.Open(TableNo);
        FieldRef2 := RecordRef2.Field(FieldNumber);
        Evaluate(FieldRef2, FieldValue);

        RecordRef.Open(TableNo);
        RecordRef.SetView(CustomTableView);
        TableNoOfRecords := RecordRef.Count();
        if not Confirm(ModifyRecordsQst, false, TableNoOfRecords, TableCaption) then
            Error('');

        if UseValidateTrigger then begin
            if not Confirm(ModifyRecordsWithValidateQst, false, FieldName, FieldValue, Format(UseTableTrigger, 0, 9)) then
                Error('');
        end else
            if not Confirm(ModifyRecordsWithoutValidateQst, false, FieldName, FieldValue, Format(UseTableTrigger, 0, 9)) then
                Error('');

        // Start audit log for bulk modify operation
        AuditLogEntryNo := AuditLogMgt.StartOperation(
            AuditLogOperationType::"Bulk Modify",
            TableNo,
            CopyStr(StrSubstNo(ModifyDescriptionLbl, FieldName, FieldValue), 1, 250),
            TableEditorLbl
        );

        ModifiedCount := 0;
        RecordRef.FindSet(true);
        repeat
            OldRecordRef := RecordRef.Duplicate();
            RecordRef2 := RecordRef.Duplicate();
            FieldRef := RecordRef.Field(FieldNumber);
            if UseValidateTrigger then
                FieldRef.Validate(FieldRef2.Value())
            else
                FieldRef.Value := FieldRef2.Value();
            RecordRef.Modify(UseTableTrigger);

            // Log field changes for this record
            AuditLogMgt.LogFieldChanges(AuditLogEntryNo, OldRecordRef, RecordRef);
            ModifiedCount += 1;
        until RecordRef.Next() = 0;

        // Complete audit log
        AuditLogMgt.CompleteOperation(AuditLogEntryNo, AuditLogStatus::Success, ModifiedCount, 0, '');

        TableNoOfRecords := RecordRef.Count();
        Commit(); // Ensure audit log is saved
        Message(DoneMsg);
        RecordRef.Close();
    end;

    local procedure FieldIndexInPrimaryKey(): Integer
    var
        RecordRef: RecordRef;
        i: Integer;
        PrimaryKeyRef: KeyRef;
    begin
        RecordRef.Open(TableNo);
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        for i := 1 to PrimaryKeyRef.FieldCount() do
            if FieldNumber = PrimaryKeyRef.FieldIndex(i).Number() then
                exit(i);
        exit(-1);
    end;

    local procedure RenameTableRecords()
    var
        AuditLogMgt: Codeunit "Audit Log Mgt.";
        RecordRef: RecordRef;
        RecordRef2: RecordRef;
        RecordRef3: RecordRef;
        OldRecordRef: RecordRef;
        FieldRef2: FieldRef;
        PKFieldRef: array[16] of FieldRef;
        IndexInPrimaryKey: Integer;
        NoOfPrimaryKeys: Integer;
        RenamedCount: Integer;
        AuditLogEntryNo: Integer;
        AuditLogOperationType: Enum "Audit Log Operation Type";
        AuditLogStatus: Enum "Audit Log Status";
        s: Text;
        TableEditorLbl: Label 'Table Editor';
        RenameDescriptionLbl: Label 'Renamed field %1 to value %2', Comment = '%1 = Field Name, %2 = New Value';
    begin
        IndexInPrimaryKey := FieldIndexInPrimaryKey();

        RecordRef2.Open(TableNo);
        FieldRef2 := RecordRef2.Field(FieldNumber);
        Evaluate(FieldRef2, FieldValue);

        RecordRef.Open(TableNo);
        RecordRef.SetView(CustomTableView);
        TableNoOfRecords := RecordRef.Count();

        if not Confirm(RenameRecordsQst, false, TableNoOfRecords, TableCaption) then
            Error('');

        NoOfPrimaryKeys := PreparePrimaryKeyFields(RecordRef, PKFieldRef, IndexInPrimaryKey, FieldRef2);

        // Start audit log for bulk rename operation
        AuditLogEntryNo := AuditLogMgt.StartOperation(
            AuditLogOperationType::"Bulk Modify",
            TableNo,
            CopyStr(StrSubstNo(RenameDescriptionLbl, RecordRef.Field(FieldNumber).Name(), FieldValue), 1, 250),
            TableEditorLbl
        );

        RenamedCount := 0;
        RecordRef.FindSet(true);
        repeat
            s := RecordRef.GetPosition();
            OldRecordRef := RecordRef.Duplicate();
            RecordRef3 := RecordRef.Duplicate();

            PKFieldRef[IndexInPrimaryKey].Value := FieldRef2.Value();
            ExecuteRename(RecordRef3, PKFieldRef, NoOfPrimaryKeys);

            // Log field changes for audit trail
            AuditLogMgt.LogFieldChanges(AuditLogEntryNo, OldRecordRef, RecordRef3);
            RenamedCount += 1;

            RecordRef.SetPosition(s);
        until RecordRef.Next() = 0;

        // Complete audit log operation
        AuditLogMgt.CompleteOperation(AuditLogEntryNo, AuditLogStatus::Success, RenamedCount, 0, '');

        TableNoOfRecords := RecordRef.Count();
        Commit(); // Ensure audit log is saved
        Message(DoneMsg);
        RecordRef.Close();
    end;

    local procedure PreparePrimaryKeyFields(var RecordRef: RecordRef; var PKFieldRef: array[16] of FieldRef; IndexInPrimaryKey: Integer; FieldRef2: FieldRef) NoOfPrimaryKeys: Integer
    var
        i: Integer;
        PrimaryKeyRef: KeyRef;
        s: Text;
    begin
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        NoOfPrimaryKeys := PrimaryKeyRef.FieldCount();

        for i := 1 to NoOfPrimaryKeys do begin
            PKFieldRef[i] := PrimaryKeyRef.FieldIndex(i);
            if i = IndexInPrimaryKey then
                s += '[' + Format(FieldRef2) + '], '
            else
                s += '"' + PKFieldRef[i].Name() + '", ';
        end;
        s := DelStr(s, StrLen(s) - 1);

        if not Confirm(RenameRecords2Qst, false, s) then
            Error('');
    end;

    local procedure ExecuteRename(var RecordRef3: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        // Handle different numbers of primary key fields by delegating to specific procedures
        if NoOfPrimaryKeys <= 8 then
            ExecuteRenameUpTo8Keys(RecordRef3, PKFieldRef, NoOfPrimaryKeys)
        else
            ExecuteRenameUpTo16Keys(RecordRef3, PKFieldRef, NoOfPrimaryKeys);
    end;

    local procedure ExecuteRenameUpTo8Keys(var RecordRef3: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        if NoOfPrimaryKeys <= 4 then
            ExecuteRename1To4Keys(RecordRef3, PKFieldRef, NoOfPrimaryKeys)
        else
            ExecuteRename5To8Keys(RecordRef3, PKFieldRef, NoOfPrimaryKeys);
    end;

    local procedure ExecuteRename1To4Keys(var RecordRef3: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        case NoOfPrimaryKeys of
            1:
                RecordRef3.Rename(PKFieldRef[1].Value());
            2:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value());
            3:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value());
            4:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value());
        end;
    end;

    local procedure ExecuteRename5To8Keys(var RecordRef3: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        case NoOfPrimaryKeys of
            5:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value());
            6:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value());
            7:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value());
            8:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value());
        end;
    end;

    local procedure ExecuteRenameUpTo16Keys(var RecordRef3: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        if NoOfPrimaryKeys <= 12 then
            ExecuteRename9To12Keys(RecordRef3, PKFieldRef, NoOfPrimaryKeys)
        else
            ExecuteRename13To16Keys(RecordRef3, PKFieldRef, NoOfPrimaryKeys);
    end;

    local procedure ExecuteRename9To12Keys(var RecordRef3: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        case NoOfPrimaryKeys of
            9:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value());
            10:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value());
            11:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value(), PKFieldRef[11].Value());
            12:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value(), PKFieldRef[11].Value(), PKFieldRef[12].Value());
        end;
    end;

    local procedure ExecuteRename13To16Keys(var RecordRef3: RecordRef; var PKFieldRef: array[16] of FieldRef; NoOfPrimaryKeys: Integer)
    begin
        case NoOfPrimaryKeys of
            13:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value(), PKFieldRef[11].Value(), PKFieldRef[12].Value(), PKFieldRef[13].Value());
            14:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value(), PKFieldRef[11].Value(), PKFieldRef[12].Value(), PKFieldRef[13].Value(), PKFieldRef[14].Value());
            15:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value(), PKFieldRef[11].Value(), PKFieldRef[12].Value(), PKFieldRef[13].Value(), PKFieldRef[14].Value(), PKFieldRef[15].Value());
            16:
                RecordRef3.Rename(PKFieldRef[1].Value(), PKFieldRef[2].Value(), PKFieldRef[3].Value(), PKFieldRef[4].Value(), PKFieldRef[5].Value(), PKFieldRef[6].Value(), PKFieldRef[7].Value(), PKFieldRef[8].Value(),
                                 PKFieldRef[9].Value(), PKFieldRef[10].Value(), PKFieldRef[11].Value(), PKFieldRef[12].Value(), PKFieldRef[13].Value(), PKFieldRef[14].Value(), PKFieldRef[15].Value(), PKFieldRef[16].Value());
        end;
    end;

    local procedure UpdateTableNoOfRecords()
    var
        RecordRef: RecordRef;
    begin
        if TableNo = 0 then
            exit;
        RecordRef.Open(TableNo);
        TableNoOfRecords := RecordRef.Count();
        RecordRef.Close();
    end;

    procedure FindLongestValue() MaxLength: Integer
    var
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        i: Integer;
    begin
        RecordRef.Open(TableNo);
        RecordRef.SetView(CustomTableView);
        FieldRef := RecordRef.Field(FieldNumber);

        if not (FieldRef.Type() in [FieldRef.Type::Text, FieldRef.Type::Code]) then
            exit;

        // Check if table is empty
        if RecordRef.IsEmpty() then begin
            Message(NoRecordsFoundMsg);
            exit;
        end;

        // Check for max length starting from the longest possible value
        for i := FieldRef.Length() downto 0 do begin
            FieldRef.SetFilter(PadStr('', i, '?'));
            if RecordRef.FindFirst() then begin
                Message(MaxLengthMsg, i, FieldRef.Value());
                exit;
            end;
        end;
    end;

    internal procedure SetParameters(NewTableNo: Integer)
    begin
        if TableNo <> NewTableNo then begin
            TableNo := NewTableNo;
            GetTableCaption();
        end;
    end;
}
