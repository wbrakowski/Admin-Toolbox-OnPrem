table 51002 "Admin Toolbox Setup"
{
    Caption = 'Admin Toolbox Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Developer License Warning"; Boolean)
        {
            Caption = 'Developer License Warning';
            DataClassification = ToBeClassified;
        }

    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}

