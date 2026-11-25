enum 51004 "Audit Log Status"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Success)
    {
        Caption = 'Success';
    }
    value(2; Failed)
    {
        Caption = 'Failed';
    }
    value(3; "Partially Failed")
    {
        Caption = 'Partially Failed';
    }
    value(4; "In Progress")
    {
        Caption = 'In Progress';
    }
}
