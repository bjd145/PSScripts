﻿. (Join-PATH $ENV:SCRIPTS_HOME "Libraries\Standard_Functions.ps1")

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$MaximumHistoryCount = 1024
$env:EDITOR = "C:\Program Files (x86)\Microsoft VS Code\code.exe"
$github_path = "D:\GitHub\PSScripts"

New-Alias -name gh    -value Get-History 
New-Alias -name i     -value Invoke-History
New-Alias -name ed    -value $env:EDITOR
New-Alias -Name code  -Value $env:EDITOR

Set-PSReadlineKeyHandler -Key Tab -Function Complete

function Get-VPNPassword {
    $vpn = ""
    $secure_password = Get-StoredCredential -Target $vpn | Select-Object -ExpandProperty Password
    Get-PlainTextPassword -password (ConvertFrom-SecureString $secure_password) | Set-Clipboard
    Write-Verbose -Message "Password sent to clip board"
}
Set-Alias -Name vpn -Value Get-VPNPassword

function Get-PublicKey {
    Get-Content -Path $pub_key_file | Set-Clipboard
}
Set-Alias -Name pubkey -Value Get-PublicKey

function Get-Profile {
    ed $profile
}

function Edit-HostFile {
    ed (Join-Path -Path $ENV:SystemRoot -ChildPath "System32\drivers\etc\hosts")
}
Set-Alias -Name hf -Value Edit-HostFile

function Set-Home {
    Set-Location -Path $home
}
Set-Alias -Name home -Value Set-Home

Remove-Item alias:cd
function cd {
    param ( $location ) 

    if ( $location -eq '-' ) {
        pop-location
    }
    else {
        push-location $pwd.path
        Set-location $location
    }
}

function Shorten-Path([string] $path) { 
    $loc = $path.Replace($HOME, '~') 
    $loc = $loc -replace '^[^:]+::', '' 
    return ($loc -replace '\\(\.?)([^\\])[^\\]*(?=\\)', '\$1$2') 
}

& {
    for ($i = 0; $i -lt 26; $i++) { 
        $funcname = ([System.Char]($i + 65)) + ':'
        $str = "function global:$funcname { set-location $funcname } " 
        Invoke-Expression $str 
    }
}

Remove-Item alias:ls
Set-Alias ls Get-ChildItemColor
 
function Get-ChildItemColor {
  
  $default = $Host.UI.RawUI.ForegroundColor
  function Write-OutputColoriezed {
    param ( 
      [string] $ForeGroundColor,
      [object] $Message
    ) 
    $Host.UI.RawUI.ForegroundColor = $ForeGroundColor
    Write-Output $Message
    $Host.UI.RawUI.ForegroundColor = $default
  }
  
  Invoke-Expression ("Get-ChildItem $args") | ForEach-Object {
    if ($_.PSIsContainer -eq $true) {
      Write-OutputColoriezed -ForeGroundColor 'Blue' -Message $_
    }
    elseif ($_.Extension -match '\.(zip|tar|gz|rar)$') {
      Write-OutputColoriezed -ForeGroundColor 'DarkGray' -Message $_
    }
    elseif ($_.Extension -match '\.(exe|bat|cmd|py|pl|ps1|psm1|vbs|rb|reg)$') {
      Write-OutputColoriezed -ForeGroundColor 'DarkCyan' -Message $_
    }
    elseif ($_.Extension -match '\.(txt|cfg|conf|ini|csv|sql|xml|config)$') {
      Write-OutputColoriezed -ForeGroundColor 'Cyan' -Message $_
    }
    elseif ($_.Extension -match '\.(cs|asax|aspx.cs)$') {
      Write-OutputColoriezed -ForeGroundColor 'Yellow' -Message $_
    }
    elseif ($_.Extension -match '\.(aspx|spark|master)$') {
      Write-OutputColoriezed -ForeGroundColor 'DarkYellow' -Message $_
    }
    elseif ($_.Extension -match '\.(sln|csproj)$') {
      Write-OutputColoriezed -ForeGroundColor 'Magenta' -Message $_
    }
    elseif ($_.Extension -match '\.(docx|doc|xls|xlsx|pdf|mobi|epub|mpp|)$') {
      Write-OutputColoriezed -ForeGroundColor 'Gray' -Message $_
    }
    else {
      Write-OutputColoriezed -ForeGroundColor $default -Message $_
    }
  }
}

function Get-ChildItemColorHidden {
  param(
    [string] $Path = $PWD.path
  )
  Get-ChildItemColor -Attributes Hidden -Path $Path
}
Set-Alias -Name ll -Value Get-ChildItemColorHidden

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}
