# dyndns for netcup

### Installation
**Copy the file to your preferred folder.**  
### Confuguration
**Fill out your data:**  
- ncid=yourID  
- apikey=yourapikey  
- apipw=yourapipw  

**Your preferred Server:**  
- aip4=$(curl -s 'https://ip4.irgendwas.ti')  
- aip6=$(curl -s 'https://ip6.irgendwas.ti')  

### HowTo

**use Argument like -U or -dfU**  

- -d   Debug Mode   dncapi.sh -d... --> some informations  
- -f   Force Mode   dncapi.sh -f... --> ignores ip-check  
- -U   CheckUpdate  dncapi.sh -P DOMAIN RECORDTYPE --> A OR AAAA  
- -h   help  

**Examples:**
- CheckUpdate-IP:  dncapi.sh -U example.com A  
- CheckUpdate-IP:  dncapi.sh -U example.com AAAA  
- CheckUpdate-IP:  dncapi.sh -dfU example.com A  

### Output

**Example for IPv4:** 
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
