apt-get update && apt-get install imagemagick wget htop lsof procps mc nano sudo -y

export TERM=xterm
work=~/tmp-images && cd ~/tmp-images
mkdir -p images
for f in 1 2 3 4 5 6 7 8 9; do
  wget --no-check-certificate -O images/src$f.jpg https://picsum.photos/1920/1080/?image=$f
done

for f in bmp32.bmp tiff32.tif png24.png png32.png gif2.gif png8.png gif.gif; do
  wget --no-check-certificate -O images/$f https://raw.githubusercontent.com/devizer/glist/master/IMAGE-MAGICK/images/$f
done



for f in images/*; do
  echo image $f
  identify $f > $(basename $f).info1
  identify -verbose $f > $(basename $f).info2
  identify -format "%m | %A | %[depth] | %[fx:w] | %[fx:h] | %[resolution.x] | %[resolution.y] " $f > $(basename $f).info3
done

