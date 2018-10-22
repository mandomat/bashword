#!/usr/bin/env bash

#set -euo pipefail

function local_help {
	cat <<'EOF'

	Usage:
		bw DB_NAME new -s facebook
		bw DB_NAME get -s facebook
	Extra:
		bw DB_NAME new -s youporn -p mypornpassword

EOF
}

function gen_pass {
	echo | cat  /dev/urandom | head -1 | base64 | tr -d '\n'| cut -c1-8
}

function new_password {
	service=$1
	read -r -s -p "DB password: " db_password
	openssl enc -aes-256-cbc -d -in "$BASHWORD_DB.enc" -out "$BASHWORD_DB" -pass pass:"$db_password"
	exists=$(check_exists "$service")
	if [[ -z "$exists" ]]; then
		service_password=$(gen_pass)
		echo "$service:$service_password" >> "$BASHWORD_DB"
		openssl enc -aes-256-cbc -salt -in "$BASHWORD_DB" -out "$BASHWORD_DB.enc" -pass pass:"$db_password"
		echo "New password generated for $service: $service_password"
	else
		echo "Service with this name already exists. Did you mean 'bashword update'?"
	fi
	rm  -fr "$BASHWORD_DB"
}

function get_password {
	service=$1
	read -r -s -p "DB password: " db_password
	openssl enc -aes-256-cbc -d -in "$BASHWORD_DB.enc" -out "$BASHWORD_DB" -pass pass:"$db_password"
	exists=$(check_exists "$service")

	if [[ -z "$exists" ]]; then
		echo "Service not found"
	else
		echo "$exists"
	fi

	rm -fr "$BASHWORD_DB"
}

function check_exists {
	found=$(awk -v name="$service" -F ':' '$1 == name { print $2 }' < "$BASHWORD_DB")
	if [[ -z "$found" ]]; then
		echo ""
	else
		echo "$found"
	fi
}

action="$1"; shift
while getopts s:p: option; do
	case $option in
		s) service=$OPTARG;;
		p) password=$OPTARG;;
		*) local_help;;
	esac
done

if [[ -z "$service" ]]; then
	echo "* No service argument supplied"
	local_help
fi

case "$action" in
	n|new) new_password "$service" ;;
	g|get) get_password "$service";;
esac
