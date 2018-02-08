<#
    .SYNOPSIS 
     Simulates liunx/unix top in windows
    .DESCRIPTION
       
#>

Param([string]$ProcessName, [int]$SelectFirst, [switch]$GridView)

If (! $ProcessName) { $ProcessName = '*' }
If (! $SelectFirst) { $SelectFirst = 5 }

If ($ProcessName -eq '*') {
  $ProcessList = gwmi Win32_PerfFormattedData_PerfProc_Process | select IDProcess,Name,PercentProcessorTime | where { $_.Name -ne "_Total" -and $_.Name -ne "Idle"} | sort PercentProcessorTime -Descending | select -First $SelectFirst
}
Else {
  $ProcessList = gwmi Win32_PerfFormattedData_PerfProc_Process | where {$_.Name -eq $ProcessName} | select IDProcess,Name,PercentProcessorTime | sort PercentProcessorTime -Descending | select -First $SelectFirst
}
$TopProcess = @()
ForEach ($Process in $ProcessList) {
  $row = new-object PSObject -Property @{
    Id = $Process.IDProcess
    Name = $Process.Name
    User = (gwmi Win32_Process | where {$_.ProcessId -eq $Process.IDProcess}).GetOwner().User
    CPU = $Process.PercentProcessorTime
    Description = (Get-Process -Id $Process.IDProcess).Description
  }
  $TopProcess += $row
}

If ($GridView) {
  $TopProcess | sort CPU -Descending | select Id,Name,User,CPU,Description | Out-GridView
}
Else {
  $TopProcess | sort CPU -Descending | select Id,Name,User,CPU,Description | ft -AutoSize
}
