Set-Variable -Name SChannelRegKeyPath        -Value 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL' -Option Constant
Set-Variable -Name SChannelDisableServerKey  -Value 'DisableRenegoOnServer'                                             -Option Constant
Set-Variable -Name SChannelDisableClientKey  -Value 'DisableRenegoOnClient'                                             -Option Constant
Set-Variable -Name Disable                   -Value 1                                                                   -Option Constant

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param (
		[parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure 
	)

	Write-Verbose "Use this cmdlet to deliver information about command processing."
    $returnValue = @{
		Ensure = "Absent"
	}

    if( (Test-Path -Path $SChannelRegKeyPath) ) {
        $Key = Get-Item -Path $SChannelRegKeyPath
        if( $key.GetValue($SChannelDisableServerKey) -and $key.GetValue($SChannelDisableClientKey) ) {
            $server = Get-ItemPropertyValue -Path $SChannelRegKeyPath -Name $SChannelDisableServerKey
            $client = Get-ItemPropertyValue -Path $SChannelRegKeyPath -Name $SChannelDisableClientKey
            if( $server -eq 1 -and $client -eq 1 ) { 
                $returnValue.Ensure = "Present"
            }
        }
    }
    
	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param (
		[parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure 

	)

    if( $Ensure -eq "Absent" ) {
        Remove-ItemProperty -Path $SChannelRegKeyPath -Name $SChannelDisableServerKey
        Remove-ItemProperty -Path $SChannelRegKeyPath -Name $SChannelDisableClientKey
    }
    else {
        Set-ItemProperty -Path $SChannelRegKeyPath -Name $SChannelDisableServerKey -Value $Disable
        Set-ItemProperty -Path $SChannelRegKeyPath -Name $SChannelDisableClientKey -Value $Disable
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param (
		[parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure 
	)

    $Value = Get-TargetResource -Ensure $Ensure 
    $ResultValues = @{}

    if( $Value.Ensure -eq $Ensure ) {
        $ResultValues.Ensure = $true
    }
    else {
        $ResultValues.Ensure = $false 
    }

    $ResultValues

}


Export-ModuleMember -Function *-TargetResource

