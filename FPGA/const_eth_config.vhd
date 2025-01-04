library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

entity const_eth_config is
	generic
	(
		MAC0		: integer := 0;   -- AA = 00 = demo MAC-Address from Intel Triple Speed Ethernet example
		MAC1		: integer := 28;  -- BB = 1c
		MAC2		: integer := 35;  -- CC = 23
		MAC3		: integer := 23;  -- DD = 17
		MAC4		: integer := 74;  -- EE = 4a
		MAC5		: integer := 203; -- FF = cb
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
	-- MAC-Addresses like AA-BB-CC-DD-EE-FF will be stored in this manner: 0xaabbccddeeff, so MSB contains AA, LSB contains FF
	-- mac_address <= x"001c23174acb"; -- demo MAC-Address from Intel Triple Speed Ethernet example
	mac_address <= std_logic_vector(to_unsigned(MAC0, 8)) & std_logic_vector(to_unsigned(MAC1, 8)) & std_logic_vector(to_unsigned(MAC2, 8)) & std_logic_vector(to_unsigned(MAC3, 8)) & std_logic_vector(to_unsigned(MAC4, 8)) & std_logic_vector(to_unsigned(MAC5, 8));

	-- IP-Addresses like 192.168.0.1 will be stored in this manner: 0xc0a80001, so MSB contains 192, LSB contains 1
	ip_address <= std_logic_vector(to_unsigned(IP0, 8)) & std_logic_vector(to_unsigned(IP1, 8)) & std_logic_vector(to_unsigned(IP2, 8)) & std_logic_vector(to_unsigned(IP3, 8));
	dst_ip_address <= std_logic_vector(to_unsigned(DestIP0, 8)) & std_logic_vector(to_unsigned(DestIP1, 8)) & std_logic_vector(to_unsigned(DestIP2, 8)) & std_logic_vector(to_unsigned(DestIP3, 8));

	src_udp_port <= to_unsigned(SrcPort, 16);
	dst_udp_port <= to_unsigned(DestPort, 16);
end Behavioral;