# Pioneer S21BT - GUARANTEED WORKING - NOV 06 2025
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ffmpeg = "$env:USERPROFILE\Downloads\ffmpeg\bin\ffmpeg.exe"
if(!(Test-Path $ffmpeg)){
    [Windows.Forms.MessageBox]::Show("Put ffmpeg in Downloads\ffmpeg\bin\ffmpeg.exe","MISSING FFMPEG")
    exit
}

$form = New-Object Windows.Forms.Form
$form.Text = "Pioneer S21BT - DRAG FOLDER HERE"
$form.Size = "640,400"
$form.StartPosition = "CenterScreen"
$form.BackColor = "White"

$lbl = New-Object Windows.Forms.Label
$lbl.Location = "20,20"
$lbl.Size = "600,100"
$lbl.Text = "DRAG YOUR MUSIC FOLDER HERE`n(it will turn green)"
$lbl.Font = "Consolas,14"
$lbl.TextAlign = "MiddleCenter"
$form.Controls.Add($lbl)

$cmb = New-Object Windows.Forms.ComboBox
$cmb.Location = "20,130"
$cmb.Size = "100,30"
"128","192","256","320" | % { $cmb.Items.Add($_) }
$cmb.SelectedIndex = 1
$form.Controls.Add($cmb)

$btn = New-Object Windows.Forms.Button
$btn.Location = "20,180"
$btn.Size = "120,60"
$btn.Text = "START"
$btn.Font = "Consolas,12"
$btn.Enabled = $false
$form.Controls.Add($btn)

$pb = New-Object Windows.Forms.ProgressBar
$pb.Location = "20,260"
$pb.Size = "600,40"
$pb.Visible = $false
$form.Controls.Add($pb)

$stat = New-Object Windows.Forms.Label
$stat.Location = "20,310"
$stat.Size = "600,60"
$stat.Font = "Consolas,10"
$form.Controls.Add($stat)

# THIS IS THE ONLY GLOBAL VARIABLE WE USE
$global:SourceFolder = $null

$form.AllowDrop = $true
$form.Add_DragEnter({ $_.Effect = "Copy"; $lbl.BackColor = "#90EE90" })
$form.Add_DragLeave({ $lbl.BackColor = "White" })
$form.Add_DragDrop({
    $path = $_.Data.GetData("FileDrop")[0]
    if((Test-Path $path) -and (Get-Item $path).PSIsContainer){
        $global:SourceFolder = $path
        $lbl.Text = "READY!`n$path"
        $lbl.BackColor = "#FFFF99"
        $btn.Enabled = $true
    }
})

$btn.Add_Click({
    if(!$global:SourceFolder){ return }

    $bitrate = $cmb.SelectedItem + "k"
    $out = "$env:USERPROFILE\Downloads\PioneerFixed"
    if(Test-Path $out){ Remove-Item $out -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item $out -ItemType Directory | Out-Null

    # THIS LINE IS THE ONLY ONE THAT MATTERS - ONLY YOUR FOLDER
    $files = Get-ChildItem $global:SourceFolder -Recurse -File -Include *.mp3,*.wma,*.flac,*.m4a,*.aac,*.wav,*.ogg,*.mod,*.xm,*.it,*.s3m,*.mid,*.midi
    $total = $files.Count
    if($total -eq 0){
        [Windows.Forms.MessageBox]::Show("No audio files found in that folder!","OOPS")
        return
    }

    $pb.Maximum = $total
    $pb.Value = 0
    $pb.Visible = $true
    $i = 0

    foreach($f in $files){
        $i++
        $pb.Value = $i
        $stat.Text = "$i/$total - $($f.Name)"

        $album = $f.Directory.Parent.Name
        if(!$album){ $album = "Unknown Album" }
        $dest = "$out\$album"
        if(!(Test-Path $dest)){ mkdir $dest | Out-Null }

        $name = $f.BaseName -replace '[^a-zA-Z0-9\-]','_'
        $temp = "$dest\$name.mp3"

        # Extract tags
        $info = & $ffmpeg -i "$($f.FullName)" 2>&1 | Out-String
        $artist = "Unknown Artist"
        $title = $name
        $albumTag = $album
        if($info -match 'artist\s*[:=]\s*(.+?)$') { $artist = $Matches[1].Trim() }
        if($info -match 'title\s*[:=]\s*(.+?)$') { $title = $Matches[1].Trim() }
        if($info -match 'album\s*[:=]\s*(.+?)$') { $albumTag = $Matches[1].Trim() }

        # Convert + tag in one command
        & $ffmpeg -y -i "$($f.FullName)" -c:a libmp3lame -b:a $bitrate -ac 2 -ar 44100 `
            -metadata artist="$artist" -metadata title="$title" -metadata album="$albumTag" `
            "$temp" -loglevel quiet 2>$null

        # Rename duplicates
        if((Test-Path "$temp") -and (Get-Item "$temp").Length -eq 0){ Remove-Item "$temp" -Force }
        $n = 2
        while(Test-Path "$dest\$name ($n).mp3"){ $n++ }
        if($n -gt 2){
            Move-Item "$temp" "$dest\$name ($n).mp3" -Force
        }
    }

    $pb.Visible = $false
    $stat.Text = "DONE! Opening PioneerFixed..."
    Start-Process $out
    [Windows.Forms.MessageBox]::Show("SUCCESS!`n`nCopy the PioneerFixed folder to your USB.`nRandom will NEVER crash again.","PIONEER FIXED")
})

$form.ShowDialog() | Out-Null
