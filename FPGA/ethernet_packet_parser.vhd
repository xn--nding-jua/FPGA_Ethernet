-- Ethernet Packet Receiver
-- (c) 2025 Dr.-Ing. Christian Noeding
-- christian@noeding-online.de
-- Released under GNU General Public License v3
-- Source: https://www.github.com/xn--nding-jua/AES50_Transmitter
--
-- This file contains an ethernet-packet-receiver to receives individual bytes from a FIFO.

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity ethernet_packet_parser is 
	port
	(
		clk						: in std_logic;

		pkt_dst_mac				: in std_logic_vector(47 downto 0); -- valid for all MAC-packets
		pkt_src_mac				: in std_logic_vector(47 downto 0); -- valid for all MAC-packets
		pkt_type					: in std_logic_vector(15 downto 0); -- valid for all MAC-packets
		arp_type					: in std_logic_vector(15 downto 0); -- only valid for ARP packages
		arp_dst_ip				: in std_logic_vector(31 downto 0); -- only valid for ARP packages
		arp_src_ip				: in std_logic_vector(31 downto 0); -- only valid for ARP packages
		ip_type					: in std_logic_vector(7 downto 0);  -- valid for all IP-packeges
		udp_src_port			: in unsigned(15 downto 0); -- only valid for UDP packages
		udp_dst_port			: in unsigned(15 downto 0); -- only valid for UDP packages
		udp_length				: in unsigned(15 downto 0); -- only valid for UDP packages

		ram_data					: in std_logic_vector(7 downto 0);
		mac_address				: in std_logic_vector(47 downto 0);
		ip_address				: in std_logic_vector(31 downto 0);
		dst_ip_address			: in std_logic_vector(31 downto 0);
		sync_in					: in std_logic;
		
		dst_mac_address		: out std_logic_vector(47 downto 0);
		arp_mac_address		: out std_logic_vector(47 downto 0);
		arp_ip_address			: out std_logic_vector(31 downto 0);
		send_arp_response		: out std_logic;
		icmp_dst_mac			: out std_logic_vector(47 downto 0);
		icmp_dst_ip 			: out std_logic_vector(31 downto 0);
		icmp_id					: out std_logic_vector(15 downto 0);
		icmp_sequence			: out std_logic_vector(15 downto 0);
		send_icmp_response	: out std_logic;
		udp_payload				: out std_logic_vector(31 downto 0);
		ram_read_address		: out unsigned(10 downto 0)
	);
end entity;

architecture Behavioral of ethernet_packet_parser is
	type t_SM_PacketParser is (s_Idle, s_ReadIpType, s_ProcessUdpPacket, s_ProcessIcmpPacket, s_ProcessArpRequest, s_ProcessArpResponse, s_UnexpectedPacket, s_Done);
	signal s_SM_PacketParser : t_SM_PacketParser := s_Idle;

	signal byte_counter			: integer range 0 to 1500 := 0;
	
	signal zsync_in				: std_logic;
	
	signal pkt_icmp_src_ip 		: std_logic_vector(31 downto 0);
	signal pkt_icmp_dst_ip 		: std_logic_vector(31 downto 0);
	signal pkt_icmp_type 		: std_logic_vector(7 downto 0);
	signal pkt_icmp_id			: std_logic_vector(15 downto 0);
	signal pkt_icmp_sequence	: std_logic_vector(15 downto 0);
begin
	process (clk)
	begin
		if (rising_edge(clk)) then
			-- sync_in comes from 25MHz domain when in 100Mbps mode, so we have to check for rising edge
			zsync_in <= sync_in;
			
			if ((sync_in = '1') and (zsync_in = '0') and (s_SM_PacketParser = s_Idle)) then
				-- a new frame has arrived
				byte_counter <= 0;
				send_arp_response <= '0';
				send_icmp_response <= '0';
				
				-- check packet type
				if (pkt_type = x"0800") then
					-- we received IP packet
					if (ip_type = x"01") then
						-- we received an ICMP packet
						ram_read_address <= to_unsigned(26, 11); -- load ram-pointer to first byte of source-ip-address
						s_SM_PacketParser <= s_ProcessIcmpPacket;
					elsif (ip_type = x"06") then
						-- we received an TCP packet
						-- at the moment we are not supporting TCP-packets in this design
						s_SM_PacketParser <= s_UnexpectedPacket;
					elsif (ip_type = x"11") then
						-- we received an UDP packet
						ram_read_address <= to_unsigned(42, 11); -- load ram-pointer to first payload-byte
						s_SM_PacketParser <= s_ProcessUdpPacket;
					else
						-- no UDP packet
						s_SM_PacketParser <= s_UnexpectedPacket;
					end if;

				elsif (pkt_type = x"0806") then
					-- we received ARP packet
					
					-- check type of ART packet (opcode)
					if (arp_type = x"0001") then
						-- we received an ARP request
						s_SM_PacketParser <= s_ProcessArpRequest;
					elsif (arp_type = x"0002") then
						-- we received an ARP response
						s_SM_PacketParser <= s_ProcessArpResponse;
					else
						-- we received unsupported packet
						s_SM_PacketParser <= s_UnexpectedPacket;
					end if;
				else
					-- we received unsupported packet
					s_SM_PacketParser <= s_UnexpectedPacket;
				end if;
				
			elsif (s_SM_PacketParser = s_ProcessUdpPacket) then
				-- do something with the new data
				-- udp_src_port
				-- udp_dst_port
				-- udp_length
				
				--if (byte_counter < (udp_length - 8)) then
				if (byte_counter < 4) then -- just read the first 4 bytes
					--udp_payload((byte_counter + 1) * 8 - 1 downto (byte_counter * 8)) <= ram_data;
					udp_payload(31 - (byte_counter * 8) downto 24 - (byte_counter * 8)) <= ram_data;
					ram_read_address <= to_unsigned(43 + byte_counter, 11); -- load next payload-byte
				else
					-- we've read the payload-data and finished the work
					s_SM_PacketParser <= s_Done;
				end if;
				
				byte_counter <= byte_counter + 1;

			elsif (s_SM_PacketParser = s_ProcessIcmpPacket) then
				-- we have to load 4 bytes for source-ip, 4 bytes for destination-ip
				-- and two bytes for the ICMP-type. We ignore the "CODE"-word and CRC for now
				if (byte_counter < 4) then -- read source-ip
					pkt_icmp_src_ip(31 - (byte_counter * 8) downto 24 - (byte_counter * 8)) <= ram_data;
				elsif (byte_counter < 8) then -- read destination-ip
					pkt_icmp_dst_ip(31 - ((byte_counter - 4) * 8) downto 24 - ((byte_counter - 4) * 8)) <= ram_data;
				elsif (byte_counter = 8) then -- read ICMP-type
					pkt_icmp_type(7 downto 0) <= ram_data;
				elsif (byte_counter < 12) then
					-- ignore ICMP-code and 2 bytes of checksum
					-- byte_counter = 9
					-- byte_counter = 10
					-- byte_counter = 11
				elsif (byte_counter < 14) then
					-- byte_counter = 12..13
					-- read ID
					-- values, if ICMP-packet
					pkt_icmp_id(15 - ((byte_counter - 12) * 8) downto 8 - ((byte_counter - 12) * 8)) <= ram_data;
				elsif (byte_counter < 16) then
					-- byte_counter = 14..15
					-- read sequence
					pkt_icmp_sequence(15 - ((byte_counter - 14) * 8) downto 8 - ((byte_counter - 14) * 8)) <= ram_data;
				elsif (byte_counter = 16) then
					if (pkt_icmp_type = x"08") then
						-- we got a PING-Request. Send a PONG back to the source as destination
						icmp_dst_mac <= pkt_src_mac;
						icmp_dst_ip <= pkt_icmp_src_ip;
						icmp_id <= pkt_icmp_id;
						icmp_sequence <= pkt_icmp_sequence;
						send_icmp_response <= '1';
					end if;
				elsif (byte_counter > 26) then
					-- disable signal after 10 clocks = 125MHz / 10 = 12.5MHz
				
					send_icmp_response <= '0';
					s_SM_PacketParser <= s_Done;
				end if;
				
				ram_read_address <= to_unsigned(27 + byte_counter, 11); -- load next payload-byte
				byte_counter <= byte_counter + 1;

			elsif (s_SM_PacketParser = s_ProcessArpRequest) then
				-- accept broadcast-message or to our specific MAC-address and check if the IP is ours
				if (((pkt_dst_mac = x"ffffffffffff") or (pkt_dst_mac = mac_address)) and (arp_dst_ip = ip_address)) then
					if (byte_counter = 0) then
						arp_mac_address <= pkt_src_mac;
						arp_ip_address <= arp_src_ip;
							
						-- rise arp-response-flag for 10 clocks = 125MHz / 10 = 12.5MHz
						-- so that arp-sender can recognize this signal
						send_arp_response <= '1';
					elsif (byte_counter > 10) then
						byte_counter <= 0;
						send_arp_response <= '0';

						s_SM_PacketParser <= s_Done;
					end if;

					byte_counter <= byte_counter + 1;
				else
					-- this packet is not for us
					s_SM_PacketParser <= s_Done;
				end if;

			elsif (s_SM_PacketParser = s_ProcessArpResponse) then
				-- check if this ARP-response is for us
				-- we are not evaluating the MAC-address within ARP-packet
				if ((pkt_dst_mac = mac_address) and (arp_src_ip = dst_ip_address) and (arp_dst_ip = ip_address)) then
					-- the ARP-response came from the destination-IP we are using
					-- and it was sent to our MAC- and IP-Address, so we can use this packet
					dst_mac_address <= pkt_src_mac; -- use the source-MAC-Address as the future destination-MAC-Address
				end if;
				
				s_SM_PacketParser <= s_Done;
			
			elsif (s_SM_PacketParser = s_UnexpectedPacket) then
				-- raise some errors or do other things here
			
				s_SM_PacketParser <= s_Idle;

			elsif (s_SM_PacketParser = s_Done) then
			
				s_SM_PacketParser <= s_Idle;
			
			end if;
		end if;
	end process;
end Behavioral;