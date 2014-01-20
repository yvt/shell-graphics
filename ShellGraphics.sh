#!/bin/sh
#
#     ShellGraphics 0.0.2
#
#  Library to draw graphics only with a shell.
#
#  USAGE EXAMPLE: 
#
#   $ . ShellGraphics.sh
#   $ SHDemo1 demo1.bmp
#   $ SHDemo2 demo2.bmp
#
#  (c) 2012 YaViT (T.Kawada)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


export SGBitmapClassName=SGBitmapClass
export SGEmptyRect="0 0 0 0"

function SGMin {
if [ "$1" == "" ]; then
echo "USAGE: SGMin VALUE1 [VALUES...]"
return 1
fi
local best=$1
shift
while [ "$1" != "" ]; do
last=$1
if (( $last < $best )); then
best=$last
fi
shift
done
echo -n $best
}

function SGMax {
if [ "$1" == "" ]; then
echo "USAGE: SGMax VALUE1 [VALUES...]"
return 1
fi
local best=$1
shift
while [ "$1" != "" ]; do
last=$1
if (( $last > $best )); then
best=$last
fi
shift
done
echo -n $best
}

# Check whether the given rect is empty.
function SGIsEmptyRect {
if [ "$4" == "" ]; then
echo "USAGE: SGIsEmptyRect X Y W H"
return 1
fi
local w=$3
local h=$4
if (( $w <= 0 || $h <= 0 )); then
return 0
else
return 1
fi
}

# Clip rect to fit in the given dimension.
#
# USAGE: OUTRECT=($(SGClipRect WIDTH HEIGHT X Y W H))
function SGClipRect {
if [ "$6" == "" ]; then
echo "USAGE: SGClipRect WIDTH HEIGHT X Y W H"
return 1
fi
local width=$1
local height=$2
local x=$3
local y=$4
local w=$5
local h=$6
if (( $x < 0 )); then
w=$(($w+$x))
x=0
fi
if (( $y < 0 )); then
h=$(($h+$y))
y=0
fi
if (( $x + $w > $width )); then
w=$(($width-$x))
fi
if (( $y + $h > $height )); then
h=$(($height-$y))
fi

# is empty?
if (( $w <= 0 || $h <= 0 )); then
echo $SGEmptyRect
return
fi
echo $x $y $w $h
}


# Checks if the given variable name is a bitmap.
#
# USAGE: SGIsBitmap NAME && echo YES
function SGIsBitmap {
if [ "$1" == "" ]; then
echo "USAGE: SGIsBitmap NAME"
return 1
fi
local name="$1"
if [ "$(eval echo \$${name})" == "$SGBitmapClassName" ]; then
return 0
else
return 1
fi
}


# Get the width of the given bitmap.
# It is assumed that the given bitmap exists.
#
# USAGE: WIDTH=$(SGWidthForBitmap NAME)
function SGWidthForBitmap {
if [ "$1" == "" ]; then
echo "USAGE: SGWidthForBitmap NAME"
return 1
fi
local width="$(eval echo \$${name}_width)"
echo $width
}


# Get the height of the given bitmap.
# It is assumed that the given bitmap exists.
#
# USAGE: HEIGHT=$(SGHeightForBitmap NAME)
function SGHeightForBitmap {
if [ "$1" == "" ]; then
echo "USAGE: SGHeightForBitmap NAME"
return 1
fi
local height="$(eval echo \$${name}_height)"
echo $height
}


# Get the dimensions of the given bitmap.
# It is assumed that the given bitmap exists.
#
# USAGE: DIMENSIONS=($(SGDimensionsForBitmap NAME))
function SGDimensionsForBitmap {
if [ "$1" == "" ]; then
echo "USAGE: SGDimensionsForBitmap NAME"
return 1
fi
local width="$(eval echo \$${name}_width)"
local height="$(eval echo \$${name}_height)"
echo $width $height
}


# Frees the bitmap with the specified name.
# No-op when the bitmap doesn't exist.
#
# USAGE: SGFreeBitmap NAME
function SGFreeBitmap {
if [ "$1" == "" ]; then
echo "USAGE: SGFreeBitmap NAME"
return 1
fi
local name="$1"
if SGIsBitmap $name; then
local height=$(SGHeightForBitmap $name)
local y
for y in $(seq 0 $((${height}-1))); do
unset ${name}_${y}
done
unset ${name}
unset ${name}_width
unset ${name}_height
fi
}


# Builds a new bitmap.
#
# USAGE: SGBuildBitmap NAME WIDTH HEIGHT
function SGBuildBitmap {
if [ "$3" == "" ]; then
echo "USAGE: SGBuildBitmap NAME WIDTH HEIGHT"
return 1
fi
local name="$1"
local width="$2"
local height="$3"

# remove old bitmap.
SGFreeBitmap $name

# make row
local row="0 0 0"
local x
for x in $(seq 1 $(($width-1))); do
row+=" 0 0 0"
done

eval "${name}=${SGBitmapClassName};"
eval "${name}_width=$width;"
eval "${name}_height=$height;"
local y
for y in $(seq 0 $(($height-1))); do
eval "${name}_${y}=(${row})"
done
}


# Outputs a byte to stdout.
#
# USAGE: SGWriteByte DECIMAL_BYTE
function SGWriteByte {
# assume $1 >=0 && $1 <= 255
printf "\\x$(printf "%x" $1)" 
}


# Outputs an 16-bit unsigned integer 
# in the little-endian.
#
# USAGE: SGWriteUInt16 DECIMAL_UINT
function SGWriteUInt16 {
SGWriteByte $(($1%256))
SGWriteByte $(($1/256))
}


# Outputs an 32-bit unsigned integer 
# in the little-endian.
#
# USAGE: SGWriteUInt32 DECIMAL_UINT
function SGWriteUInt32 {
SGWriteByte $(($1%256))
SGWriteByte $((($1/256)%256))
SGWriteByte $((($1/65536)%256))
SGWriteByte $(($1/16777216))
}


# Draws an point.
# No op is the coord is out of the range.
#
# USAGE: SGPutPixel NAME X Y R G B
function SGPutPixel {
if [ "$6" == "" ]; then
echo "USAGE: SGPutPixel NAME X Y R G B"
return 1
fi
local name="$1"
local xCoord="$2"
local yCoord="$3"
local red="$4"
local green="$5"
local blue="$6"
local width="$(eval echo \$${name}_width)"
local height="$(eval echo \$${name}_height)"
if (( $xCoord < 0 || $xCoord >= $width || 
$yCoord < 0 || $yCoord >= $height )); then
return
fi
eval "${name}_${yCoord}[$((${xCoord}*3))]=$red;"
eval "${name}_${yCoord}[$((${xCoord}*3+1))]=$green;"
eval "${name}_${yCoord}[$((${xCoord}*3+2))]=$blue;"
}


# Draws an point.
# Specifing the coord that is out of the range results in
# an unexpected behavior.
#
# USAGE: SGSetPixel NAME X Y R G B
function SGSetPixel {
if [ "$6" == "" ]; then
echo "USAGE: SGSetPixel NAME X Y R G B"
return 1
fi
local name="$1"
local xCoord="$2"
local yCoord="$3"
local red="$4"
local green="$5"
local blue="$6"
local width="$(eval echo \$${name}_width)"
local height="$(eval echo \$${name}_height)"
eval "${name}_${yCoord}[$((${xCoord}*3))]=$red;"
eval "${name}_${yCoord}[$((${xCoord}*3+1))]=$green;"
eval "${name}_${yCoord}[$((${xCoord}*3+2))]=$blue;"
}


# Gets the color at the point.
#
# USAGE: RET=($(SGGetPixel NAME X Y))
function SGGetPixel {
if [ "$3" == "" ]; then
echo "USAGE: SGGetPixel NAME X Y"
return 1
fi
local name="$1"
local xCoord="$2"
local yCoord="$3"
eval "echo -n \"\${${name}_${yCoord}[$((${xCoord}*3))]} \""
eval "echo -n \"\${${name}_${yCoord}[$((${xCoord}*3+1))]} \""
eval "echo -n \"\${${name}_${yCoord}[$((${xCoord}*3+2))]}\""
}


# Gets the BMP format respresentation for the bitmap.
#
# USAGE: SGBmpRepresentation NAME [OPTIONS...] > OUTPUT.bmp
# OPTIONS:
#  -v
#      Be verbose. Outputs some logs to /dev/stderr.
function SGBmpRepresentation {
local name
local isVerbose=NO

# read options.
while [ "$1" != "" ]; do
if [ "$1" == "-v" ]; then
isVerbose=YES
else
name="$1"
fi
shift
done

if [ "$name" == "" ]; then
echo "error: no name specified." > /dev/stderr
echo "USAGE: SGBmpRepresentation NAME [OPTIONS...] > OUT.bmp"
return 1
fi

if SGIsBitmap $name; then
echo -n ""
else
echo "error: not bitmap." > /dev/stderr
return 1
fi

local width=$(SGWidthForBitmap $name)
local height=$(SGHeightForBitmap $name)

# write BITMAPFILEHEADER.

if [ "$isVerbose" == "YES" ]; then
echo "writing BITMAPFILEHEADER..." > /dev/stderr
fi

echo -n "BM" # bfType

local fileSize=$((54+$width*$height*4))
SGWriteUInt32 $fileSize # bfSize

if [ "$isVerbose" == "YES" ]; then
echo "estimated file size: $fileSize" > /dev/stderr
fi

SGWriteUInt16 0 # bfReserved1
SGWriteUInt16 0 # bfReserved2

SGWriteUInt32 54 # bfOffBits


# write BITMAPINFOHEADER.

if [ "$isVerbose" == "YES" ]; then
echo "writing BITMAPINFOHEADER..." > /dev/stderr
fi

SGWriteUInt32 40 # biSize
SGWriteUInt32 $width # biWidth
SGWriteUInt32 $height # biHeight
SGWriteUInt16 1 # biPlanes
SGWriteUInt16 32 # biBitCount
SGWriteUInt32 0 # biCompression
SGWriteUInt32 $(($width*$height*4)) # biSizeImage
SGWriteUInt32 3780 # biXPixPerMeter
SGWriteUInt32 3780 # biYPixPerMeter
SGWriteUInt32 0 # biClrUsed
SGWriteUInt32 0 # biClrImportant

if [ "$isVerbose" == "YES" ]; then
echo "dimension: ${width}x${height}" > /dev/stderr
fi

# write bitmap.

if [ "$isVerbose" == "YES" ]; then
echo "writing bitmap..." > /dev/stderr
fi

local x
local y
local channels
for y in $(seq $(($height-1)) 0); do
for x in $(seq 0 $(($width-1))); do
channels=($(SGGetPixel $name $x $y))
SGWriteByte ${channels[2]}
SGWriteByte ${channels[1]}
SGWriteByte ${channels[0]}
SGWriteByte 255 # not used 
done

if [ "$isVerbose" == "YES" ]; then
echo -n "." > /dev/stderr
fi

done

if [ "$isVerbose" == "YES" ]; then
echo "" > /dev/stderr
echo "done." > /dev/stderr
fi

}


# Fills the bitmap with a color.
#
# USAGE: SGFill NAME R G B
function SGFill {
if [ "$4" == "" ]; then
echo "USAGE: SGFill NAME R G B"
return 1
fi
local name="$1"
local red="$2"
local green="$3"
local blue="$4"
local width=$(SGWidthForBitmap $name)
local height=$(SGHeightForBitmap $name)
local x
local y
for x in $(seq 0 $(($width-1))); do
for y in $(seq 0 $(($height-1))); do
SGSetPixel $name $x $y $red $green $blue
done
done
}

# Fills the rect with a color.
#
# USAGE: SGFillRect NAME X Y W H R G B
function SGFillRect {
if [ "$8" == "" ]; then
echo "USAGE: SGFillRect NAME X Y W H R G B"
return 1
fi
local name="$1"
local width=$(SGWidthForBitmap $name)
local height=$(SGHeightForBitmap $name)
local rect=($(SGClipRect $width $height $2 $3 $4 $5))
local red="$6"
local green="$7"
local blue="$8"
local x
local y

if SGIsEmptyRect ${rect[@]}; then
return
fi

for x in $(seq ${rect[0]} $((${rect[0]}+${rect[2]}-1))); do
for y in $(seq ${rect[1]} $((${rect[1]}+${rect[3]}-1))); do
SGSetPixel $name $x $y $red $green $blue
done
done
}

# Fills the scanline with a color.
#
# USAGE: SGFillScanline NAME Y X1 X2 R G B
function SGFillScanline {
if [ "$7" == "" ]; then
echo "USAGE: SGFillScanline NAME Y X1 X2 R G B"
return 1
fi
local name="$1"
local width=$(SGWidthForBitmap $name)
local height=$(SGHeightForBitmap $name)
local xx1="$3"
local xx2="$4"
local red="$5"
local green="$6"
local blue="$7"
local x
local y="$2"
if (( $xx1 < $xx2 )); then
local x1=$xx1
local x2=$xx2
else
local x1=$xx2
local x2=$xx1
fi


if (( $x1 < 0 )); then
x1=0
fi
if (( $x2 > $width )); then
x2=$width
fi
if (( $x2 <= $x1 )); then
return
fi

for x in $(seq $x1 $(($x2-1))); do
SGSetPixel $name $x $y $red $green $blue
done
}

# Fills the triangle with a color.
#
# USAGE: SGFillTriangle NAME X1 Y1 X2 Y2 X3 Y3 R G B
function SGFillTriangle {
local name="$1"
local width=$(SGWidthForBitmap $name)
local height=$(SGHeightForBitmap $name)
local px1="$2"
local py1="$3"
local px2="$4"
local py2="$5"
local px3="$6"
local py3="$7"

local red="$8"
local green="$9"
shift
local blue="$9"
if [ "$9" == "" ]; then
echo "USAGE: SGFillTriangle NAME X1 Y1 X2 Y2 X3 Y3 R G B"
return 1
fi

local x
local y
local x1
local y1
local x2
local y2
local x3
local y3

# sort vertices by y-coordinate.

if (( $py2 < $py1 )); then
x1=$px2; y1=$py2
x2=$px1; y2=$py1
else
x1=$px1; y1=$py1
x2=$px2; y2=$py2
fi

if (( $py3 < $y1 )); then
x3=$x2; y3=$y2
x2=$x1; y2=$y1
x1=$px3; y1=$py3
elif (( $py3 < $y2 )); then
x3=$x2; y3=$y2
x2=$px3; y2=$py3
else
x3=$px3; y3=$py3
fi

# render top-half.
local yMin=$y1
local yMed=$y2

if (( $yMin < 0 )); then
yMin=0
fi
if (( $yMed > $height )); then
yMed=$height
fi

if (( $yMin < $yMed )); then
for y in $(seq $yMin $(($yMed-1))); do

local xx1=$(($x1+($x3-$x1)*($y-$y1)/($y3-$y1)))
local xx2=$(($x1+($x2-$x1)*($y-$y1)/($y2-$y1)))

SGFillScanline $name $y $xx1 $xx2 $red $green $blue

done
fi

# render bottom-half.
local yMed=$y2
local yMax=$y3

if (( $yMed < 0 )); then
yMed=0
fi
if (( $yMax > $height )); then
yMax=$height
fi

if (( $yMed < $yMax )); then
for y in $(seq $yMed $(($yMax-1))); do

local xx1=$(($x1+($x3-$x1)*($y-$y1)/($y3-$y1)))
local xx2=$(($x2+($x3-$x2)*($y-$y2)/($y3-$y2)))

SGFillScanline $name $y $xx1 $xx2 $red $green $blue

done
fi

}

# Demonstrates the feature of ShellGraphics.
#
# USAGE: SGDemo1 OUTPUT.bmp
function SGDemo1 {
if [ "$1" == "" ]; then
echo "SGDemo1 OUTPUT.bmp"
return 1
fi

echo "createing 128x128 bitmap..."
SGBuildBitmap DemoBmp 128 128
echo "rendering..."
for x in $(seq 0 127); do
for y in $(seq 0 127); do
SGSetPixel DemoBmp $x $y $((($x^$y)%256)) $(((($x+56)^$y)%256)) $(((($x+23)^($y+34))%256))
done
echo -n "."
done
echo

SGBmpRepresentation -v DemoBmp > "$1"

echo "cleaning up..."
SGFreeBitmap DemoBmp
echo "done!"
}

# Demonstrates the feature of ShellGraphics.
#
# USAGE: SGDemo2 OUTPUT.bmp
function SGDemo2 {
if [ "$1" == "" ]; then
echo "SGDemo2 OUTPUT.bmp"
return 1
fi

echo "createing 128x160 bitmap..."
SGBuildBitmap DemoBmp 128 160
echo "rendering..."

echo -n "."
SGFillTriangle DemoBmp 64 16 112 48 64 80 192 192 192
echo -n "."
SGFillTriangle DemoBmp 64 16 16 48 64 80 192 192 192
echo -n "."
SGFillTriangle DemoBmp 112 112 112 48 64 144 128 128 128
echo -n "."
SGFillTriangle DemoBmp 64 144 112 48 64 80 128 128 128
echo -n "."
SGFillTriangle DemoBmp 16 112 16 48 64 144 64 64 64
echo -n "."
SGFillTriangle DemoBmp 64 144 16 48 64 80 64 64 64
echo -n "."


echo

SGBmpRepresentation -v DemoBmp > "$1"

echo "cleaning up..."
SGFreeBitmap DemoBmp
echo "done!"
}





