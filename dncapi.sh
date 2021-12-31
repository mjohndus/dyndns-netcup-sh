#!/bin/bash

# --> some declarations
#Your Credits
ncid=your-ncid
apikey=your-apikey
apipw=your-apipw

# --> get ipv4/6
aip4a=$(curl -s 'https://ip4.irgendwas.ti')
aip4b=$(curl -s 'https://ip4.irgendwas.ti')
aip6a=$(curl -s 'https://ip6.irgendwas.ti')
aip6b=$(curl -s 'https://ip6.irgendwas.ti')

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
         echo -e "$i\n"
         done
      fi
}

checkipv4() {

      if [[ "$aip4a" =~ $regip4 ]]; then
             aip4=$aip4a
             debug "Server-1 IP: $aip4"
    elif [[ "$aip4b" =~ $regip4 ]]; then
             aip4=$aip4b
             debug "Server-2 IP: $aip4"
    else
             echo "Invalid IP: $aip4a $aip4b"
             exit 1
      fi
}

checkipv6() {

      if [[ "$aip6a" =~ $regip6 ]]; then
             aip6=$aip6a
             debug "Server-1 IP: $aip6"
    elif [[ "$aip6b" =~ $regip6 ]]; then
             aip6=$aip6b
             debug "Server-2 IP: $aip6"
    else
             echo "Invalid IP: $aip6a $aip6b"
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

      if [ $force = false -a  "$aip4" == "$bip4" ]; then
          debug "Your IPv4 is same so nothing to do --> exit"
          exit 0
      else
         if [ $info = true ]; then
            debug "Information about \"--> $domain <--\""
            else
              echo -e "Your IPv4 for $domain has changed or -f --> force is enabled\n"
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

      if [ $force = false -a  "$aip6" == "$bip6" ]; then
          debug "Your IPv6 is same so nothing to do --> exit"
          exit 0
      else
         if [ $info = true ]; then
            debug "Information about \"--> $domain <--\""
            else
              echo -e "Your IPv6 for $domain has changed or -f --> force is enabled\n"
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
         echo "Need 2 Args: $*"
         echo "Missing Arguments --> exit"
         exit 1
      fi
      if [ "$type" == "A" ]; then
         debug "\nYour choice: Domain --> $domain\n\t       IPv4 --> $type"
         checkipv4
         ip4change
      elif [ "$type" == "AAAA" ]; then
         debug "\nYour choice: Domain --> $domain\n\t       IPv6 --> $type"
         checkipv6
         ip6change
      else
         echo "Use A for IPv4 OR AAAA for IPv6 --> exit"
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

      debug "\n$msg"

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

info() {

force=true
debug=true
info=true

      checklogin $1 $2
      login
      getrecords $2

div=----------------------------------
div=$div$div$div
br=80
head="%1s %16s %23s %8s %26s %1s\n"

          printf "%$br.${br}s\n" "$div"
          printf "$head" "|" "ID       |" "Name          |" "Type  |" "IP            " "|"
          printf "%$br.${br}s\n" "$div"
      for (( i=0; i<${#ids[@]}; i++ ));do
          printf "| %-14s | %-21s | %6s | %26s |\n" ${ids[$i]} ${subc[$i]} $type ${nip[$i]}
      done
          printf "%$br.${br}s\n" "$div"

      logout
}

checkupdate() {

      checklogin $1 $2
      login
      getrecords $2

udr="\"action\": \"updateDnsRecords\", \"param\":"
udr1="\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$ncid\", \"clientrequestid\": \"$client\" , \"domainname\": \"$domain\", \"dnsrecordset\":"

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
           echo "Update ID: "${ids[$i]}" with Hostname: "${subc[$i]}" and IP befor: "${nip[$i]}"  after: "$aip""
        #if ip not changed
        else
           echo "ID: "${ids[$i]}" with Hostname: "${subc[$i]}" and IP: "${nip[$i]}" is equal with Public IP: "$aip""
        fi
      done
      logout
}

help() {
        echo "use Argument like -U or -dfU"
        echo ""
        echo "-d   Debug Mode   dncapi.sh -d... --> some informations"
        echo "-f   Force Mode   dncapi.sh -f... --> ignores ip-check"
        echo "-U   CheckUpdate  dncapi.sh -U DOMAIN RECORDTYPE --> A OR AAAA "
        echo "-h   help"
        echo ""
        echo "Examples:"
        echo "CheckUpdate-IP:  dncapi.sh -U example.com A"
        echo "CheckUpdate-IP:  dncapi.sh -dU example.com AAAA"
        echo "CheckUpdate-IP:  dncapi.sh -fU example.com A"
        echo "CheckUpdate-IP:  dncapi.sh -dfU example.com AAAA"
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
