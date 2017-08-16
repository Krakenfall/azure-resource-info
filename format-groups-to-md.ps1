$azResourceLink = "https://portal.azure.com/#resource"
$mdContent = ""
function ReadJson ([string]$filePath) {
    return (Get-Content $filePath | Out-String | ConvertFrom-Json)
}

function MdAdd ([string]$content) {
    $script:mdContent += "$content`n"
}

class MdTable {
    [int]$columnCount;
    [string]$table;
    
    MdTable(
        [string[]]$columnNames
    ) {
        $this.columnCount = $columnNames.Count;
        $header = "|"
        $separator = "|"
        for ($i = 0; $i -lt $this.columnCount; $i++) {
            $header += "{$i}|"
            $separator += "---|"
        }
        $this.table = ($header -f $columnNames) + "`n$separator`n"
    }

    AddRow(
        [string[]]$values
    ) {
        if ($this.columnCount -ne $values.Count) {
            throw "Must provide the same number of column values as there are columns"
        }
        $row = "|"
        for ($i = 0; $i -lt $this.columnCount; $i++) {
            $row += "{$i}|"
        }
        $this.table += ($row -f $values) + "`n"
    }
}

function UrlEncode ([string]$url) {
    return [uri]::EscapeUriString($url)
}

MdAdd("# Azure Resources`n")
MdAdd("This is a presentation of existing Azure resources, organized by group.`n")

try {
    $ErrorActionPreference = "Stop"
    $groups = ReadJson(".\resources.json")

    foreach($group in $groups) {
        MdAdd("## Group: $($group.name)`n")
        MdAdd("Azure Portal Link: [$($group.name)]($($azResourceLink + $group.id))`n")
        $groupTable = [MdTable]::New(@("Resource","Link","Type","Location"))
        foreach($resource in $group.resources) {
            $url = UrlEncode($azResourceLink + $resource.id)
            $groupTable.AddRow(@("$($resource.properties.name)","[Azure Portal]($url)","$($resource.type)","$($resource.location)"))
        }
        MdAdd($groupTable.table + "`n")
    }

    $mdContent | Out-File "Azure-Resources.md" -Force | Out-Null
} finally {
    $ErrorActionPreference = "Continue"
}
