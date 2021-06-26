(Get-LocalGroup | where { $_.sid -eq 'S-1-5-32-545' })[0].Name

$_ = (Get-LocalGroup | where { $_.sid -eq 'S-1-5-32-545' }); if ($_.Length -gt 0) { $groupName = $_[0].Name } else { $groupName = $null }
Write-Host $groupName

