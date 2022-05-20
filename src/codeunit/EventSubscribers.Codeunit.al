codeunit 51002 "Event Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', true, true)]
    local procedure CompanyTriggers_OnCompanyOpen()
    var
        ActiveSession: Record "Active Session";
        AdminToolMgt: Codeunit "Admin Tool Mgt.";
        EnvironmentInformation: Codeunit "Environment Information";
        UserPermissions: Codeunit "User Permissions";
    begin
        if not EnvironmentInformation.IsOnPrem() or not GuiAllowed or not ActiveSession.Get(Database.ServiceInstanceId(), SessionId()) then
            exit;
        // if AdminToolMgt.UserHasPermissions() then
#if OnPrem
        if UserPermissions.IsSuper(UserSecurityId()) then
            AdminToolMgt.ShowDevLicenseMessageIfNeeded();
#endif
    end;
}