-- Ethernet Control
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

entity ethernet_control is 
	port
	(
		clk			: in std_logic;
		eth_rdy		: in std_logic;
		read_data	: in std_logic_vector(31 downto 0);
		wait_rqst	: in std_logic;

		read			: out std_logic;
		write_data	: out std_logic_vector(31 downto 0);
		write			: out std_logic;
		address		: out std_logic_vector(7 downto 0);
		rev			: out std_logic_vector(31 downto 0)
	);
end entity;

architecture Behavioral of ethernet_control is
	type t_SM_Ethernet is (s_Init, s_PhyAddr, s_WaitPhyAddr, s_DisableRxTx, s_WaitDisableRxTx, s_setMAC0, s_WaitMAC0, s_setMAC1, s_WaitMAC1, s_SoftRst, s_WaitSoftRst, s_EnableRxTx, s_WaitEnableRxTx, s_ReadRev, s_WaitReadRev, s_Done);
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
					s_SM_Ethernet <= s_PhyAddr;
				end if;
			elsif s_SM_Ethernet = s_PhyAddr then
				address <= x"0f";
				write_data <= x"00000001";
				write <= '1';
				counter <= 0;
				
				s_SM_Ethernet <= s_WaitPhyAddr;
			
			elsif s_SM_Ethernet = s_WaitPhyAddr then 
				-- wait until waitrequest is 0
				if (wait_rqst = '0') then
					write <= '0';
					s_SM_Ethernet <= s_DisableRxTx;
				end if;

			elsif s_SM_Ethernet = s_DisableRxTx then
				address <= x"02";
				write_data <= x"00800220"; -- 00000000100000000000001000100000, RxTx disabled, Source-MAC insert
				write <= '1';
				counter <= 0;
				
				s_SM_Ethernet <= s_WaitDisableRxTx;
			
			elsif s_SM_Ethernet = s_WaitDisableRxTx then 
				-- wait until waitrequest is 0
				if (wait_rqst = '0') then
					write <= '0';
					s_SM_Ethernet <= s_setMAC0;
				end if;

			elsif s_SM_Ethernet = s_setMAC0 then 
				address <= x"03";
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
				address <= x"04";
				write_data <= x"0000cb4a"; -- set Source MAC-Address to 00:1c:23:17:4a:cb
				write <= '1';

				s_SM_Ethernet <= s_WaitMAC1;

			elsif s_SM_Ethernet = s_WaitMAC1 then 
				-- wait until waitrequest is 0
				if (wait_rqst = '0') then
					write <= '0';
					s_SM_Ethernet <= s_SoftRst;
				end if;
				
			elsif s_SM_Ethernet = s_SoftRst then 
				address <= x"02";
				write_data <= x"00802220"; -- 100000000010001000100000, RxTx disabled, Source-MAC insert, SoftReset
				write <= '1';

				s_SM_Ethernet <= s_WaitSoftRst;

			elsif s_SM_Ethernet = s_WaitSoftRst then 
				-- wait until waitrequest is 0
				if (wait_rqst = '0') then
					write <= '0';
					s_SM_Ethernet <= s_EnableRxTx;
				end if;
				
			elsif s_SM_Ethernet = s_EnableRxTx then 
				address <= x"02";
				write_data <= x"00800223"; -- 100000000010000000100011, RxTx enabled, Source-MAC insert
				write <= '1';

				s_SM_Ethernet <= s_WaitEnableRxTx;
				
			elsif s_SM_Ethernet = s_WaitEnableRxTx then 
				-- wait until waitrequest is 0
				if (wait_rqst = '0') then
					write <= '0';
					s_SM_Ethernet <= s_ReadRev;
				end if;
				
			elsif s_SM_Ethernet = s_ReadRev then 
				address <= x"0f"; -- 0x00 = revision = 00000113 = 13.1, 0x02 = controlRegister, 0x03/0x04 MAC-Address, 0x0f = mdio-addr0
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