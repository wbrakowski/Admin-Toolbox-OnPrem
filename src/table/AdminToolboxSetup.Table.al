table 51000 "Admin Toolbox Setup"
{
    Caption = 'Admin Toolbox Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = CustomerContent;
        }
        field(10; "Developer License Warning"; Boolean)
        {
            Caption = 'Developer License Warning';
            DataClassification = CustomerContent;
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

