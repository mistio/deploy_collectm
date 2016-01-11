[CmdletBinding()]
Param(

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$url,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$filePath

)

if ($runScript -eq $true -and !$args) {
    Write-Host "You want the script to run but you didn't provide any arguments!"
    Exit
}

"Downloading $url"
$uri = New-Object "System.Uri" "$url"
$request = [System.Net.HttpWebRequest]::Create($uri)
## 15 second timeout ##
$request.set_Timeout(15000)
$response = $request.GetResponse()
$totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
$responseStream = $response.GetResponseStream()
$targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $filePath, Create
$buffer = New-Object byte[] 10KB
$count = $responseStream.Read($buffer,0,$buffer.length)
$downloadedBytes = $count
$iterations = 0
$startLeft = [Console]::CursorLeft
$startTop = [Console]::CursorTop
while ($count -gt 0) {
    [Console]::SetCursorPosition($startLeft, $startTop)
    $targetStream.Write($buffer, 0, $count)
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes = $downloadedBytes + $count
    $iterations += 1
    if (($iterations % 130 -eq 0) -or ([System.Math]::Floor($downloadedBytes/1024) -eq $totalLength)) {
        [System.Console]::Write("Downloaded {0}K of {1}K`n", [System.Math]::Floor($downloadedBytes/1024), $totalLength)
    }
}
Write-Host "Finished Download"
$targetStream.Flush()
$targetStream.Close()
$targetStream.Dispose()
$responseStream.Dispose()