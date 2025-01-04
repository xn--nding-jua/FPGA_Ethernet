library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

--use work.ethernet_types.all;
--use work.utility.all;

entity const_eth_config is
	generic
	(
		IP0		: integer := 192;
		IP1		: integer := 168;
		IP2		: integer := 0;
		IP3		: integer := 42;
		SrcPort	: integer := 4023;
		DestIP0	: integer := 192;
		DestIP1	: integer := 168;
		DestIP2	: integer := 0;
		DestIP3	: integer := 142;
		DestPort	: integer := 4023
	);
	port
	(
		mac_address		: out std_logic_vector(47 downto 0);
		ip_address		: out std_logic_vector(31 downto 0);
		dst_ip_address	: out std_logic_vector(31 downto 0);
		src_udp_port	: out unsigned(15 downto 0);
		dst_udp_port	: out unsigned(15 downto 0)
	);
end entity;

architecture Behavioral of const_eth_config is
begin
	mac_address <= x"001c23174acb";
	ip_address <= std_logic_vector(to_unsigned(IP0, 8)) & std_logic_vector(to_unsigned(IP1, 8)) & std_logic_vector(to_unsigned(IP2, 8)) & std_logic_vector(to_unsigned(IP3, 8));
	dst_ip_address <= std_logic_vector(to_unsigned(DestIP0, 8)) & std_logic_vector(to_unsigned(DestIP1, 8)) & std_logic_vector(to_unsigned(DestIP2, 8)) & std_logic_vector(to_unsigned(DestIP3, 8));
	src_udp_port <= to_unsigned(SrcPort, 16);
	dst_udp_port <= to_unsigned(DestPort, 16);
end Behavioral;