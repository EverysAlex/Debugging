# Run with:
# powershell -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/EverysAlex/Debugging/refs/heads/main/ps/RecentlyUpdatedProcesses.ps1')))"

Add-Type -TypeDefinition (irm 'https://raw.githubusercontent.com/EverysAlex/Debugging/refs/heads/main/cs/GetProcessesEx.cs')
$processes = [GetProcessesEx.Processes]::Get()

$processes |
    Select-Object `
        @{Name='PID';      Expression={$_.Process.Id}}, `
        @{Name='Modified'; Expression={(Get-Item $_.ExePath).LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")}}, `
      # @{Name='Version';  Expression={(Get-Item $_.ExePath).VersionInfo.FileVersionRaw}}, `
        @{Name='Path';     Expression={if ($_.ExePath -ne "") {$_.ExePath} else {$_.Process.Name}}} |
    Sort-Object -Property 'Modified' -Descending |
    Format-Table |
    Out-String -width 1000
