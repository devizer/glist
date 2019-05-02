$info = @{};
  try { $info.Platform = ((bash -c -e ". /etc/os-release; echo `$ID") | out-string 2>$null).Trim(@([char] 13, [char] 10, [char]32)) }
  catch { $__="/etc/os-release is not defined"; }
$info


 