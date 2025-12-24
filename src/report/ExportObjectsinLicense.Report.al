report 51000 "Export Objects in License"
{
    ApplicationArea = All;
    Caption = 'Export Used and Not Used Objects';
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;
    Permissions = tabledata "Temp Object in License" = rid;

    dataset
    {
        dataitem(LicensePermission; "License Permission")
        {
            DataItemTableView = sorting("Object Type") order(ascending) where("Read Permission" = const(1));

            trigger OnAfterGetRecord()
            begin
                TempObjectInLicense.Init();
                TempObjectInLicense."Object ID" := LicensePermission."Object Number";
                TempObjectInLicense."Object Type" := Enum::"Object Type".FromInteger(LicensePermission."Object Type");

                PopulateObjectUsage();
                InsertObjectBasedOnFilter();
            end;

            trigger OnPreDataItem()
            begin
                if (ObjectTypeFilterVar <> ObjectTypeFilterVar::" ") then
                    SetRange("Object Type", ObjectTypeFilterVar)
                else
                    SetRange("Object Type", 1, 20);

                if (ObjIDFilterVar <> '') then
                    SetFilter("Object Number", ObjIDFilterVar);
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
                    Caption = 'Options';
                    field(OnlyFreeIDField; OnlyFreeIDVar)
                    {
                        Caption = 'Only Free Objects';
                        ToolTip = 'Specifies the value of the Only Free Objects field.';
                    }
                    field(OnlyUsedIDField; OnlyUsedIDVar)
                    {
                        Caption = 'Only Used Objects';
                        ToolTip = 'Specifies the value of the Only Used Objects field.';
                    }
                    field(ObjectTypeFilterField; ObjectTypeFilterVar)
                    {
                        Caption = 'Object Types Filter';
                        ToolTip = 'Specifies the value of the Object Types Filter field.';
                    }
                    field(ObjIDFilterField; ObjIDFilterVar)
                    {
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
        TempObjectInLicense.DeleteAll(false);
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
        OnlyFreeIDVar: Boolean;
        OnlyUsedIDVar: Boolean;
        ObjectTypeFilterVar: Enum "Object Type";
        ObjIDFilterVar: Text[50];

    local procedure PopulateObjectUsage()
    begin
        UsedObjects.Reset();
        UsedObjects.SetRange("Object ID", LicensePermission."Object Number");
        UsedObjects.SetRange("Object Type", LicensePermission."Object Type");

        if UsedObjects.FindFirst() then begin
            TempObjectInLicense.Used := true;
            TempObjectInLicense."Object Name" := UsedObjects."Object Name";
        end;
    end;

    local procedure InsertObjectBasedOnFilter()
    begin
        if ShouldInsertFreeObject() then
            TempObjectInLicense.Insert(false)
        else
            if ShouldInsertUsedObject() then
                TempObjectInLicense.Insert(false)
            else
                if ShouldInsertAllObjects() then
                    TempObjectInLicense.Insert(false);
    end;

    local procedure ShouldInsertFreeObject(): Boolean
    begin
        exit((OnlyFreeIDVar = true) and (OnlyUsedIDVar = false) and (TempObjectInLicense.Used = false));
    end;

    local procedure ShouldInsertUsedObject(): Boolean
    begin
        exit((OnlyUsedIDVar = true) and (OnlyFreeIDVar = false) and (TempObjectInLicense.Used = true));
    end;

    local procedure ShouldInsertAllObjects(): Boolean
    begin
        exit((OnlyFreeIDVar = false) and (OnlyUsedIDVar = false));
    end;
}