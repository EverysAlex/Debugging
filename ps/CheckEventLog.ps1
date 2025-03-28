# Run with:
# powershell -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/EverysAlex/Debugging/refs/heads/main/ps/CheckEventLog.ps1')))"

$events = @()

foreach ($event in Get-WinEvent -FilterHashtable @{ProviderName = 'Microsoft-Windows-Kernel-Power'; Id = 41} -ErrorAction SilentlyContinue)
{
    $events += @{Time = $event.TimeCreated; Info = 'Computer crashed (unexpected shutdown)'}
}

foreach ($event in Get-WinEvent -FilterHashtable @{ProviderName = 'Microsoft-Windows-WER-SystemErrorReporting'; Id = 1001} -ErrorAction SilentlyContinue)
{
    $events += @{Time = $event.TimeCreated; Info = 'Computer crashed (BSOD)'}
}

foreach ($event in Get-WinEvent -FilterHashtable @{ProviderName = 'Microsoft-Windows-Resource-Exhaustion-Detector'; Id = 2004} -ErrorAction SilentlyContinue)
{
    $events += @{Time = $event.TimeCreated; Info = 'Computer is out of memory'}
}

foreach ($event in Get-WinEvent -FilterHashtable @{ProviderName = 'disk'; Id = 7} -ErrorAction SilentlyContinue)
{
    $events += @{Time = $event.TimeCreated; Info = 'Disk malfunction'}
}

<#
foreach ($event in Get-WinEvent -FilterHashtable @{ProviderName = 'Microsoft-Windows-Kernel-General'; Id = 12} -ErrorAction SilentlyContinue)
{
    $events += @{Time = $event.TimeCreated; Info = 'Computer booted'}
}
#>

$events = $events | ForEach-Object {[PSCustomObject]@{Time=$_.Time; Info=$_.Info}}
$events | Sort-Object -Property 'Time' -Descending | Format-Table
