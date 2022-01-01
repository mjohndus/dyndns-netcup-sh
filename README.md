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
- aip4a=$(curl -s 'https://ip4.irgendwas.ti')  
- aip4b=$(curl -s 'https://ip4.irgendwas.ti')
- aip6a=$(curl -s 'https://ip6.irgendwas.ti')
- aip6b=$(curl -s 'https://ip6.irgendwas.ti')

## HowTo
**At first start:**  
cip4.log or/and cip6.log files for saving current ip addresses are created in the install folder.  

**At start-up before login:**  
an ip check compares the current and the stored ip.  
If nothing has changed, the script will be aborted.  
The script starts if ip changed or option -f is set.  

**Use Argument -U as single or like -dU, -dfU:**  

| Option | Mode | description |
|:------:|-----:|------------:|
| -d | Debug | shows Informations |
| -f | Force | ignores ip check and changes different ip's |
| -U | Main function | checks and updates if ip's are different |
| -i | Info | shows Informations about Domain |
| -h | Help | shows Options and Examples |

**Examples:**  
```
./dncapi.sh -U example.com A  
./dncapi.sh -dU example.com AAAA  
./dncapi.sh -fU example.com A  
./dncapi.sh -dfU example.com AAAA  
./dncapi.sh -i example.com AAAA
```
## Output
**Example outputs for IPv4:**  

1. Cronjob  
0,30 * * * * /your path to/dncapi.sh -U example.de AAAA  

Using in cronjob:  
there is no Output:  
 --> if NO Error or Update  
 --> debug and force not activated  

2. Output (debug -d with force -f)  
 - force Ignores ipcheck:  
 --> is something to do changes are made  

 - debug prints some (login)informations  

user@xxxx:~# ./dncapi.sh -dfU example.de A  

Your choice: Domain --> example.de  
	       IPv4 --> A  

Server-1 IP: 177.198.122.123  

Cached IPv4: 177.198.122.123  

Your IPv4 for example.de has changed or -f --> force is enabled  

Login successful  

Session ID: NTE5NG5VSzM3ODYyMXZBbW9IY123456789123452eFo5Nz  

Hostnames: * @ xxxx yyyy  

--> force:  
ID: 44433344 with Hostname: * and IP: 177.198.122.123 is equal with Public IP: 177.198.122.123  
ID: 44433355 with Hostname: @ and IP: 177.198.122.123 is equal with Public IP: 177.198.122.123  
Update ID: 44433366 with Hostname: xxxx and IP befor: 199.198.199.123  after: 177.198.122.123  
ID: 43355566 with Hostname: yyyy and IP: 177.198.122.123 is equal with Public IP: 177.198.122.123  
<-- force  

Logout successful  

3. Output (info -i)  
 - debug and force are activated automatically  
 --> but no changes are made  
 --> only info  

user@xxxx:~# ./dncapi.sh -i example.de A

Your choice: Domain --> example.de
               IPv4 --> A

Server-1 IP: 177.198.122.123
Cached IPv4: 177.198.122.123

Information about "--> example.de <--"

Login successful

Session ID: NTE5NG5VSzM3ODYyMXZBbW9IY123456789123452eFo5Nz

--------------------------------------------------------------------------------  
|       ID       |         Name          | Type   |             IP             |  
--------------------------------------------------------------------------------  
| 44433344       | *                     | A      |            177.198.122.123 |  
| 44433355       | @                     | A      |            177.198.122.123 |  
| 44433366       | xxxx                  | A      |            177.198.122.123 |  
| 43355566       | yyyy                  | A      |            177.198.122.123 |  
--------------------------------------------------------------------------------   

Logout successful
