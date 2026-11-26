$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$mdPath = Join-Path $root 'docs\SDL_PSR_MOBILE_APP_SESSION_ANALYSIS_REPORT.html'
$pdfPath = Join-Path $root 'docs\SDL_PSR_MOBILE_APP_SESSION_ANALYSIS_REPORT.pdf'

$word = New-Object -ComObject Word.Application
$word.Visible = $false
try {
  $document = $word.Documents.Open($mdPath, $false, $true)
  $document.ExportAsFixedFormat($pdfPath, 17)
  $document.Close($false)
} finally {
  $word.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
}
Write-Output $pdfPath
