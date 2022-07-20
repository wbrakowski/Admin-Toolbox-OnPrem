page 51001 "Admin Toolbox"
{
    ApplicationArea = All;
    Caption = 'Admin Toolbox';
    PageType = Document;
    SourceTable = Integer;
    UsageCategory = Lists;
    InsertAllowed = false;
    SaveValues = true;
    DataCaptionExpression = '';
    AboutTitle = 'About the Admin Toolbox';
    AboutText = 'This toolbox assists you with the following tasks: deleting or editing records, viewing or importing licenses, running tables, publishing apps.';
    layout
    {
        area(Content)
        {
            group(Howto)
            {
                Caption = 'How To';
                field(HowToLbl; HowToLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies the link that opens the documentation.';
                    AboutTitle = 'How to use this app';
                    AboutText = 'Click on the link to open the documentation for the Admin Toolbox.';

                    trigger OnDrillDown()
                    begin
                        AdminToolMgt.OpenReadme();
                    end;
                }
            }
            part(Tables; "Record Deletion")
            {
                ApplicationArea = All;
                AboutTitle = 'About tables';
                AboutText = 'This is an overview of all the tables in the system. You can run the table, delete all records from a table, edit specific records, delete a selection of records.';
            }
#if OnPrem
            part(LicenseInformation; "License Information")
            {
                ApplicationArea = All;
                Visible = IsOnPrem;
                AboutTitle = 'About license information';
                AboutText = 'View the details of your current license or import a new license.';
                UpdatePropagation = Both;
            }
#endif

            group(Information)
            {
                Caption = 'Information';
                Editable = false;
                AboutTitle = 'About information';
                AboutText = 'The links in this fast tab will run the different tables.';
                group(Session)
                {
                    Caption = 'Session';
                    field(SessionInformationLbl; SessionInformationLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "Session".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::Session);
                        end;
                    }
                    field(ActiveSessionLbl; ActiveSessionLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "Active Session".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"Active Session");
                        end;
                    }
                    field(SessionEventLbl; SessionEventLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "Session Event".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"Session Event");
                        end;
                    }
                }
                group(Metadata)
                {
                    Caption = 'Metadata';
                    field(TableMetadataLbl; TableMetadataLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "Table Metadata".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"Table Metadata");
                        end;
                    }
                    field(CodeunitMetadataLbl; CodeunitMetadataLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "Codeunit Metadata".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"CodeUnit Metadata");
                        end;
                    }
                    field(PageMetadataLbl; PageMetadataLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "Page Metadata".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"Page Metadata");
                        end;
                    }
                }
                group(Object)
                {
                    Caption = 'Object';
                    field(AllObjectsLbl; AllObjectsLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "AllObj".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::AllObj);
                        end;
                    }
                    field(FieldLbl; FieldLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "Field".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::Field);
                        end;
                    }
                    field(KeyLbl; KeyLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "Key".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"Key");
                        end;
                    }
                    field(RecordLinkLbl; RecordLinkLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "Record Link".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"Record Link");
                        end;
                    }
                }
                group(API)
                {
                    Caption = 'API';
                    field(APIWebhookSubscriptionLbl; APIWebhookSubscriptionLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "API Webhook Subscription".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"API Webhook Subscription");
                        end;
                    }
                    field(APIWebhookNotificationLbl; APIWebhookNotificationLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "API Webhook Notification".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"API Webhook Notification");
                        end;
                    }
                }
                group(License)
                {
                    Caption = 'License';
                    field(LicensePermissionLbl; LicensePermissionLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the link that will run the table "License Permission".';

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"License Permission");
                        end;
                    }
                }
                group(Select)
                {
                    Caption = 'Table Selector';
                    AboutTitle = 'About Table Selector';
                    AboutText = 'Use the table selector if you want to run a specific table.';

                    field(SelectedTableNoText; SelectedTableNoText)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the table no. that you want to run with the table selector.';

                        trigger OnAssistEdit()
                        var
                            AllObjWithCaption: Record AllObjWithCaption;
                        begin
                            if Page.RunModal(Page::"Table Objects", AllObjWithCaption) = Action::LookupOK then begin
                                SelectedTableNo := AllObjWithCaption."Object ID";
                                SelectedTableNoText := Format(SelectedTableNo);
                                SelectedTableTxt := AllObjWithCaption."Object Caption";
                            end;
                        end;
                    }
                    field(SelectedTableTxt; SelectedTableTxt)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Specifies the table name that you want to run with the table selector.';

                        trigger OnDrillDown()
                        var
                            NoTableNoSelectedErr: Label 'Please select a "Table No." before running this link.';
                        begin
                            if SelectedTableNo <> 0 then
                                AdminToolMgt.OpenTable(SelectedTableNo)
                            else
                                Error(NoTableNoSelectedErr);
                        end;
                    }
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(InsertUpdateTables)
            {
                ApplicationArea = All;
                Caption = 'Insert/Update Tables';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                AboutTitle = 'Fills or updates the "Table" sub page';
                AboutText = 'Use this function if your want to see the tables in the system or want to edit/delete records';
                ToolTip = 'Inserts or updates the table information in the fast tab "Tables" for all the tables in the system.';

                trigger OnAction()
                begin
                    AdminToolMgt.InsertUpdateTables();
                    CurrPage.Update(false);
                end;
            }
            action(SuggestsRecords)
            {
                ApplicationArea = All;
                Caption = 'Suggest Records to Delete';
                Image = Suggest;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Ellipsis = true;
                AboutTitle = 'Your assistant if you want to delete all records from tables';
                AboutText = 'Suggests you records that you may want to delete by checking off the field "Delete Records". This is useful if you want to "clean" a company from transactional data.';
                ToolTip = 'Opens a dialog and ask you which records you want to delete. If you continue, the field "Delete records" of the suggested tables will be checked off in the table overview.';
                trigger OnAction()
                begin
                    AdminToolMgt.SuggestRecordsToDelete();
                    CurrPage.Update(false);
                end;
            }
            action(ClearRecords)
            {
                ApplicationArea = All;
                Caption = 'Clear Records to Delete';
                Image = ClearFilter;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                AboutTitle = 'Your fellow cleaning service';
                AboutText = 'Clears the checkboxes of the field "Delete Records" in all tables.';
                ToolTip = 'Clears the checkboxes of the field "Delete Records" in all tables.';
                trigger OnAction()
                begin
                    AdminToolMgt.ClearRecordsToDelete();
                    CurrPage.Update(false);
                end;
            }
            action(DeleteRecords)
            {
                ApplicationArea = All;
                Caption = 'Delete Marked Records';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Ellipsis = true;
                AboutTitle = 'The bad evil executioner';
                AboutText = 'Use this action to delete the records that were suggested to you or that you marked for deletion yourself.';
                ToolTip = 'Opens a dialog and if confirmed deletes the records from the tables where the field "Delete Records" is checked off.';
                trigger OnAction()
                begin
                    AdminToolMgt.DeleteRecords();
                    CurrPage.Update(false);
                end;
            }

            action(CheckTableRelations)
            {
                ApplicationArea = All;
                Caption = 'Check Table Relations';
                Image = Relationship;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                AboutTitle = 'Check your tables for relation errors';
                AboutText = 'Runs through all records and uses the field relations defined in the table "Field" in Business Central to validate the table relations.';
                ToolTip = 'This function runs through all records and uses the field relations defined in the table "Field" in Business Central to validate the table relations.';
                trigger OnAction()
                begin
                    AdminToolMgt.CheckTableRelations();
                    CurrPage.Update(false);
                end;
            }
            action(ViewRecords)
            {
                ApplicationArea = All;
                Caption = 'View Records';
                Image = Table;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                AboutTitle = 'View the records of the table';
                AboutText = 'This will run the selected table in a separate window.';
                ToolTip = 'Runs the selected table in a separate window.';
                trigger OnAction()
                var
                    RecordDeletion: Record "Record Deletion";
                begin
                    CurrPage.Tables.Page.GetRecord(RecordDeletion);
                    AdminToolMgt.ViewRecords(RecordDeletion);
                end;
            }
            action(EditTable)
            {
                ApplicationArea = All;
                Caption = 'Edit Table';
                Image = EditLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                AboutTitle = 'A very powerful table editor';
                AboutText = 'Use this action to open the table editor where you can edit or delete selected records.';
                ToolTip = 'Opens the table editor where you can edit or delete selected records.';
                trigger OnAction()
                begin
                    AdminToolMgt.OpenTableEditor(CurrPage.Tables.Page.GetSelectedTableNo());
                    CurrPage.Update(false);
                end;
            }
            action(PublishApp)
            {
                ApplicationArea = All;
                Caption = 'Publish and Install App';
                Image = Installments;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Ellipsis = true;
                AboutTitle = 'Publish and Install apps without powershell';
                AboutText = 'Instead of using powershell, you can use this action to publish and install apps. The action will use the powershellrunner to publish and install the app.';
                ToolTip = 'Publishes and installs the selected app by using the powershell runner.';
                Visible = IsOnPrem;

                trigger OnAction()
                var
                    AdminToolMgt: Codeunit "Admin Tool Mgt.";
                begin
                    AdminToolMgt.PublishApp();
                end;
            }
        }
        area(Navigation)
        {
            action(Setup)
            {
                Caption = 'Setup';
                ApplicationArea = All;
                Image = Setup;
                RunObject = page "Admin Toolbox Setup";
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Opens the setup of the Admin Toolbox.';
                AboutTitle = 'About the setup';
                AboutText = 'Open the setup if you want to set up additional functionalities of the Admin Toolbox.';
            }
        }
    }
    var
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
        IsOnPrem: Boolean;
        SelectedTableNo: Integer;
        ActiveSessionLbl: Label 'Active Session';
        AllObjectsLbl: Label 'All Objects';
        APIWebhookNotificationLbl: Label 'API Webhook Notification';
        APIWebhookSubscriptionLbl: Label 'API Webhook Subscription';
        CodeunitMetadataLbl: Label 'Codeunit Metadata';
        FieldLbl: Label 'Field';
        HowToLbl: Label 'Learn how to use this tool';
        KeyLbl: Label 'Key';
        LicensePermissionLbl: Label 'License Permission';
        PageMetadataLbl: Label 'Page Metadata';
        RecordLinkLbl: Label 'Record Link';
        SessionEventLbl: Label 'Session Event';
        SessionInformationLbl: Label 'Session Information';
        TableMetadataLbl: Label 'Table Metadata';
        SelectedTableNoText, SelectedTableTxt : Text;

    trigger OnOpenPage()
    var
        UserPermissions: Codeunit "User Permissions";
        NoTableSelectedLbl: Label 'No table to run selected';
        // NoAccessErr: Label 'This page can only be accessed by users with super rights. If you want to see the information of this page, please contact your it department to grant you super rights.';
        ThreeDotsLbl: Label 'Use the three dots on the right to select a table that you want to run';
    begin
        if not UserPermissions.IsSuper(UserSecurityId()) then
            Error('');
        // Error(NoAccessErr);
        SelectedTableTxt := NoTableSelectedLbl;
        SelectedTableNoText := ThreeDotsLbl;
        // AdminToolMgt.UpdateTablesIfEmpty();
        IsOnPrem := EnvironmentInformation.IsOnPrem();
    end;
}