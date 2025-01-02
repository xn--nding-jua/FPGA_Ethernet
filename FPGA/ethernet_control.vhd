-- Ethernet Control for IFI GMACII EthernetMAC
-- (c) 2025 Dr.-Ing. Christian Noeding
-- christian@noeding-online.de
-- Released under GNU General Public License v3
-- Source: https://www.github.com/xn--nding-jua/AES50_Transmitter
--
-- This file contains an ethernet-packet-generator to send individual bytes to a FIFO.
-- It generates the nescessary signals like TX-clock, TX-data, TX-EndOfPacket, etc.

-- Important Address-Locations using Standard buffer-option of GMACII
-- BYTE ADDRESS	DWORD ADDRESS	DESCRIPTION
-- 0x00003f80		0x00000fe0		MAC ID LOW
-- 0x00003f84		0x00000fe1		MAC ID HIGH
-- 0x00003f88		0x00000fe2		MAC IP
-- 0x00003f8c		0x00000fe3		Command/Status/IFG
-- 0x00003f90		0x00000fe4		Transmit Control
-- 0x00003f98		0x00000fe6		Receive Control
-- 0x00003fa0		0x00000fe8		Version
-- 0x00003fc8		0x00000ff2		Receive Source (GMACII)
-- 0x00003fd8		0x00000ff6		Transmit Destination (GMACII)
-- 0x00003fdc		0x00000ff7		Transmit Length
-- 0x00003ff8		0x00000ffe		PHY MANAGER IO
-- 0x00003ffc		0x00000fff		PHY MANAGER MIO
-- 
-- Command/Status/IFG
-- Bit:
-- 0	disable ARP_requests when 1
-- 1	disable ICMP requests when 1
-- 2	disable MCF receive frames when 1
-- 3	disables UDP receive frames when 1
-- 4	disables TCP receive frames when 1
-- 5	accept all types of IP-frames when 1
-- 6	CRC checking off when 1
-- 7	use Multicast ID-IP for SRC filter when 1
-- 8	Ethernet-Speed is 100Mbit when 1
-- 9	length checking off when 1
-- 11..10: 00 = accept UDP/IP, TCP/IP, ICMP, ARP
-- 13..12: 00 = accept broadcast IP, 01 = accept broadcast IP / DST MAC-IP / accept Multicast MAC-IP, 10 = accept broadcast IP / DST MAC-IP / all Multicast MAC-IPs, 11 = accept all MAC-IPs
-- 15..14: 00 = accept broadcast ID / accept DST MAC-ID, 01 = accept broadcast ID / accept DST MAC-ID / accept Multicast MAC-ID, 10 = accept broadcast ID / DST MAC-ID / all Multicast ID, 11 = accept all Multicast ID
--
-- Transmit Control
-- Bit:
-- 0 reset Transmitter when 1
-- 1 enable Transmitter interrupt when 1
-- 2 disable Transmitter start
-- 3 reserved
-- 4 reserved
-- 5 transmitter interrupt pending when 1
-- 6 packet transmitted, ack transmitter, clear with writing 1
-- 7 transmit request running
-- 
-- Receive Control
-- Bit:
-- 0 reset receiver
-- 1 enable receiver interrupt
-- 2 CRC error interrupt enable
-- 3 receivebuffer error interrupt enable
-- 4 CRC error interrupt
-- 5 clear receiver interrupt
-- 6 packet pending, ack receiver
-- 7 ReceiveBuffer interrupt
--
-- Version:
-- 0xaabbccdd	aa = Month, bb = Year, cc = QII, dd = Version
-- 0x04065115 = April, 2006, Quartus II, rev. 5.1+, GMACII rev 1.5

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity ethernet_control is 
	port
	(
		clk			: in std_logic;
		eth_rdy		: in std_logic;
		read_data	: in std_logic_vector(31 downto 0);
		wait_rqst	: in std_logic;

		address		: out std_logic_vector(11 downto 0);
		write_data	: out std_logic_vector(31 downto 0);
		byte_en		: out std_logic_vector(3 downto 0);
		cs				: out std_logic;
		read			: out std_logic;
		write			: out std_logic;
		rev			: out std_logic_vector(31 downto 0)
	);
end entity;

architecture Behavioral of ethernet_control is
	type t_SM_Ethernet is (s_Init, s_setMAC0, s_WaitMAC0, s_setMAC1, s_WaitMAC1, s_setIP, s_WaitIP, s_ControlReg, s_WaitControlReg, s_ReadRev, s_WaitReadRev, s_Done);
	signal s_SM_Ethernet 	: t_SM_Ethernet := s_Init;
	signal counter : integer range 0 to 1000 := 0;
	
	signal flag_read_rev_data : std_logic;
begin
	process (clk)
	begin
		if (rising_edge(clk)) then
			if s_SM_Ethernet = s_Init then
				read <= '0';
				write <= '0';
			
				if (eth_rdy = '1') then
					counter <= counter + 1;
				else
					counter <= 0;
				end if;
				
				-- wait some clocks
				if (counter > 5) then
					byte_en <= "1111";
					s_SM_Ethernet <= s_setMAC0;
				end if;

			elsif s_SM_Ethernet = s_setMAC0 then 
				address <= "111111100000"; -- 0x00000fe0
				write_data <= x"17231c00"; -- set Source MAC-Address to 00:1c:23:17:4a:cb
				write <= '1';

				s_SM_Ethernet <= s_WaitMAC0;

			elsif s_SM_Ethernet = s_WaitMAC0 then 
				-- wait until waitrequest is 0
				if (wait_rqst = '0') then
					write <= '0';
					s_SM_Ethernet <= s_setMAC1;
				end if;
				
			elsif s_SM_Ethernet = s_setMAC1 then 
				address <= "111111100001"; -- 0x00000fe1
				write_data <= x"0000cb4a"; -- set Source MAC-Address to 00:1c:23:17:4a:cb
				write <= '1';

				s_SM_Ethernet <= s_WaitMAC1;

			elsif s_SM_Ethernet = s_WaitMAC1 then 
				-- wait until waitrequest is 0
				if (wait_rqst = '0') then
					write <= '0';
					s_SM_Ethernet <= s_setIP;
				end if;
				
			elsif s_SM_Ethernet = s_setIP then 
				address <= "111111100010"; -- 0x00000fe2
				write_data <= x"c0a82a2b"; -- set IP-Address to 192.168.42.43 = 0xc0a82a2b
				write <= '1';

				s_SM_Ethernet <= s_WaitIP;

			elsif s_SM_Ethernet = s_WaitIP then 
				-- wait until waitrequest is 0
				if (wait_rqst = '0') then
					write <= '0';
					s_SM_Ethernet <= s_ControlReg;
				end if;

			elsif s_SM_Ethernet = s_ControlReg then 
				address <= "111111100011"; -- 0x00000fe3
				write_data <= "00000000000000000000000100000000"; -- bit8	Ethernet-Speed is 100Mbit when 1
				write <= '1';

				s_SM_Ethernet <= s_WaitControlReg;

			elsif s_SM_Ethernet = s_WaitControlReg then 
				-- wait until waitrequest is 0
				if (wait_rqst = '0') then
					write <= '0';
					s_SM_Ethernet <= s_ReadRev;
				end if;
				
			elsif s_SM_Ethernet = s_ReadRev then 
				address <= "111111101000";  -- 0x00000fe8
				read <= '1';
				flag_read_rev_data <= '1';
				s_SM_Ethernet <= s_WaitReadRev;
				
			elsif s_SM_Ethernet = s_WaitReadRev then 
				-- wait until waitrequest is 0
				if (wait_rqst = '0') then
					read <= '0';
					flag_read_rev_data <= '0';
					
					s_SM_Ethernet <= s_Done;
				end if;
				
			elsif s_SM_Ethernet = s_Done then
				-- stay here forever
			end if;
		end if;
		
		if (falling_edge(clk)) then
			if (wait_rqst = '0') then
				if (flag_read_rev_data = '1') then
					rev <= read_data;
				end if;
			end if;
		end if;
	end process;
end Behavioral;