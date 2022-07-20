page 51004 "Table Editor"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Table Editor';
    AdditionalSearchTerms = 'Debug';
    Permissions = tabledata "Reservation Entry" = IMD;
    AccessByPermission = tabledata "Item Ledger Entry" = MD;
    AboutTitle = 'About Table Editor';
    AboutText = 'This table editor can modify or delete selected records.';


    layout
    {
        area(Content)
        {
            group(TableSettings)
            {
                Caption = 'Table';

                field(TableNoField; TableNo)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                    BlankZero = true;
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
                    ApplicationArea = All;
                    Caption = 'Caption';
                    Editable = false;
                    ToolTip = 'Specifies the caption of the table where you want to modify or delete records.';
                }
                field(UseTableTriggerField; UseTableTrigger)
                {
                    ApplicationArea = All;
                    Caption = 'Use Trigger';
                    ToolTip = 'Specifies if you want to run the trigger of the table that you want to modify or delete.';
                    AboutTitle = 'Do you want to use table triggers?';
                    AboutText = 'Enable this field if you want to use the table triggers when modifying or deleting records.';
                    Enabled = not RenameRequired;
                }
                field(CustomTableViewField; CustomTableView)
                {
                    ApplicationArea = All;
                    Caption = 'View';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the selected records.';
                    AboutTitle = 'Record Selection';
                    AboutText = 'Select all the records that you want to modify or delete';

                    trigger OnAssistEdit()
                    begin
                        GetTableFilter();
                    end;
                }
                field(CustomTableNoOfRecordsField; TableNoOfRecords)
                {
                    ApplicationArea = All;
                    Caption = 'Records in Filter';
                    Editable = false;
                    ToolTip = 'Specifies the no. of records that you selected';
                    AboutTitle = 'No. of your selected records';
                    AboutText = 'Shows how many records you selected in the previous field.';

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
                    ApplicationArea = All;
                    Caption = 'No.';
                    BlankZero = true;
                    ToolTip = 'Specifies field no. that you want to modify.';
                    AboutTitle = 'Field selector';
                    AboutText = 'Select the field if you want to modify a field for the selected records';

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
                    ApplicationArea = All;
                    Caption = 'Value';
                    ToolTip = 'Specifies the value that the field should have after modifying it.';
                    AboutTitle = 'Choose the new value';
                    AboutText = 'This is the value that the field will have for the selected records after modifying them.';

                    trigger OnValidate()
                    begin
                        OnValidateFieldValue();
                    end;
                }
                field(UseValidateTriggerField; UseValidateTrigger)
                {
                    ApplicationArea = All;
                    Caption = 'Validate';
                    ToolTip = 'Specifies if you want to use the OnValidate trigger of the field.';
                    AboutTitle = 'Enable OnValidateTrigger';
                    AboutText = 'Enable this field if you want to use the OnValidate Trigger of the field when modifying the records.';
                    Enabled = not RenameRequired;
                }
                field(FieldNameField; FieldName)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies name of the selected field.';
                }
                field(FieldCaptionField; FieldCaption)
                {
                    ApplicationArea = All;
                    Caption = 'Caption';
                    Editable = false;
                    ToolTip = 'Specifies caption of the selected field.';
                }
                field(FieldTypeNameField; FieldTypeName)
                {
                    ApplicationArea = All;
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
                ApplicationArea = All;
                Caption = 'Delete Table Records';
                Image = Delete;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Ellipsis = true;
                Enabled = TableNo > 0;
                ToolTip = 'Deletes the selected records.';
                AboutTitle = 'Delete Records';
                AboutText = 'This will delete all the records that you selected in the field "View"';

                trigger OnAction()
                begin
                    DeleteTableRecords();
                end;
            }
            action(ModifyRecordsAction)
            {
                ApplicationArea = All;
                Caption = 'Modify Table Records';
                Image = Apply;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Ellipsis = true;
                Enabled = FieldNumber > 0;
                ToolTip = 'Modifies the selected records.';
                AboutTitle = 'Modify Records';
                AboutText = 'This will modify all the records that you selected in the field "View"';

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
                ApplicationArea = All;
                Caption = 'Create Record';
                Image = Add;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Enabled = TableNo > 0;
                ToolTip = 'Executes the Create Record action.';

                trigger OnAction()
                begin
                    CreateRecord();
                end;
            }
            action(FindLongestValueAction)
            {
                ApplicationArea = All;
                Caption = 'Find Longest Value';
                Image = Find;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Enabled = (TableNo > 0) and (FieldNumber > 0);
                ToolTip = 'Finds the longest value of a field in the table.';

                trigger OnAction()
                begin
                    FindLongestValue();
                end;
            }
        }
    }

    var
        ChangeLogManagement: Codeunit "Change Log Management";
        [InDataSet]
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
        ModifyRecordsWithoutValidateQst: Label '"%1" := [%2];\Modify(%3);\\Proceed?';
        ModifyRecordsWithValidateQst: Label 'Validate("%1", [%2]);\Modify(%3);\\Proceed?';
        NoRecordsFoundMsg: Label 'No records found.';
        RenameRecords2Qst: Label 'Rename(%1);\\Proceed?';
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
        AllObjWithCaption.FindFirst();
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
        if not RecordRef.IsEmpty then
            Error(FilterTableOnEachPKFieldMsg);

        s := 'Rec.Init();\';
        PrimaryKeyRef := RecordRef.KeyIndex(1);
        for i := 1 to PrimaryKeyRef.FieldCount() do begin
            if PrimaryKeyRef.FieldIndex(i).GetFilter = '' then
                Error(FilterTableOnEachPKFieldMsg);
            RecordRef2.Field(PrimaryKeyRef.FieldIndex(i).Number).Value := PrimaryKeyRef.FieldIndex(i).GetRangeMin;
            s += 'Rec."' + PrimaryKeyRef.FieldIndex(i).Name + '" := [' + Format(PrimaryKeyRef.FieldIndex(i).GetRangeMin) + '];\';
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
        UpdateFinishedMsg: Label '%1 tables have succesfully been updated.', Comment = '%1 = No. of tables';
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
                if NoOfRecs <= 100 then
                    UpdateDialog.Update(1, (CurrRec / NoOfRecs * 10000) div 1)
                else
                    if CurrRec mod (NoOfRecs div 100) = 0 then
                        UpdateDialog.Update(1, (CurrRec / NoOfRecs * 10000) div 1);
                if RecordRef.Delete(UseTableTrigger) then begin
                    Commit();
                    TableNoOfRecords := RecordRef.Count();
                end;
            until RecordRef.Next() = 0;
        end;
        TableNoOfRecords := RecordRef.Count();
        Message(DoneMsg);
        RecordRef.Close();
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
        if FieldRec.FindFirst() then;
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
        RecordRef: RecordRef;
        RecordRef2: RecordRef;
        FieldRef: FieldRef;
        FieldRef2: FieldRef;
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


        // TODO: Bind locally defined codeunit with manual subscriber to codeunit 423 "Change Log Management", EventPublisher OnAfterIsAlwaysLoggedTable(TableID: Integer; var AlwaysLogTable: Boolean),
        //       set AlwaysLogTable := true in order to log all changes
        RecordRef.FindSet(true, false);
        repeat
            RecordRef2 := RecordRef.Duplicate();
            FieldRef := RecordRef.Field(FieldNumber);
            if UseValidateTrigger then
                FieldRef.Validate(FieldRef2.Value)
            else
                FieldRef.Value := FieldRef2.Value;
            RecordRef.Modify(UseTableTrigger);
        until RecordRef.Next() = 0;

        TableNoOfRecords := RecordRef.Count();
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
            if FieldNumber = PrimaryKeyRef.FieldIndex(i).Number then
                exit(i);
        exit(-1);
    end;

    local procedure RenameTableRecords()
    var
        RecordRef: RecordRef;
        RecordRef2: RecordRef;
        RecordRef3: RecordRef;
        FieldRef2: FieldRef;
        PKFieldRef: array[16] of FieldRef;
        i, NoOfPrimaryKeys : Integer;
        IndexInPrimaryKey: Integer;
        PrimaryKeyRef: KeyRef;
        s: Text;
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

        PrimaryKeyRef := RecordRef.KeyIndex(1);
        NoOfPrimaryKeys := PrimaryKeyRef.FieldCount();
        for i := 1 to NoOfPrimaryKeys do begin
            PKFieldRef[i] := PrimaryKeyRef.FieldIndex(i);
            if i = IndexInPrimaryKey then
                s += '[' + Format(FieldRef2) + '], '
            else
                s += '"' + PKFieldRef[i].Name + '", ';
        end;
        s := DelStr(s, StrLen(s) - 1);

        if not Confirm(RenameRecords2Qst, false, s) then
            Error('');

        // TODO: Bind locally defined codeunit with manual subscriber to codeunit 423 "Change Log Management", EventPublisher OnAfterIsAlwaysLoggedTable(TableID: Integer; var AlwaysLogTable: Boolean),
        //       set AlwaysLogTable := true in order to log all changes

        RecordRef.FindSet(true, true);
        repeat
            s := RecordRef.GetPosition();
            RecordRef3 := RecordRef.Duplicate();

            PKFieldRef[IndexInPrimaryKey].Value := FieldRef2.Value;

            case NoOfPrimaryKeys of
                1:
                    RecordRef3.Rename(PKFieldRef[1].Value);
                2:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value);
                3:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value);
                4:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value);
                5:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value, PKFieldRef[5].Value);
                6:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value, PKFieldRef[5].Value, PKFieldRef[6].Value);
                7:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value, PKFieldRef[5].Value, PKFieldRef[6].Value, PKFieldRef[7].Value);
                8:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value, PKFieldRef[5].Value, PKFieldRef[6].Value, PKFieldRef[7].Value, PKFieldRef[8].Value);
                9:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value, PKFieldRef[5].Value, PKFieldRef[6].Value, PKFieldRef[7].Value, PKFieldRef[8].Value,
                                     PKFieldRef[9].Value);
                10:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value, PKFieldRef[5].Value, PKFieldRef[6].Value, PKFieldRef[7].Value, PKFieldRef[8].Value,
                                     PKFieldRef[9].Value, PKFieldRef[10].Value);
                11:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value, PKFieldRef[5].Value, PKFieldRef[6].Value, PKFieldRef[7].Value, PKFieldRef[8].Value,
                                     PKFieldRef[9].Value, PKFieldRef[10].Value, PKFieldRef[11].Value);
                12:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value, PKFieldRef[5].Value, PKFieldRef[6].Value, PKFieldRef[7].Value, PKFieldRef[8].Value,
                                     PKFieldRef[9].Value, PKFieldRef[10].Value, PKFieldRef[11].Value, PKFieldRef[12].Value);
                13:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value, PKFieldRef[5].Value, PKFieldRef[6].Value, PKFieldRef[7].Value, PKFieldRef[8].Value,
                                     PKFieldRef[9].Value, PKFieldRef[10].Value, PKFieldRef[11].Value, PKFieldRef[12].Value, PKFieldRef[13].Value);
                14:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value, PKFieldRef[5].Value, PKFieldRef[6].Value, PKFieldRef[7].Value, PKFieldRef[8].Value,
                                     PKFieldRef[9].Value, PKFieldRef[10].Value, PKFieldRef[11].Value, PKFieldRef[12].Value, PKFieldRef[13].Value, PKFieldRef[14].Value);
                15:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value, PKFieldRef[5].Value, PKFieldRef[6].Value, PKFieldRef[7].Value, PKFieldRef[8].Value,
                                     PKFieldRef[9].Value, PKFieldRef[10].Value, PKFieldRef[11].Value, PKFieldRef[12].Value, PKFieldRef[13].Value, PKFieldRef[14].Value, PKFieldRef[15].Value);
                16:
                    RecordRef3.Rename(PKFieldRef[1].Value, PKFieldRef[2].Value, PKFieldRef[3].Value, PKFieldRef[4].Value, PKFieldRef[5].Value, PKFieldRef[6].Value, PKFieldRef[7].Value, PKFieldRef[8].Value,
                                     PKFieldRef[9].Value, PKFieldRef[10].Value, PKFieldRef[11].Value, PKFieldRef[12].Value, PKFieldRef[13].Value, PKFieldRef[14].Value, PKFieldRef[15].Value, PKFieldRef[16].Value);
            end;

            RecordRef.SetPosition(s);

            ChangeLogManagement.LogRename(RecordRef3, RecordRef);

        until RecordRef.Next() = 0;

        TableNoOfRecords := RecordRef.Count();
        Message(DoneMsg);
        RecordRef.Close();
    end;

    local procedure UpdateTableNoOfRecords()
    var
        RecordRef: RecordRef;
        FilterPageBuilder: FilterPageBuilder;
        i: Integer;
    begin
        if TableNo <> 0 then begin
            RecordRef.Open(TableNo);
            TableNoOfRecords := RecordRef.Count();
            RecordRef.Close();
        end;
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

        if not (FieldRef.Type in [FieldRef.Type::Text, FieldRef.Type::Code]) then
            exit;

        // Check if table is empty
        if RecordRef.IsEmpty then begin
            Message(NoRecordsFoundMsg);
            exit;
        end;

        // Check for max length starting from the longest possible value
        for i := FieldRef.Length downto 0 do begin
            FieldRef.SetFilter(PadStr('', i, '?'));
            if RecordRef.FindFirst() then begin
                Message(MaxLengthMsg, i, FieldRef.Value);
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
