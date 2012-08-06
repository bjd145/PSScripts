﻿[CmdletBinding(SupportsShouldProcess=$true)]
param (
	[Parameter(Mandatory=$true)]
	[string[]]
	$computers,
	
	[string]
	$counter = "\Web Service(_Total)\Current Connections",
	
	[int]
	$samples = 10,
	
	[ValidateSet("realtime", "csv", "chart")]
	[string] $operation = "realtime"

)

. (Join-Path $ENV:SCRIPTS_HOME "Libraries\SharePoint_Functions.ps1")
. (Join-Path $ENV:SCRIPTS_HOME "Libraries\Standard_Functions.ps1")
. (Join-Path $ENV:SCRIPTS_HOME "Libraries\LibraryChart.ps1")

Write-Verbose "Working on the following computers - $computers"
Write-Verbose "Working on the following counters - $counter"

if ($pscmdlet.shouldprocess($ENV:COMPUTERNAME, "Get-PerformanceCounters -computers $computers -counter $counter to $file") )
{
	if( $operation -eq "realtime" ) { 
		Get-PerformanceCounters -computers $computers -counters $counter -interval 1 -samples $samples 
	}
	else
	{
		$ht = Get-PerformanceCounters -computers $computers -counters $counter -interval 1 -samples $samples  | Group-Object -Property Path -AsHashTable
		$ht.Keys | Sort | % { 
		
			$ErrorActionPreference = "SilentlyContinue"
			
			Write-Host $_
			$ht[$_] | Select Time, CookedValue
			
			if($operation -eq "csv") 
			{
				$file = (Join-Path $PWD:Path ($_.Split("\")[2] + "-current_connections.csv") )
				$ht[$_] | Export-Csv -Encoding ascii $file
			}
			
			if($operation -eq "chart") 
			{
				$file = (Join-Path $PWD:Path ($_.Split("\")[2] + "-current_connections.png") )
				$ht[$_] |  out-chart -xField 'Time' -yField 'CookedValue' -filename  $file
			}
		}
	}
}