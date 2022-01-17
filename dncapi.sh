#!/bin/bash

# --> some declarations
#Your Credits
ncid=your-ncid
apikey=your-apikey
apipw=your-apipw

# --> get ipv4/6
aip4a=$(curl -s 'https://ip4.first.de')
aip4b=$(curl -s 'https://ip4.second.de')
aip6a=$(curl -s 'https://ip6.first.de')
aip6b=$(curl -s 'https://ip6.second.de')

api="https://ccp.netcup.net/run/webservice/servers/endpoint.php?JSON"
client=""

dir=$(dirname $0)

regip4='^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$'
regip6='^(([0-9a-fA-F]{0,4}:){1,7}([0-9a-fA-F]{0,4}))$'

debug=false
force=false
info=false

# --> some functions
debug() {
      if [ $debug = true ]; then
         for i in "$@"; do
         echo -e "\n$i"
         done
      fi
}

checkipv4() {

      if [[ "$aip4a" =~ $regip4 ]]; then
             aip4=$aip4a
             debug "Server-1 IP: $aip4"
    elif [[ "$aip4b" =~ $regip4 ]]; then
             aip4=$aip4b
             debug "Fallback Server-2 IP: $aip4" "Server-1 not reachable ?"
    else
             echo "Error: Invalid IP: $aip4a $aip4b"
             exit 1
      fi
}

checkipv6() {

      if [[ "$aip6a" =~ $regip6 ]]; then
             aip6=$aip6a
             debug "Server-1 IP: $aip6"
    elif [[ "$aip6b" =~ $regip6 ]]; then
             aip6=$aip6b
             debug "Fallback Server-2 IP: $aip6" "Server-1 not reachable ?"
    else
             echo "Error: Invalid IP: $aip6a $aip6b"
             exit 1
      fi
}

ip4change() {

      if [ ! -f $dir/cip4.log ]; then
          echo "" > $dir/cip4.log
          /bin/chmod 600 $dir/cip4.log
          bip4=$(cat $dir/cip4.log)
      else
          bip4=$(cat $dir/cip4.log)
          debug "Cached IPv4: $bip4"
      fi

      if [ $force = false -a "$aip4" == "$bip4" ]; then
          debug "Your IPv4 is same so nothing to do --> exit"
          exit 0
      else
         if [ $info = true ]; then
            debug "Information about \"--> $domain <--\""
            else
              echo -e "\nYour IPv4 for $domain has changed or -f --> force is enabled"
              echo $aip4 > $dir/cip4.log
              aip=$aip4
         fi
      fi
}

ip6change() {

      if [ ! -f $dir/cip6.log ]; then
          echo "" > $dir/cip6.log
          /bin/chmod 600 $dir/cip6.log
          bip6=$(cat $dir/cip6.log)
      else
          bip6=$(cat $dir/cip6.log)
          debug "Cached IPv6: $bip6"
      fi

      if [ $force = false -a "$aip6" == "$bip6" ]; then
          debug "Your IPv6 is same so nothing to do --> exit"
          exit 0
      else
         if [ $info = true ]; then
            debug "Information about \"--> $domain <--\""
            else
              echo -e "\nYour IPv6 for $domain has changed or -f --> force is enabled"
              echo $aip6 > $dir/cip6.log
              aip=$aip6
         fi
      fi
}

checklogin() {

      if [ -n "$2" ]; then
         domain=$1
         type=$2
      else
         echo "Error: Need 2 Args: $*"
         echo "Error: Missing Arguments --> exit"
         exit 1
      fi
      if [ "$type" == "A" ]; then
         debug "Your choice: Domain --> $domain\t       IPv4 --> $type"
         checkipv4
         ip4change
      elif [ "$type" == "AAAA" ]; then
         debug "Your choice: Domain --> $domain\t       IPv6 --> $type"
         checkipv6
         ip6change
      else
         echo "Error: Use A for IPv4 OR AAAA for IPv6 --> exit"
         exit 1
      fi
}

login() {

loin="\"action\": \"login\", \"param\":"
loin1="\"apikey\": \"$apikey\", \"apipassword\": \"$apipw\", \"customernumber\": \"$ncid\""

      tmp=$(curl -s -X POST -d "{$loin {$loin1}}" "$api")
      if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
            echo "Error: "$(echo "$tmp" | jq -r .shortmessage)" --> Exit!"
            echo "Error: "$(echo "$tmp" | jq -r .longmessage)" --> Exit!"
            exit 1
      fi
      sid=$(echo "${tmp}" | jq -r .responsedata.apisessionid)
      msg=$(echo "${tmp}" | jq -r .shortmessage)

      debug "$msg" "Session ID: $sid"
}

logout() {

lout="\"action\": \"logout\", \"param\":"
lout1="\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$ncid\""

      tmp=$(curl -s -X POST -d "{$lout {$lout1}}" "$api")
      msg=$(echo "${tmp}" | jq -r .shortmessage)

      debug "$msg\n"

      if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
            echo "Error: Session isn't made invalid !!!"
            echo "Error: "$(echo "$tmp" | jq -r .longmessage)" --> Exit!"
            return 1
      fi
}

getrecords() {

idr="\"action\": \"infoDnsRecords\", \"param\":"
idr1="\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$ncid\", \"domainname\": \"$domain\""

# --> catch Records
      tmp=$(curl -s -X POST -d "{$idr {$idr1}}" "$api")
# --> no Records say goodby --> Check DomainName
      if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
            echo "Error: "$(echo "$tmp" | jq -r .longmessage)" --> Check DomainName: \"--> $domain <--\" --> Exit!"
#            echo "Error: $long --> Check DomainName: $domain --> Exit!"
            logout
            exit 1
      fi
# --> select ip's from Records
      nip=$(echo "${tmp}" | jq -r --arg type "$type" '.responsedata.dnsrecords[] | select(.type == $type) | .destination' | xargs)
# --> create array with IP's -> "nip"
      nip=($nip)
#      debug "Stored IP's: ${nip[*]}"

# --> select id's from Records
      ids=$(echo "${tmp}" | jq -r --arg type "$type" '.responsedata.dnsrecords[] | select(.type == $type) | .id' | xargs)
# --> create array with ID's -> "ids"
      ids=($ids)
#      debug "DNS-Record ID's: ${ids[*]}"

# --> select hostnames from Records
# --> shows symbol * and no filelist --> GLOBIGNORE=* or
      set -f
      subc=$(echo "${tmp}" | jq -r '.responsedata.dnsrecords[] | select(.type == "'$1'") | .hostname' | xargs)
# --> create array with hostnames -> "subc"
      subc=($subc)
      if [ $info = false ]; then
         debug "Hostnames: ${subc[*]}"
      fi
}

line() {
div1=----------------------------------
div1=$div1$div1$div1$div1
printf "%.$1s\n" "$div1"
}

info() {

force=true
debug=true
info=true

      checklogin $1 $2
      login
      getrecords $2

head="%s %16s %24s %8s %28s\n"
body="%s %-14s %s %-22s %s %6s %s %26s %s\n"

          echo ""
          line 81
          printf "$head" "|" "ID       |" "Name          |" "Type  |" "IP             |"
          line 81
      for (( i=0; i<${#ids[@]}; i++ ));do
          printf "$body" "|" "${ids[$i]}" "|" "${subc[$i]}" "|" $type "|" "${nip[$i]}" "|"
      done
          line 81
      logout
}

checkupdate() {

      checklogin $1 $2
      login
      getrecords $2

#"${ip:-"0"}\"
pp=$([ "$type" == "A" ] && echo "IPv4" || echo "IPv6")
top="%s %12s %24s %27s %27s %12s\n"
bod="%s %-10s %s %-22s %s %25s %s %25s %s %10s %s\n"
bod1="%s %-10s %s %-22s %s %66s %s\n"

udr="\"action\": \"updateDnsRecords\", \"param\":"
udr1="\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$ncid\", \"clientrequestid\": \"$client\" , \"domainname\": \"$domain\", \"dnsrecordset\":"

      #printf "%.*s\n" 108 "$part"
      echo ""
      line 108
      printf "$top" "|" "ID     |" "HostName        |" "Zone IP          |" "Public IP         |" "Status   |"
      line 108

      for (( i=0; i<${#ids[@]}; i++ ));do
        #if ip has changed
        if [ "${nip[$i]}" != "$aip" ]; then
              udr2="\"id\": \"${ids[$i]}\", \"hostname\": \"${subc[$i]}\", \"type\": \"$type\", \"priority\": \"0\", \"destination\": \"$aip\", \"deletercord\": \"FALSE\", \"state\": \"yes\""
              tmp=$(curl -s -X POST -d "{$udr {$udr1 { \"dnsrecords\": [ {$udr2} ]}}}" "$api")
           if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
                 echo "Error: "$(echo "$tmp" | jq -r .longmessage)" --> Exit!"
                 logout
                 return 1
           fi
           ##line 108
           printf "$bod" "|" "${ids[$i]}" "|" "${subc[$i]}" "|" "${nip[$i]}" "|" "$aip" "|" "different" "|"
           #printf "$bod1" "|" "${ids[$i]}" "|" "${subc[$i]}" "|" "$pp changed successfully                    " "|"
           #line 108
        #if ip not changed
        else
           printf "$bod" "|" "${ids[$i]}" "|" "${subc[$i]}" "|" "${nip[$i]}" "|" "$aip" "|" "equal" "|"
           ##line 108
           printf "$bod1" "|" "${ids[$i]}" "|" "${subc[$i]}" "|" "$pp changed successfully                    " "|"
           line 108
        fi
      done
      line 108
      logout
}

help() {
        echo "use Argument like -U or -dfU"
        echo ""
        echo "-d   Debug Mode   dncapi.sh -d... --> some informations"
        echo "-f   Force Mode   dncapi.sh -f... --> ignores ip-check"
        echo "-U   CheckUpdate  dncapi.sh -U DOMAIN RECORDTYPE --> A OR AAAA "
        echo "-i   info         dncapi.sh -i DOMAIN RECORDTYPE"
        echo "-h   help"
        echo ""
        echo "Examples:"
        echo "CheckUpdate-IP:  dncapi.sh -U example.com A"
        echo "CheckUpdate-IP:  dncapi.sh -dU example.com AAAA"
        echo "CheckUpdate-IP:  dncapi.sh -fU example.com A"
        echo "CheckUpdate-IP:  dncapi.sh -dfU example.com AAAA"
        echo "CheckUpdate-IP:  dncapi.sh -i example.com A"
        echo ""
}

# --> begin
if [ $# -eq 0 ]; then
        echo "No Argument"
        help
fi

while getopts 'dfUih' opt; do
        case "$opt" in
                d) debug=true;;
                f) force=true;;
                U) checkupdate "$2" "$3";;
                i) info "$2" "$3";;
                h) help;;
                *) echo "Invalid Argument";;
        esac
done
