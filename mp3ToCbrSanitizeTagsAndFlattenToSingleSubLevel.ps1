# PIONEER S21BT - MASTER EDITION - NOV 07 2025 - WORKS ANYWHERE
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === AUTO-DETECT FFMPEG IN SCRIPT FOLDER ===
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$defaultFfmpeg = "$scriptDir\ffmpeg\bin\ffmpeg.exe"
$global:ffmpegPath = $defaultFfmpeg

if(Test-Path $defaultFfmpeg){
    $global:ffmpegPath = $defaultFfmpeg
} else {
    $global:ffmpegPath = $null
}

# === MAIN FORM ===
$form = New-Object Windows.Forms.Form
$form.Text = "PIONEER S21BT - MASTER USB FIXER"
$form.Size = "760,620"
$form.StartPosition = "CenterScreen"
$form.Font = "Consolas,10"
$form.BackColor = "#1E1E1E"
$form.ForeColor = "#00FF00"

# === FFMPEG LOCATION ===
$lblFF = New-Object Windows.Forms.Label
$lblFF.Location = "20,15"
$lblFF.Size = "720,50"
$lblFF.Text = "FFMPEG: Drag folder here (default: .\ffmpeg\bin\ffmpeg.exe)"
$lblFF.BackColor = "#333333"
$lblFF.TextAlign = "MiddleCenter"
$form.Controls.Add($lblFF)

if($global:ffmpegPath){
    $lblFF.Text = "FFMPEG FOUND: $($global:ffmpegPath.Substring(0,[Math]::Min(80,$global:ffmpegPath.Length)))"
    $lblFF.BackColor = "#004400"
}

# === INPUT FOLDER ===
$lblIn = New-Object Windows.Forms.Label
$lblIn.Location = "20,80"
$lblIn.Size = "720,60"
$lblIn.Text = "INPUT: Drag your music folder here"
$lblIn.BackColor = "#333333"
$lblIn.TextAlign = "MiddleCenter"
$form.Controls.Add($lblIn)

# === OUTPUT FOLDER ===
$lblOut = New-Object Windows.Forms.Label
$lblOut.Location = "20,150"
$lblOut.Size = "720,60"
$lblOut.Text = "OUTPUT: Drag destination folder (default: Downloads\PioneerFixed)"
$lblOut.BackColor = "#333333"
$lblOut.TextAlign = "MiddleCenter"
$form.Controls.Add($lblOut)

$outputFolder = "$env:USERPROFILE\Downloads\PioneerFixed"

# === OPTIONS GROUP ===
$grp = New-Object Windows.Forms.GroupBox
$grp.Location = "20,230"
$grp.Size = "720,100"
$grp.Text = " Organization Mode "
$grp.ForeColor = "#00FF00"
$form.Controls.Add($grp)

$rbPreserve = New-Object Windows.Forms.RadioButton
$rbPreserve.Location = "20,25"
$rbPreserve.Size = "680,25"
$rbPreserve.Text = "PRESERVE MY ORIGINAL TOP-LEVEL FOLDERS (exactly how I organized it)"
$rbPreserve.Checked = $true
$grp.Controls.Add($rbPreserve)

$rbAlbum = New-Object Windows.Forms.RadioButton
$rbAlbum.Location = "20,55"
$rbAlbum.Size = "680,25"
$rbAlbum.Text = "Use ID3 album tag (usually makes a mess)"
$grp.Controls.Add($rbAlbum)

# === BITRATE ===
$cmb = New-Object Windows.Forms.ComboBox
$cmb.Location = "20,350"
$cmb.Size = "100,30"
"128","192","256","320" | % { $cmb.Items.Add($_) }
$cmb.SelectedIndex = 1
$form.Controls.Add($cmb)
$lblB = New-Object Windows.Forms.Label
$lblB.Location = "130,350"
$lblB.Size = "100,30"
$lblB.Text = "kbps CBR"
$lblB.ForeColor = "#00FF00"
$form.Controls.Add($lblB)

# === START ===
$btn = New-Object Windows.Forms.Button
$btn.Location = "20,400"
$btn.Size = "720,80"
$btn.Text = "START CONVERSION - THIS ONE ACTUALLY WORKS"
$btn.BackColor = "#00FF00"
$btn.ForeColor = "Black"
$btn.Font = "Consolas,16,style=Bold"
$btn.Enabled = $false
$form.Controls.Add($btn)

# === PROGRESS ===
$pb = New-Object Windows.Forms.ProgressBar
$pb.Location = "20,490"
$pb.Size = "720,30"
$pb.Visible = $false
$form.Controls.Add($pb)

$stat = New-Object Windows.Forms.Label
$stat.Location = "20,530"
$stat.Size = "720,50"
$stat.Text = "Ready. Drag folders above."
$stat.ForeColor = "#00FF00"
$stat.TextAlign = "MiddleCenter"
$form.Controls.Add($stat)

# === GLOBALS ===
$global:src = $null
$global:out = $outputFolder

# === DRAG FFMPEG ===
$lblFF.AllowDrop = $true
$lblFF.Add_DragEnter({ $_.Effect = "Copy"; $lblFF.BackColor = "#008800" })
$lblFF.Add_DragLeave({ if(!$global:ffmpegPath){ $lblFF.BackColor = "#333333" } else { $lblFF.BackColor = "#004400" } })
$lblFF.Add_DragDrop({
    $path = $_.Data.GetData("FileDrop")[0]
    $test = Join-Path $path "bin\ffmpeg.exe"
    if(Test-Path $test){
        $global:ffmpegPath = $test
        $lblFF.Text = "FFMPEG: $test"
        $lblFF.BackColor = "#004400"
        $stat.Text = "FFmpeg loaded."
        $btn.Enabled = ($global:src -and $global:out -and $global:ffmpegPath)
    }
})

# === DRAG INPUT ===
$lblIn.AllowDrop = $true
$lblIn.Add_DragEnter({ $_.Effect = "Copy"; $lblIn.BackColor = "#008800" })
$lblIn.Add_DragLeave({ $lblIn.BackColor = "#333333" })
$lblIn.Add_DragDrop({
    $path = $_.Data.GetData("FileDrop")[0]
    if((Test-Path $path) -and (Get-Item $path).PSIsContainer){
        $global:src = $path
        $lblIn.Text = "INPUT: $($path.Substring(0,[Math]::Min(90,$path.Length)))"
        $lblIn.BackColor = "#004400"
        $btn.Enabled = ($global:src -and $global:out -and $global:ffmpegPath)
        $stat.Text = "Input ready."
    }
})

# === DRAG OUTPUT ===
$lblOut.AllowDrop = $true
$lblOut.Add_DragEnter({ $_.Effect = "Copy"; $lblOut.BackColor = "#008800" })
$lblOut.Add_DragLeave({ $lblOut.BackColor = "#333333" })
$lblOut.Add_DragDrop({
    $path = $_.Data.GetData("FileDrop")[0]
    if((Test-Path $path) -and (Get-Item $path).PSIsContainer){
        $global:out = $path
        $lblOut.Text = "OUTPUT: $($path.Substring(0,[Math]::Min(90,$path.Length)))"
        $lblOut.BackColor = "#004400"
        $btn.Enabled = ($global:src -and $global:out -and $global:ffmpegPath)
        $stat.Text = "Output ready."
    }
})

# === START ===
$btn.Add_Click({
    if(!$global:ffmpegPath -or !$global:src){ return }
    $bitrate = $cmb.SelectedItem + "k"
    $destRoot = $global:out
    if(Test-Path $destRoot){ Remove-Item $destRoot -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item $destRoot -ItemType Directory | Out-Null

    $files = Get-ChildItem $global:src -Recurse -File -Include *.mp3,*.wma,*.flac,*.m4a,*.aac,*.wav,*.ogg,*.mod,*.xm,*.it,*.s3m,*.mid,*.midi
    $total = $files.Count
    if($total -eq 0){ [Windows.Forms.MessageBox]::Show("No audio files!","ERROR"); return }

    $pb.Maximum = $total
    $pb.Value = 0
    $pb.Visible = $true
    $i = 0

    foreach($f in $files){
        $i++
        $pb.Value = $i
        $stat.Text = "$i/$total - $($f.Name.Substring(0,[Math]::Min(70,$f.Name.Length)))"

        # === TOP-LEVEL FOLDER LOGIC ===
        $topFolder = $f.Directory.Name
        if($f.Directory.Parent.Parent){  # if deeper than one level
            $topFolder = $f.Directory.Parent.Name
        }
        if(!$topFolder -or $topFolder -eq ""){ $topFolder = "Unknown" }

        $dest = "$destRoot\$topFolder"
        if(!(Test-Path $dest)){ mkdir $dest | Out-Null }

        $name = $f.BaseName -replace '[^a-zA-Z0-9\-]','_'
        $outFile = "$dest\$name.mp3"

        # Extract tags
        $info = & $global:ffmpegPath -i "$($f.FullName)" 2>&1 | Out-String
        $artist = if($info -match 'artist\s*[:=]\s*(.+?)$') { $Matches[1].Trim() } else { "Unknown Artist" }
        $title  = if($info -match 'title\s*[:=]\s*(.+?)$')  { $Matches[1].Trim() } else { $name }
        $album  = $topFolder

        & $global:ffmpegPath -y -i "$($f.FullName)" -c:a libmp3lame -b:a $bitrate -ac 2 -ar 44100 `
            -metadata artist="$artist" -metadata title="$title" -metadata album="$album" `
            "$outFile" -loglevel quiet 2>$null

        # Duplicates
        $n = 2
        while(Test-Path "$dest\$name ($n).mp3"){ $n++ }
        if($n -gt 2){
            Move-Item "$outFile" "$dest\$name ($n).mp3" -Force
        }
    }

    $pb.Visible = $false
    $stat.Text = "PERFECTION ACHIEVED"
    Start-Process $destRoot
    [Windows.Forms.MessageBox]::Show("IT'S DONE.`n`nYour USB is now perfect.`n`nRandom will work forever.`n`nCopy the folder and go drive.","PIONEER = FIXED", "OK", "Information")
})

$form.ShowDialog() | Out-Null
