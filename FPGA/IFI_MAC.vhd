--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---  File             : C:/Users/cnoeding/AppData/Local/Temp/alt0090_49990308619216675.dir/0002_sopcgen/IFI_MAC.vhd
--   this file is automatically created by the SOPC Builder
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
entity IFI_MAC is
	port ( 
  		clk                 						: in    std_logic                     := '0';             
 		clrn                						: in    std_logic                     := '0';             
		clk125              					: in    std_logic                     := '0';             
		RX_CLK              					: in    std_logic                     := '0';             
		RX_DV               					: in    std_logic                     := '0';             
		TX_EN               					: out   std_logic;                                        
		MDC                 					: out   std_logic;                                        
		MDIO                					: inout std_logic                     := '0';             
		TXD                 					: out   std_logic_vector(3 downto 0);                     
		RXD                 					: in    std_logic_vector(3 downto 0)  := (others => '0'); 
		mGMAC_we            				: out   std_logic;                                        
		mGMAC_rd            				: out   std_logic;                                        
		mGMAC_be            				: out   std_logic_vector(3 downto 0);                     
		mGMAC_D             				: in    std_logic_vector(31 downto 0) := (others => '0'); 
		mGMAC_A             				: out   std_logic_vector(31 downto 0);                    
		mGMAC_Q             				: out   std_logic_vector(31 downto 0);                    
		mGMAC_waitrequest   		: in    std_logic                     := '0';             
		mGMAC_readdatavalid 		: in    std_logic                     := '0';             
		sGMAC_cs            				: in    std_logic                     := '0';             
		sGMAC_we            				: in    std_logic                     := '0';             
		sGMAC_rd            				: in    std_logic                     := '0';             
		sGMAC_be            				: in    std_logic_vector(3 downto 0)  := (others => '0'); 
		sGMAC_D             				: in    std_logic_vector(31 downto 0) := (others => '0'); 
		sGMAC_Q             				: out   std_logic_vector(31 downto 0);                    
		sGMAC_waitrequest   		: out   std_logic;                                        
		sGMAC_A             				: in    std_logic_vector(11 downto 0) := (others => '0'); 
		sGMAC_INT           				: out   std_logic;                                        
		RX_ER               					: in    std_logic                     := '0';             
		TX_ER               					: out    std_logic                  ;             
		TX_CLK               				: in    std_logic                     := '0';             
		waitrequest         				: out   std_logic                                         
   
	);
end entity IFI_MAC;
  
architecture rtl of IFI_MAC is
  component ifi_gmacii_top is
		generic (			
			sys_freq     : integer := 0;
			jumbo        : integer := 0;
			RAW          : integer := 10;
			TDP          : integer := 0;
			dv           : integer := 4;
			TAW          : integer := 10;
			ITYP         : integer := 0;
			FTYP         : integer := 1
		);  
	port ( 
  		clk                 						: in    std_logic                     := '0';             
 		clrn                						: in    std_logic                     := '0';             
		clk125              					: in    std_logic                     := '0';             
		RX_CLK              					: in    std_logic                     := '0';             
		RX_DV               					: in    std_logic                     := '0';             
		TX_EN               					: out   std_logic;                                        
		MDC                 					: out   std_logic;                                        
		MDIO                					: inout std_logic                     := '0';             
		TXD                 					: out   std_logic_vector(3 downto 0);                     
		RXD                 					: in    std_logic_vector(3 downto 0)  := (others => '0'); 
		mGMAC_we            				: out   std_logic;                                        
		mGMAC_rd            				: out   std_logic;                                        
		mGMAC_be            				: out   std_logic_vector(3 downto 0);                     
		mGMAC_D             				: in    std_logic_vector(31 downto 0) := (others => '0'); 
		mGMAC_A             				: out   std_logic_vector(31 downto 0);                    
		mGMAC_Q             				: out   std_logic_vector(31 downto 0);                    
		mGMAC_waitrequest   		: in    std_logic                     := '0';             
		mGMAC_readdatavalid 		: in    std_logic                     := '0';             
		sGMAC_cs            				: in    std_logic                     := '0';             
		sGMAC_we            				: in    std_logic                     := '0';             
		sGMAC_rd            				: in    std_logic                     := '0';             
		sGMAC_be            				: in    std_logic_vector(3 downto 0)  := (others => '0'); 
		sGMAC_D             				: in    std_logic_vector(31 downto 0) := (others => '0'); 
		sGMAC_Q             				: out   std_logic_vector(31 downto 0);                    
		sGMAC_waitrequest   		: out   std_logic;                                        
		sGMAC_A             				: in    std_logic_vector(11 downto 0) := (others => '0'); 
		sGMAC_INT           				: out   std_logic;                                        
		RX_ER               					: in    std_logic                     := '0';             
		TX_ER               					: out    std_logic                  ;             
		TX_CLK               				: in    std_logic                     := '0';             
		waitrequest         				: out   std_logic                                         
   
	);
end component ifi_gmacii_top;
 
begin  
  
	IFI_MAC : component ifi_gmacii_top   
		generic map(			
			sys_freq     => 0, 
			jumbo        => 0, 
			RAW          => 10, 
			TDP          => 0, 
			dv           => 4, 
			TAW          => 10, 
			ITYP         => 0, 
			FTYP         => 1 
		) 
		port map (   
  	clk                 						=>   clk                 					   ,
 		clrn                						=>   clrn                					   ,
		clk125              					=>   clk125              				   ,
		RX_CLK              					=>   RX_CLK              				   ,
		RX_DV               					=>   RX_DV               				   ,
		TX_EN               					=>   TX_EN               				   ,
		MDC                 					=>   MDC                 				   ,
		MDIO                					=>   MDIO                				   ,
		TXD                 					=>   TXD                 				   ,
		RXD                 					=>   RXD                 				   ,
		mGMAC_we            				=>   mGMAC_we            			   ,
		mGMAC_rd            				=>   mGMAC_rd            			   ,
		mGMAC_be            				=>   mGMAC_be            			   ,
		mGMAC_D             				=>   mGMAC_D             			   ,
		mGMAC_A             				=>   mGMAC_A             			   ,
		mGMAC_Q             				=>   mGMAC_Q             			   ,
		mGMAC_waitrequest   		=>   mGMAC_waitrequest   	   ,
		mGMAC_readdatavalid 		=>   mGMAC_readdatavalid 	   ,
		sGMAC_cs            				=>   sGMAC_cs            			   ,
		sGMAC_we            				=>   sGMAC_we            			   ,
		sGMAC_rd            				=>   sGMAC_rd            			   ,
		sGMAC_be            				=>   sGMAC_be            			   ,
		sGMAC_D             				=>   sGMAC_D             			   ,
		sGMAC_Q             				=>   sGMAC_Q             			   ,
		sGMAC_waitrequest   		=>   sGMAC_waitrequest   	   ,
		sGMAC_A             				=>   sGMAC_A             			   ,
		sGMAC_INT           				=>   sGMAC_INT           			   ,
		RX_ER               					=>   RX_ER   ,
		TX_ER               					=>   TX_ER   ,
		TX_CLK               				=>   TX_CLK   ,
		waitrequest         				=>   waitrequest   
		);    
        
end architecture rtl;    
        
