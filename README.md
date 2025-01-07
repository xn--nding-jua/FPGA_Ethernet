# FPGA_Ethernet
This project contains an FPGA-based Ethernet-System to receive and send ARP-Messages, ICMP-Packets (PING) and UDP-Messages using pure logic-elements without any kind of soft-core-processors.

It is using the nice EthernetMAC of Philipp Kerling (https://github.com/yol/ethernet_mac) to communicate with an EthernetPHY. This project is designed for an Altera EP3C40 Cyclone III DevBoard using a Marvel 881119 10/100/1000Mbps EthernetPHY but can be used with any other Intel FPGA using Quartus 13.1 and newer. Just change the pin-configuration and you should be good to go.

As this project is not using any soft-core-processor and all protocols are implemented using pure logic, it is optimized to work as a Single-Destination-System. For instance, the FPGA could be used to measure fast signals or audio and transmit it with 100 or 1000Mbps to a single destination computer using UDP.

For this, the FPGA requests via the ARP-protocol the MAC-address of one single IP-address. After some seconds it begins sending UDP-messages to this IP-address. Using two ore more destinations is possible.

If you like a more complex network-situation, a soft-core-process using C-language is recommended, but loosing several of the speed-benefits you have with this system.


# General things to get this up and running

## Init Git-Submodules
This repository uses other GitHub-repositories as submodules. Please use the following command to checkout the main-repo together with submodules:
```
git clone --recurse-submodules [URL]
```

If you have already checkout the repo without submodules, you can checkout them using the following command:
```
git submodule update --init --recursive
```
