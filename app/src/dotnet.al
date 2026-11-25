#if OnPrem
dotnet
{
    assembly("Microsoft.Dynamics.Nav.PowerShellRunner")
    {
        PublicKeyToken = '31bf3856ad364e35';
        type("Microsoft.Dynamics.Nav.PowerShellRunner"; PowerShellRunner) { }
    }
}
#endif
