-- Data-storage for ethernet data
-- (c) 2024 Dr.-Ing. Christian Noeding
-- christian@noeding-online.de
-- Released under GNU General Public License v3
-- Source: https://www.github.com/xn--nding-jua/X-FBAPE
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
		enable		: in std_logic;
		
		writeAddr	: in unsigned(10 downto 0); -- 0..1531
		data_in		: in unsigned(7 downto 0); -- 8 bit
		write			: in std_logic;

		readAddr		: in unsigned(10 downto 0); -- 0..1531
		data_out		: out unsigned(7 downto 0); -- 8 bit

		readDbgAddr	: in unsigned(10 downto 0); -- 0..1531
		dataDbg_out	: out unsigned(7 downto 0) -- 8 bit
	);
end aes50_ram;

architecture behav of aes50_ram is
	type ram_type is array(lastAddress downto 0) of unsigned(7 downto 0);
	signal tmp_ram: ram_type;
begin
	-- writing data to ram
	process(write)
	begin
		if rising_edge(write) then
			if (enable = '1') then
				tmp_ram(to_integer(writeAddr)) <= data_in;
			end if;
		end if;
	end process;

	-- continuously outputting data at specified address
	data_out <= tmp_ram(to_integer(readAddr));
	dataDbg_out <= tmp_ram(to_integer(readDbgAddr));
end behav;
