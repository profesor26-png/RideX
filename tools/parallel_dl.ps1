$ErrorActionPreference = "Continue"
$gh = "C:\Program Files\GitHub CLI\gh.exe"
$r = "C:\Users\User\Desktop\RideX"
$dist = Join-Path $r "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null
Get-Process curl -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$token = (& $gh auth token).Trim()
$arts = (& $gh api "repos/profesor26-png/RideX/actions/runs/44604198019/artifacts") | ConvertFrom-Json
$art = $arts.artifacts | Where-Object { $_.name -eq "ridex-ipa-unsigned" } | Select-Object -First 1
$api = "https://api.github.com/repos/profesor26-png/RideX/actions/artifacts/$($art.id)/zip"
"art: $($art.id)  $([math]::Round($art.size_in_bytes/1MB,1)) MB"

$headers = & curl.exe -sIL -H "Authorization: token $token" $api
$locLines = $headers | Select-String -Pattern '(?i)^location:'
$final = ($locLines | Select-Object -Last 1).Line -replace '(?i)^location:\s*', ''
$lenLines = $headers | Select-String -Pattern '(?i)^content-length:'
$len = [int64](($lenLines | Select-Object -Last 1).Line -replace '(?i)^content-length:\s*', '')
"final: $final"
"len: $len"

if (-not $final -or $len -le 0) { "URL/len alinamadi"; exit 1 }

$parts = 8
$chunk = [math]::Ceiling($len / $parts)
$procs = @()
$files = @()
for ($i = 0; $i -lt $parts; $i++) {
    $start = [int64]($i * $chunk)
    $end = [int64][math]::Min($start + $chunk - 1, $len - 1)
    if ($start -gt $end) { break }
    $f = Join-Path $dist ("part{0}.bin" -f $i)
    $files += $f
    $cargs = @("-sL", "--retry", "30", "--retry-delay", "3", "--retry-all-errors", "-r", "$start-$end", "-o", $f, $final)
    $procs += Start-Process -FilePath "curl.exe" -ArgumentList $cargs -PassThru -NoNewWindow
}
"parts started: $($procs.Count)"
$procs | Wait-Process
"parts done"

$zip = Join-Path $dist "artifact.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
$out = [System.IO.File]::Create($zip)
foreach ($f in $files) {
    $in = [System.IO.File]::OpenRead($f)
    $in.CopyTo($out)
    $in.Close()
    Remove-Item $f -Force
}
$out.Close()
"zip MB: $([math]::Round((Get-Item $zip).Length / 1MB, 1))"
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $dist)
Get-ChildItem $dist -File | Select-Object Name, @{n = 'MB'; e = { [math]::Round($_.Length / 1MB, 1) } }
