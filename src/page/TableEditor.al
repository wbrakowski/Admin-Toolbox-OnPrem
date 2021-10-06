page 51004 "Table Editor"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Table Editor';
    AdditionalSearchTerms = 'Debug';
    Permissions = TableData "337" = IMD;
    AccessByPermission = TableData "32" = MD;
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
                ToolTip = 'Modifies the selected records.';
                AboutTitle = 'Modify Records';
                AboutText = 'This will modify all the records that you selected in the field "View"';

                trigger OnAction()
                begin
                    ModifyTableRecords();
                end;
            }
        }
    }

    var
        TableNo, TableNoOfRecords, FieldNumber : Integer;
        TableCaption, CustomTableView : Text;
        FieldName, FieldCaption, FieldValue : Text;
        UseTableTrigger, UseValidateTrigger : Boolean;
        DeleteRecordsQst: Label 'Do you want to delete %1 records from table %2?';
        DeleteWithTriggerQst: Label 'Records will be deleted using DeleteAll(%1).\\Proceed?';
        ModifyRecordsQst: Label 'Do you want to modify %1 records in table %2?';
        ModifyRecordsWithValidateQst: Label 'Validate("%1", [%2]);\Modify(%3);\\Proceed?';
        ModifyRecordsWithoutValidateQst: Label '"%1" := [%2];\Modify(%3);\\Proceed?';
        DoneMsg: Label 'Done.';

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
        FiltertPageBuilder: FilterPageBuilder;
        RecordRef: RecordRef;
    begin
        GetTableCaption();

        RecordRef.Open(TableNo);

        FiltertPageBuilder.AddTable(TableCaption, TableNo);
        if CustomTableView <> '' then
            FiltertPageBuilder.SetView(TableCaption, CustomTableView);

        if FiltertPageBuilder.RunModal() then begin
            CustomTableView := FiltertPageBuilder.GetView(TableCaption, false);
            RecordRef.SetView(CustomTableView);
        end;

        TableNoOfRecords := RecordRef.Count;
        RecordRef.Close();
    end;

    local procedure DeleteTableRecords()
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableNo);
        RecordRef.SetView(CustomTableView);
        TableNoOfRecords := RecordRef.Count;
        if not Confirm(DeleteRecordsQst, false, TableNoOfRecords, TableCaption) then
            Error('');
        if not Confirm(DeleteWithTriggerQst, false, Format(UseTableTrigger, 0, 9)) then
            Error('');
        RecordRef.DeleteAll(UseTableTrigger);
        TableNoOfRecords := RecordRef.Count;
        Message(DoneMsg);
        RecordRef.Close();
    end;

    local procedure ShowCustomTable()
    var
        RecordRef: RecordRef;
        PageMgt: Codeunit "Page Management";
    begin
        RecordRef.Open(TableNo);
        RecordRef.SetView(CustomTableView);
        PageMgt.PageRun(RecordRef);
        RecordRef.Close();
    end;

    local procedure ClearFieldVariables()
    begin
        Clear(FieldNumber);
        Clear(FieldName);
        Clear(FieldCaption);
        Clear(FieldValue);
    end;

    local procedure OnLookupFieldNumber(var Text: Text): Boolean
    var
        FieldRec: Record Field;
        FieldsLookup: Page "Fields Lookup";
    begin
        FieldRec.SetRange(TableNo, TableNo);
        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
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
        if FieldNumber = 0 then
            exit;
        FieldRec.SetRange(TableNo, TableNo);
        FieldRec.SetRange("No.", FieldNumber);
        if not FieldRec.FindFirst() then
            exit;
        FieldName := FieldRec.FieldName;
        FieldCaption := FieldRec."Field Caption";
    end;

    local procedure OnValidateFieldValue()
    var
        FieldRec: Record Field;
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
        TableNoOfRecords := RecordRef.Count;
        if not Confirm(ModifyRecordsQst, false, TableNoOfRecords, TableCaption) then
            Error('');

        if UseValidateTrigger then begin
            if not Confirm(ModifyRecordsWithValidateQst, false, FieldName, FieldValue, Format(UseTableTrigger, 0, 9)) then
                Error('');
        end else
            if not Confirm(ModifyRecordsWithoutValidateQst, false, FieldName, FieldValue, Format(UseTableTrigger, 0, 9)) then
                Error('');

        RecordRef.FindSet(true, false);
        repeat
            FieldRef := RecordRef.Field(FieldNumber);
            if UseValidateTrigger then
                FieldRef.Validate(FieldRef2.Value)
            else
                FieldRef.Value := FieldRef2.Value;
            RecordRef.Modify(UseTableTrigger);
        until RecordRef.Next() = 0;

        TableNoOfRecords := RecordRef.Count;
        Message(DoneMsg);
        RecordRef.Close();
    end;

    internal procedure SetParameters(NewTableNo: Integer)
    begin
        if TableNo <> NewTableNo then begin
            TableNo := NewTableNo;
            GetTableCaption();
        end;
    end;
}
