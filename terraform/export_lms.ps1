$BASE = "https://portal.capilingua.com"
$OUT  = "d:\Personal\Trizen\Projects\lms\terraform\lms_export"
New-Item -ItemType Directory -Force -Path $OUT | Out-Null

# Login
$loginFields = @{ usr = "Administrator"; pwd = "47e6b4a6aa03" }
$resp = Invoke-WebRequest -Uri "$BASE/api/method/login" -Method POST -Body $loginFields -SessionVariable ws -UseBasicParsing -ErrorAction Stop
Write-Host "Login: $($resp.StatusCode)"
$hdrs = @{}

$doctypes = @(
  "LMS Course",
  "LMS Enrollment",
  "LMS Batch",
  "LMS Batch Enrollment",
  "LMS Quiz",
  "LMS Quiz Question",
  "LMS Quiz Submission",
  "LMS Quiz Result",
  "LMS Assignment",
  "LMS Assignment Submission",
  "LMS Certificate",
  "LMS Course Progress",
  "LMS Course Review",
  "LMS Live Class",
  "LMS Settings",
  "Batch Course",
  "Course Chapter",
  "Course Lesson",
  "LMS Section",
  "LMS Question",
  "LMS Option",
  "User"
)

Write-Host "=== Exporting ==="
foreach ($dt in $doctypes) {
  $slug = [uri]::EscapeDataString($dt)
  $url  = "$BASE/api/resource/$slug?limit_page_length=999"
  try {
    $r    = Invoke-WebRequest -Uri $url -Headers $hdrs -WebSession $ws -UseBasicParsing -ErrorAction Stop
    $list = ($r.Content | ConvertFrom-Json).data
    if ($null -eq $list) { Write-Host "  EMPTY: $dt"; continue }
    Write-Host "  $dt`: $($list.Count) items - fetching details..."
    $records = @()
    foreach ($item in $list) {
      $du = "$BASE/api/resource/$slug/$([uri]::EscapeDataString($item.name))"
      try {
        $dr = Invoke-WebRequest -Uri $du -Headers $hdrs -WebSession $ws -UseBasicParsing -ErrorAction Stop
        $records += ($dr.Content | ConvertFrom-Json).data
      } catch { }
    }
    $fn = $dt.Replace(" ", "_") + ".json"
    $records | ConvertTo-Json -Depth 20 | Out-File "$OUT\$fn" -Encoding utf8
    Write-Host "  SAVED $fn ($($records.Count) records)"
  } catch {
    $code = $_.Exception.Response.StatusCode.Value__
    Write-Host "  SKIP [$code] $dt"
  }
}
Write-Host "=== Done: $OUT ==="
