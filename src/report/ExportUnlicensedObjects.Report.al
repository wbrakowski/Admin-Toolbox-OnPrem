report 51001 "Export Unlicensed Objects"
{
    ApplicationArea = All;
    Caption = 'Export Unlicensed Objects';
    Permissions = tabledata "Temp Unlicensed Object" = rid;
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(AllObj; AllObj)
        {
            DataItemTableView = sorting("Object Type");

            dataitem(LicensePermission; "License Permission")
            {
                DataItemLink = "Object Type" = field("Object Type"), "Object Number" = field("Object ID");
                DataItemTableView = where("Read Permission" = const(0));
                trigger OnAfterGetRecord()
                begin
                    UnlicensedObject.Init();
                    UnlicensedObject."Object Type" := Enum::"Object Type".FromInteger(LicensePermission."Object Type");
                    UnlicensedObject."Object ID" := LicensePermission."Object Number";
                    UnlicensedObject."Object Name" := AllObj."Object Name";
                    UnlicensedObject.Insert(false);
                end;
            }
            trigger OnPreDataItem()
            begin
                if (ObjectTypeFilterVar <> ObjectTypeFilterVar::" ") then
                    SetRange("Object Type", ObjectTypeFilterVar)
                else
                    SetRange("Object Type", 1, 20);

                if (ObjIDFilterVar <> '') then
                    SetFilter("Object ID", ObjIDFilterVar);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ObjectTypeFilter; ObjectTypeFilterVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Object Types Filter';
                        ToolTip = 'Specifies the value of the Object Types Filter field.';
                    }
                    field(ObjIDFilter; ObjIDFilterVar)
                    {
                        ApplicationArea = All;
                        Caption = 'Objects ID (Number) Filter';
                        ToolTip = 'Specifies the value of the Objects ID (Number) Filter field.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            ObjIDFilterVar := '50000..99999';
        end;
    }

    trigger OnPreReport()
    begin
        UnlicensedObject.DeleteAll(false);
    end;

    trigger OnPostReport()

    begin
        UnlicensedObjects.Run();
    end;

    var
        UnlicensedObject: Record "Temp Unlicensed Object";
        UnlicensedObjects: Page "Unlicensed Objects";
        ObjectTypeFilterVar: Enum "Object Type";
        ObjIDFilterVar: Text[50];
}