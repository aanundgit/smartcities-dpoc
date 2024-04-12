function RefreshTokens() {
    #Copy external blob content
    $global:powerbitoken = ((az account get-access-token --resource https://analysis.windows.net/powerbi/api) | ConvertFrom-Json).accessToken
    $global:graphToken = ((az account get-access-token --resource https://graph.microsoft.com) | ConvertFrom-Json).accessToken
    $global:fabric = ((az account get-access-token --resource https://api.fabric.microsoft.com) | ConvertFrom-Json).accessToken
}

function Check-HttpRedirect($uri) {
    $httpReq = [system.net.HttpWebRequest]::Create($uri)
    $httpReq.Accept = "text/html, application/xhtml+xml, */*"
    $httpReq.method = "GET"   
    $httpReq.AllowAutoRedirect = $false;

    #use them all...
    #[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls11 -bor [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Ssl3 -bor [System.Net.SecurityProtocolType]::Tls;

    $global:httpCode = -1;

    $response = "";            

    try {
        $res = $httpReq.GetResponse();

        $statusCode = $res.StatusCode.ToString();
        $global:httpCode = [int]$res.StatusCode;
        $cookieC = $res.Cookies;
        $resHeaders = $res.Headers;  
        $global:rescontentLength = $res.ContentLength;
        $global:location = $null;
                                
        try {
            $global:location = $res.Headers["Location"].ToString();
            return $global:location;
        }
        catch {
        }

        return $null;

    }
    catch {
        $res2 = $_.Exception.InnerException.Response;
        $global:httpCode = $_.Exception.InnerException.HResult;
        $global:httperror = $_.exception.message;

        try {
            $global:location = $res2.Headers["Location"].ToString();
            return $global:location;
        }
        catch {
        }
    } 

    return $null;
}

function ReplaceTokensInFile($ht, $filePath) {
    $template = Get-Content -Raw -Path $filePath
        
    foreach ($paramName in $ht.Keys) {
        $template = $template.Replace($paramName, $ht[$paramName])
    }

    return $template;
}

az login

#for powershell...
Connect-AzAccount -DeviceCode

$starttime = get-date

$subs = Get-AzSubscription | Select-Object -ExpandProperty Name
if ($subs.GetType().IsArray -and $subs.length -gt 1) {
    $subOptions = [System.Collections.ArrayList]::new()
    for ($subIdx = 0; $subIdx -lt $subs.length; $subIdx++) {
        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
        $subOptions.Add($opt)
    }
    $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
    $selectedSubName = $subs[$selectedSubIdx]
    Write-Host "Selecting the subscription : $selectedSubName "
    $title = 'Subscription selection'
    $question = 'Are you sure you want to select this subscription for this lab?'
    $choices = '&Yes', '&No'
    $decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
    if ($decision -eq 0) {
        Select-AzSubscription -SubscriptionName $selectedSubName
        az account set --subscription $selectedSubName
    }
    else {
        $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab', 'Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(), 0)
        $selectedSubName = $subs[$selectedSubIdx]
        Write-Host "Selecting the subscription : $selectedSubName "
        Select-AzSubscription -SubscriptionName $selectedSubName
        az account set --subscription $selectedSubName
    }
}

[string]$suffix = -join ((48..57) + (97..122) | Get-Random -Count 7 | % { [char]$_ })
$rgName = "smartcity-dpoc-$suffix"
$Region = Read-Host "Enter the region for deployment "
$storageAccountName = "stsmartcity$suffix"
if($storageAccountName.length -gt 24)
{
$storageAccountName = $storageAccountName.substring(0,24)
}
$app_smartcity_name = "app-smart-city-$suffix"
$asp_smartcity_name = "asp-smart-city-$suffix"
$tenantId = (Get-AzContext).Tenant.Id

##Fetch PowerBI workspace name
$wsId = Read-Host "Enter your 'PowerBI' workspace Id "

Add-Content log.txt "------Creating Fabric Assets------"
Write-Host "------------Creating Fabric Assets------------"

RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId";
$wsName = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" };
$wsName = $wsName.name

$lakehouseBronze = "lakehouseBronze$suffix"
$lakehouseSilver = "lakehouseSilver$suffix"
    
Add-Content log.txt "------Creating Lakehouses------"
Write-Host "------Creating Lakehouses------"
$lakehouseNames = @($lakehouseBronze, $lakehouseSilver)
# Set the token and request headers
$pat_token = $fabric
$requestHeaders = @{
    Authorization  = "Bearer" + " " + $pat_token
    "Content-Type" = "application/json"
    "Scope"        = "itemType.ReadWrite.All"
}

# Iterate through each Lakehouse name and create it
foreach ($lakehouseName in $lakehouseNames) {
    # Create the body for the Lakehouse creation
    $body = @{
        displayName = $lakehouseName
        type        = "Lakehouse"
    } | ConvertTo-Json
    
    # Set the API endpoint
    $endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items/"

    # Invoke the REST method to create a new Lakehouse
    try {
        $Lakehouse = Invoke-RestMethod $endPoint `
            -Method POST `
            -Headers $requestHeaders `
            -Body $body

        Write-Host "Lakehouse '$lakehouseName' created successfully."
    } catch {
        Write-Host "Error creating Lakehouse '$lakehouseName': $_"
        if ($_.Exception.Response -ne $null) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $reader.ReadToEnd()
        }
    }
}

Add-Content log.txt "------Lakehouse Creation Complete------"
Write-Host "------Lakehouse Creation Complete------"

Add-Content log.txt "------Uploading assets to Lakehouses------"
Write-Host "------------Uploading assets to Lakehouses------------"
$tenantId = (Get-AzContext).Tenant.Id
azcopy login --tenant-id $tenantId

azcopy copy "https://smartcitydpoc.blob.core.windows.net/bronzelakehousefiles/*" "https://onelake.blob.fabric.microsoft.com/$wsName/$lakehouseBronze.Lakehouse/Files/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;
azcopy copy "https://smartcitydpoc.blob.core.windows.net/silverlakehousetables/*" "https://onelake.blob.fabric.microsoft.com/$wsName/$lakehouseSilver.Lakehouse/Tables/" --overwrite=prompt --from-to=BlobBlob --s2s-preserve-access-tier=false --check-length=true --include-directory-stub=false --s2s-preserve-blob-tags=false --recursive --trusted-microsoft-suffixes=onelake.blob.fabric.microsoft.com --log-level=INFO;

Add-Content log.txt "------Uploading assets to Lakehouses COMPLETE------"
Write-Host "------------Uploading assets to Lakehouses COMPLETE------------"

## notebooks
Add-Content log.txt "-----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses-----"
Write-Host "----Configuring Fabric Notebooks w.r.t. current workspace and lakehouses----"

(Get-Content -path "artifacts/fabricnotebooks/Bronze_to_Silver_layer_Medallion_Architecture.ipynb" -Raw) | Foreach-Object { $_ `
    -replace '#SMARTCITY_WORKSPACE_NAME#', $wsName `
    -replace '#LAKEHOUSE_BRONZE_NAME#', $lakehouseBronze `
    -replace '#LAKEHOUSE_SILVER_NAME#', $lakehouseSilver `
} | Set-Content -Path "artifacts/fabricnotebooks/Bronze_to_Silver_layer_Medallion_Architecture.ipynb"

Add-Content log.txt "-----Uploading Notebooks -----"
Write-Host "-----Uploading Notebooks -----"
    RefreshTokens
    $requestHeaders = @{
    Authorization  = "Bearer " + $fabric
    "Content-Type" = "application/json"
    "Scope"        = "Notebook.ReadWrite.All"
    }

    $files = Get-ChildItem -Path "./artifacts/fabricnotebooks" -File -Recurse
    Set-Location ./artifacts/fabricnotebooks

    foreach ($name in $files.name) {
    if ($name -eq "Bronze_to_Silver_layer_Medallion_Architecture.ipynb" ) {
        
        $fileContent = Get-Content -Raw $name
        $fileContentBytes = [System.Text.Encoding]::UTF8.GetBytes($fileContent)
        $fileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes)}}

        $body = '{
            "displayName": "' + $name + '",
            "type": "Notebook",
            "definition": {
                "format": "ipynb",
                "parts": [
                    {
                        "path": "artifact.content.ipynb",
                        "payload": "' + $fileContentEncoded + '",
                        "payloadType": "InlineBase64"
                    }
                ]
            }
        }'

        $endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items/"
        $Lakehouse = Invoke-RestMethod $endPoint -Method POST -Headers $requestHeaders -Body $body

        Write-Host "Notebook uploaded: $name"
        cd..
        cd..
Add-Content log.txt "-----Uploading Notebooks Complete-----"
Write-Host "-----Uploading Notebooks Complete-----"

Add-Content log.txt "------Fabric Assets Creation COMPLETE------"
Write-Host "------------Fabric Assets Creation COMPLETE------------"

Add-Content log.txt "------Creating Azure Assets------"
Write-Host "------------Creating Azure Assets------------"

Write-Host "Creating $rgName resource group in $Region ..."
New-AzResourceGroup -Name $rgName -Location $Region | Out-Null
Write-Host "Resource group $rgName creation COMPLETE"

Write-Host "Creating resources in $rgName..."
New-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile "mainTemplate.json" `
    -Mode Complete `
    -location $Region `
    -storageAccountName $storageAccountName `
    -app_smartcity_name $app_smartcity_name `
    -asp_smartcity_name $asp_smartcity_name `
    -Force

Write-Host "Resource creation in $rgName resource group COMPLETE"

# Adding workspace id tag to resourceGroup
$Tag = @{
    "Workspace ID" = $wsId
    "suffix" = $suffix
}
Set-AzResourceGroup -ResourceGroupName $rgName -Tag $Tag

#fetching storage account key
$storage_account_key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -AccountName $storageAccountName)[0].Value
    
#download azcopy command
if ([System.Environment]::OSVersion.Platform -eq "Unix") {
    $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-linux"

    if (!$azCopyLink) {
        $azCopyLink = "https://azcopyvnext.azureedge.net/release20200709/azcopy_linux_amd64_10.5.0.tar.gz"
    }

    Invoke-WebRequest $azCopyLink -OutFile "azCopy.tar.gz"
    tar -xf "azCopy.tar.gz"
    $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy).Directory.FullName

    if ($azCopyCommand.count -gt 1) {
        $azCopyCommand = $azCopyCommand[0];
    }

    cd $azCopyCommand
    chmod +x azcopy
    cd ..
    $azCopyCommand += "\azcopy"
} else {
    $azCopyLink = Check-HttpRedirect "https://aka.ms/downloadazcopy-v10-windows"

    if (!$azCopyLink) {
        $azCopyLink = "https://azcopyvnext.azureedge.net/release20200501/azcopy_windows_amd64_10.4.3.zip"
    }

    Invoke-WebRequest $azCopyLink -OutFile "azCopy.zip"
    Expand-Archive "azCopy.zip" -DestinationPath ".\" -Force
    $azCopyCommand = (Get-ChildItem -Path ".\" -Recurse azcopy.exe).Directory.FullName

    if ($azCopyCommand.count -gt 1) {
        $azCopyCommand = $azCopyCommand[0];
    }

    $azCopyCommand += "\azcopy"
}

#Uploading to storage containers
Add-Content log.txt "-----------Uploading to storage containers-----------------"
Write-Host "----Uploading to Storage Containers-----"

$dataLakeContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storage_account_key

RefreshTokens

$destinationSasKey = New-AzStorageContainerSASToken -Container "webappassets" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storageAccountName).blob.core.windows.net/webappassets$($destinationSasKey)"
& $azCopyCommand copy "https://smartcitydpoc.blob.core.windows.net/webappassets" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "bronzelakehousefiles" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storageAccountName).blob.core.windows.net/bronzelakehousefiles$($destinationSasKey)"
& $azCopyCommand copy "https://smartcitydpoc.blob.core.windows.net/bronzelakehouseshortcut" $destinationUri --recursive

$destinationSasKey = New-AzStorageContainerSASToken -Container "reports" -Context $dataLakeContext -Permission rwdl
if (-not $destinationSasKey.StartsWith('?')) { $destinationSasKey = "?$destinationSasKey"}
$destinationUri = "https://$($storageAccountName).blob.core.windows.net/reports$($destinationSasKey)"
& $azCopyCommand copy "https://smartcitydpoc.blob.core.windows.net/reports" $destinationUri --recursive

Add-Content log.txt "-----------Uploading to storage containers COMPLETE-----------------"
Write-Host "----Uploading to Storage Containers COMPLETE-----"

#Assigning Admin Rights to Service Principal to PowerBI Workspace
Add-Content log.txt "------Assigning Admin Rights to Service Principal to PowerBI Workspace------"
Write-Host  "-----------------Assigning Admin Rights to Service Principal to PowerBI Workspace---------------"
RefreshTokens

$spname = "Smart City $suffix"

$app = az ad app create --display-name $spname | ConvertFrom-Json
$appId = $app.appId

$mainAppCredential = az ad app credential reset --id $appId | ConvertFrom-Json
$clientsecpwd = $mainAppCredential.password

az ad sp create --id $appId | Out-Null    
$sp = az ad sp show --id $appId --query "id" -o tsv
start-sleep -s 20

#https://docs.microsoft.com/en-us/power-bi/developer/embedded/embed-service-principal
#Allow service principals to user PowerBI APIS must be enabled - https://app.powerbi.com/admin-portal/tenantSettings?language=en-U
#add PowerBI App to workspace as an admin to group
RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups";
$result = Invoke-WebRequest -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization = "Bearer $powerbitoken" } -ea SilentlyContinue;
$homeCluster = $result.Headers["home-cluster-uri"]
#$homeCluser = "https://wabi-west-us-redirect.analysis.windows.net";

RefreshTokens
$url = "$homeCluster/metadata/tenantsettings"
$post = "{`"featureSwitches`":[{`"switchId`":306,`"switchName`":`"ServicePrincipalAccess`",`"isEnabled`":true,`"isGranular`":true,`"allowedSecurityGroups`":[],`"deniedSecurityGroups`":[]}],`"properties`":[{`"tenantSettingName`":`"ServicePrincipalAccess`",`"properties`":{`"HideServicePrincipalsNotification`":`"false`"}}]}"
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "Bearer $powerbiToken")
$headers.Add("X-PowerBI-User-Admin", "true")
#$result = Invoke-RestMethod -Uri $url -Method PUT -body $post -ContentType "application/json" -Headers $headers -ea SilentlyContinue;

#add PowerBI App to workspace as an admin to group
RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/users";
$post = "{
`"identifier`":`"$($sp)`",
`"groupUserAccessRight`":`"Admin`",
`"principalType`":`"App`"
}";

$result = Invoke-RestMethod -Uri $url -Method POST -body $post -ContentType "application/json" -Headers @{ Authorization = "Bearer $powerbitoken" } -ea SilentlyContinue;

#get the power bi app...
$powerBIApp = Get-AzADServicePrincipal -DisplayNameBeginsWith "Power BI service"
$powerBiAppId = $powerBIApp.Id;

#setup powerBI app...
RefreshTokens
$url = "https://graph.microsoft.com/beta/OAuth2PermissionGrants";
$post = "{
    `"clientId`":`"$appId`",
    `"consentType`":`"AllPrincipals`",
    `"resourceId`":`"$powerBiAppId`",
    `"scope`":`"Dataset.ReadWrite.All Dashboard.Read.All Report.Read.All Group.Read Group.Read.All Content.Create Metadata.View_Any Dataset.Read.All Data.Alter_Any`",
    `"expiryTime`":`"2021-03-29T14:35:32.4943409+03:00`",
    `"startTime`":`"2020-03-29T14:35:32.4933413+03:00`"
}";

$result = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization = "Bearer $graphtoken" } -ea SilentlyContinue;

#setup powerBI app...
RefreshTokens
$url = "https://graph.microsoft.com/beta/OAuth2PermissionGrants";
$post = "{
    `"clientId`":`"$appId`",
    `"consentType`":`"AllPrincipals`",
    `"resourceId`":`"$powerBiAppId`",
    `"scope`":`"User.Read Directory.AccessAsUser.All`",
    `"expiryTime`":`"2021-03-29T14:35:32.4943409+03:00`",
    `"startTime`":`"2020-03-29T14:35:32.4933413+03:00`"
}";

$result = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json" -Headers @{ Authorization = "Bearer $graphtoken" } -ea SilentlyContinue;

$credential = New-Object PSCredential($appId, (ConvertTo-SecureString $clientsecpwd -AsPlainText -Force))

# Connect to Power BI using the service principal
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -TenantId $tenantId

#PowerBI report upload section
Add-Content log.txt "------Uploading PowerBI Reports to the Workspace------"
Write-Host  "--------------Uploading PowerBI Reports to the Workspace---------------"

## Training the Knowledge Base      -------   index_name ="prod-responsibleai-search" container_name = "knowledge-base-responsibleai"
$urlReports = "https://" + $storageAccountName + ".blob.core.windows.net/reports/"  

$containerName = "reports"

$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storage_account_key

$blobs = Get-AzStorageBlob -Container $containerName -Context $context

mkdir ./reports

foreach ($file in $blobs.Name) {
    $reportDownload = az storage blob download --account-name $storageAccountName --container-name $containerName --name $file --file ./reports/$file --account-key $storage_account_key --auth-mode key
}

# Uploading Reports to PowerBI Workspace
$PowerBIFiles = Get-ChildItem "./reports" -Recurse -Filter *.pbix

foreach ($Pbix in $PowerBIFiles) {
    Write-Output "Uploading report: $($Pbix.BaseName)"
  
    $report = New-PowerBIReport -Path $Pbix.FullName -WorkspaceId $wsId

    if ($report -ne $null) {
        Write-Output "Report uploaded successfully: $($report.Name)"
    } else {
        Write-Output "Failed to upload report: $($Pbix.BaseName)"
    }
}

#PowerBI report upload section
Add-Content log.txt "------Uploading PowerBI Reports to the Workspace COMPLETE------"
Write-Host  "--------------Uploading PowerBI Reports to the Workspace COMPLETE---------------"

# #retrieving cognitive service endpoint
# $cognitiveEndpoint = az cognitiveservices account show -n $cognitive_service_name -g $rgName | jq -r .properties.endpoint

# #retirieving cognitive service key
# $cognitivePrimaryKey = az cognitiveservices account keys list -n $cognitive_service_name -g $rgName | jq -r .key1

#Web App Section
Add-Content log.txt "------unzipping poc web app------"
Write-Host  "--------------Unzipping web app---------------"
$zips = @("app-smart-cities")
foreach ($zip in $zips) {
    expand-archive -path "./artifacts/binaries/$($zip).zip" -destinationpath "./$($zip)" -force
}

Add-Content log.txt "------Deploying the main web app------"
Write-Host  "--------------Deploying the main web app---------------"

(Get-Content -path app-smart-cities/appsettings.json -Raw) | Foreach-Object { $_ `
        -replace '#WORKSPACE_ID#', $wsId`
        -replace '#APP_ID#', $appId`
        -replace '#APP_SECRET#', $clientsecpwd`
        -replace '#TENANT_ID#', $tenantId`
} | Set-Content -Path app-smart-cities/appsettings.json

$filepath = "./app-smart-cities/wwwroot/environment.js"
$itemTemplate = Get-Content -Path $filepath
$item = $itemTemplate.Replace("#SPEECH_SERVICE_KEY#", $speech_service_key).Replace("#REGION#", $Region).Replace("#STORAGE_ACCOUNT_NAME#", $storageAccountName).Replace("#SERVER_NAME#", $app_smartcity_name).Replace("#WORKSPACE_ID#", $wsId)
Set-Content -Path $filepath -Value $item

RefreshTokens
$url = "https://api.powerbi.com/v1.0/myorg/groups/$wsId/reports";
$reportList = Invoke-RestMethod -Uri $url -Method GET -Headers @{ Authorization = "Bearer $powerbitoken" };
$reportList = $reportList.Value

#update all th report ids in the poc web app...
$ht = new-object system.collections.hashtable   
# $ht.add("#Bing_Map_Key#", "AhBNZSn-fKVSNUE5xYFbW_qajVAZwWYc8OoSHlH8nmchGuDI6ykzYjrtbwuNSrR8")
$ht.add("#NYC_AQI#", $($reportList | where { $_.name -eq "NYC_AQI" }).id)
$ht.add("#TRANSPORT_DEEP_DIVE#", $($reportList | where { $_.name -eq "Transport Deep Dive" }).id)
$ht.add("#Contoso_City_Call_Center_Report_(After)#", $($reportList | where { $_.name -eq "Contoso City Call Center Report (After)" }).id)
$ht.add("#Contoso_City_Call_Center_Report_(Before)#", $($reportList | where { $_.name -eq "Contoso City Call Center Report (Before)" }).id)

$filePath = "./app-smart-cities/wwwroot/environment.js";
Set-Content $filePath $(ReplaceTokensInFile $ht $filePath)

Compress-Archive -Path "./app-smart-cities/*" -DestinationPath "./app-smart-cities.zip" -Update

az webapp stop --name $app_smartcity_name --resource-group $rgName
try {
    az webapp deployment source config-zip --resource-group $rgName --name $app_smartcity_name --src "./app-smart-cities.zip"
}
catch {
}
az webapp start --name $app_smartcity_name --resource-group $rgName

Add-Content log.txt "------Main web app deployment COMPLETE------"
Write-Host  "--------------Main web app deployment COMPLETE---------------"

$endtime = get-date
$executiontime = $endtime - $starttime
Write-Host "Execution Time - "$executiontime.TotalMinutes
Add-Content log.txt "------Execution Time - '$executiontime.TotalMinutes'------"

Add-Content log.txt "------Azure Assets Creation COMPLETE------"
Write-Host "------------Azure Assets Creation COMPLETE------------"

Write-Host "List of resources deployed in $rgName resource group"
$deployed_resources = Get-AzResource -resourcegroup $rgName
$deployed_resources = $deployed_resources | Select-Object Name, Type | Format-Table -AutoSize
Write-Output $deployed_resources

Write-Host "List of resources deployed in $wsId workspace"
$endPoint = "https://api.fabric.microsoft.com/v1/workspaces/$wsId/items"
$fabric_items = Invoke-RestMethod $endPoint `
    -Method GET `
    -Headers $requestHeaders 

$table = $fabric_items.value | Select-Object DisplayName, Type | Format-Table -AutoSize

Write-Output $table

Write-Host  "-----------------Execution Complete----------------"
Add-Content log.txt "------Execution Complete------"
