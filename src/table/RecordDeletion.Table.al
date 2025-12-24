table 51001 "Record Deletion"
{
    Caption = 'Record Deletion';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            Editable = false;
            ToolTip = 'Specifies the ID of the table.';
        }
        field(10; "Table Name"; Text[250])
        {
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
            ToolTip = 'Specifies the name of the table.';
        }

#pragma warning disable AL0717
        field(20; "No. of Records"; Integer)
#pragma warning restore AL0717
        {
            Caption = 'No. of Records';
            Editable = false;
            FieldClass = FlowField;
#if OnPrem
            CalcFormula = lookup("Table Information"."No. of Records" where("Company Name" = field(Company), "Table No." = field("Table ID")));
#endif
            ToolTip = 'Specifies the total no. of records in the table.';
        }

        field(21; "No. of Table Relation Errors"; Integer)
        {
            Caption = 'No. of Table Relation Errors';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Record Deletion Rel. Error" where("Table ID" = field("Table ID")));
            ToolTip = 'Specifies the no. of table relation errors that were detected when running the table relation check.';
        }
        field(30; "Delete Records"; Boolean)
        {
            Caption = 'Delete Records';
            ToolTip = 'Specifies that this table was marked for deletion.';
        }
        field(40; Company; Text[30])
        {
            Caption = 'Company';
            AllowInCustomizations = Never;
        }


    }

    keys
    {
        key(PK; "Table ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Table ID", "Table Name", "No. of Records")
        {
        }
        fieldgroup(Brick; "Table ID", "Table Name", "No. of Records", "Delete Records")
        {
        }
    }

    trigger OnInsert()
    begin
        Company := CopyStr(CompanyName(), 1, MaxStrLen(Company));
    end;

}