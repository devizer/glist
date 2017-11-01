$files=$("Essentials.7z.exe")
$baseUrl="https://raw.githubusercontent.com/devizer/glist/master/Essentials/"
$Temp="$($Env:LocalAppData)"
$Essentials="$Temp\Temp\Essentials"
Write-Host "Essentials folder: $Essentials"
New-Item $Essentials -type directory -force -EA SilentlyContinue | out-null
[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true};
foreach($file in $files) {
 $d=new-object System.Net.WebClient; $d.DownloadFile("$baseurl/$file","$Essentials\$file");
}
pushd $Essentials
cmd /c Essentials.7z.exe -y
ri Essentials.7z.exe
popd
# Done: Essentials
