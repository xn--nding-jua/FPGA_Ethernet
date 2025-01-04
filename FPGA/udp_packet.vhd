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
		tx_enable				: out std_logic;  -- TX valid
		tx_data					: out std_logic_vector(7 downto 0) -- data-octet
	);
end entity;

architecture Behavioral of udp_packet is
	-- Constants
	constant MAC_HEADER_LENGTH		: integer := 14;
	constant IP_HEADER_LENGTH		: integer := 5 * (32 / 8); -- Header length always 20 bytes (5 * 32 bit words)
	constant UDP_HEADER_LENGTH		: integer := 8;
	constant PAYLOAD_LENGTH			: integer := 12;
	constant PACKET_LENGTH			: integer := MAC_HEADER_LENGTH + IP_HEADER_LENGTH + UDP_HEADER_LENGTH + PAYLOAD_LENGTH;

	-- Functions
	function log2(A: integer) return integer is
	begin
		for I in 1 to 30 loop  -- Works for up to 32 bit integers
			if(2**I > A) then return(I-1);  end if;
		end loop;
		return(30);
	end;

	-- Checksum calculation
	signal checksum					: unsigned(15 downto 0) := (others => '0');
	signal checksum16					: unsigned(16 downto 0) := (others => '0');
	signal checksum_word_count		: unsigned(log2(IP_HEADER_LENGTH) - 1 downto 0)  := (others => '0');
	signal calculating_checksum	: std_logic := '0';
	signal calc_new_checksum		: std_logic := '0';

	-- Other signals used in this file
	type t_SM_Ethernet is (s_Idle, s_Start, s_Wait, s_Transmit, s_End);
	signal s_SM_Ethernet				: t_SM_Ethernet := s_Idle;
	signal byte_counter				: integer range 0 to 2048 := 0; -- we expecting not more than 2^11 bytes
	signal packet_counter			: integer range 0 to 65535 := 0;

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
				udp_frame(16) <= x"00"; -- total length: entire packet size in bytes, including header and data. The minimum size is 46 bytes of user data (= 0x2e, header without data) and the maximum is 65,535 bytes
				udp_frame(17) <= x"2e"; -- 0x002e = 46
				udp_frame(18) <= x"00"; -- identification (primarily used for uniquely identifying the group of fragments of a single IP datagram)
				udp_frame(19) <= x"00";
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
				udp_frame(38) <= x"00"; -- length (length of this UDP packet including header and data. Minimum 8 bytes)
				udp_frame(39) <= x"14";
				udp_frame(40) <= x"00"; -- checksum (0 is a valid CRC-value to ignore it)
				udp_frame(41) <= x"00";

				-- UDP PAYLOAD (12 bytes)
				udp_frame(42) <= x"48";
				udp_frame(43) <= x"45";
				udp_frame(44) <= x"4c";
				udp_frame(45) <= x"4c";
				udp_frame(46) <= x"4f";
				udp_frame(47) <= x"20";
				udp_frame(48) <= x"57";
				udp_frame(49) <= x"4f";
				udp_frame(50) <= x"52";
				udp_frame(51) <= x"4c";
				udp_frame(52) <= x"44";
				udp_frame(53) <= x"21";
				
				s_SM_Ethernet <= s_Start;
				
			elsif (s_SM_Ethernet = s_Start) then
				-- wait until MAC is ready again
				if (tx_busy = '0') then
					tx_enable <= '1';
					byte_counter <= 0; -- preload to first byte again
					tx_data <= udp_frame(0);
					calc_new_checksum <= '1'; -- calculate new checksum
					
					-- insert packet_counter to frame
					udp_frame(MAC_HEADER_LENGTH + 4) <= std_logic_vector(to_unsigned(packet_counter, 16))(15 downto 8);
					udp_frame(MAC_HEADER_LENGTH + 5) <= std_logic_vector(to_unsigned(packet_counter, 16))(7 downto 0);

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
					elsif (byte_counter = MAC_HEADER_LENGTH + 8) then
						-- insert CRC checksum into header, when byte_counter is 2 bytes before CRC
						udp_frame(MAC_HEADER_LENGTH + 10) <= std_logic_vector(checksum(15 downto 8)); -- MSB
						udp_frame(MAC_HEADER_LENGTH + 11) <= std_logic_vector(checksum(7 downto 0)); -- LSB
					end if;

					byte_counter <= byte_counter + 1;
				end if;
				
			elsif (s_SM_Ethernet = s_End) then
				tx_enable <= '0';
				tx_data <= "00000000";
				calc_new_checksum <= '0';

				s_SM_Ethernet <= s_Idle;
			end if;
		end if;
	end process;

	-- Checksum-calculation (c) 2012 by Peter A Bennett
	-- Add in the carry for ones complement addition.
	checksum <= checksum16(15 downto 0) + ("000000000000000" & checksum16(16));
	-----------------------------------------------------------------
	HEADER_CHECKSUM : process (tx_clk)
	begin
		if falling_edge(tx_clk) then
			if calc_new_checksum = '1' and calculating_checksum = '0' then
				calculating_checksum <= '1';
				checksum16              <= (others => '0');
				checksum_word_count     <= (others => '0');
			elsif calculating_checksum = '1' and checksum_word_count < IP_HEADER_LENGTH then
				checksum16              <= ('0' & checksum) + ('0' & unsigned(udp_frame(to_integer(MAC_HEADER_LENGTH + checksum_word_count)))); -- offset of 14 bytes for MAC-header
				checksum_word_count     <= checksum_word_count + 1;
			else
				calculating_checksum <= '0';
			end if;
		end if;
	end process HEADER_CHECKSUM;
end Behavioral;
