page 50000 "Admin Toolbox"
{
    ApplicationArea = All;
    Caption = 'Admin Toolbox';
    DataCaptionFields = "Table Name";
    PageType = ListPlus;
    SourceTable = "Record Deletion";
    UsageCategory = Lists;
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
                        Hyperlink('https://github.com/wbrakowski/Admin-Tool-OnPrem/blob/main/README.md');
                    end;
                }
            }
            group(Options)
            {
                Caption = 'Options';
                field(View; Appearance)
                {
                    ApplicationArea = All;
                    Caption = 'View';

                    trigger OnValidate()
                    begin
                        UpdateControlVisibilities();
                    end;
                }
            }
            group(Tables)
            {
                Visible = not HideDeletionArea;
                Caption = 'Tables';
                repeater(General)
                {
                    field("Table ID"; "Table ID")
                    {
                        ApplicationArea = All;
                    }
                    field("Table Name"; "Table Name")
                    {
                        ApplicationArea = All;
                    }
                    // field(NoOfRecords; AdminToolMgt.CalcRecordsInTable("Table ID"))
                    // field(NoOfRecords; AdminToolMgt.CalcRecordsInTable("Table ID"))
                    // {
                    //     ApplicationArea = All;
                    //     Caption = 'No. of Records';

                    // }

                    field("No. of Table Relation Errors"; "No. of Table Relation Errors")
                    {
                        ApplicationArea = All;
                    }
                    field("No. of Records"; Rec."No. of Records")
                    {
                        ApplicationArea = All;
                    }
                    field("Delete Records"; "Delete Records")
                    {
                        ApplicationArea = All;
                    }
                }
            }

            part(LicenseInformation; "License Information")
            {
                ApplicationArea = All;
                Visible = not HideLicenseArea;
            }

            group(Information)
            {
                Caption = 'Information';
                Editable = false;
                Visible = not HideInformationArea;
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
                Visible = not HideDeletionArea;

                trigger OnAction()
                begin
                    AdminToolMgt.InsertUpdateTables();
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
                Visible = not HideDeletionArea;
                trigger OnAction()
                begin
                    AdminToolMgt.SuggestRecordsToDelete();
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
                Visible = not HideDeletionArea;
                trigger OnAction()
                begin
                    AdminToolMgt.ClearRecordsToDelete();
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
                Visible = not HideDeletionArea;
                trigger OnAction()
                begin
                    AdminToolMgt.DeleteRecords();
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
                Visible = not HideDeletionArea;
                trigger OnAction()
                begin
                    AdminToolMgt.CheckTableRelations();
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
                Visible = not HideDeletionArea;
                trigger OnAction()
                begin
                    AdminToolMgt.ViewRecords(Rec);
                end;
            }
        }

    }
    var
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        HideDeletionArea: Boolean;
        HideInformationArea: Boolean;
        HideLicenseArea: Boolean;
        Appearance: Enum Appearance;
        LastAppearance: Enum Appearance;
        ActiveSessionLbl: Label 'Active Session';
        SessionEventLbl: Label 'Session Event';
        EventSubscriptionLbl: Label 'Event Subscription';
        TableMetadataLbl: Label 'Table Metadata';
        CodeunitMetadataLbl: Label 'Codeunit Metadata';
        PageMetadataLbl: Label 'Page Metadata';
        AllObjectsLbl: Label 'All Objects';
        FieldLbl: Label 'Field';
        KeyLbl: Label 'Key';
        RecordLinkLbl: Label 'Record Link';
        APIWebhookSubscriptionLbl: Label 'API Webhook Subscription';
        APIWebhookNotificationLbl: Label 'API Webhook Notification';
        HowToLbl: Label 'Learn how to use this tool';
        SessionInformationLbl: Label 'Session Information';

    trigger OnAfterGetCurrRecord()
    begin
        Appearance := LastAppearance;
    end;

    local procedure UpdateControlVisibilities()
    begin
        LastAppearance := Appearance;
        case Appearance of
            Appearance::All:
                begin
                    Clear(HideDeletionArea);
                    Clear(HideLicenseArea);
                    Clear(HideInformationArea);
                end;
            Appearance::License:
                begin
                    Clear(HideLicenseArea);
                    HideDeletionArea := true;
                    HideInformationArea := true;
                end;
            Appearance::Tables:
                begin
                    Clear(HideDeletionArea);
                    HideLicenseArea := true;
                    HideInformationArea := true;
                end;
            Appearance::Information:
                begin
                    Clear(HideInformationArea);
                    HideLicenseArea := true;
                    HideDeletionArea := true;
                end;
            else
        // Here be dragons
        end;
    end;
}