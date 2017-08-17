$azResourceLink = "https://portal.azure.com/#resource"
$mdContent = ""
function ReadJson ([string]$filePath) {
    return (Get-Content $filePath | Out-String | ConvertFrom-Json)
}

function MdAdd ([string]$content) {
    $script:mdContent += "$content`n"
}

function UrlEncode ([string]$url) {
    return [uri]::EscapeUriString($url)
}

MdAdd("# Azure Resources`n")
MdAdd("This is a presentation of existing Azure resources, organized by group.`n")

try {
    $ErrorActionPreference = "Stop"
    Import-Module ".\MdBuilder.psm1"
    Write-Output "Loaded MdBuilder module"
    $groups = ReadJson(".\resources.json")

    MdAdd("### Table of Contents`n")
    MdAdd("Azure Resource Groups:")
    foreach($group in $groups) {
        $anchorLink = MdAnchor -DisplayText "$($group.name)" -HeadingText "Group $($group.name -replace '\.',' ')"
        MdAdd(" * $anchorLink")
    }
    MdAdd("")

    # Added Group Tables
    foreach($group in $groups) {
        MdAdd("## Group $($group.name -replace '\.',' ')`n")
        MdAdd("Azure Portal Link: [$($group.name)]($($azResourceLink + $group.id))`n")
        $groupTable = [MdTable]::New(@("Resource","Link","Type","Location"))
        foreach($resource in $group.resources) {
            $url = UrlEncode($azResourceLink + $resource.id)
            if ($null -ne $resource.properties.name) { $name = $resource.properties.name }
            elseif ($null -ne $resource.name) { $name = $resource.name }
            $groupTable.AddRow(@("$name","[Azure Portal]($url)","``$($resource.type)``","$($resource.location)"))
        }
        MdAdd($groupTable.table + "`n")
        MdAdd((MdAnchor -DisplayText "Go to top" -HeadingText "Table of Contents"))
    }

    $mdContent | Out-File "Azure-Resources.md" -Force | Out-Null
} finally {
    $ErrorActionPreference = "Continue"
    Remove-Module -Name MdBuilder
    Write-Output "Removed MdBuilder module"
}
