$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$mdPath = Join-Path $root 'docs\SDL_PSR_MOBILE_APP_SESSION_ANALYSIS_REPORT.md'
$htmlPath = Join-Path $root 'docs\SDL_PSR_MOBILE_APP_SESSION_ANALYSIS_REPORT.html'
$pdfPath = Join-Path $root 'docs\SDL_PSR_MOBILE_APP_SESSION_ANALYSIS_REPORT.pdf'
$chromePath = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$profilePath = Join-Path $root '.chrome-pdf-profile'

$markdown = Get-Content -Raw $mdPath
$encoded = [System.Net.WebUtility]::HtmlEncode($markdown)
$html = @"
<!doctype html>
<html><head><meta charset="utf-8"><title>SDL PSR Mobile App Analysis Report</title>
<style>body{font-family:Segoe UI,Arial,sans-serif;margin:36px;color:#1f2937}h1{color:#123b63;font-size:24px}pre{white-space:pre-wrap;font:12px/1.5 Consolas,monospace} @page{size:A4;margin:18mm}</style>
</head><body><pre>$encoded</pre></body></html>
"@
Set-Content -LiteralPath $htmlPath -Value $html -Encoding UTF8
& $chromePath --headless --disable-gpu --no-sandbox --user-data-dir=$profilePath --allow-file-access-from-files --print-to-pdf=$pdfPath --print-to-pdf-no-header "file:///$($htmlPath -replace '\\','/')" | Out-Null
Get-Item $pdfPath | Select-Object FullName,Length,LastWriteTime
