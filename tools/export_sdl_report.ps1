$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$csvPath = Join-Path $root 'docs\SDL_PSR_MOBILE_APP_SESSION_ANALYSIS.csv'
$xlsxPath = Join-Path $root 'docs\SDL_PSR_MOBILE_APP_SESSION_ANALYSIS.xlsx'

$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
try {
  $workbook = $excel.Workbooks.Add()
  $summary = $workbook.Worksheets.Item(1)
  $summary.Name = 'Summary'
  $summaryData = @(
    @('SDL PSR Mobile App Session Analysis','Value','Status'),
    @('Report date','2026-11-24','Measured'),
    @('Indexed project sessions','41','Measured'),
    @('Non-archived sessions','40','Measured'),
    @('Session additions proxy','14690','Measured proxy'),
    @('Session deletions proxy','3091','Measured proxy'),
    @('Flutter Dart files','49','Measured'),
    @('Flutter test files','12','Measured'),
    @('AI model / token / credit totals','Not available','Requires provider exports'),
    @('Copilot usage','Not available','No Copilot export in workspace')
  )
  for ($r=0; $r -lt $summaryData.Count; $r++) { for ($c=0; $c -lt 3; $c++) { $summary.Cells.Item($r+1,$c+1) = $summaryData[$r][$c] } }

  $data = Import-Csv $csvPath
  $sheet = $workbook.Worksheets.Add()
  $sheet.Name = 'Evidence'
  $headers = @('Category','Item','Value','Status','Source or note')
  for ($c=0; $c -lt $headers.Count; $c++) { $sheet.Cells.Item(1,$c+1) = $headers[$c] }
  for ($r=0; $r -lt $data.Count; $r++) {
    $row = $data[$r]
    $values = @($row.Category,$row.Item,$row.Value,$row.Status,$row.'Source or note')
    for ($c=0; $c -lt $values.Count; $c++) { $sheet.Cells.Item($r+2,$c+1) = $values[$c] }
  }

  foreach ($ws in @($summary,$sheet)) {
    $ws.Rows.Item(1).Font.Bold = $true
    $ws.Rows.Item(1).Interior.ColorIndex = 15
    $ws.UsedRange.Columns.AutoFit() | Out-Null
    $ws.UsedRange.WrapText = $true
  }
  $workbook.SaveAs($xlsxPath, 51)
  $workbook.Close($true)
} finally {
  $excel.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
}
Write-Output $xlsxPath
