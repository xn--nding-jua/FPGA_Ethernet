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
		frame_start				: in std_logic;
		tx_clk					: in std_logic;
		tx_busy					: in std_logic;
		tx_byte_sent			: in std_logic;

		tx_enable				: out std_logic;  -- TX valid
		tx_data					: out std_logic_vector(7 downto 0) -- data-octet
	);
end entity;

architecture Behavioral of icmp_packet is
	-- Constants
	constant MAC_HEADER_LENGTH		: integer := 14;
	constant IP_HEADER_LENGTH		: integer := 5 * (32 / 8); -- Header length always 20 bytes (5 * 32 bit words)
	constant ICMP_LENGTH				: integer := 8;
	constant PAYLOAD_LENGTH			: integer := 0;
	constant PACKET_LENGTH			: integer := MAC_HEADER_LENGTH + IP_HEADER_LENGTH + ICMP_LENGTH + PAYLOAD_LENGTH;

	-- Functions
	function log2(A: integer) return integer is
	begin
		for I in 1 to 30 loop  -- Works for up to 32 bit integers
			if(2**I > A) then return(I-1);  end if;
		end loop;
		return(30);
	end;

	type t_SM_Ethernet is (s_Idle, s_Start, s_Wait, s_Transmit, s_End);
	signal s_SM_Ethernet				: t_SM_Ethernet := s_Idle;
	signal byte_counter				: integer range 0 to 20 := 0; -- ICMP has maximum of 4 bytes + 14 bytes MAC-Header

	-- Checksum calculation
	signal checksum					: unsigned(15 downto 0) := (others => '0');
	signal checksum16					: unsigned(16 downto 0) := (others => '0');
	signal checksum_word_count		: unsigned(log2(IP_HEADER_LENGTH) - 1 downto 0)  := (others => '0');
	signal calculating_checksum	: std_logic := '0';
	signal calc_new_checksum		: std_logic := '0';

	type t_ethernet_frame is array (0 to PACKET_LENGTH - 1) of std_logic_vector(7 downto 0);
	signal icmp_frame : t_ethernet_frame;

	signal zframe_start	: std_logic;
begin
	process (tx_clk)
	begin
		zframe_start <= frame_start;

		if (falling_edge(tx_clk)) then
			if ((frame_start = '1') and (zframe_start = '0') and (s_SM_Ethernet = s_Idle)) then
				-- prepare begin of packet
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
				icmp_frame(16) <= x"00"; -- total length: entire packet size in bytes, including header and data. The minimum size is 46 bytes of user data (= 0x2e, header without data) and the maximum is 65,535 bytes
				icmp_frame(17) <= x"2e"; -- 0x002e = 46 = minimum size with 0-padding
				icmp_frame(18) <= x"00"; -- identification (primarily used for uniquely identifying the group of fragments of a single IP datagram)
				icmp_frame(19) <= x"00";
				icmp_frame(20) <= x"00"; -- flags (3-bits) | fragment offsets (13-bits)
				icmp_frame(21) <= x"00";
				icmp_frame(22) <= x"80"; -- time to live (0x80 = 128)
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
				icmp_frame(38) <= x"00"; -- ICMP Extended Header (4 bytes)
				icmp_frame(39) <= x"00";
				icmp_frame(40) <= x"00";
				icmp_frame(41) <= x"00";
				-- optional: Payload data back to requester

				s_SM_Ethernet <= s_Start;
				
			elsif (s_SM_Ethernet = s_Start) then
				-- wait until MAC is ready again
				if (tx_busy = '0') then
					tx_enable <= '1';
					byte_counter <= 0; -- preload to first byte again
					tx_data <= icmp_frame(0);
					calc_new_checksum <= '1'; -- calculate new checksum
					
					s_SM_Ethernet <= s_Transmit;
				end if;
			
			elsif (s_SM_Ethernet = s_Transmit) then
				-- wait until previous byte is sent
				if (tx_byte_sent = '1') then
					-- send next byte and increment byte_counter
					tx_data <= icmp_frame(byte_counter);
					
					if (byte_counter = PACKET_LENGTH - 1) then
						-- stop transmitting
						s_SM_Ethernet <= s_End;
					elsif (byte_counter = MAC_HEADER_LENGTH + 8) then
						-- insert CRC checksum into header, when byte_counter is 2 bytes before CRC
						icmp_frame(MAC_HEADER_LENGTH + 10) <= std_logic_vector(checksum(15 downto 8)); -- MSB
						icmp_frame(MAC_HEADER_LENGTH + 11) <= std_logic_vector(checksum(7 downto 0)); -- LSB
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
				checksum16              <= ('0' & checksum) + ('0' & unsigned(icmp_frame(to_integer(MAC_HEADER_LENGTH + checksum_word_count)))); -- offset of 14 bytes for MAC-header
				checksum_word_count     <= checksum_word_count + 1;
			else
				calculating_checksum <= '0';
			end if;
		end if;
	end process HEADER_CHECKSUM;
end Behavioral;
