![Showcase Image](media/showcase.png)

## What is DPoC?
DREAM PoC Accelerators (DPoC) are packaged DREAM Demos using ARM templates and automation scripts (with a demo web application, Power BI reports, Fabric resources, Azure OpenAI services, ML Notebooks etc.) that can be deployed in a customer’s Azure environment.

## Objective & Intent
Partners can deploy DREAM Demos in their own Azure subscriptions and demonstrate them live to their customers. 
Partnering with Microsoft sellers, partners can deploy the Industry scenario DREAM demos into customer subscriptions. 
Customers can play, get hands-on experience navigating through the demo environment in their own subscription and show it to their own stakeholders.

**Here are some important guidelines before you begin** 

1. **Read the [license agreement](/license.md) and [disclaimer](/disclaimer.md) before proceeding, as your access to and use of the code made available hereunder is subject to the terms and conditions made available therein.**
2. Without limiting the terms of the [license](/license.md) , any Partner distribution of the Software (whether directly or indirectly) must be conducted through Microsoft’s Customer Acceleration Portal for Engagements (“CAPE”). CAPE is accessible to Microsoft employees. For more information aregarding the CAPE process, contact your local Data & AI specialist or CSA/GBB.
3. It is important to note that **Azure hosting costs** are involved when DREAM PoC Accelerator is implemented in customer or partner Azure subscriptions. DPoC hosting costs are not covered by Microsoft for partners or customers.
4. Since this is a DPoC, there are certain resources available to the public. **Please ensure that proper security practices are followed before adding any sensitive data to the environment.** To strengthen the environment's security posture, **leverage Azure Security Centre.** 
5.  In case of questions or comments; please email **[dreamdemos@microsoft.com](mailto:dreamdemos@microsoft.com).**

## Disclaimer
**This is a demonstration showing the art of the possible. Note that there is currently no Azure OpenAI service implementation in this demo.**

## Contents

<!-- TOC -->

- [Requirements](#requirements)
- [Before Starting](#before-starting)
  - [Task 1: Power BI Workspace creation](#task-1-power-bi-workspace-creation)
  - [Task 2: Run the Cloud Shell to provision the demo resources](#task-2-run-the-cloud-shell-to-provision-the-demo-resources)
  - [Task 3: Creating a Shortcut in Lakehouse](#task-3-creating-a-shortcut-in-lakehouse)
  - [Task 4: Running Notebooks](#task-4-running-notebooks)
  - [Task 5: Creating Pipelines and Dataflows](#task-5-creating-pipelines-and-dataflows)

- [Appendix](#appendix)
  - [Creating a Resource Group](#creating-a-resource-group)

<!-- /TOC -->

## Requirements

* A Power BI with Fabric License to host Power BI reports.
* Make sure your Power BI administrator can provide service principal access on your Power BI tenant.
* Make sure to register the following resource providers with your Azure Subscription:
   - Microsoft.Fabric
   - Microsoft.StorageAccount
   - Microsoft.AppService
* You must only execute one deployment at a time and wait for its completion. Running multiple deployments simultaneously is highly discouraged, as it can lead to deployment failures.
* Select a region where the desired Azure Services are available. If certain services are not available, deployment may fail. See [Azure Services Global Availability](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=all) for understanding target service availability.
* In this Accelerator, we have converted real-time reports into static reports for the users' ease but have covered the entire process to configure real-time dataset. Using those real-time dataset, you can create real-time reports.
* Make sure you use the same valid credentials to log into Azure and Power BI.
* Review the [License Agreement](/license.md) before proceeding.

### Task 1: Power BI Workspace creation

1. **Open** Power BI in a new tab by clicking [HERE](https://app.powerbi.com/)

2. **Sign in** to Power BI.

	![Sign in to Power BI.](media/power-bi.png)

	> **Note:** Use your Azure Active Directory credentials to login to Power BI.

3. In Power BI service **click** 'Workspaces'.

4. **Click** '+ New workspace' button.

	![Create Power BI Workspace.](media/power-bi-2.png)

5. **Enter** the name as 'smartCity' and **click** 'Apply'.

>**Note:** The name of the workspace should be in camel case, i.e. the first word starting with a small letter and then the second word staring with a capital letter with no spaces in between.

>If name 'smartCity' is already taken, add some suffix to the end of the name for eg. 'smartCityTest'.

>Workspace name should not have any spaces.

   ![Create Power BI Workspace.](media/power-bi-4.png)

6. **Copy** the Workspace GUID or ID from the address URL.

7. **Save** the GUID in a notepad for future reference.

	![Give the name and description for the new workspace.](media/power-bi-3.png)

	> **Note:** This workspace ID will be used during powershell script execution.

8. In the workspace **click** the three dots(Ellipsis) and **select** 'Workspace settings'.

	![Give the name and description for the new workspace.](media/power-bi-6.png)

9. In the left pane of the side bar **click** 'Premium', scroll down and **check** the 'Fabric capacity' radio box.

	![Give the name and description for the new workspace.](media/power-bi-7.png)

10. **Scroll down** and **click** on 'Apply'.

	![Give the name and description for the new workspace.](media/power-bi-8.png)

11. **Navigate** to the repository link. **Click** on 'Repos' and **click** on the 'Clone' button.

	![Give the name and description for the new workspace.](media/gitcred1.png)

12. **Click** on 'Generate Git Credentials'.

	![Give the name and description for the new workspace.](media/gitcred2.png)

13. **Copy** the password generated. You will need it when cloning the repository in [Task 2](#task-2-run-the-cloud-shell-to-provision-the-demo-resources) step 9.

	![Give the name and description for the new workspace.](media/gitcred3.png)

### Task 2: Run the Cloud Shell to provision the demo resources

>**Note:** For this Demo we have assets in an Azure resource group as well as Fabric Workspaces

>**Note:** In this task we will execute a powershell script on Cloudshell to create those assets

>**Note:** List of the resources are as follows:

**Azure resources:**
|NAME	|TYPE|
|-----|-----|
|app-smart-city-{suffix}	|App Service	|
|asp-smart-city-{suffix}	|App Service plan	|
|stsmartcity{suffix}	|Storage account	|
| | |


**Fabric resources:**
| displayName | type |
|-----------|------|
|lakehouseBronze{suffix}                                                |Lakehouse|
|lakehouseBronze{suffix}                                                | SemanticModel|
|lakehouseBronze{suffix}                                            |     SQLEndpoint|
|lakehouseSilver{suffix}                            |                     Lakehouse|
|lakehouseSilver{suffix}                                              |   SemanticModel|
|lakehouseSilver{suffix}                                             |    SQLEndpoint|
|Contoso City Call Center Report (After)               |              Report|
|Contoso City Call Center Report (Before)                    |            Report|
|Fleet Manager Dashboard                                       |           Report|
|Master Images                                      |          Report|
|Mayor Dashboard                                  |         Report|
|NYC_AQI                                                       |        Report|
|Power Management                                                 |       Report|
|Transport Deep Dive                                                 |      Report|
|Contoso City Call Center Report (After)             |                SemanticModel|
|Contoso City Call Center Report (Before)                  |              SemanticModel|
|Fleet Manager Dashboard                                     |             SemanticModel|
|Master Images                                    |            SemanticModel|
|Mayor Dashboard                                |           SemanticModel|
|NYC_AQI                                                     |          SemanticModel|
|Power Management                                               |         SemanticModel|
|Transport Deep Dive                                               |        SemanticModel|
|Bronze_to_Silver_layer_Medallion_Architecture.ipynb	|   Notebook|
|  |  |


1. **Open** Azure Portal by clicking [HERE](https://portal.azure.com/)

2. In the Resource group section, **select** the Terminal icon to open Azure Cloud Shell.

	![A portion of the Azure Portal taskbar is displayed with the Azure Cloud Shell icon highlighted.](media/cloud-shell.png)

3. **Click** on the 'PowerShell'.

4. **Click** 'Show advanced settings'.

	![Mount a Storage for running the Cloud Shell.](media/cloud-shell-2.png)

	> **Note:** If you already have a storage mounted for Cloud Shell, you will not get this prompt. In that case, skip step 5 and 6.

5. **Select** your 'Subscription', 'Cloud Shell region' and 'Resource Group'.

>**Note:** If you do not have an existing resource group please follow the steps mentioned [HERE](#creating-a-resource-group) to create one. Complete the task and then continue with the below steps.

>Cloud Shell region need not be specific, you may select any region which works best for your experience.

6. **Enter** the 'Storage account', 'File share' name and then **click** on 'Create storage'.

	![Mount a storage for running the Cloud Shell and Enter the Details.](media/cloud-shell-3.png)

	> **Note:** If you are creating a new storage account, give it a unique name with no special characters or uppercase letters. The whole name should be in small case and not more than 24 characters.

	> It is not mandatory for storage account and file share name to be same.

7. In the Azure Cloud Shell window, ensure that the PowerShell environment is selected.

	![Git Clone Command to Pull Down the demo Repository.](media/cloud-shell-3.1.png)

	>**Note:** All the cmdlets used in the script works best in Powershell.	

8. **Enter** the following command to clone the repository files in cloudshell.

Command:
```
git clone -b main --depth 1 --single-branch https://daidemos@dev.azure.com/daidemos/Microsoft%20Data%20and%20AI%20DREAM%20Demos%20and%20DDiB/_git/Sustainability%20Smart%20Cities%20DPoC smartcities
```

   ![Git Clone Command to Pull Down the demo Repository.](media/cloud-shell-4.5.png)
	
   > **Note:** If you get File already exist error, please execute the following command to delete existing clone and then reclone:
```
 rm smartcities -r -f 
```
   > **Note**: When executing scripts, it is important to let them run to completion. Some tasks may take longer than others to run. When a script completes execution, you will be returned to a command prompt. 

9. **Enter** the password for cloning the repo which you copied in [Task 1](#task-1-power-bi-workspace-creation) step 13.

	![Git Clone Command to Pull Down the demo Repository.](media/cloud-shell-4.6.png)

10. **Execute** the Powershell script with the following command:
```
cd ./smartcities
```

```
./smartcitySetup.ps1
```
    
   ![Commands to run the PowerShell Script.](media/cloud-shell-5.1.png)
      
11. From the Azure Cloud Shell, **copy** the authentication code. You will need to enter this code in next step.

12. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin) and a new browser window will launch.

	![Authentication link and Device Code.](media/cloud-shell-6.png)
     
13. **Paste** the authentication code.

	![New Browser Window to provide the Authentication Code.](media/cloud-shell-7.png)

14. **Select** the user account that is used for logging into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

	![Select the User Account which you want to Authenticate.](media/cloud-shell-8.png)

15. **Click** on 'Continue' button.

	![Select the User Account which you want to Authenticate.](media/cloud-shell-8.1.png)

16. **Close** the browser tab once you see the message box.

	![Authentication done.](media/cloud-shell-9.png)  

17. **Navigate back** to your Azure Cloud Shell execution window.

18. **Copy** the code on screen to authenticate Azure PowerShell script for creating reports in Power BI.

18. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin).

	![Authentication link and Device code.](media/cloud-shell-10.png)

19. A new browser window will launch.

20. **Paste** the authentication code you copied from the shell above.

	![Enter the Resource Group name.](media/cloud-shell-11.png)

21. **Select** the user account that is used for logging into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

	![Select Same User to Authenticate.](media/cloud-shell-12.png)

22. **Click** on 'Continue'.

	![Select Same User to Authenticate.](media/cloud-shell-12.1.png)

23. **Close** the browser tab once you see the message box.

	![Close the browser tab.](media/cloud-shell-13.png)

24. **Go back** to Azure Cloud Shell execution window.

25. **Copy** your subscription name from the screen and **paste** it in the prompt.

    ![Close the browser tab.](media/select-sub.png)
	
	> **Notes:**
	> - The user with single subscription won't be prompted to select subscription.
	> - The subscription highlighted in yellow will be selected by default if you do not enter any disired subscription. Please select the subscription carefully, as it may break the execution further.
	> - While you are waiting for processes to get completed in the Azure Cloud Shell window, you'll be asked to enter the code three times. This is necessary for performing installation of various Azure Services and preloading the data.

26. In case of multiple subscription, **enter** 'Y' to confirm your subscription.

	![Close the browser tab.](media/cloud-shell-13.1.png)

27. **Enter** the Region for deployment with necessary resources available, preferably "eastus". (ex. eastus, eastus2, westus, westus2 etc)

	![Enter Resource Group name.](media/cloudshell-region.png)

>**Note:** It will take sometime for the script to create the resources in the resource group.

28. **Enter** the workspace id which you copied in Step 6 of [Task 1](#task-1-power-bi-workspace-and-lakehouse-creation).

	![Enter Resource Group name.](media/cloud-shell-14.1.png)

29. From the Azure Cloud Shell, **copy** the authentication code. You will need to enter this code in next step.

30. **Click** the link [https://microsoft.com/devicelogin](https://microsoft.com/devicelogin) and a new browser window will launch.

	![Authentication link and Device Code.](media/cloud-shell-14.3.png)
     
31. **Paste** the authentication code.

	![New Browser Window to provide the Authentication Code.](media/cloud-shell-7.png)

32. **Select** the user account that is used for logging into the Azure Portal in [Task 1](#task-1-create-a-resource-group-in-azure).

	![Select the User Account which you want to Authenticate.](media/cloud-shell-8.png)

33. **Click** on 'Continue' button.

	![Select the User Account which you want to Authenticate.](media/cloud-shell-8.1.png)

34. **Close** the browser tab once you see the message box.

	![Authentication done.](media/cloud-shell-14.4.png)  

35. **Navigate back** to your Azure Cloud Shell execution window.

	> **Note:** The deployment will take approximately 10-15 minutes to complete. Keep checking the progress with messages printed in the console to avoid timeout.

36. After the script execution is complete, the user is prompted "--Execution Complete--"

>**Note:** The screenshot below shows how the resources would look like:

**Azure Resource Group:**

![Authentication done.](media/resources-1.png)  

**Fabric Workspace:**

![Authentication done.](media/resources-2.png)  


### Task 3: Creating a Shortcut in Lakehouse

1. **Open** [Power BI](app.powerbi.com)

2. In PowerBI, **click** 'Workspaces' and **select** 'smartCity'

    ![Lakehouse.](media/demo-4.png)

3. In 'smartCity' workspace, **click** on 'lakehouseBronze' lakehouse.

    ![Lakehouse.](media/lakehouse-1.png)

4. In the lakehouse window **click** on the three dots in front of Files.

5. **Click** on 'New shortcut'.

	![Lakehouse.](media/lakehouse-2.png)

6. In the pop-up window, under External sources **select** 'Azure Data Lake Storage Gen2'

	![Lakehouse.](media/demo-9.png)

7. In a new tab **open** the resource group created in [Task 2](#task-2-run-the-cloud-shell-to-provision-the-demo-resources) while script execution with name 'smartcity-dpoc-...'.

8. **Search** for 'storage account', **click** on the storage account name starts with 'stsmartcity'.

	![Lakehouse.](media/demo-10.png)

9. In the resource window **goto** the left pane and **scroll down**.

10. In 'Security + networking' section, **click** 'Access keys'.

11. **Click** 'Show' button under key1.

	![Lakehouse.](media/demo-11.png)

12. **Click** 'Copy to clickboard' button.
13. **Save** it in a notepad for further use.

	![Lakehouse.](media/demo-12.png)

14. **Scroll down** in the left pane.
15. **Select** 'Endpoints' from 'Settings' section.
16. **Scroll down** and **copy** the 'Data Lake Storage' endpoint under 'Data Lake Storage' section.
17. **Save** it in a notepad for further use.

	![Lakehouse.](media/demo-12.1.png)

>**Note:** You may see different endpoints as well in the above screen. Make sure to select only the Data Lake Storage endpoint.

18. **Navigate back** to Power BI workspace i.e. the powerbi tab which we working earlier.

19. **Select** the 'Create new connection' radio button.

20. **Paste** the endpoint copied under the 'URL' field.

21. In the 'Authentiation kind' dropdown, **select** 'Account Key'.

22. **Paste** the account key copied in step number 13.

23. **Click** on 'Next'.

	![Lakehouse.](media/demo-12.2.png)

24. **Click** on the 'bronzelakehousefiles' dropdown, **select** the 'city_aqi_data' checkbox and then **click** on the 'Next' button.

	![Lakehouse.](media/lakehouse-3.png)

25. **Click** on the 'Create' button.

	![Lakehouse.](media/lakehouse-4.png)

### Task 4: Running Notebooks

1. In the workspace **click** on the "Bronze_to_Silver_layer_Medallion_Architecture" notebook.

	![Datawarehouse.](media/notebook-1.png)

2. In the left pane **click** on '+ Data source' button and **select** 'Lakehouses'.

	![Datawarehouse.](media/notebook-2.png)

3. In the pop-up **select** 'Existing Lakehouse' radio button and then **click** on the 'Add' button.

	![Datawarehouse.](media/notebook-5.png)

4. **Click** on 'lakehouseBronze' checkbox and **click** on the 'Add' button.

	![Datawarehouse.](media/notebook-6.png)

5. **Click** on the 'Run all' button.
   >**Note:** For demo purposes, data has already been loaded to silver lakehouse.

    ![Datawarehouse.](media/notebook-7.png)

### Task 5: Creating Pipelines and Dataflows

1. While you are in the 'smartCity' workspace **click** '+ New' button and **select** 'More options'.

	![Pipeline.](media/pipeline-1.png)

2. Under Data Factory section, **select** 'Dataflow Gen2.

	![Pipeline.](media/pipeline-2.png)

3. In the dataflow window, **click** the default dataflow name 'Dataflow 1' and in the Name field **type** 'Customer Insights Data from Dataverse' finally **click** somewhere outside the rename box to update the dataflow name.

	![Pipeline.](media/pipeline-3.png)

4. **Click** 'Get data' and **click** 'More...'.

	![Pipeline.](media/pipeline-4.png)

5. **Click** 'Dataverse'.

	![Pipeline.](media/pipeline-5.png)

6. **Enter** your Dynamics 365 credentials if available and then **click** 'Next' button.

>**Note:** For demo purposes, this data has already been loaded.

> You can connect you own data from Dataverse to Fabric using this Dataflow Gen2.

![Pipeline.](media/pipeline-6.png)

7. **Go back** to the workspace, **click** '+ New' and **select** 'More options'.

![Pipeline.](media/pipeline-1.png)

8. Under Data Factory section, **select** 'Data pipeline.

![Pipeline.](media/pipeline-7.png)

9. **Type** the name as 'Customer Insights Dataflow trigger from Data' and **click** 'Create'.

![Pipeline.](media/pipeline-8.png)

10. Wait for the pipeline to create, **click** 'Add pipeline activity' and **click** 'Dataflow'.

	![Pipeline.](media/pipeline-9.png)

11. **Click** the new dataflow activity, in General tab **type** the name as 'Customer Insights Data to Lakehouse'.

	![Pipeline.](media/pipeline-10.png)

12. In the Settings tab **attach** it to the dataflow created in the earlier steps.

	![Pipeline.](media/pipeline-11.png)

### Appendix

### Creating a Resource Group

1. **Log into** the [Azure Portal](https://portal.azure.com) using your Azure credentials.

2. On the Azure Portal home screen, **select** the '+ Create a resource' tile.

	![A portion of the Azure Portal home screen is displayed with the + Create a resource tile highlighted.](media/create-a-resource.png)

3. In the Search the Marketplace text box, **type** "Resource Group" and **press** the Enter key.

	![On the new resource screen Resource group is entered as a search term.](media/resource-group.png)

4. **Select** the 'Create' button on the 'Resource Group' overview page.

	![A portion of the Azure Portal home screen is displayed with Create Resource Group tile](media/resource-group-2.png)
	
5. On the 'Create a resource group' screen, **select** your desired Subscription. For Resource group, **type** 'cloudshell-dpoc'. 

6. **Select** your desired region.

	> **Note:** Some services behave differently in different regions and may break some part of the setup. Choosing one of the following regions is preferable: 		westus2, eastus2, northcentralus, northeurope, southeastasia, australliaeast, centralindia, uksouth, japaneast.

7. **Click** the 'Review + Create' button.

	![The Create a resource group form is displayed populated with Synapse-MCW as the resource group name.](media/resource-group-3.png)

8. **Click** the 'Create' button once all entries have been validated.

	![Create Resource Group with the final validation passed.](media/resource-group-4.png)


# Copyright

© 2023 Microsoft Corporation. All rights reserved.   

By using this demo/lab, you agree to the following terms: 

The technology/functionality described in this demo/lab is provided by Microsoft Corporation for purposes of obtaining your feedback and to provide you with a learning experience. You may only use the demo/lab to evaluate such technology features and functionality and provide feedback to Microsoft.  You may not use it for any other purpose. You may not modify, copy, distribute, transmit, display, perform, reproduce, publish, license, create derivative works from, transfer, or sell this demo/lab or any portion thereof. 

COPYING OR REPRODUCTION OF THE DEMO/LAB (OR ANY PORTION OF IT) TO ANY OTHER SERVER OR LOCATION FOR FURTHER REPRODUCTION OR REDISTRIBUTION IS EXPRESSLY PROHIBITED. 

THIS DEMO/LAB PROVIDES CERTAIN SOFTWARE TECHNOLOGY/PRODUCT FEATURES AND FUNCTIONALITY, INCLUDING POTENTIAL NEW FEATURES AND CONCEPTS, IN A SIMULATED ENVIRONMENT WITHOUT COMPLEX SET-UP OR INSTALLATION FOR THE PURPOSE DESCRIBED ABOVE. THE TECHNOLOGY/CONCEPTS REPRESENTED IN THIS DEMO/LAB MAY NOT REPRESENT FULL FEATURE FUNCTIONALITY AND MAY NOT WORK THE WAY A FINAL VERSION MAY WORK. WE ALSO MAY NOT RELEASE A FINAL VERSION OF SUCH FEATURES OR CONCEPTS.  YOUR EXPERIENCE WITH USING SUCH FEATURES AND FUNCITONALITY IN A PHYSICAL ENVIRONMENT MAY ALSO BE DIFFERENT.

