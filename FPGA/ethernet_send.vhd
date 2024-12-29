-- Ethernet Packet Sender
-- (c) 2025 Dr.-Ing. Christian Noeding
-- christian@noeding-online.de
-- Released under GNU General Public License v3
-- Source: https://www.github.com/xn--nding-jua/aes50
--
-- This file contains an ethernet-packet-generator to send individual bytes to a FIFO.
-- It generates the nescessary signals like TX-clock, TX-data, TX-EndOfPacket, etc.

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity ethernet_send is 
	port
	(
		clk		: in std_logic;
		start_in	: in std_logic;
		tx_rdy	: in std_logic;
		ramData	: in std_logic_vector(7 downto 0);

		ramAddr	: out unsigned(10 downto 0);
		tx_clock	: out std_logic; -- write clock
		tx_data	: out std_logic_vector(7 downto 0); -- data-octet
		tx_eop	: out std_logic; -- EndOfPacket
		tx_err	: out std_logic; -- Error
		tx_sop	: out std_logic; -- StartOfPacket
		tx_wren	: out std_logic  -- Valid
	);
end entity;

architecture Behavioral of ethernet_send is
	type t_SM_Ethernet is (s_Idle, s_Header, s_Payload, s_CRC);
	signal s_SM_Ethernet 	: t_SM_Ethernet := s_Idle;
begin
	process (clk)
	begin
		if (rising_edge(clk)) then
			-- wait until we are ready and want to send a new packet
			if ((start_in = '1') and (tx_rdy = '1') and (s_SM_Ethernet = s_Idle)) then

				s_SM_Ethernet <= s_Header;
			elsif s_SM_Ethernet = s_Header then
			
				s_SM_Ethernet <= s_Payload;
			elsif s_SM_Ethernet = s_Payload then
				
				s_SM_Ethernet <= s_CRC;
			elsif s_SM_Ethernet = s_CRC then
			
				s_SM_Ethernet <= s_Idle;
			end if;
		end if;
	end process;
end Behavioral;