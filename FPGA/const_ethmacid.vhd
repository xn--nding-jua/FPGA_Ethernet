library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

use work.ethernet_types.all;
use work.utility.all;

entity const_ethmacid is 
	port
	(
		mac_out		: out std_ulogic_vector(47 downto 0)
	);
end entity;

architecture Behavioral of const_ethmacid is
begin
	mac_out <= reverse_bytes(x"001c23174acb"); -- convert 0x001c23174acb into 0xcb4a17231c00
end Behavioral;