Set-Variable -Name SCRIPT:map -Value @{}
Set-Variable -Name sessions -Value @{}

Import-Module (Join-Path $ENV:SCRIPTS_HOME "\Libraries\Credentials.psm1")

Set-Variable -Name sb_servers_to_deploy -Value {
	param ([string] $type = "Microsoft SharePoint Foundation Web Application")
    . (Join-Path $ENV:SCRIPTS_HOME "Libraries\SharePoint2010_Functions.ps1")
    Get-SPServiceInstance | Where { $_.TypeName -eq $type -and $_.Status -eq "Online" } | Select @{N="Servers";E={$_.Server.Address}} | Select -ExpandProperty Servers
}

Set-Variable -Name sb_iis_home_directory -Value {
	param ( [string] $url, [string] $zone = "Default" )
	. (Join-Path $ENV:SCRIPTS_HOME "Libraries\SharePoint2010_Functions.ps1")
	$sp_web_application = Get-SPWebApplication ("http://" + $url)
	$zone_settings = $sp_web_application.IISSettings[$zone]
	return ($zone_settings.Path | Select -Expand FullName)
}

function Get-PSRemoteSession
{
    param(
        [string] $remote_server
    )

    if(!$sessions.ContainsKey($remote_server)) {
        $session = New-PSSession -ComputerName $remote_server -Authentication CredSSP -Credential (Get-Cred) 
        $sessions.Add($remote_server, $session)
    }
    
    return $sessions[$remote_server]
}

function Get-SPIISHomeDirectory
{
    param(
        [string] $url, 
        [string] $central_admin, 
        [string] $zone
    )

	Write-Verbose -Message ("Destination set to auto. Going to deteremine the IIS Home Directory for $url in the $zone zone")
	$home_directory = Invoke-Command -Session (Get-PSRemoteSession -remote_server $server) `
        -ScriptBlock $sb_iis_home_directory `
        -ArgumentList $url, $zone

    return $home_directory
}

function Get-SPServersForComponent
{	
    param(
        [string] $central_admin
    )

	Write-Verbose -Message ("Configuration set to auto. Going to determine SharePoint Foundation Web Application servers for the $farm $env farm")
	$servers = Invoke-Command -Session (Get-PSRemoteSession -remote_server $central_admin) `
        -ScriptBlock $sb_servers_to_deploy 

    Write-Verbose -Mesage ("Found the following servers that have the Web Application role online - " + $servers)
	return $servers
}


function New-DeploymentMap
{	
    param(
        [Parameter(Position=0,ValueFromPipeline=$true)]
        [object] $config,
        [string] $url
    )
	
	Set-Variable -Name servers -Value @()

	if( $config.servers.type -ieq "sharepoint" ) {
		$servers = Get-SPServersForComponent -central_admin $config.servers.server
	}
    elseif( $config.servers.type -ieq ".net" ) {
        $servers = $config.servers.server #Feature is coming but for now treat as manual
    }
    else {
		$servers = $config.servers.server
	}
			
	$map = @()
    foreach( $location in $config.locations.location ) {
		if( $location.destination -eq "auto" ) {
			$destination = Get-SPIISHomeDirectory -url $url -central_admin $central_admin -zone $location.name
		}
        else {
			$destination = $location.destination
		}
		
		$map += New-Object PSObject -Property @{ 
		 	Source =  $location.Source
			Destination = $destination
			Servers = $servers
			File = $location.file
		}
	}

    if($VerbosePreference) {
        foreach( $config in $map ) {
            Write-Verbose -Message ("VERBOSE: Map Section - $($config) ...")
        }
    }
	return $map
}


function Set-DeploymentMapCache { 
	param(
		[Object] $map,
		[string] $url
	)
	
	$SCRIPT:map[$url] = $map
}

function Get-DeploymentMapCache {
	param(
		[string] $url
	)
	
	return $SCRIPT:map[$url]
}

Export-ModuleMember -Function New-DeploymentMap,Get-DeploymentMapCache, Set-DeploymentMapCache