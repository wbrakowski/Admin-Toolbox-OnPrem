report 51001 "Export Unlicensed Objects"
{
    ApplicationArea = All;
    Caption = 'Export Unlicensed Objects';
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;

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
                    UnlicensedObject."Object Type" := LicensePermission."Object Type";
                    UnlicensedObject."Object ID" := LicensePermission."Object Number";
                    UnlicensedObject."Object Name" := AllObj."Object Name";
                    UnlicensedObject.Insert();
                end;
            }
            trigger OnPreDataItem();
            begin
                if (ObjectTypeFilter <> ObjectTypeFilter::" ") then
                    SetRange("Object Type", ObjectTypeFilter)
                else
                    SetRange("Object Type", 1, 20);

                if (ObjIDFilter <> '') then
                    SetFilter("Object ID", ObjIDFilter);
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
                group(options)
                {
                    field(ObjectTypeFilter; ObjectTypeFilter)
                    {
                        ApplicationArea = All;
                        OptionCaption = ',Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,,,,,PageExtension,TableExtension,Enum,EnumExtension,,,PermissionSet,PermissionSetExtension,ReportExtension';
                        Caption = 'Object Types Filter';
                        ToolTip = 'Specifies the value of the Object Types Filter field.';
                    }
                    field(ObjIDFilter; ObjIDFilter)
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
            ObjIDFilter := '50000..99999';
        end;
    }

    trigger OnPreReport()
    begin
        UnlicensedObject.DeleteAll();
    end;


    trigger OnPostReport()

    begin
        UnlicensedObjects.Run();
    end;


    var
        UsedObjects: Record AllObjWithCaption;
        UnlicensedObject: Record "Temp Unlicensed Object";
        UnlicensedObjects: Page "Unlicensed Objects";
        ObjectTypeFilter: Option " ",Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,,,,,"Pageextension","TableExtension",Enum,EnumExtension,,,PermissionSet,PermissionSetExtension,ReportExtension;
        ObjIDFilter: Text[50];
}