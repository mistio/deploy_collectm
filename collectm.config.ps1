[CmdletBinding()]
Param(

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$filePath,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$username,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$password,

    [Parameter(Mandatory=$false)]
    [switch]$restartService=$false,

    [Parameter(Mandatory=$false)]
    [string]$svcPath,

    [Parameter(Mandatory=$false)]
    [int32]$interval=5,

    [Parameter(Mandatory=$false)]
    [int32]$timeUntilRestart=-1,

    [Parameter(Mandatory=$false)]
    [int32]$logDeletionDays=30,

    [Parameter(Mandatory=$false)]
    [string]$httpAdmin="admin",

    [Parameter(Mandatory=$false)]
    [string]$httpPassword="admin",

    [Parameter(Mandatory=$false)]
    [int32]$listenPort=25826,

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$svcName="CollectM",

    [Parameter(Mandatory=$false)]
    [string[]]$servers=@("localhost:25826"),
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("", "default", "lower", "upper")]
    [string]$hostNameCase=""
)

if($restartService -eq $true -and !$svcPath) {
    Write-Host "You did not give the path to the location of the nssm. Exiting!"
    Exit
}

if (![System.IO.Path]::IsPathRooted($filePath)) {
    Write-Host "$filePath is not absolute"
    $filePath = (Convert-Path ".") + "\" + $filePath
    Write-Host "New path is $filePath"
}

if ((Test-Path $filePath) -eq $true) {
    Remove-Item $filePath
}

$configStr = "{`n  ""Hostname"": ""$username"",`n"
$configStr += "  //""HostnameCase"": ""default"" or ""lower"" or ""upper""`n"

if ($hostNameCase -ne "") {
    $configStr += "  ""HostnameCase"": ""$hostNameCase"",`n"
}

$configStr += "  ""Interval"": $interval,`n"
$configStr += "  ""Crypto"": {`n    ""SecurityLevel"": 2,`n    ""Username"": ""$username"",`n    ""Password"": ""$password""`n  },`n"
$configStr += "  //  ""CollectmTimeToLive"": 86400 Used to restart the service every # of seconds. Useful in case of memory leaks`n"

if ($timeUntilRestart -ne -1) {
    $configStr += "  ""CollectmTimeToLive"": $timeUntilRestart,`n"
}

$configStr += "  //  Every day, remove old logs (based on modified time).`n  //  If unset, or if set to 0, no logs will be deleted.`n"
$configStr += 
$congigStr += "  ""LogDeletionDays"": $logDeletionDays,`n"
$configStr += "  ""HttpConfig"": {`n    ""enable"": 1,`n    ""listenPort"": $listenPort,`n    ""login"": ""$httpAdmin"",`n    ""password"": ""$httpPassword""`n  },`n"
$configStr += "  ""Network"": {`n    ""servers"":`n    [`n"

## fix the servers ##
$counter = 0
foreach ($elem in $servers){
    $elems = $elem.Split(":")
    if ($elems.Count -eq 2) {
        if ($($elems[1].Trim()) -match "^[-]?[0-9.]+$") {
            if ($counter -ge 1) {
                $configStr += ",`n      {`n        ""hostname"": ""$($elems[0])"",`n        ""port"": $($elems[1])`n      }"
            } else {
                $configStr += "      {`n        ""hostname"": ""$($elems[0])"",`n        ""port"": $($elems[1])`n      }"
            }
            $counter++
        }
    }
}

$configStr += "`n    ]`n  },`n"
$configStr += "  ""Plugin"": {`n    ""collectdCompat"": {`n      ""enable"": 1`n    }`n,""process"": {`n      ""enable"": 0`n    }`n   }`n"
$configStr += "}"

## Output String to File and make sure that the file is UTF 8 w/o BOM ##
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($filePath, $configStr, $Utf8NoBomEncoding)

Write-Host "Updated CollectM configuration file"

if ($restartService -eq $true) {
    if ((Test-Path "$svcPath") -eq $true) {
        Start-Process "$svcPath" -ArgumentList "restart $svcName"
        Write-Host "Restarted CollectM service to load new config file"
    } else {
        Write-Host "Could not find executable in the path given to restart the service"
    }
}
