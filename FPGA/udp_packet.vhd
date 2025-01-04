-- UDP Packet Sender
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
	signal ethernet_frame		: t_ethernet_frame :=
	(
		-- 7 preamble bytes + SFD will be added by Ethernet-MAC
	
		-- MAC HEADER (14 bytes)
		x"00", -- destination MAC address
		x"00",
		x"00",
		x"00",
		x"00",
		x"00",
		x"00", -- source MAC address (set ARP-entry in Windows using "netsh interface ipv4 add neighbors "Ethernet 5" 192.168.42.43 00-1c-23-17-4a-cb") "arp -d 192.168.42.43" entfernt Eintrag wieder
		x"00",
		x"00",
		x"00",
		x"00",
		x"00",
		x"08", -- type [0x0800 = IP]
		x"00",
		
		-- IP HEADER (20 bytes)
		x"45", -- version (4-bit) | internet header length (4-bit) [Version 4 and header length of 0x05 = 20 bytes]
		x"00", -- differentiated services (6-bits) | explicit congestion notification (2-bits)
		x"00", -- total length: entire packet size in bytes, including header and data. The minimum size is 46 bytes (= 0x2e, header without data) and the maximum is 65,535 bytes
		x"2e",
		x"00", -- identification (primarily used for uniquely identifying the group of fragments of a single IP datagram)
		x"00",
		x"00", -- flags (3-bits) | fragment offsets (13-bits)
		x"00",
		x"80", -- time to live (0x80 = 128)
		x"11", -- protocol (0x06 = TCP, 0x11 = UDP)
		x"00", -- header checksum (16-bit ones' complement of the ones' complement sum of all 16-bit words in the header)
		x"00",
		x"00", -- source ip address
		x"00",
		x"00",
		x"00", 
		x"00", -- destination ip address
		x"00",
		x"00",
		x"00",
		-- options | padding
		
		-- UDP HEADER (8 bytes)
		x"00", -- source port
		x"00",
		x"00", -- destination port
		x"00",
		x"00", -- length (length of this UDP packet including header and data. Minimum 8 bytes)
		x"14",
		x"00", -- checksum (0 is a valid CRC-value to ignore it)
		x"00",
		
		-- UDP PAYLOAD (12 bytes)
		x"48", -- Payload 0...1500 bytes HELLO WORLD!
		x"45",
		x"4c",
		x"4c",
		x"4f",
		x"20",
		x"57",
		x"4f",
		x"52",
		x"4c",
		x"44",
		x"21"
		
		-- padding bytes to fill to at least 64 byte will be added by the Ethernet-MAC

		-- 4 CRC32 bytes will be added by the Ethernet-MAC
	);

begin
	process (tx_clk)
	begin
		if (falling_edge(tx_clk)) then
			if ((frame_start = '1') and (s_SM_Ethernet = s_Idle)) then
				-- prepare begin of packet
				packet_counter <= packet_counter + 1; -- increment packet counter
				tx_enable <= '0';
				byte_counter <= 0;
				tx_data <= dst_mac_address(47 downto 40);
				
				-- fill MAC-Header with desired values
				ethernet_frame(0) <= dst_mac_address(47 downto 40);
				ethernet_frame(1) <= dst_mac_address(39 downto 32);
				ethernet_frame(2) <= dst_mac_address(31 downto 24);
				ethernet_frame(3) <= dst_mac_address(23 downto 16);
				ethernet_frame(4) <= dst_mac_address(15 downto 8);
				ethernet_frame(5) <= dst_mac_address(7 downto 0);

				ethernet_frame(6) <= src_mac_address(47 downto 40);
				ethernet_frame(7) <= src_mac_address(39 downto 32);
				ethernet_frame(8) <= src_mac_address(31 downto 24);
				ethernet_frame(9) <= src_mac_address(23 downto 16);
				ethernet_frame(10) <= src_mac_address(15 downto 8);
				ethernet_frame(11) <= src_mac_address(7 downto 0);

				ethernet_frame(26) <= src_ip_address(31 downto 24);
				ethernet_frame(27) <= src_ip_address(23 downto 16);
				ethernet_frame(28) <= src_ip_address(15 downto 8);
				ethernet_frame(29) <= src_ip_address(7 downto 0);
				
				ethernet_frame(30) <= dst_ip_address(31 downto 24);
				ethernet_frame(31) <= dst_ip_address(23 downto 16);
				ethernet_frame(32) <= dst_ip_address(15 downto 8);
				ethernet_frame(33) <= dst_ip_address(7 downto 0);

				ethernet_frame(34) <= src_udp_port(15 downto 8);
				ethernet_frame(35) <= src_udp_port(7 downto 0);
				ethernet_frame(36) <= dst_udp_port(15 downto 8);
				ethernet_frame(37) <= dst_udp_port(7 downto 0);
				
				s_SM_Ethernet <= s_Start;
				
			elsif (s_SM_Ethernet = s_Start) then
				-- wait until MAC is ready again
				if (tx_busy = '0') then
					tx_enable <= '1';
					byte_counter <= 0; -- preload to first byte again
					tx_data <= ethernet_frame(0);
					
					-- insert packet_counter to frame
					ethernet_frame(MAC_HEADER_LENGTH + 4) <= std_logic_vector(to_unsigned(packet_counter, 16))(15 downto 8);
					ethernet_frame(MAC_HEADER_LENGTH + 5) <= std_logic_vector(to_unsigned(packet_counter, 16))(7 downto 0);
					calc_new_checksum <= '1'; -- calculate new checksum

					s_SM_Ethernet <= s_Transmit;
				end if;
			
			elsif (s_SM_Ethernet = s_Transmit) then
				-- wait until previous byte is sent
				if (tx_byte_sent = '1') then
					-- send next byte and increment byte_counter
					tx_data <= ethernet_frame(byte_counter);
					
					if (byte_counter = PACKET_LENGTH - 1) then
						-- stop transmitting
						s_SM_Ethernet <= s_End;
					elsif (byte_counter = MAC_HEADER_LENGTH + 8) then
						-- insert CRC checksum into header, when byte_counter is 2 bytes before CRC
						ethernet_frame(MAC_HEADER_LENGTH + 10) <= std_logic_vector(checksum(15 downto 8)); -- MSB
						ethernet_frame(MAC_HEADER_LENGTH + 11) <= std_logic_vector(checksum(7 downto 0)); -- LSB
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
				checksum16              <= ('0' & checksum) + ('0' & unsigned(ethernet_frame(to_integer(MAC_HEADER_LENGTH + checksum_word_count)))); -- offset of 14 bytes for MAC-header
				checksum_word_count     <= checksum_word_count + 1;
			else
				calculating_checksum <= '0';
			end if;
		end if;
	end process HEADER_CHECKSUM;
end Behavioral;