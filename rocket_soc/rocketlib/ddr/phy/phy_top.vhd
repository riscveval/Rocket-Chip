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
-- \   \   \/     Version: 3.92
--  \   \         Application: MIG
--  /   /         Filename: phy_top.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:13 $
-- \   \  /  \    Date Created: Aug 03 2009
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--Purpose:
--   Top-level for memory physical layer (PHY) interface
--   NOTES:
--     1. Need to support multiple copies of CS outputs
--     2. DFI_DRAM_CKE_DISABLE not supported
--
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_top.vhd,v 1.1 2011/06/02 07:18:13 mishra Exp $
--**$Date: 2011/06/02 07:18:13 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_top.vhd,v $
--******************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_top is
   generic (
      TCQ                        : integer := 100;
      nCK_PER_CLK                : integer := 2;		-- # of memory clocks per CLK
      CLK_PERIOD                 : integer := 3333;		-- Internal clock period (in ps)
      REFCLK_FREQ                : real    := 300.0;		-- IODELAY Reference Clock freq (MHz)
      DRAM_TYPE                  : string  := "DDR3";		-- Memory I/F type: "DDR3", "DDR2"
      -- Slot Conifg parameters
      SLOT_0_CONFIG              : std_logic_vector(7 downto 0) := X"01";
      SLOT_1_CONFIG              : std_logic_vector(7 downto 0) := X"00";
      -- DRAM bus widths
      BANK_WIDTH                 : integer := 2;		-- # of bank bits
      CK_WIDTH                   : integer := 1;		-- # of CK/CK# outputs to memory
      COL_WIDTH                  : integer := 10;		-- column address width
      nCS_PER_RANK               : integer := 1;		-- # of unique CS outputs per rank
      DQ_CNT_WIDTH               : integer := 6;		-- = ceil(log2(DQ_WIDTH))
      DQ_WIDTH                   : integer := 64;		-- # of DQ (data)
      DM_WIDTH                   : integer := 8;		-- # of DM (data mask)
      DQS_CNT_WIDTH              : integer := 3;		-- = ceil(log2(DQS_WIDTH))
      DQS_WIDTH                  : integer := 8;		-- # of DQS (strobe)
      DRAM_WIDTH                 : integer := 8;		-- # of DQ per DQS
      ROW_WIDTH                  : integer := 14;		-- DRAM address bus width
      RANK_WIDTH                 : integer := 1;		-- log2(CS_WIDTH)
      CS_WIDTH                   : integer := 1;		-- # of DRAM ranks
      CKE_WIDTH                  : integer := 1;		-- # of DRAM ranks
      CAL_WIDTH                  : string  := "HALF";		-- # of DRAM ranks to be calibrated
      								-- CAL_WIDTH = CS_WIDTH when "FULL"
								-- CAL_WIDTH = CS_WIDTH/2 when "HALF"
      -- calibration Address. The address given below will be used for calibration
      -- read and write operations. 
      CALIB_ROW_ADD              : std_logic_vector(15 downto 0) := X"0000";  -- Calibration row address
      CALIB_COL_ADD              : std_logic_vector(11 downto 0) := X"000";   -- Calibration column address
      CALIB_BA_ADD               : std_logic_vector(2 downto 0)  := "000";    -- Calibration bank address 
   
      -- DRAM mode settings
      AL                         : string  := "0";		-- Additive Latency option
      BURST_MODE                 : string  := "8";		-- Burst length
      BURST_TYPE                 : string  := "SEQ";		-- Burst type
      nAL                        : integer := 0;		-- Additive latency (in clk cyc)
      nCL                        : integer := 5;		-- Read CAS latency (in clk cyc)
      nCWL                       : integer := 5;		-- Write CAS latency (in clk cyc)
      tRFC                       : integer := 110000;		-- Refresh-to-command delay
      OUTPUT_DRV                 : string  := "HIGH";		-- DRAM reduced output drive option
      REG_CTRL                   : string  := "ON";		-- "ON" for registered DIMM
      RTT_NOM                    : string  := "60";		-- ODT Nominal termination value
      RTT_WR                     : string  := "60";		-- ODT Write termination value
      WRLVL                      : string  := "OFF";		-- Enable write leveling
      -- Phase Detector/Read Leveling options
      PHASE_DETECT               : string  := "OFF";		-- Enable read phase detector
      PD_TAP_REQ                 : integer := 0;		-- # of IODELAY taps reserved for PD
      PD_MSB_SEL                 : integer := 8;		-- # of IODELAY taps reserved for PD
      PD_DQS0_ONLY               : string  := "ON";		-- Enable use of DQS[0] only for
      								-- phase detector
      PD_LHC_WIDTH               : integer := 16;		-- sampling averaging cntr widths
      PD_CALIB_MODE              : string  := "PARALLEL";	-- parallel/seq PD calibration
      -- IODELAY/BUFFER options
      IBUF_LPWR_MODE             : string  := "OFF";		-- Input buffer low power mode
      IODELAY_HP_MODE            : string  := "ON";		-- IODELAY High Performance Mode
      IODELAY_GRP                : string  := "IODELAY_MIG";	-- May be assigned unique name
      								-- when mult IP cores in design
      -- Pin-out related parameters
      nDQS_COL0                  : integer := 8;		-- # DQS groups in I/O column #1
      nDQS_COL1                  : integer := 0;		-- # DQS groups in I/O column #2
      nDQS_COL2                  : integer := 0;		-- # DQS groups in I/O column #3
      nDQS_COL3                  : integer := 0;		-- # DQS groups in I/O column #4
      DQS_LOC_COL0               : std_logic_vector(143 downto 0) := X"11100F0E0D0C0B0A09080706050403020100";
      								-- DQS grps in col #1
      DQS_LOC_COL1               : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
							        -- DQS grps in col #2
      DQS_LOC_COL2               : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
							        -- DQS grps in col #3
      DQS_LOC_COL3               : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
							        -- DQS grps in col #4
      USE_DM_PORT                : integer := 1;		-- DM instantation enable  
      -- Simulation /debug options
      SIM_BYPASS_INIT_CAL        : string  := "OFF";            -- Parameter used to force skipping
                                                                -- or abbreviation of initialization
                                                                -- and calibration. Overrides
                                                                -- SIM_INIT_OPTION, SIM_CAL_OPTION,
                                                                -- and disables various other blocks
      SIM_INIT_OPTION            : string  := "NONE";		-- Skip various initialization steps
      SIM_CAL_OPTION             : string  := "NONE";		-- Skip various calibration steps
      DEBUG_PORT                : string  := "OFF"		-- Enable debug port
   );
   port (
      clk_mem                    : in std_logic;		-- Memory clock
      clk                        : in std_logic;                -- Internal (logic) clock
      clk_rd_base                : in std_logic;                -- For inner/outer I/O cols
      rst                        : in std_logic;                -- Reset sync'ed to CLK
      -- Slot present inputs
      slot_0_present             : in std_logic_vector(7 downto 0);             
      slot_1_present             : in std_logic_vector(7 downto 0);             
      -- DFI Control/Address
      dfi_address0               : in std_logic_vector(ROW_WIDTH-1 downto 0);
      dfi_address1               : in std_logic_vector(ROW_WIDTH-1 downto 0);
      dfi_bank0                  : in std_logic_vector(BANK_WIDTH-1 downto 0);
      dfi_bank1                  : in std_logic_vector(BANK_WIDTH-1 downto 0);
      dfi_cas_n0                 : in std_logic;
      dfi_cas_n1                 : in std_logic;
      dfi_cke0                   : in std_logic_vector(CKE_WIDTH-1 downto 0);
      dfi_cke1                   : in std_logic_vector(CKE_WIDTH-1 downto 0);
      dfi_cs_n0                  : in std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
      dfi_cs_n1                  : in std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
      dfi_odt0                   : in std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
      dfi_odt1                   : in std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
      dfi_ras_n0                 : in std_logic;
      dfi_ras_n1                 : in std_logic;
      dfi_reset_n                : in std_logic;
      dfi_we_n0                  : in std_logic;
      dfi_we_n1                  : in std_logic;
      -- DFI Write
      dfi_wrdata_en              : in std_logic;
      dfi_wrdata                 : in std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
      dfi_wrdata_mask            : in std_logic_vector(4 * (DQ_WIDTH / 8) - 1 downto 0);
      -- DFI Read
      dfi_rddata_en              : in std_logic;
      dfi_rddata                 : out std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
      dfi_rddata_valid           : out std_logic;
      -- DFI Initialization Status / CLK Disable
      dfi_dram_clk_disable       : in std_logic;
      dfi_init_complete          : out std_logic;
      -- sideband signals
      io_config_strobe           : in std_logic;
      io_config                  : in std_logic_vector(RANK_WIDTH downto 0);
      -- DDRx Output Interface
      ddr_ck_p                   : out std_logic_vector(CK_WIDTH - 1 downto 0);
      ddr_ck_n                   : out std_logic_vector(CK_WIDTH - 1 downto 0);
      ddr_addr                   : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      ddr_ba                     : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      ddr_ras_n                  : out std_logic;
      ddr_cas_n                  : out std_logic;
      ddr_we_n                   : out std_logic;
      ddr_cs_n                   : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      ddr_cke                    : out std_logic_vector(CKE_WIDTH - 1 downto 0);
      ddr_odt                    : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      ddr_reset_n                : out std_logic;
      ddr_parity                 : out std_logic;
      ddr_dm                     : out std_logic_vector(DM_WIDTH - 1 downto 0);
      ddr_dqs_p                  : inout std_logic_vector(DQS_WIDTH - 1 downto 0);
      ddr_dqs_n                  : inout std_logic_vector(DQS_WIDTH - 1 downto 0);
      ddr_dq                     : inout std_logic_vector(DQ_WIDTH - 1 downto 0);
      -- Read Phase Detector Interface
      pd_PSDONE                  : in std_logic;        
      pd_PSEN                    : out std_logic;         
      pd_PSINCDEC                : out std_logic;
      -- Debug Port
      -- Write leveling logic
      dbg_wr_dqs_tap_set         : in std_logic_vector(5 * DQS_WIDTH - 1 downto 0); 
      dbg_wr_dq_tap_set          : in std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_wr_tap_set_en          : in std_logic; 
      dbg_wrlvl_start            : out std_logic;
      dbg_wrlvl_done             : out std_logic;
      dbg_wrlvl_err              : out std_logic;
      dbg_wl_dqs_inverted        : out std_logic_vector(DQS_WIDTH - 1 downto 0);
      dbg_wr_calib_clk_delay     : out std_logic_vector(2 * DQS_WIDTH - 1 downto 0);
      dbg_wl_odelay_dqs_tap_cnt  : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_wl_odelay_dq_tap_cnt   : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_tap_cnt_during_wrlvl   : out std_logic_vector(4 downto 0);
      dbg_wl_edge_detect_valid   : out std_logic;
      dbg_rd_data_edge_detect    : out std_logic_vector(DQS_WIDTH - 1 downto 0);
      -- Read leveling logic
      dbg_rdlvl_start            : out std_logic_vector(1 downto 0);
      dbg_rdlvl_done             : out std_logic_vector(1 downto 0);
      dbg_rdlvl_err              : out std_logic_vector(1 downto 0);
      dbg_cpt_first_edge_cnt     : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_cpt_second_edge_cnt    : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_rd_bitslip_cnt         : out std_logic_vector(3 * DQS_WIDTH - 1 downto 0);
      dbg_rd_clkdly_cnt          : out std_logic_vector(2 * DQS_WIDTH - 1 downto 0);
      dbg_rd_active_dly          : out std_logic_vector(4 downto 0);
      dbg_rd_data                : out std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
      -- Delay control
      dbg_idel_up_all            : in std_logic;
      dbg_idel_down_all          : in std_logic;
      dbg_idel_up_cpt            : in std_logic;
      dbg_idel_down_cpt          : in std_logic;
      dbg_idel_up_rsync          : in std_logic;
      dbg_idel_down_rsync        : in std_logic;
      dbg_sel_idel_cpt           : in std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);
      dbg_sel_all_idel_cpt       : in std_logic;
      dbg_sel_idel_rsync         : in std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);
      dbg_sel_all_idel_rsync     : in std_logic;
      dbg_cpt_tap_cnt            : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_rsync_tap_cnt          : out std_logic_vector(19 downto 0);
      dbg_dqs_tap_cnt            : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_dq_tap_cnt             : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      -- Phase detector
      dbg_pd_off                 : in std_logic;
      dbg_pd_maintain_off        : in std_logic;
      dbg_pd_maintain_0_only     : in std_logic;
      dbg_pd_inc_cpt             : in std_logic;
      dbg_pd_dec_cpt             : in std_logic;
      dbg_pd_inc_dqs             : in std_logic;
      dbg_pd_dec_dqs             : in std_logic;
      dbg_pd_disab_hyst          : in std_logic;
      dbg_pd_disab_hyst_0        : in std_logic;
      dbg_pd_msb_sel             : in std_logic_vector(3 downto 0);
      dbg_pd_byte_sel            : in std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);
      dbg_inc_rd_fps             : in std_logic;
      dbg_dec_rd_fps             : in std_logic;
      -- General debug ports - connect to internal nets as needed
      dbg_phy_pd                 : out std_logic_vector(255 downto 0); -- Phase Detector
      dbg_phy_read               : out std_logic_vector(255 downto 0); -- Read datapath
      dbg_phy_rdlvl              : out std_logic_vector(255 downto 0); -- Read leveling calibration
      dbg_phy_top                : out std_logic_vector(255 downto 0)  -- General PHY debug
   );
end entity phy_top;

architecture arch of phy_top is
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of arch : ARCHITECTURE IS
    "mig_v3_92_ddr3_V6, Coregen 14.7";

  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of arch : ARCHITECTURE IS "ddr3_V6_phy,mig_v3_92,{LANGUAGE=VHDL, SYNTHESIS_TOOL=ISE, LEVEL=PHY, AXI_ENABLE=0, NO_OF_CONTROLLERS=1, INTERFACE_TYPE=DDR3, CLK_PERIOD=2500, MEMORY_TYPE=SODIMM, MEMORY_PART=mt4jsf6464hy-1g1, DQ_WIDTH=64, ECC=OFF, DATA_MASK=1, BURST_MODE=8, BURST_TYPE=SEQ, OUTPUT_DRV=HIGH, RTT_NOM=60, REFCLK_FREQ=200, MMCM_ADV_BANDWIDTH=OPTIMIZED, CLKFBOUT_MULT_F=6, CLKOUT_DIVIDE=3, DEBUG_PORT=OFF, IODELAY_HP_MODE=ON, INTERNAL_VREF=0, DCI_INOUTS=1, CLASS_ADDR=II, INPUT_CLK_TYPE=DIFFERENTIAL}";
   -- For reg dimm addign one extra cycle of latency for CWL. The new value
   -- will be passed to phy_write and phy_data_io	
   function CALC_CWL_M return integer is
   begin
      if (REG_CTRL = "ON") then
         return (nCWL + 1);
      else
         return nCWL;
      end if;	 
   end function;	 

   -- function to AND the bits in a vectored signal
   function AND_BR (inp_var: std_logic_vector)
            return std_logic is
       variable temp: std_logic := '1';
    begin
       for idx in inp_var'range loop
	  temp := temp and inp_var(idx);
       end loop;
       return temp;  
   end function;

   -- function to OR the bits in a vectored signal
   function OR_BR (inp_var: std_logic_vector)
            return std_logic is
       variable temp: std_logic := '0';
    begin
       for idx in inp_var'range loop
	  temp := temp or inp_var(idx);
       end loop;
       return temp;  
   end function;

   -- Calculate number of slots in the system
   function CALC_nSLOTS return integer is
   begin
      if (OR_BR(SLOT_1_CONFIG) = '1') then
         return (2);
      else
         return (1);
      end if;	 
   end function;	 

   -- Temp parameters used to force skipping or abbreviation of
   -- initialization and calibration. In some cases logic blocks
   -- may be disabled altogether. 
   function CALC_SIM_INIT_OPTION_W return string is
   begin
      if (SIM_BYPASS_INIT_CAL = "SKIP" or
          SIM_BYPASS_INIT_CAL = "FAST") then
         return ("SKIP_PU_DLY");
      else
         return (SIM_INIT_OPTION);
      end if;
   end function;

   function CALC_SIM_CAL_OPTION_W return string is
   begin
      if (SIM_BYPASS_INIT_CAL = "SKIP") then
         return ("SKIP_CAL");
      elsif (SIM_BYPASS_INIT_CAL = "FAST") then
         return ("FAST_CAL");
      else
        return (SIM_CAL_OPTION);
      end if;
   end function;  

   function CALC_WRLVL_W return string is
   begin
      if (SIM_BYPASS_INIT_CAL = "SKIP") then
         return ("OFF");
      else
         return (WRLVL);
      end if;
   end function;

   function CALC_PHASE_DETECT_W return string is
   begin
      if (SIM_BYPASS_INIT_CAL = "SKIP") then
         return ("OFF");
      else
         return (PHASE_DETECT);
      end if;
   end function;

   -- Parameter used to force skipping or abbreviation of initialization
   -- and calibration. Overrides SIM_INIT_OPTION, SIM_CAL_OPTION, and 
   -- disables various other blocks depending on the option selected
   -- This option should only be used during simulation. In the case of
   -- the "SKIP" option, the testbench used should also not be modeling
   -- propagation delays.
   -- Allowable options = {"NONE", "SKIP", "FAST"}
   --  "NONE" = options determined by the individual parameter settings
   --  "SKIP" = skip power-up delay, skip calibration for read leveling,
   --           write leveling, and phase detector. In the case of write
   --           leveling and the phase detector, this means not instantiating
   --           those blocks at all.
   --  "FAST" = skip power-up delay, and calibrate (read leveling, write
   --           leveling, and phase detector) only using one DQS group, and
   --           apply the results to all other DQS groups. 
   constant SIM_INIT_OPTION_W : string := CALC_SIM_INIT_OPTION_W;
   constant SIM_CAL_OPTION_W  : string := CALC_SIM_CAL_OPTION_W;
   constant WRLVL_W           : string := CALC_WRLVL_W;
   constant PHASE_DETECT_W    : string := CALC_PHASE_DETECT_W;
  
   -- Advance ODELAY of DQ by extra 0.25*tCK (quarter clock cycle) to center
   -- align DQ and DQS on writes. Round (up or down) value to nearest integer
   constant SHIFT_TBY4_TAP : integer := integer((real(CLK_PERIOD) + (real(nCK_PER_CLK)*(1000000.0/(REFCLK_FREQ*64.0))*2.0) - 1.0) / 
                                       (real(nCK_PER_CLK)*(1000000.0/(REFCLK_FREQ*64.0)) * 4.0));
   constant CWL_M : integer := CALC_CWL_M;
   constant nSLOTS : integer := CALC_nSLOTS;

   -- Temp parameter to enable disable PD based on the PD override parameter
   -- Disabling phase detect below 250 MHz for the MIG 3.2 release   
   function CALC_PHASE_DETECT_TOP return string is
   begin
      if (CLK_PERIOD > 8000) then
         return ("OFF");
      else
         return (PHASE_DETECT_W);
      end if;
   end function;
  
   constant USE_PHASE_DETECT : string := CALC_PHASE_DETECT_TOP;

   -- Param to determine if the configuration is an UDIMM configuration for DDR2
   -- this parameter is used for advancing the chip select for frequencies above
   -- 200 MHz.
   function DDR2_EARLY_CS_CALC return integer is
   begin
      if ((CLK_PERIOD < 10000) and ( DQ_WIDTH >= 64) and (CK_WIDTH < 5) and 
          (DRAM_TYPE = "DDR2") and (REG_CTRL = "OFF")) then
         return 1;
      else
         return 0;
      end if;
   end function;

   constant DDR2_EARLY_CS : integer := DDR2_EARLY_CS_CALC;

   signal calib_width                 : std_logic_vector(2 downto 0);
   signal chip_cnt                    : std_logic_vector(1 downto 0);
   signal chip_cnt_r                  : std_logic_vector(1 downto 0);
   signal chip_cnt_r1                 : std_logic_vector(1 downto 0);
   signal clk_cpt                     : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal clk_rsync                   : std_logic_vector(3 downto 0);
   signal dfi_rd_dqs                  : std_logic_vector(4*DQS_WIDTH - 1 downto 0);
   signal dlyce_cpt                   : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dlyce_pd_cpt                : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dlyce_rdlvl_cpt             : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dlyce_rdlvl_rsync           : std_logic_vector(3 downto 0);
   signal dlyce_rsync                 : std_logic_vector(3 downto 0);
   signal dlyinc_cpt                  : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dlyinc_pd_cpt               : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dlyinc_pd_dqs               : std_logic;
   signal dlyinc_rdlvl_cpt            : std_logic;
   signal dlyinc_rdlvl_rsync          : std_logic;
   signal dlyinc_rsync                : std_logic_vector(3 downto 0);
   signal dlyrst_cpt                  : std_logic;
   signal dlyrst_rsync                : std_logic;
   signal dlyval_dq                   : std_logic_vector(5*DQS_WIDTH - 1 downto 0);
   signal dlyval_dqs                  : std_logic_vector(5*DQS_WIDTH - 1 downto 0);
   signal dlyval_pd_dqs               : std_logic_vector(5*DQS_WIDTH - 1 downto 0);
   signal dlyval_rdlvl_dq             : std_logic_vector(5*DQS_WIDTH - 1 downto 0);
   signal dlyval_rdlvl_dqs            : std_logic_vector(5*DQS_WIDTH - 1 downto 0);
   signal dlyval_wrlvl_dq             : std_logic_vector(5*DQS_WIDTH - 1 downto 0);
   signal dlyval_wrlvl_dq_w           : std_logic_vector(5*DQS_WIDTH - 1 downto 0);
   signal dlyval_wrlvl_dqs            : std_logic_vector(5*DQS_WIDTH - 1 downto 0);
   signal dlyval_wrlvl_dqs_w          : std_logic_vector(5*DQS_WIDTH - 1 downto 0);
   signal dm_ce                       : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dq_oe_n                     : std_logic_vector(4*DQS_WIDTH - 1 downto 0);
   signal dqs_inv                     : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dqs_oe_n                    : std_logic_vector(4*DQS_WIDTH - 1 downto 0);
   signal dqs_oe                      : std_logic;
   signal dqs_rst                     : std_logic_vector((DQS_WIDTH*4) - 1 downto 0);
   signal inv_dqs                     : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal mask_data_fall0             : std_logic_vector((DQ_WIDTH / 8) - 1 downto 0);
   signal mask_data_fall1             : std_logic_vector((DQ_WIDTH / 8) - 1 downto 0);
   signal mask_data_rise0             : std_logic_vector((DQ_WIDTH / 8) - 1 downto 0);
   signal mask_data_rise1             : std_logic_vector((DQ_WIDTH / 8) - 1 downto 0);
   signal pd_cal_done                 : std_logic;
   signal pd_cal_start                : std_logic;
   signal pd_prech_req                : std_logic;
   signal phy_address0                : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal phy_address1                : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal phy_bank0                   : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal phy_bank1                   : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal phy_cas_n0                  : std_logic;
   signal phy_cas_n1                  : std_logic;
   signal phy_cke0                    : std_logic_vector(CKE_WIDTH - 1 downto 0);
   signal phy_cke1                    : std_logic_vector(CKE_WIDTH - 1 downto 0);
   signal phy_cs_n0                   : std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
   signal phy_cs_n1                   : std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
   signal phy_init_data_sel           : std_logic;
   signal phy_io_config               : std_logic_vector(0 downto 0);		--bus can be expanded later
   signal phy_io_config_strobe        : std_logic;
   signal phy_odt0                    : std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
   signal phy_odt1                    : std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
   signal phy_ras_n0                  : std_logic;
   signal phy_ras_n1                  : std_logic;
   signal phy_rddata_en               : std_logic;
   signal phy_reset_n                 : std_logic;
   signal phy_we_n0                   : std_logic;
   signal phy_we_n1                   : std_logic;
   signal phy_wrdata                  : std_logic_vector(4*DQ_WIDTH - 1 downto 0);
   signal phy_wrdata_en               : std_logic;
   signal phy_wrdata_mask             : std_logic_vector(4*(DQ_WIDTH / 8) - 1 downto 0);
   signal prech_done                  : std_logic;
   signal rank_cnt                    : std_logic_vector(1 downto 0);
   signal rd_active_dly               : std_logic_vector(4 downto 0);
   signal rd_bitslip_cnt              : std_logic_vector(2*DQS_WIDTH - 1 downto 0);
   signal rd_clkdiv_inv               : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal rd_clkdly_cnt               : std_logic_vector(2*DQS_WIDTH - 1 downto 0);
   signal rd_data_fall0               : std_logic_vector(DQ_WIDTH - 1 downto 0);
   signal rd_data_fall1               : std_logic_vector(DQ_WIDTH - 1 downto 0);
   signal rd_data_rise0               : std_logic_vector(DQ_WIDTH - 1 downto 0);
   signal rd_data_rise1               : std_logic_vector(DQ_WIDTH - 1 downto 0);
   signal rd_dqs_fall0                : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal rd_dqs_fall1                : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal rd_dqs_rise0                : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal rd_dqs_rise1                : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal rdlvl_clkdiv_done           : std_logic;
   signal rdlvl_clkdiv_start          : std_logic;
   signal rdlvl_done                  : std_logic_vector(1 downto 0);
   signal rdlvl_err                   : std_logic_vector(1 downto 0);
   signal rdlvl_pat_resume            : std_logic;
   signal rdlvl_pat_resume_w          : std_logic;
   signal rdlvl_pat_err               : std_logic;
   signal rdlvl_pat_err_cnt           : std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);
   signal rdlvl_prech_req             : std_logic;
   signal rdlvl_start                 : std_logic_vector(1 downto 0);
   signal rst_rsync                   : std_logic_vector(3 downto 0);
   signal wl_sm_start                 : std_logic;
   signal wr_calib_dly                : std_logic_vector(2*DQS_WIDTH - 1 downto 0);
   signal wr_data_rise0               : std_logic_vector(DQ_WIDTH - 1 downto 0);
   signal wr_data_fall0               : std_logic_vector(DQ_WIDTH - 1 downto 0);
   signal wr_data_rise1               : std_logic_vector(DQ_WIDTH - 1 downto 0);
   signal wr_data_fall1               : std_logic_vector(DQ_WIDTH - 1 downto 0);
   signal wrcal_dly_w                 : std_logic_vector(2*DQS_WIDTH - 1 downto 0);
   signal wrcal_err                   : std_logic;
   signal wrlvl_active                : std_logic;
   signal wrlvl_done                  : std_logic;
   signal wrlvl_err                   : std_logic;
   signal wrlvl_start                 : std_logic;
   signal dfi_rddata_valid_phy        : std_logic;
   signal dbg_wr_calib_clk_dly_cnt    : std_logic;
   signal rdpath_rdy                  : std_logic;
   signal wrlvl_rank_done             : std_logic;
   signal out_oserdes_wc	      : std_logic;

  -- X-HDL generated signals
   signal xhdl1 : std_logic_vector(3 downto 0);
   signal xhdl2 : std_logic_vector(3 downto 0);
   
   -- Declare intermediate signals for referenced outputs
   signal pll_lock_ck_fb_41           : std_logic;
   signal dfi_rddata_37               : std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
   signal dfi_rddata_valid_38         : std_logic;
   signal dfi_init_complete_36        : std_logic;
   signal ddr_ck_p_27                 : std_logic_vector(CK_WIDTH - 1 downto 0);
   signal ddr_ck_n_26                 : std_logic_vector(CK_WIDTH - 1 downto 0);
   signal ddr_addr_23                 : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal ddr_ba_24                   : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal ddr_ras_n_33                : std_logic;
   signal ddr_cas_n_25                : std_logic;
   signal ddr_we_n_35                 : std_logic;
   signal ddr_cs_n_29                 : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal ddr_cke_28                  : std_logic_vector(CKE_WIDTH - 1 downto 0);
   signal ddr_odt_31                  : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal ddr_reset_n_34              : std_logic;
   signal ddr_parity_32               : std_logic;
   signal ddr_dm_30                   : std_logic_vector(DM_WIDTH - 1 downto 0);
   signal dbg_tap_cnt_during_wrlvl_21 : std_logic_vector(4 downto 0);
   signal dbg_wl_edge_detect_valid_22 : std_logic;
   signal dbg_rd_data_edge_detect_16  : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dbg_rdlvl_clk_17            : std_logic;
   signal dbg_cpt_first_edge_cnt_0    : std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
   signal dbg_cpt_second_edge_cnt_1   : std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
   signal dbg_rd_bitslip_cnt_14       : std_logic_vector(3 * DQS_WIDTH - 1 downto 0);
   signal dbg_rd_clkdly_cnt_15        : std_logic_vector(2 * DQS_WIDTH - 1 downto 0);
   signal dbg_rd_active_dly_13        : std_logic_vector(4 downto 0);
   signal dbg_phy_rdlvl_11            : std_logic_vector(255 downto 0);
   signal dbg_phy_read_12             : std_logic_vector(255 downto 0);
   signal dbg_dly_clk_3               : std_logic;
   signal dbg_cpt_tap_cnt_2           : std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
   signal dbg_rsync_tap_cnt_20        : std_logic_vector(19 downto 0);
   signal dbg_dqs_tap_cnt_6      : std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
   signal dbg_dq_tap_cnt_4            : std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
   signal dbg_pd_clk_9                : std_logic;
   signal dbg_phy_pd_10               : std_logic_vector(255 downto 0);

--------- component phy_init ---------
   component phy_init
      generic (
         TCQ                         : integer := 100;
         nCK_PER_CLK                 : integer := 2;		
         CLK_PERIOD                  : integer := 3333;	
         BANK_WIDTH                  : integer := 2;
         COL_WIDTH                   : integer := 10;
         nCS_PER_RANK                : integer := 1;		
         DQ_WIDTH                    : integer := 64;
         ROW_WIDTH                   : integer := 14;
         CS_WIDTH                    : integer := 1;
         CKE_WIDTH                   : integer := 1;	
         DRAM_TYPE                   : string := "DDR3";
         REG_CTRL                    : string := "ON";
         CALIB_ROW_ADD               : std_logic_vector(15 downto 0) := X"0000";  
         CALIB_COL_ADD               : std_logic_vector(11 downto 0) := X"000";  
         CALIB_BA_ADD                : std_logic_vector(2 downto 0)  := "000";    
         AL                          : string := "0";		
         BURST_MODE                  : string := "8";		
         BURST_TYPE                  : string := "SEQ";		
         nAL                         : integer := 0;		
         nCL                         : integer := 5;		
         nCWL                        : integer := 5;		
         tRFC                        : integer := 110000;	
         OUTPUT_DRV                  : string := "HIGH";
         RTT_NOM                     : string := "60";		
         RTT_WR                      : string := "60";		
         WRLVL                       : string := "ON";		
         PHASE_DETECT                : string := "ON";		
         DDR2_DQSN_ENABLE            : string := "YES";		
         nSLOTS                      : integer := 1;		
         SIM_INIT_OPTION             : string := "NONE";		
         SIM_CAL_OPTION              : string := "NONE"		
      );
      port (
         clk                         : in std_logic;
         rst                         : in std_logic;
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
         chip_cnt                    : out std_logic_vector(1 downto 0);
         pd_cal_start                : out std_logic;
         pd_cal_done                 : in std_logic;
         pd_prech_req                : in std_logic;
         prech_done                  : out std_logic;
         dfi_init_complete           : out std_logic;
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
         phy_wrdata_en               : out std_logic;
         phy_wrdata                  : out std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
         phy_rddata_en               : out std_logic;
         phy_ioconfig                : out std_logic_vector(0 downto 0);
         phy_ioconfig_en             : out std_logic
      );
   end component;
   
--------- component phy_control_io ---------
   component phy_control_io
      generic (
         TCQ                    : integer := 100;		
         BANK_WIDTH             : integer := 2;		
         RANK_WIDTH             : integer := 1;		
         nCS_PER_RANK           : integer := 1;	
         CS_WIDTH               : integer := 1;		
         CKE_WIDTH              : integer := 1;		
         ROW_WIDTH              : integer := 14;		
         WRLVL                  : string := "OFF";		
         nCWL                   : integer := 5;		
         DRAM_TYPE              : string := "DDR3";
         REG_CTRL               : string := "ON";		
         REFCLK_FREQ            : real := 300.0;
         IODELAY_HP_MODE        : string := "ON";
         IODELAY_GRP            : string := "IODELAY_MIG";
         DDR2_EARLY_CS          : integer := 0
      );
      port (
         clk_mem                : in std_logic;
         clk                    : in std_logic;
         rst                    : in std_logic;
         mc_data_sel            : in std_logic; 
         dfi_address0           : in std_logic_vector(ROW_WIDTH - 1 downto 0);
         dfi_address1           : in std_logic_vector(ROW_WIDTH - 1 downto 0);
         dfi_bank0              : in std_logic_vector(BANK_WIDTH - 1 downto 0);
         dfi_bank1              : in std_logic_vector(BANK_WIDTH - 1 downto 0);
         dfi_cas_n0             : in std_logic;
         dfi_cas_n1             : in std_logic;
         dfi_cke0               : in std_logic_vector(CKE_WIDTH - 1 downto 0);
         dfi_cke1               : in std_logic_vector(CKE_WIDTH - 1 downto 0);
         dfi_cs_n0              : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
         dfi_cs_n1              : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
         dfi_odt0               : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
         dfi_odt1               : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
         dfi_ras_n0             : in std_logic;
         dfi_ras_n1             : in std_logic;
         dfi_reset_n            : in std_logic;
         dfi_we_n0              : in std_logic;
         dfi_we_n1              : in std_logic;
         phy_address0           : in std_logic_vector(ROW_WIDTH - 1 downto 0);
         phy_address1           : in std_logic_vector(ROW_WIDTH - 1 downto 0);
         phy_bank0              : in std_logic_vector(BANK_WIDTH - 1 downto 0);
         phy_bank1              : in std_logic_vector(BANK_WIDTH - 1 downto 0);
         phy_cas_n0             : in std_logic;
         phy_cas_n1             : in std_logic;
         phy_cke0               : in std_logic_vector(CKE_WIDTH - 1 downto 0);
         phy_cke1               : in std_logic_vector(CKE_WIDTH - 1 downto 0);
         phy_cs_n0              : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
         phy_cs_n1              : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
         phy_odt0               : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
         phy_odt1               : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
         phy_ras_n0             : in std_logic;
         phy_ras_n1             : in std_logic;
         phy_reset_n            : in std_logic;
         phy_we_n0              : in std_logic;
         phy_we_n1              : in std_logic;
         ddr_addr               : out std_logic_vector(ROW_WIDTH - 1 downto 0);
         ddr_ba                 : out std_logic_vector(BANK_WIDTH - 1 downto 0);
         ddr_ras_n              : out std_logic;
         ddr_cas_n              : out std_logic;
         ddr_we_n               : out std_logic;
         ddr_cke                : out std_logic_vector(CKE_WIDTH - 1 downto 0);
         ddr_cs_n               : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
         ddr_odt                : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
         ddr_parity             : out std_logic;
         ddr_reset_n            : out std_logic
      );
   end component;

--------- component phy_clock_io ---------
   component phy_clock_io
      generic (
         TCQ             : integer := 100;			
         CK_WIDTH        : integer := 2;			
         WRLVL           : string  := "OFF";		
         DRAM_TYPE       : string  := "DDR3";		
         REFCLK_FREQ     : real    := 300.0;		
         IODELAY_GRP     : string  := "IODELAY_MIG"	
      );
      port (
         clk_mem         : in std_logic;					
         clk             : in std_logic;					
         rst             : in std_logic;					
         ddr_ck_p        : out std_logic_vector(CK_WIDTH - 1 downto 0);	
         ddr_ck_n        : out std_logic_vector(CK_WIDTH - 1 downto 0)	
      );
   end component;
   
--------- component phy_data_io ---------
   component phy_data_io
      generic (
         TCQ                 : integer := 100;		
         nCK_PER_CLK         : integer := 2;		
         CLK_PERIOD          : integer := 3000;		
         DRAM_WIDTH          : integer := 8;		
         DM_WIDTH            : integer := 9;		
         DQ_WIDTH            : integer := 72;		
         DQS_WIDTH           : integer := 9;		
         DRAM_TYPE           : string  := "DDR3";
         nCWL                : integer := 5;		
         WRLVL               : string  := "OFF";		
         REFCLK_FREQ         : real    := 300.0;		
         IBUF_LPWR_MODE      : string  := "OFF";		
         IODELAY_HP_MODE     : string  := "ON";		
         IODELAY_GRP         : string  := "IODELAY_MIG";	
         nDQS_COL0           : integer := 4;		
         nDQS_COL1           : integer := 4;		
         nDQS_COL2           : integer := 0;		
         nDQS_COL3           : integer := 0;		
         DQS_LOC_COL0        : std_logic_vector(143 downto 0) := X"000000000000000000000000000003020100";
         DQS_LOC_COL1        : std_logic_vector(143 downto 0) := X"000000000000000000000000000007060504";
         DQS_LOC_COL2        : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
         DQS_LOC_COL3        : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
         USE_DM_PORT         : integer := 1	
      );
      port (
         clk_mem             : in std_logic;
         clk                 : in std_logic;
         clk_cpt             : in std_logic_vector(DQS_WIDTH - 1 downto 0);
         clk_rsync           : in std_logic_vector(3 downto 0);
         rst                 : in std_logic;
         rst_rsync           : in std_logic_vector(3 downto 0);
         dlyval_dq           : in std_logic_vector(5*DQS_WIDTH - 1 downto 0);
         dlyval_dqs          : in std_logic_vector(5*DQS_WIDTH - 1 downto 0);
         inv_dqs             : in std_logic_vector(DQS_WIDTH - 1 downto 0);
         wr_calib_dly        : in std_logic_vector(2*DQS_WIDTH - 1 downto 0);
         dqs_oe_n            : in std_logic_vector(4*DQS_WIDTH - 1 downto 0);
         dq_oe_n             : in std_logic_vector(4*DQS_WIDTH - 1 downto 0);
         dqs_rst             : in std_logic_vector((DQS_WIDTH * 4) - 1 downto 0);
         dm_ce               : in std_logic_vector(DQS_WIDTH - 1 downto 0);
         mask_data_rise0     : in std_logic_vector((DQ_WIDTH / 8) - 1 downto 0);
         mask_data_fall0     : in std_logic_vector((DQ_WIDTH / 8) - 1 downto 0);
         mask_data_rise1     : in std_logic_vector((DQ_WIDTH / 8) - 1 downto 0);
         mask_data_fall1     : in std_logic_vector((DQ_WIDTH / 8) - 1 downto 0);
         wr_data_rise0       : in std_logic_vector(DQ_WIDTH - 1 downto 0);
         wr_data_rise1       : in std_logic_vector(DQ_WIDTH - 1 downto 0);
         wr_data_fall0       : in std_logic_vector(DQ_WIDTH - 1 downto 0);
         wr_data_fall1       : in std_logic_vector(DQ_WIDTH - 1 downto 0);
         rd_bitslip_cnt      : in std_logic_vector(2*DQS_WIDTH - 1 downto 0);
         rd_clkdly_cnt       : in std_logic_vector(2*DQS_WIDTH - 1 downto 0);
         rd_clkdiv_inv       : in std_logic_vector(DQS_WIDTH - 1 downto 0);
         rd_data_rise0       : out std_logic_vector(DQ_WIDTH - 1 downto 0);
         rd_data_fall0       : out std_logic_vector(DQ_WIDTH - 1 downto 0);
         rd_data_rise1       : out std_logic_vector(DQ_WIDTH - 1 downto 0);
         rd_data_fall1       : out std_logic_vector(DQ_WIDTH - 1 downto 0);
         rd_dqs_rise0        : out std_logic_vector(DQS_WIDTH - 1 downto 0);
         rd_dqs_fall0        : out std_logic_vector(DQS_WIDTH - 1 downto 0);
         rd_dqs_rise1        : out std_logic_vector(DQS_WIDTH - 1 downto 0);
         rd_dqs_fall1        : out std_logic_vector(DQS_WIDTH - 1 downto 0);
         ddr_dm              : out std_logic_vector(DM_WIDTH - 1 downto 0);
         ddr_dqs_p           : inout std_logic_vector(DQS_WIDTH - 1 downto 0);
         ddr_dqs_n           : inout std_logic_vector(DQS_WIDTH - 1 downto 0);
         ddr_dq              : inout std_logic_vector(DQ_WIDTH - 1 downto 0);
         dbg_dqs_tap_cnt     : out std_logic_vector(5*DQS_WIDTH - 1 downto 0); 
         dbg_dq_tap_cnt      : out std_logic_vector(5*DQS_WIDTH - 1 downto 0)   
      );
   end component;
   
--------- component phy_dly_ctrl ---------
   component phy_dly_ctrl
      generic (
         TCQ             	: integer := 100;	
         DQ_WIDTH       	: integer := 64;	
         DQS_CNT_WIDTH   	: integer := 3;		
         DQS_WIDTH     		: integer := 8; 	
         RANK_WIDTH     	: integer := 1; 	
         nCWL     		: integer := 5; 	
         REG_CTRL               : string  := "OFF";
         WRLVL    		: string  := "ON"; 	
         PHASE_DETECT		: string  := "ON"; 	
         DRAM_TYPE		: string  := "DDR3";   	
         nDQS_COL0		: integer := 4;		
         nDQS_COL1		: integer := 4;		
         nDQS_COL2		: integer := 0;		
         nDQS_COL3		: integer := 0;		
         DQS_LOC_COL0           : std_logic_vector(143 downto 0) := X"000000000000000000000000000003020100";
         DQS_LOC_COL1           : std_logic_vector(143 downto 0) := X"000000000000000000000000000007060504";
         DQS_LOC_COL2           : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
         DQS_LOC_COL3           : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
         DEBUG_PORT             : string := "OFF" 
      );
      port (
         clk    	        : in std_logic;  
         rst       		: in std_logic; 
         clk_rsync	        : in std_logic_vector(3 downto 0);  
         rst_rsync       	: in std_logic_vector(3 downto 0); 
         wrlvl_done      	: in std_logic; 
         rdlvl_done          	: in std_logic_vector(1 downto 0);
         pd_cal_done   		: in std_logic; 
         mc_data_sel   		: in std_logic; 
         mc_ioconfig   		: in std_logic_vector(RANK_WIDTH downto 0);
         mc_ioconfig_en   	: in std_logic; 
         phy_ioconfig   	: in std_logic_vector(0 downto 0); 
         phy_ioconfig_en 	: in std_logic; 
         dqs_oe	   		: in std_logic; 
         dlyval_wrlvl_dqs	: in std_logic_vector((5*DQS_WIDTH-1) downto 0);
         dlyval_wrlvl_dq	: in std_logic_vector((5*DQS_WIDTH-1) downto 0);
         dlyce_rdlvl_cpt	: in std_logic_vector((DQS_WIDTH-1) downto 0);
         dlyinc_rdlvl_cpt	: in std_logic;
         dlyce_rdlvl_rsync	: in std_logic_vector(3 downto 0);
         dlyinc_rdlvl_rsync	: in std_logic;
         dlyval_rdlvl_dq	: in std_logic_vector((5*DQS_WIDTH-1) downto 0);
         dlyval_rdlvl_dqs	: in std_logic_vector((5*DQS_WIDTH-1) downto 0);
         dlyce_pd_cpt		: in std_logic_vector((DQS_WIDTH-1) downto 0);
         dlyinc_pd_cpt		: in std_logic_vector((DQS_WIDTH-1) downto 0);
         dlyval_pd_dqs	        : in std_logic_vector((5*DQS_WIDTH-1) downto 0);
         dlyval_dqs		: out std_logic_vector((5*DQS_WIDTH-1) downto 0);
         dlyval_dq		: out std_logic_vector((5*DQS_WIDTH-1) downto 0);
         dlyrst_cpt		: out std_logic;
         dlyce_cpt		: out std_logic_vector((DQS_WIDTH-1) downto 0);
         dlyinc_cpt		: out std_logic_vector((DQS_WIDTH-1) downto 0);
         dlyrst_rsync		: out std_logic;
         dlyce_rsync		: out std_logic_vector(3 downto 0);
         dlyinc_rsync		: out std_logic_vector(3 downto 0);
         dbg_pd_off		: in std_logic
      );
   end component;
   
-------- component phy_write ---------
   component phy_write
      generic (
         TCQ             	: integer := 100;
         WRLVL	   		: string  := "ON";		
         DRAM_TYPE	   	: string  := "DDR3";		
         DQ_WIDTH       	: integer := 64;	
         DQS_WIDTH     		: integer := 8; 
         nCWL			: integer := 5;
         REG_CTRL		: string  := "OFF";
         RANK_WIDTH		: integer := 1;   
         CLKPERF_DLY_USED 	: string  := "OFF"		
         );
      port (
         clk    	        : in std_logic;  
         rst       		: in std_logic; 
         mc_data_sel      	: in std_logic; 
         wrlvl_active     	: in std_logic; 
         wrlvl_done       	: in std_logic; 
         inv_dqs      		: in std_logic_vector(DQS_WIDTH-1 downto 0); 
         wr_calib_dly     	: in std_logic_vector(2*DQS_WIDTH-1 downto 0); 
         dfi_wrdata     	: in std_logic_vector(4*DQ_WIDTH-1 downto 0); 
         dfi_wrdata_mask  	: in std_logic_vector((4*DQ_WIDTH/8)-1 downto 0); 
         dfi_wrdata_en    	: in std_logic; 
         mc_ioconfig_en   	: in std_logic; 				
         mc_ioconfig    	: in std_logic_vector(RANK_WIDTH downto 0); 	
         phy_wrdata_en    	: in std_logic; 
         phy_wrdata    		: in std_logic_vector(4*DQ_WIDTH-1 downto 0);
         phy_ioconfig_en  	: in std_logic; 				
         phy_ioconfig    	: in std_logic_vector(0 downto 0);		
         out_oserdes_wc		: in std_logic;
         dm_ce  	  	: out std_logic_vector(DQS_WIDTH-1 downto 0);
         dq_oe_n    		: out std_logic_vector(4*DQS_WIDTH-1 downto 0);
         dqs_oe_n    		: out std_logic_vector(4*DQS_WIDTH-1 downto 0);
         dqs_rst    		: out std_logic_vector(4*DQS_WIDTH-1 downto 0);
         dq_wc			: out std_logic;
         dqs_wc			: out std_logic;
         mask_data_rise0	: out std_logic_vector((DQ_WIDTH/8)-1 downto 0);
         mask_data_fall0	: out std_logic_vector((DQ_WIDTH/8)-1 downto 0);
         mask_data_rise1	: out std_logic_vector((DQ_WIDTH/8)-1 downto 0);
         mask_data_fall1	: out std_logic_vector((DQ_WIDTH/8)-1 downto 0);
         wl_sm_start		: out std_logic;
         wr_lvl_start		: out std_logic;
         wr_data_rise0		: out std_logic_vector(DQ_WIDTH-1 downto 0);
         wr_data_fall0		: out std_logic_vector(DQ_WIDTH-1 downto 0);
         wr_data_rise1		: out std_logic_vector(DQ_WIDTH-1 downto 0);
         wr_data_fall1		: out std_logic_vector(DQ_WIDTH-1 downto 0)
      );	 
   end component;
   
--------- component phy_wrlvl ---------
   component phy_wrlvl
      generic (
         TCQ             		: integer := 100;
         DQS_CNT_WIDTH   		: integer := 3;		
         DQ_WIDTH       		: integer := 64;	
         SHIFT_TBY4_TAP    		: integer := 7;	
         DQS_WIDTH     			: integer := 8; 
         DRAM_WIDTH			: integer := 8;   
         CS_WIDTH			: integer := 1;
         CAL_WIDTH			: string  := "HALF";
         DQS_TAP_CNT_INDEX		: integer := 42;
         SIM_CAL_OPTION                 : string  := "NONE"
      );
      port (
         clk    	        	: in std_logic;  
         rst       			: in std_logic; 
         calib_width      		: in std_logic_vector(2 downto 0); 
         rank_cnt          		: in std_logic_vector(1 downto 0);
         wr_level_start   		: in std_logic; 
         wl_sm_start   			: in std_logic; 
         rd_data_rise0   		: in std_logic_vector((DQ_WIDTH-1) downto 0);
         rdlvl_error			: in std_logic;
         rdlvl_err_byte			: in std_logic_vector((DQS_CNT_WIDTH-1) downto 0);
         wr_level_done			: out std_logic;
         wrlvl_rank_done  		: out std_logic;
         dlyval_wr_dqs    		: out std_logic_vector(DQS_TAP_CNT_INDEX downto 0);
         dlyval_wr_dq      		: out std_logic_vector(DQS_TAP_CNT_INDEX downto 0);
         inv_dqs       			: out std_logic_vector((DQS_WIDTH-1) downto 0);
         rdlvl_resume			: out std_logic;
         wr_calib_dly			: out std_logic_vector((2*DQS_WIDTH-1) downto 0);
         wrcal_err			: out std_logic;
         wrlvl_err			: out std_logic;
         dbg_wl_tap_cnt			: out std_logic_vector(4 downto 0);
         dbg_wl_edge_detect_valid	: out std_logic;
         dbg_rd_data_edge_detect	: out std_logic_vector((DQS_WIDTH-1) downto 0);
         dbg_rd_data_inv_edge_detect	: out std_logic_vector((DQS_WIDTH-1) downto 0);
         dbg_dqs_count			: out std_logic_vector(DQS_CNT_WIDTH downto 0);
         dbg_wl_state			: out std_logic_vector(3 downto 0)
      );
   end component;
   
--------- component phy_read ---------
   component phy_read
      generic (
         TCQ 		   	: integer := 100;
         nCK_PER_CLK       	: integer := 2;       		 
         CLK_PERIOD        	: integer := 3333;    		 
         REFCLK_FREQ       	: real := 300.0;   		 
         DQS_WIDTH         	: integer := 8;       		 
         DQ_WIDTH          	: integer := 64;      		 
         DRAM_WIDTH        	: integer := 8;       		 
         IODELAY_GRP       	: string := "IODELAY_MIG"; 	 
         nDQS_COL0         	: integer := 4;       		 
         nDQS_COL1         	: integer := 4;       		 
         nDQS_COL2         	: integer := 0;       		 
         nDQS_COL3         	: integer := 0;       		 
         DQS_LOC_COL0      	: std_logic_vector(143 downto 0) := X"11100F0E0D0C0B0A09080706050403020100";
         DQS_LOC_COL1      	: std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
         DQS_LOC_COL2      	: std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
         DQS_LOC_COL3      	: std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000"
      );      
      port (
         clk_mem		: in std_logic;		     
         clk			: in std_logic;		     
         rst   		        : in std_logic;		     
         clk_rd_base		: in std_logic;		     
         dlyrst_cpt		: in std_logic;		     
         dlyce_cpt		: in std_logic_vector(DQS_WIDTH-1 downto 0);		     
         dlyinc_cpt		: in std_logic_vector(DQS_WIDTH-1 downto 0);		     
         dlyrst_rsync		: in std_logic;		     
         dlyce_rsync		: in std_logic_vector(3 downto 0);		     
         dlyinc_rsync		: in std_logic_vector(3 downto 0);		     
         clk_cpt		: out std_logic_vector(DQS_WIDTH-1 downto 0);		     
         clk_rsync		: out std_logic_vector(3 downto 0);		     
         rst_rsync		: out std_logic_vector(3 downto 0);		     
         rdpath_rdy		: out std_logic;	
         mc_data_sel		: in std_logic;		     
         rd_active_dly		: in std_logic_vector(4 downto 0);		     
         rd_data_rise0		: in std_logic_vector((DQ_WIDTH-1) downto 0);		     
         rd_data_fall0		: in std_logic_vector((DQ_WIDTH-1) downto 0);		     
         rd_data_rise1		: in std_logic_vector((DQ_WIDTH-1) downto 0);		     
         rd_data_fall1		: in std_logic_vector((DQ_WIDTH-1) downto 0);		     
         rd_dqs_rise0	        : in std_logic_vector((DQS_WIDTH-1) downto 0);		     
         rd_dqs_fall0	        : in std_logic_vector((DQS_WIDTH-1) downto 0);		     
         rd_dqs_rise1	        : in std_logic_vector((DQS_WIDTH-1) downto 0);		     
         rd_dqs_fall1	        : in std_logic_vector((DQS_WIDTH-1) downto 0);		     
         dfi_rddata_en		: in std_logic;		     
         phy_rddata_en		: in std_logic;		     
         dfi_rddata_valid	: out std_logic;		     
         dfi_rddata_valid_phy	: out std_logic;		     
         dfi_rddata		: out std_logic_vector((4*DQ_WIDTH-1) downto 0);		     
         dfi_rd_dqs		: out std_logic_vector((4*DQS_WIDTH-1) downto 0);		     
         dbg_cpt_tap_cnt	: out std_logic_vector(5*DQS_WIDTH-1 downto 0);	
         dbg_rsync_tap_cnt	: out std_logic_vector(19 downto 0);		
         dbg_phy_read		: out std_logic_vector(255 downto 0)		
   	);
   end component;	
   
--------- component phy_rdlvl ---------
   component phy_rdlvl
      generic (
         TCQ                       : integer := 100;	
         nCK_PER_CLK               : integer := 2;		
         CLK_PERIOD                : integer := 3333;	
         REFCLK_FREQ               : integer := 300;	
         DQ_WIDTH                  : integer := 64;	
         DQS_CNT_WIDTH             : integer := 3;		
         DQS_WIDTH                 : integer := 2;		
         DRAM_WIDTH                : integer := 8;
         DRAM_TYPE                 : string  := "DDR3";		
         PD_TAP_REQ                : integer := 10;	
         nCL                       : integer := 5;		
         SIM_CAL_OPTION            : string  := "FAST_WIN_DETECT";	
         REG_CTRL                  : string  := "ON";
         DEBUG_PORT                : string  := "ON"
         );
      port (
         clk                       : in std_logic;
         rst                       : in std_logic;
         rdlvl_start               : in std_logic_vector(1 downto 0);
         rdlvl_clkdiv_start        : in std_logic;
         rdlvl_rd_active           : in std_logic;
         rdlvl_done                : out std_logic_vector(1 downto 0);
         rdlvl_clkdiv_done         : out std_logic;
         rdlvl_err                 : out std_logic_vector(1 downto 0);
         rdlvl_prech_req           : out std_logic;
         prech_done                : in std_logic;
         rd_data_rise0             : in std_logic_vector(DQ_WIDTH - 1 downto 0);
         rd_data_fall0             : in std_logic_vector(DQ_WIDTH - 1 downto 0);
         rd_data_rise1             : in std_logic_vector(DQ_WIDTH - 1 downto 0);
         rd_data_fall1             : in std_logic_vector(DQ_WIDTH - 1 downto 0);
         dlyce_cpt                 : out std_logic_vector(DQS_WIDTH - 1 downto 0);
         dlyinc_cpt                : out std_logic;
         dlyce_rsync               : out std_logic_vector(3 downto 0);
         dlyinc_rsync              : out std_logic;
         dlyval_dq                 : out std_logic_vector(5*DQS_WIDTH - 1 downto 0);
         dlyval_dqs                : out std_logic_vector(5*DQS_WIDTH - 1 downto 0);
         rd_bitslip_cnt            : out std_logic_vector(2*DQS_WIDTH - 1 downto 0);
         rd_clkdly_cnt             : out std_logic_vector(2*DQS_WIDTH - 1 downto 0);
         rd_active_dly             : out std_logic_vector(4 downto 0);
         rdlvl_pat_resume          : in std_logic;					
         rdlvl_pat_err             : out std_logic;                                      
         rdlvl_pat_err_cnt         : out std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);
         rd_clkdiv_inv             : out std_logic_vector(DQS_WIDTH - 1 downto 0);
         dbg_cpt_first_edge_cnt    : out std_logic_vector(5*DQS_WIDTH - 1 downto 0);
         dbg_cpt_second_edge_cnt   : out std_logic_vector(5*DQS_WIDTH - 1 downto 0);
         dbg_rd_bitslip_cnt        : out std_logic_vector(3*DQS_WIDTH - 1 downto 0);
         dbg_rd_clkdiv_inv         : out std_logic_vector(DQS_WIDTH - 1 downto 0);
         dbg_rd_clkdly_cnt         : out std_logic_vector(2*DQS_WIDTH - 1 downto 0);
         dbg_rd_active_dly         : out std_logic_vector(4 downto 0);
         dbg_idel_up_all           : in std_logic;
         dbg_idel_down_all         : in std_logic;
         dbg_idel_up_cpt           : in std_logic;
         dbg_idel_down_cpt         : in std_logic;
         dbg_idel_up_rsync         : in std_logic;
         dbg_idel_down_rsync       : in std_logic;
         dbg_sel_idel_cpt          : in std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);
         dbg_sel_all_idel_cpt      : in std_logic;
         dbg_sel_idel_rsync        : in std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);
         dbg_sel_all_idel_rsync    : in std_logic;
         dbg_phy_rdlvl             : out std_logic_vector(255 downto 0)
      );
   end component;
   
--------- component phy_pd_top ---------
   component phy_pd_top
      generic (
         TCQ                     : integer := 100;		
         DQS_CNT_WIDTH           : integer := 3;		
         DQS_WIDTH               : integer := 8;		
         SIM_CAL_OPTION          : string  := "NONE";	
         PD_LHC_WIDTH            : integer := 16;		
         PD_CALIB_MODE           : string  := "PARALLEL";	
         PD_MSB_SEL              : integer := 8;           
         PD_DQS0_ONLY            : string  := "ON";        
         DEBUG_PORT              : string  := "OFF"        
      );
      port (
         clk                     : in std_logic;
         rst                     : in std_logic;
         pd_cal_start            : in std_logic;					
         pd_cal_done             : out std_logic;					
         dfi_init_complete       : in std_logic;					
         read_valid              : in std_logic;					
         pd_PSEN                 : out std_logic;                                  
         pd_PSINCDEC             : out std_logic;                                  
         dlyval_rdlvl_dqs        : in  std_logic_vector(5*DQS_WIDTH - 1 downto 0);	
         dlyce_pd_cpt            : out std_logic_vector(DQS_WIDTH - 1 downto 0);	
         dlyinc_pd_cpt           : out std_logic_vector(DQS_WIDTH - 1 downto 0);	
         dlyval_pd_dqs           : out std_logic_vector(5*DQS_WIDTH - 1 downto 0); 
         rd_dqs_rise0            : in std_logic_vector(DQS_WIDTH - 1 downto 0);
         rd_dqs_fall0            : in std_logic_vector(DQS_WIDTH - 1 downto 0);
         rd_dqs_rise1            : in std_logic_vector(DQS_WIDTH - 1 downto 0);
         rd_dqs_fall1            : in std_logic_vector(DQS_WIDTH - 1 downto 0);
         pd_prech_req            : out std_logic;					
         prech_done              : in std_logic;					
         
         dbg_pd_off              : in std_logic;
         dbg_pd_maintain_off     : in std_logic;
         dbg_pd_maintain_0_only  : in std_logic;
         dbg_pd_inc_cpt          : in std_logic;
         dbg_pd_dec_cpt          : in std_logic;
         dbg_pd_inc_dqs          : in std_logic;
         dbg_pd_dec_dqs          : in std_logic;
         dbg_pd_disab_hyst       : in std_logic;
         dbg_pd_disab_hyst_0     : in std_logic;
         dbg_pd_msb_sel          : in std_logic_vector(3 downto 0);
         dbg_pd_byte_sel         : in std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);
         dbg_inc_rd_fps          : in std_logic;
         dbg_dec_rd_fps          : in std_logic;
         dbg_phy_pd              : out std_logic_vector(255 downto 0)
      );
   end component;
   
--------- component phy_ocb_mon_top ---------
   component phy_ocb_mon_top
      generic (
         TCQ                   : integer := 100;
         MMCM_ADV_PS_WA        : string := "OFF";
         DRAM_TYPE             : string := "DDR3";
         CLKPERF_DLY_USED      : string := "OFF";
         SIM_CAL_OPTION        : string := "NONE"
      );
      port (         
         dbg_ocb_mon_off       : in std_logic;
         dbg_ocb_mon_clk       : out std_logic;
         dbg_ocb_mon           : out std_logic_vector(255 downto 0);      
         ocb_mon_PSEN          : out std_logic;		
         ocb_mon_PSINCDEC      : out std_logic;		
         ocb_mon_calib_done    : out std_logic;		
         ocb_mon_PSDONE        : in std_logic;		
         ocb_mon_go            : in std_logic;		
         clk_mem               : in std_logic;
         clk                   : in std_logic;
         clk_wr                : in std_logic;
         rst                   : in std_logic
      );
   end component;

begin

   -- Drive referenced outputs
   dfi_rddata <= dfi_rddata_37;
   dfi_rddata_valid <= dfi_rddata_valid_38;
   dfi_init_complete <= dfi_init_complete_36;
   ddr_ck_p <= ddr_ck_p_27;
   ddr_ck_n <= ddr_ck_n_26;
   ddr_addr <= ddr_addr_23;
   ddr_ba <= ddr_ba_24;
   ddr_ras_n <= ddr_ras_n_33;
   ddr_cas_n <= ddr_cas_n_25;
   ddr_we_n <= ddr_we_n_35;
   ddr_cs_n <= ddr_cs_n_29;
   ddr_cke <= ddr_cke_28;
   ddr_odt <= ddr_odt_31;
   ddr_reset_n <= ddr_reset_n_34;
   ddr_parity <= ddr_parity_32;
   ddr_dm <= ddr_dm_30;
   dbg_tap_cnt_during_wrlvl <= dbg_tap_cnt_during_wrlvl_21;
   dbg_wl_edge_detect_valid <= dbg_wl_edge_detect_valid_22;
   dbg_rd_data_edge_detect <= dbg_rd_data_edge_detect_16;
   dbg_cpt_first_edge_cnt <= dbg_cpt_first_edge_cnt_0;
   dbg_cpt_second_edge_cnt <= dbg_cpt_second_edge_cnt_1;
   dbg_rd_bitslip_cnt <= dbg_rd_bitslip_cnt_14;
   dbg_rd_clkdly_cnt <= dbg_rd_clkdly_cnt_15;
   dbg_rd_active_dly <= dbg_rd_active_dly_13;
   dbg_phy_rdlvl <= dbg_phy_rdlvl_11;
   dbg_phy_read <= dbg_phy_read_12;
   dbg_cpt_tap_cnt <= dbg_cpt_tap_cnt_2;
   dbg_rsync_tap_cnt <= dbg_rsync_tap_cnt_20;
   dbg_dqs_tap_cnt <= dbg_dqs_tap_cnt_6;
   dbg_dq_tap_cnt <= dbg_dq_tap_cnt_4;
   dbg_phy_pd <= dbg_phy_pd_10;

   --***************************************************************************
   -- Debug
   --***************************************************************************
   -- Captured data in clk domain
   -- NOTE: Prior to MIG 3.4, this data was synchronized to CLK_RSYNC domain
   --  But was never connected beyond PHY_TOP (at the MEM_INTFC level, this
   --  port is never used, and instead DFI_RDDATA was routed to DBG_RDDATA)
   dbg_rd_data <= dfi_rddata_37;

   -- Unused for now - use these as needed to bring up lower level signals
   dbg_phy_top <= (others => '0');

   -- Write Level and write calibration debug observation ports
   dbg_wrlvl_start           <= wrlvl_start;  
   dbg_wrlvl_done            <= wrlvl_done;
   dbg_wrlvl_err             <= wrlvl_err;
   dbg_wl_dqs_inverted       <= dqs_inv;
   dbg_wl_odelay_dqs_tap_cnt <= dlyval_wrlvl_dqs;
   dbg_wl_odelay_dq_tap_cnt  <= dlyval_wrlvl_dq;
   dbg_wr_calib_clk_delay    <= wr_calib_dly;

   -- Read Level debug observation ports
   dbg_rdlvl_start           <= rdlvl_start;
   dbg_rdlvl_done            <= rdlvl_done;
   dbg_rdlvl_err             <= rdlvl_err;

   --***************************************************************************
   -- Write leveling dependent signals
   --***************************************************************************  
   rdlvl_pat_resume_w <= rdlvl_pat_resume when (WRLVL_W = "ON") else '0';
   dqs_inv            <= inv_dqs when (WRLVL_W = "ON") else (others => '0');
   wrcal_dly_w        <= wr_calib_dly when (WRLVL_W = "ON") else (others => '0');

   -- Rank count (chip_cnt) from phy_init for write bitslip during read leveling
   -- Rank count (io_config) from MC during normal operation
   process (rst, dfi_init_complete_36, chip_cnt_r1, io_config)
   begin
      if ((rst = '1') or (RANK_WIDTH = 0)) then
         rank_cnt <= "00";
      else
         if (dfi_init_complete_36 = '0') then	      
            rank_cnt <= chip_cnt_r1;
         else
	    -- io_config[1:0] causes warning with VCS
            -- io_config[RANK_WIDTH-1:0] causes error with VCS
	    if (RANK_WIDTH = 2) then		 
               rank_cnt <= io_config(1 downto 0);
            else   
               rank_cnt <= ('0' & io_config(0));
	    end if;
         end if;
      end if;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         chip_cnt_r  <= chip_cnt after (TCQ)*1 ps;
         chip_cnt_r1 <= chip_cnt_r after (TCQ)*1 ps;
      end if;
   end process;

   --*****************************************************************
   -- DETERMINE DQ/DQS output delay values
   --   1. If WRLVL disabled: DQS = 0 delay, DQ = 90 degrees delay
   --   2. If WRLVL enabled: DQS and DQ delays are determined during
   --      write leveling
   -- For multi-rank design the appropriate rank values will be sent to
   -- phy_write, phy_dly_ctrl, and phy_data_io
   --*****************************************************************
   gen_offset_tap: for offset_i in 0 to (DQS_WIDTH-1) generate
      gen_offset_tap_dbg: if (DEBUG_PORT = "ON") generate
         -- Allow debug port to modify the post-write-leveling ODELAY
         -- values of DQ and DQS. This can be used to measure DQ-DQS
         -- (as well as tDQSS) timing margin on writes  
	 dlyval_wrlvl_dq(5*offset_i+4 downto 5*offset_i) <=       
	                 dbg_wr_dq_tap_set(5*offset_i+4 downto 5*offset_i) when ((WRLVL_W = "ON") and ((wrlvl_done and dbg_wr_tap_set_en)= '1'))    else
	                 dlyval_wrlvl_dq_w(5*offset_i+4 downto 5*offset_i) when ((WRLVL_W = "ON") and not((wrlvl_done and dbg_wr_tap_set_en)= '1')) else
	                 dbg_wr_dq_tap_set(5*offset_i+4 downto 5*offset_i) when (not(WRLVL_W = "ON") and (dbg_wr_tap_set_en = '1'))                 else
                         std_logic_vector(to_unsigned(SHIFT_TBY4_TAP,5));

	 dlyval_wrlvl_dqs(5*offset_i+4 downto 5*offset_i) <=       
	                 dbg_wr_dqs_tap_set(5*offset_i+4 downto 5*offset_i) when ((WRLVL_W = "ON") and ((wrlvl_done and dbg_wr_tap_set_en)= '1'))    else
	                 dlyval_wrlvl_dqs_w(5*offset_i+4 downto 5*offset_i) when ((WRLVL_W = "ON") and not((wrlvl_done and dbg_wr_tap_set_en)= '1')) else
	                 dbg_wr_dqs_tap_set(5*offset_i+4 downto 5*offset_i) when (not(WRLVL_W = "ON") and (dbg_wr_tap_set_en = '1'))                 else
			 (others => '0');
      end generate;
      gen_offset_tap_nodbg: if (not(DEBUG_PORT = "ON")) generate
         dlyval_wrlvl_dq(5*offset_i+4 downto 5*offset_i)  <= dlyval_wrlvl_dq_w(5*offset_i+4 downto 5*offset_i) when (WRLVL_W = "ON") else
							     std_logic_vector(to_unsigned(SHIFT_TBY4_TAP,5));
         dlyval_wrlvl_dqs(5*offset_i+4 downto 5*offset_i) <= dlyval_wrlvl_dqs_w(5*offset_i+4 downto 5*offset_i) when (WRLVL_W = "ON") else
	 						     (others => '0');
      end generate;
   end generate;    

   --***************************************************************************
   -- Used for multi-rank case to determine the number of ranks to be calibrated
   -- The number of ranks to be calibrated can be less than the CS_WIDTH (rank
   -- width)
   -- Assumes at least one rank per slot to be calibrated
   -- If nSLOTS equals 1 slot_1_present input will be ignored
   -- Assumes CS_WIDTH to be 1, 2, 3, or 4
   --***************************************************************************
   gen_single_slot : if (nSLOTS = 1) generate
      xhdl1 <= slot_0_present(0) & slot_0_present(1) & slot_0_present(2) & slot_0_present(3);
      process (clk)
      begin
         if (clk'event and clk = '1') then
            case xhdl1 is
               -- single slot quad rank calibration
               when "1111" =>
                  if (CAL_WIDTH = "FULL") then
                     calib_width <= "100" after (TCQ)*1 ps;
                  else
                     calib_width <= "010" after (TCQ)*1 ps;
                  end if;
               -- single slot dual rank calibration
               when "1100" =>
                  if (CAL_WIDTH = "FULL") then
                     calib_width <= "010" after (TCQ)*1 ps;
                  else
                     calib_width <= "001" after (TCQ)*1 ps;
                  end if;
               when others =>
                  calib_width <= "001" after (TCQ)*1 ps;
            end case;
         end if;
      end process;     
   end generate;

   gen_dual_slot : if (nSLOTS = 2) generate
      xhdl2 <= slot_0_present(0) & slot_0_present(1) & slot_1_present(0) & slot_1_present(1);
      process (clk)
      begin
         if (clk'event and clk = '1') then
            case xhdl2 is
               -- two slots single rank per slot CAL_WIDTH ignored since one rank
               -- per slot must be calibrated
               when "1010" =>
                  calib_width <= "010" after (TCQ)*1 ps;
               -- two slots single rank in slot0
               when "1000" =>
                  calib_width <= "001" after (TCQ)*1 ps;
               -- two slots single rank in slot1
               when "0010" =>
                  calib_width <= "001" after (TCQ)*1 ps;
               -- two slots two ranks per slot calibration
               when "1111" =>
                  if (CAL_WIDTH = "FULL") then
                     calib_width <= "100" after (TCQ)*1 ps;
                  else
                     calib_width <= "010" after (TCQ)*1 ps;
                  end if;
               -- two slots: 2 ranks in slot0, 1 rank in slot1
               when "1110" =>
                  if (CAL_WIDTH = "FULL") then
                     calib_width <= "011" after (TCQ)*1 ps;
                  else
                     calib_width <= "010" after (TCQ)*1 ps;
                  end if;
               -- two slots: 2 ranks in slot0, none in slot1
               when "1100" =>
                  if (CAL_WIDTH = "FULL") then
                     calib_width <= "010" after (TCQ)*1 ps;
                  else
                     calib_width <= "001" after (TCQ)*1 ps;
                  end if;
               -- two slots: 1 rank in slot0, 2 ranks in slot1
               when "1011" =>
                  if (CAL_WIDTH = "FULL") then
                     calib_width <= "011" after (TCQ)*1 ps;
                  else
                     calib_width <= "010" after (TCQ)*1 ps;
                  end if;
               -- two slots: none in slot0, 2 ranks in slot1
               when "0011" =>
                  if (CAL_WIDTH = "FULL") then
                     calib_width <= "010" after (TCQ)*1 ps;
                  else
                     calib_width <= "001" after (TCQ)*1 ps;
                  end if;
               when others =>
                  calib_width <= "010" after (TCQ)*1 ps;
            end case;
         end if;
      end process;         
   end generate;
   
   --***************************************************************************
   -- Initialization / Master PHY state logic (overall control during memory
   -- init, timing leveling)
   --***************************************************************************   
   u_phy_init : phy_init
      generic map (
         tcq              => TCQ,
         nck_per_clk      => nCK_PER_CLK,
         clk_period       => CLK_PERIOD,
         dram_type        => DRAM_TYPE,
         bank_width       => BANK_WIDTH,
         col_width        => COL_WIDTH,
         ncs_per_rank     => nCS_PER_RANK,
         dq_width         => DQ_WIDTH,
         row_width        => ROW_WIDTH,
         cs_width         => CS_WIDTH,
	 cke_width        => CKE_WIDTH,
	 calib_row_add    => CALIB_ROW_ADD,
	 calib_col_add    => CALIB_COL_ADD,
	 calib_ba_add     => CALIB_BA_ADD,
         al               => AL,
         burst_mode       => BURST_MODE,
         burst_type       => BURST_TYPE,
         nal              => nAL,
         ncl              => nCL,
         ncwl             => nCWL,
         trfc             => tRFC,
         output_drv       => OUTPUT_DRV,
         reg_ctrl         => REG_CTRL,
         rtt_nom          => RTT_NOM,
         rtt_wr           => RTT_WR,
         wrlvl            => WRLVL_W,
         phase_detect     => USE_PHASE_DETECT,
         nslots           => nSLOTS,
         sim_init_option  => SIM_INIT_OPTION_W,
         sim_cal_option   => SIM_CAL_OPTION_W
      )
      port map (
         clk                => clk,
         rst                => rst,
         calib_width        => calib_width,
         rdpath_rdy         => rdpath_rdy,
         wrlvl_done         => wrlvl_done,
         wrlvl_rank_done    => wrlvl_rank_done,
         wrlvl_active       => wrlvl_active,
         slot_0_present     => slot_0_present,
         slot_1_present     => slot_1_present,
         rdlvl_done         => rdlvl_done,
         rdlvl_start        => rdlvl_start,
         rdlvl_clkdiv_done  => rdlvl_clkdiv_done,
         rdlvl_clkdiv_start => rdlvl_clkdiv_start,         
         rdlvl_prech_req    => rdlvl_prech_req,
         rdlvl_resume       => rdlvl_pat_resume_w,
         chip_cnt           => chip_cnt,
         pd_cal_start       => pd_cal_start,
         pd_cal_done        => pd_cal_done,
         pd_prech_req       => pd_prech_req,
         prech_done         => prech_done,
         dfi_init_complete  => dfi_init_complete_36,
         phy_address0       => phy_address0,
         phy_address1       => phy_address1,
         phy_bank0          => phy_bank0,
         phy_bank1          => phy_bank1,
         phy_cas_n0         => phy_cas_n0,
         phy_cas_n1         => phy_cas_n1,
         phy_cke0           => phy_cke0,
         phy_cke1           => phy_cke1,
         phy_cs_n0          => phy_cs_n0,
         phy_cs_n1          => phy_cs_n1,
         phy_init_data_sel  => phy_init_data_sel,
         phy_odt0           => phy_odt0,
         phy_odt1           => phy_odt1,
         phy_ras_n0         => phy_ras_n0,
         phy_ras_n1         => phy_ras_n1,
         phy_reset_n        => phy_reset_n,
         phy_we_n0          => phy_we_n0,
         phy_we_n1          => phy_we_n1,
         phy_wrdata_en      => phy_wrdata_en,
         phy_wrdata         => phy_wrdata,
         phy_rddata_en      => phy_rddata_en,
         phy_ioconfig       => phy_io_config,
         phy_ioconfig_en    => phy_io_config_strobe
      );
   
   --*****************************************************************
   -- Control/Address MUX and IOB logic
   --*****************************************************************   
   u_phy_control_io : phy_control_io
      generic map (
         tcq               => TCQ,
         bank_width        => BANK_WIDTH,
         rank_width        => RANK_WIDTH,
         ncs_per_rank      => nCS_PER_RANK,
         cs_width          => CS_WIDTH,
         row_width         => ROW_WIDTH,
	 cke_width         => CKE_WIDTH,
         wrlvl             => WRLVL_W,
         ncwl              => CWL_M,
         dram_type         => DRAM_TYPE,
         reg_ctrl          => REG_CTRL,
         refclk_freq       => REFCLK_FREQ,
         iodelay_hp_mode   => IODELAY_HP_MODE,
         iodelay_grp       => IODELAY_GRP,
         ddr2_early_cs     => DDR2_EARLY_CS
      )
      port map (
         clk_mem         => clk_mem,
         clk             => clk,
         rst             => rst,
         mc_data_sel     => phy_init_data_sel,
         dfi_address0    => dfi_address0,
         dfi_address1    => dfi_address1,
         dfi_bank0       => dfi_bank0,
         dfi_bank1       => dfi_bank1,
         dfi_cas_n0      => dfi_cas_n0,
         dfi_cas_n1      => dfi_cas_n1,
         dfi_cke0        => dfi_cke0,
         dfi_cke1        => dfi_cke1,
         dfi_cs_n0       => dfi_cs_n0,
         dfi_cs_n1       => dfi_cs_n1,
         dfi_odt0        => dfi_odt0,
         dfi_odt1        => dfi_odt1,
         dfi_ras_n0      => dfi_ras_n0,
         dfi_ras_n1      => dfi_ras_n1,
         dfi_reset_n     => dfi_reset_n,
         dfi_we_n0       => dfi_we_n0,
         dfi_we_n1       => dfi_we_n1,
         phy_address0    => phy_address0,
         phy_address1    => phy_address1,
         phy_bank0       => phy_bank0,
         phy_bank1       => phy_bank1,
         phy_cas_n0      => phy_cas_n0,
         phy_cas_n1      => phy_cas_n1,
         phy_cke0        => phy_cke0,
         phy_cke1        => phy_cke1,
         phy_cs_n0       => phy_cs_n0,
         phy_cs_n1       => phy_cs_n1,
         phy_odt0        => phy_odt0,
         phy_odt1        => phy_odt1,
         phy_ras_n0      => phy_ras_n0,
         phy_ras_n1      => phy_ras_n1,
         phy_reset_n     => phy_reset_n,
         phy_we_n0       => phy_we_n0,
         phy_we_n1       => phy_we_n1,
         ddr_addr        => ddr_addr_23,
         ddr_ba          => ddr_ba_24,
         ddr_ras_n       => ddr_ras_n_33,
         ddr_cas_n       => ddr_cas_n_25,
         ddr_we_n        => ddr_we_n_35,
         ddr_cke         => ddr_cke_28,
         ddr_cs_n        => ddr_cs_n_29,
         ddr_odt         => ddr_odt_31,
         ddr_parity      => ddr_parity_32,
         ddr_reset_n     => ddr_reset_n_34
      );
   
   --*****************************************************************
   -- Memory clock forwarding and feedback
   --*****************************************************************   
   u_phy_clock_io : phy_clock_io
      generic map (
         tcq               => TCQ,
         ck_width          => CK_WIDTH,
         wrlvl             => WRLVL_W,
         dram_type         => DRAM_TYPE,
         refclk_freq       => REFCLK_FREQ,
         iodelay_grp       => IODELAY_GRP
      )
      port map (
         clk_mem    => clk_mem,
         clk        => clk,
         rst        => rst,
         ddr_ck_p   => ddr_ck_p_27,
         ddr_ck_n   => ddr_ck_n_26
      );
   
   --*****************************************************************
   -- Data-related IOBs (data, strobe, mask), and regional clock buffers
   -- Also includes output clock IOBs, and external feedback clock
   --*****************************************************************   
   u_phy_data_io : phy_data_io
      generic map (
         tcq               => TCQ,
         nck_per_clk       => nCK_PER_CLK,
         clk_period        => CLK_PERIOD,
         dram_type         => DRAM_TYPE,
         dram_width        => DRAM_WIDTH,
         dm_width          => DM_WIDTH,
         dq_width          => DQ_WIDTH,
         dqs_width         => DQS_WIDTH,
         ncwl              => CWL_M,
         wrlvl             => WRLVL_W,
         refclk_freq       => REFCLK_FREQ,
         ibuf_lpwr_mode    => IBUF_LPWR_MODE,
         iodelay_hp_mode   => IODELAY_HP_MODE,
         iodelay_grp       => IODELAY_GRP,
         ndqs_col0         => nDQS_COL0,
         ndqs_col1         => nDQS_COL1,
         ndqs_col2         => nDQS_COL2,
         ndqs_col3         => nDQS_COL3,
         dqs_loc_col0      => DQS_LOC_COL0,
         dqs_loc_col1      => DQS_LOC_COL1,
         dqs_loc_col2      => DQS_LOC_COL2,
         dqs_loc_col3      => DQS_LOC_COL3,
         use_dm_port       => USE_DM_PORT
      )
      port map (
         clk_mem             => clk_mem,
         clk                 => clk,
         clk_cpt             => clk_cpt,
         clk_rsync           => clk_rsync,
         rst                 => rst,
         rst_rsync           => rst_rsync,
         -- IODELAY I/F
         dlyval_dq           => dlyval_dq,
         dlyval_dqs          => dlyval_dqs,
         -- Write datapath I/F
         inv_dqs             => dqs_inv,
         wr_calib_dly        => wrcal_dly_w,
         dqs_oe_n            => dqs_oe_n,
         dq_oe_n             => dq_oe_n,
         dqs_rst             => dqs_rst,
         dm_ce               => dm_ce,
         mask_data_rise0     => mask_data_rise0,
         mask_data_fall0     => mask_data_fall0,
         mask_data_rise1     => mask_data_rise1,
         mask_data_fall1     => mask_data_fall1,
         wr_data_rise0       => wr_data_rise0,
         wr_data_fall0       => wr_data_fall0,
         wr_data_rise1       => wr_data_rise1,
         wr_data_fall1       => wr_data_fall1,
         -- Read datapath I/F
         rd_bitslip_cnt      => rd_bitslip_cnt,
         rd_clkdly_cnt       => rd_clkdly_cnt,
         rd_clkdiv_inv       => rd_clkdiv_inv,
         rd_data_rise0       => rd_data_rise0,
         rd_data_fall0       => rd_data_fall0,
         rd_data_rise1       => rd_data_rise1,
         rd_data_fall1       => rd_data_fall1,
         rd_dqs_rise0        => rd_dqs_rise0,
         rd_dqs_fall0        => rd_dqs_fall0,
         rd_dqs_rise1        => rd_dqs_rise1,
         rd_dqs_fall1        => rd_dqs_fall1,
         -- DDR3 bus signals
         ddr_dm              => ddr_dm_30,
         ddr_dqs_p           => ddr_dqs_p,
         ddr_dqs_n           => ddr_dqs_n,
         ddr_dq              => ddr_dq,
	 -- Debug signals
	 dbg_dqs_tap_cnt     => dbg_dqs_tap_cnt_6,
         dbg_dq_tap_cnt      => dbg_dq_tap_cnt_4
      );
   
   --*****************************************************************
   -- IODELAY control logic
   --*****************************************************************   
   u_phy_dly_ctrl : phy_dly_ctrl
      generic map (
         tcq            => TCQ,
         dq_width       => DQ_WIDTH,
         dqs_cnt_width  => DQS_CNT_WIDTH,
         dqs_width      => DQS_WIDTH,
         rank_width     => RANK_WIDTH,
         ncwl           => CWL_M,
         reg_ctrl       => REG_CTRL,
         wrlvl          => WRLVL_W,
         phase_detect   => USE_PHASE_DETECT,
         dram_type      => DRAM_TYPE,
         ndqs_col0      => nDQS_COL0,
         ndqs_col1      => nDQS_COL1,
         ndqs_col2      => nDQS_COL2,
         ndqs_col3      => nDQS_COL3,
         dqs_loc_col0   => DQS_LOC_COL0,
         dqs_loc_col1   => DQS_LOC_COL1,
         dqs_loc_col2   => DQS_LOC_COL2,
         dqs_loc_col3   => DQS_LOC_COL3,
         debug_port    => DEBUG_PORT
      )
      port map (
         clk                    => clk,
         rst                    => rst,
         clk_rsync              => clk_rsync,
         rst_rsync              => rst_rsync,
         wrlvl_done             => wrlvl_done,
         rdlvl_done             => rdlvl_done,
         pd_cal_done            => pd_cal_done,
         mc_data_sel            => phy_init_data_sel,
         mc_ioconfig            => io_config,
         mc_ioconfig_en         => io_config_strobe,
         phy_ioconfig           => phy_io_config,
         phy_ioconfig_en        => phy_io_config_strobe,
         dqs_oe                 => dqs_oe,
         dlyval_wrlvl_dqs       => dlyval_wrlvl_dqs,
         dlyval_wrlvl_dq        => dlyval_wrlvl_dq,
         dlyce_rdlvl_cpt        => dlyce_rdlvl_cpt,
         dlyinc_rdlvl_cpt       => dlyinc_rdlvl_cpt,
         dlyce_rdlvl_rsync      => dlyce_rdlvl_rsync,
         dlyinc_rdlvl_rsync     => dlyinc_rdlvl_rsync,
         dlyval_rdlvl_dq        => dlyval_rdlvl_dq,
         dlyval_rdlvl_dqs       => dlyval_rdlvl_dqs,
         dlyce_pd_cpt           => dlyce_pd_cpt,
         dlyinc_pd_cpt          => dlyinc_pd_cpt,
         dlyval_pd_dqs          => dlyval_pd_dqs,
         dlyval_dqs             => dlyval_dqs,
         dlyval_dq              => dlyval_dq,
         dlyrst_cpt             => dlyrst_cpt,
         dlyce_cpt              => dlyce_cpt,
         dlyinc_cpt             => dlyinc_cpt,
         dlyrst_rsync           => dlyrst_rsync,
         dlyce_rsync            => dlyce_rsync,
         dlyinc_rsync           => dlyinc_rsync,
         dbg_pd_off             => dbg_pd_off
      );
   
   --*****************************************************************
   -- Write path logic (datapath, tri-state enable)
   --*****************************************************************   
   u_phy_write : phy_write
      generic map (
         tcq               => TCQ,
         wrlvl             => WRLVL_W,
         dq_width          => DQ_WIDTH,
         dqs_width         => DQS_WIDTH,
         dram_type         => DRAM_TYPE,
         rank_width        => RANK_WIDTH,
         ncwl              => CWL_M,
         REG_CTRL          => REG_CTRL
      )
      port map (
         clk              => clk,
         rst              => rst,
         mc_data_sel      => phy_init_data_sel,
         wrlvl_active     => wrlvl_active,
         wrlvl_done       => wrlvl_done,
         inv_dqs          => dqs_inv,
         wr_calib_dly     => wrcal_dly_w,
         dfi_wrdata       => dfi_wrdata,
         dfi_wrdata_mask  => dfi_wrdata_mask,
         dfi_wrdata_en    => dfi_wrdata_en,
         mc_ioconfig_en   => io_config_strobe,
         mc_ioconfig      => io_config,
         phy_wrdata       => phy_wrdata,
         phy_wrdata_en    => phy_wrdata_en,
         phy_ioconfig_en  => phy_io_config_strobe,
         phy_ioconfig     => phy_io_config,
         dm_ce            => dm_ce,
         dq_oe_n          => dq_oe_n,
         dqs_oe_n         => dqs_oe_n,
         dqs_rst          => dqs_rst,
         out_oserdes_wc   => out_oserdes_wc,
         dqs_wc           => open,
         dq_wc            => open,
         wl_sm_start      => wl_sm_start,
         wr_lvl_start     => wrlvl_start,
         wr_data_rise0    => wr_data_rise0,
         wr_data_fall0    => wr_data_fall0,
         wr_data_rise1    => wr_data_rise1,
         wr_data_fall1    => wr_data_fall1,
         mask_data_rise0  => mask_data_rise0,
         mask_data_fall0  => mask_data_fall0,
         mask_data_rise1  => mask_data_rise1,
         mask_data_fall1  => mask_data_fall1
      );

   --***************************************************************************
   -- Registered version of DQS Output Enable to determine when to switch
   -- from ODELAY to IDELAY in phy_dly_ctrl module
   --***************************************************************************

   -- SYNTHESIS_NOTE: might need another pipeline stage to meet timing      
   process (clk)
   begin
      if (clk'event and clk = '1') then
         dqs_oe <= not(AND_BR(dqs_oe_n)) after (TCQ)*1 ps;
      end if;
   end process;

   --***************************************************************************
   -- Write-leveling calibration logic
   --***************************************************************************
   mb_wrlvl_inst : if (WRLVL_W = "ON") generate
            
      u_phy_wrlvl : phy_wrlvl
         generic map (
            tcq                => TCQ,
            dqs_cnt_width      => DQS_CNT_WIDTH,
            dq_width           => DQ_WIDTH,
            dqs_width          => DQS_WIDTH,
            dram_width         => DRAM_WIDTH,
            cs_width           => CS_WIDTH,
            cal_width          => CAL_WIDTH,
            dqs_tap_cnt_index  => 5*DQS_WIDTH-1,
            shift_tby4_tap     => SHIFT_TBY4_TAP,
            SIM_CAL_OPTION     => SIM_CAL_OPTION_W
         )
         port map (
            clk                       => clk,
            rst                       => rst,
            calib_width               => calib_width,
            rank_cnt                  => rank_cnt,
            wr_level_start            => wrlvl_start,
            wl_sm_start               => wl_sm_start,
            rd_data_rise0             => dfi_rddata_37(DQ_WIDTH-1 downto 0),
            wr_level_done             => wrlvl_done,
            wrlvl_rank_done           => wrlvl_rank_done,
            dlyval_wr_dqs             => dlyval_wrlvl_dqs_w,
            dlyval_wr_dq              => dlyval_wrlvl_dq_w,
            inv_dqs                   => inv_dqs,
            rdlvl_error               => rdlvl_pat_err,
            rdlvl_err_byte            => rdlvl_pat_err_cnt,
            rdlvl_resume              => rdlvl_pat_resume,
            wr_calib_dly              => wr_calib_dly,
            wrcal_err                 => wrcal_err,
            wrlvl_err                 => wrlvl_err,
            dbg_wl_tap_cnt            => dbg_tap_cnt_during_wrlvl_21,
            dbg_wl_edge_detect_valid  => dbg_wl_edge_detect_valid_22,
            dbg_rd_data_edge_detect   => dbg_rd_data_edge_detect_16,
	    dbg_rd_data_inv_edge_detect => open,
            dbg_dqs_count             => open,
            dbg_wl_state              => open 
         );
   end generate;

   --*****************************************************************
   -- Read clock generation and data/control synchronization
   --*****************************************************************   
   u_phy_read : phy_read
      generic map (
         tcq              => TCQ,
         nck_per_clk      => nCK_PER_CLK,
         clk_period       => CLK_PERIOD,
         refclk_freq      => REFCLK_FREQ,
         dqs_width        => DQS_WIDTH,
         dq_width         => DQ_WIDTH,
         dram_width       => DRAM_WIDTH,
         iodelay_grp      => IODELAY_GRP,
         ndqs_col0        => nDQS_COL0,
         ndqs_col1        => nDQS_COL1,
         ndqs_col2        => nDQS_COL2,
         ndqs_col3        => nDQS_COL3,
         dqs_loc_col0     => DQS_LOC_COL0,
         dqs_loc_col1     => DQS_LOC_COL1,
         dqs_loc_col2     => DQS_LOC_COL2,
         dqs_loc_col3     => DQS_LOC_COL3
      )
      port map (
         clk_mem               => clk_mem,
         clk                   => clk,
         clk_rd_base           => clk_rd_base,
         rst                   => rst,
         dlyrst_cpt            => dlyrst_cpt,
         dlyce_cpt             => dlyce_cpt,
         dlyinc_cpt            => dlyinc_cpt,
         dlyrst_rsync          => dlyrst_rsync,
         dlyce_rsync           => dlyce_rsync,
         dlyinc_rsync          => dlyinc_rsync,
         clk_cpt               => clk_cpt,
         clk_rsync             => clk_rsync,
         rst_rsync             => rst_rsync,
         rdpath_rdy            => rdpath_rdy,
         mc_data_sel           => phy_init_data_sel,
         rd_active_dly         => rd_active_dly,
         rd_data_rise0         => rd_data_rise0,
         rd_data_fall0         => rd_data_fall0,
         rd_data_rise1         => rd_data_rise1,
         rd_data_fall1         => rd_data_fall1,
         rd_dqs_rise0          => rd_dqs_rise0,
         rd_dqs_fall0          => rd_dqs_fall0,
         rd_dqs_rise1          => rd_dqs_rise1,
         rd_dqs_fall1          => rd_dqs_fall1,
         dfi_rddata_en         => dfi_rddata_en,
         phy_rddata_en         => phy_rddata_en,
         dfi_rddata_valid      => dfi_rddata_valid_38,
         dfi_rddata_valid_phy  => dfi_rddata_valid_phy,
         dfi_rddata            => dfi_rddata_37,
         dfi_rd_dqs            => dfi_rd_dqs,
         dbg_cpt_tap_cnt       => dbg_cpt_tap_cnt_2,
         dbg_rsync_tap_cnt     => dbg_rsync_tap_cnt_20,
         dbg_phy_read          => dbg_phy_read_12
      );
   
   --***************************************************************************
   -- Read-leveling calibration logic
   --***************************************************************************    

   u_phy_rdlvl : phy_rdlvl
      generic map (
         TCQ             => TCQ,
         nCK_PER_CLK     => nCK_PER_CLK,
         CLK_PERIOD      => CLK_PERIOD,
         REFCLK_FREQ     => integer(REFCLK_FREQ),
         DQ_WIDTH        => DQ_WIDTH,
         DQS_CNT_WIDTH   => DQS_CNT_WIDTH,
         DQS_WIDTH       => DQS_WIDTH,
         DRAM_WIDTH      => DRAM_WIDTH,
         DRAM_TYPE       => DRAM_TYPE,
         nCL             => nCL,
         PD_TAP_REQ      => PD_TAP_REQ,
         SIM_CAL_OPTION  => SIM_CAL_OPTION_W,
         REG_CTRL        => REG_CTRL,
         DEBUG_PORT      => DEBUG_PORT
      )
      port map (
         clk                      => clk,
         rst                      => rst,
         rdlvl_start              => rdlvl_start,
         rdlvl_clkdiv_start       => rdlvl_clkdiv_start,
         rdlvl_rd_active          => dfi_rddata_valid_phy,
         rdlvl_done               => rdlvl_done,
         rdlvl_clkdiv_done        => rdlvl_clkdiv_done,
         rdlvl_err                => rdlvl_err,
         rdlvl_prech_req          => rdlvl_prech_req,
         prech_done               => prech_done,
         rd_data_rise0            => dfi_rddata_37(DQ_WIDTH - 1 downto 0),
         rd_data_fall0            => dfi_rddata_37(2 * DQ_WIDTH - 1 downto DQ_WIDTH),
         rd_data_rise1            => dfi_rddata_37(3 * DQ_WIDTH - 1 downto 2 * DQ_WIDTH),
         rd_data_fall1            => dfi_rddata_37(4 * DQ_WIDTH - 1 downto 3 * DQ_WIDTH),
         dlyce_cpt                => dlyce_rdlvl_cpt,
         dlyinc_cpt               => dlyinc_rdlvl_cpt,
         dlyce_rsync              => dlyce_rdlvl_rsync,
         dlyinc_rsync             => dlyinc_rdlvl_rsync,
         dlyval_dq                => dlyval_rdlvl_dq,
         dlyval_dqs               => dlyval_rdlvl_dqs,
         rd_bitslip_cnt           => rd_bitslip_cnt,
         rd_clkdly_cnt            => rd_clkdly_cnt,
         rd_active_dly            => rd_active_dly,
         rdlvl_pat_resume         => rdlvl_pat_resume_w,
         rdlvl_pat_err            => rdlvl_pat_err,
         rdlvl_pat_err_cnt        => rdlvl_pat_err_cnt,
         rd_clkdiv_inv            => rd_clkdiv_inv,
         dbg_cpt_first_edge_cnt   => dbg_cpt_first_edge_cnt_0,
         dbg_cpt_second_edge_cnt  => dbg_cpt_second_edge_cnt_1,
         dbg_rd_bitslip_cnt       => dbg_rd_bitslip_cnt_14,
         dbg_rd_clkdiv_inv        => open, -- connect in future release
         dbg_rd_clkdly_cnt        => dbg_rd_clkdly_cnt_15,
         dbg_rd_active_dly        => dbg_rd_active_dly_13,
         dbg_idel_up_all          => dbg_idel_up_all,
         dbg_idel_down_all        => dbg_idel_down_all,
         dbg_idel_up_cpt          => dbg_idel_up_cpt,
         dbg_idel_down_cpt        => dbg_idel_down_cpt,
         dbg_idel_up_rsync        => dbg_idel_up_rsync,
         dbg_idel_down_rsync      => dbg_idel_down_rsync,
         dbg_sel_idel_cpt         => dbg_sel_idel_cpt,
         dbg_sel_all_idel_cpt     => dbg_sel_all_idel_cpt,
         dbg_sel_idel_rsync       => dbg_sel_idel_rsync,
         dbg_sel_all_idel_rsync   => dbg_sel_all_idel_rsync,
         dbg_phy_rdlvl            => dbg_phy_rdlvl_11
      );
   
   --***************************************************************************
   -- Phase Detector: Periodic read-path delay compensation
   --***************************************************************************
   
   gen_enable_pd : if (USE_PHASE_DETECT = "ON") generate
            
      u_phy_pd_top : phy_pd_top
         generic map (
            TCQ                    => TCQ,
            DQS_CNT_WIDTH          => DQS_CNT_WIDTH,
            DQS_WIDTH              => DQS_WIDTH,
            PD_LHC_WIDTH           => PD_LHC_WIDTH,
            PD_CALIB_MODE          => PD_CALIB_MODE,
            PD_MSB_SEL             => PD_MSB_SEL,
            PD_DQS0_ONLY           => PD_DQS0_ONLY,
            SIM_CAL_OPTION         => SIM_CAL_OPTION_W,
            DEBUG_PORT             => DEBUG_PORT   
         )
         port map (
            clk                     => clk,
            rst                     => rst,
            pd_cal_start            => pd_cal_start,
            pd_cal_done             => pd_cal_done,
            dfi_init_complete       => phy_init_data_sel,
            pd_PSEN                 => pd_PSEN,
            pd_PSINCDEC             => pd_PSINCDEC,
            read_valid              => dfi_rddata_valid_phy,
            dlyval_rdlvl_dqs        => dlyval_rdlvl_dqs,
            dlyce_pd_cpt            => dlyce_pd_cpt,
            dlyinc_pd_cpt           => dlyinc_pd_cpt,
            dlyval_pd_dqs           => dlyval_pd_dqs,
            rd_dqs_rise0            => dfi_rd_dqs(DQS_WIDTH - 1 downto 0),
            rd_dqs_fall0            => dfi_rd_dqs(2*DQS_WIDTH - 1 downto DQS_WIDTH),
            rd_dqs_rise1            => dfi_rd_dqs(3*DQS_WIDTH - 1 downto 2*DQS_WIDTH),
            rd_dqs_fall1            => dfi_rd_dqs(4*DQS_WIDTH - 1 downto 3*DQS_WIDTH),
            pd_prech_req            => pd_prech_req,
            prech_done              => prech_done,
            dbg_pd_off              => dbg_pd_off,
            dbg_pd_maintain_off     => dbg_pd_maintain_off,
            dbg_pd_maintain_0_only  => dbg_pd_maintain_0_only,
            dbg_pd_inc_cpt          => dbg_pd_inc_cpt,
            dbg_pd_dec_cpt          => dbg_pd_dec_cpt,
            dbg_pd_inc_dqs          => dbg_pd_inc_dqs,
            dbg_pd_dec_dqs          => dbg_pd_dec_dqs,
            dbg_pd_disab_hyst       => dbg_pd_disab_hyst,
            dbg_pd_disab_hyst_0     => dbg_pd_disab_hyst_0,
            dbg_pd_msb_sel          => dbg_pd_msb_sel,
            dbg_pd_byte_sel         => dbg_pd_byte_sel,
            dbg_inc_rd_fps          => dbg_inc_rd_fps,
            dbg_dec_rd_fps          => dbg_dec_rd_fps,
            dbg_phy_pd              => dbg_phy_pd_10
         );
   end generate;
   
   gen_disable_pd_tie_off : if (not(USE_PHASE_DETECT = "ON")) generate
      -- Otherwise if phase detector is not used, tie off all PD-related
      -- control signals
      pd_cal_done         <= '0';
      pd_prech_req        <= '0';
      dlyce_pd_cpt        <= (others => '0');
      dlyinc_pd_cpt       <= (others => '0');
      dlyval_pd_dqs       <= (others => '0');
   end generate;
         
end architecture arch;


