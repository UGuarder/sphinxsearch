#!/bin/bash

set -e

if [ "$1" = 'sphinx' ]; then
	trap "echo TRAPed signal" HUP INT QUIT KILL TERM

	chown -R sphinx:sphinx /var/lib/sphinx /var/log/sphinx
	echo "Start Cron Daemon"
	/usr/sbin/crond -n -x misc 2>&1 | while read line; do echo "[`date +'%a %b %d %T.%3N %Y'`] $line"; done; >> /var/log/sphinx/cron &
	if [ "$2" = 'indexer' ]; then
		shift
		shift
		indexes=$@
		if [ -z "$1" ]; then
			indexes='--all'
		fi

		echo "Start Sphinxsearch Indexer for \"$indexes\" indexes"
		su - sphinx -c "/usr/bin/indexer $indexes"
	fi

	echo "Starting Sphinx"
	service searchd start
	
	echo "[hit enter key to exit] or run 'docker stop <container>'"
	read

	echo "Stopping Sphinx"
	service searchd stop
elif [ "$1" = 'indexer' ]; then
	shift
	indexes=$@
	if [ -z "$1" ]; then
		indexes='--all'
	fi
	echo "Start Sphinxsearch Indexer for \"$indexes\" indexes"
	su - sphinx -c "/usr/bin/indexer $indexes"
elif [ "$1" = 'crontab' ]; then
	crontab -e -u sphinx
elif [ "$1" = 'editconfig' ]; then
	vim /etc/sphinx/sphinx.conf
elif [ "$1" = 'log' ]; then
	tail -f /var/log/sphinx/*
else
	exec "$@"
fi

