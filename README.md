# netcat-stratum-client
A quick netcat startum client, using the raw json to login and get a work unit for any coin.

Currently only have connection json for grin on nicehash. 
Add server and port to the .sh file and your wallet address to the json file.

# . ./connect.sh 
# getwork

To add other coins one would load a packet capture tool ( wireshark/pcap ) and watch a client connect, get work and send a share back.
Modifiying the json file as needed or creating a new json file for each coin.
