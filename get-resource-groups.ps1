

try {
    $ErrorActionPreference = "Stop"
    $resourceGroups = az group list | ConvertFrom-Json
    Write-Output 'Retrieved groups'

    $retrievedGroups = New-Object System.Collections.ArrayList($null)
    $counter = 1
    foreach ($item in $resourceGroups) {
            $group = az resource list -g $item.name | ConvertFrom-Json
            Write-Output "`nRetrieved resource list for group ($($counter)) $($item.name)"
            $resources = New-Object System.Collections.ArrayList($null)
            foreach ($resource in $group) {
                try {
                    #Start-Sleep -Milliseconds 500
                    Write-Output "   Getting $($resource.name) resource data with resource type $($resource.type)"
                    $resourceInfo = cmd.exe /c "az resource show -g `"$($item.name)`" --name `"$($resource.name)`" --resource-type `"$($resource.type)`"" | Out-String | ConvertFrom-Json
                    Write-Output "   Retrieved data for resource $($resource.name)"
                    $resources.Add($resourceInfo) | Out-Null
                    Write-Output "   Added $($resource.name) resource data to group list"
                } catch {
                    Write-Output "   Failed to retrieve $($item.name) resource $($resource.name) `n$_"
                }
            }
            $retrieved = @{
                name = "$($item.name)";
                id = "$($item.id)";
                location = "$($item.location)";
                properties = $item.properties;
                tags = $item.tags;
                resources = $resources
            }
            Write-Output "   $($retrieved)"
            $retrievedGroups.Add($retrieved) | Out-Null
            Write-Output "   Finished retrieving group resources for $($retrieved.name)"        
        $counter++
        Start-Sleep -Milliseconds 250    
    }
    $retrievedGroups | ConvertTo-Json -Depth 100 | Out-File ".\results.json" -Force
    Write-Output 'Done'
} finally {
    $ErrorActionPreference = "Continue"
}
