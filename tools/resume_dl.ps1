$ErrorActionPreference = "Continue"
$gh = "C:\Program Files\GitHub CLI\gh.exe"
$r = "C:\Users\User\Desktop\RideX"
$dist = Join-Path $r "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null
Get-Process curl -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-ChildItem $dist -Filter "part*.bin" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$zip = Join-Path $dist "artifact.zip"
$token = (& $gh auth token).Trim()
$arts = (& $gh api "repos/profesor26-png/RideX/actions/runs/44760267295/artifacts") | ConvertFrom-Json
$art = $arts.artifacts | Where-Object { $_.name -eq "ridex-ipa-unsigned" } | Select-Object -First 1
$api = "https://api.github.com/repos/profesor26-png/RideX/actions/artifacts/$($art.id)/zip"
$total = [int64]$art.size_in_bytes
"artifact: $($art.id)  total=$total"

for ($pass = 0; $pass -lt 40; $pass++) {
    $sz = if (Test-Path $zip) { (Get-Item $zip).Length } else { [int64]0 }
    if ($sz -ge $total) { break }
    $hdrs = & curl.exe -sIL -H "Authorization: token $token" $api
    $final = (($hdrs | Select-String -Pattern '(?i)^location:') | Select-Object -Last 1).Line -replace '(?i)^location:\s*', ''
    $lenLine = (($hdrs | Select-String -Pattern '(?i)^content-length:') | Select-Object -Last 1)
    if ($lenLine) {
        $l = [int64]($lenLine.Line -replace '(?i)^content-length:\s*', '')
        if ($l -gt 0) { $total = $l }
    }
    "pass $pass  have=$([math]::Round($sz/1MB,1))MB / $([math]::Round($total/1MB,1))MB"
    & curl.exe -sL --retry 20 --retry-delay 3 --retry-all-errors --max-time 540 -C - -o "$zip" $final
    Start-Sleep -Seconds 2
}

$sz = if (Test-Path $zip) { (Get-Item $zip).Length } else { 0 }
"downloaded: $([math]::Round($sz/1MB,1)) MB / $([math]::Round($total/1MB,1)) MB"

$py = @'
import zipfile, sys
z = zipfile.ZipFile(r"C:\Users\User\Desktop\RideX\dist\artifact.zip")
z.extractall(r"C:\Users\User\Desktop\RideX\dist")
print("extract OK")
'@
$py | Out-File -Encoding utf8 (Join-Path $r "tools\_extract.py")
python (Join-Path $r "tools\_extract.py")
Get-ChildItem $dist -File | Select-Object Name, @{n = 'MB'; e = { [math]::Round($_.Length / 1MB, 1) } }
