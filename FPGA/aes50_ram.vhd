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
		lastAddress : integer := 100 -- more entries will use lots of FPGA-ressources. Better use a dedicated SD-RAM here instead
	);
	port(
		rx_clk			: in std_logic;
		
		writeAddr		: in unsigned(10 downto 0); -- 0..1531
		data_in			: in std_logic_vector(7 downto 0); -- 8 bit

		pkt_dst_mac		: out std_logic_vector(47 downto 0); -- valid for all MAC-packets
		pkt_src_mac		: out std_logic_vector(47 downto 0); -- valid for all MAC-packets
		pkt_type			: out std_logic_vector(15 downto 0); -- valid for all MAC-packets
		arp_type			: out std_logic_vector(15 downto 0); -- only valid for ARP packages
		arp_dst_ip		: out std_logic_vector(31 downto 0); -- only valid for ARP packages
		arp_src_ip		: out std_logic_vector(31 downto 0); -- only valid for ARP packages
		ip_type			: out std_logic_vector(7 downto 0);  -- valid for all IP-packets
		udp_src_port	: out std_logic_vector(15 downto 0);
		udp_dst_port	: out std_logic_vector(15 downto 0);
		udp_length		: out std_logic_vector(15 downto 0);
				
		read0Addr		: in unsigned(10 downto 0); -- 0..1531
		data0_out		: out std_logic_vector(7 downto 0); -- 8 bit

		read1Addr		: in unsigned(10 downto 0); -- 0..1531
		data1_out		: out std_logic_vector(7 downto 0); -- 8 bit

		read2Addr		: in unsigned(10 downto 0); -- 0..1531
		data2_out		: out std_logic_vector(7 downto 0) -- 8 bit
	);
end aes50_ram;

architecture Behavioral of aes50_ram is
	type t_ram is array(lastAddress downto 0) of std_logic_vector(7 downto 0);
	signal ram: t_ram;
begin
	-- writing data to ram
	process(rx_clk)
	begin
		if rising_edge(rx_clk) then
			if (writeAddr <= lastAddress) then
				ram(to_integer(writeAddr)) <= data_in;
			end if;
		end if;
	end process;

	-- continuously outputting data at specified address
	pkt_dst_mac <= ram(0) & ram(1) & ram(2) & ram(3) & ram(4) & ram(5); -- MSB contains typical left side of MAC
	pkt_src_mac <= ram(6) & ram(7) & ram(8) & ram(9) & ram(10) & ram(11); -- MSB contains typical left side of MAC
	pkt_type <= ram(12) & ram(13);
	arp_type <= ram(20) & ram(21);
	arp_src_ip <= ram(28) & ram(29) & ram(30) & ram(31); -- MSB contains typical "192"
	arp_dst_ip <= ram(38) & ram(39) & ram(40) & ram(41); -- MSB contains typical "192"
	ip_type <= ram(23);
	udp_src_port <= ram(34) & ram(35);
	udp_dst_port <= ram(36) & ram(37);
	udp_length <= ram(38) & ram(39);
	
	-- TODO: make this safe when calling addresses above "lastAddress"
	data0_out <= ram(to_integer(read0Addr)); -- output to packet parser
	data1_out <= ram(to_integer(read1Addr)); -- output to packet parser
	data2_out <= ram(to_integer(read2Addr)); -- output to packet parser
end Behavioral;
