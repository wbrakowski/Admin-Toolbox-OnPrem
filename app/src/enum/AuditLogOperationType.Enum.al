enum 51003 "Audit Log Operation Type"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; Insert)
    {
        Caption = 'Insert';
    }
    value(2; Modify)
    {
        Caption = 'Modify';
    }
    value(3; Delete)
    {
        Caption = 'Delete';
    }
    value(4; "Bulk Delete")
    {
        Caption = 'Bulk Delete';
    }
    value(5; "Bulk Modify")
    {
        Caption = 'Bulk Modify';
    }
}
