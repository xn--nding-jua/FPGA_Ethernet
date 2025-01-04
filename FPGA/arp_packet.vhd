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

entity arp_packet is
	port
	(
		arp_response			: in std_logic; -- 0 = request, 1 = response
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

architecture Behavioral of arp_packet is
	constant PACKET_LENGTH			: integer := 42;

	type t_SM_Ethernet is (s_Idle, s_Start, s_Wait, s_Transmit, s_End);
	signal s_SM_Ethernet				: t_SM_Ethernet := s_Idle;
	signal byte_counter				: integer range 0 to 50 := 0; -- ARP has maximum of 28 bytes + 14 bytes MAC-Header

	type t_ethernet_frame is array (0 to PACKET_LENGTH - 1) of std_logic_vector(7 downto 0);
	signal arp_frame : t_ethernet_frame;

	signal zframe_start	: std_logic;
	signal var_start_frame : std_logic;
begin
	detect_frame_start_pos_edge : process(tx_clk)
	begin
		if falling_edge(tx_clk) then
			zframe_start <= frame_start;
			if frame_start = '1' and zframe_start = '0' then
				var_start_frame <= '1';
			else
				var_start_frame <= '0';
			end if;
		end if;
	end process;

	process (tx_clk)
	begin
		if (falling_edge(tx_clk)) then
			if ((var_start_frame = '1') and (s_SM_Ethernet = s_Idle)) then
				-- prepare begin of packet
				tx_enable <= '0';
				byte_counter <= 0;

				-- source MAC address
				arp_frame(6) <= src_mac_address(47 downto 40);
				arp_frame(7) <= src_mac_address(39 downto 32);
				arp_frame(8) <= src_mac_address(31 downto 24);
				arp_frame(9) <= src_mac_address(23 downto 16);
				arp_frame(10) <= src_mac_address(15 downto 8);
				arp_frame(11) <= src_mac_address(7 downto 0);
				
				arp_frame(12) <= x"08"; -- type [0x0806 = IP ARP Protocol]
				arp_frame(13) <= x"06";
				arp_frame(14) <= x"00"; -- type of hardwareaddress
				arp_frame(15) <= x"01";
				arp_frame(16) <= x"08"; -- type [0x0800 = IP]
				arp_frame(17) <= x"00";
				arp_frame(18) <= x"06"; -- size of MAC address
				arp_frame(19) <= x"04"; -- size of protocol

				-- source MAC address
				arp_frame(22) <= src_mac_address(47 downto 40);
				arp_frame(23) <= src_mac_address(39 downto 32);
				arp_frame(24) <= src_mac_address(31 downto 24);
				arp_frame(25) <= src_mac_address(23 downto 16);
				arp_frame(26) <= src_mac_address(15 downto 8);
				arp_frame(27) <= src_mac_address(7 downto 0);

				-- source ip address
				arp_frame(28) <= src_ip_address(31 downto 24);
				arp_frame(29) <= src_ip_address(23 downto 16);
				arp_frame(30) <= src_ip_address(15 downto 8);
				arp_frame(31) <= src_ip_address(7 downto 0);

				-- destination MAC address
				arp_frame(32) <= dst_mac_address(47 downto 40);
				arp_frame(33) <= dst_mac_address(39 downto 32);
				arp_frame(34) <= dst_mac_address(31 downto 24);
				arp_frame(35) <= dst_mac_address(23 downto 16);
				arp_frame(36) <= dst_mac_address(15 downto 8);
				arp_frame(37) <= dst_mac_address(7 downto 0);

				-- destination ip address
				arp_frame(38) <= dst_ip_address(31 downto 24);
				arp_frame(39) <= dst_ip_address(23 downto 16);
				arp_frame(40) <= dst_ip_address(15 downto 8);
				arp_frame(41) <= dst_ip_address(7 downto 0);

				if (arp_response = '0') then
					tx_data <= x"ff";
					
					-- destination MAC address (Broadcast)
					arp_frame(0) <= x"ff";
					arp_frame(1) <= x"ff";
					arp_frame(2) <= x"ff";
					arp_frame(3) <= x"ff";
					arp_frame(4) <= x"ff";
					arp_frame(5) <= x"ff";

					arp_frame(20) <= x"00"; -- operations (0x0001 = ARP request, 0x0002 = ARP response)
					arp_frame(21) <= x"01";

					-- destination MAC address (Broadcast)
					arp_frame(32) <= x"00";
					arp_frame(33) <= x"00";
					arp_frame(34) <= x"00";
					arp_frame(35) <= x"00";
					arp_frame(36) <= x"00";
					arp_frame(37) <= x"00";
				else
					tx_data <= dst_mac_address(47 downto 40);
					
					-- destination MAC address
					arp_frame(0) <= dst_mac_address(47 downto 40);
					arp_frame(1) <= dst_mac_address(39 downto 32);
					arp_frame(2) <= dst_mac_address(31 downto 24);
					arp_frame(3) <= dst_mac_address(23 downto 16);
					arp_frame(4) <= dst_mac_address(15 downto 8);
					arp_frame(5) <= dst_mac_address(7 downto 0);

					arp_frame(20) <= x"00"; -- operations (0x0001 = ARP request, 0x0002 = ARP response)
					arp_frame(21) <= x"02";

					arp_frame(32) <= dst_mac_address(47 downto 40);
					arp_frame(33) <= dst_mac_address(39 downto 32);
					arp_frame(34) <= dst_mac_address(31 downto 24);
					arp_frame(35) <= dst_mac_address(23 downto 16);
					arp_frame(36) <= dst_mac_address(15 downto 8);
					arp_frame(37) <= dst_mac_address(7 downto 0);
				end if;
				
				s_SM_Ethernet <= s_Start;
				
			elsif (s_SM_Ethernet = s_Start) then
				-- wait until MAC is ready again
				if (tx_busy = '0') then
					tx_enable <= '1';
					byte_counter <= 0; -- preload to first byte again
					tx_data <= arp_frame(0);
					
					s_SM_Ethernet <= s_Transmit;
				end if;
			
			elsif (s_SM_Ethernet = s_Transmit) then
				-- wait until previous byte is sent
				if (tx_byte_sent = '1') then
					-- send next byte and increment byte_counter
					tx_data <= arp_frame(byte_counter);
					
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
end Behavioral;