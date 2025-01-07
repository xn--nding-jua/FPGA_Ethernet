-- UDP Packet Sender
-- (c) 2025 Dr.-Ing. Christian Noeding
-- christian@noeding-online.de
-- Released under GNU General Public License v3
-- Source: https://www.github.com/xn--nding-jua/AES50_Transmitter
--
-- This file contains an ethernet-packet-generator to send individual bytes to a FIFO.
-- It generates the nescessary signals like TX-clock, TX-data, TX-EndOfPacket, etc.
--
-- when not using ARP, set ARP-entry in Windows manually using
-- netsh interface ipv4 add neighbors "Ethernet 1" 192.168.0.42 00-1c-23-17-4a-cb
-- To delete this entry, use the following command:
-- arp -d 192.168.0.42

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity udp_packet is
	port
	(
		src_mac_address		: in std_logic_vector(47 downto 0);
		src_ip_address			: in std_logic_vector(31 downto 0);
		dst_mac_address		: in std_logic_vector(47 downto 0);
		dst_ip_address			: in std_logic_vector(31 downto 0);
		src_udp_port			: in std_logic_vector(15 downto 0);
		dst_udp_port			: in std_logic_vector(15 downto 0);
		frame_start				: in std_logic;
		tx_clk					: in std_logic;
		tx_busy					: in std_logic;
		tx_byte_sent			: in std_logic;
		ramData					: in std_logic_vector(7 downto 0);

		ramAddr					: out unsigned(10 downto 0);
		tx_enable				: out std_logic := '0';  -- TX valid
		tx_data					: out std_logic_vector(7 downto 0) := (others => '0') -- data-octet
	);
end entity;

architecture Behavioral of udp_packet is
	-- Constants
	constant MAC_HEADER_LENGTH			: integer := 14;
	constant IP_HEADER_LENGTH			: integer := 5 * (32 / 8); -- Header length always 20 bytes (5 * 32 bit words)
	constant UDP_PSEUDO_HEADER_LENGTH: integer := 8;
	constant UDP_HEADER_LENGTH			: integer := 8;
	constant UDP_PAYLOAD_LENGTH		: integer := 18;
	constant PACKET_LENGTH				: integer := MAC_HEADER_LENGTH + IP_HEADER_LENGTH + UDP_HEADER_LENGTH + UDP_PAYLOAD_LENGTH;

	-- Checksum calculation
	signal checksum						: unsigned(15 downto 0) := (others => '0');
	signal checksum_tmp					: unsigned(31 downto 0) := (others => '0');
	signal checksum_byte_count			: integer range 0 to IP_HEADER_LENGTH + 2;
	signal calculating_checksum		: std_logic := '0';
	signal calc_new_checksum			: std_logic := '0';

	signal udp_checksum					: unsigned(15 downto 0) := (others => '0');
	signal udp_checksum_tmp				: unsigned(31 downto 0) := (others => '0');
	signal udp_checksum_byte_count	: integer range 0 to UDP_PSEUDO_HEADER_LENGTH + UDP_HEADER_LENGTH + UDP_PAYLOAD_LENGTH + 2;
	signal udp_calculating_checksum	: std_logic := '0';
	signal udp_calc_new_checksum		: std_logic := '0';

	-- Other signals used in this file
	type t_SM_Ethernet is (s_Idle, s_CalcChecksum, s_WaitChecksum, s_Start, s_Wait, s_Transmit, s_End);
	signal s_SM_Ethernet					: t_SM_Ethernet := s_Idle;
	signal byte_counter					: integer range 0 to 1600 := 0; -- one ethernet-frame cannot take more than 1500 bytes + header
	signal packet_counter				: integer range 0 to 65535 := 1;

	type t_ethernet_frame is array (0 to PACKET_LENGTH - 1) of std_logic_vector(7 downto 0);
	signal udp_frame		: t_ethernet_frame;

	signal zframe_start	: std_logic;
begin
	process (tx_clk)
	begin
		if (falling_edge(tx_clk)) then
			zframe_start <= frame_start;

			if ((frame_start = '1') and (zframe_start = '0') and (s_SM_Ethernet = s_Idle)) then
				-- prepare begin of packet
				packet_counter <= packet_counter + 1; -- increment packet counter
				tx_enable <= '0';
				byte_counter <= 0;
				tx_data <= dst_mac_address(47 downto 40);

				-- 7 preamble bytes + SFD will be added by Ethernet-MAC
				
				-- MAC HEADER (14 bytes)
				-- fill MAC-Header with desired values
				udp_frame(0) <= dst_mac_address(47 downto 40); -- MSB contains typical left side of MAC
				udp_frame(1) <= dst_mac_address(39 downto 32);
				udp_frame(2) <= dst_mac_address(31 downto 24);
				udp_frame(3) <= dst_mac_address(23 downto 16);
				udp_frame(4) <= dst_mac_address(15 downto 8);
				udp_frame(5) <= dst_mac_address(7 downto 0);

				udp_frame(6) <= src_mac_address(47 downto 40); -- MSB contains typical left side of MAC
				udp_frame(7) <= src_mac_address(39 downto 32);
				udp_frame(8) <= src_mac_address(31 downto 24);
				udp_frame(9) <= src_mac_address(23 downto 16);
				udp_frame(10) <= src_mac_address(15 downto 8);
				udp_frame(11) <= src_mac_address(7 downto 0);

				-- IP Protocol
				udp_frame(12) <= x"08"; -- type [0x0800 = IP Protocol]
				udp_frame(13) <= x"00";

				-- IP HEADER (20 bytes)
				udp_frame(14) <= x"45"; -- b14 = version (4-bit) | internet header length (4-bit) [Version 4 and header length of 0x05 = 20 bytes]
				udp_frame(15) <= x"00"; -- differentiated services (6-bits) | explicit congestion notification (2-bits)
				udp_frame(16) <= std_logic_vector(to_unsigned(IP_HEADER_LENGTH + UDP_HEADER_LENGTH + UDP_PAYLOAD_LENGTH, 16)(15 downto 8)); -- total length without MAC-header: entire packet size in bytes, including IP-header and payload-data. The minimum size is 46 bytes of user data (= 0x2e, header without data) and the maximum is 65,535 bytes
				udp_frame(17) <= std_logic_vector(to_unsigned(IP_HEADER_LENGTH + UDP_HEADER_LENGTH + UDP_PAYLOAD_LENGTH, 16)(7 downto 0)); -- 20 bytes IP-header + 8 bytes UDP-header + 18 bytes UDP-payload = 46 bytes = 0x002e
				udp_frame(18) <= std_logic_vector(to_unsigned(packet_counter, 16))(15 downto 8); -- identification (primarily used for uniquely identifying the group of fragments of a single IP datagram) [0x0000 will be ignored by windows, so we set the packet_counter to this value in the next step]
				udp_frame(19) <= std_logic_vector(to_unsigned(packet_counter, 16))(7 downto 0);
				udp_frame(20) <= x"00"; -- flags (3-bits) | fragment offsets (13-bits)
				udp_frame(21) <= x"00";
				udp_frame(22) <= x"80"; -- time to live (0x80 = 128)
				udp_frame(23) <= x"11"; -- b23 = protocol (0x01 = ICMP, 0x06 = TCP, 0x11 = UDP)
				udp_frame(24) <= x"00"; -- header checksum (16-bit ones' complement of the ones' complement sum of all 16-bit words in the header)
				udp_frame(25) <= x"00";

				udp_frame(26) <= src_ip_address(31 downto 24); -- MSB contains typical "192"
				udp_frame(27) <= src_ip_address(23 downto 16);
				udp_frame(28) <= src_ip_address(15 downto 8);
				udp_frame(29) <= src_ip_address(7 downto 0);
				
				udp_frame(30) <= dst_ip_address(31 downto 24); -- MSB contains typical "192"
				udp_frame(31) <= dst_ip_address(23 downto 16);
				udp_frame(32) <= dst_ip_address(15 downto 8);
				udp_frame(33) <= dst_ip_address(7 downto 0);
				-- options | padding

				-- UDP HEADER (8 bytes)
				udp_frame(34) <= src_udp_port(15 downto 8);
				udp_frame(35) <= src_udp_port(7 downto 0);
				udp_frame(36) <= dst_udp_port(15 downto 8);
				udp_frame(37) <= dst_udp_port(7 downto 0);
				udp_frame(38) <= std_logic_vector(to_unsigned(UDP_HEADER_LENGTH + UDP_PAYLOAD_LENGTH, 16)(15 downto 8)); -- length (length of this UDP packet including header and data. Minimum 8 bytes)
				udp_frame(39) <= std_logic_vector(to_unsigned(UDP_HEADER_LENGTH + UDP_PAYLOAD_LENGTH, 16)(7 downto 0));
				udp_frame(40) <= x"00"; -- checksum (0 is a valid CRC-value to ignore it)
				udp_frame(41) <= x"00";

				-- UDP PAYLOAD (18 bytes)
				udp_frame(42) <= x"48"; -- H
				udp_frame(43) <= x"45"; -- E
				udp_frame(44) <= x"4c"; -- L
				udp_frame(45) <= x"4c"; -- L
				udp_frame(46) <= x"4f"; -- O
				udp_frame(47) <= x"20"; --  
				udp_frame(48) <= x"57"; -- W
				udp_frame(49) <= x"4f"; -- O
				udp_frame(50) <= x"52"; -- R
				udp_frame(51) <= x"4c"; -- L
				udp_frame(52) <= x"44"; -- D
				udp_frame(53) <= x"21"; -- !
				udp_frame(54) <= x"20"; --  
				udp_frame(55) <= x"30"; -- 0
				udp_frame(56) <= x"31"; -- 1
				udp_frame(57) <= x"32"; -- 2
				udp_frame(58) <= x"33"; -- 3
				udp_frame(59) <= x"34"; -- 4

				calc_new_checksum <= '1'; -- calculate new checksum for IP-HEADER
				udp_calc_new_checksum <= '1'; -- calculate new checksum for udp packet
				
				s_SM_Ethernet <= s_CalcChecksum;
				
			elsif (s_SM_Ethernet = s_CalcChecksum) then
				calc_new_checksum <= '0';
				udp_calc_new_checksum <= '0';

				s_SM_Ethernet <= s_WaitChecksum;
			
			elsif (s_SM_Ethernet = s_WaitChecksum) then
				-- wait until both Checksums are calculated
				if ((calculating_checksum = '0') and (udp_calculating_checksum = '0')) then
					s_SM_Ethernet <= s_Start;
				end if;
				
			elsif (s_SM_Ethernet = s_Start) then
				-- wait until MAC is ready again
				if (tx_busy = '0') then
					udp_frame(MAC_HEADER_LENGTH + 10) <= std_logic_vector(checksum(15 downto 8)); -- MSB
					udp_frame(MAC_HEADER_LENGTH + 11) <= std_logic_vector(checksum(7 downto 0)); -- LSB
					udp_frame(MAC_HEADER_LENGTH + IP_HEADER_LENGTH + 6) <= std_logic_vector(udp_checksum(15 downto 8)); -- MSB
					udp_frame(MAC_HEADER_LENGTH + IP_HEADER_LENGTH + 7) <= std_logic_vector(udp_checksum(7 downto 0)); -- LSB
					
					tx_enable <= '1';
					byte_counter <= 0; -- preload to first byte again
					tx_data <= udp_frame(0);

					s_SM_Ethernet <= s_Transmit;
				end if;
			
			elsif (s_SM_Ethernet = s_Transmit) then
				-- wait until previous byte is sent
				if (tx_byte_sent = '1') then
					-- send next byte and increment byte_counter
					tx_data <= udp_frame(byte_counter);
					
					if (byte_counter = PACKET_LENGTH - 1) then
						-- stop transmitting
						s_SM_Ethernet <= s_End;
					end if;
					
					byte_counter <= byte_counter + 1;
				end if;
				
			elsif (s_SM_Ethernet = s_End) then
				tx_enable <= '0';
				tx_data <= "00000000";

				s_SM_Ethernet <= s_Idle;
			end if;
		end if;
	end process;

	HEADER_CHECKSUM_CALC : process (tx_clk)
		variable Word: std_logic_vector(15 downto 0);
	begin
		if falling_edge(tx_clk) then
			if ((calc_new_checksum = '1') and (calculating_checksum = '0')) then
				calculating_checksum    <= '1';
				checksum_tmp            <= (others => '0');
				checksum_byte_count     <= 0;
			elsif ((calculating_checksum = '1') and (checksum_byte_count < IP_HEADER_LENGTH)) then
				Word                    := udp_frame(MAC_HEADER_LENGTH + checksum_byte_count) & udp_frame(MAC_HEADER_LENGTH + checksum_byte_count + 1);
				checksum_tmp            <= checksum_tmp + resize(unsigned(Word), 32);
				checksum_byte_count     <= checksum_byte_count + 2; -- we are reading two bytes at once
			else
				checksum                <= x"ffff" - (checksum_tmp(15 downto 0) + checksum_tmp(31 downto 16)); -- add carryover above 16th bit to 16-bit CRC
				checksum_byte_count     <= 0;
				calculating_checksum    <= '0';
			end if;
		end if;
	end process HEADER_CHECKSUM_CALC;
	
	UDP_CHECKSUM_CALC : process (tx_clk)
		variable Word: std_logic_vector(15 downto 0);
	begin
		if falling_edge(tx_clk) then
			if ((udp_calc_new_checksum = '1') and (udp_calculating_checksum = '0')) then
				udp_calculating_checksum    <= '1';
				udp_checksum_tmp            <= to_unsigned(17 + UDP_HEADER_LENGTH + UDP_PAYLOAD_LENGTH, 32); -- 0x11 (protocol) + UDP-LENGTH (header+payload)
				udp_checksum_byte_count     <= 0;
			elsif ((udp_calculating_checksum = '1') and (udp_checksum_byte_count < (UDP_PSEUDO_HEADER_LENGTH + UDP_HEADER_LENGTH + UDP_PAYLOAD_LENGTH))) then
				Word                        := udp_frame(MAC_HEADER_LENGTH + IP_HEADER_LENGTH - UDP_PSEUDO_HEADER_LENGTH + udp_checksum_byte_count) & udp_frame(MAC_HEADER_LENGTH + IP_HEADER_LENGTH - UDP_PSEUDO_HEADER_LENGTH + udp_checksum_byte_count + 1);
				udp_checksum_tmp            <= udp_checksum_tmp + resize(unsigned(Word), 32);
				udp_checksum_byte_count     <= udp_checksum_byte_count + 2; -- we are reading two bytes at once
			else
				udp_checksum                <= x"ffff" - (udp_checksum_tmp(15 downto 0) + udp_checksum_tmp(31 downto 16)); -- add carryover above 16th bit to 16-bit CRC
				udp_checksum_byte_count     <= 0;
				udp_calculating_checksum    <= '0';
			end if;
		end if;
	end process UDP_CHECKSUM_CALC;
end Behavioral;
