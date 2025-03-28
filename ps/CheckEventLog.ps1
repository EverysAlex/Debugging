# Run with:
# powershell -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/EverysAlex/Debugging/refs/heads/main/ps/CheckEventLog.ps1')))"

param([String]$a_eventsFile)

function GetEvents($a_provider, $a_eventID) {
    if ($a_eventsFile -ne "") {
        $filterXPath = "*[System[Provider[@Name='$a_provider'] and EventID=$a_eventID]]"
        return (Get-WinEvent -Path $a_eventsFile -FilterXPath $filterXPath -ErrorAction SilentlyContinue)
    } else {
        return (Get-WinEvent -FilterHashtable @{ProviderName = $a_provider; Id = $a_eventID} -ErrorAction SilentlyContinue)
    }
}

$events = @()

foreach ($event in GetEvents 'Microsoft-Windows-Kernel-Power' 41) {
    $events += @{Time = $event.TimeCreated; Info = "Booted after unexpected shutdown"}
}

foreach ($event in GetEvents 'EventLog' 6008) {
    $lastKnownTime = $event.Properties[1].Value + " " + $event.Properties[0].Value
    $events += @{Time = $event.TimeCreated; Info = "Unexpected shutdown on $lastKnownTime"}
}

foreach ($event in GetEvents 'Microsoft-Windows-WER-SystemErrorReporting' 1001) {
    $events += @{Time = $event.TimeCreated; Info = 'Computer crashed (BSOD)'}
}

foreach ($event in GetEvents 'Microsoft-Windows-Resource-Exhaustion-Detector' 2004) {
    $commitLimit  = [math]::round($event.Properties[0].Value /1Gb, 3)
    $commitCharge = [math]::round($event.Properties[1].Value /1Gb, 3)
    $events += @{Time = $event.TimeCreated; Info = "Computer is out of memory: $commitCharge/$commitLimit GB used"}
}

foreach ($event in GetEvents 'disk' 7) {
    $diskName = $event.Properties[0].Value
    $events += @{Time = $event.TimeCreated; Info = "Disk malfunction: $diskName"}
}

<#
foreach ($event in GetEvents 'Microsoft-Windows-Kernel-General' 12) {
    $events += @{Time = $event.TimeCreated; Info = "Computer booted"}
}
#>

if ($events.Count -eq 0) {
    Write-Host "All good, no dangerous events found"
    Exit
}

$events `
    | ForEach-Object {[PSCustomObject]@{Time=$_.Time.ToString("yyyy-MM-dd HH:mm:ss"); Info=$_.Info}} `
    | Sort-Object -Property 'Time' -Descending `
    | Format-Table
