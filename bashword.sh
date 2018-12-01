#!/usr/bin/env bash
home=$HOME
BASHWORD_DB="$HOME/.bashword/bashword_db"

if [ ! -e "$BASHWORD_DB.enc" ]
then
  mkdir -p "$home/.bashword"
  touch  "$home/.bashword/bashword_db"

	chmod +x /usr/local/bin/bw

	echo " * DB has been generated in $home/.bashword *"
  read -p "Provide a password (make sure to remember it):" db_password
  openssl enc -aes-256-cbc -salt -in "$BASHWORD_DB" -out "$BASHWORD_DB.enc" -pass pass:"$db_password"
  echo "* The DB has been succesfully encrypted. *"
  rm "$BASHWORD_DB"
fi

function local_help {
	cat <<'EOF'

	Usage:
		bw new|n -s [service]
		bw get|g -s [service]
		bw update|u -s [service]
		bw ls
	Extra:
		bw  new|n -s [service] -p [password]
		bw update|u -s [service] -p [password]
		bw  new|n -s [service] -l [length] #default length is 8

EOF
}

function gen_pass {
	length=$1
	if [[ -z "$length" ]]; then
			echo | cat  /dev/urandom | head -10 | base64 | tr -d '\n'| cut -c1-8
	else
		echo | cat  /dev/urandom | head -1 | base64 |tr -d ' '| tr -d '\n'| cut -c1-"$length"
	fi
}

function decrypt {
	read -r -s -p "DB password: " db_password
	openssl enc -aes-256-cbc -d -in "$BASHWORD_DB.enc" -out "$BASHWORD_DB" -pass pass:"$db_password"
	echo "$db_password"
}

function encrypt {
	db_password=$1
	openssl enc -aes-256-cbc -salt -in "$BASHWORD_DB" -out "$BASHWORD_DB.enc" -pass pass:"$db_password"
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


function new_password {
	service=$1
	provided_pass=$2
	length=$3

	db_password=$(decrypt)
	exists=$(check_exists "$service")
	if [[ -z "$exists" ]]; then
		if [[ -z "$provided_pass" ]]; then
				service_password=$(gen_pass "$length")
		else
			service_password="$provided_pass"
		fi
		echo "$service:$service_password" >> "$BASHWORD_DB"
		printf "\n\nNew password generated for $service: $service_password\n"
	else
		printf "\nService with this name already exists. Did you mean 'bw update'?\n"
	fi
	encrypt "$db_password"
}

function update_password {
	service=$1
	provided_pass=$2
	length=$3

	db_password=$(decrypt)
	exists=$(check_exists "$service")
	if [[ "$exists" ]]; then
		if [[ -z "$provided_pass" ]]; then
			service_password=$(gen_pass "$length")
		else
			service_password="$provided_pass"
		fi
		awk -v name="$service" -v pass="$service_password" -F ':' '$1 == name {$2=pass;print $1":"$2}' "$BASHWORD_DB" > "$BASHWORD_DB.tmp"
		awk -v name="$service" -F ':' '$1 != name {print $1":"$2}' "$BASHWORD_DB" >> "$BASHWORD_DB.tmp"
		rm "$BASHWORD_DB"
		mv "$BASHWORD_DB.tmp" "$BASHWORD_DB"
		encrypt "$db_password"
		printf "\n\nPassword updated for $service\n"
	else
		printf "\n\n "$service" does not exist. Did you mean 'bw new'?\n"
	fi

}

function get_password {
	service=$1
	db_password=$(decrypt)
	exists=$(check_exists "$service")
	if [[ -z "$exists" ]]; then
		printf "\n\nService not found \n"
	else
		printf "\n\nThe password for "$service" is "$exists"\n"
	fi
	encrypt "$db_password"
}


function list_services {
	db_password=$(decrypt)
	printf "\n\nHere is the list of your services:\n\n"
	awk -F ":" '{out="- " $1 "\n" ; print out}' "$BASHWORD_DB"
	encrypt "$db_password"

}

action="$1"; shift
while getopts s:p:l: option; do
	case $option in
		s) service=$OPTARG;;
		p) password=$OPTARG;;
		l) length=$OPTARG;;
		*) local_help;;
	esac
done

if [ -z "$service" ] && [ "$action" != "ls" ]; then
	echo "* No argument supplied"
	local_help
fi

case "$action" in
	n|new) new_password "$service" "$password" "$length";;
	g|get) get_password "$service";;
	u|update)update_password "$service" "$password" "$length";;
	ls)list_services;;

esac
