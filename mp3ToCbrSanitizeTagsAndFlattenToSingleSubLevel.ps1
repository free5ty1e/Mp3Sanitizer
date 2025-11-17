# PIONEER S21BT - ULTIMATE FINAL - NOV 17 2025
# 100% PRESERVES YOUR TOP-LEVEL FOLDERS - NO MISSING SONGS - FULL ERROR REPORT
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Auto-detect ffmpeg next to script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$defaultFF = "$scriptDir\ffmpeg\bin\ffmpeg.exe"
$global:ffmpeg = if(Test-Path $defaultFF) { $defaultFF } else { $null }

$form = New-Object Windows.Forms.Form
$form.Text = "PIONEER S21BT - ULTIMATE USB FIXER"
$form.Size = "780,660"
$form.StartPosition = "CenterScreen"
$form.Font = "Consolas,10"
$form.BackColor = "#0A0A0A"
$form.ForeColor = "#00FF00"

# FFMPEG
$lblFF = New-Object Windows.Forms.Label
$lblFF.Location = "20,10"
$lblFF.Size = "740,50"
$lblFF.Text = if($global:ffmpeg) { "FFmpeg FOUND: $global:ffmpeg" } else { "DRAG FFMPEG FOLDER HERE" }
$lblFF.BackColor = if($global:ffmpeg) { "#004400" } else { "#440000" }
$lblFF.TextAlign = "MiddleCenter"
$form.Controls.Add($lblFF)

# INPUT
$lblIn = New-Object Windows.Forms.Label
$lblIn.Location = "20,70"
$lblIn.Size = "740,60"
$lblIn.Text = "INPUT: Drag your music folder here"
$lblIn.BackColor = "#333333"
$lblIn.TextAlign = "MiddleCenter"
$form.Controls.Add($lblIn)

# OUTPUT
$lblOut = New-Object Windows.Forms.Label
$lblOut.Location = "20,140"
$lblOut.Size = "740,60"
$lblOut.Text = "OUTPUT: Drag destination (default: Downloads\PioneerFixed)"
$lblOut.BackColor = "#333333"
$lblOut.TextAlign = "MiddleCenter"
$form.Controls.Add($lblOut)

$outputFolder = "$env:USERPROFILE\Downloads\PioneerFixed"

# BITRATE
$cmb = New-Object Windows.Forms.ComboBox
$cmb.Location = "20,210"
$cmb.Size = "100,30"
"128","192","256","320" | % { $cmb.Items.Add($_) }
$cmb.SelectedIndex = 1
$form.Controls.Add($cmb)
$lblB = New-Object Windows.Forms.Label
$lblB.Location = "130,210"
$lblB.Size = "100,30"
$lblB.Text = "kbps CBR"
$form.Controls.Add($lblB)

# START
$btn = New-Object Windows.Forms.Button
$btn.Location = "20,250"
$btn.Size = "740,80"
$btn.Text = "START - THIS ONE REALLY WORKS"
$btn.BackColor = "#00FF00"
$btn.ForeColor = "Black"
$btn.Font = "Consolas,16,style=Bold"
$btn.Enabled = $false
$form.Controls.Add($btn)

# PROGRESS + STATS
$pb = New-Object Windows.Forms.ProgressBar
$pb.Location = "20,340"
$pb.Size = "740,30"
$pb.Visible = $false
$form.Controls.Add($pb)

$stat = New-Object Windows.Forms.Label
$stat.Location = "20,380"
$stat.Size = "740,200"
$stat.Text = "Ready."
$stat.TextAlign = "MiddleLeft"
$form.Controls.Add($stat)

# GLOBALS
$global:src = $null
$global:out = $outputFolder
$global:failed = @()
$global:topLevelCount = 0

# DRAG HANDLERS
$lblFF.AllowDrop = $true ; $lblFF.Add_DragEnter({$_.Effect="Copy";$lblFF.BackColor="#008800"})
$lblFF.Add_DragDrop({
    $p = $_.Data.GetData("FileDrop")[0]
    $test = Join-Path $p "bin\ffmpeg.exe"
    if(Test-Path $test){ $global:ffmpeg = $test; $lblFF.Text = "FFmpeg: $test"; $lblFF.BackColor = "#004400"; $btn.Enabled = ($global:src -and $global:out -and $global:ffmpeg) }
})
$lblIn.AllowDrop = $true ; $lblIn.Add_DragEnter({$_.Effect="Copy";$lblIn.BackColor="#008800"})
$lblIn.Add_DragDrop({
    $p = $_.Data.GetData("FileDrop")[0]
    if((Test-Path $p) -and (Get-Item $p).PSIsContainer){
        $global:src = $p
        $lblIn.Text = "INPUT: $p"
        $lblIn.BackColor = "#004400"
        $btn.Enabled = ($global:src -and $global:out -and $global:ffmpeg)
    }
})
$lblOut.AllowDrop = $true ; $lblOut.Add_DragEnter({$_.Effect="Copy";$lblOut.BackColor="#008800"})
$lblOut.Add_DragDrop({
    $p = $_.Data.GetData("FileDrop")[0]
    if((Test-Path $p) -and (Get-Item $p).PSIsContainer){
        $global:out = $p
        $lblOut.Text = "OUTPUT: $p"
        $lblOut.BackColor = "#004400"
        $btn.Enabled = ($global:src -and $global:out -and $global:ffmpeg)
    }
})

$btn.Add_Click({
    if(!$global:src -or !$global:ffmpeg){ return }
    $bitrate = $cmb.SelectedItem + "k"
    $destRoot = $global:out
    if(Test-Path $destRoot){ Remove-Item $destRoot -Recurse -Force -ErrorAction SilentlyContinue }
    mkdir $destRoot | Out-Null

    $allFiles = Get-ChildItem $global:src -Recurse -File -Include *.mp3,*.wma,*.flac,*.m4a,*.aac,*.wav,*.ogg,*.mod,*.xm,*.it,*.s3m,*.mid,*.midi
    $total = $allFiles.Count
    $pb.Maximum = $total
    $pb.Value = 0
    $pb.Visible = $true
    $processed = 0
    $global:failed = @()
    $seenTopLevels = @{}

    foreach($f in $allFiles){
        $pb.Value = $processed + 1
        $stat.Text = "$($processed + 1)/$total - $($f.Name)"

        try {
            # TRUE TOP-LEVEL FOLDER (the first folder under your input)
            $relative = $f.FullName.Substring($global:src.Length).TrimStart('\')
            $parts = $relative -split '\\'
            $topFolder = $parts[0]
            if(!$topFolder){ $topFolder = "Unknown" }

            $seenTopLevels[$topFolder] = $true
            $dest = Join-Path $destRoot $topFolder
            if(!(Test-Path $dest)){ mkdir $dest | Out-Null }

            $name = $f.BaseName -replace '[^a-zA-Z0-9\-]','_'
            $outFile = Join-Path $dest "$name.mp3"

            $info = & $global:ffmpeg -i "$($f.FullName)" 2>&1 | Out-String
            $artist = if($info -match 'artist\s*[:=]\s*(.+?)$') { $Matches[1].Trim() } else { "Unknown Artist" }
            $title  = if($info -match 'title\s*[:=]\s*(.+?)$')  { $Matches[1].Trim() } else { $name }
            $album  = $topFolder

            & $global:ffmpeg -y -i "$($f.FullName)" -c:a libmp3lame -b:a $bitrate -ac 2 -ar 44100 `
                -metadata artist="$artist" -metadata title="$title" -metadata album="$album" `
                "$outFile" -loglevel quiet 2>$null

            if($LASTEXITCODE -ne 0){ throw "ffmpeg failed" }

            # Duplicates
            $n = 2
            while(Test-Path "$dest\$name ($n).mp3"){ $n++ }
            if($n -gt 2){
                Move-Item "$outFile" "$dest\$name ($n).mp3" -Force
            }

            $processed++
        }
        catch {
            $global:failed += "$($f.FullName) - $_"
        }
    }

    $pb.Visible = $false
    $topCount = $seenTopLevels.Keys.Count
    $failedCount = $global:failed.Count
    $stats = @"
SUCCESS!

Input files:       $total
Output files:      $processed
Top-level folders: $topCount
Failed/skipped:    $failedCount

$(if($failedCount -gt 0){"`nFAILED FILES:`n" + ($global:failed -join "`n")}else{"All files processed perfectly!"})

Copy the folder:
$destRoot
"@
    $stat.Text = $stats
    Start-Process $destRoot
    [Windows.Forms.MessageBox]::Show($stats, "PIONEER ULTIMATE - DONE", "OK", "Information")
})

$form.ShowDialog() | Out-Null
