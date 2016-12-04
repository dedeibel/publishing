#!/usr/bin/env bash
set -e
set -x

BASEDIR=$(dirname $0)
INTERVAL=180

file="$1"
outdir="$2"


LENGTH=$(ffprobe -loglevel quiet -print_format default -show_format "$file" | grep duration= | sed -e 's/duration=\([[:digit:]]*\).*/\1/g')

TMPDIR=$(mktemp -d /tmp/thumb.XXXXXX)

if [ -z "$outdir" ]; then
  outgif=${file%.*}.gif
  outjpg=${file%.*}.jpg
  outjpg_preview=${file%.*}_preview.jpg
else
  outgif=${outdir}/$(basename ${file%.*}.gif)
  outjpg=${outdir}/$(basename ${file%.*}.jpg)
  outjpg_preview=${outdir}/$(basename ${file%.*}_preview.jpg)
fi


# now extract candidates and convert to non-anamorphic images
#
# we use equidistant sampling, but skip parts of the file that might contain pre-/postroles
# also, use higher resolution sampling at the beginning, as there's usually some interesting stuff there


#for POS in 20 30 40 $(seq 15 $INTERVAL $[ $LENGTH - 60 ])
for POS in 20
do
	ffmpeg -loglevel error -ss $POS -i "$file"  -an -r 1 -filter:v 'scale=sar*iw:ih' -vframes 1 -f image2 -vcodec png -y "$TMPDIR/$POS.png"
done

WINNER=$(python2 $BASEDIR/select.py $TMPDIR/*.png)

ffmpeg -loglevel error -i $WINNER -filter_complex:v 'scale=400:-1' -f image2 -vcodec mjpeg -q:v 0 -y $outjpg
ffmpeg -loglevel error -i $WINNER -filter_complex:v 'scale=400:-1' -f image2 -vcodec mjpeg -q:v 3 -y `basename $outjpg .jpg`_q3.jpg

convert -quiet $WINNER -strip -resize 400 -quality 100 `basename $outjpg .jpg`_im_100.jpg
convert -quiet $WINNER -strip -resize 400 -quality 95  `basename $outjpg .jpg`_im_095.jpg
convert -quiet $WINNER -strip -resize 400 -quality 92  `basename $outjpg .jpg`_im_092.jpg
convert -quiet $WINNER -strip -resize 400 -quality 90  `basename $outjpg .jpg`_im_090.jpg
convert -quiet $WINNER -strip -resize 400 -quality 85  `basename $outjpg .jpg`_im_085.jpg

gm convert $WINNER -strip -resize 400 -quality 100 `basename $outjpg .jpg`_gm_100.jpg
gm convert $WINNER -strip -resize 400 -quality 95  `basename $outjpg .jpg`_gm_095.jpg
gm convert $WINNER -strip -resize 400 -quality 92  `basename $outjpg .jpg`_gm_092.jpg
gm convert $WINNER -strip -resize 400 -quality 90  `basename $outjpg .jpg`_gm_090.jpg
gm convert $WINNER -strip -resize 400 -quality 85  `basename $outjpg .jpg`_gm_085.jpg

ffmpeg -loglevel error -i $WINNER                                  -f image2 -vcodec mjpeg -q:v 0 -y $outjpg_preview
convert -quiet $WINNER -strip `basename $outjpg_preview .jpg`_im.jpg

rm -rf $TMPDIR || true
