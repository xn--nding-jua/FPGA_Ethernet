-- ARP Packet Sender
-- (c) 2025 Dr.-Ing. Christian Noeding
-- christian@noeding-online.de
-- Released under GNU General Public License v3
-- Source: https://www.github.com/xn--nding-jua/AES50_Transmitter
--
-- This file contains an ethernet-packet-generator to send individual bytes to a FIFO.
-- It generates the nescessary signals like TX-clock, TX-data, TX-EndOfPacket, etc.

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity icmp_packet is
	port
	(
		src_mac_address		: in std_logic_vector(47 downto 0) := (others => '0');
		src_ip_address			: in std_logic_vector(31 downto 0) := (others => '0');
		dst_mac_address		: in std_logic_vector(47 downto 0) := (others => '0');
		dst_ip_address			: in std_logic_vector(31 downto 0) := (others => '0');
		icmp_id					: in std_logic_vector(15 downto 0);
		icmp_sequence			: in std_logic_vector(15 downto 0);
		frame_start				: in std_logic;
		tx_clk					: in std_logic;
		tx_busy					: in std_logic;
		tx_byte_sent			: in std_logic;

		tx_enable				: out std_logic := '0';  -- TX valid
		tx_data					: out std_logic_vector(7 downto 0) := (others => '0') -- data-octet
	);
end entity;

architecture Behavioral of icmp_packet is
	-- Constants
	constant MAC_HEADER_LENGTH		: integer := 14;
	constant IP_HEADER_LENGTH		: integer := 5 * (32 / 8); -- Header length always 20 bytes (5 * 32 bit words)
	constant ICMP_LENGTH				: integer := 8;
	constant ICMP_PAYLOAD_LENGTH	: integer := 32;
	constant PACKET_LENGTH			: integer := MAC_HEADER_LENGTH + IP_HEADER_LENGTH + ICMP_LENGTH + ICMP_PAYLOAD_LENGTH;

	type t_SM_Ethernet is (s_Idle, s_Start, s_Wait, s_Transmit, s_End);
	signal s_SM_Ethernet					: t_SM_Ethernet := s_Idle;
	signal byte_counter					: integer range 0 to (PACKET_LENGTH + 1);
	signal packet_counter				: integer range 0 to 65535 := 1;

	-- Checksum calculation
	signal checksum						: unsigned(15 downto 0) := (others => '0');
	signal checksum_tmp					: unsigned(31 downto 0) := (others => '0');
	signal checksum_byte_count			: integer range 0 to IP_HEADER_LENGTH + 2;
	signal calculating_checksum		: std_logic := '0';
	signal calc_new_checksum			: std_logic := '0';

	signal icmp_checksum					: unsigned(15 downto 0) := (others => '0');
	signal icmp_checksum_tmp			: unsigned(31 downto 0) := (others => '0'); -- enough headroom for longer messages
	signal icmp_checksum_byte_count	: integer range 0 to ICMP_PAYLOAD_LENGTH + 2;
	signal icmp_calculating_checksum	: std_logic := '0';
	signal icmp_calc_new_checksum		: std_logic := '0';

	type t_ethernet_frame is array (0 to PACKET_LENGTH - 1) of std_logic_vector(7 downto 0);
	signal icmp_frame : t_ethernet_frame;

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
				-- destination MAC address
				icmp_frame(0) <= dst_mac_address(47 downto 40); -- MSB contains typical left side of MAC
				icmp_frame(1) <= dst_mac_address(39 downto 32);
				icmp_frame(2) <= dst_mac_address(31 downto 24);
				icmp_frame(3) <= dst_mac_address(23 downto 16);
				icmp_frame(4) <= dst_mac_address(15 downto 8);
				icmp_frame(5) <= dst_mac_address(7 downto 0);

				-- source MAC address
				icmp_frame(6) <= src_mac_address(47 downto 40); -- MSB contains typical left side of MAC
				icmp_frame(7) <= src_mac_address(39 downto 32);
				icmp_frame(8) <= src_mac_address(31 downto 24);
				icmp_frame(9) <= src_mac_address(23 downto 16);
				icmp_frame(10) <= src_mac_address(15 downto 8);
				icmp_frame(11) <= src_mac_address(7 downto 0);

				-- IP Protocol
				icmp_frame(12) <= x"08"; -- type [0x0800 = IP Protocol]
				icmp_frame(13) <= x"00";
				
				-- IP HEADER (20 bytes)
				icmp_frame(14) <= x"45"; -- b14 = version (4-bit) | internet header length (4-bit) [Version 4 and header length of 0x05 = 20 bytes]
				icmp_frame(15) <= x"00"; -- differentiated services (6-bits) | explicit congestion notification (2-bits)
				icmp_frame(16) <= std_logic_vector(to_unsigned(IP_HEADER_LENGTH + ICMP_LENGTH + ICMP_PAYLOAD_LENGTH, 16)(15 downto 8)); -- total length without MAC-header: entire packet size in bytes, including IP-header and payload-data. The minimum size is 46 bytes of user data (= 0x2e, header without data) and the maximum is 65,535 bytes
				icmp_frame(17) <= std_logic_vector(to_unsigned(IP_HEADER_LENGTH + ICMP_LENGTH + ICMP_PAYLOAD_LENGTH, 16)(7 downto 0)); -- 20 bytes IP-header + 8 bytes ICMP-header + 32 bytes ICMP-payload = 60 bytes = 0x003c
				icmp_frame(18) <= std_logic_vector(to_unsigned(packet_counter, 16))(15 downto 8); -- identification (primarily used for uniquely identifying the group of fragments of a single IP datagram) [0x0000 will be ignored by windows, so we set the packet_counter to this value in the next step]
				icmp_frame(19) <= std_logic_vector(to_unsigned(packet_counter, 16))(7 downto 0);
				icmp_frame(20) <= x"00"; -- flags (3-bits) | fragment offsets (13-bits)
				icmp_frame(21) <= x"00";
				icmp_frame(22) <= x"40"; -- time to live (0x40 = 64)
				icmp_frame(23) <= x"01"; -- b23 = protocol (0x01 = ICMP, 0x06 = TCP, 0x11 = UDP)
				icmp_frame(24) <= x"00"; -- header checksum (16-bit ones' complement of the ones' complement sum of all 16-bit words in the header)
				icmp_frame(25) <= x"00";

				icmp_frame(26) <= src_ip_address(31 downto 24); -- MSB contains typical "192"
				icmp_frame(27) <= src_ip_address(23 downto 16);
				icmp_frame(28) <= src_ip_address(15 downto 8);
				icmp_frame(29) <= src_ip_address(7 downto 0);

				icmp_frame(30) <= dst_ip_address(31 downto 24); -- MSB contains typical "192"
				icmp_frame(31) <= dst_ip_address(23 downto 16);
				icmp_frame(32) <= dst_ip_address(15 downto 8);
				icmp_frame(33) <= dst_ip_address(7 downto 0);
				-- options | padding

				-- ICMP HEADER
				icmp_frame(34) <= x"00"; -- b34 = ICMP type (0x00 = PING Response, 0x08 = PING Request)
				icmp_frame(35) <= x"00"; -- Code
				icmp_frame(36) <= x"00"; -- ICMP checksum (CRC16, 2 bytes)
				icmp_frame(37) <= x"00";
				icmp_frame(38) <= icmp_id(15 downto 8); -- ICMP-ID (2 bytes)
				icmp_frame(39) <= icmp_id(7 downto 0);
				icmp_frame(40) <= icmp_sequence(15 downto 8); -- ICMP Sequence (2 bytes)
				icmp_frame(41) <= icmp_sequence(7 downto 0);
				
				-- Payload data back to requester
				icmp_frame(42) <= x"61"; -- a
				icmp_frame(43) <= x"62"; -- b
				icmp_frame(44) <= x"63"; -- c
				icmp_frame(45) <= x"64"; -- d
				icmp_frame(46) <= x"65"; -- e
				icmp_frame(47) <= x"66"; -- f
				icmp_frame(48) <= x"67"; -- g
				icmp_frame(49) <= x"68"; -- h
				icmp_frame(50) <= x"69"; -- i
				icmp_frame(51) <= x"6a"; -- j
				icmp_frame(52) <= x"6b"; -- k
				icmp_frame(53) <= x"6c"; -- l
				icmp_frame(54) <= x"6d"; -- m
				icmp_frame(55) <= x"6e"; -- n
				icmp_frame(56) <= x"6f"; -- o
				icmp_frame(57) <= x"70"; -- p
				icmp_frame(58) <= x"71"; -- q
				icmp_frame(59) <= x"72"; -- r
				icmp_frame(60) <= x"73"; -- s
				icmp_frame(61) <= x"74"; -- t
				icmp_frame(62) <= x"75"; -- u
				icmp_frame(63) <= x"76"; -- v
				icmp_frame(64) <= x"77"; -- w
				icmp_frame(65) <= x"61"; -- a
				icmp_frame(66) <= x"62"; -- b
				icmp_frame(67) <= x"63"; -- c
				icmp_frame(68) <= x"64"; -- d
				icmp_frame(69) <= x"65"; -- e
				icmp_frame(70) <= x"66"; -- f
				icmp_frame(71) <= x"67"; -- g
				icmp_frame(72) <= x"68"; -- h
				icmp_frame(73) <= x"69"; -- i

				calc_new_checksum <= '1'; -- calculate new checksum for IP-HEADER
				icmp_calc_new_checksum <= '1'; -- calculate new checksum for ICMP-Part

				s_SM_Ethernet <= s_Start;
				
			elsif (s_SM_Ethernet = s_Start) then
				calc_new_checksum <= '0';
				icmp_calc_new_checksum <= '0';

				-- wait until MAC is ready again
				if (tx_busy = '0') then
					tx_enable <= '1';
					byte_counter <= 0; -- preload to first byte again
					tx_data <= icmp_frame(0);

					s_SM_Ethernet <= s_Transmit;
				end if;
			
			elsif (s_SM_Ethernet = s_Transmit) then
				-- insert CRC checksum into header when ready
				if (calculating_checksum = '0') then
					icmp_frame(MAC_HEADER_LENGTH + 10) <= std_logic_vector(checksum(15 downto 8)); -- MSB
					icmp_frame(MAC_HEADER_LENGTH + 11) <= std_logic_vector(checksum(7 downto 0)); -- LSB
				end if;
				
				-- insert CRC checksum into ICMP-Packet when ready
				if (icmp_calculating_checksum = '0') then
					icmp_frame(MAC_HEADER_LENGTH + IP_HEADER_LENGTH + 2) <= std_logic_vector(icmp_checksum(15 downto 8)); -- MSB
					icmp_frame(MAC_HEADER_LENGTH + IP_HEADER_LENGTH + 3) <= std_logic_vector(icmp_checksum(7 downto 0)); -- LSB
				end if;

				-- wait until previous byte is sent
				if (tx_byte_sent = '1') then
					-- send next byte and increment byte_counter
					tx_data <= icmp_frame(byte_counter);
					
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
				Word                    := icmp_frame(MAC_HEADER_LENGTH + checksum_byte_count) & icmp_frame(MAC_HEADER_LENGTH + checksum_byte_count + 1);
				checksum_tmp            <= checksum_tmp + resize(unsigned(Word), 32);
				checksum_byte_count     <= checksum_byte_count + 2; -- we are reading two bytes at once
			else
				checksum                <= x"ffff" - (checksum_tmp(15 downto 0) + checksum_tmp(31 downto 16)); -- add carryover above 16th bit to 16-bit CRC
				checksum_byte_count     <= 0;
				calculating_checksum    <= '0';
			end if;
		end if;
	end process HEADER_CHECKSUM_CALC;

	ICMP_CHECKSUM_CALC : process (tx_clk)
		variable Word: std_logic_vector(15 downto 0);
	begin
		if falling_edge(tx_clk) then
			if ((icmp_calc_new_checksum = '1') and (icmp_calculating_checksum = '0')) then
				icmp_calculating_checksum    <= '1';
				icmp_checksum_tmp            <= resize(unsigned(icmp_sequence(15 downto 0)), 32) + resize(unsigned(icmp_id(15 downto 0)), 32);
				icmp_checksum_byte_count     <= 0;
			elsif ((icmp_calculating_checksum = '1') and (icmp_checksum_byte_count < ICMP_PAYLOAD_LENGTH)) then
				Word                         := icmp_frame(MAC_HEADER_LENGTH + IP_HEADER_LENGTH + ICMP_LENGTH + icmp_checksum_byte_count) & icmp_frame(MAC_HEADER_LENGTH + IP_HEADER_LENGTH + ICMP_LENGTH + icmp_checksum_byte_count + 1);
				icmp_checksum_tmp            <= icmp_checksum_tmp + resize(unsigned(Word), 32);
				icmp_checksum_byte_count     <= icmp_checksum_byte_count + 2; -- we are reading two bytes at once
			else
				icmp_checksum                <= x"ffff" - (icmp_checksum_tmp(15 downto 0) + icmp_checksum_tmp(31 downto 16)); -- add carryover above 16th bit to 16-bit CRC
				icmp_checksum_byte_count     <= 0;
				icmp_calculating_checksum    <= '0';
			end if;
		end if;
	end process ICMP_CHECKSUM_CALC;
end Behavioral;
