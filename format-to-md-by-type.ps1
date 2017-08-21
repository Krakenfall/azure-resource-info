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

function GetResourceTypes([Parameter()]$resources) {
    $types = New-Object System.Collections.ArrayList($null)
    foreach ($resource in $resources) {
        if (-not $types.Contains($resource.type)) {
            $types.Add($resource.type) | Out-Null
        }
    }
    return $types
}

function GetResourcesWithType(
    [string]$type, 
    [Parameter()]$resources
) {
    $resourcesOfType = @{
        type = $type;
        resources = New-Object System.Collections.ArrayList($null)
    }
    foreach ($resource in $resources) {
        if ($type -eq $resource.type) {
            $resourcesOfType.resources.Add($resource) | Out-Null
        }
    }
    return $resourcesOfType
}

try {
    $ErrorActionPreference = "Stop"
    $groups = ReadJson(".\resources.json")

    $mdFile = [MdFile]::New("Azure Resources by Type")
    $mdFile.Add("This is a presentation of existing Azure resources, organized by type.`n")
    
    # Process types
    $flatResources = GetAllResources($groups)
    $types = GetResourceTypes($flatResources)
    $resources = New-Object System.Collections.ArrayList($null)
    foreach ($type in $types) {
        $typeGrouping = GetResourcesWithType -type $type -resources $flatResources
        $resources.Add($typeGrouping) | Out-Null
    }

    $mdFile.Add("### Table of Contents`n")
    $mdFile.Add("Azure Resource Types:")
    foreach($type in $resources) {
        $anchorLink = MdHeadingAnchor -DisplayText "$($type.type -replace '[\./]',' ')  ($($group.resources.Count) resources)" -HeadingText "Type $($type.type -replace '[\./]',' ')"
        $mdFile.Add(" * $anchorLink")
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
