# dyndns for netcup
**simple script to update all IPv4 or IPv6 for one domain hosted by netcup**  
ONLY UPDATING. No adding, deleting, creating, changing names, ...  

Using the **[Netcup-DNS_API](https://www.netcup-wiki.de/wiki/DNS_API)**  

## Installation
**Copy the file to your preferred folder.**  
## Confuguration
**Fill out your data:**  
- ncid=yourID  
- apikey=yourapikey  
- apipw=yourapipw  

**Your preferred Server:**  
- aip4=$(curl -s 'https://ip4.irgendwas.ti')  
- aip6=$(curl -s 'https://ip6.irgendwas.ti')  

## HowTo
**At first start:**  
cip4.log or cip6.log files for saving current addresses are created in the same folder.  

**At start-up before login:**  
an ip check compares the current and the stored ip.  
If nothing has changed, the script is terminated.  
The script starts if ip changed or option -f is set.  

**Use Argument -U as single or like -dU, -dfU:**  

| Option | Mode | description |
|:------:|-----:|------------:|
| -d | Debug Mode | shows some Informations |
| -f | Force Mode | ignores ip check |
| -U | Main function | checks and updates if ip's are different |
| -h | Help Mode | shows Options and Examples |

**Examples:**  
```
./dncapi.sh -U example.com A  
./dncapi.sh -dU example.com AAAA  
./dncapi.sh -dfU example.com A  
```
## Output
**Example output for IPv4:**  
```
user@xxxx:~# ./dncapi.sh -dfU example.de A  
Your choice: IPv4 --> A  
Your public IPv4: 177.198.122.123  
Your IPv4 for example.de has changed or -force is enabled  
Login successful  
Session ID: NTE5NG5VSzM3ODYyMXZBbW9IY123456789123452eFo5Nz  
Stored IP's: 177.198.122.123 177.198.122.123 199.198.199.123 177.198.122.123  
DNS-Record ID's: 44433344 44433355 44433366 43355566  
Hostnames: * @ xxxx yyyy  

ID: 44433344 with Hostname: * and IP: 177.198.122.123 is equal with Public IP: 177.198.122.123  
ID: 44433355 with Hostname: @ and IP: 177.198.122.123 is equal with Public IP: 177.198.122.123  
Update ID: 44433366 with Hostname: xxxx and IP befor: 199.198.199.123  after: 177.198.122.123  
ID: 43355566 with Hostname: yyyy and IP: 177.198.122.123 is equal with Public IP: 177.198.122.123  
Logout successful  
```
