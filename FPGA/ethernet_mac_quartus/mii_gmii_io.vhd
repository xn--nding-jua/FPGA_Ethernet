-- This file is part of the ethernet_mac project.
--
-- For the full copyright and license information, please read the
-- LICENSE.md file that was distributed with this source code.
--
-- Device-specific IO setup needed for communicating with the PHY
--
-- Copyright (c) 2015, Philipp Kerling
-- All rights reserved.
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
-- * Redistributions of source code must retain the above copyright notice, this
--   list of conditions and the following disclaimer.
-- 
-- * Redistributions in binary form must reproduce the above copyright notice,
--   this list of conditions and the following disclaimer in the documentation
--   and/or other materials provided with the distribution.
-- 
-- * Neither the name of ethernet\_mac nor the names of its
--   contributors may be used to endorse or promote products derived from
--   this software without specific prior written permission.
-- 
-- * Neither the source code, nor any derivative product, may be used for military
--   purposes.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--

library ieee;
use ieee.std_logic_1164.all;

use work.ethernet_types.all;

entity mii_gmii_io is
	port(
		-- 125 MHz clock input (exact requirements can vary by implementation)
		-- Spartan 6: clock should be unbuffered
		clock_125_i     : in  std_ulogic;

		-- RX and TX clocks
		clock_tx_o      : out std_ulogic;
		clock_rx_o      : out std_ulogic;

		-- Speed selection for clock switch
		speed_select_i  : in  t_ethernet_speed;

		-- Signals connected directly to external ports
		-- MII
		mii_tx_clk_i    : in  std_ulogic;
		mii_tx_en_o     : out std_ulogic;
		mii_txd_o       : out t_ethernet_data;
		mii_rx_clk_i    : in  std_ulogic;
		mii_rx_er_i     : in  std_ulogic;
		mii_rx_dv_i     : in  std_ulogic;
		mii_rxd_i       : in  t_ethernet_data;

		-- GMII
		gmii_gtx_clk_o  : out std_ulogic;

		-- Signals connected to the mii_gmii module
		int_mii_tx_en_i : in  std_ulogic;
		int_mii_txd_i   : in  t_ethernet_data;
		int_mii_rx_er_o : out std_ulogic;
		int_mii_rx_dv_o : out std_ulogic;
		int_mii_rxd_o   : out t_ethernet_data
	);
end entity;

architecture Behavioral of mii_gmii_io is
	signal clock_tx         : std_ulogic := '0';
	signal clock_tx_inv     : std_ulogic := '1';
	signal clock_rx         : std_ulogic := '0';
begin
	-- set tx-clock: switch between 125 Mhz reference clock and MII_TX_CLK for TX process
	with speed_select_i select clock_tx <=
		clock_125_i when SPEED_1000MBPS,
		mii_tx_clk_i when others;
	-- set rx-clock
	clock_rx <= mii_rx_clk_i;
		
	-- output 1000Mbps-clock only when running GMII to reduce switching noise
	with speed_select_i select gmii_gtx_clk_o <=
		clock_tx_inv when SPEED_1000MBPS,
		'0' when others;

	-- output rx/tx-clocks
	clock_tx_o   <= clock_tx;
	clock_tx_inv <= not clock_tx;
	clock_rx_o <= clock_rx;

	process (clock_tx)
	begin
		if rising_edge(clock_tx) then
			-- output data to PHY
			mii_tx_en_o <= int_mii_tx_en_i;
			mii_txd_o <= int_mii_txd_i;
		end if;
	end process;
	
	process (clock_rx)
	begin
		if rising_edge(clock_rx) then
			-- receive data from PHY
			int_mii_rx_dv_o <= mii_rx_dv_i;
			int_mii_rx_er_o <= mii_rx_er_i;
			int_mii_rxd_o <= mii_rxd_i;
		end if;
	end process;
end architecture;
