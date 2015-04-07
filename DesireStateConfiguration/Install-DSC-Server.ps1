﻿param(
    [ParaMeter(Mandatory=$true)]
    [string] $web_site,
    [ParaMeter(Mandatory=$true)]
    [string] $url,
    [ParaMeter(Mandatory=$true)]
    [string] $path,
    [ParaMeter(Mandatory=$true)]
    [string] $pfx_path,
    [ParaMeter(Mandatory=$true)]
    [string] $pfx_pass
)

Add-WindowsFeature DSC-Service
. (Join-Path $env:SCRIPTS_HOME "Libraries\IIS_Functions.ps1")

Set-Variable -Name app_pool -Value "AppPool - DSC" -Option Constant

$settings = @(

if( !(Test-Path $path) ){ 
    mkdir $path
    mkdir (Join-Path $path "bin")
}

Copy-Item -Path $pshome\modules\psdesiredstateconfiguration\pullserver\Global.asax -Destination $path -Verbose
Copy-Item -Path $pshome\modules\psdesiredstateconfiguration\pullserver\PSDSCPullServer.mof -Destination $path -Verbose
Copy-Item -Path $pshome\modules\psdesiredstateconfiguration\pullserver\PSDSCPullServer.svc -Destination $path -Verbose
Copy-Item -Path $pshome\modules\psdesiredstateconfiguration\pullserver\PSDSCPullServer.xml -Destination $path -Verbose
Copy-Item -Path $pshome\modules\psdesiredstateconfiguration\pullserver\PSDSCPullServer.config -Destination (Join-Path $path "web.config")
Copy-Item -Path $pshome\modules\psdesiredstateconfiguration\pullserver\Microsoft.Powershell.DesiredStateConfiguration.Service.dll -Destination (Join-Path $path "bin")

Create-IISAppPool -apppool $app_pool -version v4.0

Create-IISWebSite -site $web_site -path $path -header $url
Set-IISAppPoolforWebSite -apppool $app_pool -site $web_site


Copy-Item -Path $pshome/modules/psdesiredstateconfiguration/pullserver/devices.mdb -Destination $env:programfiles\WindowsPowerShell\DscService\ -Verbose

    $add.SetAttribute("key", $setting.Key)
    $add.SetAttribute("value", $setting.Value )
    $cfg.Configuration.appSettings.AppendChild($add)
Import-PfxCertificate -certpath $pfx_path -pfxPass $secure_pass
Set-SSLforWebApplication -name $web_site -common_name $url