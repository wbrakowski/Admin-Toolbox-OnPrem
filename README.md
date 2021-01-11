# Admin-Toolbox-OnPrem

I've combined features from a few blog posts into one single app called "Admin-Toolbox": </br>
- [Record Deletion Tool](https://navinsights.net/2020/04/02/record-deletion-tool/ "Record Deletion Tool, Waldemar Brakowski")
- [View License Information](https://www.imbatman.info/post/using-powershell-in-microsoft-al-for-business-central-onprem "View License Information, Waldo")
- [Import Licenses](https://www.imbatman.info/post/using-powershell-in-microsoft-al-for-business-central-onprem "Import Licenses, Neil Roberts")
- [Not out of the box information for consultants, Waldo](https://www.waldo.be/2020/05/26/getting-not-out-of-the-box-information-with-the-out-of-the-box-web-client/ "Not out of the box information for consultants, Waldo") </br>

![Admin Toolbox](images/Toolbox.png)

Currently this page is only for OnPrem, because license information can only be displayed OnPrem and for the license import DotNet is used. </br>
If there is enough demand, I can create a SaaS version without the license area. </br> </br>

But that's not all. In addition, I have created a How To for consultants so that they can upload the app themselves without the help of developers. </br>

## How To Install the Toolbox

To allow consultants to use the app without the help of their developers, I compiled it for the different Business Central versions. </br>
You can download these different apps from a separate [GitHub Repository](https://github.com/wbrakowski/Admin-Toolbox-Apps "GitHub Repository"). </br> </br>

The [readme of the repository](https://github.com/wbrakowski/Admin-Toolbox-Apps/blob/main/README.md "readme of the repository") describes the individual steps for the installation. </br> </br>

Currently the following object numbers are used by the Admin Toolbox:
- Codeunits 50000, 50001
- Enum 50000
- Table 50000, 50001
- Page 50000-50002 </br>

In the toolbox, the languages German and English are maintained.



[this link](https://docs.microsoft.com/en-us/powershell/module/microsoft.dynamics.nav.apps.management/install-navapp?view=businesscentral-ps-16 "this link")
