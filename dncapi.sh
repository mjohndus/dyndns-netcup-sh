#!/bin/bash

# --> some declarations
#Your Credits
ncid=yourID
apikey=yourapikey
apipw=yourapipw

# --> get ipv4/6
aip4=$(curl -s 'https://ip4.irgendwas.ti')
aip6=$(curl -s 'https://ip6.irgendwas.ti')

api="https://ccp.netcup.net/run/webservice/servers/endpoint.php?JSON"
client=""

dir=$(dirname $0)

debug=false
force=false

# --> some functions
debug() {
      if [ $debug = true ]; then
         for i in "$@"; do
         echo -e $i"\n"
         done
      fi
}

ip4changed() {
      if [ ! -f $dir/ip4 ];then
          echo "" > $dir/ip4
          /bin/chmod 600 $dir/ip4
          bip4=$(cat $dir/ip4)
      else
          bip4=$(cat $dir/ip4)
      fi

      if [ $force = false -a  "$aip4" == "$bip4" -o "$aip4" == "" ];then
          debug "Your IPv4 is same or empty so nothing to do --> exit"
          exit 0
      else
          debug "Your public IPv4: $aip4"
          echo -e "Your IPv4 for $domain has changed or -f --> force is enabled\n"
          echo $aip4 > $dir/ip4
          aip=$aip4
      fi
}

ip6changed() {
      if [ ! -f $dir/ip6 ];then
          echo "" > $dir/ip6
          /bin/chmod 600 $dir/ip6
          bip6=$(cat $dir/ip6)
      else
          bip6=$(cat $dir/ip6)
      fi

      if [ $force = false -a  "$aip6" == "$bip6" -o "$aip6" == "" ];then
          debug "Your IPv6 is same or empty so nothing to do --> exit"
          exit 0
      else
          debug "Your public IPv6: $aip6"
          echo -e "Your IPv6 for $domain has changed or -f --> force is enabled\n"
          echo $aip6 > $dir/ip6
          aip=$aip6
      fi
}

login() {

loin="\"action\": \"login\", \"param\":"
loin1="\"apikey\": \"$apikey\", \"apipassword\": \"$apipw\", \"customernumber\": \"$ncid\""

      tmp=$(curl -s -X POST -d "{$loin {$loin1}}" "$api")
      sid=$(echo "${tmp}" | jq -r .responsedata.apisessionid)
      msg=$(echo "${tmp}" | jq -r .shortmessage)

      debug "$msg" "Session ID: $sid"

      if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
            echo "Error: $tmp"
            return 1
      fi
}

logout() {

lout="\"action\": \"logout\", \"param\":"
lout1="\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$ncid\""

      tmp=$(curl -s -X POST -d "{$lout {$lout1}}" "$api")
      msg=$(echo "${tmp}" | jq -r .shortmessage)
      debug "$msg"

      if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
            echo "Error: Session isn't made invalid !!!"
            echo "Error: $tmp"
            return 1
      fi
}

checkupdate() {
domain=$1
type=$2

      if [ $type == 'A' ];then
         debug "Your choice: IPv4 --> $type"
         ip4changed
      elif [ $type == 'AAAA' ];then
         debug "Your choice: IPv6 --> $type"
         ip6changed
      else
         echo "Use A for IPv4 OR AAAA for IPv6 --> exit"
         return 1
      fi
      login

idr="\"action\": \"infoDnsRecords\", \"param\":"
idr1="\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$ncid\", \"domainname\": \"$domain\""

# --> catch Records
      tmp=$(curl -s -X POST -d "{$idr {$idr1}}" "$api")

# --> select ip's from Records
      nip=$(echo "${tmp}" | jq -r --arg type "$type" '.responsedata.dnsrecords[] | select(.type == $type) | .destination' | xargs)
# --> create array with IP's -> "nip"
      nip=($nip)
      debug "Stored IP's: ${nip[*]}"

# --> select id's from Records
      ids=$(echo "${tmp}" | jq -r --arg type "$type" '.responsedata.dnsrecords[] | select(.type == $type) | .id' | xargs)
# --> create array with ID's -> "ids"
      ids=($ids)
      debug "DNS-Record ID's: ${ids[*]}"

# --> select hostnames from Records
# --> shows symbol * and no filelist --> GLOBIGNORE=* or
      set -f
      subc=$(echo "${tmp}" | jq -r '.responsedata.dnsrecords[] | select(.type == "'$2'") | .hostname' | xargs)
# --> create array with hostnames -> "subc"
      subc=($subc)
      debug "Hostnames: ${subc[*]}"

udr="\"action\": \"updateDnsRecords\", \"param\":"
udr1="\"apikey\": \"$apikey\", \"apisessionid\": \"$sid\", \"customernumber\": \"$ncid\", \"clientrequestid\": \"$client\" , \"domainname\": \"$domain\", \"dnsrecordset\":"

      for (( i=0; i<${#ids[@]}; i++ ));do
        #if ip has changed
        if [ "${nip[$i]}" != "$aip" ];then
              udr2="\"id\": \"${ids[$i]}\", \"hostname\": \"${subc[$i]}\", \"type\": \"$type\", \"priority\": \"0\", \"destination\": \"$aip\", \"deletercord\": \"FALSE\", \"state\": \"yes\""
              tmp=$(curl -s -X POST -d "{$udr {$udr1 { \"dnsrecords\": [ {$udr2} ]}}}" "$api")
           if [ "$(echo "$tmp" | jq -r .status)" != "success" ]; then
                 echo "Error: $tmp"
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
        echo "-U   CheckUpdate  dncapi.sh -P DOMAIN RECORDTYPE --> A OR AAAA "
        echo "-h   help"
        echo ""
        echo "Examples:"
        echo "CheckUpdate-IP:  dncapi.sh -U example.com A"
        echo "CheckUpdate-IP:  dncapi.sh -U example.com AAAA"
        echo "CheckUpdate-IP:  dncapi.sh -dfU example.com A"
        echo ""
}

# --> begin
if [ $# -eq 0 ]; then
        echo "No Argument"
        help
fi

while getopts 'dfUh' opt; do
        case "$opt" in
                d) debug=true;;
                f) force=true;;
                U) checkupdate "$2" "$3";;
                h) help;;
                *) echo "Invalid Argument";;
        esac
done
