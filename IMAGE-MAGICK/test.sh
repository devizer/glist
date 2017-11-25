apt-get update && apt-get install imagemagick wget htop lsof procps mc nano sudo -y

export TERM=xterm
work=~/tmp-images && cd ~/tmp-images
for f in 1 2 3 4 5 6 7 8 9; do
  wget -O src$f.jpg https://picsum.photos/1920/1080/?image=$f
  identify src$f.jpg > src$f.jpg.info1
  identify -verbose src$f.jpg > src$f.jpg.info2
  identify -format "%m %A %[depth] %[fx:w] %[fx:h] %[resolution.x] %[resolution.y] %[resolution.hernia] " src$f.jpg > src$f.jpg.info3
done
