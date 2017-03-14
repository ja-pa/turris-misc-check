#!/bin/bash

BASE_DIR=pkg_base
TMP_DIR=tmp
#CHECK_ONLY_NAMES=false
CHECK_ONLY_NAMES=true
DEBUG_DIFF=false

get_packages() {
	feed_name=$1
	repo=$2
	prefix=$3
	postfix=$4
	curl -s http://repo.turris.cz/$repo/packages/$feed_name/|awk -F'>' '{print $6}'|awk -F'"' '{print $2}'|grep ipk|sort>$prefix$feed_name$postfix.txt
}

print_added_packages() {
	file_a=$1
	file_b=$2
	if [ "$CHECK_ONLY_NAMES" == "true" ]; then
		cat $file_a |awk -F'_' '{ print $1 }' >$file_a.tmp
		cat $file_b |awk -F'_' '{ print $1 }' >$file_b.tmp

		comm -13 $file_a.tmp $file_b.tmp 2>/dev/null| sed "s/^/	+ /"
		rm $file_a.tmp
		rm $file_b.tmp
	else
		comm -13 $file_a $file_b 2>/dev/null| sed "s/^/	+ /"
	fi
}

print_removed_packages() {
	file_a="$1"
	file_b="$2"

	if [ "$CHECK_ONLY_NAMES" == "true" ]; then
		cat $file_a |awk -F'_' '{ print $1 }' >$file_a.tmp
		cat $file_b |awk -F'_' '{ print $1 }' >$file_b.tmp

		comm -23 $file_a.tmp $file_b.tmp 2>/dev/null | sed "s/^/ + /"
		rm $file_a.tmp
		rm $file_b.tmp
	else
		comm -23 $file_a $file_b 2>/dev/null | sed "s/^/ + /"
	fi
}

create_base() {
	[ ! -d $BASE_DIR ] && mkdir $BASE_DIR

	for repo_name in omnia-stable omnia-rc omnia-nightly
	do
		for feed in base lucics management openwisp packages printing routing telephony turrispackages
		do
			if [ ! -f "$BASE_DIR/$feed.txt" ]; then
				get_packages $feed $repo_name $BASE_DIR/ _$repo_name
			fi
		done
	done
}

compare_to_base() {

	if [ "$DEBUG_DIFF" == "false" ]; then
		rm -rf $TMP_DIR
		mkdir $TMP_DIR
	fi

	for repo_name in omnia-stable omnia-rc omnia-nightly
	do
		feed_out=""
		for feed in base lucics management openwisp packages printing routing telephony turrispackages
		do
			if [ "$DEBUG_DIFF" == "false" ]; then
				get_packages $feed $repo_name $TMP_DIR/ _$repo_name
			fi

			pkg_removed=$(print_removed_packages $BASE_DIR/${feed}_${repo_name}.txt $TMP_DIR/${feed}_${repo_name}.txt)
			pkg_added=$(print_added_packages $BASE_DIR/${feed}_${repo_name}.txt $TMP_DIR/${feed}_${repo_name}.txt)

			if [ ! -z "$pkg_removed" ]; then
				feed_out="${feed_out}Removed packages from feed $feed:\n"
				feed_out="${feed_out}$pkg_removed\n"
			fi

			if [ ! -z "$pkg_added" ]; then
				feed_out="${feed_out}Added packages to feed $feed:\n"
				feed_out="${feed_out}$pkg_added\n"
			fi

		done

		if [ ! -z "$feed_out" ]; then
			echo "==$repo_name=="
			echo  -e "$feed_out"
		fi
	done

}

create_cron_files() {

SCRIPT_DIR=$(pwd)
SCRIPT_PATH=$SCRIPT_DIR/cron_check_feeds.sh
CRON_PATH=$SCRIPT_DIR/cron_check_feeds

cat >$CRON_PATH <<EOL
# /etc/cron.d/cron_check_feeds
5 11 * * * $SCRIPT_PATH
EOL
chmod +x $CRON_PATH

cat >$SCRIPT_PATH <<EOL
#!/bin/bash
script_dir=${SCRIPT_DIR}/
mail_script=${SCRIPT_DIR}/mail.py
repo_script=${SCRIPT_DIR}/check_feeds.sh
output_file=${SCRIPT_DIR}/repo_status.txt

fromaddr="xxx@xxx.yyy"
password="xyz"
toaddr="yyy@yyy.xxx"
subject="[repo.turris.cz] Missing packages "

cd \$script_dir && \$repo_script > \$output_file
if [ -s "\$output_file" ]; then
	subject="\$subject - OK"
	echo "Everything is OK :-) " > \$output_file
else
	subject="\$subject - Change!!"
fi
\$mail_script "\$fromaddr" "\$toaddr" "\$password" "\$subject" "\$output_file"

EOL
chmod +x $SCRIPT_PATH

}

case $1 in
--debug)
	DEBUG_DIFF=true
	compare_to_base
	;;
-u)
	echo "Updating base files:"
	rm -rf $BASE_DIR
	create_base
	;;
--create-cron-files)
	echo "Creating cron files:"
	create_cron_files
	;;
--help)
	echo "Help"
	;;
*)
	compare_to_base
	;;
esac


