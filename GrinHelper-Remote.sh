#!/bin/bash

#### Deps ####
# Needs GrinHelper ( https://github.com/dewdeded/GrinHelper on remote node)

#### Configuration ####
ConfigFile="$(pwd)/GrinHelper-NodeList.conf"
UpdateURL1="https://raw.githubusercontent.com/dewdeded/GrinHelper/master/GrinHelper.sh"
UpdateURL2="https://raw.githubusercontent.com/dewdeded/GrinHelper/master/GrinHelper-CheckRemoteNodes.sh"
BaseDir="/root/mw"
RustDir="~/.cargo/bin"
NodeListLocation="./GrinHelper-NodeList.conf"

#### Begin main script ####
	if [ ! -f $NodeListLocation ]; then echo "GrinHelper-NodeList.conf not found. Creating now, please edit." 
	wget --no-check-certificate --quiet 'https://raw.githubusercontent.com/dewdeded/GrinHelper/master/GrinHelper-NodeList.conf.example' -O GrinHelper-NodeList.conf > /dev/null 2> /dev/null
	exit
	fi


#### Begin main script ####
source "$ConfigFile"

# Function Check Stats
option_1() {
	clear
	echo -e "\033[0;33mNetwork height:			$(curl -s https://grintest.net/v1/chain | jq .height)\033[0m"
	echo -e "\033[0;33mNetwork difficulty:		$(curl -s https://grintest.net/v1/chain | jq .total_difficulty)\033[0m"

	for host in "${hosts[@]}"; do
		IFS=":" names=($host)
		echo -e "\033[0;34m\nHostname: ${names[2]} (IP: ${names[1]})\n\033[0m"
		if [ "${names[3]}" == "testnet1" ]; then
		ssh ${names[1]} /bin/grinhelper remote_stats
		else
		echo -e "Testnet2 Node\n"
		ssh ${names[1]} "tail -n 3 $BaseDir/grin/server/grin.log"
		fi
	done
	echo ""
	echo -e "\033[0;33m\nPress ENTER To Return\033[0m"
	read continue
}

# Function Check Outputs
option_2() {
	clear

	for host in "${hosts[@]}"; do
		IFS=":" names=($host)
		echo -e "\nHostname: ${names[2]} (IP: ${names[1]})\n"
		cmd="export PATH=\"$BaseDir/grin/target/debug:$RustDir/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\" ; cd $BaseDir/grin/node1; grin wallet -p password outputs"
		ssh -o LogLevel=QUIET ${names[1]} -t "$cmd"
	done

	echo -e "\033[0;33m\nPress ENTER To Return\033[0m"
	read continue
}

# Function Check Balances
option_3() {
    clear

	for host in "${hosts[@]}"; do
		IFS=":" names=($host)
		echo -e "\nHostname: ${names[2]} (IP: ${names[1]})\n"
	if [ "${names[3]}" == "testnet1" ]; then
		cmd="export PATH=\"$BaseDir/grin/target/debug:$RustDir/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\"; pushd "$BaseDir/grin/node1" > /dev/null ; grin wallet -p password info|grep Spend"
		balance=$(ssh -o LogLevel=QUIET ${names[1]} -t "$cmd" | awk '{print $4}')
		echo "${names[2]} has $balance"

		else
		echo -e "Testnet2 Node, no wallet ATM\n"
		#ssh ${names[1]} "tail -n 3 $BaseDir/grin/server/grin.log"
		fi
	done

	echo -e "\033[0;33m\nPress ENTER To Return\033[0m"
	read continue
}

# Function Update Grinhelper
option_4() {
	clear

	for host in "${hosts[@]}"; do
		IFS=":" names=($host)
		echo -e "\n\033[0;35mChecking ports at Hostname: ${names[2]} (IP: ${names[1]})\033[0m\n"
	   
	    echo -e "Checking if port 13413 at ${names[2]} is publicly reachable."
		result_test=$(timeout 2 bash -c "</dev/tcp/${names[1]}/13413" 2>&1)
		if [ "$?" == "0" ]; then echo -e "\033[0;32mSuccess, port 13413 is reachable.\033[0m"; else echo -e "\033[0;31mFail, port 13413 is NOT reachable.\033[0m"; fi
		
		echo -e "\nChecking if port 13414 at ${names[2]} is publicly reachable."
		result_test=$(timeout 2 bash -c "</dev/tcp/${names[1]}/13414" 2>&1)
		if [ "$?" == "0" ]; then echo -e "\033[0;32mSuccess, port 13414 is reachable.\033[0m"; else echo -e "\033[0;31mFail, port 13414 is NOT reachable.\033[0m"; fi
		
		echo -e "\nChecking if port 13415 at ${names[2]} is publicly reachable."
		result_test=$(timeout 2 bash -c "</dev/tcp/${names[1]}/13415" 2>&1)
		if [ "$?" == "0" ]; then echo -e "\033[0;32mSuccess, port 13415 is reachable.\033[0m"; else echo -e "\033[0;31mFail, port 13415 is NOT reachable.\033[0m"; fi
	done

	echo -e "\033[0;33m\nPress ENTER To Return\033[0m"
	read continue
}

# Function Update Grinhelper
option_u() {
	clear

	for host in "${hosts[@]}"; do
		IFS=":" names=($host)
		echo -e "\nUpdating Grinhelper at Hostname: ${names[2]} (IP: ${names[1]})\n"
		ssh ${names[1]} "sudo wget -q $UpdateURL1 -O /bin/grinhelper; 
		sudo chmod +x /bin/grinhelper;
		if [ ! -f "/bin/GrinHelper" ]; then sudo ln -s /bin/grinhelper /bin/GrinHelper; fi;
		sudo wget -q $UpdateURL2 -O /bin/GrinHelper-Remote;
		sudo chmod +x /bin/GrinHelper-Remote"
		echo "Finished updating Grinhelper at ${names[2]}"

	done

	echo -e "\033[0;33m\nPress ENTER To Return\033[0m"
	read continue
}

## Check if CLI argument passed to start updating nodes
if [ "$1" == "update" ]; then
	echo Updating nodes
	option_u
	exit 0
fi

while :; do
	clear
	echo "=========================================================================="
	figlet -f small -f small GrinHelper Suite
	figlet -f small -f small Check Remote Nodes
	echo -e "All functions, will be executed on all your Grin nodes.\n"
	echo "1) Check Sync & Mining Stats"
	echo "2) Check Outputs"
	echo "3) Check Balance"
	echo "4) Check Connectivity (ports reachable)"
	echo ""
	echo "u) Update Grinhelper"
	echo "e) Exit"
	echo "=========================================================================="
	echo ""
	echo "Please select an option: "
	read m_menu

	case "$m_menu" in

	1) option_1 ;;
	2) option_2 ;;
	3) option_3 ;;
	4) option_4 ;;
	u) option_u ;;
	e) exit 0 ;;
	*)
		echo "Error, invalid input. Press ENTER to go back."
		read
		;;

	esac
done
