class MdFile {
    [string]$content

    MdFile (
        [string]$title
    ) {
        $this.content = "# $title`n"
    }

    Add (
        [string]$content
    ) {
        $this.content += "$content`n"
    }
}

function MdHeadingAnchor([string]$DisplayText, [string]$HeadingText) {
    $formattedHeading = $HeadingText.ToLower() -replace " ","-"
    return "[$DisplayText](#$formattedHeading)"
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
            throw "Must provide $($this.columnCount) column values because there are $($this.columnCount) columns"
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