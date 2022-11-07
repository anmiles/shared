<#
.SYNOPSIS
    Regenerate Sourcetree bookmarks file
#>

Function CreateFolder($name) {
    return [PSCustomObject]@{name = $name; folders = @{}; repos = @{}}
}

Function StartElement($type, $name, $level, $isLeaf) {
    $xmlWriter.WriteStartElement("TreeViewNode")
    $xmlWriter.WriteAttributeString("xsi:type", $type)
    $xmlWriter.WriteElementString("Level", $level)
    $xmlWriter.WriteElementString("IsExpanded", "false")
    $xmlWriter.WriteElementString("IsLeaf", $isLeaf.ToString().ToLower())
    $xmlWriter.WriteElementString("Name", $name)
}

Function StartNodeElement($name, $level) {
    StartElement -type "BookmarkNode" -name $name -level $level -isLeaf $true
    $xmlWriter.WriteElementString("Children", $null)
}

Function StartFolderElement($name, $level) {
    StartElement -type "BookmarkFolderNode" -name $name -level $level -isLeaf $false
    $xmlWriter.WriteStartElement("Children")
}

Function EndFolderElement() {
    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteElementString("CanSelect", "true")
    $xmlWriter.WriteElementString("HasError", "false")
    $xmlWriter.WriteEndElement()
}

Function EndNodeElement($path) {
    $xmlWriter.WriteElementString("CanSelect", "true")
    $xmlWriter.WriteElementString("HasError", "false")
    $xmlWriter.WriteElementString("Path", $path)
    $xmlWriter.WriteElementString("RepoType", "Git")
    $xmlWriter.WriteEndElement()
}

Function ExportFolder($folder, $level) {
    $folder.folders.Keys | Sort | % {
        StartFolderElement -name $folder.folders[$_].name -level $level
        ExportFolder -folder $folder.folders[$_] -level ($level + 1)
        EndFolderElement
    }

    $folder.repos.Keys | Sort | % {
        StartNodeElement -name $_ -level $level
        EndNodeElement -path $folder.repos[$_]
    }
}

$file = Join-Path $env:LocalAppData "Atlassian\SourceTree\bookmarks.xml"
$utf8 = New-Object System.Text.UTF8Encoding $false
$xmlWriter = [System.Xml.XmlTextWriter]::new($file, $utf8)
$xmlWriter.Formatting = "Indented"
$xmlWriter.Indentation = 2
$xmlWriter.IndentChar = ' '
$xmlWriter.WriteStartDocument()
$xmlWriter.WriteStartElement("ArrayOfTreeViewNode")
$xmlWriter.WriteAttributeString("xmlns:xsd", "http://www.w3.org/2001/XMLSchema")
$xmlWriter.WriteAttributeString("xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")

$gits = CreateFolder

repo all {
    $relativePath = $repo.Replace($env:GIT_ROOT, "").Trim("\")
    $parts = $relativePath.Split("\")
    $root = $gits

    if ($parts.Count -eq 1) {
        $root.repos[$name] = $repo
    } else {
        $parts[0..($parts.Length - 2)] | % {
            if (!$root.folders[$_]) {
                $root.folders[$_] = CreateFolder -name $_
            }
            $root = $root.folders[$_]
        }
        $root.repos[$name] = $repo
    }
}

ExportFolder -folder $gits -level 0

$xmlWriter.WriteEndElement()
$xmlWriter.WriteEndDocument()
$xmlWriter.Flush()
$xmlWriter.Close()
