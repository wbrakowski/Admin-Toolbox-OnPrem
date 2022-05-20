
#if OnPrem
dotnet
{

    assembly("Microsoft.Dynamics.Nav.PowerShellRunner")
    {
        PublicKeyToken = '31bf3856ad364e35';
        Version = '20.0.0.0';
        type("Microsoft.Dynamics.Nav.PowerShellRunner"; Powershellrunner) { }
    }

}
#endif
