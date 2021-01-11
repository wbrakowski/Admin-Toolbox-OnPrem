# Admin-Toolbox-OnPrem

I've combined features from a few blog posts into one single app called "Admin-Toolbox": </br>
- [Record Deletion Tool](https://navinsights.net/2020/04/02/record-deletion-tool/ "Record Deletion Tool, Waldemar Brakowski")
- [View License Information](https://www.waldo.be/2021/01/07/check-customer-license-in-an-onprem-db-from-the-web-client/ "View License Information, Waldo")
- [Import Licenses](https://www.imbatman.info/post/using-powershell-in-microsoft-al-for-business-central-onprem "Import Licenses, Neil Roberts")
- [Not out of the box information for consultants, Waldo](https://www.waldo.be/2020/05/26/getting-not-out-of-the-box-information-with-the-out-of-the-box-web-client/ "Not out of the box information for consultants, Waldo") </br>

Currently this page is only for OnPrem, because license information can only be displayed OnPrem and for the license import DotNet is used. </br>
If there is enough demand, I can create a SaaS version without the license area. </br> 

In addition, I have created a How To for consultants so that they can upload the app themselves without the help of developers. </br>

## How To Install the Toolbox

To enable consultants to use this app, I compiled it for the different Business Central versions. </br>
You can download these different apps from a separate [GitHub Repository](https://github.com/wbrakowski/Admin-Toolbox-Apps "GitHub Repository"). </br> 

The [readme of the repository](https://github.com/wbrakowski/Admin-Toolbox-Apps/blob/main/README.md "readme of the repository") describes the individual steps for the installation. </br> </br>

Currently the following object numbers are used by the Admin Toolbox:
- Codeunits 50000, 50001
- Enum 50000
- Table 50000, 50001
- Page 50000-50002 </br>

In the toolbox, the languages German and English are maintained.

## How To Use the Toolbox

After successful installation you will find the toolbox under the search term "Admin Toolbox". </br>

![Search Toolbox](images/SearchToolbox.png)

The toolbox is divided into four areas:
- How To
- Options
- License Information
- Information </br>

![Admin Toolbox](images/Toolbox.png)

The link in the FastTab "How To" will take you directly to the readme you are reading right now. </br>

![Howto](images/HowTo.png)

You can use the "View" field to control the visibility of the controls in the page. </br>
When you open the page, all controls are displayed at first. </br>
If you change the view to "License", only the license information and the corresponding PageActions are displayed. </br>

![ViewOptions](images/ViewOptions.png)

### Record Deletion Tool

The Tables area shows you all the tables in the system except the system tables. </br>
It also contains functionalities to delete records from these tables. </br> </br>

Part of the following descriptions were copied from [Olof Simren's original post](http://www.olofsimren.com/record-deletion-tool-for-dynamics-nav-2015/ "Olof Simren's original post") for the Record Deletion Tool. </br>
He created the original version for Microsoft Dynamics NAV. </br>
I rebuilt the tool and added some new functions to it. </br> 

This data deletion tool is useful if you want to 'clean' a company from transactional data. </br>
It could for example be that you have been testing transactions in a company that you want to use for a go-live. </br>
It is also useful if you just want to have a clean company without transactions for a demo, training or testing session. </br> 

Use the PageAction "Insert/Update Tables". This will populate the list with all the tables that are in the database. </br>
System tables are excluded here. If you afterwards add new tables you can run this function again to have them added. </br>

![InsertTables](images/InsertTables.png)

After you used the function, the tables are now available in the list. </br>

![TableList](images/TableList.png)

Then you go through and select the tables you want to delete records from by checking the "Delete Records" field. </br>
The PageActrion "Suggest Records to Delete" can suggest records for you to delete by providing you with these two options:
- Suggest all transactional records to delete
- Suggest unlicensed partner or custom records to delete

Use the first option to select the tables you typically want to delete records from when cleaning a company from transactional data. </br>

Use the second option to suggest unlicensed partner or custom records to delete. </br>
This may be useful if you used a developer license in the system at some point and created records with that license. </br>
Now you want to switch back to the customer license and have errors in the system because of these still existing records.
<b>Note:</b> This second option must be used with the customer license. </br>
After you have suggested the records, you need to import the developer license to delete the records. </br>

![SuggestOptions](images/SuggestOptions.png)

<b>Note that the suggestion of tables may be incomplete or the logic faulty, but for my cases it worked. </br>
You should always check the suggested records manually afterwards and select additional tables if necessary! </b> </br> 

Also note that I am not responsible if this suggestion selects something you don’t want to delete or skips something that you do want to delete. </br>

![SuggestRecords](images/SuggestRecords.png)

Use the "Clear Records to Delete" function to remove all the selections. </br>

![ClearRecords](images/ClearRecords.png)

When you are happy with the selection you press "Delete Records". </br>
Business Central now goes through the tables and deletes all records from each of the selected tables. </br>
</b>It might make sense to do a backup of the data before you do this. </b> </br> 

I typically just copy the company before this step, so at least you have a company that can easily be restored or copy/paste data from. </br>

![DeleteRecords](images/DeleteRecords.png)

Note that you can delete records either by running the deletion trigger or not. </br>
The default option is to delete records without using the deletion trigger. </br>

![DeleteOptions](images/DeleteOptions.png)

Before the deletion is being executed, you get an information how many tables were marked for deletion. </br>

![TablesMarked](images/TablesMarked.png)

After pressing "Yes", you can watch the system do its work. </br>

![DeletingRecords](images/DeletingRecords.png) 

...and you get a success message after the operation has finished. </br>

![DeleteSuccess](images/DeleteSuccess.png) 

Note that the field "No. of Records" is updated after the operation. </br>

![NoOfRecords](images/NoOfRecords.png)

After the records have been deleted it is recommended to review the tables that still have data in them to make sure you have not missed anything. </br>
The easiest way to do this is to just apply a filter on the "No. of Records" field to be <>0. </br>

![NoOfRecordsFilter](images/NoOfRecordsFilter.png)

Use the "View Records" function to view the records in the tables. </br>
When selecting "View Records" the table will be run to show all the records and all the fields, like below. </br>

![ViewRecords](images/ViewRecords.png)

![ViewRecordsList](images/ViewRecordsList.png)

When looking at the records it is typically quite easy to see if they should have been deleted or not. </br>
If the records has an entry number, document number, etc. it is most likely transactional data that should be deleted. </br>
The number of records in the table could sometimes also give you a hint if it should be deleted or not. </br> </br>

The next option when reviewing the remaining data is to use the "Check Table Relations" function. </br>
This function runs through all records and uses the field relations defined in the table "Field" in Business Central to validate the table relations. </br>
It does so by just looking if the related record is in the database or not. </br>
Note that this only checks the very basic relations where a field has a table relation to a field in another table. </br>
This is similar to the table relations you find in the FactBox in the configuration worksheet. </br>
It does not check table relations that involve multiple fields or conditional table relations. </br>
It is still a good check I think. </br>

![CheckTableRelations](images/CheckTableRelations.png)

As this is a time consuming operation, you need to confirm before the table relations are being checked. </br>

![CheckTableRelationsConfirm](images/CheckTableRelationsConfirm.png)

Watch the system work. </br>

![CheckingRelations](images/CheckingRelations.png)

After the check on the table relations has run you can set a filter on the "No. of Table Relations Errors" to be <> 0. </br>
 You should then see if there are any basic table relation errors. </br>

 ![NoOfErrorsFilter](images/NoOfErrorsFilter.png)

 If there are any errors you can make a drilldown on the number to see the errors. </br>

 ![ErrorsDrilldown](images/ErrorsDrilldown.png)

 These are the table relation errors in my example: </br>

 ![DrilldownExample](images/DrilldownExample.png)

 As mentioned above, the table relation check is only doing a basic check, so don’t rely too much on it. </br>
 If you have a large amount of master data it might also take a while to run. </br>

 ### License Overview and Import

 The area "License" shows you the license information. </br>
 It is using the field "Text" from the table "License Information" to present you the information. </br>

![License](images/License.png)

You can import a new license by using the "Manage" -> "Import License" function. </br>

![ImportLicense](images/ImportLicense.png)

Select a new license file and be happy. </br>

![SelectLicense](images/SelectLicense.png)

### Links to Informational Tables

Find links to useful tables in the area "Information". I used the links from [Waldo's blogpost](https://www.waldo.be/2020/05/26/getting-not-out-of-the-box-information-with-the-out-of-the-box-web-client/, "Waldo's Blogpost"). </br>

![Information](images/Information.png)

By clicking on a link a new tab will be created that leads you to the page. </br>

![SessionInformation](images/SessionInformation.png) 

![SessionInformationTable](images/SessionInformationTable.png) 
