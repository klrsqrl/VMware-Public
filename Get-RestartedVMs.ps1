function Get-RestartedVMs {
<#
    .SYNOPSIS
    Gets a list of restarted VMs after an HA event

    .DESCRIPTION
    Returns a list of restarted VMs as well as where they migrated from/to

    .PARAMETER HoursToSearch
    The number of hours you want to go back and check
    
    .PARAMETER VMClusterToSearch
    The cluster you want to check against

    .PARAMETER VMHostToSearch
    The host you want to check against

    .EXAMPLE
    Get-RestartedVMs -HoursToSearch 4 -VMClusterToSearch CLUSTER1

    .EXAMPLE
    Get-RestartedVMs -HoursToSearch 2 -VMHostToSearch esxhost01.local

    .EXAMPLE 
    Get-RestartedVMs -HoursToSearch 24

    .NOTES
    Written by Jaime Navarro
#>
    [Cmdletbinding()]

    param (
        [Parameter(Mandatory=$true)]
        [int]$HoursToSearch,

        [Parameter(Mandatory=$false)]
        [String]$VMClusterToSearch,

        [Parameter(Mandatory=$false)]
        [String]$VMHostToSearch
    )

    Write-Verbose "Gathering VMs..."
    $events = Get-VIEvent -maxsamples 100000 -Start ((Get-Date).AddHours(-$HoursToSearch)) -type warning | Where {$_.FullFormattedMessage -match "restarted"} |select * |sort CreatedTime -Descending
    
    If ($VMClusterToSearch) {
        Write-Verbose "Gathering VMHosts Info for $VMClusterToSearch Cluster..."
        $VMHostQuery = Get-Cluster -Name $VMClusterToSearch | Get-VMHost
    }
    elseif ($VMHostToSearch){
        Write-Verbose "Gathering VMHost Info for $VMHostToSearch..."
        $VMHostQuery = Get-VMHost -Name $VMHostToSearch
    }
    else {
        Write-Verbose "No Cluster or Host specified.  Gathering ALL VMHosts Info..."
        $VMHostQuery = Get-VMHost
    }
    
    $restartedFromHost = $VMHostQuery | ?{$_.ExtensionData.Runtime.BootTime.AddHours(-6) -gt (Get-Date).AddHours(-$HoursToSearch)}

    If ($events.Count -ge 1) {
        foreach ($event in $events) {
            $psop = [ordered]@{
                Name = $event.ObjectName
                Type = $event.ObjectType
                RestartedTime = $event.CreatedTime
                RestartedFromHost = $restartedFromHost
                RestartedToHost = $event.FullFormattedMessage.Split(' ')[8]
                HostCluster = $event.FullFormattedMessage.Split(' ')[11]
            }
            $obj = New-Object -TypeName PSObject -Property $psop
            Write-Output $obj
        }
    }
    Else {
        Write-Output 'No results found.'
    }
}