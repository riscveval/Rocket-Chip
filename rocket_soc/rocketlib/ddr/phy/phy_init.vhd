--*****************************************************************************
-- (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Application: MIG                                
--  \   \         Filename: phy_init.vhd                          
--  /   /         Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- /___/   /\     Date Created: Mon Jun 23 2008                   
-- \   \  /  \    
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--  Memory initialization and overall master state control during
--  initialization and calibration. Specifically, the following functions
--  are performed:
--    1. Memory initialization (initial AR, mode register programming, etc.)
--    2. Initiating write leveling
--    3. Generate training pattern writes for read leveling. Generate
--       memory readback for read leveling.
--  This module has a DFI interface for providing control/address and write
--  data to the rest of the PHY datapath during initialization/calibration.
--  Once initialization is complete, control is passed to the MC. 
--  NOTES:
--    1. Multiple CS (multi-rank) not supported
--    2. DDR2 not supported
--Reference:
--Revision History:
-- 9-16-2008 Adding DDR2 initialization sequence. Also adding the DDR_MODE 
-- parmater. KP
-- 12-8-2008 Fixed the address[12] for OTF mode. KP 
--*****************************************************************************

--******************************************************************************
--**$Id: phy_init.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_init.vhd,v $
--******************************************************************************
library unisim;
   use unisim.vcomponents.all;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;
library std;
   use std.textio.all;
   
entity phy_init is
   generic (
      TCQ                         : integer := 100;
      nCK_PER_CLK                 : integer := 2;		-- # of memory clocks per CLK
      CLK_PERIOD                  : integer := 3333;		-- Logic (internal) clk period (in ps)
      BANK_WIDTH                  : integer := 2;
      COL_WIDTH                   : integer := 10;
      nCS_PER_RANK                : integer := 1;		-- # of CS bits per rank e.g. for 
      								-- component I/F with CS_WIDTH=1, 
      								-- nCS_PER_RANK=# of components
      DQ_WIDTH                    : integer := 64;
      ROW_WIDTH                   : integer := 14;
      CS_WIDTH                    : integer := 1;
      CKE_WIDTH                   : integer := 1;		-- # of cke outputs 
      DRAM_TYPE                   : string := "DDR3";
      REG_CTRL                    : string := "ON";
      
      -- calibration Address
      CALIB_ROW_ADD               : std_logic_vector(15 downto 0) := X"0000";  -- Calibration row address
      CALIB_COL_ADD               : std_logic_vector(11 downto 0) := X"000";   -- Calibration column address
      CALIB_BA_ADD                : std_logic_vector(2 downto 0)  := "000";    -- Calibration bank address 
   
      -- DRAM mode settings
      AL                          : string := "0";		-- Additive Latency option
      BURST_MODE                  : string := "8";		-- Burst length
      BURST_TYPE                  : string := "SEQ";		-- Burst type 
      nAL                         : integer := 0;		-- Additive latency (in clk cyc)
      nCL                         : integer := 5;		-- Read CAS latency (in clk cyc)
      nCWL                        : integer := 5;		-- Write CAS latency (in clk cyc)
      tRFC                        : integer := 110000;		-- Refresh-to-command delay (in ps)
      OUTPUT_DRV                  : string := "HIGH";		-- DRAM reduced output drive option
      RTT_NOM                     : string := "60";		-- Nominal ODT termination value
      RTT_WR                      : string := "60";		-- Write ODT termination value
      WRLVL                       : string := "ON";		-- Enable write leveling
      PHASE_DETECT                : string := "ON";		-- Enable read phase detector
      DDR2_DQSN_ENABLE            : string := "YES";		-- Enable differential DQS for DDR2
      nSLOTS                      : integer := 1;		-- Number of DIMM SLOTs in the system
      SIM_INIT_OPTION             : string := "NONE";		-- "NONE", "SKIP_PU_DLY", "SKIP_INIT"
      SIM_CAL_OPTION              : string := "NONE"		-- "NONE", "FAST_CAL", "SKIP_CAL"
   );
   port (
      clk                         : in std_logic;
      rst                         : in std_logic;
      -- Read/write calibration interface
      calib_width                 : in std_logic_vector(2 downto 0);
      rdpath_rdy                  : in std_logic;
      wrlvl_done                  : in std_logic;
      wrlvl_rank_done             : in std_logic;
      slot_0_present              : in std_logic_vector(7 downto 0);
      slot_1_present              : in std_logic_vector(7 downto 0);
      wrlvl_active                : out std_logic;
      rdlvl_done                  : in std_logic_vector(1 downto 0);
      rdlvl_start                 : out std_logic_vector(1 downto 0);
      rdlvl_clkdiv_done           : in std_logic;
      rdlvl_clkdiv_start          : out std_logic;
      rdlvl_prech_req             : in std_logic;
      rdlvl_resume                : in std_logic;
      -- To phy_write for write bitslip during read leveling
      chip_cnt                    : out std_logic_vector(1 downto 0);
      -- Read phase detector calibration control 
      pd_cal_start                : out std_logic;
      pd_cal_done                 : in std_logic;
      pd_prech_req                : in std_logic;
      -- Signals shared btw multiple calibration stages
      prech_done                  : out std_logic;
      -- Data select / status
      dfi_init_complete           : out std_logic;
      -- PHY DFI address/control
      phy_address0                : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      phy_address1                : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      phy_bank0                   : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      phy_bank1                   : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      phy_cas_n0                  : out std_logic;
      phy_cas_n1                  : out std_logic;
      phy_cke0                    : out std_logic_vector(CKE_WIDTH - 1 downto 0);
      phy_cke1                    : out std_logic_vector(CKE_WIDTH - 1 downto 0);
      phy_cs_n0                   : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      phy_cs_n1                   : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      phy_init_data_sel           : out std_logic;
      phy_odt0                    : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      phy_odt1                    : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      phy_ras_n0                  : out std_logic;
      phy_ras_n1                  : out std_logic;
      phy_reset_n                 : out std_logic;
      phy_we_n0                   : out std_logic;
      phy_we_n1                   : out std_logic;
      -- PHY DFI Write
      phy_wrdata_en               : out std_logic;
      phy_wrdata                  : out std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
      -- PHY DFI Read
      phy_rddata_en               : out std_logic;
      -- PHY sideband signals
      phy_ioconfig                : out std_logic_vector(0 downto 0);
      phy_ioconfig_en             : out std_logic
   );
end phy_init;

architecture trans of phy_init is

   type type_xhdl4 is array (0 to 3) of std_logic_vector(1 downto 0);
   type type_xhdl5 is array (0 to 3) of std_logic_vector(2 downto 0);

   function AND_BR(inp_sig: std_logic_vector)
            return std_logic is
      variable return_var : std_logic := '1';		    
   begin
      for index in inp_sig'range loop
	 return_var := return_var and inp_sig(index);
      end loop;
      
      return return_var;
   end function;

   function CALC_BURST4_FLAG return std_logic is
   begin
      if (DRAM_TYPE = "DDR3") then
         return ('0');
      else
         if (BURST_MODE = "8") then
	    return ('0');
         else
	    if (BURST_MODE = "4") then
               return ('1');
	    else
	       return ('0');
	    end if;
	 end if;
      end if;
   end function;

   function CALC_REG_RC1 return std_logic_vector is
   begin
      if (CS_WIDTH <= 2) then
         return ("00110001");
      else
         return ("00000001");
      end if;	 
   end function;

   function CALC_CWL_M return integer is
   begin
      if (REG_CTRL = "ON") then
         return (nCWL + 1);
      else
         return (nCWL);
      end if;	 
   end function;

   function CALC_PHY_WRDATA (choice : integer) return std_logic_vector is
      variable temp1, temp2, temp3, temp4 : std_logic_vector(DQ_WIDTH-1 downto 0);
   begin
      if ((choice = 0) or (choice = 1) or (choice = 2) or (choice = 3)) then
	 temp1 := (others => '0');
	 temp2 := (others => '1');
	 temp3 := (others => '0');
	 temp4 := (others => '1');	 
	 return (temp1 & temp2 & temp3 & temp4);
      elsif ((choice = 4) or (choice = 6)) then
 	 temp1 := (others => '1');
	 temp2 := (others => '1');
	 temp3 := (others => '1');
	 temp4 := (others => '1');	 
	 return (temp1 & temp2 & temp3 & temp4);
      elsif ((choice = 5) or (choice = 7)) then
 	 temp1 := (others => '0');
	 temp2 := (others => '0');
	 temp3 := (others => '0');
	 temp4 := (others => '0');	 
	 return (temp1 & temp2 & temp3 & temp4);          
      elsif (choice = 8) then
	 for idx in 0 to (DQ_WIDTH/4)-1 loop     
	    temp1(4*idx+3 downto 4*idx) := "0101";
	    temp2(4*idx+3 downto 4*idx) := "1010";
	    temp3(4*idx+3 downto 4*idx) := "0000";
	    temp4(4*idx+3 downto 4*idx) := "1111";
	 end loop;   
	 return (temp1 & temp2 & temp3 & temp4);
      elsif (choice = 9) then
	 for idx in 0 to (DQ_WIDTH/4)-1 loop     
	    temp1(4*idx+3 downto 4*idx) := "0110";
	    temp2(4*idx+3 downto 4*idx) := "1001";
	    temp3(4*idx+3 downto 4*idx) := "1010";
	    temp4(4*idx+3 downto 4*idx) := "0101";
	 end loop;   
	 return (temp1 & temp2 & temp3 & temp4);         
      else
 	 temp1 := (others => '0');
	 temp2 := (others => '0');
	 temp3 := (others => '0');
	 temp4 := (others => '0');	 
	 return (temp1 & temp2 & temp3 & temp4);
      end if;
   end function;

   -- In a 2 slot dual rank per system RTT_NOM values 
   -- for Rank2 and Rank3 default to 40 ohms
   constant RTT_NOM2                    : string := "040";
   constant RTT_NOM3                    : string := "040";
   
   -- Specifically for use with half-frequency controller (nCK_PER_CLK=2)
   -- = 1 if burst length = 4, = 0 if burst length = 8. Determines how
   -- often row command needs to be issued during read-leveling
   -- For DDR3 the burst length is fixed during calibration 
   constant BURST4_FLAG                 : std_logic := CALC_BURST4_FLAG;
   
   --***************************************************************************
   -- Counter values used to determine bus timing
   -- NOTE on all counter terminal counts - these can/should be one less than 
   --   the actual delay to take into account extra clock cycle delay in 
   --   generating the corresponding "done" signal
   --***************************************************************************
   
   constant CLK_MEM_PERIOD              : integer := CLK_PERIOD / nCK_PER_CLK;

   function CALC_TXPR_DELAY_CNT return integer is
   begin
      if (5*CLK_MEM_PERIOD > tRFC+10000) then
         return ((((5+nCK_PER_CLK-1)/nCK_PER_CLK)-1) + 5);
      else
         return ((((tRFC+10000+CLK_PERIOD-1)/CLK_PERIOD)-1) + 5);
      end if; 	 
   end function;

   function CALC_TWR_CYC return integer is
   begin
      if ((15000 mod CLK_MEM_PERIOD) > 0) then
         return ((15000/CLK_MEM_PERIOD) + 1);
      else
         return (15000/CLK_MEM_PERIOD);
      end if; 	 
   end function;

   -- Calculate initial delay required in number of CLK clock cycles
   -- to delay initially. The counter is clocked by [CLK/1024] - which
   -- is approximately division by 1000 - note that the formulas below will
   -- result in more than the minimum wait time because of this approximation.
   -- NOTE: For DDR3 JEDEC specifies to delay reset
   --       by 200us, and CKE by an additional 500us after power-up
   --       For DDR2 CKE is delayed by 200us after power up.
   constant DDR3_RESET_DELAY_NS         : integer := 200000;
   constant DDR3_CKE_DELAY_NS           : integer := 500000 + DDR3_RESET_DELAY_NS;
   constant DDR2_CKE_DELAY_NS           : integer := 200000;
   constant PWRON_RESET_DELAY_CNT       : integer := ((DDR3_RESET_DELAY_NS + CLK_PERIOD - 1) / CLK_PERIOD);
   
   function CALC_PWRON_CKE_DELAY_CNT return integer is
   begin
      if (DRAM_TYPE = "DDR3") then
         return (((DDR3_CKE_DELAY_NS+CLK_PERIOD-1)/CLK_PERIOD));
      else
         return ((DDR2_CKE_DELAY_NS+CLK_PERIOD-1)/CLK_PERIOD);
      end if;	 
   end function;
   constant PWRON_CKE_DELAY_CNT         : integer := CALC_PWRON_CKE_DELAY_CNT;

   -- FOR DDR2 -1 taken out. With -1 not getting 200us. The equation
   -- needs to be reworked. 
   constant DDR2_INIT_PRE_DELAY_PS      : integer := 400000;
   constant DDR2_INIT_PRE_CNT           : integer := ((DDR2_INIT_PRE_DELAY_PS + CLK_PERIOD - 1) / CLK_PERIOD) - 1;
   
   -- Calculate tXPR time: reset from CKE HIGH to valid command after power-up
   -- tXPR = (max(5nCK, tRFC(min)+10ns). Add a few (blah, messy) more clock
   -- cycles because this counter actually starts up before CKE is asserted
   -- to memory.
   constant TXPR_DELAY_CNT              : integer := CALC_TXPR_DELAY_CNT;
   
   -- tDLLK/tZQINIT time = 512*tCK = 256*tCLKDIV
   constant TDLLK_TZQINIT_DELAY_CNT     : integer := 255;
   
   -- TWR values in ns. Both DDR2 and DDR3 have the same value.
   -- 15000ns/tCK
   constant TWR_CYC                     : integer := CALC_TWR_CYC;
   
   -- time to wait between consecutive commands in PHY_INIT - this is a
   -- generic number, and must be large enough to account for worst case
   -- timing parameter (tRFC - refresh-to-active) across all memory speed
   -- grades and operating frequencies. Expressed in CLKDIV clock cycles. 
   constant CNTNEXT_CMD                 : std_logic_vector(6 downto 0) := "1111111";
   
   -- Counter values to keep track of which MR register to load during init
   -- Set value of INIT_CNT_MR_DONE to equal value of counter for last mode
   -- register configured during initialization. 
   -- NOTE: Reserve more bits for DDR2 - more MR accesses for DDR2 init
   constant INIT_CNT_MR2                : std_logic_vector(1 downto 0) := "00";
   constant INIT_CNT_MR3                : std_logic_vector(1 downto 0) := "01";
   constant INIT_CNT_MR1                : std_logic_vector(1 downto 0) := "10";
   constant INIT_CNT_MR0                : std_logic_vector(1 downto 0) := "11";
   constant INIT_CNT_MR_DONE            : std_logic_vector(1 downto 0) := "11";
   
   -- Register chip programmable values for DDR3
   -- The register chip for the registered DIMM needs to be programmed
   -- before the initialization of the registered DIMM.
   -- Address for the control word is in : DBA2, DA2, DA1, DA0
   -- Data for the control word is in: DBA1 DBA0, DA4, DA3
   -- The values will be stored in the local param in the following format
   -- {DBA[2:0], DA[4:0]}
   
   -- RC0 is global features control word. Address == 000
   
   constant REG_RC0                     : std_logic_vector(7 downto 0) := "00000000";
   
   -- RC1 Clock driver enable control word. Enables or disables the four
   -- output clocks in the register chip. For single rank and dual rank
   -- two clocks will be enabled and for quad rank all the four clocks
   -- will be enabled. Address == 000. Data = 0110 for single and dual rank.
   -- = 0000 for quad rank 
   constant REG_RC1                     : std_logic_vector(7 downto 0) := CALC_REG_RC1;
   
   -- RC2 timing control word. Set in 1T timing mode
   -- Address = 010. Data = 0000
   constant REG_RC2                     : std_logic_vector(7 downto 0) := "00000010";
   
   -- RC3 timing control word. Setting the data to 0000
   constant REG_RC3                     : std_logic_vector(7 downto 0) := "00000011";
   
   -- RC4 timing control work. Setting the data to 0000 
   constant REG_RC4                     : std_logic_vector(7 downto 0) := "00000100";

   -- RC5 timing control work. Setting the data to 0000 
   constant REG_RC5                     : std_logic_vector(7 downto 0) := "00000101";
   
   -- Adding the register dimm latency to write latency
   constant CWL_M                       : integer := CALC_CWL_M;
   
   -- Master state machine encoding
   constant INIT_IDLE                   : std_logic_vector(5 downto 0) := "000000";		--0
   constant INIT_WAIT_CKE_EXIT          : std_logic_vector(5 downto 0) := "000001";		--1
   constant INIT_LOAD_MR                : std_logic_vector(5 downto 0) := "000010";		--2
   constant INIT_LOAD_MR_WAIT           : std_logic_vector(5 downto 0) := "000011";		--3
   constant INIT_ZQCL                   : std_logic_vector(5 downto 0) := "000100";		--4
   constant INIT_WAIT_DLLK_ZQINIT       : std_logic_vector(5 downto 0) := "000101";		--5
   constant INIT_WRLVL_START            : std_logic_vector(5 downto 0) := "000110";		--6
   constant INIT_WRLVL_WAIT             : std_logic_vector(5 downto 0) := "000111";		--7
   constant INIT_WRLVL_LOAD_MR          : std_logic_vector(5 downto 0) := "001000";		--8
   constant INIT_WRLVL_LOAD_MR_WAIT     : std_logic_vector(5 downto 0) := "001001";		--9
   constant INIT_WRLVL_LOAD_MR2         : std_logic_vector(5 downto 0) := "001010";		--A  
   constant INIT_WRLVL_LOAD_MR2_WAIT    : std_logic_vector(5 downto 0) := "001011";		--B  
   constant INIT_RDLVL_ACT              : std_logic_vector(5 downto 0) := "001100";		--C  
   constant INIT_RDLVL_ACT_WAIT         : std_logic_vector(5 downto 0) := "001101";		--D  
   constant INIT_RDLVL_STG1_WRITE       : std_logic_vector(5 downto 0) := "001110";		--E  
   constant INIT_RDLVL_STG1_WRITE_READ  : std_logic_vector(5 downto 0) := "001111";		--F  
   constant INIT_RDLVL_STG1_READ        : std_logic_vector(5 downto 0) := "010000";		--10 
   constant INIT_RDLVL_STG2_WRITE       : std_logic_vector(5 downto 0) := "010001";		--11 
   constant INIT_RDLVL_STG2_WRITE_READ  : std_logic_vector(5 downto 0) := "010010";		--12 
   constant INIT_RDLVL_STG2_READ        : std_logic_vector(5 downto 0) := "010011";		--13 
   constant INIT_RDLVL_STG2_READ_WAIT   : std_logic_vector(5 downto 0) := "010100";		--14 
   constant INIT_PRECHARGE_PREWAIT      : std_logic_vector(5 downto 0) := "010101";		--15 
   constant INIT_PRECHARGE              : std_logic_vector(5 downto 0) := "010110";		--16 
   constant INIT_PRECHARGE_WAIT         : std_logic_vector(5 downto 0) := "010111";		--17 
   constant INIT_DONE                   : std_logic_vector(5 downto 0) := "011000";		--18 
   constant INIT_IOCONFIG_WR            : std_logic_vector(5 downto 0) := "011001";		--19 
   constant INIT_IOCONFIG_RD            : std_logic_vector(5 downto 0) := "011010";		--1A 
   constant INIT_IOCONFIG_WR_WAIT       : std_logic_vector(5 downto 0) := "011011";		--1B 
   constant INIT_IOCONFIG_RD_WAIT       : std_logic_vector(5 downto 0) := "011100";		--1C 
   constant INIT_DDR2_PRECHARGE         : std_logic_vector(5 downto 0) := "011101";		--1D 
   constant INIT_DDR2_PRECHARGE_WAIT    : std_logic_vector(5 downto 0) := "011110";		--1E 
   constant INIT_REFRESH                : std_logic_vector(5 downto 0) := "011111";		--1F 
   constant INIT_REFRESH_WAIT           : std_logic_vector(5 downto 0) := "100000";		--20
   constant INIT_PD_ACT                 : std_logic_vector(5 downto 0) := "100001";		--21
   constant INIT_PD_ACT_WAIT            : std_logic_vector(5 downto 0) := "100010";		--22
   constant INIT_PD_READ                : std_logic_vector(5 downto 0) := "100011";		--23
   constant INIT_REG_WRITE              : std_logic_vector(5 downto 0) := "100100";		--24
   constant INIT_REG_WRITE_WAIT         : std_logic_vector(5 downto 0) := "100101";		--25
   constant INIT_DDR2_MULTI_RANK        : std_logic_vector(5 downto 0) := "100110";		--26
   constant INIT_DDR2_MULTI_RANK_WAIT   : std_logic_vector(5 downto 0) := "100111";		--27 
   constant INIT_RDLVL_CLKDIV_WRITE     : std_logic_vector(5 downto 0) := "101000";             --28  
   constant INIT_RDLVL_CLKDIV_WRITE_READ: std_logic_vector(5 downto 0) := "101001";             --29  
   constant INIT_RDLVL_CLKDIV_READ      : std_logic_vector(5 downto 0) := "101010";             --2A
   
   signal auto_cnt_r                   : std_logic_vector(1 downto 0);
   signal burst_addr_r                 : std_logic_vector(1 downto 0);
   signal chip_cnt_r                   : std_logic_vector(1 downto 0);
   signal cnt_cmd_r                    : std_logic_vector(6 downto 0);
   signal cnt_cmd_done_r               : std_logic;
   signal cnt_dllk_zqinit_r            : std_logic_vector(7 downto 0);
   signal cnt_dllk_zqinit_done_r       : std_logic;
   signal cnt_init_af_done_r           : std_logic;
   signal cnt_init_af_r                : std_logic_vector(1 downto 0);
   signal cnt_init_data_r              : std_logic_vector(3 downto 0);
   signal cnt_init_mr_r                : std_logic_vector(1 downto 0);
   signal cnt_init_mr_done_r           : std_logic;
   signal cnt_init_pre_wait_done_r     : std_logic;
   signal cnt_init_pre_wait_r          : std_logic_vector(7 downto 0);
   signal cnt_pwron_ce_r               : std_logic_vector(9 downto 0);
   signal cnt_pwron_cke_done_r         : std_logic;
   signal cnt_pwron_r                  : std_logic_vector(8 downto 0);
   signal cnt_pwron_reset_done_r       : std_logic;
   signal cnt_txpr_done_r              : std_logic;
   signal cnt_txpr_r                   : std_logic_vector(7 downto 0);
   signal ddr2_pre_flag_r              : std_logic;
   signal ddr2_refresh_flag_r          : std_logic;
   signal ddr3_lm_done_r               : std_logic;
   signal enable_wrlvl_cnt             : std_logic_vector(4 downto 0);
   signal init_complete_r              : std_logic;
   signal init_complete_r1             : std_logic;
   signal init_complete_r2             : std_logic;
   signal init_next_state              : std_logic_vector(5 downto 0);
   signal init_state_r                 : std_logic_vector(5 downto 0);
   signal init_state_r1                : std_logic_vector(5 downto 0);
   signal load_mr0                     : std_logic_vector(15 downto 0);
   signal load_mr1                     : std_logic_vector(15 downto 0);
   signal load_mr2                     : std_logic_vector(15 downto 0);
   signal load_mr3                     : std_logic_vector(15 downto 0);
   signal mem_init_done_r              : std_logic;
   signal mem_init_done_r1             : std_logic;
   signal mr2_r                        : type_xhdl4;
   signal mr1_r                        : type_xhdl5;
   signal new_burst_r                  : std_logic;
   signal pd_cal_start_dly_r           : std_logic_vector(15 downto 0);
   signal pd_cal_start_pre             : std_logic;
   signal phy_tmp_odt0_r               : std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
   signal phy_tmp_odt1_r               : std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
   signal phy_tmp_odt0_r1              : std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
   signal phy_tmp_odt1_r1              : std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
   signal phy_tmp_cs1_r                : std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
   signal prech_done_pre               : std_logic;
   signal prech_done_dly_r             : std_logic_vector(15 downto 0);
   signal prech_pending_r              : std_logic;
   signal prech_req_posedge_r          : std_logic;
   signal prech_req_r                  : std_logic;
   signal pwron_ce_r                   : std_logic;
   signal address_w                    : std_logic_vector(ROW_WIDTH-1 downto 0);
   signal bank_w                       : std_logic_vector(BANK_WIDTH-1 downto 0);
   signal rdlvl_start_dly0_r           : std_logic_vector(15 downto 0);
   signal rdlvl_start_dly1_r           : std_logic_vector(15 downto 0);
   signal rdlvl_start_dly_clkdiv_r     : std_logic_vector(15 downto 0);
   signal rdlvl_start_pre              : std_logic_vector(1 downto 0);
   signal rdlvl_start_pre_clkdiv       : std_logic;
   signal rdlvl_rd                     : std_logic;
   signal rdlvl_wr                     : std_logic;
   signal rdlvl_wr_r                   : std_logic;
   signal rdlvl_wr_rd                  : std_logic;
   signal reg_ctrl_cnt_r               : std_logic_vector(2 downto 0);
   signal tmp_mr2_r                    : type_xhdl4;
   signal tmp_mr1_r                    : type_xhdl5;   
   signal wrlvl_done_r                 : std_logic;
   signal wrlvl_done_r1                : std_logic;
   signal wrlvl_rank_done_r1           : std_logic;
   signal wrlvl_rank_done_r2           : std_logic;
   signal wrlvl_rank_done_r3           : std_logic;
   signal wrlvl_rank_cntr              : std_logic_vector(2 downto 0);
   signal wrlvl_odt                    : std_logic;
   signal wrlvl_odt_r1                 : std_logic;

   -- Shared request from multiple sources
   signal prech_req                    : std_logic;

   -- X-HDL generated signals
   signal xhdl15 : std_logic_vector(3 downto 0);
   signal xhdl16 : std_logic_vector(2 downto 0);
   signal xhdl17 : std_logic_vector(2 downto 0);
   signal xhdl18 : std_logic_vector(1 downto 0);
   signal xhdl19 : std_logic_vector(2 downto 0);
   signal xhdl20 : std_logic_vector(2 downto 0);
   signal xhdl21 : std_logic_vector(1 downto 0);
   signal xhdl22 : std_logic_vector(2 downto 0);
   signal xhdl23 : std_logic_vector(2 downto 0);
   signal xhdl24 : std_logic_vector(1 downto 0);
   signal xhdl25 : std_logic_vector(2 downto 0);
   signal xhdl26 : std_logic_vector(2 downto 0);
   signal xhdl27 : std_logic_vector(1 downto 0);
   signal xhdl30 : std_logic_vector(3 downto 0);
   signal xhdl31 : std_logic_vector(2 downto 0);
   signal xhdl32 : std_logic_vector(2 downto 0);
   signal xhdl33 : std_logic_vector(1 downto 0);
   signal xhdl34 : std_logic_vector(2 downto 0);
   signal xhdl35 : std_logic_vector(2 downto 0);
   signal xhdl36 : std_logic_vector(1 downto 0);
   signal xhdl37 : std_logic_vector(2 downto 0);
   signal xhdl38 : std_logic_vector(2 downto 0);
   signal xhdl39 : std_logic_vector(1 downto 0);
   signal xhdl40 : std_logic_vector(2 downto 0);
   signal xhdl41 : std_logic_vector(2 downto 0);
   signal xhdl42 : std_logic_vector(1 downto 0);
   signal xhdl43 : std_logic_vector(2 downto 0);
   signal xhdl44 : std_logic_vector(2 downto 0);
   signal xhdl45 : std_logic_vector(2 downto 0);
   signal xhdl46 : std_logic_vector(2 downto 0);
   signal xhdl47 : std_logic_vector(1 downto 0);
   signal xhdl48 : std_logic_vector(2 downto 0);
   signal xhdl49 : std_logic_vector(2 downto 0);
   signal xhdl50 : std_logic_vector(2 downto 0);
   signal xhdl51 : std_logic_vector(2 downto 0);
   signal xhdl52 : std_logic_vector(1 downto 0);
   signal xhdl53 : std_logic_vector(2 downto 0);
   signal xhdl54 : std_logic_vector(2 downto 0);
   signal xhdl55 : std_logic_vector(2 downto 0);
   signal xhdl56 : std_logic_vector(2 downto 0);
   signal xhdl57 : std_logic_vector(2 downto 0);
   signal xhdl58 : std_logic_vector(2 downto 0);
   signal xhdl59 : std_logic_vector(2 downto 0);
   signal xhdl60 : std_logic_vector(2 downto 0);
   signal xhdl61 : std_logic_vector(2 downto 0);
   signal xhdl62 : std_logic_vector(2 downto 0);
   signal xhdl63 : std_logic_vector(2 downto 0);
   signal xhdl64 : std_logic_vector(2 downto 0);
   signal xhdl65 : std_logic_vector(1 downto 0);
   signal xhdl66 : std_logic_vector(2 downto 0);
   signal xhdl67 : std_logic_vector(2 downto 0);
   signal xhdl68 : std_logic_vector(2 downto 0);
   signal xhdl69 : std_logic_vector(2 downto 0);
   signal xhdl70 : std_logic_vector(1 downto 0);
   signal xhdl71 : std_logic_vector(2 downto 0);
   signal xhdl72 : std_logic_vector(2 downto 0);
   signal xhdl73 : std_logic_vector(2 downto 0);
   signal xhdl74 : std_logic_vector(2 downto 0);
   signal xhdl75 : std_logic_vector(2 downto 0);
   signal xhdl76 : std_logic_vector(2 downto 0);
   signal xhdl77 : std_logic_vector(2 downto 0);
   signal xhdl78 : std_logic_vector(2 downto 0);
   signal xhdl79 : std_logic_vector(1 downto 0);
   signal xhdl80 : std_logic_vector(2 downto 0);
   signal xhdl81 : std_logic_vector(2 downto 0);
   signal xhdl82 : std_logic_vector(2 downto 0);
   signal xhdl83 : std_logic_vector(2 downto 0);
   signal xhdl84 : std_logic_vector(1 downto 0);
   signal xhdl85 : std_logic_vector(2 downto 0);
   signal xhdl86 : std_logic_vector(2 downto 0);
   signal xhdl87 : std_logic_vector(2 downto 0);
   signal xhdl88 : std_logic_vector(2 downto 0);
   signal xhdl89 : std_logic_vector(2 downto 0);
   signal xhdl90 : std_logic_vector(2 downto 0);
   signal xhdl91 : std_logic_vector(2 downto 0);
   signal xhdl92 : std_logic_vector(2 downto 0);
   signal xhdl93 : std_logic_vector(2 downto 0);
   signal xhdl94 : std_logic_vector(2 downto 0);
   signal xhdl95 : std_logic_vector(2 downto 0);
   signal xhdl96 : std_logic_vector(2 downto 0);
   signal xhdl97 : std_logic_vector(1 downto 0);
   signal xhdl98 : std_logic_vector(1 downto 0);
   signal xhdl99 : std_logic_vector(2 downto 0);
   signal xhdl100 : std_logic_vector(2 downto 0);
   signal xhdl101 : std_logic_vector(2 downto 0);
   signal xhdl102 : std_logic_vector(2 downto 0);
   signal xhdl103 : std_logic_vector(1 downto 0);
   signal xhdl104 : std_logic_vector(2 downto 0);
   signal xhdl105 : std_logic_vector(2 downto 0);
   signal xhdl106 : std_logic_vector(2 downto 0);
   signal xhdl107 : std_logic_vector(2 downto 0);
   signal xhdl108 : std_logic_vector(1 downto 0);
   signal xhdl109 : std_logic_vector(2 downto 0);
   signal xhdl110 : std_logic_vector(2 downto 0);
   signal xhdl111 : std_logic_vector(2 downto 0);
   signal xhdl112 : std_logic_vector(2 downto 0);
   signal xhdl113 : std_logic_vector(2 downto 0);
   signal xhdl114 : std_logic_vector(1 downto 0);
   
   -- Declare intermediate signals for referenced outputs
   signal rdlvl_clkdiv_start_xhdl4     : std_logic;
   signal wrlvl_active_xhdl3           : std_logic;
   signal rdlvl_start_xhdl2            : std_logic_vector(1 downto 0);
   signal phy_wrdata_en_xhdl1          : std_logic;
   
begin

   -- Drive referenced outputs
   rdlvl_clkdiv_start <= rdlvl_clkdiv_start_xhdl4;
   wrlvl_active <= wrlvl_active_xhdl3;
   rdlvl_start <= rdlvl_start_xhdl2;
   phy_wrdata_en <= phy_wrdata_en_xhdl1;

   --***************************************************************************
   -- Debug
   --***************************************************************************
   
   --synthesis translate_off   
   process (mem_init_done_r1)
      variable out_data : line;
   begin
      if (mem_init_done_r1'event and mem_init_done_r1 = '1') then
         if ((not(rst)) = '1') then
            write(out_data, string'("PHY_INIT: Memory Initialization completed at "));
            write(out_data, now);
            writeline(output, out_data);
         end if;
      end if;
   end process;
   
   process (wrlvl_done)
      variable out_data : line;
   begin
      if (wrlvl_done'event and wrlvl_done = '1') then
         if ((not(rst)) = '1' and (WRLVL = "ON")) then
            write(out_data, string'("PHY_INIT: Write Leveling completed at "));
            write(out_data, now);
            writeline(output, out_data);
         end if;
      end if;
   end process;
   
   process (rdlvl_done(0))
      variable out_data : line;
   begin
      if (rdlvl_done(0)'event and rdlvl_done(0) = '1') then
         if ((not(rst)) = '1') then
            write(out_data, string'("PHY_INIT: Read Leveling Stage 1 completed at "));
            write(out_data, now);
            writeline(output, out_data);
         end if;
      end if;
   end process;
   
   process (rdlvl_done(1))
      variable out_data : line;
   begin
      if (rdlvl_done(1)'event and rdlvl_done(1) = '1') then
         if ((not(rst)) = '1') then
            write(out_data, string'("PHY_INIT: Read Leveling Stage 2 completed at "));
            write(out_data, now);
            writeline(output, out_data);
         end if;
      end if;
   end process;

   process (rdlvl_clkdiv_done)
      variable out_data : line;
   begin
      if (rdlvl_clkdiv_done'event and rdlvl_clkdiv_done = '1') then
         if ((not(rst)) = '1') then
            write(out_data, string'("PHY_INIT: Read Leveling CLKDIV cal completed at "));
            write(out_data, now);
            writeline(output, out_data);
         end if;
      end if;
   end process;
   
   process (pd_cal_done)
      variable out_data : line;
   begin
      if (pd_cal_done'event and pd_cal_done = '1') then
         if ((not(rst)) = '1' and (PHASE_DETECT = "ON")) then
            write(out_data, string'("PHY_INIT: Phase Detector Initial Cal completed at "));
            write(out_data, now);
            writeline(output, out_data);
         end if;
      end if;
   end process;
  
   --synthesis translate_on

   --***************************************************************************
   -- Signal PHY completion when calibration is finished
   -- Signal assertion is delayed by four clock cycles to account for the
   -- multi cycle path constraint to (phy_init_data_sel) signal. 
   --***************************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            init_complete_r <= '0' after (TCQ)*1 ps;
            init_complete_r1 <= '0' after (TCQ)*1 ps;
            init_complete_r2 <= '0' after (TCQ)*1 ps;
            dfi_init_complete <= '0' after (TCQ)*1 ps;
         else
            if (init_state_r = INIT_DONE) then
               init_complete_r <= '1' after (TCQ)*1 ps;
            end if;
            init_complete_r1 <= init_complete_r after (TCQ)*1 ps;
            init_complete_r2 <= init_complete_r1 after (TCQ)*1 ps;
            dfi_init_complete <= init_complete_r2 after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   --***************************************************************************  
   -- Instantiate FF for the phy_init_data_sel signal. A multi cycle path 
   -- constraint will be assigned to this signal. This signal will only be 
   -- used within the PHY 
   --*************************************************************************** 
   u_ff_phy_init_data_sel : FDRSE
      port map (
         q   => phy_init_data_sel,
         c   => clk,
         ce  => '1',
         d   => init_complete_r,
         r   => '0',
         s   => '0'
      ); -- synthesis syn_preserve=1
         -- synthesis syn_replicate = 0 ; 
   
   --***************************************************************************
   -- Mode register programming
   --***************************************************************************
   
   --*****************************************************************
   -- DDR3 Load mode reg0
   -- Mode Register (MR0):
   --   [15:13]   - unused          - 000
   --   [12]      - Precharge Power-down DLL usage - 0 (DLL frozen, slow-exit), 
   --               1 (DLL maintained)
   --   [11:9]    - write recovery for Auto Precharge (tWR/tCK = 6)
   --   [8]       - DLL reset       - 0 or 1
   --   [7]       - Test Mode       - 0 (normal)
   --   [6:4],[2] - CAS latency     - CAS_LAT
   --   [3]       - Burst Type      - BURST_TYPE
   --   [1:0]     - Burst Length    - BURST_LEN
   -- DDR2 Load mode register
   -- Mode Register (MR):
   --   [15:14] - unused          - 00
   --   [13]    - reserved        - 0
   --   [12]    - Power-down mode - 0 (normal)
   --   [11:9]  - write recovery  - write recovery for Auto Precharge
   --                               (tWR/tCK = 6)
   --   [8]     - DLL reset       - 0 or 1
   --   [7]     - Test Mode       - 0 (normal)
   --   [6:4]   - CAS latency     - CAS_LAT
   --   [3]     - Burst Type      - BURST_TYPE
   --   [2:0]   - Burst Length    - BURST_LEN
   
   --*****************************************************************
   gen_load_mr0_DDR3 : if (DRAM_TYPE = "DDR3") generate
      load_mr0(1 downto 0) <= "00" when (BURST_MODE = "8") else
                              "01" when (BURST_MODE = "OTF") else
                              "10" when (BURST_MODE = "4") else
                              "11";
      load_mr0(2) <= '0';		-- LSB of CAS latency
      load_mr0(3) <= '0' when (BURST_TYPE = "SEQ") else
                     '1';
      load_mr0(6 downto 4) <= "001" when (nCL = 5) else
                              "010" when (nCL = 6) else
                              "011" when (nCL = 7) else
                              "100" when (nCL = 8) else
                              "101" when (nCL = 9) else
                              "110" when (nCL = 10) else
                              "111" when (nCL = 11) else
                              "111";
      load_mr0(7) <= '0';
      load_mr0(8) <= '1';		-- Reset DLL (init only)
      load_mr0(11 downto 9) <= "001" when (TWR_CYC = 5) else
                               "010" when (TWR_CYC = 6) else
                               "011" when (TWR_CYC = 7) else
                               "100" when (TWR_CYC = 8) else
                               "101" when (TWR_CYC = 9) else
                               "101" when (TWR_CYC = 10) else
                               "110" when (TWR_CYC = 11) else
                               "110" when (TWR_CYC = 12) else
                               "010";
      load_mr0(12) <= '0';		-- Precharge Power-Down DLL 'slow-exit'
      load_mr0(15 downto 13) <= "000";
   end generate;

   gen_load_mr0_DDR2 : if (not(DRAM_TYPE = "DDR3")) generate
      load_mr0(2 downto 0) <= "011" when (BURST_MODE = "8") else
                              "010" when (BURST_MODE = "4") else
                              "111";
      load_mr0(3) <= '0' when (BURST_TYPE = "SEQ") else
                     '1';
      load_mr0(6 downto 4) <= "011" when (nCL = 3) else
                              "100" when (nCL = 4) else
                              "101" when (nCL = 5) else
                              "110" when (nCL = 6) else
                              "111";
      load_mr0(7) <= '0';
      load_mr0(8) <= '1';		-- Reset DLL (init only)
      load_mr0(11 downto 9) <= "001" when (TWR_CYC = 2) else
                               "010" when (TWR_CYC = 3) else
                               "011" when (TWR_CYC = 4) else
                               "100" when (TWR_CYC = 5) else
                               "101" when (TWR_CYC = 6) else
                               "010";
      load_mr0(15 downto 12) <= "0000"; -- Reserved
   end generate;

   --*****************************************************************
   -- DDR3 Load mode reg1
   -- Mode Register (MR1):
   --   [15:13] - unused          - 00
   --   [12]    - output enable   - 0 (enabled for DQ, DQS, DQS#)
   --   [11]    - TDQS enable     - 0 (TDQS disabled and DM enabled)
   --   [10]    - reserved   - 0 (must be '0')
   --   [9]     - RTT[2]     - 0 
   --   [8]     - reserved   - 0 (must be '0')
   --   [7]     - write leveling - 0 (disabled), 1 (enabled)
   --   [6]     - RTT[1]          - RTT[1:0] = 0(no ODT), 1(75), 2(150), 3(50)
   --   [5]     - Output driver impedance[1] - 0 (RZQ/6 and RZQ/7)
   --   [4:3]   - Additive CAS    - ADDITIVE_CAS
   --   [2]     - RTT[0]
   --   [1]     - Output driver impedance[0] - 0(RZQ/6), or 1 (RZQ/7)
   --   [0]     - DLL enable      - 0 (normal)
   -- DDR2 ext mode register
   -- Extended Mode Register (MR):
   --   [15:14] - unused          - 00
   --   [13]    - reserved        - 0
   --   [12]    - output enable   - 0 (enabled)
   --   [11]    - RDQS enable     - 0 (disabled)
   --   [10]    - DQS# enable     - 0 (enabled)
   --   [9:7]   - OCD Program     - 111 or 000 (first 111, then 000 during init)
   --   [6]     - RTT[1]          - RTT[1:0] = 0(no ODT), 1(75), 2(150), 3(50)
   --   [5:3]   - Additive CAS    - ADDITIVE_CAS
   --   [2]     - RTT[0]
   --   [1]     - Output drive    - REDUCE_DRV (= 0(full), = 1 (reduced)
   --   [0]     - DLL enable      - 0 (normal)
   --*****************************************************************
   gen_load_mr1_DDR3 : if (DRAM_TYPE = "DDR3") generate
      load_mr1(0) <= '0';		-- DLL enabled during Imitialization
      load_mr1(1) <= '0' when (OUTPUT_DRV = "LOW") else
                     '1';
      load_mr1(2) <= '1' when ((RTT_NOM = "30") or (RTT_NOM = "40") or (RTT_NOM = "60")) else
                     '0';
      load_mr1(4 downto 3) <= "00" when (AL = "0") else
                              "01" when (AL = "CL-1") else
                              "10" when (AL = "CL-2") else
                              "11";
      load_mr1(5) <= '0';
      load_mr1(6) <= '1' when ((RTT_NOM = "40") or (RTT_NOM = "120")) else
                     '0';
      load_mr1(7) <= '0';		-- Enable write lvl after init sequence
      load_mr1(8) <= '0';
      load_mr1(9) <= '1' when ((RTT_NOM = "20") or (RTT_NOM = "30")) else
                     '0';
      load_mr1(10) <= '0';
      load_mr1(15 downto 11) <= "00000";
   end generate;

   gen_load_mr1_DDR2 : if (not(DRAM_TYPE = "DDR3")) generate
      load_mr1(0) <= '0';		-- DLL enabled during Imitialization
      load_mr1(1) <= '1' when (OUTPUT_DRV = "LOW") else
                     '0';
      load_mr1(2) <= '1' when ((RTT_NOM = "75") or (RTT_NOM = "50")) else
                     '0';
      load_mr1(5 downto 3) <= "000" when (AL = "0") else
                              "001" when (AL = "1") else
                              "010" when (AL = "2") else
                              "011" when (AL = "3") else
                              "100" when (AL = "4") else
                              "111";
      load_mr1(6) <= '1' when ((RTT_NOM = "50") or (RTT_NOM = "150")) else
                     '0';
      load_mr1(9 downto 7) <= "000";
      load_mr1(10) <= '0' when (DDR2_DQSN_ENABLE = "YES") else
                      '1';
      load_mr1(15 downto 11) <= "00000";
   end generate; 

   --*****************************************************************
   -- DDR3 Load mode reg2
   -- Mode Register (MR2):
   --   [15:11] - unused     - 00
   --   [10:9]  - RTT_WR     - 00 (Dynamic ODT off) 
   --   [8]     - reserved   - 0 (must be '0')
   --   [7]     - self-refresh temperature range - 
   --               0 (normal), 1 (extended)
   --   [6]     - Auto Self-Refresh - 0 (manual), 1(auto)
   --   [5:3]   - CAS Write Latency (CWL) - 
   --               000 (5 for 400 MHz device), 
   --               001 (6 for 400 MHz to 533 MHz devices), 
   --               010 (7 for 533 MHz to 667 MHz devices), 
   --               011 (8 for 667 MHz to 800 MHz)
   --   [2:0]   - Partial Array Self-Refresh (Optional)      - 
   --               000 (full array)
   -- Not used for DDR2 
   --*****************************************************************   
   gen_load_mr2_DDR3 : if (DRAM_TYPE = "DDR3") generate
      load_mr2(2 downto 0) <= "000";
      load_mr2(5 downto 3) <= "000" when (nCWL = 5) else
                              "001" when (nCWL = 6) else
                              "010" when (nCWL = 7) else
                              "011" when (nCWL = 8) else
                              "111";
      load_mr2(6) <= '0';
      load_mr2(7) <= '0';
      load_mr2(8) <= '0';		-- Dynamic ODT disabled
      load_mr2(10 downto 9) <= "00";
      load_mr2(15 downto 11) <= "00000";
   end generate;

   gen_load_mr2_DDR2 : if (not(DRAM_TYPE = "DDR3")) generate
      load_mr2(15 downto 0) <= (others => '0');
   end generate;

   --*****************************************************************
   -- DDR3 Load mode reg3
   -- Mode Register (MR3):
   --   [15:3] - unused        - All zeros
   --   [2]    - MPR Operation - 0(normal operation), 1(data flow from MPR)
   --   [1:0]  - MPR location  - 00 (Predefined pattern)
   --*****************************************************************
   load_mr3(1 downto 0) <= "00";
   load_mr3(2) <= '0';
   load_mr3(15 downto 3) <= (others => '0');

   -- For multi-rank systems the rank being accessed during writes in 
   -- Read Leveling must be sent to phy_write for the bitslip logic
   -- Due to timing issues this signal is registered in phy_top.v
   chip_cnt <= chip_cnt_r;
   
   --***************************************************************************
   -- Logic to begin initial calibration, and to handle precharge requests
   -- during read-leveling (to avoid tRAS violations if individual read 
   -- levelling calibration stages take more than max{tRAS) to complete). 
   --***************************************************************************
   
   -- Assert when readback for each stage of read-leveling begins. However,
   -- note this indicates only when the read command is issued, it does not
   -- indicate when the read data is present on the bus (when this happens 
   -- after the read command is issued depends on CAS LATENCY) - there will 
   -- need to be some delay before valid data is present on the bus. 
   rdlvl_start_pre(0) <= '1' when (init_state_r = INIT_RDLVL_STG1_READ) else '0';
   rdlvl_start_pre(1) <= '1' when (init_state_r = INIT_RDLVL_STG2_READ) else '0';
   rdlvl_start_pre_clkdiv <= '1' when (init_state_r = INIT_RDLVL_CLKDIV_READ) else '0';
   
   -- Similar comment applies to start of PHASE DETECTOR
   pd_cal_start_pre <= '1' when (init_state_r = INIT_PD_READ) else '0';
   
   -- Common precharge signal done signal - pulses only when there has been
   -- a precharge issued as a result of a PRECH_REQ pulse. Note also a common
   -- PRECH_DONE signal is used for all blocks
   prech_done_pre <= '1' when (((init_state_r = INIT_RDLVL_STG1_READ) or (init_state_r = INIT_RDLVL_STG2_READ) or
                                (init_state_r = INIT_RDLVL_CLKDIV_READ) or
		                (init_state_r = INIT_PD_READ)) and (prech_pending_r = '1') and (prech_req_posedge_r = '0')) else '0';
   
   -- Delay start of each calibration by 16 clock cycles to ensure that when 
   -- calibration logic begins, read data is already appearing on the bus.   
   -- Each circuit should synthesize using an SRL16. Assume that reset is
   -- long enough to clear contents of SRL16. 
   process (clk)
   begin
      if (clk'event and clk = '1') then
         rdlvl_start_dly0_r <= (rdlvl_start_dly0_r(14 downto 0) & rdlvl_start_pre(0)) after (TCQ)*1 ps;
         rdlvl_start_dly1_r <= (rdlvl_start_dly1_r(14 downto 0) & rdlvl_start_pre(1)) after (TCQ)*1 ps;
         rdlvl_start_dly_clkdiv_r <= (rdlvl_start_dly_clkdiv_r(14 downto 0) &  rdlvl_start_pre_clkdiv) after (TCQ)*1 ps ;
         pd_cal_start_dly_r <= (pd_cal_start_dly_r(14 downto 0) & pd_cal_start_pre) after (TCQ)*1 ps;
         prech_done_dly_r <= (prech_done_dly_r(14 downto 0) & prech_done_pre) after (TCQ)*1 ps;
      end if;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         prech_done <= prech_done_dly_r(15) after (TCQ)*1 ps;
      end if;
   end process;

   -- Generate latched signals for start of write and read leveling
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            rdlvl_start_xhdl2 <= "00" after (TCQ)*1 ps;
            rdlvl_clkdiv_start_xhdl4 <= '0' after (TCQ)*1 ps;
            pd_cal_start <= '0' after (TCQ)*1 ps;
         else
            if ((rdlvl_start_dly0_r(15)) = '1') then
               rdlvl_start_xhdl2(0) <= '1' after (TCQ)*1 ps;
            end if;
            if ((rdlvl_start_dly1_r(15)) = '1') then
               rdlvl_start_xhdl2(1) <= '1' after (TCQ)*1 ps;
            end if;
            if ((rdlvl_start_dly_clkdiv_r(15)) = '1') then
               rdlvl_clkdiv_start_xhdl4 <= '1' after (TCQ)*1 ps;
            end if;            
            if ((pd_cal_start_dly_r(15)) = '1') then
               pd_cal_start <= '1' after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;

   -- Constantly enable DQS while write leveling is enabled in the memory
   -- This is more to get rid of warnings in simulation, can later change
   -- this code to only enable WRLVL_ACTIVE when WRLVL_START is asserted
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            enable_wrlvl_cnt <= "00000" after (TCQ)*1 ps;
         elsif (init_state_r = INIT_WRLVL_START) then
            enable_wrlvl_cnt <= "10100" after (TCQ)*1 ps;
         elsif (enable_wrlvl_cnt > "00000") then
            enable_wrlvl_cnt <= enable_wrlvl_cnt - '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if ((rst or wrlvl_rank_done or wrlvl_done) = '1') then
            wrlvl_active_xhdl3 <= '0' after (TCQ)*1 ps;
         elsif ((enable_wrlvl_cnt = "00001") and (not(wrlvl_active_xhdl3)) = '1') then
            wrlvl_active_xhdl3 <= '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if ((rst or wrlvl_rank_done or wrlvl_done) = '1') then
            wrlvl_odt <= '0' after (TCQ)*1 ps;
         elsif (enable_wrlvl_cnt = "01110") then
            wrlvl_odt <= '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         wrlvl_odt_r1 <= wrlvl_odt;
         wrlvl_done_r <= wrlvl_done after (TCQ)*1 ps;
         wrlvl_done_r1 <= wrlvl_done_r after (TCQ)*1 ps;
         wrlvl_rank_done_r1 <= wrlvl_rank_done after (TCQ)*1 ps;
         wrlvl_rank_done_r2 <= wrlvl_rank_done_r1 after (TCQ)*1 ps;
         wrlvl_rank_done_r3 <= wrlvl_rank_done_r2 after (TCQ)*1 ps;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            wrlvl_rank_cntr <= "000" after (TCQ)*1 ps;
         elsif (wrlvl_rank_done = '1') then
            wrlvl_rank_cntr <= wrlvl_rank_cntr + '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;

   --*****************************************************************
   -- Precharge request logic - those calibration logic blocks
   -- that require greater than tRAS(max) to finish must break up
   -- their calibration into smaller units of time, with precharges
   -- issued in between. This is done using the XXX_PRECH_REQ and
   -- PRECH_DONE handshaking between PHY_INIT and those blocks
   --*****************************************************************

   -- Shared request from multiple sources
   prech_req <= rdlvl_prech_req or pd_prech_req;
   
   -- Handshaking logic to force precharge during read leveling, and to
   -- notify read leveling logic when precharge has been initiated and
   -- it's okay to proceed with leveling again
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            prech_req_r <= '0' after (TCQ)*1 ps;
            prech_req_posedge_r <= '0' after (TCQ)*1 ps;
            prech_pending_r <= '0' after (TCQ)*1 ps;
         else
            prech_req_r <= prech_req after (TCQ)*1 ps;
            prech_req_posedge_r <= prech_req and not(prech_req_r) after (TCQ)*1 ps;
            if (prech_req_posedge_r = '1') then
               -- Clear after we've finished with the precharge and have
               -- returned to issuing read leveling calibration reads
               prech_pending_r <= '1' after (TCQ)*1 ps;
            elsif (prech_done_pre = '1') then
               prech_pending_r <= '0' after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;
   
   --***************************************************************************
   -- Various timing counters
   --***************************************************************************
   
   --*****************************************************************
   -- Generic delay for various states that require it (e.g. for turnaround
   -- between read and write). Make this a sufficiently large number of clock
   -- cycles to cover all possible frequencies and memory components)
   -- Requirements for this counter:
   --  1. Greater than tMRD
   --  2. tRFC (refresh-active) for DDR2
   --  3. (list the other requirements, slacker...)
   --*****************************************************************  
   process (clk)
   begin
      if (clk'event and clk = '1') then
         case (init_state_r) is
            when INIT_LOAD_MR_WAIT |
                 INIT_WRLVL_LOAD_MR_WAIT |
                 INIT_WRLVL_LOAD_MR2_WAIT |
                 INIT_RDLVL_ACT_WAIT |
                 INIT_RDLVL_STG1_WRITE_READ |
                 INIT_RDLVL_STG2_WRITE_READ |
                 INIT_RDLVL_CLKDIV_WRITE_READ |
                 INIT_RDLVL_STG2_READ_WAIT |
                 INIT_PD_ACT_WAIT |
                 INIT_PRECHARGE_PREWAIT |
                 INIT_PRECHARGE_WAIT |
                 INIT_DDR2_PRECHARGE_WAIT |
                 INIT_REG_WRITE_WAIT |
                 INIT_REFRESH_WAIT =>
               cnt_cmd_r <= cnt_cmd_r + '1' after (TCQ)*1 ps;
            when INIT_WRLVL_WAIT =>
               cnt_cmd_r <= (others => '0') after (TCQ)*1 ps;
            when others =>
               cnt_cmd_r <= (others => '0') after (TCQ)*1 ps;
         end case;
      end if;
   end process;
      
   -- pulse when count reaches terminal count
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (cnt_cmd_r = CNTNEXT_CMD) then     
            cnt_cmd_done_r <= '1' after (TCQ)*1 ps;
         else   
            cnt_cmd_done_r <= '0' after (TCQ)*1 ps;
         end if;   
      end if;
   end process;         
   --*****************************************************************
   -- Initial delay after power-on for RESET, CKE
   -- NOTE: Could reduce power consumption by turning off these counters
   --       after initial power-up (at expense of more logic)
   -- NOTE: Likely can combine multiple counters into single counter
   --*****************************************************************
   
   -- Create divided by 1024 version of clock 
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            cnt_pwron_ce_r <= "00" & X"00" after (TCQ)*1 ps;
            pwron_ce_r <= '0' after (TCQ)*1 ps;
         else
            cnt_pwron_ce_r <= cnt_pwron_ce_r + '1' after (TCQ)*1 ps;
	    if (cnt_pwron_ce_r = "1111111111") then
	       pwron_ce_r <= '1'after (TCQ)*1 ps;
            else    
	       pwron_ce_r <= '0'after (TCQ)*1 ps;
            end if;   
         end if;
      end if;
   end process;
   
   
   -- "Main" power-on counter - ticks every CLKDIV/1024 cycles
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            cnt_pwron_r <= (others => '0') after (TCQ)*1 ps;
         elsif (pwron_ce_r = '1') then
            
            cnt_pwron_r <= cnt_pwron_r + '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            cnt_pwron_reset_done_r <= '0' after (TCQ)*1 ps;
            cnt_pwron_cke_done_r <= '0' after (TCQ)*1 ps;
         else
            -- skip power-up count for simulation purposes only
            if ((SIM_INIT_OPTION = "SKIP_PU_DLY") or (SIM_INIT_OPTION = "SKIP_INIT")) then
               cnt_pwron_reset_done_r <= '1' after (TCQ)*1 ps;
               cnt_pwron_cke_done_r <= '1' after (TCQ)*1 ps;
            else
               -- otherwise, create latched version of done signal for RESET, CKE
               if (DRAM_TYPE = "DDR3") then
                  if (cnt_pwron_reset_done_r = '0') then
		     if (to_integer(unsigned(cnt_pwron_r)) = PWRON_RESET_DELAY_CNT) then
     			cnt_pwron_reset_done_r <= '1' after (TCQ)*1 ps;
		     else
     			cnt_pwron_reset_done_r <= '0' after (TCQ)*1 ps;
		     end if;	
                  end if;
                  if (cnt_pwron_cke_done_r = '0') then
		     if (to_integer(unsigned(cnt_pwron_r)) = PWRON_CKE_DELAY_CNT) then
     			cnt_pwron_cke_done_r <= '1' after (TCQ)*1 ps;
		     else
     			cnt_pwron_cke_done_r <= '0' after (TCQ)*1 ps;
		     end if;			   -- DDR2
                  end if;
               else
                  cnt_pwron_reset_done_r <= '1' after (TCQ)*1 ps; -- not needed 
                  if (cnt_pwron_cke_done_r = '0') then
		     if (to_integer(unsigned(cnt_pwron_r)) = PWRON_CKE_DELAY_CNT) then
     			cnt_pwron_cke_done_r <= '1' after (TCQ)*1 ps;
		     else
     			cnt_pwron_cke_done_r <= '0' after (TCQ)*1 ps;
		     end if;				  
                  end if;
               end if;
            end if;
         end if;
      end if;
   end process;
      
   -- Keep RESET asserted and CKE deasserted until after power-on delay
   process (clk)
   begin
      if (clk'event and clk = '1') then
         phy_reset_n <= cnt_pwron_reset_done_r after (TCQ)*1 ps;
         phy_cke0 <= (others => cnt_pwron_cke_done_r) after (TCQ)*1 ps;
         phy_cke1 <= (others => cnt_pwron_cke_done_r) after (TCQ)*1 ps;
      end if;
   end process;
      
   --*****************************************************************
   -- Counter for tXPR (pronouned "Tax-Payer") - wait time after 
   -- CKE deassertion before first MRS command can be asserted
   --*****************************************************************   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (cnt_pwron_cke_done_r = '0') then
            cnt_txpr_r <= (others => '0') after (TCQ)*1 ps;
            cnt_txpr_done_r <= '0' after (TCQ)*1 ps;
         else
            cnt_txpr_r <= cnt_txpr_r + '1' after (TCQ)*1 ps;
            if ((not(cnt_txpr_done_r)) = '1') then
	       if (to_integer(unsigned(cnt_txpr_r)) = TXPR_DELAY_CNT) then
     	          cnt_txpr_done_r <= '1' after (TCQ)*1 ps;
	       else
     	          cnt_txpr_done_r <= '0' after (TCQ)*1 ps;
	       end if;	  
            end if;
         end if;
      end if;
   end process;
      
   --*****************************************************************
   -- Counter for the initial 400ns wait for issuing precharge all
   -- command after CKE assertion. Only for DDR2. 
   --*****************************************************************            
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (cnt_pwron_cke_done_r = '0') then
            cnt_init_pre_wait_r <= (others => '0') after (TCQ)*1 ps;
            cnt_init_pre_wait_done_r <= '0' after (TCQ)*1 ps;
         else
            cnt_init_pre_wait_r <= cnt_init_pre_wait_r + '1' after (TCQ)*1 ps;
            if (cnt_init_pre_wait_done_r /= '1') then
	       if (to_integer(unsigned(cnt_init_pre_wait_r)) >= DDR2_INIT_PRE_CNT) then
     	          cnt_init_pre_wait_done_r <= '1' after (TCQ)*1 ps;
	       else
     	          cnt_init_pre_wait_done_r <= '0' after (TCQ)*1 ps;
	       end if;	  
            end if;
         end if;
      end if;
   end process;

   --*****************************************************************
   -- Wait for both DLL to lock (tDLLK) and ZQ calibration to finish
   -- (tZQINIT). Both take the same amount of time (512*tCK)
   --*****************************************************************   
   -- Reset condition added to cnt_dll_zqinit_r, cnt_dll_zqinit_done_r 
   -- and stopped cnt_dllk_zqinit_r from free running to avoid corner 
   -- case where downstream signal mem_init_done_r can be asserted early in H/W (i.e. 
   -- without a reset if cnt_dll_zqinit_r is free running mem_init_done_r could be high earlier)

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            cnt_dllk_zqinit_r <= (others => '0');
         elsif (init_state_r = INIT_ZQCL) then
            cnt_dllk_zqinit_r <= (others => '0') after (TCQ)*1 ps;
         elsif ((init_state_r = INIT_WAIT_DLLK_ZQINIT) and 
                not(to_integer(unsigned(cnt_dllk_zqinit_r)) = TDLLK_TZQINIT_DELAY_CNT)) then
            cnt_dllk_zqinit_r <= cnt_dllk_zqinit_r + '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            cnt_dllk_zqinit_done_r <= '0' after (TCQ)*1 ps;
         elsif (init_state_r = INIT_ZQCL) then
            cnt_dllk_zqinit_done_r <= '0' after (TCQ)*1 ps;
         else
            if (cnt_dllk_zqinit_r = TDLLK_TZQINIT_DELAY_CNT) then
               cnt_dllk_zqinit_done_r <= '1' after (TCQ)*1 ps;
            else
               cnt_dllk_zqinit_done_r <= '0' after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;

      
   --*****************************************************************  
   -- Keep track of which MRS counter needs to be programmed during
   -- memory initialization
   -- The counter and the done signal are reset an additional time
   -- for DDR2. The same signals are used for the additional DDR2
   -- initialization sequence. 
   --*****************************************************************   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if ((init_state_r = INIT_IDLE) or ((init_state_r = INIT_REFRESH) and (mem_init_done_r1 = '0'))) then
            cnt_init_mr_r <= (others => '0') after (TCQ)*1 ps;
            cnt_init_mr_done_r <= '0' after (TCQ)*1 ps;
         elsif (init_state_r = INIT_LOAD_MR) then
            cnt_init_mr_r <= cnt_init_mr_r + '1' after (TCQ)*1 ps;
	    if (cnt_init_mr_r = INIT_CNT_MR_DONE) then
	       cnt_init_mr_done_r <= '1' after (TCQ)*1 ps;
            else
	       cnt_init_mr_done_r <= '0' after (TCQ)*1 ps;		    
            end if;   
         end if;
      end if;
   end process;
   
   
   --*****************************************************************  
   -- Flag to tell if the first precharge for DDR2 init sequence is
   -- done 
   --*****************************************************************   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (init_state_r = INIT_IDLE) then
            ddr2_pre_flag_r <= '0' after (TCQ)*1 ps;
         elsif (init_state_r = INIT_LOAD_MR) then
            -- reset the flag for multi rank case 
            ddr2_pre_flag_r <= '1' after (TCQ)*1 ps;
         elsif ((ddr2_refresh_flag_r = '1') and (init_state_r = INIT_LOAD_MR_WAIT) and (cnt_cmd_done_r = '1') and (cnt_init_mr_done_r = '1')) then
            ddr2_pre_flag_r <= '0' after (TCQ)*1 ps;
         end if;
      end if;
   end process;

   --*****************************************************************  
   -- Flag to tell if the refresh stat  for DDR2 init sequence is
   -- reached 
   --*****************************************************************               
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (init_state_r = INIT_IDLE) then
            ddr2_refresh_flag_r <= '0' after (TCQ)*1 ps;
         elsif ((init_state_r = INIT_REFRESH) and (mem_init_done_r1 = '0')) then
            -- reset the flag for multi rank case 
            ddr2_refresh_flag_r <= '1' after (TCQ)*1 ps;
         elsif ((ddr2_refresh_flag_r = '1') and (init_state_r = INIT_LOAD_MR_WAIT) and 
	        (cnt_cmd_done_r = '1') and (cnt_init_mr_done_r = '1')) then
            ddr2_refresh_flag_r <= '0' after (TCQ)*1 ps;
         end if;
      end if;
   end process;

   --*****************************************************************  
   -- Keep track of the number of auto refreshes for DDR2 
   -- initialization. The spec asks for a minimum of two refreshes.
   -- Four refreshes are performed here. The two extra refreshes is to
   -- account for the 200 clock cycle wait between step h and l.
   -- Without the two extra refreshes we would have to have a
   -- wait state. 
   --*****************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (init_state_r = INIT_IDLE) then
            cnt_init_af_r <= (others => '0') after (TCQ)*1 ps;
            cnt_init_af_done_r <= '0' after (TCQ)*1 ps;
         elsif ((init_state_r = INIT_REFRESH) and (mem_init_done_r1 = '0')) then
            cnt_init_af_r <= cnt_init_af_r + '1' after (TCQ)*1 ps;
	    if (cnt_init_af_r = "11") then
	       cnt_init_af_done_r <= '1' after (TCQ)*1 ps;
            else   
	       cnt_init_af_done_r <= '0' after (TCQ)*1 ps;
            end if;   
   	 end if;
      end if;
   end process;
      
   --*****************************************************************  
   -- Keep track of the register control word programming for
   -- DDR3 RDIMM 
   --*****************************************************************   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (init_state_r = INIT_IDLE) then
            reg_ctrl_cnt_r <= (others => '0') after (TCQ)*1 ps;
         elsif (init_state_r = INIT_REG_WRITE) then
            reg_ctrl_cnt_r <= reg_ctrl_cnt_r + '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;

   --***************************************************************************
   -- Initialization state machine
   --***************************************************************************
   
   --*****************************************************************
   -- Next-state logic 
   --*****************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            init_state_r <= INIT_IDLE after (TCQ)*1 ps;
            init_state_r1 <= INIT_IDLE after (TCQ)*1 ps;
         else
            init_state_r <= init_next_state after (TCQ)*1 ps;
            init_state_r1 <= init_state_r after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   
   process (burst_addr_r, chip_cnt_r, cnt_cmd_done_r, cnt_dllk_zqinit_done_r,
	    cnt_init_af_done_r, cnt_init_mr_done_r, 
	    cnt_init_pre_wait_done_r, cnt_pwron_cke_done_r, cnt_txpr_done_r,
	    ddr2_pre_flag_r, ddr2_refresh_flag_r, ddr3_lm_done_r, init_state_r,
	    mem_init_done_r1, mem_init_done_r, pd_cal_done, prech_req_posedge_r,
            rdlvl_clkdiv_done, rdlvl_clkdiv_start_xhdl4,
	    rdlvl_done, rdlvl_resume, rdlvl_start_xhdl2, rdpath_rdy, reg_ctrl_cnt_r,
	    wrlvl_done_r1, wrlvl_rank_done_r3,auto_cnt_r)
   begin
      init_next_state <= init_state_r;
      
      case init_state_r is
      --*******************************************************
      -- DRAM initialization
      --*******************************************************
      
      -- Initial state - wait for:
      --   1. Power-on delays to pass
      --   2. Read path initialization to finish
         
         when INIT_IDLE =>
            if ((cnt_pwron_cke_done_r = '1') and (rdpath_rdy = '1')) then		 
               -- If skipping memory initialization (simulation only)
               if (SIM_INIT_OPTION = "SKIP_INIT") then
                  if (WRLVL = "ON") then
		     -- Proceed to write leveling 	  
                     init_next_state <= INIT_WRLVL_START;
                  elsif (not(SIM_CAL_OPTION = "SKIP_CAL")) then
		     -- Proceed to read leveling	  
                     init_next_state <= INIT_RDLVL_ACT;
                  else
		     -- Skip read leveling     
                     init_next_state <= INIT_DONE;
                  end if;
               else
                  init_next_state <= INIT_WAIT_CKE_EXIT;
               end if;
            end if;

         -- Wait minimum of Reset CKE exit time (tXPR = max(tXS,         
         when INIT_WAIT_CKE_EXIT =>
            if ((cnt_txpr_done_r = '1') and (DRAM_TYPE = "DDR3")) then
               if ((REG_CTRL = "ON") and ((nCS_PER_RANK > 1) or (CS_WIDTH > 1))) then
                  -- register write for reg dimm. Some register chips
                  -- have the register chip in a pre-programmed state
                  -- in that case the nCS_PER_RANK == 1 && CS_WIDTH == 1 		       
                  init_next_state <= INIT_REG_WRITE;
               else
                  -- Load mode register - this state is repeated multiple times
                  init_next_state <= INIT_LOAD_MR;
               end if;
            elsif (((cnt_init_pre_wait_done_r)) = '1' and (DRAM_TYPE = "DDR2")) then
               -- DDR2 start with a precharge all command 
               init_next_state <= INIT_DDR2_PRECHARGE;
            end if;
         
         when INIT_REG_WRITE =>
            init_next_state <= INIT_REG_WRITE_WAIT;
         
         when INIT_REG_WRITE_WAIT =>
            if (cnt_cmd_done_r = '1') then
               if (reg_ctrl_cnt_r = "101") then
                  init_next_state <= INIT_LOAD_MR;
               else
                  init_next_state <= INIT_REG_WRITE;
               end if;
            end if;
         
         when INIT_LOAD_MR =>
            init_next_state <= INIT_LOAD_MR_WAIT;

         -- After loading MR, wait at least tMRD
         when INIT_LOAD_MR_WAIT =>
            if (cnt_cmd_done_r = '1') then
               -- If finished loading all mode registers, proceed to next step
               if (AND_BR(rdlvl_done) = '1') then
                  -- for ddr3 when the correct burst length is writtern at end
                  init_next_state <= INIT_PRECHARGE;
               elsif (cnt_init_mr_done_r = '1') then
                  if (DRAM_TYPE = "DDR3") then
                     init_next_state <= INIT_ZQCL;
                  else		-- DDR2
                     if (ddr2_refresh_flag_r = '1') then
                        -- memory initialization per rank for multi-rank case
                        if ((not(mem_init_done_r1)) = '1' and (chip_cnt_r <= std_logic_vector(to_unsigned(CS_WIDTH - 1, 2)))) then
                           init_next_state <= INIT_DDR2_MULTI_RANK;
                        else
                           init_next_state <= INIT_RDLVL_ACT;
                           -- ddr2 initialization done.load mode state after refresh
                        end if;
                     else
                        init_next_state <= INIT_DDR2_PRECHARGE;
                     end if;
                  end if;
               else
                  init_next_state <= INIT_LOAD_MR;
               end if;
            end if;
         
         -- DDR2 multi rank transition state
         when INIT_DDR2_MULTI_RANK =>
            init_next_state <= INIT_DDR2_MULTI_RANK_WAIT;
         
         when INIT_DDR2_MULTI_RANK_WAIT =>
            init_next_state <= INIT_DDR2_PRECHARGE;
         
         -- Initial ZQ calibration 
         when INIT_ZQCL =>
            init_next_state <= INIT_WAIT_DLLK_ZQINIT;

         -- Wait until both DLL have locked, and ZQ calibration done
         when INIT_WAIT_DLLK_ZQINIT =>
            if (cnt_dllk_zqinit_done_r = '1') then
               -- memory initialization per rank for multi-rank case
               if ((not(mem_init_done_r)) = '1' and (chip_cnt_r <= std_logic_vector(to_unsigned(CS_WIDTH - 1, 2)))) then
                  init_next_state <= INIT_LOAD_MR;
               elsif (WRLVL = "ON") then
                  init_next_state <= INIT_WRLVL_START;
               else
                  -- skip write-leveling (e.g. for component interface)
                  init_next_state <= INIT_RDLVL_ACT;
               end if;
            end if;
         
         -- Initial precharge for DDR2
         when INIT_DDR2_PRECHARGE =>
            init_next_state <= INIT_DDR2_PRECHARGE_WAIT;
         
         when INIT_DDR2_PRECHARGE_WAIT =>
            if (cnt_cmd_done_r = '1') then
               if (ddr2_pre_flag_r = '1') then
                  init_next_state <= INIT_REFRESH;
               else		-- from precharge state initally go to load mode 
                  init_next_state <= INIT_LOAD_MR;
               end if;
            end if;
         
         when INIT_REFRESH =>
            init_next_state <= INIT_REFRESH_WAIT;

         when INIT_REFRESH_WAIT =>
            if (cnt_cmd_done_r = '1') then
               if ((cnt_init_af_done_r and (not(mem_init_done_r1))) = '1') then
	          -- go to lm state as part of DDR2 init sequence 
                  init_next_state <= INIT_LOAD_MR;
               elsif (mem_init_done_r1 = '1') then
 	          if (to_integer(unsigned(auto_cnt_r)) < CS_WIDTH) then     
                     init_next_state <= INIT_REFRESH;
                  elsif (((AND_BR(rdlvl_done))) = '1' and (PHASE_DETECT = "ON")) then
                     init_next_state <= INIT_PD_ACT;
	          else   
                     init_next_state <= INIT_RDLVL_ACT;
	          end if;   
               else		-- to DDR2 init state as part of DDR2 init sequence  
                  init_next_state <= INIT_REFRESH;
               end if;
            end if;
         
      --********************************************************
      -- Write Leveling
      --********************************************************

         -- Enable write leveling in MR1 and start write leveling
         -- for current rank	    
         when INIT_WRLVL_START =>
            init_next_state <= INIT_WRLVL_WAIT;
         
         -- Wait for both MR load and write leveling to complete
         -- (write leveling should take much longer than MR load..)
         when INIT_WRLVL_WAIT =>
            if (wrlvl_rank_done_r3 = '1') then
               init_next_state <= INIT_WRLVL_LOAD_MR;
            end if;
         
         -- Disable write leveling in MR1 for current rank
         when INIT_WRLVL_LOAD_MR =>
            init_next_state <= INIT_WRLVL_LOAD_MR_WAIT;
         
         when INIT_WRLVL_LOAD_MR_WAIT =>
            if (cnt_cmd_done_r = '1') then
               init_next_state <= INIT_WRLVL_LOAD_MR2;
            end if;
         
         -- Load MR2 to set ODT: Dynamic ODT for single rank case
         -- And ODTs for multi-rank case as well	    
         when INIT_WRLVL_LOAD_MR2 =>
            init_next_state <= INIT_WRLVL_LOAD_MR2_WAIT;
  
         -- Wait tMRD before proceeding
         when INIT_WRLVL_LOAD_MR2_WAIT =>
            if (cnt_cmd_done_r = '1') then
               if ((not(wrlvl_done_r1)) = '1') then
                  init_next_state <= INIT_WRLVL_START;
               elsif (SIM_CAL_OPTION = "SKIP_CAL") then
                  -- If skip rdlvl, then we're done
                  init_next_state <= INIT_DONE;
               else
                  -- Otherwise, proceed to read leveling 
                  init_next_state <= INIT_RDLVL_ACT;
               end if;
            end if;

      --********************************************************
      -- Read Leveling
      --********************************************************

         -- single row activate. All subsequent read leveling writes and 
         -- read will take place in this row  
         when INIT_RDLVL_ACT =>
            init_next_state <= INIT_RDLVL_ACT_WAIT;

         -- hang out for awhile before issuing subsequent column commands
         -- it's also possible to reach this state at various points
         -- during read leveling - determine what the current stage is 	    
         when INIT_RDLVL_ACT_WAIT =>
            if (cnt_cmd_done_r = '1') then
               -- Just finished an activate. Now either write, read, or precharge 
               -- depending on where we are in the training sequence
	       if ((not(rdlvl_done(0)) and not(rdlvl_start_xhdl2(0))) = '1') then
                  -- Case 1: If in stage 1, and entering for first time, then
                  --   write training pattern to memory		       
                  init_next_state <= INIT_IOCONFIG_WR;
               elsif ((not(rdlvl_done(0)) and rdlvl_start_xhdl2(0)) = '1') then
                  -- Case 2: If in stage 1, and just precharged after training
                  --   previous byte, then continue reading
                  init_next_state <= INIT_IOCONFIG_RD;
               elsif ((not(rdlvl_clkdiv_done) and not(rdlvl_clkdiv_start_xhdl4)) = '1') then
                  -- Case 3: If in CLKDIV cal, and entering for first time, then
                  --   write training pattern to memory
                  init_next_state <= INIT_IOCONFIG_WR;
               elsif ((not(rdlvl_clkdiv_done) and rdlvl_clkdiv_start_xhdl4) = '1') then
                  -- Case 4: If in CLKDIV cal, and just precharged after training
                  --   previous byte, then continue reading              
                  init_next_state <= INIT_IOCONFIG_RD;
               elsif ((not(rdlvl_done(1)) and not(rdlvl_start_xhdl2(1))) = '1') then
                  -- Case 5: If in stage 2, and entering for first time, then
                  --   write training pattern to memory		       
                  init_next_state <= INIT_IOCONFIG_WR;
               elsif ((not(rdlvl_done(1)) and rdlvl_start_xhdl2(1)) = '1') then
                  -- Case 6: If in stage 2, and just precharged after training
                  --   previous byte, then continue reading              		       
                  init_next_state <= INIT_IOCONFIG_RD;
               else
                  -- Otherwise, if we're finished with calibration, then precharge
                  -- the row - silly, because we just opened it - possible to take
                  -- this out by adding logic to avoid the ACT in first place. Make
                  -- sure that cnt_cmd_done will handle tRAS(min)		       
                  init_next_state <= INIT_PRECHARGE_PREWAIT;
               end if;
            end if;

      --***************************************************      
      -- Stage 1 read-leveling (write and continuous read)
      --***************************************************        	    

         -- Write training pattern for stage 1
         when INIT_RDLVL_STG1_WRITE =>
            -- Once we've issued enough commands for 16 words - proceed to reads
            -- Note that 16 words are written even though the training pattern
            -- is only 8 words (training pattern is written twice) because at
            -- this point in the calibration process we may be generating the
            -- DQS and DQ a few cycles early (that part of the write timing
            -- adjustment doesn't happen until stage 2)
            if (burst_addr_r = "11") then
               init_next_state <= INIT_RDLVL_STG1_WRITE_READ;
            end if;
         
         -- Write-read turnaround
         when INIT_RDLVL_STG1_WRITE_READ =>
            if (cnt_cmd_done_r = '1') then
               init_next_state <= INIT_IOCONFIG_RD;
            end if;

         -- Continuous read, where interruptible by precharge request from
         -- calibration logic. Also precharges when stage 1 is complete   	    
         when INIT_RDLVL_STG1_READ =>
            if ((rdlvl_done(0) or prech_req_posedge_r) = '1') then
               init_next_state <= INIT_PRECHARGE_PREWAIT;
            end if;

         --*********************************************      
         -- CLKDIV calibration read-leveling (write and continuous read)
         --*********************************************      

         -- Write training pattern for stage 1
         when INIT_RDLVL_CLKDIV_WRITE =>
            -- Once we've issued enough commands for 16 words - proceed to reads
            -- See comment for state RDLVL_STG1_WRITE
            if (burst_addr_r = "11") then
               init_next_state <= INIT_RDLVL_CLKDIV_WRITE_READ;
            end if;
               
         -- Write-read turnaround
         when INIT_RDLVL_CLKDIV_WRITE_READ => 
            if (cnt_cmd_done_r = '1') then
               init_next_state <= INIT_IOCONFIG_RD;
            end if;

         -- Continuous read, where interruptible by precharge request from
         -- calibration logic. Also precharges when stage 1 is complete
         when INIT_RDLVL_CLKDIV_READ =>
            if ((rdlvl_clkdiv_done or prech_req_posedge_r) = '1') then
               init_next_state <= INIT_PRECHARGE_PREWAIT;
            end if;
            
         --***************************************************      
         -- Stage 2 read-leveling (write and continuous read)
         --***************************************************

         -- Write training pattern for stage 1 
         when INIT_RDLVL_STG2_WRITE =>
            -- Once we've issued enough commands for 16 words - proceed to reads
            -- Write 8 extra words in order to prevent any previous data in
            -- memory from skewing calibration results (write 8 words for
            -- training pattern followed by 8 zeros)
           if (burst_addr_r = "11") then
               init_next_state <= INIT_RDLVL_STG2_WRITE_READ;
            end if;
         
         -- Write-read turnaround
         when INIT_RDLVL_STG2_WRITE_READ =>
            if (cnt_cmd_done_r = '1') then
               init_next_state <= INIT_IOCONFIG_RD;
            end if;

         -- Read of training data. Note that Stage 2 is not a constant read, 
         -- instead there is a large gap between each read	    
         when INIT_RDLVL_STG2_READ =>
            -- Keep reading for 8 words
            if (burst_addr_r = "01") then
               init_next_state <= INIT_RDLVL_STG2_READ_WAIT;
            end if;
         
         -- Wait before issuing the next read. If a precharge request comes in
         -- then handle it     
         when INIT_RDLVL_STG2_READ_WAIT =>
            if (rdlvl_resume = '1') then
               init_next_state <= INIT_IOCONFIG_WR;
            elsif ((rdlvl_done(1) = '1') or (prech_req_posedge_r = '1')) then
                  init_next_state <= INIT_PRECHARGE_PREWAIT;
	    elsif (cnt_cmd_done_r = '1') then
                  init_next_state <= INIT_RDLVL_STG2_READ;
            end if;

      --*********************************************      
      -- Phase detector initial calibration                                  
      --*********************************************

         -- single row activate. All subsequent PD calibration takes place
         -- using this row     	    
         when INIT_PD_ACT =>
            init_next_state <= INIT_PD_ACT_WAIT;
         
         -- hang out for awhile before issuing subsequent column command
         when INIT_PD_ACT_WAIT =>
            if (cnt_cmd_done_r = '1') then
               init_next_state <= INIT_IOCONFIG_RD;
            end if;

         -- Read of training data - constant reads. Note that for PD 
         -- calibration, data is not important - only DQS is used.
         -- PD calibration is interruptible by precharge request from 
         -- calibration logic. Also precharges a final time when PD cal done   	    
         when INIT_PD_READ =>
            if ((pd_cal_done or prech_req_posedge_r) = '1') then
               init_next_state <= INIT_PRECHARGE_PREWAIT;
            end if;

      --*********************************************      
      -- Handling of precharge during and in between read-level stages
      --*********************************************   

         -- Make sure we aren't violating any timing specs by precharging
         --  immediately   	    
         when INIT_PRECHARGE_PREWAIT =>
            if (cnt_cmd_done_r = '1') then
               init_next_state <= INIT_PRECHARGE;
            end if;
         
         -- Initiate precharge
         when INIT_PRECHARGE =>
            init_next_state <= INIT_PRECHARGE_WAIT;

         when INIT_PRECHARGE_WAIT =>
            if (cnt_cmd_done_r = '1') then
               if (((pd_cal_done = '1') or (not(PHASE_DETECT = "ON"))) and ((AND_BR(rdlvl_done))) = '1' and
	           (((ddr3_lm_done_r)) = '1' or (DRAM_TYPE = "DDR2"))) then
                  -- If read leveling and phase detection calibration complete, 
                  -- and programing the correct burst length then we're finished			   
                  init_next_state <= INIT_DONE;
               elsif (((pd_cal_done = '1') or (not(PHASE_DETECT = "ON"))) and ((AND_BR(rdlvl_done))) = '1') then
                  -- after all calibration program the correct burst length
                  init_next_state <= INIT_LOAD_MR;
               else
                  -- Otherwise, open row for read-leveling purposes
                  init_next_state <= INIT_REFRESH;
               end if;
            end if;
        
      --*******************************************************
      -- Wait a cycle before switching commands to pulse the IOCONFIG
      -- Time is needed to turn around the IODELAY. Wait state is
      -- added because IOCONFIG must be asserted 2 clock cycles before
      -- before corresponding command/address (probably a less logic-
      -- intensive way of doing this, that doesn't involve extra states)
      --*******************************************************	    
         when INIT_IOCONFIG_WR =>
            init_next_state <= INIT_IOCONFIG_WR_WAIT;

         when INIT_IOCONFIG_WR_WAIT =>
            if ((not(rdlvl_done(0))) = '1') then
               -- Write Stage 1 training pattern to memory
               init_next_state <= INIT_RDLVL_STG1_WRITE;
            elsif ((not(rdlvl_clkdiv_done)) = '1') then
               -- Write CLKDIV cal training pattern to memory
               init_next_state <= INIT_RDLVL_CLKDIV_WRITE;
            else
	       -- Write Stage 2 training pattern to memory
               init_next_state <= INIT_RDLVL_STG2_WRITE;
            end if;
         
         when INIT_IOCONFIG_RD =>
            init_next_state <= INIT_IOCONFIG_RD_WAIT;

         when INIT_IOCONFIG_RD_WAIT =>
            if ((not(rdlvl_done(0))) = '1') then
               -- Read Stage 1 training pattern from memory
               init_next_state <= INIT_RDLVL_STG1_READ;
            elsif ((not(rdlvl_clkdiv_done)) = '1') then
               -- Read CLKDIV cal training pattern from memory
               init_next_state <= INIT_RDLVL_CLKDIV_READ;              
            elsif ((not(rdlvl_done(1))) = '1') then
               -- Read Stage 2 training pattern from memory
               init_next_state <= INIT_RDLVL_STG2_READ;
            else
               -- Phase Detector read
               init_next_state <= INIT_PD_READ;
            end if;

      --*******************************************************
      -- Initialization/Calibration done. Take a long rest, relax
      --*******************************************************	    
         when INIT_DONE =>
            init_next_state <= INIT_DONE;

	 when others =>
	    null;	 

      end case;
   end process;
   
   
   --*****************************************************************
   -- Initialization done signal - asserted before leveling starts
   --*****************************************************************  
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            mem_init_done_r <= '0' after (TCQ)*1 ps;
         elsif (((not(cnt_dllk_zqinit_done_r) = '1') and (cnt_dllk_zqinit_r = std_logic_vector(to_unsigned(TDLLK_TZQINIT_DELAY_CNT, 8))) and 
	        (chip_cnt_r = std_logic_vector(to_unsigned(CS_WIDTH-1, 2))) and (DRAM_TYPE = "DDR3")) or ((init_state_r = 
		INIT_LOAD_MR_WAIT) and (ddr2_refresh_flag_r = '1') and (chip_cnt_r = std_logic_vector(to_unsigned(CS_WIDTH-1, 2))) and 
		(cnt_init_mr_done_r = '1') and (DRAM_TYPE = "DDR2"))) then
            mem_init_done_r <= '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;

   -- registered for timing. mem_init_done_r1 will be used in the
   -- design. The design can tolerate the extra cycle of latency. 
   process (clk)
   begin
      if (clk'event and clk = '1') then
         mem_init_done_r1 <= mem_init_done_r after (TCQ)*1 ps;         
      end if;
   end process;
   
   --*****************************************************************
   -- DDR3 final burst length programming done. For DDR3 during
   -- calibration the burst length is fixed to BL8. After calibration
   -- the correct burst length is programmed. 
   --*****************************************************************               
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            ddr3_lm_done_r <= '0' after (TCQ)*1 ps;
         elsif ((init_state_r = INIT_LOAD_MR_WAIT) and (chip_cnt_r = std_logic_vector(to_unsigned(CS_WIDTH-1, 2))) and
	        (AND_BR(rdlvl_done) = '1')) then
            ddr3_lm_done_r <= '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;

   --***************************************************************************
   -- Logic for deep memory (multi-rank) configurations
   -- 
   --***************************************************************************
   
   -- For DDR3 asserted when    
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1' or (wrlvl_done_r = '1' and (init_state_r = INIT_WRLVL_LOAD_MR2_WAIT))
             or (((mem_init_done_r and not(mem_init_done_r1)) = '1') and (DRAM_TYPE = "DDR2"))) then

            chip_cnt_r <= "00" after (TCQ)*1 ps;
         elsif ((init_state_r1 = INIT_REFRESH) and (mem_init_done_r1 = '1')) then
	    if (to_integer(unsigned(chip_cnt_r)) < (CS_WIDTH-1)) then
	       chip_cnt_r <= (chip_cnt_r + "01") after (TCQ)*1 ps;
	    else
               chip_cnt_r <= "00" after (TCQ)*1 ps;
            end if;   
         elsif ((((init_state_r = INIT_WAIT_DLLK_ZQINIT) and
	          (to_integer(unsigned(cnt_dllk_zqinit_r)) = TDLLK_TZQINIT_DELAY_CNT) and
                  (cnt_dllk_zqinit_done_r = '0')) or
	         (((init_state_r /= INIT_WRLVL_LOAD_MR2_WAIT) and
	       	   (init_next_state = INIT_WRLVL_LOAD_MR2_WAIT)) and
	       	  (DRAM_TYPE = "DDR3"))) or
	       	((init_state_r = INIT_DDR2_MULTI_RANK) and
	       	 (DRAM_TYPE = "DDR2")) or
                -- condition to increment chip_cnt during
                -- final burst length programming for DDR3 		
	       	((init_state_r = INIT_LOAD_MR_WAIT) and
	       	 (cnt_cmd_done_r = '1') and
	       	 (AND_BR(rdlvl_done) = '1'))) then

            if ((((mem_init_done_r1 = '0') or (AND_BR(rdlvl_done) = '1')) and (not(to_integer(unsigned(chip_cnt_r)) = (CS_WIDTH-1)))) or
	        ((mem_init_done_r1 = '1') and (AND_BR(rdlvl_done) = '0') and not(('0' & chip_cnt_r) = (calib_width-'1')))) then
               chip_cnt_r <= chip_cnt_r + '1' after (TCQ)*1 ps;
            else
               chip_cnt_r <= "00" after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;

   -- keep track of which chip selects got auto-refreshed (avoid auto-refreshing
   -- all CS's at once to avoid current spike)   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if ((rst = '1') or (init_state_r = INIT_PRECHARGE)) then
            auto_cnt_r <= (others => '0') after (TCQ)*1 ps;
	 elsif ((init_state_r = INIT_REFRESH) and (mem_init_done_r1 = '1')) then
	    if (to_integer(unsigned(auto_cnt_r)) < CS_WIDTH) then
	       auto_cnt_r <= (auto_cnt_r + "01") after (TCQ)*1 ps;
	    end if;
	 end if;    
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            phy_cs_n0 <= (others => '1') after (TCQ)*1 ps;
            phy_cs_n1 <= (others => '1') after (TCQ)*1 ps;
         else
            phy_cs_n0 <= (others => '1') after (TCQ)*1 ps;
            phy_cs_n1 <= (others => '1') after (TCQ)*1 ps;
            if (init_state_r = INIT_REG_WRITE) then
               phy_cs_n0 <= (others => '1') after (TCQ)*1 ps;
               phy_cs_n1 <= (others => '0') after (TCQ)*1 ps;
            elsif (wrlvl_odt = '1') then
               -- Component interface without fly-by topology
               -- must have all CS# outputs asserted simultaneously
               -- since it is a wide not deep interface
               if ((REG_CTRL = "OFF") and (nCS_PER_RANK > 1)) then
                  -- For single and dual rank RDIMMS and UDIMMs only
                  -- CS# of the selected rank must be asserted
                  phy_cs_n0 <= (others => '0') after (TCQ)*1 ps;
               else
                  phy_cs_n0 <= (others => '1') after (TCQ)*1 ps;
		  if (to_integer(unsigned(chip_cnt_r)) < CS_WIDTH*nCS_PER_RANK) then
                     phy_cs_n0(to_integer(unsigned(chip_cnt_r))) <= '0' after (TCQ)*1 ps;
	          end if;
               end if;
               phy_cs_n1 <= phy_tmp_cs1_r after (TCQ)*1 ps;
            elsif ((init_state_r = INIT_LOAD_MR) or
	           (init_state_r = INIT_ZQCL) or
		   (init_state_r = INIT_WRLVL_START) or
		   (init_state_r = INIT_WRLVL_LOAD_MR) or
		   (init_state_r = INIT_WRLVL_LOAD_MR2) or
		   (init_state_r = INIT_RDLVL_ACT) or
		   (init_state_r = INIT_RDLVL_STG1_WRITE) or
		   (init_state_r = INIT_RDLVL_STG1_READ) or
		   (init_state_r = INIT_PRECHARGE) or
		   (init_state_r = INIT_RDLVL_STG2_READ) or
		   (init_state_r = INIT_RDLVL_STG2_WRITE) or
                   (init_state_r = INIT_RDLVL_CLKDIV_READ) or
                   (init_state_r = INIT_RDLVL_CLKDIV_WRITE) or
                   (init_state_r = INIT_PD_ACT) or
		   (init_state_r = INIT_PD_READ) or
		   (init_state_r = INIT_DDR2_PRECHARGE) or
		   (init_state_r = INIT_REFRESH)) then
               phy_cs_n0 <= (others => '1') after (TCQ)*1 ps;
               phy_cs_n1 <= phy_tmp_cs1_r after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;
   
   
   --***************************************************************************
   -- Write/read burst logic for calibration
   --***************************************************************************   
   rdlvl_wr    <= '1' when ((init_state_r = INIT_RDLVL_STG1_WRITE) or (init_state_r = INIT_RDLVL_STG2_WRITE) or
                            (init_state_r = INIT_RDLVL_CLKDIV_WRITE)) else '0';
   rdlvl_rd    <= '1' when ((init_state_r = INIT_RDLVL_STG1_READ) or (init_state_r = INIT_RDLVL_STG2_READ) or
		            (init_state_r = INIT_RDLVL_CLKDIV_READ) or (init_state_r = INIT_PD_READ)) else '0';
   rdlvl_wr_rd <= rdlvl_wr or rdlvl_rd;

  -- Determine current DRAM address (lower bits of address) when writing or
  -- reading from memory during calibration (to access training patterns):
  --  (1) address must be initialized to 0 before entering all write/read
  --      states
  --  (2) for writes, the maximum address is = {2 * length of calibration
  --      training pattern}
  --  (3) for reads, the maximum address is = {length of calibration
  --      training pattern}, therefore it will need to be reinitialized
  --      while we remain in a read state since reads can occur continuously
  -- NOTE: For a training pattern length of 8, burst_addr is used to 
  -- such that the lower order bits of the address are given by = 
  -- {burst_addr, 2'b00}. This can be expanded for more bits if the training 
  -- sequence is longer than 8 words  
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rdlvl_rd = '1') then
            -- Reads only access first 8 words of memory, and the access can
            -- occur continously (i.e. w/o leaving the read state)
            burst_addr_r <= ('0' & not(burst_addr_r(0))) after (TCQ)*1 ps;
         elsif (rdlvl_wr = '1') then
            -- Writes will access first 16 words fo memory, and the access is
            -- only one-time (before leaving the write state)
            burst_addr_r <= burst_addr_r + '1' after (TCQ)*1 ps;
         else
            -- Otherwise, during any other states, reset address to 0
            burst_addr_r <= "00" after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   -- determine how often to issue row command during read leveling writes
   -- and reads   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rdlvl_wr_rd = '1') then
            if (BURST4_FLAG /= '0') then
               new_burst_r <= '1' after (TCQ)*1 ps;
            else
               new_burst_r <= not(new_burst_r) after (TCQ)*1 ps;
            end if;
         else
            new_burst_r <= '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;

   -- indicate when a write is occurring. PHY_WRDATA_EN must be asserted
   -- simultaneous with the corresponding command/address for CWL=5,6.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         rdlvl_wr_r <= rdlvl_wr after (TCQ)*1 ps;
      end if;
   end process;
      
   -- As per the tPHY_WRLAT spec phy_wrdata_en should be delayed
   -- for CWL >= 7    
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (CWL_M <= 4) then
            phy_wrdata_en_xhdl1 <= rdlvl_wr after (TCQ)*1 ps;
         elsif (CWL_M = 5) then
            phy_wrdata_en_xhdl1 <= rdlvl_wr after (TCQ)*1 ps;
         elsif (CWL_M = 6) then
            phy_wrdata_en_xhdl1 <= rdlvl_wr after (TCQ)*1 ps;
         elsif (CWL_M = 7) then
            phy_wrdata_en_xhdl1 <= rdlvl_wr_r after (TCQ)*1 ps;
         elsif (CWL_M = 8) then
            phy_wrdata_en_xhdl1 <= rdlvl_wr_r after (TCQ)*1 ps;
         elsif (CWL_M = 9) then
            phy_wrdata_en_xhdl1 <= rdlvl_wr_r after (TCQ)*1 ps;
         end if;
      end if;
   end process;
      
   -- generate the sideband signal to indicate when the bus turns around 
   -- from a write to a read, or vice versa. Used asserting signals related
   -- to the bus turnaround (e.g. IODELAY delay value)
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (init_state_r = INIT_IOCONFIG_WR) then
            -- Transition for writes 
            phy_ioconfig_en <= '1' after (TCQ)*1 ps;
            phy_ioconfig(0) <= '1' after (TCQ)*1 ps;
         elsif (init_state_r = INIT_IOCONFIG_RD) then
            -- Transition for reads      
            phy_ioconfig_en <= '1' after (TCQ)*1 ps;
            phy_ioconfig(0) <= '0' after (TCQ)*1 ps;
         else
            -- Keep PHY_IOCONFIG at whatever value it currently is
            -- Only assert strobe when a new value appears 
            phy_ioconfig_en <= '0' after (TCQ)*1 ps;
         end if;
      end if;
   end process;
      
   -- indicate when a write is occurring. PHY_RDDATA_EN must be asserted
   -- simultaneous with the corresponding command/address. PHY_RDDATA_EN
   -- is used during read-leveling to determine read latency
   process (clk)
   begin
      if (clk'event and clk = '1') then
         phy_rddata_en <= rdlvl_rd after (TCQ)*1 ps;
      end if;
   end process;

   --***************************************************************************
   -- Generate training data written at start of each read-leveling stage
   -- For every stage of read leveling, 8 words are written into memory
   -- The format is as follows (shown as {rise,fall}):
   --   Stage 1:    0xF, 0x0, 0xF, 0x0, 0xF, 0x0, 0xF, 0x0
   --   CLKDIV cal: 0xF, 0xF, 0xF. 0xF, 0x0, 0x0, 0x0, 0x0 
   --   Stage 2:    0xF, 0x0, 0xA, 0x5, 0x5, 0xA, 0x9, 0x6
   --***************************************************************************            
   process (clk)
   begin
      if (clk'event and clk = '1') then
         -- NOTE: No need to initialize cnt_init_data_r except possibly for
         --  simulation purposes (to prevent excessive warnings) since first
         --  state encountered before its use is RDLVL_STG1_WRITE 
         if (phy_wrdata_en_xhdl1 = '1') then
            cnt_init_data_r <= cnt_init_data_r + '1' after (TCQ)*1 ps;
         elsif ((init_state_r = INIT_IDLE) or (init_state_r = INIT_RDLVL_STG1_WRITE)) then
            cnt_init_data_r <= "0000" after (TCQ)*1 ps;
         elsif (init_state_r = INIT_RDLVL_CLKDIV_WRITE) then
            cnt_init_data_r <= "0100" after (TCQ)*1 ps;
         elsif (init_state_r = INIT_RDLVL_STG2_WRITE) then
            cnt_init_data_r <= "1000" after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         case cnt_init_data_r is
            -- Stage 1 calibration pattern (all 4 writes have same data)
            when "0000" |  "0001" | "0010" | "0011" =>
               phy_wrdata <= CALC_PHY_WRDATA(0) after (TCQ)*1 ps;
            -- Stage 3 calibration pattern (repeat twice)
            when "0100" | "0110" => 
               phy_wrdata <= CALC_PHY_WRDATA(4) after (TCQ)*1 ps;       
            when "0101" | "0111" =>
               phy_wrdata <= CALC_PHY_WRDATA(5) after (TCQ)*1 ps;
            -- Stage 2 calibration pattern (2 different sets of writes, each 8
            -- 2 different sets of writes, each 8words long
            when "1000" =>
               phy_wrdata <= CALC_PHY_WRDATA(8) after (TCQ)*1 ps;
            when "1001" =>
               phy_wrdata <= CALC_PHY_WRDATA(9) after (TCQ)*1 ps;
            when "1010" | "1011" =>
               phy_wrdata <= CALC_PHY_WRDATA(10) after (TCQ)*1 ps;
	    when others =>
	       null;   
         end case;
      end if;
   end process;               
   
   --***************************************************************************
   -- Memory control/address
   --***************************************************************************
   
   -- Assert RAS when: (1) Loading MRS, (2) Activating Row, (3) Precharging
   -- (4) auto refresh
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if ((init_state_r = INIT_LOAD_MR) or
	     (init_state_r = INIT_REG_WRITE) or
	     (init_state_r = INIT_WRLVL_START) or
	     (init_state_r = INIT_WRLVL_LOAD_MR) or
	     (init_state_r = INIT_WRLVL_LOAD_MR2) or
	     (init_state_r = INIT_RDLVL_ACT) or
	     (init_state_r = INIT_PD_ACT) or
	     (init_state_r = INIT_PRECHARGE) or
	     (init_state_r = INIT_DDR2_PRECHARGE) or
	     (init_state_r = INIT_REFRESH)) then
            phy_ras_n1 <= '0' after (TCQ)*1 ps;
            phy_ras_n0 <= '0' after (TCQ)*1 ps;
         else
            phy_ras_n1 <= '1' after (TCQ)*1 ps;
            phy_ras_n0 <= '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Assert CAS when: (1) Loading MRS, (2) Issuing Read/Write command
   -- (3) auto refresh
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if ((init_state_r = INIT_LOAD_MR) or
	 (init_state_r = INIT_REG_WRITE) or
	 (init_state_r = INIT_WRLVL_START) or
	 (init_state_r = INIT_WRLVL_LOAD_MR) or
	 (init_state_r = INIT_WRLVL_LOAD_MR2) or
	 (init_state_r = INIT_REFRESH) or
	 ((rdlvl_wr_rd and new_burst_r)) = '1') then
            phy_cas_n1 <= '0' after (TCQ)*1 ps;
            phy_cas_n0 <= '0' after (TCQ)*1 ps;
         else
            phy_cas_n1 <= '1' after (TCQ)*1 ps;
            phy_cas_n0 <= '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Assert WE when: (1) Loading MRS, (2) Issuing Write command (only
   -- occur during read leveling), (3) Issuing ZQ Long Calib command,
   -- (4) Precharge
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if ((init_state_r = INIT_LOAD_MR) or
	     (init_state_r = INIT_REG_WRITE) or
	     (init_state_r = INIT_ZQCL) or
	     (init_state_r = INIT_WRLVL_START) or
	     (init_state_r = INIT_WRLVL_LOAD_MR) or
	     (init_state_r = INIT_WRLVL_LOAD_MR2) or
	     (init_state_r = INIT_PRECHARGE) or
	     (init_state_r = INIT_DDR2_PRECHARGE) or
	     ((rdlvl_wr and new_burst_r)) = '1') then
            phy_we_n1 <= '0' after (TCQ)*1 ps;
            phy_we_n0 <= '0' after (TCQ)*1 ps;
         else
            phy_we_n1 <= '1' after (TCQ)*1 ps;
            phy_we_n0 <= '1' after (TCQ)*1 ps;
         end if;
      end if;
   end process;
      
   gen_rnk : for rnk_i in 0 to 3 generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst = '1') then
               mr2_r(rnk_i) <= "00" after (TCQ)*1 ps;
               mr1_r(rnk_i) <= "000" after (TCQ)*1 ps;
            else
               mr2_r(rnk_i) <= tmp_mr2_r(rnk_i) after (TCQ)*1 ps;
               mr1_r(rnk_i) <= tmp_mr1_r(rnk_i) after (TCQ)*1 ps;
            end if;
         end if;
      end process;
      
   end generate;
   
   -- ODT assignment based on slot config and slot present
   -- Assuming CS_WIDTH equals number of ranks configured
   -- For single slot systems slot_1_present input will be ignored
   -- Assuming component interfaces to be single slot systems
   gen_single_slot_odt : if (nSLOTS = 1) generate
      
      xhdl15 <= slot_0_present(0) & slot_0_present(1) & slot_0_present(2) & slot_0_present(3);

      xhdl16 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl17 <= "011" when (RTT_NOM = "40") else
                    xhdl16;
      xhdl18 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl19 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl20 <= "011" when (RTT_NOM = "40") else
                    xhdl19;
      xhdl21 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl22 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl23 <= "011" when (RTT_NOM = "40") else
                    xhdl22;
      xhdl24 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl25 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl26 <= "011" when (RTT_NOM = "40") else
                    xhdl25;
      xhdl27 <= "01" when (RTT_WR = "60") else
                    "10";
      process (clk)
      begin
         if (clk'event and clk = '1') then
            tmp_mr2_r(1) <= "00" after (TCQ)*1 ps;
            tmp_mr2_r(2) <= "00" after (TCQ)*1 ps;
            tmp_mr2_r(3) <= "00" after (TCQ)*1 ps;
            tmp_mr1_r(1) <= "000" after (TCQ)*1 ps;
            tmp_mr1_r(2) <= "000" after (TCQ)*1 ps;
            tmp_mr1_r(3) <= "000" after (TCQ)*1 ps;
            phy_tmp_cs1_r <= (others => '1') after (TCQ)*1 ps;
            phy_tmp_odt0_r  <= (others => '0') after (TCQ)*1 ps;
            phy_tmp_odt1_r  <= (others => '0') after (TCQ)*1 ps;
            phy_tmp_odt0_r1 <= phy_tmp_odt0_r after (TCQ)*1 ps;
            phy_tmp_odt1_r1 <= phy_tmp_odt1_r after (TCQ)*1 ps;

            -- Single slot configuration with quad rank
            -- Assuming same behavior as single slot dual rank for now
            -- DDR2 does not have quad rank parts 	    
            case xhdl15 is
               when "1111" =>
                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done) = '1') and (wrlvl_rank_cntr = "000"))) then
                     -- Rank0 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
                     -- Rank0 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl17 after (TCQ)*1 ps;
                  else
                     -- Rank0 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl18 after (TCQ)*1 ps;
                     -- Rank0 Rtt_NOM
                     tmp_mr1_r(0) <= "000" after (TCQ)*1 ps;
                  end if;
                  phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                  phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                  -- Chip Select assignments
		  if (to_integer(unsigned(chip_cnt_r)) < CS_WIDTH) then
		     for idx in 0 to nCS_PER_RANK-1 loop	  
                        phy_tmp_cs1_r(to_integer(unsigned(chip_cnt_r))*nCS_PER_RANK + idx) <= '0' after TCQ*1 ps;
		     end loop;  	
	          end if;

               -- Single slot configuration with single rank
               when "1000" =>
                  phy_tmp_odt0_r <= (others => '1') after (TCQ)*1 ps;
                  phy_tmp_odt1_r <= (others => '1') after (TCQ)*1 ps;
                  if ((REG_CTRL = "ON") and (nCS_PER_RANK > 1)) then
		     if (to_integer(unsigned(chip_cnt_r)) < CS_WIDTH*nCS_PER_RANK) then	  
                        phy_tmp_cs1_r(to_integer(unsigned(chip_cnt_r))) <= '0' after (TCQ)*1 ps;
		     end if;	
                  else
                     phy_tmp_cs1_r <= (others => '0') after (TCQ)*1 ps;
                  end if;
                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done) = '1'))) then
                     -- Rank0 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
                     -- Rank0 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl20 after (TCQ)*1 ps;
                  else
                     -- Rank0 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl21 after (TCQ)*1 ps;
                     -- Rank0 Rtt_NOM
                     tmp_mr1_r(0) <= "000" after (TCQ)*1 ps;
                  end if;

               -- Single slot configuration with dual rank
               when "1100" =>
                  phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                  phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;

 		  -- Chip Select assignments
		  if (to_integer(unsigned(chip_cnt_r)) < CS_WIDTH) then
		     for idx in 0 to nCS_PER_RANK-1 loop	  
                        phy_tmp_cs1_r(to_integer(unsigned(chip_cnt_r))*nCS_PER_RANK + idx) <= '0' after TCQ*1 ps; 
		     end loop;  	
	          end if;

                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done) = '1') and (wrlvl_rank_cntr = "000"))) then
                     -- Rank0 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
                     -- Rank0 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl23 after (TCQ)*1 ps;
                  else
                     -- Rank0 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl24 after (TCQ)*1 ps;
                     -- Rank0 Rtt_NOM
                     tmp_mr1_r(0) <= "000" after (TCQ)*1 ps;
                  end if;

               when others =>	
                  phy_tmp_odt0_r <= (others => '1') after (TCQ)*1 ps;
                  phy_tmp_odt1_r <= (others => '1') after (TCQ)*1 ps;
                  phy_tmp_cs1_r <= (others => '0') after (TCQ)*1 ps;
                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done)) = '1')) then
                     -- Rank0 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
                     -- Rank0 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl26 after (TCQ)*1 ps;
                  else
                     -- Rank0 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl27 after (TCQ)*1 ps;
                     -- Rank0 Rtt_NOM
                     tmp_mr1_r(0) <= "000" after (TCQ)*1 ps;
                  end if;
            end case;	-- case({slot_0_present[0],slot_0_present[1],...
         end if;
      end process;     
   end generate;

   gen_dual_slot_odt : if (nSLOTS = 2) generate

      xhdl30 <= slot_0_present(0) & slot_0_present(1) & slot_1_present(0) & slot_1_present(1);

      xhdl31 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl32 <= "011" when (RTT_NOM = "40") else
                    xhdl31;
      xhdl33 <= "01" when (RTT_WR = "60") else
                    "10";

      xhdl34 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl35 <= "011" when (RTT_NOM = "40") else
                    xhdl34;
      xhdl36 <= "01" when (RTT_WR = "60") else
                    "10";

      xhdl37 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl38 <= "011" when (RTT_NOM = "40") else
                    xhdl37;
      xhdl39 <= "01" when (RTT_WR = "60") else
                    "10";

      xhdl40 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl41 <= "011" when (RTT_NOM = "40") else
                    xhdl40;
      xhdl42 <= "01" when (RTT_WR = "60") else
                    "10";

      xhdl43 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl44 <= "011" when (RTT_NOM = "40") else
                    xhdl43;

      xhdl45 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl46 <= "011" when (RTT_NOM = "40") else
                    xhdl45;
      xhdl47 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl48 <= "101" when (RTT_NOM = "30") else
                    "011";
      xhdl49 <= "100" when (RTT_NOM = "20") else
                    xhdl48;
      xhdl50 <= "010" when (RTT_NOM = "120") else
                    xhdl49;
      xhdl51 <= "001" when (RTT_NOM = "60") else
                    xhdl50;
      xhdl52 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl53 <= "101" when (RTT_NOM = "30") else
                    "011";
      xhdl54 <= "100" when (RTT_NOM = "20") else
                    xhdl53;
      xhdl55 <= "010" when (RTT_NOM = "120") else
                    xhdl54;
      xhdl56 <= "001" when (RTT_NOM = "60") else
                    xhdl55;
      xhdl57 <= "101" when (RTT_NOM3 = "030") else
                    "011";
      xhdl58 <= "100" when (RTT_NOM3 = "020") else
                    xhdl57;
      xhdl59 <= "010" when (RTT_NOM3 = "120") else
                    xhdl58;
      xhdl60 <= "001" when (RTT_NOM3 = "060") else
                    xhdl59;
      xhdl61 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl62 <= "011" when (RTT_NOM = "40") else
                    xhdl61;
      xhdl63 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl64 <= "011" when (RTT_NOM = "40") else
                    xhdl63;
      xhdl65 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl66 <= "101" when (RTT_NOM = "30") else
                    "011";
      xhdl67 <= "100" when (RTT_NOM = "20") else
                    xhdl66;
      xhdl68 <= "010" when (RTT_NOM = "120") else
                    xhdl67;
      xhdl69 <= "001" when (RTT_NOM = "60") else
                    xhdl68;
      xhdl70 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl71 <= "101" when (RTT_NOM2 = "030") else
                    "011";
      xhdl72 <= "100" when (RTT_NOM2 = "020") else
                    xhdl71;
      xhdl73 <= "010" when (RTT_NOM2 = "120") else
                    xhdl72;
      xhdl74 <= "001" when (RTT_NOM2 = "060") else
                    xhdl73;
      xhdl75 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl76 <= "011" when (RTT_NOM = "40") else
                    xhdl75;
      xhdl77 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl78 <= "011" when (RTT_NOM = "40") else
                    xhdl77;
      xhdl79 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl80 <= "101" when (RTT_NOM = "30") else
                    "011";
      xhdl81 <= "100" when (RTT_NOM = "20") else
                    xhdl80;
      xhdl82 <= "010" when (RTT_NOM = "120") else
                    xhdl81;
      xhdl83 <= "001" when (RTT_NOM = "60") else
                    xhdl82;
      xhdl84 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl85 <= "101" when (RTT_NOM2 = "030") else
                    "011";
      xhdl86 <= "100" when (RTT_NOM2 = "020") else
                    xhdl85;
      xhdl87 <= "010" when (RTT_NOM2 = "120") else
                    xhdl86;
      xhdl88 <= "001" when (RTT_NOM2 = "060") else
                    xhdl87;
      xhdl89 <= "101" when (RTT_NOM3 = "030") else
                    "011";
      xhdl90 <= "100" when (RTT_NOM3 = "020") else
                    xhdl89;
      xhdl91 <= "010" when (RTT_NOM3 = "120") else
                    xhdl90;
      xhdl92 <= "001" when (RTT_NOM3 = "060") else
                    xhdl91;
      xhdl93 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl94 <= "011" when (RTT_NOM = "40") else
                    xhdl93;
      xhdl95 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl96 <= "011" when (RTT_NOM = "40") else
                    xhdl95;
      xhdl97 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl98 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl99 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl100 <= "011" when (RTT_NOM = "40") else
                    xhdl99;
      xhdl101 <= "001" when (RTT_NOM = "60") else
                    "010";
      xhdl102 <= "011" when (RTT_NOM = "40") else
                    xhdl101;
      xhdl103 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl104 <= "101" when (RTT_NOM = "30") else
                    "011";
      xhdl105 <= "100" when (RTT_NOM = "20") else
                    xhdl104;
      xhdl106 <= "010" when (RTT_NOM = "120") else
                    xhdl105;
      xhdl107 <= "001" when (RTT_NOM = "60") else
                    xhdl106;
      xhdl108 <= "01" when (RTT_WR = "60") else
                    "10";
      xhdl109 <= "101" when (RTT_NOM = "30") else
                    "011";
      xhdl110 <= "100" when (RTT_NOM = "20") else
                    xhdl109;
      xhdl111 <= "010" when (RTT_NOM = "120") else
                    xhdl110;
      xhdl112 <= "001" when (RTT_NOM = "60") else
                    xhdl111;

      process (clk)
      begin
         if (clk'event and clk = '1') then
            tmp_mr2_r(1) <= "00" after (TCQ)*1 ps;
            tmp_mr2_r(2) <= "00" after (TCQ)*1 ps;
            tmp_mr2_r(3) <= "00" after (TCQ)*1 ps;
            tmp_mr1_r(1) <= "000" after (TCQ)*1 ps;
            tmp_mr1_r(2) <= "000" after (TCQ)*1 ps;
            tmp_mr1_r(3) <= "000" after (TCQ)*1 ps;
            phy_tmp_odt0_r <= (others => '0') after (TCQ)*1 ps;
            phy_tmp_odt1_r <= (others => '0') after (TCQ)*1 ps;
            phy_tmp_cs1_r <= (others => '1') after (TCQ)*1 ps;
            phy_tmp_odt0_r1 <= phy_tmp_odt0_r after (TCQ)*1 ps;
            phy_tmp_odt1_r1 <= phy_tmp_odt1_r after (TCQ)*1 ps;

            case xhdl30 is
               -- Two slot configuration, one slot present, single rank
               when "1000" =>
                 if ((wrlvl_odt = '1') or (init_state_r = INIT_IOCONFIG_WR_WAIT)
                    or (init_state_r = INIT_RDLVL_STG1_WRITE) 
		    or (init_state_r = INIT_RDLVL_STG2_WRITE)
                    or (init_state_r = INIT_RDLVL_CLKDIV_WRITE)) then
		     -- odt turned on only during write 
                     phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                     phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
	          end if;
                  phy_tmp_cs1_r <= (others => '0') after (TCQ)*1 ps;

                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done)) = '1')) then
                	-- Rank0 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl32 after (TCQ)*1 ps;
                  else
                	-- Rank0 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl33 after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM
                     tmp_mr1_r(0) <= "000" after (TCQ)*1 ps;
                  end if;
                  
               when "0010" =>
                 if ((wrlvl_odt = '1') or (init_state_r = INIT_IOCONFIG_WR_WAIT)
                    or (init_state_r = INIT_RDLVL_STG1_WRITE) 
		    or (init_state_r = INIT_RDLVL_STG2_WRITE)
                    or (init_state_r = INIT_RDLVL_CLKDIV_WRITE)) then
                    -- odt turned on only during write 
                     phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                     phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
	          end if;
                  phy_tmp_cs1_r <= (others => '0') after (TCQ)*1 ps;

                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done)) = '1')) then
                	-- Rank1 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
                	-- Rank1 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl35 after (TCQ)*1 ps;
                  else
                	-- Rank1 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl36 after (TCQ)*1 ps;
                 	-- Rank1 Rtt_NOM
                     tmp_mr1_r(0) <= "000" after (TCQ)*1 ps;
                  end if;

               -- Two slot configuration, one slot present, dual rank
               when "0011" =>
                 if ((wrlvl_odt = '1') or (init_state_r = INIT_IOCONFIG_WR_WAIT)
                    or (init_state_r = INIT_RDLVL_STG1_WRITE) 
		    or (init_state_r = INIT_RDLVL_STG2_WRITE)
                    or (init_state_r = INIT_RDLVL_CLKDIV_WRITE)) then
		     -- odt turned on only during write 
                     phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                     phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
	          end if;

                  -- chip select assignment
		  if (to_integer(unsigned(chip_cnt_r)) < CS_WIDTH) then
		     for idx in 0 to nCS_PER_RANK-1 loop	  
                        phy_tmp_cs1_r(to_integer(unsigned(chip_cnt_r))*nCS_PER_RANK + idx) <= '0' after TCQ*1 ps; 
		     end loop;  	
	          end if;

                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done)) = '1' and (wrlvl_rank_cntr = "000"))) then
                	-- Rank0 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
               	-- Rank0 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl41 after (TCQ)*1 ps;
                  else
                	-- Rank0 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl42 after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM
                     tmp_mr1_r(0) <= "000" after (TCQ)*1 ps;
                  end if;

               when "1100" =>
                 if ((wrlvl_odt = '1') or (init_state_r = INIT_IOCONFIG_WR_WAIT)
                    or (init_state_r = INIT_RDLVL_STG1_WRITE) 
		    or (init_state_r = INIT_RDLVL_STG2_WRITE)
                    or (init_state_r = INIT_RDLVL_CLKDIV_WRITE)) then
		     -- odt turned on only during write 
                     phy_tmp_odt0_r(nCS_PER_RANK-1) <= '1' after (TCQ)*1 ps;
                     phy_tmp_odt1_r(nCS_PER_RANK-1) <= '1' after (TCQ)*1 ps;
	          end if;

                  -- chip select assignment
		  if (to_integer(unsigned(chip_cnt_r)) < CS_WIDTH) then
		     for idx in 0 to nCS_PER_RANK-1 loop	  
                        phy_tmp_cs1_r(to_integer(unsigned(chip_cnt_r))*nCS_PER_RANK + idx) <= '0' after TCQ*1 ps; 
		     end loop;  	
	          end if;
		  
                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done)) = '1' and (wrlvl_rank_cntr = "000"))) then
                	-- Rank0 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
                 	-- Rank0 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl38 after (TCQ)*1 ps;
                  else
                	-- Rank0 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl39 after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM
                     tmp_mr1_r(0) <= "000" after (TCQ)*1 ps;
                  end if;

               -- Two slot configuration, one rank per slot
               when "1010" =>
                  if (DRAM_TYPE = "DDR2") then
                     if (chip_cnt_r = "00") then
                        phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '0') after (TCQ)*1 ps;
                        phy_tmp_odt0_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '0') after (TCQ)*1 ps;
                        phy_tmp_odt1_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                     else
                        phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                        phy_tmp_odt0_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '0') after (TCQ)*1 ps;
                        phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                        phy_tmp_odt1_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '0') after (TCQ)*1 ps;
                     end if;
                  else
                     if ((wrlvl_odt = '1') or (init_state_r = INIT_IOCONFIG_WR_WAIT)
                        or (init_state_r = INIT_RDLVL_STG1_WRITE) 
		        or (init_state_r = INIT_RDLVL_STG2_WRITE)
                        or (init_state_r = INIT_RDLVL_CLKDIV_WRITE)) then
                        phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                        phy_tmp_odt0_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                        phy_tmp_odt1_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                     elsif ((init_state_r = INIT_IOCONFIG_RD_WAIT) or
                            (init_state_r = INIT_RDLVL_STG1_READ) or
                            (init_state_r = INIT_RDLVL_STG2_READ) or
                            (init_state_r = INIT_RDLVL_CLKDIV_READ)) then
                        if (chip_cnt_r = "00") then
                           phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '0') after (TCQ)*1 ps;
                           phy_tmp_odt0_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '0') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        elsif (chip_cnt_r = "01") then
                           phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt0_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '0') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '0') after (TCQ)*1 ps;
                        end if;
                     end if;
                  end if; -- else: !if(DRAM_TYPE == "DDR2")

                  -- Chip Select assignments
		  if (to_integer(unsigned(chip_cnt_r)) < CS_WIDTH) then
		     for idx in 0 to nCS_PER_RANK-1 loop	  
                        phy_tmp_cs1_r(to_integer(unsigned(chip_cnt_r))*nCS_PER_RANK + idx) <= '0' after TCQ*1 ps; 
		     end loop;  	
	          end if;

                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done)) = '1' and (wrlvl_rank_cntr = "000"))) then
                	-- Rank0 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl44 after (TCQ)*1 ps;
                	-- Rank1 Dynamic ODT disabled
                     tmp_mr2_r(1) <= "00" after (TCQ)*1 ps;
                	-- Rank1 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(1) <= xhdl46 after (TCQ)*1 ps;
                  else
                	-- Rank0 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl47 after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM defaults to 40 ohms
                     tmp_mr1_r(0) <= xhdl51 after (TCQ)*1 ps;
                	-- Rank1 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(1) <= xhdl52 after (TCQ)*1 ps;
                	-- Rank1 Rtt_NOM defaults to 40 ohms
                     tmp_mr1_r(1) <= xhdl56 after (TCQ)*1 ps;
                  end if;

               -- Two Slots - One slot with dual rank and the other with single rank
               when "1011" =>
                  tmp_mr1_r(2) <= xhdl60 after (TCQ)*1 ps;
                  tmp_mr2_r(2) <= "00" after (TCQ)*1 ps;
                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done)) = '1' and (wrlvl_rank_cntr = "000"))) then
                	-- Rank0 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl62 after (TCQ)*1 ps;
                	-- Rank1 Dynamic ODT disabled
                     tmp_mr2_r(1) <= "00" after (TCQ)*1 ps;
                	-- Rank1 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(1) <= xhdl64 after (TCQ)*1 ps;
                  else
                	-- Rank0 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl65 after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM defaults to 40 ohms
                     tmp_mr1_r(0) <= xhdl69 after (TCQ)*1 ps;
                	-- Rank1 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(1) <= xhdl70 after (TCQ)*1 ps;
                	-- Rank1 Rtt_NOM
                     tmp_mr1_r(1) <= "000" after (TCQ)*1 ps;
                  end if;
                  
                  -- Slot1 Rank1 or Rank3 is being written
                  if (DRAM_TYPE = "DDR2") then
                     if (chip_cnt_r = "00") then
                        phy_tmp_odt0_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        phy_tmp_odt1_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                     else
                        phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                        phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                     end if;
                  else
                     if ((wrlvl_odt = '1') or (init_state_r = INIT_IOCONFIG_WR_WAIT)
                        or (init_state_r = INIT_RDLVL_STG1_WRITE) 
		        or (init_state_r = INIT_RDLVL_STG2_WRITE)
                        or (init_state_r = INIT_RDLVL_CLKDIV_WRITE)) then
                        if (chip_cnt_r(0) = '1') then
                           phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt0_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                  	   -- Slot0 Rank0 is being written
                        else
                           phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt0_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        end if;
                     elsif ((init_state_r = INIT_IOCONFIG_RD_WAIT)
                        or (init_state_r = INIT_RDLVL_STG1_READ) 
		        or (init_state_r = INIT_RDLVL_STG2_READ)
                        or (init_state_r = INIT_RDLVL_CLKDIV_READ)) then
                        if (chip_cnt_r = "00") then
                           phy_tmp_odt0_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        else
                           phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                        end if;
                     end if;		-- else: !if(DRAM_TYPE == "DDR2")
	          end if;   
             	
                  -- Chip Select assignments
		  if (to_integer(unsigned(chip_cnt_r)) < CS_WIDTH) then
		     for idx in 0 to nCS_PER_RANK-1 loop	  
                        phy_tmp_cs1_r(to_integer(unsigned(chip_cnt_r))*nCS_PER_RANK + idx) <= '0' after TCQ*1 ps; 
		     end loop;  	
	          end if;

               -- Two Slots - One slot with dual rank and the other with single rank
               when "1110" =>
                  -- Rank2 Rtt_NOM defaults to 40 ohms
                  tmp_mr1_r(2) <= xhdl74 after (TCQ)*1 ps;
                  tmp_mr2_r(2) <= "00" after (TCQ)*1 ps;
                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done)) = '1' and (wrlvl_rank_cntr = "000"))) then
                	-- Rank0 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl76 after (TCQ)*1 ps;
                	-- Rank1 Dynamic ODT disabled
                     tmp_mr2_r(1) <= "00" after (TCQ)*1 ps;
                	-- Rank1 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(1) <= xhdl78 after (TCQ)*1 ps;
                  else
                	-- Rank1 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(1) <= xhdl79 after (TCQ)*1 ps;
                	-- Rank1 Rtt_NOM defaults to 40 ohms
                     tmp_mr1_r(1) <= xhdl83 after (TCQ)*1 ps;
                	-- Rank0 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl84 after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM
                     tmp_mr1_r(0) <= "000" after (TCQ)*1 ps;
                  end if; 	-- // else: !if((RTT_WR == "OFF") ||...

                  if (DRAM_TYPE = "DDR2") then
                     if (chip_cnt_r(1) = '1') then
                        phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                        phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                     else
                        phy_tmp_odt0_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        phy_tmp_odt1_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                     end if;
                  else  
                     if ((wrlvl_odt = '1') or (init_state_r = INIT_IOCONFIG_WR_WAIT)
                        or (init_state_r = INIT_RDLVL_STG1_WRITE) 
		        or (init_state_r = INIT_RDLVL_STG2_WRITE)
                        or (init_state_r = INIT_RDLVL_CLKDIV_WRITE)) then
                        -- Slot1 Rank1 is being written
                        if (chip_cnt_r(1) = '1') then
                           phy_tmp_odt0_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt0_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        -- Slot0 Rank0 or Rank2 is being written
                        else
                           phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt0_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        end if;
                     elsif ((init_state_r = INIT_IOCONFIG_RD_WAIT)
                        or (init_state_r = INIT_RDLVL_STG1_READ) 
		        or (init_state_r = INIT_RDLVL_STG2_READ)
                        or (init_state_r = INIT_RDLVL_CLKDIV_READ)) then

                        -- Slot1 Rank1 is being read
                        if (chip_cnt_r(1) = '1') then
                           phy_tmp_odt0_r(2*nCS_PER_RANK-1 downto 1*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(2*nCS_PER_RANK-1 downto 1*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        -- Slot0 Rank0 or Rank2 is being read
                        else
                           phy_tmp_odt0_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        end if;	
                     end if;		-- if (init_state_r == INIT_IOCONFIG_RD)
                  end if;	        -- else: !if(DRAM_TYPE == "DDR2")
                  
                  -- Chip Select assignments
		  if (to_integer(unsigned(chip_cnt_r)) < CS_WIDTH) then
		     for idx in 0 to nCS_PER_RANK-1 loop	  
                        phy_tmp_cs1_r(to_integer(unsigned(chip_cnt_r))*nCS_PER_RANK + idx) <= '0' after TCQ*1 ps; 
		     end loop;  	
	          end if;

               -- Two Slots - two ranks per slot
               when "1111" =>
                  -- Rank2 Rtt_NOM defaults to 40 ohms
                  tmp_mr1_r(2) <= xhdl88 after (TCQ)*1 ps;
                  -- Rank3 Rtt_NOM defaults to 40 ohms
                  tmp_mr1_r(3) <= xhdl92 after (TCQ)*1 ps;
                  tmp_mr2_r(2) <= "00" after (TCQ)*1 ps;
                  tmp_mr2_r(3) <= "00" after (TCQ)*1 ps;
                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done)) = '1' and (wrlvl_rank_cntr = "000"))) then
                	-- Rank0 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl94 after (TCQ)*1 ps;
                	-- Rank1 Dynamic ODT disabled
                     tmp_mr2_r(1) <= "00" after (TCQ)*1 ps;
                	-- Rank1 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(1) <= xhdl96 after (TCQ)*1 ps;
                  else
                	-- Rank1 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(1) <= xhdl97 after (TCQ)*1 ps;
                	-- Rank1 Rtt_NOM
                     tmp_mr1_r(1) <= "000" after (TCQ)*1 ps;
                	-- Rank0 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl98 after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM
                     tmp_mr1_r(0) <= "000" after (TCQ)*1 ps;
                  end if;	-- else: !if((RTT_WR == "OFF") ||...

                  if (DRAM_TYPE = "DDR2") then
                     if (chip_cnt_r(1) = '1') then
                        phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                        phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                     else
                        phy_tmp_odt0_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        phy_tmp_odt1_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                     end if;
                  else  			     
                     if ((wrlvl_odt = '1') or (init_state_r = INIT_IOCONFIG_WR_WAIT)
                        or (init_state_r = INIT_RDLVL_STG1_WRITE) 
		        or (init_state_r = INIT_RDLVL_STG2_WRITE)
                        or (init_state_r = INIT_RDLVL_CLKDIV_WRITE)) then
                  	   -- Slot1 Rank1 or Rank3 is being written
                        if (chip_cnt_r(0) = '1') then
                           phy_tmp_odt0_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(2*nCS_PER_RANK-1 downto nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt0_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                  	   -- Slot0 Rank0 or Rank2 is being written
                        else
                           phy_tmp_odt0_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(nCS_PER_RANK-1 downto 0) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt0_r(4*nCS_PER_RANK-1 downto 3*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(4*nCS_PER_RANK-1 downto 3*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        end if;
                     elsif ((init_state_r = INIT_IOCONFIG_RD_WAIT)
                        or (init_state_r = INIT_RDLVL_STG1_READ) 
		        or (init_state_r = INIT_RDLVL_STG2_READ)
                        or (init_state_r = INIT_RDLVL_CLKDIV_READ)) then
                  	   -- Slot1 Rank1 or Rank3 is being read
                        if (chip_cnt_r(0) = '1') then
                           phy_tmp_odt0_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(3*nCS_PER_RANK-1 downto 2*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                  	   -- Slot0 Rank0 or Rank2 is being read
                        else
                           phy_tmp_odt0_r(4*nCS_PER_RANK-1 downto 3*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                           phy_tmp_odt1_r(4*nCS_PER_RANK-1 downto 3*nCS_PER_RANK) <= (others => '1') after (TCQ)*1 ps;
                        end if;
                     end if;		-- if (init_state_r == INIT_IOCONFIG_RD)
                  end if;		-- else: !if(DRAM_TYPE == "DDR2")

                  -- Chip Select assignments
		  if (to_integer(unsigned(chip_cnt_r)) < CS_WIDTH) then
		     for idx in 0 to nCS_PER_RANK-1 loop	  
                        phy_tmp_cs1_r(to_integer(unsigned(chip_cnt_r))*nCS_PER_RANK + idx) <= '0' after TCQ*1 ps; 
		     end loop;  	
	          end if;

               when others =>
                  phy_tmp_odt0_r <= (others => '1') after (TCQ)*1 ps;
                  phy_tmp_odt1_r <= (others => '1') after (TCQ)*1 ps;
                  -- Chip Select assignments
		  if (to_integer(unsigned(chip_cnt_r)) < CS_WIDTH) then
		     for idx in 0 to nCS_PER_RANK-1 loop	  
                        phy_tmp_cs1_r(to_integer(unsigned(chip_cnt_r))*nCS_PER_RANK + idx) <= '0' after TCQ*1 ps; 
		     end loop;  	
	          end if;

                  if ((RTT_WR = "OFF") or ((WRLVL = "ON") and (not(wrlvl_done)) = '1')) then
                	-- Rank0 Dynamic ODT disabled
                     tmp_mr2_r(0) <= "00" after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(0) <= xhdl100 after (TCQ)*1 ps;
                	-- Rank1 Dynamic ODT disabled
                     tmp_mr2_r(1) <= "00" after (TCQ)*1 ps;
                	-- Rank1 Rtt_NOM defaults to 120 ohms
                     tmp_mr1_r(1) <= xhdl102 after (TCQ)*1 ps;
                  else
                	-- Rank0 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(0) <= xhdl103 after (TCQ)*1 ps;
                	-- Rank0 Rtt_NOM defaults to 40 ohms
                     tmp_mr1_r(0) <= xhdl107 after (TCQ)*1 ps;
                	-- Rank1 Dynamic ODT defaults to 120 ohms
                     tmp_mr2_r(1) <= xhdl108 after (TCQ)*1 ps;
                	-- Rank1 Rtt_NOM defaults to 40 ohms
                     tmp_mr1_r(1) <= xhdl112 after (TCQ)*1 ps;
                  end if;
            end case;
         end if;
      end process;
      
   end generate;
   
   -- Assert ODT when: (1) Write Leveling, (2) Issuing Write command
   -- Timing of ODT is not particularly precise (i.e. does not turn
   -- on right before write data, and turn off immediately after
   -- write is finished), but it doesn't have to be
   gen_nSLOTS_1 : if (nSLOTS = 1) generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if ((((RTT_NOM = "DISABLED") and (RTT_WR = "OFF")) or
                ((wrlvl_done = '1') and (wrlvl_done_r = '0'))) and (DRAM_TYPE = "DDR3")) then
               phy_odt0 <= (others => '0') after (TCQ)*1 ps;
               phy_odt1 <= (others => '0') after (TCQ)*1 ps;
            elsif (((DRAM_TYPE = "DDR3") or
	           ((not(RTT_NOM = "DISABLED")) and (DRAM_TYPE = "DDR2"))) and
		   ((wrlvl_odt = '1') or
		   (init_state_r = INIT_IOCONFIG_WR_WAIT) or
		   (init_state_r = INIT_RDLVL_STG1_WRITE) or
		   (init_state_r = INIT_RDLVL_STG1_WRITE_READ) or
		   (init_state_r = INIT_RDLVL_STG2_WRITE) or
		   (init_state_r = INIT_RDLVL_STG2_WRITE_READ) or
                   (init_state_r = INIT_RDLVL_CLKDIV_WRITE) or
                   (init_state_r = INIT_RDLVL_CLKDIV_WRITE_READ))) then
               phy_odt0 <= phy_tmp_odt0_r after (TCQ)*1 ps;
               phy_odt1 <= phy_tmp_odt1_r after (TCQ)*1 ps;
            else
               phy_odt0 <= (others => '0') after (TCQ)*1 ps;
               phy_odt1 <= (others => '0') after (TCQ)*1 ps;
            end if;
         end if;
      end process;     
   end generate;

   gen_nSLOTS_2 : if (nSLOTS = 2) generate
         process (clk)
         begin
            if (clk'event and clk = '1') then
               if (((RTT_NOM = "DISABLED") and (RTT_WR = "OFF")) or
	           ((wrlvl_rank_done= '1') or (wrlvl_rank_done_r1 = '1') or
                   ((wrlvl_done = '1') and (wrlvl_done_r = '0')) )) then
                  phy_odt0 <= (others => '0') after (TCQ)*1 ps;
                  phy_odt1 <= (others => '0') after (TCQ)*1 ps;
               elsif (((DRAM_TYPE = "DDR3") or 
	              ((not(RTT_NOM = "DISABLED")) and (DRAM_TYPE = "DDR2"))) and
		      (((wrlvl_odt_r1)) = '1' or
		      (init_state_r = INIT_RDLVL_STG1_WRITE) or
		      (init_state_r = INIT_RDLVL_STG1_WRITE_READ) or
                      (init_state_r = INIT_RDLVL_STG1_READ) or
                      (init_state_r = INIT_RDLVL_CLKDIV_WRITE) or
                      (init_state_r = INIT_RDLVL_CLKDIV_WRITE_READ) or
                      (init_state_r = INIT_RDLVL_CLKDIV_READ) or
                      (init_state_r = INIT_RDLVL_STG2_WRITE) or
		      (init_state_r = INIT_RDLVL_STG2_WRITE_READ) or
		      (init_state_r = INIT_RDLVL_STG2_READ) or
		      (init_state_r = INIT_RDLVL_STG2_READ_WAIT) or
		      (init_state_r = INIT_PRECHARGE_PREWAIT))) then
                  phy_odt0 <= phy_tmp_odt0_r or phy_tmp_odt0_r1 after (TCQ)*1 ps;
                  phy_odt1 <= phy_tmp_odt1_r or phy_tmp_odt1_r1 after (TCQ)*1 ps;
               else
                  phy_odt0 <= (others => '0') after (TCQ)*1 ps;
                  phy_odt1 <= (others => '0') after (TCQ)*1 ps;
               end if;
            end if;
         end process;
         
   end generate;
   
   --*****************************************************************
   -- memory address during init
   --*****************************************************************
   process (mr1_r, mr2_r, chip_cnt_r)
   begin
         xhdl113 <= mr1_r(to_integer(unsigned(chip_cnt_r)));
         xhdl114 <= mr2_r(to_integer(unsigned(chip_cnt_r)));
   end process;

   process (burst_addr_r, cnt_init_mr_r, chip_cnt_r, ddr2_refresh_flag_r,
	    init_state_r, load_mr0, load_mr1, load_mr2, load_mr3,
	    xhdl113, xhdl114, rdlvl_done, rdlvl_wr_rd, reg_ctrl_cnt_r)
   begin
      -- Bus 0 for address/bank never used
      address_w <= (others => '0');
      bank_w <= (others => '0');
      if ((init_state_r = INIT_PRECHARGE) or
          (init_state_r = INIT_ZQCL) or
          (init_state_r = INIT_DDR2_PRECHARGE)) then
         -- Set A10=1 for ZQ long calibration or Precharge All
         address_w <= (others => '0');
         address_w(10) <= '1';
         bank_w <= (others => '0');
      elsif (init_state_r = INIT_WRLVL_START) then
         -- Enable wrlvl in MR1
         bank_w(1 downto 0) <= "01";
         address_w <= load_mr1(ROW_WIDTH - 1 downto 0);
         address_w(7) <= '1';
      elsif (init_state_r = INIT_WRLVL_LOAD_MR) then
         -- Finished with write leveling, disable wrlvl in MR1
         -- For single rank disable Rtt_Nom
         bank_w(1 downto 0) <= "01";
         address_w <= load_mr1(ROW_WIDTH-1 downto 0);
         address_w(2) <= xhdl113(0);
         address_w(6) <= xhdl113(1);
         address_w(9) <= xhdl113(2);
      elsif (init_state_r = INIT_WRLVL_LOAD_MR2) then
         -- Set RTT_WR in MR2 after write leveling disabled
         bank_w(1 downto 0) <= "10";
         address_w <= load_mr2(ROW_WIDTH-1 downto 0);
         address_w(10 downto 9) <= xhdl114;
      elsif ( (init_state_r = INIT_REG_WRITE) and
              (DRAM_TYPE = "DDR3")) then
         -- bank_w is assigned a 3 bit value. In some
         -- DDR2 cases there will be only two bank bits.
         --Qualifying the condition with DDR3
         bank_w <= (others => '0');
         address_w <= (others => '0');

	 if (reg_ctrl_cnt_r = REG_RC0(2 downto 0)) then
            address_w(4 downto 0) <= REG_RC0(4 downto 0);
	 elsif (reg_ctrl_cnt_r = REG_RC1(2 downto 0)) then
            address_w(4 downto 0) <= REG_RC1(4 downto 0);
            bank_w <= REG_RC1(7 downto 5);
	 elsif (reg_ctrl_cnt_r = REG_RC2(2 downto 0)) then            
            address_w(4 downto 0) <= REG_RC2(4 downto 0);
	 elsif (reg_ctrl_cnt_r = REG_RC3(2 downto 0)) then            	       
            address_w(4 downto 0) <= REG_RC3(4 downto 0);
	 elsif (reg_ctrl_cnt_r = REG_RC4(2 downto 0)) then            	       
            address_w(4 downto 0) <= REG_RC4(4 downto 0);
	 elsif (reg_ctrl_cnt_r = REG_RC5(2 downto 0)) then            	       
            address_w(4 downto 0) <= REG_RC5(4 downto 0);
         else      
	    null;
         end if;

      elsif (init_state_r = INIT_LOAD_MR) then
         -- If loading mode register, look at cnt_init_mr to determine
         -- which MR is currently being programmed
         address_w <= (others => '0');
         bank_w <= (others => '0');
         if (DRAM_TYPE = "DDR3") then
            if ((AND_BR(rdlvl_done)) = '1') then
               -- end of the calibration programming correct
               -- burst length
               bank_w(1 downto 0) <= "00";
               address_w <= load_mr0(ROW_WIDTH - 1 downto 0);		
               address_w(8) <= '0';		--Don't reset DLL
            else
               case cnt_init_mr_r is
                  when INIT_CNT_MR2 =>
                     bank_w(1 downto 0) <= "10";
                     address_w <= load_mr2(ROW_WIDTH - 1 downto 0);
                     address_w(10 downto 9) <= xhdl114;
                  when INIT_CNT_MR3 =>
                     bank_w(1 downto 0) <= "11";
                     address_w <= load_mr3(ROW_WIDTH - 1 downto 0);
                  when INIT_CNT_MR1 =>
                     bank_w(1 downto 0) <= "01";
                     address_w <= load_mr1(ROW_WIDTH - 1 downto 0);
                     address_w(2) <= xhdl113(0);
                     address_w(6) <= xhdl113(1);
                     address_w(9) <= xhdl113(2);
                  when INIT_CNT_MR0 =>
                     bank_w(1 downto 0) <= "00";
                     address_w <= load_mr0(ROW_WIDTH - 1 downto 0);
                     -- fixing it to BL8 for calibration
                     address_w(1 downto 0) <= "00";
                  when others =>	
                     bank_w    <= (others => 'X');
                     address_w <= (others => 'X');
               end case;	-- case(cnt_init_mr_r)
            end if;		-- else: !if(&rdlvl_done)
         else
            -- DDR2
            case cnt_init_mr_r is
               when INIT_CNT_MR2 =>
                  if ((not(ddr2_refresh_flag_r)) = '1') then
                     bank_w(1 downto 0) <= "10";
                     address_w <= load_mr2(ROW_WIDTH - 1 downto 0);
                  else		-- second set of lm commands
                     bank_w(1 downto 0) <= "00";
                     address_w <= load_mr0(ROW_WIDTH - 1 downto 0);
                     address_w(8) <= '0';
                  end if;	-- MRS command without resetting DLL
               
               when INIT_CNT_MR3 =>
                  if ((not(ddr2_refresh_flag_r)) = '1') then
                     bank_w(1 downto 0) <= "11";
                     address_w <= load_mr3(ROW_WIDTH - 1 downto 0);
                  else		-- second set of lm commands
                     bank_w(1 downto 0) <= "00";
                     address_w <= load_mr0(ROW_WIDTH - 1 downto 0);
                     address_w(8) <= '0';
                     --MRS command without resetting DLL. Repeted again
                     -- because there is an extra state.		     
                  end if;
                              
               when INIT_CNT_MR1 =>
                  bank_w(1 downto 0) <= "01";
                  if ((not(ddr2_refresh_flag_r)) = '1') then
                     address_w <= load_mr1(ROW_WIDTH - 1 downto 0);
                  else		-- second set of lm commands
                     address_w <= load_mr1(ROW_WIDTH - 1 downto 0);
                     address_w(9 downto 7) <= "111";
		     --OCD default state
                  end if;
               
               when INIT_CNT_MR0 =>
                  if ((not(ddr2_refresh_flag_r)) = '1') then
                     bank_w(1 downto 0) <= "00";
                     address_w <= load_mr0(ROW_WIDTH - 1 downto 0);
                  else		-- second set of lm commands
                     bank_w(1 downto 0) <= "01";
                     address_w <= load_mr1(ROW_WIDTH - 1 downto 0);
                     if ((chip_cnt_r = "01") or (chip_cnt_r = "11")) then
                     -- always disable odt for rank 1 and rank 3 as per SPEC
                        address_w(2) <= '0';
                        address_w(6) <= '0';
                        --OCD exit
                     end if;
                  end if;
               when others =>		-- case(cnt_init_mr_r)
                  bank_w    <= (others => 'X');
                  address_w <= (others => 'X');
            end case;
         end if;
      elsif (rdlvl_wr_rd = '1') then
         -- when writing or reading back training pattern for read leveling
         -- need to support both burst length of 4 or 8. This may mean issuing
         -- multiple commands to cover the entire range of addresses accessed
         -- during read leveling
         bank_w <= (others => '0');
         address_w(ROW_WIDTH-1 downto 4) <= (others => '0');
         address_w(3 downto 0) <= (burst_addr_r & "00");
         address_w(12) <= '1';
      elsif ((init_state_r = INIT_RDLVL_ACT) or (init_state_r = INIT_PD_ACT)) then
         -- all read leveling writes/reads takes place in row 0x0 only
         -- same goes for phase detector initial calibration
         bank_w    <= (others => '0');
         address_w <= (others => '0');
      else
         bank_w    <= (others => 'X');
         address_w <= (others => 'X');
      end if;
   end process;
   
   
   -- registring before sending out
   process (clk)
   begin
      if (clk'event and clk = '1') then
         phy_bank0 <= bank_w after (TCQ)*1 ps;
         phy_address0 <= address_w after (TCQ)*1 ps;
         phy_bank1 <= bank_w after (TCQ)*1 ps;
         phy_address1 <= address_w after (TCQ)*1 ps;
      end if;
   end process;
   
   
end trans;


