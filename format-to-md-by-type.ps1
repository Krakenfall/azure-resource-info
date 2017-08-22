using module ".\MdBuilder.psm1"

$azResourceLink = "https://portal.azure.com/#resource"
function ReadJson ([string]$filePath) {
    return (Get-Content $filePath | Out-String | ConvertFrom-Json)
}

function GetAllResources([Parameter()]$groups) {
    $resources = New-Object System.Collections.ArrayList($null)
    foreach ($group in $groups) {
        $resources.AddRange($group.resources) | Out-Null
    }
    return $resources
}

function GetHighestQuantityResourceType (
    [Parameter()]$resourcesByType
) {
    # Top consists of resource types with the greatest number of resources
    # if there is a tie for the most resources, $top will contain more than one element
    $top = New-Object System.Collections.ArrayList($null);
    $top.Add($resourcesByType[0]) | Out-Null

    for ($i = 0; $i -lt $resourcesByType.Count; $i++) {
        if ($resourcesByType[$i].resources.Count -gt $top[0].resources.Count) {
            # Clear $top, add new leader
            $top = New-Object System.Collections.ArrayList($null)
            $top.Add($resourcesByType[$i]) | Out-Null
        } elseif ($resourcesByType[$i].resources.Count -eq $top.resources.Count) {
            # if tie, add element to $top
            $top.Add($resourcesByType[$i]) | Out-Null
        }
    }
    return $top
}

function GetResourceTypes([Parameter()]$flatResources) {
    $types = New-Object System.Collections.ArrayList($null)
    foreach ($resource in $flatResources) {
        if (-not $types.Contains($resource.type)) {
            $types.Add($resource.type) | Out-Null
        }
    }
    return $types
}

function GetResourcesWithType(
    [string]$type, 
    [Parameter()]$flatResources
) {
    $resourcesOfType = @{
        type = $type;
        resources = New-Object System.Collections.ArrayList($null)
    }
    foreach ($resource in $flatResources) {
        if ($type -eq $resource.type) {
            $resourcesOfType.resources.Add($resource) | Out-Null
        }
    }
    return $resourcesOfType
}

try {
    $ErrorActionPreference = "Stop"
    $groups = ReadJson(".\resources.json")

    # Process types
    $flatResources = GetAllResources($groups)
    $types = GetResourceTypes($flatResources)
    $resources = New-Object System.Collections.ArrayList($null)
    foreach ($type in $types) {
        $typeGrouping = GetResourcesWithType -type $type -flatResources $flatResources
        $resources.Add($typeGrouping) | Out-Null
    }

    $mdFile = [MdFile]::New("Azure Resources by Type")
    $mdFile.Add("This is a presentation of existing Azure resources, organized by type.`n")
    $mdFile.Add("### Summary`n")
    $mdFile.Add("* $($flatResources.Count) total resources")
    $mdFile.Add("* $($types.Count) different types of resources persistently allocated")
    $mdFile.Add("* Type with highest volume allocated:")
    $highestResources = GetHighestQuantityResourceType -resourcesByType $resources
    foreach ($type in $highestResources) {
        $mdFile.Add("   * $($type.type): $($type.resources.Count) allocated")
    }
    $mdFile.Add("")

    $mdFile.Add("### Table of Contents`n")
    $mdFile.Add("Azure Resource Types:")
    foreach($type in $resources) {
        $anchorLink = MdHeadingAnchor -DisplayText "$($type.type -replace '[\./]',' ')" -HeadingText "Type $($type.type -replace '[\./]',' ')"
        $mdFile.Add(" * $anchorLink ($($type.resources.Count) resources)")
    }
    $mdFile.Add("")

    # Added Group Tables
    foreach($type in $resources) {
        $mdFile.Add("## Type $($type.type -replace '[\./]',' ')`n")
        $typeTable = [MdTable]::New(@("Resource","Link","Group","Location"))
        foreach($resource in $type.resources) {
            $url = UrlEncode($azResourceLink + $resource.id)
            if ($null -ne $resource.properties.name) { $name = $resource.properties.name }
            elseif ($null -ne $resource.name) { $name = $resource.name }
            $typeTable.AddRow(@("``$name``","[Azure Portal]($url)","``$($resource.resourceGroup)``","$($resource.location)"))
        }
        $mdFile.Add($typeTable.table + "`n")
        $mdFile.Add((MdHeadingAnchor -DisplayText "Go to top" -HeadingText "Table of Contents"))
    }

    $mdFile.content | Out-File "Azure-Resources-By-Type.md" -Force | Out-Null
} finally {
    $ErrorActionPreference = "Continue"
}
