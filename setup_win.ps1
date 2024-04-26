

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-File",$MyInvocation.MyCommand.Path
    Exit
}


$url = "https://packages.fluentbit.io/windows/fluent-bit-3.0.2-win64.exe"

$output = "C:\Program Files\fluent-bit-3.0.2-win64.exe"

Invoke-WebRequest -Uri $url -OutFile $output

$process = Start-Process -FilePath $output -PassThru
$process.WaitForExit()

$filePath = "C:\Program Files\fluent-bit\conf\fluent-bit.conf"

$newContent = @"
[SERVICE]
    flush        1
    daemon       Off
    log_level    info
    parsers_file parsers.conf
    storage.metrics on

[INPUT]
    Name         winlog
    Channels     Security, Application, System, Windows PowerShell
    Interval_Sec 1
    DB           winlog.sqlite

[OUTPUT]
    Name        http
    Match        *
    Host         3.36.119.174
    Port          8088
    uri          /win_log
    Format       json
"@

Set-Content -Path $filePath -Value $newContent -Force
