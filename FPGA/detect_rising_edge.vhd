-- Detect Rising Edge
-- (c) 2025 Dr.-Ing. Christian Noeding
-- christian@noeding-online.de
-- Released under GNU General Public License v3
-- Source: https://www.github.com/xn--nding-jua/AES50_Transmitter
--
-- This file detects a rising edge and outputs a 1 for a single clock

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity detect_rising_edge is 
	port
	(
		clk		: in std_logic;
		input		: in std_logic;

		rising	: out std_logic;
		falling	: out std_logic
	);
end entity;

architecture Behavioral of detect_rising_edge is
	signal zinput, zzinput	: std_logic;
begin
	detect_edge : process(clk)
	begin
		if rising_edge(clk) then
			zinput <= input;
			zzinput <= zinput;

			if input = '1' and zinput = '0' then
				rising <= '1';
			elsif input = '0' and zinput = '1' then
				falling <= '1';
			else
				rising <= '0';
				falling <= '0';
			end if;
		end if;
	end process;
end Behavioral;