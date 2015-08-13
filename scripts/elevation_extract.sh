#!/bin/bash
set -e

function usage() {
	echo "Usage: $0 min_x max_x min_y max_y [target_dir=elevation]"
	exit 1
}

#validate ranges
if [ -z "$4" ]; then
	usage
fi
min_x=$(python -c "import math; print int(math.floor($1))")
max_x=$(python -c "import math; print int(math.ceil($2) - 1)")
min_y=$(python -c "import math; print int(math.floor($3))")
max_y=$(python -c "import math; print int(math.ceil($4) - 1)")
if [ $min_x -gt $max_x ] || [ $min_x -lt -180 ] || [ $max_x -gt 180 ]; then
	usage
fi
if [ $min_y -gt $max_y ] || [ $min_y -lt -90 ] || [ $max_y -gt 90 ]; then
	usage
fi

if [ -z $5 ]; then
	dest=elevation
else
	dest="$5"
fi

#get the data
for x in $(seq ${min_x} 1 ${max_x}); do
        for y in $(seq ${min_y} 1 ${max_y}); do
		file=$(python -c "print '%s%02d%s%03d.hgt.gz' % ('S' if ${y} < 0 else 'N', abs(${y}), 'W' if ${x} < 0 else 'E', abs(${x}))")
                dir=$(echo ${file} | sed "s/^\([NS][0-9]\{2\}\).*/\1/g")
		echo "--retry 3 --retry-delay 0 --max-time 100 -s --create-dirs -o ${dest}/${dir}/${file} http://s3.amazonaws.com/mapzen.valhalla/elevation/${dir}/${file}"
	done
done | parallel -C ' ' -P $(nproc) "curl {}" 

#inflate it
find "${dest}" | grep -F .gz | xargs -P $(nproc) gunzip
