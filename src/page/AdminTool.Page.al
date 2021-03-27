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
    layout
    {
        area(content)
        {
            group(Howto)
            {
                Caption = 'How To';
                field(HowToLbl; HowToLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        AdminToolMgt.OpenReadme();
                    end;
                }
            }
            part(Tables; "Record Deletion")
            {
                ApplicationArea = All;
                // Visible = ShowLicenseArea;
            }

            part(LicenseInformation; "License Information")
            {
                ApplicationArea = All;
                // Visible = ShowLicenseArea;
            }

            group(Information)
            {
                Caption = 'Information';
                Editable = false;
                // Visible = ShowInformationArea;
                group(Session)
                {
                    Caption = 'Session';
                    field(SessionInformationLbl; SessionInformationLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

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

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"Session Event");
                        end;
                    }
                }
                group(Events)
                {
                    Caption = 'Event';
                    field(EventSubscriptionLbl; EventSubscriptionLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"Event Subscription");
                        end;
                    }
                    field(SessionEvent2Lbl; SessionEventLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

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

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"Codeunit Metadata");
                        end;
                    }
                    field(PageMetadataLbl; PageMetadataLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

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

                        trigger OnDrillDown()
                        begin
                            AdminToolMgt.OpenTable(Database::"License Permission");
                        end;
                    }
                }
                group(Select)
                {
                    Caption = 'Table Selector';
                    field(SelectedTableNoText; SelectedTableNoText)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnAssistEdit()
                        var
                            AllObjWithCaption: Record AllObjWithCaption;
                            TableObjects: Page "Table Objects";
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
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                trigger OnAction()
                begin
                    AdminToolMgt.ClearRecordsToDelete();
                    CurrPage.Update(false);
                end;
            }
            action(DeleteRecords)
            {
                ApplicationArea = All;
                Caption = 'Delete Records';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
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
                trigger OnAction()
                var
                    RecordDeletion: Record "Record Deletion";
                begin
                    CurrPage.Tables.Page.GetRecord(RecordDeletion);
                    AdminToolMgt.ViewRecords(RecordDeletion);
                end;
            }
            action(PublishApp)
            {
                ApplicationArea = All;
                Caption = 'Publish App';
                Image = Installments;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    AdminToolMgt: Codeunit "Admin Tool Mgt.";
                begin
                    AdminToolMgt.PublishApp();
                end;
            }
        }

    }
    var
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        SelectedTableNo: Integer;
        ActiveSessionLbl: Label 'Active Session';
        AllObjectsLbl: Label 'All Objects';
        APIWebhookNotificationLbl: Label 'API Webhook Notification';
        APIWebhookSubscriptionLbl: Label 'API Webhook Subscription';
        CodeunitMetadataLbl: Label 'Codeunit Metadata';
        EventSubscriptionLbl: Label 'Event Subscription';
        FieldLbl: Label 'Field';
        KeyLbl: Label 'Key';
        HowToLbl: Label 'Learn how to use this tool';
        LicensePermissionLbl: Label 'License Permission';
        PageMetadataLbl: Label 'Page Metadata';
        RecordLinkLbl: Label 'Record Link';
        SessionEventLbl: Label 'Session Event';
        SessionInformationLbl: Label 'Session Information';
        TableMetadataLbl: Label 'Table Metadata';
        SelectedTableNoText: Text;
        SelectedTableTxt: Text;

    trigger OnOpenPage()
    var
        NoTableSelectedLbl: Label 'No table to run selected';
        ThreeDotsLbl: Label 'Use the three dots on the right to select a table that you want to run';
    begin
        SelectedTableTxt := NoTableSelectedLbl;
        SelectedTableNoText := ThreeDotsLbl;
        AdminToolMgt.UpdateTablesIfEmpty();
    end;
}