<#
.SYNOPSIS
    Build solution
.DESCRIPTION
    Find *.sln files in current repository and build them with MSBuild 15
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
    build
    # build all *.sln in the current directory, or if there are no solutions here, build all *.sln in the current repository
.EXAMPLE
    build this
    # build all *.sln in the current repository
.EXAMPLE
    build lib
    # build all *.sln in the repository "lib"
.EXAMPLE
    build all
    # build all *.sln in directories for each repository that can be found in $roots
#>

Param (
    [string]$name,
    [switch]$release,
    [switch]$quiet
)

Function BuildSolution($sln) {
    $name = $sln -replace ".sln", ""
    $cfg = switch($release){$true {"Release"} $false {"Debug"}}
    out "Build {Green:$name} [{Green:$cfg}]"
    & "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\MSBuild.exe" $sln /m /v:m /p:Configuration=$cfg /t:Rebuild /nologo /warnasmessage:MSB3277
}

$solutions = Get-ChildItem -Filter *.sln

if ($solutions) {
    $solutions | BuildSolution $_
} else {
    repo -name $name -quiet:$quiet -action {
        $solutions = Get-ChildItem -Filter *.sln

        if (!$solutions) {
            $solutions = Get-ChildItem -Filter *.sln -Recurse
        }

        if (!$solutions) {
            out "{Red:There are no *.sln files inside} {Yellow:$($pwd.Path)}"
            exit
        }

        Get-ChildItem -Filter *.sln -Recurse | foreach {
            BuildSolution $_
        }
    }
}
