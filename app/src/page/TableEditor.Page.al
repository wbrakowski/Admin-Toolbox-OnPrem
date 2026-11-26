namespace AdminToolbox;

using Microsoft.Inventory.Ledger;
using Microsoft.Utilities;
using System.Reflection;
using System.Utilities;

page 51004 "Table Editor"
{
    AboutText = 'This table editor can modify or delete selected records.';
    AboutTitle = 'About Table Editor';
    AccessByPermission = tabledata "Item Ledger Entry" = MD;
    AdditionalSearchTerms = 'Debug';
    ApplicationArea = All;
    Caption = 'Table Editor';
    PageType = Card;
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
                        RenameRequired := TableEditorMgt.FieldIndexInPrimaryKey(TableNo, FieldNumber) > 0;
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
                ToolTip = 'Executes the Create Record action.';

                trigger OnAction()
                begin
                    CreateTableRecord();
                end;
            }
            action(FindLongestValueAction)
            {
                Caption = 'Find Longest Value';
                Enabled = (TableNo > 0) and (FieldNumber > 0);
                Image = Find;
                ToolTip = 'Finds the longest value of a field in the table.';

                trigger OnAction()
                begin
                    FindLongestValue();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(DeleteRecordsAction_Promoted; DeleteRecordsAction)
                {
                }
                actionref(ModifyRecordsAction_Promoted; ModifyRecordsAction)
                {
                }
                actionref(CreateRecordAction_Promoted; CreateRecordAction)
                {
                }
                actionref(FindLongestValueAction_Promoted; FindLongestValueAction)
                {
                }
            }
        }
    }

    var
        TableEditorMgt: Codeunit "Table Editor Mgt.";
        RenameRequired: Boolean;
        UseTableTrigger, UseValidateTrigger : Boolean;
        FieldNumber, TableNo, TableNoOfRecords : Integer;
        CreateRecord2Qst: Label 'Proceed?';
        CreateRecordQst: Label 'Do you want to create a new record in table %1?', Comment = '%1 = Table Caption';
        DeleteRecordsQst: Label 'Do you want to delete %1 records from table %2?', Comment = '%1 = No. of Records, %2 = Table Caption';
        DeleteWithTriggerQst: Label 'Records will be deleted using DeleteAll(%1).\\Proceed?', Comment = '%1 = UseTrigger (Boolean)';
        DoneMsg: Label 'Done.';
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
        TableEditorMgt.CheckSuperPermission();
        UpdateTableNoOfRecords();
    end;

    local procedure ClearTableVariables()
    begin
        Clear(TableCaption);
        Clear(CustomTableView);
        Clear(TableNoOfRecords);
        Clear(FieldNumber);
        Clear(FieldName);
        Clear(FieldCaption);
        Clear(FieldValue);
        Clear(FieldTypeName);
        RenameRequired := false;
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

    local procedure CreateTableRecord()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        Preview: Text;
    begin
        TableNoOfRecords := TableEditorMgt.CountRecords(TableNo, CustomTableView);
        Preview := TableEditorMgt.GetCreateRecordPreview(TableNo, CustomTableView);

        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(CreateRecordQst, TableCaption), false) then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(Preview + CreateRecord2Qst, false) then
            exit;

        TableEditorMgt.CreateRecord(TableNo, CustomTableView);
        TableNoOfRecords := TableEditorMgt.CountRecords(TableNo, CustomTableView);
        Message(DoneMsg);
    end;

    local procedure DeleteTableRecords()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        CreateBackup: Boolean;
    begin
        TableNoOfRecords := TableEditorMgt.CountRecords(TableNo, CustomTableView);
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(DeleteRecordsQst, TableNoOfRecords, TableCaption), false) then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(DeleteWithTriggerQst, Format(UseTableTrigger, 0, 9)), false) then
            exit;

        CreateBackup := TableEditorMgt.ConfirmBackupBeforeDeletion(TableNo);
        TableEditorMgt.DeleteRecords(TableNo, CustomTableView, UseTableTrigger, CreateBackup, true);

        TableNoOfRecords := TableEditorMgt.CountRecords(TableNo, CustomTableView);
        Message(DoneMsg);
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
        ConfirmManagement: Codeunit "Confirm Management";
        ConfirmText: Text;
    begin
        TableNoOfRecords := TableEditorMgt.CountRecords(TableNo, CustomTableView);
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ModifyRecordsQst, TableNoOfRecords, TableCaption), false) then
            exit;

        if UseValidateTrigger then
            ConfirmText := StrSubstNo(ModifyRecordsWithValidateQst, FieldName, FieldValue, Format(UseTableTrigger, 0, 9))
        else
            ConfirmText := StrSubstNo(ModifyRecordsWithoutValidateQst, FieldName, FieldValue, Format(UseTableTrigger, 0, 9));
        if not ConfirmManagement.GetResponseOrDefault(ConfirmText, false) then
            exit;

        TableEditorMgt.ModifyRecords(TableNo, CustomTableView, FieldNumber, FieldValue, UseTableTrigger, UseValidateTrigger);

        TableNoOfRecords := TableEditorMgt.CountRecords(TableNo, CustomTableView);
        Commit(); // Ensure audit log is saved
        Message(DoneMsg);
    end;

    local procedure RenameTableRecords()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        TableNoOfRecords := TableEditorMgt.CountRecords(TableNo, CustomTableView);
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(RenameRecordsQst, TableNoOfRecords, TableCaption), false) then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(RenameRecords2Qst, TableEditorMgt.GetRenamePreview(TableNo, FieldNumber, FieldValue)), false) then
            exit;

        TableEditorMgt.RenameRecords(TableNo, CustomTableView, FieldNumber, FieldValue);

        TableNoOfRecords := TableEditorMgt.CountRecords(TableNo, CustomTableView);
        Commit(); // Ensure audit log is saved
        Message(DoneMsg);
    end;

    local procedure UpdateTableNoOfRecords()
    begin
        TableNoOfRecords := TableEditorMgt.CountRecords(TableNo, '');
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
