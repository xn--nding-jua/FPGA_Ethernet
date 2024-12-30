-- Ethernet Packet Receiver
-- (c) 2025 Dr.-Ing. Christian Noeding
-- christian@noeding-online.de
-- Released under GNU General Public License v3
-- Source: https://www.github.com/xn--nding-jua/AES50_Transmitter
--
-- This file contains an ethernet-packet-receiver to receives individual bytes from a FIFO.

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity ethernet_receive is 
	port
	(
		rx_clk		: in std_logic;
		rx_data		: in std_logic_vector(7 downto 0); -- data-octet
		rx_eop		: in std_logic; -- end of packet
		rx_err		: in std_logic_vector(4 downto 0);
		rx_sop		: in std_logic; -- start of packet (we are ignoring this as we wait until we have the FIFO filled with a full frame
		rx_valid		: in std_logic; -- valid

		ram_addr		: out unsigned(10 downto 0); -- 11 bit to store one full fifo
		ram_data		: out std_logic_vector(7 downto 0);
		rx_rdy		: out std_logic -- ready
	);
end entity;

architecture Behavioral of ethernet_receive is
	type t_SM_Ethernet is (s_Idle, s_Read);
	signal s_SM_Ethernet 	: t_SM_Ethernet := s_Idle;
	signal ram_ptr : integer range 0 to 2048 := 0; -- we expecting not more than 2^11 bytes
begin
	process (rx_clk)
	begin
		if (falling_edge(rx_clk)) then
			if ((rx_sop = '1') and (rx_valid = '1') and (s_SM_Ethernet = s_Idle)) then
				-- read first byte and start state-machine
				ram_addr <= to_unsigned(0, 11);
				ram_data <= rx_data;
				
				ram_ptr <= 1;
				s_SM_Ethernet <= s_Read;
			elsif (s_SM_Ethernet = s_Read) then
				if (rx_valid = '1') then
					-- still a valid byte
					ram_addr <= to_unsigned(ram_ptr, 11);
					ram_data <= rx_data;

					ram_ptr <= ram_ptr + 1;

					if (rx_eop = '1') then
						s_SM_Ethernet <= s_Idle;
					end if;
				else
					-- not a valid byte
					-- just wait until the eop is reached
				end if;
			end if;
		end if;
	end process;
end Behavioral;