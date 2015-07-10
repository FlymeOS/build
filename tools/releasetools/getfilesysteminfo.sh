#!/system/bin/sh

FILE_INFO=/data/local/tmp/file.info

function traverse_dir {
	local root=$1
	# Using "-Z" to get the selable
	ls -a -Z ${root} | while read line
	do
		name=${line##* }
		if [ "${line:0:1}" = "d" ]; then # directory
			traverse_dir ${root}/${name}
		fi

	echo "$line ${root:1}" >> ${FILE_INFO}
	done
}

echo "Traversing /system to retrieve filesystem_info ..."
traverse_dir "/system"
echo "Traversing /system to retrieve filesystem_info done"
