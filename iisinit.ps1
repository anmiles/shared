Import-Module $env:MODULES_ROOT\iis.ps1 -Force

$debug = $true
$iis_config_file = Join-Path $PSScriptRoot "../iis.xml"

if (!(confirm "Do you really want to re-create all IIS websites and bindings")) { exit }
ClearIISRecords

$hosts = [HostsFile]::new()

$iis_config = [xml](Get-Content $iis_config_file)

$iis_config.root.sections.section | % {
    $section = $_

    $http = $section.http -eq "true"
    $https = $section.https -eq "true"
    $hosts_section = $section.name.ToUpper()

    $section.sites.site | % {
        $site = $_.name

        $section.templates.template | % {
            $template = $_
            $urls = @($_.hostname, $_.alias)

            if (!$_.hostname) {
                $urls += $_.name
            }

            $section.sites.site | % {
                $site = $_

                $name = $template.name.Replace("{0}", $site.prefix)
                $directory = $template.path.Replace("{0}", $site.prefix)

                $urls | ? { $_ } | % {
                    $url = $_.Replace("{0}", $site.prefix)

                    "CreateIISRecord -name $name -url $url -directory $directory -local_ip $template.ip -http $http -https $https -persistent $true -hosts $hosts -hosts_section $hosts_section"
                    CreateIISRecord -name $name -url $url -directory $directory -local_ip $template.ip -http $http -https $https -persistent $true -hosts $hosts -hosts_section $hosts_section
                }
            }
        }
    }
}

$hosts.Save()
