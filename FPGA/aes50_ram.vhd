-- Data-storage for ethernet data
-- (c) 2024 Dr.-Ing. Christian Noeding
-- christian@noeding-online.de
-- Released under GNU General Public License v3
-- Source: https://www.github.com/xn--nding-jua/AES50_Transmitter
--
-- This file contains a RAM-module with asynchronuous read/write
-- from/to the DMX512-data. It stores 512 bytes plus start-byte.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aes50_ram is
	generic(
		lastAddress : integer := 1531
	);
	port(
		rx_clk		: in std_logic;
		
		writeAddr	: in unsigned(10 downto 0); -- 0..1531
		data_in		: in unsigned(7 downto 0); -- 8 bit

		readAddr		: in unsigned(10 downto 0); -- 0..1531
		data_out		: out unsigned(7 downto 0); -- 8 bit

		readDbgAddr	: in unsigned(10 downto 0); -- 0..1531
		dataDbg_out	: out unsigned(7 downto 0) -- 8 bit
	);
end aes50_ram;

architecture Behavioral of aes50_ram is
	type t_ram is array(lastAddress downto 0) of unsigned(7 downto 0);
	signal ram: t_ram;
begin
	-- writing data to ram
	process(rx_clk)
	begin
		if rising_edge(rx_clk) then
			ram(to_integer(writeAddr)) <= data_in;
		end if;
	end process;

	-- continuously outputting data at specified address
	data_out <= ram(to_integer(readAddr));
	dataDbg_out <= ram(to_integer(readDbgAddr));
end Behavioral;
