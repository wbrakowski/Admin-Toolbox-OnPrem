table 51001 "Record Deletion"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "Table Name"; Text[250])
        {
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Name" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
        }

#pragma warning disable AL0717
        field(20; "No. of Records"; Integer)
#pragma warning restore AL0717
        {
            Caption = 'No. of Records';
            Editable = false;
            FieldClass = FlowField;
#if OnPrem
            CalcFormula = lookup ("Table Information"."No. of Records" where("Company Name" = field(Company), "Table No." = field("Table ID")));
#endif
        }

        field(21; "No. of Table Relation Errors"; Integer)
        {
            Caption = 'No. of Table Relation Errors';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Record Deletion Rel. Error" where("Table ID" = field("Table ID")));
        }
        field(30; "Delete Records"; Boolean)
        {
            Caption = 'Delete Records';
            DataClassification = CustomerContent;
        }
        field(40; Company; Text[30])
        {
            Caption = 'Company';
            DataClassification = CustomerContent;
        }


    }

    keys
    {
        key(PK; "Table ID")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        Company := CompanyName();
    end;

}