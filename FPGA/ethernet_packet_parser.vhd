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
		clk					: in std_logic;

		dst_mac				: in std_logic_vector(47 downto 0); -- valid for all MAC-packets
		src_mac				: in std_logic_vector(47 downto 0); -- valid for all MAC-packets
		packet_type			: in std_logic_vector(15 downto 0); -- valid for all MAC-packets
		arp_type				: in std_logic_vector(15 downto 0); -- only valid for ARP packages
		arp_dst_ip			: in std_logic_vector(31 downto 0); -- only valid for ARP packages
		arp_src_ip			: in std_logic_vector(31 downto 0); -- only valid for ARP packages
		ip_type				: in std_logic_vector(7 downto 0);  -- valid for all IP-packeges
		udp_src_port		: in unsigned(15 downto 0); -- only valid for UDP packages
		udp_dst_port		: in unsigned(15 downto 0); -- only valid for UDP packages
		udp_length			: in unsigned(15 downto 0); -- only valid for UDP packages

		ram_data				: in std_logic_vector(7 downto 0);
		mac_address			: in std_logic_vector(47 downto 0);
		ip_address			: in std_logic_vector(31 downto 0);
		dst_ip_address		: in std_logic_vector(31 downto 0);
		frame_rdy			: in std_logic;
		
		dst_mac_address	: out std_logic_vector(47 downto 0);
		arp_mac_address	: out std_logic_vector(47 downto 0);
		arp_ip_address		: out std_logic_vector(31 downto 0);
		send_arp_response	: out std_logic;
		udp_payload			: out std_logic_vector(31 downto 0);
		ram_read_address	: out unsigned(10 downto 0)
	);
end entity;

architecture Behavioral of ethernet_packet_parser is
	type t_SM_PacketParser is (s_Idle, s_ReadIpType, s_ProcessUdpPacket, s_ProcessArpRequest, s_ProcessArpResponse, s_UnexpectedPacket, s_Done);
	signal s_SM_PacketParser : t_SM_PacketParser := s_Idle;

	signal byte_counter : integer range 0 to 1500 := 0;
	
	signal zframe_rdy	: std_logic;
	signal frame_rdy_pos_edge : std_logic;
begin
	-- frame_rdy comes from 25MHz domain, so we have to check for rising edge
	detect_frame_rdy_pos_edge : process(clk)
	begin
		if rising_edge(clk) then
			zframe_rdy <= frame_rdy;
			if frame_rdy = '1' and zframe_rdy = '0' then
				frame_rdy_pos_edge <= '1';
			else
				frame_rdy_pos_edge <= '0';
			end if;
		end if;
	end process;

	process (clk)
	begin
		if (rising_edge(clk)) then
			if ((frame_rdy_pos_edge = '1') and (s_SM_PacketParser = s_Idle)) then
				-- a new frame has arrived
				byte_counter <= 0;
				
				-- check packet type
				if (packet_type = x"0800") then
					-- we received IP packet
					if (ip_type = x"11") then
						-- we received an UDP packet
						ram_read_address <= to_unsigned(42, 11); -- load ram-pointer to first payload-byte
						s_SM_PacketParser <= s_ProcessUdpPacket;
					else
						-- no UDP packet
						s_SM_PacketParser <= s_UnexpectedPacket;
					end if;

				elsif (packet_type = x"0806") then
					-- we received ARP packet
					
					-- check type of ART packet
					if (arp_type = x"01") then
						-- we received an ARP request
						s_SM_PacketParser <= s_ProcessArpRequest;
					elsif (arp_type = x"02") then
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
					udp_payload((byte_counter + 1) * 8 - 1 downto (byte_counter * 8)) <= ram_data;
					ram_read_address <= to_unsigned(43 + byte_counter, 11); -- load next payload-byte
				else
					-- we've read the payload-data and finished the work
					s_SM_PacketParser <= s_Done;
				end if;
				
				byte_counter <= byte_counter + 1;

			elsif (s_SM_PacketParser = s_ProcessArpRequest) then
				-- check if this is a broadcast-message and if the IP is ours
				if ((dst_mac = x"ffffffffffff") and (arp_dst_ip = ip_address)) then
					if (byte_counter < 11) then
						arp_mac_address <= src_mac;
						arp_ip_address <= arp_src_ip;
							
						-- rise arp-response-flag for 10 clocks = 125MHz / 10 = 12.5MHz
						-- so that arp-sender can recognize this signal
						send_arp_response <= '1';
					else
						byte_counter <= 0;
						send_arp_response <= '1';

						s_SM_PacketParser <= s_Done;
					end if;

					byte_counter <= byte_counter + 1;
				else
					-- this packet is not for us
					s_SM_PacketParser <= s_Done;
				end if;

			elsif (s_SM_PacketParser = s_ProcessArpResponse) then
				-- check if this response is for us (we are not evaluating the MAC-address within ARP-packet)
				if ((dst_mac = mac_address) and (arp_dst_ip = ip_address)) then
					dst_mac_address <= src_mac; -- use the source-MAC-Address as the future destination-MAC-Address
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