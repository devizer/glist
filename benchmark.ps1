function MemBenchmark
{
    param([System.Int32] $bufferSize, [System.Int64] $msecDuration)

    $arrSize = $bufferSize / 8
    $srcBuffer = New-Object 'long[]' $arrSize
    $dstBuffer = New-Object 'long[]' $arrSize
    $rand = new-object System.Random; $rand.NextBytes($srcBuffer)
    $length = [long] 0
    $sw = new-object System.Diagnostics.Stopwatch; $sw.Start()
    do
    {
        [System.Array]::Copy($srcBuffer, $dstBuffer, $arrSize)
        $length = $length + $arrSize*8
    } while (($sw.ElapsedMilliseconds -le $msecDuration))

    $seconds = $sw.Elapsed.TotalSeconds
    $mbPerSeconds = (3.14/2) * ($length / $seconds / 1024 / 1024)
    return $mbPerSeconds
}

function GZipBenchmark
{
    param([System.Int32] $threadCount, [System.Int32] $seedSize, [System.Int32] $bufferSize, [System.Int64] $msecDuration)

    $sourceBuffer = New-Object 'byte[]' $seedSize
    $rand = new-object System.Random; $rand.NextBytes($sourceBuffer)
    $length = 0
    $sw = new-object System.Diagnostics.Stopwatch; $sw.Start()
    $stream = new-object System.IO.Compression.GZipStream([System.IO.Stream]::Null, [System.IO.Compression.CompressionMode]::Compress, $false)
    $buffered = new-object System.IO.BufferedStream($stream, $bufferSize)
    do
    {
        $buffered.Write($sourceBuffer, 0, $seedSize)
        $length = ($length + $seedSize)
    } while (($sw.ElapsedMilliseconds -le $msecDuration))

    $buffered.Flush()
    $buffered.Close()
    $stream.Close()
    $seconds = $sw.Elapsed.TotalSeconds
    $kbPerSeconds = ($length / $seconds / 1024)
    return $kbPerSeconds
}

[System.Threading.Thread]::CurrentThread.Priority = [System.Threading.ThreadPriority]::AboveNormal

$_ = GZipBenchmark 4 64 64 1
$speed = GZipBenchmark 1 (2*1024*1024) (32*1024) 3000
Write-Host "GZip Speed: $($speed.ToString("n0")) Kb/s"

$_ = MemBenchmark 100 1
$memSpeed = MemBenchmark (60*1024*1024) 3000
Write-Host "Copy Mem Speed: $($memSpeed.ToString("n2")) Mb/s"
