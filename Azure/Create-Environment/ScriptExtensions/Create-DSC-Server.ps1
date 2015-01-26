﻿param(
    [ParaMeter(Mandatory=$true)]
    [string] $web_site,
    [ParaMeter(Mandatory=$true)]
    [string] $url,
    [ParaMeter(Mandatory=$true)]
    [string] $path
)

Add-WindowsFeature DSC-Service

Set-Variable -Name app_pool -Value "AppPool - DSC" -Option Constant
Set-Variable -Name app_pool_path -value 'IIS:\AppPools' -Option Constant

$settings = @(

if( !(Test-Path $path) ){ 
    New-Item $path -ItemType Directory
    New-Item (Join-Path $path "bin") -ItemType Directory
}

Copy-Item -Path $pshome\modules\psdesiredstateconfiguration\pullserver\Global.asax -Destination $path -Verbose
Copy-Item -Path $pshome\modules\psdesiredstateconfiguration\pullserver\PSDSCPullServer.mof -Destination $path -Verbose
Copy-Item -Path $pshome\modules\psdesiredstateconfiguration\pullserver\PSDSCPullServer.svc -Destination $path -Verbose
Copy-Item -Path $pshome\modules\psdesiredstateconfiguration\pullserver\PSDSCPullServer.xml -Destination $path -Verbose
Copy-Item -Path $pshome\modules\psdesiredstateconfiguration\pullserver\PSDSCPullServer.config -Destination (Join-Path $path "web.config")
Copy-Item -Path $pshome\modules\psdesiredstateconfiguration\pullserver\Microsoft.Powershell.DesiredStateConfiguration.Service.dll -Destination (Join-Path $path "bin")

New-WebAppPool -Name $app_pool
Set-ItemProperty (Join-Path $app_pool_path $app_pool) -name managedRuntimeVersion "v4.0"


New-WebSite -PhysicalPath $path -Name $web_site -Port 80  -HostHeader $url
Set-ItemProperty (Join-path $path $site) -name applicationPool -value $app_pool


Copy-Item -Path $pshome/modules/psdesiredstateconfiguration/pullserver/devices.mdb -Destination $env:programfiles\WindowsPowerShell\DscService\ -Verbose

    $add.SetAttribute("key", $setting.Key)
    $add.SetAttribute("value", $setting.Value )
    $cfg.Configuration.appSettings.AppendChild($add)