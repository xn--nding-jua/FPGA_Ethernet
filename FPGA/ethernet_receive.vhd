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
		rx_clk				: in std_logic;
		rx_frame				: in std_logic; -- start of packet (we are ignoring this as we wait until we have the FIFO filled with a full frame
		rx_data				: in std_logic_vector(7 downto 0); -- data-octet
		rx_byte_received	: in std_logic;
		rx_error				: in std_logic;

		ram_addr				: out unsigned(10 downto 0); -- 11 bit to store one full fifo
		ram_data				: out std_logic_vector(7 downto 0);
		rx_byte_count		: out unsigned(10 downto 0);
		frame_rdy			: out std_logic -- ready
	);
end entity;

architecture Behavioral of ethernet_receive is
	type t_SM_Ethernet is (s_Idle, s_Read, s_Done);
	signal s_SM_Ethernet : t_SM_Ethernet := s_Idle;
	signal ram_ptr 		: integer range 0 to 2048 := 0; -- we expecting not more than 2^11 bytes per frame
begin
	process (rx_clk)
	begin
		if (falling_edge(rx_clk)) then
			if (s_SM_Ethernet = s_Idle) then
				if ((rx_frame = '1') and (rx_error = '0')) then
					-- prepare receiving new ethernet-frame into RAM
					ram_ptr <= 0;

					s_SM_Ethernet <= s_Read;
				end if;
				
			elsif (s_SM_Ethernet = s_Read) then
				if (rx_error = '0') then
					if (rx_frame = '1') then
						if (rx_byte_received = '1') then
							-- we received a valid byte
							ram_addr <= to_unsigned(ram_ptr, 11);
							ram_data <= rx_data;

							ram_ptr <= ram_ptr + 1;

						else
							-- data not valid -> just wait until rx_byte_received is reached
							-- during this we keep the values on ram_addr and ram_data
							-- so we can keep the RAM clocked by the rx_clock without a WriteEnable-signal
						end if;
					else
						-- end of frame
						
						-- set signal, that frame in RAM is completed
						rx_byte_count <= to_unsigned(ram_ptr, 11);
						frame_rdy <= '1';
						
						s_SM_Ethernet <= s_Done;
					end if;
				else
					-- an error occured
					s_SM_Ethernet <= s_Done;
				end if;

			elsif (s_SM_Ethernet = s_Done) then
				frame_rdy <= '0';
				
				s_SM_Ethernet <= s_Idle;
				
			end if;
		end if;
	end process;
end Behavioral;