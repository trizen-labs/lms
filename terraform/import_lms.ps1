param()
$B = "http://44.198.68.2:8000"
$EXPORT_DIR = "d:\Personal\Trizen\Projects\lms\terraform\lms_export"

$lf = @{ usr = "Administrator"; pwd = "admin" }
Invoke-WebRequest -Uri "$B/api/method/login" -Method POST -Body $lf -SessionVariable ws -UseBasicParsing | Out-Null
Write-Host "Logged into $B"

function Try-Exists($doctype, $name) {
    $enc = [uri]::EscapeDataString($doctype)
    $encName = [uri]::EscapeDataString($name)
    try {
        Invoke-WebRequest -Uri "$B/api/resource/$enc/$encName" -WebSession $ws -UseBasicParsing -EA Stop | Out-Null
        return $true
    }
    catch { return $false }
}

function Post-Doc($doctype, $clean) {
    $enc = [uri]::EscapeDataString($doctype)
    $json = $clean | ConvertTo-Json -Depth 20 -Compress
    $body = "doc=$([uri]::EscapeDataString($json))"
    $r = Invoke-WebRequest -Uri "$B/api/resource/$enc" -Method POST -Body $body `
        -WebSession $ws -UseBasicParsing -EA Stop `
        -ContentType "application/x-www-form-urlencoded"
    return $r
}

function Import-Records($filename, $doctype) {
    $path = Join-Path $EXPORT_DIR $filename
    if (-not (Test-Path $path)) { Write-Host "SKIP (no file): $filename"; return }
    $raw = Get-Content $path -Raw
    $records = $raw | ConvertFrom-Json
    if ($null -eq $records) { Write-Host "SKIP (empty): $doctype"; return }
    if ($records -isnot [System.Array]) { $records = @($records) }

    $skip = @("owner","creation","modified","modified_by","docstatus","idx","__islocal","__unsaved","_comments","_user_tags","_likes","_assign")
    $created = 0
    $existed = 0
    $errors = 0

    foreach ($rec in $records) {
        $name = $rec.name
        if (Try-Exists $doctype $name) {
            $existed++
            continue
        }
        $clean = @{ doctype = $doctype; __newname = $name }
        foreach ($k in $rec.PSObject.Properties.Name) {
            if ($skip -notcontains $k) {
                $v = $rec.$k
                if ($null -ne $v) { $clean[$k] = $v }
            }
        }
        try {
            Post-Doc $doctype $clean | Out-Null
            $created++
        }
        catch {
            $errors++
            $msg = $_.Exception.Message
            Write-Host "  [ERR] $name : $($msg.Substring(0, [Math]::Min(120,$msg.Length)))"
        }
    }
    Write-Host "DONE $doctype | created=$created existed=$existed errors=$errors"
}

Write-Host "`n--- Users ---"
$users = (Get-Content (Join-Path $EXPORT_DIR "User.json") -Raw) | ConvertFrom-Json
if ($users -isnot [System.Array]) { $users = @($users) }
$uc = 0; $ue = 0; $uerr = 0
foreach ($u in $users) {
    if ($u.name -in @("Administrator","Guest")) { continue }
    if (Try-Exists "User" $u.name) { $ue++; continue }
    $ln = if ($u.last_name) { $u.last_name } else { "" }
    $clean = @{
        doctype            = "User"
        email              = $u.email
        first_name         = $u.first_name
        last_name          = $ln
        username           = $u.username
        enabled            = 1
        send_welcome_email = 0
        new_password       = "Welcome@123"
    }
    try { Post-Doc "User" $clean | Out-Null; $uc++ }
    catch {
        $uerr++
        $msg = $_.Exception.Message
        Write-Host "  [ERR] $($u.name): $($msg.Substring(0,[Math]::Min(100,$msg.Length)))"
    }
}
Write-Host "DONE Users | created=$uc existed=$ue errors=$uerr"

Write-Host "`n--- Roles ---"
$lmsRoles = @("Moderator","Course Creator","Batch Evaluator","LMS Student")
foreach ($u in $users) {
    if ($u.name -in @("Administrator","Guest")) { continue }
    if ($null -eq $u.roles) { continue }
    foreach ($re in $u.roles) {
        $role = $re.role
        if ($role -notin $lmsRoles) { continue }
        $clean = @{ doctype="Has Role"; parent=$u.name; parenttype="User"; parentfield="roles"; role=$role }
        try { Post-Doc "Has Role" $clean | Out-Null } catch {}
    }
}
Write-Host "Roles assigned"

Write-Host "`n--- LMS Courses ---"
Import-Records "LMS_Course.json" "LMS Course"

Write-Host "`n--- LMS Batches ---"
Import-Records "LMS_Batch.json" "LMS Batch"

Write-Host "`n--- LMS Quizzes ---"
Import-Records "LMS_Quiz.json" "LMS Quiz"

Write-Host "`n--- LMS Assignments ---"
Import-Records "LMS_Assignment.json" "LMS Assignment"

Write-Host "`n--- LMS Enrollments ---"
Import-Records "LMS_Enrollment.json" "LMS Enrollment"

Write-Host "`n--- LMS Course Progress ---"
Import-Records "LMS_Course_Progress.json" "LMS Course Progress"

Write-Host "`n--- LMS Quiz Submissions ---"
Import-Records "LMS_Quiz_Submission.json" "LMS Quiz Submission"

Write-Host "`n--- LMS Assignment Submissions ---"
Import-Records "LMS_Assignment_Submission.json" "LMS Assignment Submission"

Write-Host "`n--- LMS Certificates ---"
Import-Records "LMS_Certificate.json" "LMS Certificate"

Write-Host "`n--- LMS Course Reviews ---"
Import-Records "LMS_Course_Review.json" "LMS Course Review"

Write-Host "`n--- LMS Badges ---"
Import-Records "LMS_Badge.json" "LMS Badge"

Write-Host "`n--- LMS Badge Assignments ---"
Import-Records "LMS_Badge_Assignment.json" "LMS Badge Assignment"

Write-Host "`n=== IMPORT COMPLETE ==="
