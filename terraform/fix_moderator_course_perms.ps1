$B = "https://portal.capilingua.com"
$lf = @{ usr = "Administrator"; pwd = "47e6b4a6aa03" }
Invoke-WebRequest -Uri "$B/api/method/login" -Method POST -Body $lf -SessionVariable ws -UseBasicParsing | Out-Null
Write-Host "Logged in"

# All doctypes involved in course editing
$doctypes = @(
    "LMS Course",
    "Course Chapter",
    "Course Lesson",
    "LMS Quiz",
    "LMS Question",
    "LMS Assignment",
    "LMS Source",
    "LMS Live Class",
    "LMS Timetable Template"
)

foreach ($dt in $doctypes) {
    # Just create the Custom DocPerm — ignore if duplicate (409 = already exists)
    $doc = @{
        doctype     = "Custom DocPerm"
        parent      = $dt
        parenttype  = "DocType"
        parentfield = "permissions"
        role        = "Moderator"
        permlevel   = 0
        read        = 1
        write       = 1
        create      = 1
        delete      = 1
        report      = 1
        export      = 1
        if_owner    = 0
    } | ConvertTo-Json

    try {
        $r = Invoke-WebRequest -Uri "$B/api/resource/Custom%20DocPerm" -Method POST -Body $doc -WebSession $ws -UseBasicParsing -ContentType "application/json" -ErrorAction Stop
        Write-Host "CREATED $dt`: $($r.StatusCode)"
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        if ($status -eq 409 -or $_.Exception.Message -like "*DuplicateEntryError*") {
            Write-Host "EXISTS  $dt (already has Custom DocPerm)"
        } else {
            Write-Host "ERROR   $dt`: $($_.Exception.Message.Split([char]10)[0])"
        }
    }
}

Write-Host ""
Write-Host "Done. Moderators can now edit all courses regardless of owner."
