param(
    [Parameter(Mandatory = $true)][string]$Path
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding $false

function Write-Result($result) {
    [Console]::Out.WriteLine(($result | ConvertTo-Json -Compress))
}

try {
    $key = $env:API_KEY
    if (-not $key) { throw 'API key not valid. Please pass a valid API key.' }

    $item = Get-Item -LiteralPath $Path
    Add-Type -AssemblyName System.Web
    $mime = [System.Web.MimeMapping]::GetMimeMapping($item.Name)
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $start = Invoke-WebRequest -UseBasicParsing -Method Post `
        -Uri 'https://generativelanguage.googleapis.com/upload/v1beta/files' `
        -Headers @{
            'x-goog-api-key' = $key
            'X-Goog-Upload-Protocol' = 'resumable'
            'X-Goog-Upload-Command' = 'start'
            'X-Goog-Upload-Header-Content-Length' = [string]$item.Length
            'X-Goog-Upload-Header-Content-Type' = $mime
        } `
        -ContentType 'application/json' `
        -Body '{"file": {"display_name": "Image"}}'

    $uploadUrl = @($start.Headers['X-Goog-Upload-URL'])[0]
    if (-not $uploadUrl) { throw 'The upload was not accepted.' }

    $done = Invoke-WebRequest -UseBasicParsing -Method Post -Uri $uploadUrl `
        -Headers @{
            'x-goog-api-key' = $key
            'X-Goog-Upload-Offset' = '0'
            'X-Goog-Upload-Command' = 'upload, finalize'
        } `
        -ContentType $mime `
        -InFile $item.FullName

    $file = ($done.Content | ConvertFrom-Json).file
    if (-not $file.uri) { throw 'The upload returned no file.' }
    $fileMime = if ($file.mimeType) { $file.mimeType } else { $mime }
    Write-Result @{ uri = $file.uri; mimeType = $fileMime }
} catch {
    $message = $_.Exception.Message
    $response = $_.Exception.Response
    if ($response) {
        try {
            $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
            $body = $reader.ReadToEnd() | ConvertFrom-Json
            if ($body.error.message) { $message = $body.error.message }
        } catch {}
    }
    Write-Result @{ error = $message }
    exit 1
}
