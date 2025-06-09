connect-azaccount -UseDeviceAuthentication

$subscriptionid = "88a53b8a-b6bb-42d8-8729-3db903944983"
$resourcegroupname = "rg-ocs-synapse"
$workspaceName = "ocstestworkspace"
$originalPool = "ocspool02"
$newpool = "ocspool01"

$notebooks = Get-AzSynapseNotebook -WorkspaceName $workspaceName

$filteredNotebooks = $notebooks | Where-Object {
    $_.properties.metadata.additionalproperties.a365ComputeOptions -and
    $_.properties.metadata.additionalproperties.a365ComputeOptions.name -eq $originalPool
}

foreach ($notebook in $filteredNotebooks) {
    $notebookName = $notebook.name
    $uri = "https://management.azure.com/subscriptions/$subscriptionid/resourceGroups/$resourcegroupname/providers/Microsoft.Synapse/workspaces/$workspaceName/notebooks/$notebookName?api-version=2020-12-01"

    # Update the notebook object in memory
    $notebook.properties.metadata.additionalproperties.a365ComputeOptions.id = "/subscriptions/$subscriptionid/resourceGroups/$resourcegroupname/providers/Microsoft.Synapse/workspaces/$workspaceName/bigDataPools/$newpool"
    $notebook.properties.metadata.additionalproperties.a365ComputeOptions.name = $newpool
    $notebook.properties.metadata.additionalproperties.a365ComputeOptions.endpoint = "https://$workspaceName.dev.azuresynapse.net/livyApi/versions/2019-11-01-preview/sparkPools/$newpool"

    $body = @{
        properties = $notebook.properties
    } | ConvertTo-Json -Depth 10

    Invoke-AzRestMethod -Method PUT -Uri $uri -Payload $body | Out-Null


    $nbcheck = get-azsynapsenotebook -workspacename $workspacename -name $notebookname
    if (
        $nbcheck.properties.metadata.additionalproperties.a365ComputeOptions.id -eq "/subscriptions/$subscriptionid/resourceGroups/$resourcegroupname/providers/Microsoft.Synapse/workspaces/$workspaceName/bigDataPools/$newpool" -and
        $nbcheck.properties.metadata.additionalproperties.a365ComputeOptions.name -eq $newpool -and
        $nbcheck.properties.metadata.additionalproperties.a365ComputeOptions.endpoint -eq "https://$workspaceName.dev.azuresynapse.net/livyApi/versions/2019-11-01-preview/sparkPools/$newpool"
    ) {
        Write-Host "Updated notebook: $notebookName"
    } else {
        Write-Warning "Notebook $notebookName properties not set as expected."
    }
}