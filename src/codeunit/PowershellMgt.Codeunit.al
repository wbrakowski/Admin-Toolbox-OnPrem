codeunit 51001 "Powershell Mgt."
{
#if OnPrem
    [Scope('OnPrem')]
    procedure ImportLicense()
    var
        ActiveSession: Record "Active Session";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        UpdateDialog: Dialog;
        PowerShellRunner: DotNet PowerShellRunner;
        AllFilesFilterTxt: Label '*.*';
        BusyDlgLbl: Label 'Busy importing......';
        FileFilterLbl: Label 'License (*.flf)|*.flf|All Files (*.*)|*.*';
        NAVAdminToolLbl: Label 'NavAdminTool.ps1';
        SelectFileTxt: Label 'Select License File';
        FileName: Text;
    begin
        FileName := FileManagement.BLOBImportWithFilter(TempBlob, SelectFileTxt, '', FileFilterLbl, AllFilesFilterTxt);
        if FileName = '' then
            exit;

        FileName := TemporaryPath + FileName;
        if Exists(FileName) then
            Erase(FileName);

        FileManagement.BLOBExportToServerFile(TempBlob, FileName);

        ActiveSession.Get(ServiceInstanceId(), SessionId());
        PowerShellRunner := PowerShellRunner.CreateInSandbox();
        PowerShellRunner.WriteEventOnError := true;
        PowerShellRunner.ImportModule(ApplicationPath + NAVAdminToolLbl);
        PowerShellRunner.AddCommand('Import-NAVServerLicense');
        PowerShellRunner.AddParameter('ServerInstance', ActiveSession."Server Instance Name");
        PowerShellRunner.AddParameter('LicenseFile', FileName);
        PowerShellRunner.BeginInvoke();

        UpdateDialog.Open(BusyDlgLbl);

        while not PowerShellRunner.IsCompleted() do
            Sleep(1000);
        UpdateDialog.Close();
    end;
#endif
}