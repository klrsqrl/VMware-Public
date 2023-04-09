function New-VMScheduledSnapshot {
<#
    .SYNOPSIS
    Creates a new scheduled snapshot for a VM in vCenter

    .DESCRIPTION
    Creates a new scheduled snapshot for a VM in vCenter

    .PARAMETER VM
    Name of the VM you want to create a scheduled snapshot for

    .PARAMETER MonthDayYear
    The date you want to perform the snapshot (ex. 05/24/2023)

    .PARAMETER Hour
    The hour you want to perform the snapshot
    Example: 09 for 9am
    Example: 16 for 4pm

    .PARAMETER Minute
    The minute you want to perform the snapshot

    .PARAMETER SnapName
    The name of the snapshot you want to create

    .PARAMETER SnapDescription
    The description you want to give for the snapshot you want to create

    .PARAMETER EmailAddr
    The email address(es) you want to send notification to when the snapshot is taken

    .PARAMETER SnapMemory
    Add this parameter if you want to snap the VM memory

    .PARAMETER SnapQuiesce
    Add this parameter if you want to quiesce the VM snapshot

    .EXAMPLE
    #Example test -VM MyVM -MonthDayYear 05/24/2023 -Hour 15 -Minute 14 -SnapName MyTestSnap -SnapDescription 'Snap Test' -EmailAddr 'user1@gmail.com,user2@gmail.com,user3@gmail.com' -SnapMemory -SnapQuiesce
    
    This will create a snapshot named "MyTestSnap" with a description of "Snap Test" for a VM named, "MyVM" on 05/24/2023 at 3:14pm.  It will send an email notification to user1,user2,user3, and it will snap memory and quiesce the VM snapshot

    .EXAMPLE
    #Example test -VM MyVM -MonthDayYear 05/24/2023 -Hour 09 -Minute 30 -SnapName MyTestSnap -SnapDescription 'Snap Test' -EmailAddr 'user1@gmail.com'

    This will create a snapshot named "MyTestSnap" with a description of "Snap Test" for a VM named, "MyVM" on 05/24/2023 at 09:30am.  It will send an email notification to user1.
    
    .NOTES
    Written by Jaime Navarro
#>
    [Cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [String]$VM,

        [Parameter(Mandatory)]
        [String]$MonthDayYear,

        [Parameter(Mandatory)]
        [String]$Hour,

        [Parameter(Mandatory)]
        [String]$Minute,

        [Parameter(Mandatory)]
        [String]$SnapName,

        [Parameter(Mandatory)]
        [String]$SnapDescription,

        [Parameter(Mandatory)]
        [String[]]$EmailAddr,

        [Parameter(Mandatory=$false)]
        [Switch]$SnapMemory,

        [Parameter(Mandatory=$false)]
        [Switch]$SnapQuiesce
    )

    $vmObj = Get-VM -Name $VM
    $snapTime = "$(Get-Date -Date $MonthDayYear -Hour $Hour -Minute $Minute)"
    $si = get-view ServiceInstance
    $scheduledTaskManager = Get-View $si.Content.ScheduledTaskManager
 
    $spec = New-Object VMware.Vim.ScheduledTaskSpec
    $spec.Name = $snapName
    $spec.Description = "$snapDescription"
    $spec.Enabled = $true
    $spec.Notification = $emailAddr
    $spec.Scheduler = New-Object VMware.Vim.OnceTaskScheduler
    $spec.Scheduler.runat = $snapTime
 
    $spec.Action = New-Object VMware.Vim.MethodAction
    $spec.Action.Name = "CreateSnapshot_Task"
 
    If ($SnapMemory.IsPresent) { $sMemory = $true }
    else { $sMemory = $false }

    If ($SnapQuiesce.IsPresent) { $sQuiesce = $true }
    else { $sQuiesce = $false }

    @($snapName,$snapDescription,$sMemory,$sQuiesce) | %{
        $arg = New-Object VMware.Vim.MethodActionArgument
        $arg.Value = $_
        $spec.Action.Argument += $arg
    }
 
    $scheduledTaskManager.CreateObjectScheduledTask($vmObj.ExtensionData.MoRef, $spec)
}
