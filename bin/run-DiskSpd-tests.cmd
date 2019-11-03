diskspd.exe -d5 -c2000M -b1M -Sw -Su -t1 -w0 -s1b "io-perf.tmp" > seq-read-report.txt
diskspd.exe -d5 -c2000M -b1M -Sw -Su -t1 -w100 -s1b "io-perf.tmp" > seq-write-report.txt

diskspd.exe -d5 -c2000M -b16K -Sw -Su -t8 -w0 -r1b "io-perf.tmp" > random-read-report.txt
diskspd.exe -d5 -c2000M -b16K -Sw -Su -t8 -w100 -r1b "io-perf.tmp" > random-write-report.txt

del "io-perf.tmp"
