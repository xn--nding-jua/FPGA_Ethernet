-- This file is part of the ethernet_mac project.
--
-- For the full copyright and license information, please read the
-- LICENSE.md file that was distributed with this source code.

-- Utility functions
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

package utility is
	-- Return the reverse of the given vector
	function reverse_vector(vec : in std_ulogic_vector) return std_ulogic_vector;
	-- Return a vector with the bytes in opposite order but the content of the bytes unchanged (e.g. for big/little endian conversion)
	function reverse_bytes(vec : in std_ulogic_vector) return std_ulogic_vector;
	-- Extract a byte out of a vector
	function extract_byte(vec : in std_ulogic_vector; byteno : in natural) return std_ulogic_vector;
	-- Set a byte in a vector
	procedure set_byte(vec : inout std_ulogic_vector; byteno : in natural; value : in std_ulogic_vector(7 downto 0));
end package;

package body utility is
	function reverse_vector(vec : in std_ulogic_vector) return std_ulogic_vector is
		variable result : std_ulogic_vector(vec'range);
		alias rev_vec   : std_ulogic_vector(vec'reverse_range) is vec;
	begin
		for i in rev_vec'range loop
			result(i) := rev_vec(i);
		end loop;
		return result;
	end function;
	
	function reverse_bytes(vec : in std_ulogic_vector) return std_ulogic_vector is
		variable result : std_ulogic_vector(vec'range);
	begin
		assert vec'length mod 8 = 0 report "Vector length must be a multiple of 8 for byte reversal" severity failure;
		assert vec'low = 0 report "Vector must start at 0 for byte reversal" severity failure;
		for byte in 0 to vec'high / 8 loop
			set_byte(result, vec'high / 8 - byte, extract_byte(vec, byte));
		end loop;
		return result;
	end function;

	function extract_byte(vec : in std_ulogic_vector; byteno : in natural) return std_ulogic_vector is
	begin
		-- Support both vector directions
		if vec'ascending then
			--return vec(byteno * 8 to (byteno + 1) * 8 - 1);
			if (byteno = 0) then
				return vec(0 to 7);
			elsif (byteno = 1) then
				return vec(8 to 15);
			elsif (byteno = 2) then
				return vec(16 to 23);
			elsif (byteno = 3) then
				return vec(24 to 31);
			elsif (byteno = 4) then
				return vec(32 to 39);
			else
				return vec(40 to 47);
			end if;
		else
			--return vec((byteno + 1) * 8 - 1 downto byteno * 8);
			if (byteno = 0) then
				return vec(7 downto 0);
			elsif (byteno = 1) then
				return vec(15 downto 8);
			elsif (byteno = 2) then
				return vec(23 downto 16);
			elsif (byteno = 3) then
				return vec(31 downto 24);
			elsif (byteno = 4) then
				return vec(39 downto 32);
			else
				return vec(47 downto 40);
			end if;
		end if;
	end function;
	
	procedure set_byte(vec : inout std_ulogic_vector; byteno : in natural; value : in std_ulogic_vector(7 downto 0)) is
	begin
		-- Support both vector directions
		if vec'ascending then
			vec(byteno * 8 to (byteno + 1) * 8 - 1) := value;
		else
			vec((byteno + 1) * 8 - 1 downto byteno * 8) := value;
		end if;
	end procedure;
end package body;
