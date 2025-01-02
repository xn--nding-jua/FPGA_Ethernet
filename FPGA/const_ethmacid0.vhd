-- megafunction wizard: %LPM_CONSTANT%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: LPM_CONSTANT 

-- ============================================================
-- File Name: const_ethmacid0.vhd
-- Megafunction Name(s):
-- 			LPM_CONSTANT
--
-- Simulation Library Files(s):
-- 			
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 13.1.0 Build 162 10/23/2013 SJ Full Version
-- ************************************************************


--Copyright (C) 1991-2013 Altera Corporation
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, Altera MegaCore Function License 
--Agreement, or other applicable license agreement, including, 
--without limitation, that your use is for the sole purpose of 
--programming logic devices manufactured by Altera and sold by 
--Altera or its authorized distributors.  Please refer to the 
--applicable agreement for further details.


--lpm_constant CBX_AUTO_BLACKBOX="ALL" ENABLE_RUNTIME_MOD="NO" LPM_CVALUE=000023174ACB LPM_WIDTH=48 result
--VERSION_BEGIN 13.1 cbx_lpm_constant 2013:10:23:18:05:48:SJ cbx_mgl 2013:10:23:18:06:54:SJ  VERSION_END

--synthesis_resources = 
 LIBRARY ieee;
 USE ieee.std_logic_1164.all;

 ENTITY  const_ethmacid0_lpm_constant_9c9 IS 
	 PORT 
	 ( 
		 result	:	OUT  STD_LOGIC_VECTOR (47 DOWNTO 0)
	 ); 
 END const_ethmacid0_lpm_constant_9c9;

 ARCHITECTURE RTL OF const_ethmacid0_lpm_constant_9c9 IS

 BEGIN

	result <= "000000000000000000100011000101110100101011001011";

 END RTL; --const_ethmacid0_lpm_constant_9c9
--VALID FILE


LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY const_ethmacid0 IS
	PORT
	(
		result		: OUT STD_LOGIC_VECTOR (47 DOWNTO 0)
	);
END const_ethmacid0;


ARCHITECTURE RTL OF const_ethmacid0 IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (47 DOWNTO 0);



	COMPONENT const_ethmacid0_lpm_constant_9c9
	PORT (
			result	: OUT STD_LOGIC_VECTOR (47 DOWNTO 0)
	);
	END COMPONENT;

BEGIN
	result    <= sub_wire0(47 DOWNTO 0);

	const_ethmacid0_lpm_constant_9c9_component : const_ethmacid0_lpm_constant_9c9
	PORT MAP (
		result => sub_wire0
	);



END RTL;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone III"
-- Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
-- Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
-- Retrieval info: PRIVATE: Radix NUMERIC "16"
-- Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
-- Retrieval info: PRIVATE: Value NUMERIC "588729035"
-- Retrieval info: PRIVATE: nBit NUMERIC "48"
-- Retrieval info: PRIVATE: new_diagram STRING "1"
-- Retrieval info: LIBRARY: lpm lpm.lpm_components.all
-- Retrieval info: CONSTANT: LPM_CVALUE NUMERIC "588729035"
-- Retrieval info: CONSTANT: LPM_HINT STRING "ENABLE_RUNTIME_MOD=NO"
-- Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_CONSTANT"
-- Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "48"
-- Retrieval info: USED_PORT: result 0 0 48 0 OUTPUT NODEFVAL "result[47..0]"
-- Retrieval info: CONNECT: result 0 0 48 0 @result 0 0 48 0
-- Retrieval info: GEN_FILE: TYPE_NORMAL const_ethmacid0.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL const_ethmacid0.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL const_ethmacid0.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL const_ethmacid0.bsf TRUE FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL const_ethmacid0_inst.vhd FALSE
