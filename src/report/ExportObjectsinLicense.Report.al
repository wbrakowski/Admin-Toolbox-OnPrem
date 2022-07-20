report 51000 "Export Objects in License"
{
    ApplicationArea = All;
    Caption = 'Export Used and Not Used Objects';
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;

    dataset
    {
        dataitem(LicensePermission; "License Permission")
        {
            DataItemTableView = sorting("Object Type") order(ascending) where("Read Permission" = const(1));

            trigger OnAfterGetRecord()
            begin
                TempObjectInLicense.Init();
                TempObjectInLicense."Object ID" := LicensePermission."Object Number";
                TempObjectInLicense."Object Type" := LicensePermission."Object Type";

                UsedObjects.Reset();
                UsedObjects.SetRange("Object ID", "Object Number");
                UsedObjects.SetRange("Object Type", "Object Type");

                if UsedObjects.FindFirst() then begin
                    TempObjectInLicense.Used := true;
                    TempObjectInLicense."Object Name" := UsedObjects."Object Name";
                end;

                if (OnlyFreeID = true) and (OnlyUsedID = false) then begin
                    if TempObjectInLicense.Used = false then
                        TempObjectInLicense.Insert();
                end;

                if (OnlyUsedID = true) and (OnlyFreeID = false) then begin
                    if TempObjectInLicense.Used = true then
                        TempObjectInLicense.Insert();
                end;

                if (OnlyFreeID = false) and (OnlyUsedID = false) then
                    TempObjectInLicense.Insert();

            end;

            trigger OnPreDataItem();
            begin
                if (ObjectTypeFilter <> ObjectTypeFilter::" ") then
                    SetRange("Object Type", ObjectTypeFilter)
                else
                    SetRange("Object Type", 1, 20);

                if (ObjIDFilter <> '') then
                    SetFilter("Object Number", ObjIDFilter);
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
                    field(OnlyFreeID; OnlyFreeID)
                    {
                        ApplicationArea = All;
                        Caption = 'Only Free Objects';
                        ToolTip = 'Specifies the value of the Only Free Objects field.';
                    }
                    field(OnlyUsedID; OnlyUsedID)
                    {
                        ApplicationArea = All;
                        Caption = 'Only Used Objects';
                        ToolTip = 'Specifies the value of the Only Used Objects field.';
                    }
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
        TempObjectInLicense.DeleteAll();
    end;


    trigger OnPostReport()

    begin
        ObjectInLicense.Run();
    end;


    var
        UsedObjects: Record AllObjWithCaption;
        TempObjectInLicense: Record "Temp Object in License";

        //AppPbjMetadata: record "Application Object Metadata"

        ObjectInLicense: Page "Objects in License";
        OnlyFreeID: Boolean;
        OnlyUsedID: Boolean;
        ObjectTypeFilter: Option " ",Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,,,,,"Pageextension","TableExtension",Enum,EnumExtension,,,PermissionSet,PermissionSetExtension,ReportExtension;
        ObjIDFilter: Text[50];
}