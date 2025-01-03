-- This file is part of the ethernet_mac project.
--
-- For the full copyright and license information, please read the
-- LICENSE.md file that was distributed with this source code.

-- Synchronize a single bit from an arbitrary clock domain
-- into the clock_target domain
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

entity single_signal_synchronizer is
	port(
		clock_target_i : in  std_ulogic;
		-- Asynchronous preset of the output and synchronizer flip-flops
		preset_i       : in  std_ulogic := '0';
		-- Asynchronous signal input
		signal_i       : in  std_ulogic;
		-- Synchronous signal output
		signal_o       : out std_ulogic
	);
end entity;

architecture simple of single_signal_synchronizer is
	signal signal_tmp : std_ulogic := '0';
begin
	process(clock_target_i, preset_i)
	begin
		if preset_i = '1' then
			signal_tmp <= '1';
			signal_o   <= '1';
		elsif rising_edge(clock_target_i) then
			signal_tmp <= signal_i;
			signal_o   <= signal_tmp;
		end if;
	end process;
end architecture;
