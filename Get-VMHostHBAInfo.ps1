function Get-VMHostHBAInfo {
<#
    .SYNOPSIS
    Gets information about the installed HBAs on a ESXi Host

    .DESCRIPTION
    Gets the HBA information for each VMHost in a cluster

    .PARAMETER VMHost
    Enter the ESXi host you want to query

    .EXAMPLE
    Get-VMHostHBA -Cluster CLUSTER1

    .NOTES
    Written by Jaime Navarro
#>
    [Cmdletbinding()]
    param (
        [Parameter(Mandatory)]
        [String]$VMHost
    )

    $vmh = Get-VMHost -Name $VMHost
    $hbas = $vmh | Get-VMHostHBA -Type FibreChannel | where {$_.Status -eq "online" -or $_.Status -eq "offline"}

    foreach ($hba in $hbas) {
        $targets = ((Get-View $hba.VMhost).Config.StorageDevice.ScsiTopology.Adapter | where {$_.Adapter -eq $hba.Key}).Target
        $targetcount = $targets.Count
        Try {
            $luns = (Get-ScsiLun -Hba $hba -LunType "disk" -ErrorAction Stop).Count
        }
        Catch {
            $luns = 0
        }
        $paths = ($targets | Foreach-Object {$_.Lun.Count} | Measure-Object -Sum).Sum
        $nodewwn = ($hba | Select @{N="WWN";E={"{0:X}" -f $_.NodeWorldWideName}}).wwn
        $portwwn = ($hba | Select @{N="WWN";E={"{0:X}" -f $_.PortWorldWideName}}).wwn

        $psop = [ordered]@{
            VMHost = $hba.VMHost
            Device = $hba.Device
            Model = $hba.Model
            Type = $hba.Type
            Status = $hba.Status
            NodeWWN = $nodewwn
            PortWWN = $portwwn
            Targets = $targetcount
            LUNs = $luns
            Paths = $paths
        }
        $obj = New-Object -TypeName PSObject -Property $psop
        Write-Output $obj
    }
}