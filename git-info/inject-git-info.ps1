$branch = & { git rev-parse --abbrev-ref HEAD }
"Branch: [$branch]"

$commitsRaw = & { set TZ=GMT; git log -999999 --date=raw --pretty=format:"%cd" }
$lines = $commitsRaw.Split([Environment]::NewLine)
$commitCount = $lines.Length
$commitDate = $lines[0].Split(" ")[0]
"Commit Counter: [$commitCount]"
"Commit Date: [$commitDate]"

"[assembly: AssemblyGitInfo(`"$branch`", $commitCount, $($commitDate)L)]" > AssemblyGitInfo.cs
