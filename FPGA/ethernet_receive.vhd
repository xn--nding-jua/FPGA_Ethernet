-- Ethernet Packet Receiver
-- (c) 2025 Dr.-Ing. Christian Noeding
-- christian@noeding-online.de
-- Released under GNU General Public License v3
-- Source: https://www.github.com/xn--nding-jua/aes50
--
-- This file contains an ethernet-packet-receiver to receives individual bytes from a FIFO.

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity ethernet_receive is 
	port
	(
		clk			: in std_logic;
		rx_data		: in std_logic_vector(7 downto 0); -- data-octet
		rx_eop		: in std_logic; -- end of packet
		rx_err		: in std_logic_vector(5 downto 0);
		rx_sop		: in std_logic; -- start of packet (we are ignoring this as we wait until we have the FIFO filled with a full frame
		rx_valid		: in std_logic; -- valid

		ram_addr		: out unsigned(10 downto 0); -- 11 bit to store one full fifo
		ram_data		: out std_logic_vector(7 downto 0);
		ram_write	: out std_logic;
		rx_clock		: out std_logic; -- read clock
		rx_rdy		: out std_logic -- ready
	);
end entity;

architecture Behavioral of ethernet_receive is
	type t_SM_Ethernet is (s_Idle, s_Validate, s_Read, s_End);
	signal s_SM_Ethernet 	: t_SM_Ethernet := s_Idle;
begin
	process (clk)
	begin
		if (rising_edge(clk)) then
			-- wait until a full valid packet has been received
			if ((rx_eop = '1') and (s_SM_Ethernet = s_Idle)) then
		
				s_SM_Ethernet <= s_Validate;
			elsif s_SM_Ethernet = s_Validate then
				-- check if rx_valid = '1'
			
				s_SM_Ethernet <= s_Read;
			elsif s_SM_Ethernet = s_Read then
				-- read all bytes in FIFO into RAM
				
				s_SM_Ethernet <= s_End;
			elsif s_SM_Ethernet = s_End then
				-- start processing of data in RAM
			
				s_SM_Ethernet <= s_Idle;
			end if;
		end if;
	end process;
end Behavioral;