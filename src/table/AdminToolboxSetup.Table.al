table 51000 "Admin Toolbox Setup"
{
    Caption = 'Admin Toolbox Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            AllowInCustomizations = Never;
            NotBlank = true;
        }
        field(10; "Developer License Warning"; Boolean)
        {
            Caption = 'Developer License Warning';
            ToolTip = 'Specifies if a warning should be shown on opening the company when a developer license is active (only OnPrem).';
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

