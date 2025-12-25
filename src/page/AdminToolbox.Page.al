page 51001 "Admin Toolbox"
{
    AboutText = 'This toolbox assists you with the following tasks: deleting or editing records, viewing or importing licenses, running tables, publishing apps.';
    AboutTitle = 'About the Admin Toolbox';
    ApplicationArea = All;
    Caption = 'Admin Toolbox';
    DataCaptionExpression = '';
    InherentEntitlements = X;
    InherentPermissions = X;
    InsertAllowed = false;
    PageType = Document;
    Permissions = tabledata "Admin Toolbox Setup" = RI;
    PromotedActionCategories = 'New,Process,Report,Category4,Tables,Deletion,Audit & Backup,Apps';
    SaveValues = true;
    SourceTable = Integer;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            group(Welcome)
            {
                Caption = 'Welcome to Admin Toolbox';
                Visible = ShowInlineHelp;

                field(WelcomeText1; WelcomeText1)
                {
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                    StyleExpr = 'Standard';
                }
                field(HowToLbl; HowToLbl)
                {
                    AboutText = 'Click on the link to open the documentation for the Admin Toolbox.';
                    AboutTitle = 'How to use this app';
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a link to the comprehensive documentation for the Admin Toolbox with examples, best practices, and step-by-step guides for all functions.';

                    trigger OnDrillDown()
                    begin
                        AdminToolMgt.OpenReadme();
                    end;
                }
                field(WelcomeText2; WelcomeText2)
                {
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                    StyleExpr = 'Attention';
                }
                field(WelcomeText3; WelcomeText3)
                {
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                    StyleExpr = 'Favorable';
                }
                field(WelcomeText4; WelcomeText4)
                {
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                    StyleExpr = 'Standard';
                }
            }
            group(Howto)
            {
                Caption = 'How To';
            }
            part(Tables; "Record Deletion")
            {
                AboutText = 'This is an overview of all the tables in the system. You can run the table, delete all records from a table, edit specific records, delete a selection of records.';
                AboutTitle = 'About tables';
            }
#if OnPrem
            part(LicenseInformation; "License Information")
            {
                AboutText = 'View the details of your current license or import a new license.';
                AboutTitle = 'About license information';
                UpdatePropagation = Both;
                Visible = IsOnPrem;
            }
#endif

            group(Information)
            {
                AboutText = 'The links in this fast tab will run the different tables.';
                AboutTitle = 'About information';
                Caption = 'Information';
                Editable = false;
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
                    AboutText = 'Use the table selector if you want to run a specific table.';
                    AboutTitle = 'About Table Selector';
                    Caption = 'Table Selector';

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
        area(FactBoxes)
        {
            part(TableBackups; "Table Backup FactBox")
            {
                Caption = 'Table Backups';
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(OpenDashboard)
            {
                Caption = 'Open Dashboard';
                Image = ViewDetails;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Opens the Admin Toolbox Dashboard with statistics, quick actions, and color-coded operations by risk level.';

                trigger OnAction()
                begin
                    Page.Run(Page::"Admin Toolbox Dashboard");
                end;
            }
            group(TableManagement)
            {
                Caption = 'Table Management';
                Image = Table;

                action(InsertUpdateTables)
                {
                    AboutText = 'Use this function if your want to see the tables in the system or want to edit/delete records';
                    AboutTitle = 'Fills or updates the "Table" sub page';
                    Caption = 'Refresh Table List';
                    Image = Refresh;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Inserts or updates the table information in the fast tab "Tables" for all the tables in the system.';

                    trigger OnAction()
                    begin
                        AdminToolMgt.InsertUpdateTables();
                        CurrPage.Update(false);
                    end;
                }
                action(ViewRecords)
                {
                    AboutText = 'This will run the selected table in a separate window.';
                    AboutTitle = 'View the records of the table';
                    Caption = 'View Records';
                    Image = Table;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = false;
                    PromotedOnly = true;
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
                    AboutText = 'Use this action to open the table editor where you can edit or delete selected records.';
                    AboutTitle = 'A very powerful table editor';
                    Caption = 'Edit Table';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = false;
                    PromotedOnly = true;
                    ToolTip = 'Opens the table editor where you can edit or delete selected records.';
                    trigger OnAction()
                    begin
                        AdminToolMgt.OpenTableEditor(CurrPage.Tables.Page.GetSelectedTableNo());
                        CurrPage.Update(false);
                    end;
                }
                action(CheckTableRelations)
                {
                    AboutText = 'Runs through all records and uses the field relations defined in the table "Field" in Business Central to validate the table relations.';
                    AboutTitle = 'Check your tables for relation errors';
                    Caption = 'Check Table Relations';
                    Image = Relationship;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = false;
                    PromotedOnly = true;
                    ToolTip = 'This function runs through all records and uses the field relations defined in the table "Field" in Business Central to validate the table relations.';
                    trigger OnAction()
                    begin
                        AdminToolMgt.CheckTableRelations();
                        CurrPage.Update(false);
                    end;
                }
            }
            group(RecordDeletion)
            {
                Caption = 'Record Deletion';
                Image = Delete;

                action(SuggestsRecords)
                {
                    AboutText = 'Suggests you records that you may want to delete by checking off the field "Delete Records". This is useful if you want to "clean" a company from transactional data.';
                    AboutTitle = 'Your assistant if you want to delete all records from tables';
                    Caption = 'Suggest Records';
                    Ellipsis = true;
                    Image = Suggest;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Opens a dialog and ask you which records you want to delete. If you continue, the field "Delete records" of the suggested tables will be checked off in the table overview.';
                    trigger OnAction()
                    begin
                        AdminToolMgt.SuggestRecordsToDelete();
                        CurrPage.Update(false);
                    end;
                }
                action(DeleteRecords)
                {
                    AboutText = 'Use this action to delete the records that were suggested to you or that you marked for deletion yourself.';
                    AboutTitle = 'The bad evil executioner';
                    Caption = 'Delete Marked Records';
                    Ellipsis = true;
                    Image = Delete;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Opens a dialog and if confirmed deletes the records from the tables where the field "Delete Records" is checked off.';
                    trigger OnAction()
                    begin
                        AdminToolMgt.DeleteRecords();
                        CurrPage.Update(false);
                    end;
                }
                action(ClearRecords)
                {
                    AboutText = 'Clears the checkboxes of the field "Delete Records" in all tables.';
                    AboutTitle = 'Your fellow cleaning service';
                    Caption = 'Clear Selection';
                    Image = ClearFilter;
                    Promoted = true;
                    PromotedCategory = Category6;
                    PromotedIsBig = false;
                    PromotedOnly = true;
                    ToolTip = 'Clears the checkboxes of the field "Delete Records" in all tables.';
                    trigger OnAction()
                    begin
                        AdminToolMgt.ClearRecordsToDelete();
                        CurrPage.Update(false);
                    end;
                }
            }
            group(BackupRestore)
            {
                Caption = 'Backup & Restore';
                Image = Archive;

                action(ManageBackups)
                {
                    AboutText = 'View, create, restore and manage backups of your table data.';
                    AboutTitle = 'Manage Table Backups';
                    Caption = 'Manage Backups';
                    Image = Archive;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Opens the table backup management where you can view, create, restore and export/import backups.';

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Table Backup List");
                    end;
                }
                action(ViewAuditLog)
                {
                    AboutText = 'View the audit log of all delete and modify operations including field changes.';
                    AboutTitle = 'View Audit Log';
                    Caption = 'View Audit Log';
                    Image = EntryStatistics;
                    Promoted = true;
                    PromotedCategory = Category7;
                    PromotedIsBig = false;
                    PromotedOnly = true;
                    ToolTip = 'Opens the audit log where you can see all operations performed in the Admin Toolbox including who did what and when.';

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Audit Log Entries");
                    end;
                }
            }
            group(AppManagement)
            {
                Caption = 'App Management';
                Image = Installments;
                Visible = IsOnPrem;

                action(PublishApp)
                {
                    AboutText = 'Instead of using powershell, you can use this action to publish and install apps. The action will use the powershellrunner to publish and install the app.';
                    AboutTitle = 'Publish and Install apps without powershell';
                    Caption = 'Publish & Install App';
                    Ellipsis = true;
                    Image = Installments;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Publishes and installs the selected app by using the powershell runner.';

                    trigger OnAction()
                    var
                        AdminToolMgt: Codeunit "Admin Tool Mgt.";
                    begin
                        AdminToolMgt.PublishApp();
                    end;
                }
            }
        }
        area(Navigation)
        {
            action(Setup)
            {
                AboutText = 'Open the setup if you want to set up additional functionalities of the Admin Toolbox.';
                AboutTitle = 'About the setup';
                Caption = 'Setup';
                Image = Setup;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = page "Admin Toolbox Setup";
                ToolTip = 'Opens the setup of the Admin Toolbox.';
            }
        }
    }
    var
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
        IsOnPrem: Boolean;
        ShowInlineHelp: Boolean;
        CurrentTableID: Integer;
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
        WelcomeText1: Text;
        WelcomeText2: Text;
        WelcomeText3: Text;
        WelcomeText4: Text;

    trigger OnOpenPage()
    var
        AdminToolboxSetup: Record "Admin Toolbox Setup";
        UserPermissions: Codeunit "User Permissions";
        NoTableSelectedLbl: Label 'No table to run selected';
        ThreeDotsLbl: Label 'Use the three dots on the right to select a table that you want to run';
    begin
        if not UserPermissions.IsSuper(UserSecurityId()) then
            Error('');
        SelectedTableTxt := NoTableSelectedLbl;
        SelectedTableNoText := ThreeDotsLbl;
        IsOnPrem := EnvironmentInformation.IsOnPrem();

        // Load UI settings
        if not AdminToolboxSetup.Get() then begin
            AdminToolboxSetup.Init();
            AdminToolboxSetup.Insert(false);
        end;

        ShowInlineHelp := AdminToolboxSetup."Enable Inline Documentation";
        InitializeWelcomeTexts();
    end;

    local procedure InitializeWelcomeTexts()
    var
        Welcome1Lbl: Label '🛠️ Admin Toolbox provides powerful tools for system administration.';
        Welcome2Lbl: Label '⚠️ IMPORTANT: Always create backups before modifying or deleting data!';
        Welcome3Lbl: Label '✅ All operations are logged in the Audit Log for compliance.';
        Welcome4Lbl: Label '� Use the Dashboard for an overview of your system statistics.';
        ReadThisLbl: Label ' Please read this before proceeding:';
    begin
        WelcomeText1 := Welcome1Lbl + ReadThisLbl;
        WelcomeText2 := Welcome2Lbl;
        WelcomeText3 := Welcome3Lbl;
        WelcomeText4 := Welcome4Lbl;
    end;

    trigger OnAfterGetCurrRecord()
    var
        RecDeletion: Record "Record Deletion";
    begin
        CurrPage.Tables.Page.GetRecord(RecDeletion);
        if RecDeletion."Table ID" <> CurrentTableID then begin
            CurrentTableID := RecDeletion."Table ID";
            CurrPage.TableBackups.Page.SetTableFilter(CurrentTableID);
        end;
    end;
}