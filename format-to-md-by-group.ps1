using module ".\MdBuilder.psm1"

$azResourceLink = "https://portal.azure.com/#resource"
function ReadJson ([string]$filePath) {
    return (Get-Content $filePath | Out-String | ConvertFrom-Json)
}

try {
    $ErrorActionPreference = "Stop"
    $groups = ReadJson(".\resources.json")

    $mdFile = [MdFile]::New("Azure Resources")
    $mdFile.Add("This is a presentation of existing Azure resources, organized by group.`n")
    
    $mdFile.Add("### Table of Contents`n")
    $mdFile.Add("Azure Resource Groups:")
    foreach($group in $groups) {
        $anchorLink = MdHeadingAnchor -DisplayText "$($group.name)" -HeadingText "Group $($group.name -replace '\.',' ')"
        $mdFile.Add(" * $anchorLink")
    }
    $mdFile.Add("")

    # Added Group Tables
    foreach($group in $groups) {
        $mdFile.Add("## Group $($group.name -replace '\.',' ')`n")
        $mdFile.Add("Azure Portal Link: [$($group.name)]($($azResourceLink + $group.id))`n")
        $groupTable = [MdTable]::New(@("Resource","Link","Type","Location"))
        foreach($resource in $group.resources) {
            $url = UrlEncode($azResourceLink + $resource.id)
            if ($null -ne $resource.properties.name) { $name = $resource.properties.name }
            elseif ($null -ne $resource.name) { $name = $resource.name }
            $groupTable.AddRow(@("$name","[Azure Portal]($url)","``$($resource.type)``","$($resource.location)"))
        }
        $mdFile.Add($groupTable.table + "`n")
        $mdFile.Add((MdHeadingAnchor -DisplayText "Go to top" -HeadingText "Table of Contents"))
    }

    $mdFile.content | Out-File "Azure-Resources-By-Group.md" -Force | Out-Null
} finally {
    $ErrorActionPreference = "Continue"
}
