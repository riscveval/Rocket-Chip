--*****************************************************************************
-- (c) Copyright 2008-2009 Xilinx, Inc. All rights reserved.
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
-- /___/  \  /    Vendor                : Xilinx
-- \   \   \/     Version               : 3.92
--  \   \         Application           : MIG
--  /   /         Filename              : mem_intfc.v
-- /___/   /\     Date Last Modified    : $date$
-- \   \  /  \    Date Created          : Aug 03 2009
--  \___\/\___\
--
--Device            : Virtex-6
--Design Name       : DDR3 SDRAM
--Purpose           : Top level memory interface block. Instantiates a clock 
--                    and reset generator, the memory controller, the phy and 
--                    the user interface blocks.
--Reference         :
--Revision History  :
--*****************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity mem_intfc is
  generic (
    TCQ                    : integer := 100;
    PAYLOAD_WIDTH          : integer := 64;
    ADDR_CMD_MODE          : string := "1T";
    AL                     : string := "0";		-- Additive Latency option
    BANK_WIDTH             : integer := 3;		-- # of bank bits
    BM_CNT_WIDTH           : integer := 2;		-- Bank machine counter width
    BURST_MODE             : string := "8";		-- Burst length
    BURST_TYPE             : string := "SEQ";		-- Burst type
    CK_WIDTH               : integer := 1;		-- # of CK/CK# outputs to memory
    CL                     : integer := 5;		-- pS
    COL_WIDTH              : integer := 12;		-- column address width
    CMD_PIPE_PLUS1         : string := "ON";
    CS_WIDTH               : integer := 1;		-- # of unique CS outputs
    CKE_WIDTH              : integer := 1;		-- # of CKE outputs 
    CWL                    : integer := 5;
    DATA_WIDTH             : integer := 64;
    DATA_BUF_ADDR_WIDTH    : integer := 8;
    DATA_BUF_OFFSET_WIDTH  : integer := 1;
    --DELAY_WR_DATA_CNTRL    : integer := 0; --This parameter is made as MC's constant
    DM_WIDTH               : integer := 8;		-- # of DM (data mask)
    DQ_CNT_WIDTH           : integer := 6;		-- = ceil(log2(DQ_WIDTH))
    DQ_WIDTH               : integer := 64;		-- # of DQ (data)
    DQS_CNT_WIDTH          : integer := 3;		-- = ceil(log2(DQS_WIDTH))
    DQS_WIDTH              : integer := 8;		-- # of DQS (strobe)
    DRAM_TYPE              : string := "DDR3";
    DRAM_WIDTH             : integer := 8;		-- # of DQ per DQS
    ECC                    : string := "OFF";
    ECC_WIDTH              : integer := 8;
    MC_ERR_ADDR_WIDTH      : integer := 31;
    nAL                    : integer := 0;		-- Additive latency (in clk cyc)
    nBANK_MACHS            : integer := 4;
    nCK_PER_CLK            : integer := 2;		-- # of memory CKs per fabric CLK
    nCS_PER_RANK           : integer := 1;		-- # of unique CS outputs per rank for phy
    ORDERING               : string := "NORM";
    PHASE_DETECT           : string := "OFF";		--to phy_top
    IBUF_LPWR_MODE         : string := "OFF";		-- to phy_top
    IODELAY_HP_MODE        : string := "ON";		-- to phy_top
    IODELAY_GRP            : string := "IODELAY_MIG";	--to phy_top
    OUTPUT_DRV             : string := "HIGH";		--to phy_top
    REG_CTRL               : string := "OFF";		--to phy_top
    RTT_NOM                : string := "60";		--to phy_top
    RTT_WR                 : string := "120";		--to phy_top
    STARVE_LIMIT           : integer := 2;
    tCK                    : integer := 2500;		-- pS
    tFAW                   : integer := 40000;		-- pS
    tPRDI                  : integer := 1000000;	-- pS
    tRAS                   : integer := 37500;		-- pS
    tRCD                   : integer := 12500;		-- pS
    tREFI                  : integer := 7800000;	-- pS
    tRFC                   : integer := 110000;		-- pS
    tRP                    : integer := 12500;		-- pS
    tRRD                   : integer := 10000;		-- pS
    tRTP                   : integer := 7500;		-- pS
    tWTR                   : integer := 7500;		-- pS
    tZQI                   : integer := 128000000;	-- nS
    tZQCS                  : integer := 64;		-- CKs
    WRLVL                  : string := "OFF";		--to phy_top
    DEBUG_PORT             : string := "OFF";		--to phy_top
    CAL_WIDTH              : string := "HALF";		--to phy_top
    RANK_WIDTH             : integer := 1;
    RANKS                  : integer := 4;
    ROW_WIDTH              : integer := 16;		-- DRAM address bus width
    SLOT_0_CONFIG          : std_logic_vector(7 downto 0) := "00000001";
    SLOT_1_CONFIG          : std_logic_vector(7 downto 0) := "00000000";
    SIM_BYPASS_INIT_CAL    : string := "OFF";
    REFCLK_FREQ            : real := 300.0;
    nDQS_COL0              : integer := 0;	-- The generic nDQS_COL0 has been removed as it requires the value of another generic
    nDQS_COL1              : integer := 0;
    nDQS_COL2              : integer := 0;
    nDQS_COL3              : integer := 0;
    DQS_LOC_COL0           : std_logic_vector (143 downto 0) := X"11100F0E0D0C0B0A09080706050403020100";
    DQS_LOC_COL1           : std_logic_vector (143 downto 0) := X"000000000000000000000000000000000000";
    DQS_LOC_COL2           : std_logic_vector (143 downto 0) := X"000000000000000000000000000000000000";
    DQS_LOC_COL3           : std_logic_vector (143 downto 0) := X"000000000000000000000000000000000000";
    USE_DM_PORT		   : integer := 1
  );
  port ( 
    -- Beginning of automatic outputs (from unused autoinst outputs)
    accept                      : out std_logic;						-- From mc0 of mc.v
    accept_ns                   : out std_logic;						-- From mc0 of mc.v
    bank_mach_next              : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
    dbg_cpt_first_edge_cnt      : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
    dbg_cpt_second_edge_cnt     : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
    dbg_cpt_tap_cnt             : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
    dbg_dq_tap_cnt              : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
    dbg_dqs_tap_cnt             : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
    dbg_rd_active_dly           : out std_logic_vector(4 downto 0);
    dbg_rd_bitslip_cnt          : out std_logic_vector(3 * DQS_WIDTH - 1 downto 0);
    dbg_rd_clkdly_cnt           : out std_logic_vector(2 * DQS_WIDTH - 1 downto 0);
    dbg_rd_data_edge_detect     : out std_logic_vector(DQS_WIDTH - 1 downto 0);
    dbg_rddata                  : out std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
    dbg_rdlvl_done              : out std_logic_vector(1 downto 0);
    dbg_rdlvl_err               : out std_logic_vector(1 downto 0);
    dbg_rdlvl_start             : out std_logic_vector(1 downto 0);
    dbg_tap_cnt_during_wrlvl    : out std_logic_vector(4 downto 0);
    dbg_wl_dqs_inverted         : out std_logic_vector(DQS_WIDTH - 1 downto 0);
    dbg_wl_edge_detect_valid    : out std_logic;						-- From mc0 of mc.v
    dbg_wl_odelay_dqs_tap_cnt   : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
    dbg_wl_odelay_dq_tap_cnt    : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
    dbg_wr_calib_clk_delay      : out std_logic_vector(2 * DQS_WIDTH - 1 downto 0);
    dbg_wrlvl_done              : out std_logic;						-- From mc0 of mc.v
    dbg_wrlvl_err               : out std_logic;						-- From mc0 of mc.v
    dbg_wrlvl_start             : out std_logic;						-- From mc0 of mc.v
    ddr_we_n                    : out std_logic;						-- From phy_top0 of phy_top.v
    ddr_parity                  : out std_logic;
    ddr_reset_n                 : out std_logic;						-- From phy_top0 of phy_top.v
    ddr_ras_n                   : out std_logic;						-- From phy_top0 of phy_top.v
    ddr_odt                     : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);	-- From phy_top0 of phy_top.v
    ddr_dm                      : out std_logic_vector(DM_WIDTH - 1 downto 0);			-- From phy_top0 of phy_top.v
    ddr_cs_n                    : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);	-- From phy_top0 of phy_top.v
    ddr_cke                     : out std_logic_vector(CKE_WIDTH - 1 downto 0);			-- From phy_top0 of phy_top.v
    ddr_ck                      : out std_logic_vector(CK_WIDTH - 1 downto 0);			-- From phy_top0 of phy_top.v
    ddr_ck_n                    : out std_logic_vector(CK_WIDTH - 1 downto 0);			-- From phy_top0 of phy_top.v
    ddr_cas_n                   : out std_logic;						-- From phy_top0 of phy_top.v
    ddr_ba                      : out std_logic_vector(BANK_WIDTH - 1 downto 0);		-- From phy_top0 of phy_top.v
    ddr_addr                    : out std_logic_vector(ROW_WIDTH - 1 downto 0);			-- From phy_top0 of phy_top.v
    dfi_init_complete           : out std_logic;
    ecc_single                  : out std_logic_vector(3 downto 0);
    ecc_multiple                : out std_logic_vector(3 downto 0);
    ecc_err_addr                : out std_logic_vector(MC_ERR_ADDR_WIDTH - 1 downto 0);
    pd_PSEN                     : out std_logic;						-- From phy_top0 of phy_top.v		
    pd_PSINCDEC                 : out std_logic;						-- From phy_top0 of phy_top.v
    dbg_phy_pd                  : out std_logic_vector(255 downto 0);
    dbg_phy_read                : out std_logic_vector(255 downto 0);
    dbg_phy_rdlvl               : out std_logic_vector(255 downto 0);
    dbg_phy_top                 : out std_logic_vector(255 downto 0);
    rd_data                     : out std_logic_vector((4 * PAYLOAD_WIDTH) - 1 downto 0);	
    rd_data_offset              : out std_logic_vector(DATA_BUF_OFFSET_WIDTH - 1 downto 0);	-- From mc0 of mc.v
    rd_data_en                  : out std_logic;						-- From mc0 of mc.v
    rd_data_addr                : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);	-- From mc0 of mc.v
    rd_data_end                 : out std_logic;						-- From mc0 of mc.v
    dbg_rsync_tap_cnt           : out std_logic_vector(19 downto 0);
    wr_data_offset              : out std_logic_vector(DATA_BUF_OFFSET_WIDTH - 1 downto 0);	-- From mc0 of mc.v
    wr_data_en                  : out std_logic;						-- From mc0 of mc.v
    wr_data_addr                : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);	-- From mc0 of mc.v
    -- End of automatics
    
    -- AUTOINOUT
    -- Beginning of automatic inouts (from unused autoinst inouts)
    ddr_dq                      : inout std_logic_vector(DQ_WIDTH - 1 downto 0);		-- To/From phy_top0 of phy_top.v
    ddr_dqs                     : inout std_logic_vector(DQS_WIDTH - 1 downto 0);		-- To/From phy_top0 of phy_top.v
    ddr_dqs_n                   : inout std_logic_vector(DQS_WIDTH - 1 downto 0);		-- To/From phy_top0 of phy_top.v

    -- Beginning of automatic inputs (from unused autoinst inputs)
    bank                        : in std_logic_vector(BANK_WIDTH - 1 downto 0);			-- To mc0 of mc.v
    col                         : in std_logic_vector(COL_WIDTH - 1 downto 0);			-- To mc0 of mc.v
    cmd                         : in std_logic_vector(2 downto 0);				-- To mc0 of mc.v
    clk_rd_base                 : in std_logic;							-- To phy_top0 of phy_top.v
    clk_mem                     : in std_logic;							-- To phy_top0 of phy_top.v
    clk                         : in std_logic;							-- To mc0 of mc.v
    correct_en                  : in std_logic;
    data_buf_addr               : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);	-- To mc0 of mc.v

    dbg_dec_rd_fps              : in std_logic;  
    dbg_idel_down_all           : in std_logic;  
    dbg_idel_down_cpt           : in std_logic;  
    dbg_idel_down_rsync         : in std_logic;  
    dbg_idel_up_all             : in std_logic;  
    dbg_idel_up_cpt             : in std_logic;  
    dbg_idel_up_rsync           : in std_logic;  
    dbg_inc_rd_fps              : in std_logic;  
    dbg_pd_byte_sel             : in std_logic_vector(DQS_CNT_WIDTH-1 downto 0);  
    dbg_pd_dec_cpt              : in std_logic;  
    dbg_pd_dec_dqs              : in std_logic;  
    dbg_pd_inc_cpt              : in std_logic;  
    dbg_pd_inc_dqs              : in std_logic;  
    dbg_pd_off                  : in std_logic;  
    dbg_pd_maintain_off         : in std_logic;  
    dbg_pd_maintain_0_only      : in std_logic;  
    dbg_pd_disab_hyst           : in std_logic;  
    dbg_pd_disab_hyst_0         : in std_logic;  
    dbg_pd_msb_sel              : in std_logic_vector(3 downto 0);  
    dbg_sel_all_idel_cpt        : in std_logic;  
    dbg_sel_all_idel_rsync      : in std_logic;  
    dbg_sel_idel_cpt            : in std_logic_vector(DQS_CNT_WIDTH-1 downto 0);  
    dbg_sel_idel_rsync          : in std_logic_vector(DQS_CNT_WIDTH-1 downto 0);  
    dbg_wr_dq_tap_set           : in std_logic_vector(5 * DQS_WIDTH - 1 downto 0);  
    dbg_wr_dqs_tap_set          : in std_logic_vector(5 * DQS_WIDTH - 1 downto 0);  
    dbg_wr_tap_set_en           : in std_logic;  
    hi_priority                 : in std_logic;							-- To mc0 of mc.v
    pd_PSDONE                   : in std_logic;							-- To phy_top0 of phy_top.v
    raw_not_ecc                 : in std_logic_vector(3 downto 0);
    size                        : in std_logic;							-- To mc0 of mc.v
    rst                         : in std_logic;							-- To mc0 of mc.v
    row                         : in std_logic_vector(ROW_WIDTH - 1 downto 0);			-- To mc0 of mc.v
    rank                        : in std_logic_vector(RANK_WIDTH - 1 downto 0);			-- To mc0 of mc.v
    slot_0_present              : in std_logic_vector(7 downto 0);				-- To mc0 of mc.v
    slot_1_present              : in std_logic_vector(7 downto 0);				-- To mc0 of mc.v
    use_addr                    : in std_logic;							-- To mc0 of mc.v
    wr_data                     : in std_logic_vector((4 * PAYLOAD_WIDTH) - 1 downto 0);	
    wr_data_mask                : in std_logic_vector((4 * (DATA_WIDTH / 8)) - 1 downto	0)
  );
end entity mem_intfc;

architecture arch of mem_intfc is

  function CALC_NSLOTS ( SLOT_1_CONFIG: std_logic_vector ) return integer is
  variable tmp : std_logic := '0';
  begin
     for i in SLOT_1_CONFIG'range loop
      tmp := tmp or SLOT_1_CONFIG(i);
     end loop;
     if ( tmp = '1' ) then
             return 2;
     else
             return 1;
     end if;
  end function;
  constant nSLOTS                    : integer := CALC_NSLOTS(SLOT_1_CONFIG);

  function CALC_SLOT_0_CONFIG_MC (nSLOTS : integer) return std_logic_vector is
  begin
     if (nSLOTS = 2) then	  
        return (X"05");
     else
	return (X"0F");
     end if;
  end function;

  function CALC_SLOT_1_CONFIG_MC (nSLOTS : integer) return std_logic_vector is
  begin
     if (nSLOTS = 2) then	  
        return (X"0A");
     else
	return (X"00");
     end if;
  end function;

  -- assigning CWL = CL -1 for DDR2. DDR2 customers will not know anything
  -- about CWL. There is also nCWL parameter. Need to clean it up.
  function CALC_CWL_T ( CWL, CL : integer ; DRAM_TYPE : string) return integer is
  begin
     if ( DRAM_TYPE = "DDR3" ) then
        return CWL;
     else
        return CL - 1;
     end if;
  end function;

  constant CWL_T                     : integer := CALC_CWL_T(CWL,CL,DRAM_TYPE);
  constant SLOT_0_CONFIG_MC	     : std_logic_vector(7 downto 0) := CALC_SLOT_0_CONFIG_MC(nSLOTS);
  constant SLOT_1_CONFIG_MC	     : std_logic_vector(7 downto 0) := CALC_SLOT_1_CONFIG_MC(nSLOTS);

  -- following calculations should be moved inside PHY
  -- odt bus should  be added to PHY.  
  constant CLK_PERIOD                : integer := tCK * nCK_PER_CLK;
  constant nCL                       : integer := CL;
  constant nCWL                      : integer := CWL_T;

  component phy_top is
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
  end component;
  
  component mc is
   generic (
      TCQ                        : integer := 100;
      ADDR_CMD_MODE              : string := "1T";
      BANK_WIDTH                 : integer := 3;
      BM_CNT_WIDTH               : integer := 2;
      BURST_MODE                 : string := "8";
      CL                         : integer := 5;
      COL_WIDTH                  : integer := 12;
      CMD_PIPE_PLUS1             : string := "ON";
      CS_WIDTH                   : integer := 4;
      CWL                        : integer := 5;
      DATA_WIDTH                 : integer := 64;
      DATA_BUF_ADDR_WIDTH        : integer := 8;
      DATA_BUF_OFFSET_WIDTH      : integer := 1;
      --DELAY_WR_DATA_CNTRL        : integer := 0;
      nREFRESH_BANK              : integer := 1;
      DRAM_TYPE                  : string := "DDR3";
      DQS_WIDTH                  : integer := 8;
      DQ_WIDTH                   : integer := 64;
      ECC                        : string := "OFF";
      ECC_WIDTH                  : integer := 8;
      MC_ERR_ADDR_WIDTH          : integer := 31;
      nBANK_MACHS                : integer := 4;
      nCK_PER_CLK                : integer := 2;
      nCS_PER_RANK               : integer := 1;
      ORDERING                   : string := "NORM";
      PAYLOAD_WIDTH              : integer := 64;
      RANK_WIDTH                 : integer := 2;
      RANKS                      : integer := 4;
      PHASE_DETECT               : string  := "OFF";
      ROW_WIDTH                  : integer := 16;
      RTT_NOM                    : string := "40";
      RTT_WR                     : string := "120";
      STARVE_LIMIT               : integer := 2;
      SLOT_0_CONFIG              : std_logic_vector(7 downto 0)  := X"05";
      SLOT_1_CONFIG              : std_logic_vector(7 downto 0)  := X"0A";
      nSLOTS                     : integer := 1;
      tCK                        : integer := 2500;		-- pS
      tFAW                       : integer := 40000;		-- pS
      tPRDI                      : integer := 1000000;		-- pS
      tRAS                       : integer := 37500;		-- pS
      tRCD                       : integer := 12500;		-- pS
      tREFI                      : integer := 7800000;		-- pS
      tRFC                       : integer := 110000;		-- pS
      tRP                        : integer := 12500;		-- pS
      tRRD                       : integer := 10000;		-- pS
      tRTP                       : integer := 7500;		-- pS
      tWTR                       : integer := 7500;		-- pS
      tZQI                       : integer := 128000000;		-- nS
      tZQCS                      : integer := 64		-- CKs
   );
   port (
      wr_data_en                 : out std_logic;		-- From col_mach0 of col_mach.v
      rd_data_end                : out std_logic;
      rd_data_en                 : out std_logic;
      io_config_strobe           : out std_logic;
      ecc_err_addr               : out std_logic_vector(MC_ERR_ADDR_WIDTH - 1 downto 0);
      dfi_wrdata_en              : out std_logic_vector(DQS_WIDTH - 1 downto 0);
      dfi_we_n1                  : out std_logic;
      dfi_we_n0                  : out std_logic;
      dfi_rddata_en              : out std_logic_vector(DQS_WIDTH - 1 downto 0);
      dfi_ras_n1                 : out std_logic;
      dfi_ras_n0                 : out std_logic;
      dfi_odt_wr1                : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_wr0                : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_nom1               : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_nom0               : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_cs_n1                  : out std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
      dfi_cs_n0                  : out std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
      dfi_cas_n1                 : out std_logic;
      dfi_cas_n0                 : out std_logic;
      dfi_bank1                  : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      dfi_bank0                  : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      dfi_address1               : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      dfi_address0               : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      bank_mach_next             : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      accept_ns                  : out std_logic;
      accept                     : out std_logic;
      dfi_dram_clk_disable       : out std_logic;		--= 1'b0;
      dfi_reset_n                : out std_logic;		-- = 1'b1;
      io_config                  : out std_logic_vector(RANK_WIDTH downto 0);
      rd_data_addr               : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      rd_data_offset             : out std_logic_vector(DATA_BUF_OFFSET_WIDTH - 1 downto 0);
      wr_data_addr               : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      wr_data_offset             : out std_logic_vector(DATA_BUF_OFFSET_WIDTH - 1 downto 0);
      dfi_wrdata                 : out std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
      dfi_wrdata_mask            : out std_logic_vector((4 * DQ_WIDTH / 8) - 1 downto 0);
      rd_data                    : out std_logic_vector(4 * PAYLOAD_WIDTH - 1 downto 0);
      ecc_single                 : out std_logic_vector(3 downto 0);
      ecc_multiple               : out std_logic_vector(3 downto 0);
      use_addr                   : in std_logic;
      slot_1_present             : in std_logic_vector(7 downto 0);
      slot_0_present             : in std_logic_vector(7 downto 0);
      size                       : in std_logic;
      rst                        : in std_logic;
      row                        : in std_logic_vector(ROW_WIDTH - 1 downto 0);
      raw_not_ecc                : in std_logic_vector(3 downto 0);
      rank                       : in std_logic_vector(RANK_WIDTH - 1 downto 0);
      hi_priority                : in std_logic;
      dfi_rddata_valid           : in std_logic;
      dfi_init_complete          : in std_logic;
      data_buf_addr              : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      correct_en                 : in std_logic;
      col                        : in std_logic_vector(COL_WIDTH - 1 downto 0);
      cmd                        : in std_logic_vector(2 downto 0);
      clk                        : in std_logic;
      bank                       : in std_logic_vector(BANK_WIDTH - 1 downto 0);
      app_zq_req                 : in std_logic;
      app_ref_req                : in std_logic;
      app_periodic_rd_req        : in std_logic;
      dfi_rddata                 : in std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
      wr_data                    : in std_logic_vector(4 * PAYLOAD_WIDTH - 1 downto 0);
      wr_data_mask               : in std_logic_vector(4 * DATA_WIDTH / 8 - 1 downto 0)
   );
  end component;

  -- Beginning of automatic wires (for undeclared instantiated-module outputs)
  signal dfi_address0                : std_logic_vector(ROW_WIDTH - 1 downto 0);		-- From mc0 of mc.v
  signal dfi_address1                : std_logic_vector(ROW_WIDTH - 1 downto 0);		-- From mc0 of mc.v
  signal dfi_bank0                   : std_logic_vector(BANK_WIDTH - 1 downto 0);		-- From mc0 of mc.v
  signal dfi_bank1                   : std_logic_vector(BANK_WIDTH - 1 downto 0);		-- From mc0 of mc.v
  signal dfi_cas_n0                  : std_logic;						-- From mc0 of mc.v
  signal dfi_cas_n1                  : std_logic;						-- From mc0 of mc.v
  signal dfi_cs_n0                   : std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);-- From mc0 of mc.v
  signal dfi_cs_n1                   : std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);-- From mc0 of mc.v
  signal dfi_odt_nom0                : std_logic_vector(nSLOTS * nCS_PER_RANK - 1 downto 0);
  signal dfi_odt_nom1                : std_logic_vector(nSLOTS * nCS_PER_RANK - 1 downto 0);
  signal dfi_odt0_tmp                : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
  signal dfi_odt1_tmp                : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
  signal dfi_odt_wr0                 : std_logic_vector(nSLOTS * nCS_PER_RANK - 1 downto 0);
  signal dfi_odt_wr1                 : std_logic_vector(nSLOTS * nCS_PER_RANK - 1 downto 0);
  signal dfi_odt_nom0_r              : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_nom0_r1             : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_nom0_r2             : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_nom0_r3             : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_nom1_r              : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_nom1_r1             : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_nom1_r2             : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_nom1_r3             : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_wr0_r               : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_wr0_r1              : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_wr0_r2              : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_wr0_r3              : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_wr1_r               : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_wr1_r1              : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_wr1_r2              : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_wr1_r3              : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_nom0_w              : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_nom1_w              : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_wr0_w               : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt_wr1_w               : std_logic_vector(nSLOTS*nCS_PER_RANK-1 downto 0);
  signal dfi_odt0                    : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
  signal dfi_odt1                    : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
  signal dfi_dram_clk_disable        : std_logic;						-- From mc0 of mc.v
  signal dfi_ras_n0                  : std_logic;						-- From mc0 of mc.v 
  signal dfi_ras_n1                  : std_logic;						-- From mc0 of mc.v
  signal dfi_rddata_valid            : std_logic;						-- From mc0 of mc.v
  signal dfi_reset_n                 : std_logic;						-- From mc0 of mc.v
  signal dfi_we_n0                   : std_logic;						-- From mc0 of mc.v
  signal dfi_we_n1                   : std_logic;						-- From mc0 of mc.v
  signal dfi_wrdata_en               : std_logic_vector(DQS_WIDTH - 1 downto 0);
  signal io_config                   : std_logic_vector(RANK_WIDTH downto 0);			-- From mc0 of mc.v
  signal io_config_strobe            : std_logic;						-- From mc0 of mc.v
  signal dfi_rddata_en               : std_logic_vector(DQS_WIDTH - 1 downto 0);
  signal dfi_rddata                  : std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
  signal dfi_wrdata                  : std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
  signal dfi_wrdata_mask             : std_logic_vector(4 * DQ_WIDTH / 8 - 1 downto 0);
  signal slot_0_present_mc           : std_logic_vector(7 downto 0);
  signal slot_1_present_mc           : std_logic_vector(7 downto 0);
  -- End of automatics

  -- X-HDL generated signals
  signal wire39 : std_logic_vector(3 downto 0);
  signal wire41 : std_logic_vector(3 downto 0);

  -- Intermediate signals
  signal xhdl0 : std_logic;

begin

  -- Assign the outputs with corresponding intermediate signals
  dfi_init_complete <= xhdl0;	

  -- ODT assignment from mc to phy_top based on slot config and slot present
  -- Assuming CS_WIDTH equals number of ranks configured
  -- For single slot systems slot_1_present input will be ignored
  -- Assuming component interfaces to be single slot system
  dfi_odt0 <= dfi_odt0_tmp;
  dfi_odt1 <= dfi_odt1_tmp;

   -- staging the odt from phy for delaying it based on CWL.
   process (clk)
   begin
    if ( clk'event and clk = '1' ) then
     dfi_odt_nom0_r  <= dfi_odt_nom0    after (TCQ) * 1 ps;
     dfi_odt_nom0_r1 <= dfi_odt_nom0_r  after (TCQ) * 1 ps;
     dfi_odt_nom0_r2 <= dfi_odt_nom0_r1 after (TCQ) * 1 ps;
     dfi_odt_nom0_r3 <= dfi_odt_nom0_r2 after (TCQ) * 1 ps;
     dfi_odt_nom1_r  <= dfi_odt_nom1    after (TCQ) * 1 ps;
     dfi_odt_nom1_r1 <= dfi_odt_nom1_r  after (TCQ) * 1 ps;
     dfi_odt_nom1_r2 <= dfi_odt_nom1_r1 after (TCQ) * 1 ps;
     dfi_odt_nom1_r3 <= dfi_odt_nom1_r2 after (TCQ) * 1 ps;

     dfi_odt_wr0_r   <= dfi_odt_wr0    after (TCQ) * 1 ps;
     dfi_odt_wr0_r1  <= dfi_odt_wr0_r  after (TCQ) * 1 ps;
     dfi_odt_wr0_r2  <= dfi_odt_wr0_r1 after (TCQ) * 1 ps;
     dfi_odt_wr0_r3  <= dfi_odt_wr0_r2 after (TCQ) * 1 ps;
     dfi_odt_wr1_r   <= dfi_odt_wr1    after (TCQ) * 1 ps;
     dfi_odt_wr1_r1  <= dfi_odt_wr1_r  after (TCQ) * 1 ps;
     dfi_odt_wr1_r2  <= dfi_odt_wr1_r1 after (TCQ) * 1 ps;
     dfi_odt_wr1_r3  <= dfi_odt_wr1_r2 after (TCQ) * 1 ps;
    end if;
   end process;

   CWL_7 : if(CWL >= 7) generate
       process (clk)
       begin 
        if ( clk'event and clk = '1' ) then
         dfi_odt_nom0_w  <= dfi_odt_nom0;
         dfi_odt_nom1_w  <= dfi_odt_nom1;
	     dfi_odt_wr0_w   <= dfi_odt_wr0;
	     dfi_odt_wr1_w   <= dfi_odt_wr1;
        end if;
       end process;
    end generate;

    CWL_n_7 : if ( not (CWL >= 7) ) generate
             dfi_odt_nom0_w  <= dfi_odt_nom0;
             dfi_odt_nom1_w  <= dfi_odt_nom1;
	     dfi_odt_wr0_w   <= dfi_odt_wr0;
	     dfi_odt_wr1_w   <= dfi_odt_wr1;
   end generate;


  
  gen_single_slot_odt : if (nSLOTS = 1) generate
    wire39 <= slot_0_present(0) & slot_0_present(1) & slot_0_present(2) & slot_0_present(3);
    process (slot_0_present(0), slot_0_present(2), slot_0_present(1), slot_0_present(3), dfi_odt_nom0_w, dfi_odt_nom1_w, dfi_odt_wr0_w, dfi_odt_wr1_w,slot_1_present)
    begin
       slot_0_present_mc <= slot_0_present;
       slot_1_present_mc <= slot_1_present;

       dfi_odt0_tmp <= (others => '0');
       dfi_odt1_tmp <= (others => '0');
       dfi_odt0_tmp(nCS_PER_RANK-1 downto 0) <= dfi_odt_wr0_w(nCS_PER_RANK-1 downto 0) or
                                                dfi_odt_nom0_w(nCS_PER_RANK-1 downto 0);
       dfi_odt1_tmp(nCS_PER_RANK-1 downto 0) <= dfi_odt_wr1_w(nCS_PER_RANK-1 downto 0) or
                                                dfi_odt_nom1_w(nCS_PER_RANK-1 downto 0);
    end process;    
  end generate;

  gen_dual_slot_odt : if (nSLOTS = 2) generate
    -- ODT assignment fixed for nCS_PER_RANK =1. Need to change for others 
    wire41 <= slot_0_present(0) & slot_0_present(1) & slot_1_present(0) & slot_1_present(1);
    process (slot_0_present(0), slot_0_present(1), slot_1_present(0), 
             slot_1_present(1), dfi_odt_nom0_w, dfi_odt_nom1_w,wire41, 
             dfi_odt_wr0_w, dfi_odt_wr1_w)
    begin
      case wire41 is
        -- Two slot configuration, one slot present, single rank
        when "1000" =>
          dfi_odt0_tmp <= (others => '0');
          dfi_odt1_tmp <= (others => '0');
          dfi_odt0_tmp(0) <= dfi_odt_nom0_w(0);
          dfi_odt1_tmp(0) <= dfi_odt_nom1_w(0);
          slot_0_present_mc <= "00000001";
          slot_1_present_mc <= "00000000";
        when "0010" =>
          dfi_odt0_tmp <= (others => '0');
          dfi_odt1_tmp <= (others => '0');
          dfi_odt0_tmp(0) <= dfi_odt_nom0_w(1);
          dfi_odt1_tmp(0) <= dfi_odt_nom1_w(1);
          slot_0_present_mc <= "00000000";
          slot_1_present_mc <= "00000010";
        -- Two slot configuration, one slot present, dual rank
        when "1100" =>
          dfi_odt0_tmp <= (others => '0');
          dfi_odt1_tmp <= (others => '0');
          dfi_odt0_tmp <= (dfi_odt_nom0_w(0) & dfi_odt_wr0_w(0));
          dfi_odt1_tmp <= (dfi_odt_nom1_w(0) & dfi_odt_wr1_w(0));
          slot_0_present_mc <= "00000101";
          slot_1_present_mc <= "00000000";
        when "0011" =>
          dfi_odt0_tmp <= (others => '0');
          dfi_odt1_tmp <= (others => '0');
          dfi_odt0_tmp <= (dfi_odt_nom0_w(1) & dfi_odt_wr0_w(1));
          dfi_odt1_tmp <= (dfi_odt_nom1_w(1) & dfi_odt_wr1_w(1));
          slot_0_present_mc <= "00000000";
          slot_0_present_mc <= "00001010";
        -- Two slot configuration, one rank per slot
        when "1010" =>
          dfi_odt0_tmp <= (others => '0');
          dfi_odt1_tmp <= (others => '0');
          dfi_odt0_tmp <= (dfi_odt_nom0_w(1) & dfi_odt_nom0_w(0));
          dfi_odt1_tmp <= (dfi_odt_nom1_w(1) & dfi_odt_nom1_w(0));
          slot_0_present_mc <= "00000001";
          slot_0_present_mc <= "00000010";
        -- Two Slots - One slot with dual rank and the other with single rank
        when "1011" =>
          dfi_odt0_tmp <= (others => '0');
          dfi_odt1_tmp <= (others => '0');
          dfi_odt0_tmp <= (dfi_odt_nom0_w(1) & dfi_odt_wr0_w(1) & dfi_odt_nom0_w(0));
          dfi_odt1_tmp <= (dfi_odt_nom1_w(1) & dfi_odt_wr1_w(1) & dfi_odt_nom1_w(0));
          slot_0_present_mc <= "00000001";
          slot_0_present_mc <= "00001010";
        when "1110" =>
          dfi_odt0_tmp <= (others => '0');
          dfi_odt1_tmp <= (others => '0');
          dfi_odt0_tmp <= (dfi_odt_nom0_w(1) & dfi_odt_nom0_w(0) & dfi_odt_wr0_w(0));
          dfi_odt1_tmp <= (dfi_odt_nom1_w(1) & dfi_odt_nom1_w(0) & dfi_odt_wr1_w(0));
          slot_0_present_mc <= "00000101";
          slot_0_present_mc <= "00000010";
        -- Two Slots - two ranks per slot
        when "1111" =>
          dfi_odt1_tmp <= (dfi_odt_nom0_w(1) & dfi_odt_wr0_w(1) & dfi_odt_nom0_w(0) & dfi_odt_wr0_w(0));
          dfi_odt1_tmp <= (dfi_odt_nom1_w(1) & dfi_odt_wr1_w(1) & dfi_odt_nom1_w(0) & dfi_odt_wr1_w(0));
          slot_0_present_mc <= "00000101";
          slot_0_present_mc <= "00001010";
        when others => 
          dfi_odt1_tmp <= (others => '0');
          dfi_odt0_tmp <= (others => '0');
      end case;
    end process;
    
  end generate;
  
  
  mc0 : mc
    generic map (
      -- AUTOINSTPARAM_disabled
      tcq                    => TCQ,
      payload_width          => PAYLOAD_WIDTH,
      mc_err_addr_width      => MC_ERR_ADDR_WIDTH,
      addr_cmd_mode          => ADDR_CMD_MODE,
      bank_width             => BANK_WIDTH,
      bm_cnt_width           => BM_CNT_WIDTH,
      burst_mode             => BURST_MODE,
      col_width              => COL_WIDTH,
      CMD_PIPE_PLUS1         => CMD_PIPE_PLUS1,
      cs_width               => CS_WIDTH,
      data_width             => DATA_WIDTH,
      data_buf_addr_width    => DATA_BUF_ADDR_WIDTH,
      data_buf_offset_width  => DATA_BUF_OFFSET_WIDTH,
      --delay_wr_data_cntrl    => DELAY_WR_DATA_CNTRL,
      dram_type              => DRAM_TYPE,
      dqs_width              => DQS_WIDTH,
      dq_width               => DQ_WIDTH,
      ecc                    => ECC,
      ecc_width              => ECC_WIDTH,
      nbank_machs            => nBANK_MACHS,
      nck_per_clk            => nCK_PER_CLK,
      nSLOTS                 => nSLOTS,
      cl                     => CL,
      ncs_per_rank           => nCS_PER_RANK,
      cwl                    => CWL_T,
      ordering               => ORDERING,
      rank_width             => RANK_WIDTH,
      ranks                  => RANKS,
      PHASE_DETECT           => PHASE_DETECT, --Added to control periodic reads
      row_width              => ROW_WIDTH,
      rtt_nom                => RTT_NOM,
      rtt_wr                 => RTT_WR,
      starve_limit           => STARVE_LIMIT,
      slot_0_config          => SLOT_0_CONFIG_MC,
      slot_1_config          => SLOT_1_CONFIG_MC,
      tck                    => tCK,
      tfaw                   => tFAW,
      tprdi                  => tPRDI,
      tras                   => tRAS,
      trcd                   => tRCD,
      trefi                  => tREFI,
      trfc                   => tRFC,
      trp                    => tRP,
      trrd                   => tRRD,
      trtp                   => tRTP,
      twtr                   => tWTR,
      tzqi                   => tZQI,
      tzqcs                  => tZQCS
    )
    port map (
      app_periodic_rd_req   => '0',
      app_ref_req           => '0',
      app_zq_req            => '0',
      dfi_rddata_en         => dfi_rddata_en(DQS_WIDTH - 1 downto 0),
      dfi_wrdata_en         => dfi_wrdata_en(DQS_WIDTH - 1 downto 0),
      dfi_odt_nom0          => dfi_odt_nom0,
      dfi_odt_wr0           => dfi_odt_wr0,
      dfi_odt_nom1          => dfi_odt_nom1,
      dfi_odt_wr1           => dfi_odt_wr1,
      ecc_single            => ecc_single,
      ecc_multiple          => ecc_multiple,
      ecc_err_addr          => ecc_err_addr,
      accept                => accept,
      accept_ns             => accept_ns,
      bank_mach_next        => bank_mach_next(BM_CNT_WIDTH - 1 downto 0),
      dfi_address0          => dfi_address0(ROW_WIDTH - 1 downto 0),
      dfi_address1          => dfi_address1(ROW_WIDTH - 1 downto 0),
      dfi_bank0             => dfi_bank0(BANK_WIDTH - 1 downto 0),
      dfi_bank1             => dfi_bank1(BANK_WIDTH - 1 downto 0),
      dfi_cas_n0            => dfi_cas_n0,
      dfi_cas_n1            => dfi_cas_n1,
      dfi_cs_n0             => dfi_cs_n0((CS_WIDTH * nCS_PER_RANK) - 1 downto 0),
      dfi_cs_n1             => dfi_cs_n1((CS_WIDTH * nCS_PER_RANK) - 1 downto 0),
      dfi_ras_n0            => dfi_ras_n0,
      dfi_ras_n1            => dfi_ras_n1,
      dfi_we_n0             => dfi_we_n0,
      dfi_we_n1             => dfi_we_n1,
      io_config             => io_config(RANK_WIDTH downto 0),
      io_config_strobe      => io_config_strobe,
      rd_data_addr          => rd_data_addr(DATA_BUF_ADDR_WIDTH - 1 downto 0),
      rd_data_en            => rd_data_en,
      rd_data_end           => rd_data_end,
      rd_data_offset        => rd_data_offset(DATA_BUF_OFFSET_WIDTH - 1 downto 0),
      wr_data_addr          => wr_data_addr(DATA_BUF_ADDR_WIDTH - 1 downto 0),
      wr_data_en            => wr_data_en,
      wr_data_offset        => wr_data_offset(DATA_BUF_OFFSET_WIDTH - 1 downto 0),
      dfi_dram_clk_disable  => dfi_dram_clk_disable,
      dfi_reset_n           => dfi_reset_n,
      dfi_rddata            => dfi_rddata(4 * DQ_WIDTH - 1 downto 0),
      dfi_wrdata            => dfi_wrdata(4 * DQ_WIDTH - 1 downto 0),
      dfi_wrdata_mask       => dfi_wrdata_mask(4 * DQ_WIDTH / 8 - 1 downto 0),
      rd_data               => rd_data(4 * PAYLOAD_WIDTH - 1 downto 0),
      wr_data               => wr_data(4 * PAYLOAD_WIDTH - 1 downto 0),
      wr_data_mask          => wr_data_mask(4 * DATA_WIDTH / 8 - 1 downto 0),
      correct_en            => correct_en,
      bank                  => bank(BANK_WIDTH - 1 downto 0),
      clk                   => clk,
      cmd                   => cmd(2 downto 0),
      col                   => col(COL_WIDTH - 1 downto 0),
      data_buf_addr         => data_buf_addr(DATA_BUF_ADDR_WIDTH - 1 downto 0),
      dfi_init_complete     => xhdl0,
      dfi_rddata_valid      => dfi_rddata_valid,
      hi_priority           => hi_priority,
      rank                  => rank(RANK_WIDTH - 1 downto 0),
      raw_not_ecc           => raw_not_ecc(3 downto 0),
      row                   => row(ROW_WIDTH - 1 downto 0),
      rst                   => rst,
      size                  => size,
      slot_0_present        => slot_0_present_mc(7 downto 0),
      slot_1_present        => slot_1_present_mc(7 downto 0),
      use_addr              => use_addr
    );

  phy_top0 : phy_top
    generic map (
      tcq              => TCQ,
      refclk_freq      => REFCLK_FREQ,
      ncs_per_rank     => nCS_PER_RANK,
      cal_width        => CAL_WIDTH,
      cs_width         => CS_WIDTH,
      nck_per_clk      => nCK_PER_CLK,
      cke_width        => CKE_WIDTH,
      dram_type        => DRAM_TYPE,
      slot_0_config    => SLOT_0_CONFIG,
      slot_1_config    => SLOT_1_CONFIG,
      clk_period       => CLK_PERIOD,
      bank_width       => BANK_WIDTH,
      ck_width         => CK_WIDTH,
      col_width        => COL_WIDTH,
      dm_width         => DM_WIDTH,
      dq_cnt_width     => DQ_CNT_WIDTH,
      dq_width         => DQ_WIDTH,
      dqs_cnt_width    => DQS_CNT_WIDTH,
      dqs_width        => DQS_WIDTH,
      dram_width       => DRAM_WIDTH,
      row_width        => ROW_WIDTH,
      rank_width       => RANK_WIDTH,
      al               => AL,
      burst_mode       => BURST_MODE,
      burst_type       => BURST_TYPE,
      nal              => NAL,
      ncl              => NCL,
      ncwl             => NCWL,
      trfc             => TRFC,
      output_drv       => OUTPUT_DRV,
      reg_ctrl         => REG_CTRL,
      rtt_nom          => RTT_NOM,
      rtt_wr           => RTT_WR,
      wrlvl            => WRLVL,
      phase_detect     => PHASE_DETECT,
      iodelay_hp_mode  => IODELAY_HP_MODE,
      iodelay_grp      => IODELAY_GRP,
      -- Prevent the following simulation-related parameters from
      -- being overridden for synthesis - for synthesis only the
      -- default values of these parameters should be used
      --synthesis translate_off
      sim_bypass_init_cal => SIM_BYPASS_INIT_CAL,
      --synthesis translate_on
      ndqs_col0        => nDQS_COL0,
      ndqs_col1        => nDQS_COL1,
      ndqs_col2        => nDQS_COL2,
      ndqs_col3        => nDQS_COL3,
      dqs_loc_col0     => DQS_LOC_COL0,
      dqs_loc_col1     => DQS_LOC_COL1,
      dqs_loc_col2     => DQS_LOC_COL2,
      dqs_loc_col3     => DQS_LOC_COL3,
      use_dm_port      => USE_DM_PORT,
      debug_port       => DEBUG_PORT
    )
    port map (
      -- Outputs
      dfi_rddata                => dfi_rddata,
      dfi_rddata_valid          => dfi_rddata_valid,
      dfi_init_complete         => xhdl0,
      ddr_ck_p                  => ddr_ck,
      ddr_ck_n                  => ddr_ck_n,
      ddr_addr                  => ddr_addr,
      ddr_ba                    => ddr_ba,
      ddr_ras_n                 => ddr_ras_n,
      ddr_cas_n                 => ddr_cas_n,
      ddr_we_n                  => ddr_we_n,
      ddr_cs_n                  => ddr_cs_n,
      ddr_cke                   => ddr_cke,
      ddr_odt                   => ddr_odt,
      ddr_reset_n               => ddr_reset_n,
      ddr_parity                => ddr_parity,
      ddr_dm                    => ddr_dm,
      pd_PSEN                   => pd_PSEN,
      pd_PSINCDEC               => pd_PSINCDEC,
      dbg_wrlvl_start           => dbg_wrlvl_start,
      dbg_wrlvl_done            => dbg_wrlvl_done,
      dbg_wrlvl_err             => dbg_wrlvl_err,       
      dbg_wl_dqs_inverted       => dbg_wl_dqs_inverted,
      dbg_wr_calib_clk_delay    => dbg_wr_calib_clk_delay,
      dbg_wl_odelay_dqs_tap_cnt => dbg_wl_odelay_dqs_tap_cnt,
      dbg_wl_odelay_dq_tap_cnt  => dbg_wl_odelay_dq_tap_cnt,
      dbg_tap_cnt_during_wrlvl  => dbg_tap_cnt_during_wrlvl,
      dbg_wl_edge_detect_valid  => dbg_wl_edge_detect_valid,
      dbg_rd_data_edge_detect   => dbg_rd_data_edge_detect,
      dbg_rdlvl_start           => dbg_rdlvl_start,
      dbg_rdlvl_done            => dbg_rdlvl_done,
      dbg_rdlvl_err             => dbg_rdlvl_err,
      dbg_cpt_first_edge_cnt    => dbg_cpt_first_edge_cnt,
      dbg_cpt_second_edge_cnt   => dbg_cpt_second_edge_cnt,
      dbg_rd_bitslip_cnt        => dbg_rd_bitslip_cnt,
      dbg_rd_clkdly_cnt         => dbg_rd_clkdly_cnt,
      dbg_rd_active_dly         => dbg_rd_active_dly,
      dbg_rd_data               => dbg_rddata,
      dbg_cpt_tap_cnt           => dbg_cpt_tap_cnt,
      dbg_rsync_tap_cnt         => dbg_rsync_tap_cnt,
      dbg_dqs_tap_cnt           => dbg_dqs_tap_cnt,
      dbg_dq_tap_cnt            => dbg_dq_tap_cnt,
      dbg_phy_pd                => dbg_phy_pd,
      dbg_phy_read              => dbg_phy_read,
      dbg_phy_rdlvl             => dbg_phy_rdlvl,       
      dbg_phy_top               => dbg_phy_top,       
      -- Inouts
      ddr_dqs_p                 => ddr_dqs,
      ddr_dqs_n                 => ddr_dqs_n,
      ddr_dq                    => ddr_dq,
      -- Inputs
      clk_mem                   => clk_mem,
      clk                       => clk,
      clk_rd_base               => clk_rd_base,
      rst                       => rst,
      slot_0_present            => slot_0_present,
      slot_1_present            => slot_1_present,
      dfi_address0              => dfi_address0,
      dfi_address1              => dfi_address1,
      dfi_bank0                 => dfi_bank0,
      dfi_bank1                 => dfi_bank1,
      dfi_cas_n0                => dfi_cas_n0,
      dfi_cas_n1                => dfi_cas_n1,
      dfi_cke0                  => (others => '1'),
      dfi_cke1                  => (others => '1'),
      dfi_cs_n0                 => dfi_cs_n0,
      dfi_cs_n1                 => dfi_cs_n1,
      dfi_odt0                  => dfi_odt0,
      dfi_odt1                  => dfi_odt1,
      dfi_ras_n0                => dfi_ras_n0,
      dfi_ras_n1                => dfi_ras_n1,
      dfi_reset_n               => dfi_reset_n,
      dfi_we_n0                 => dfi_we_n0,
      dfi_we_n1                 => dfi_we_n1,
      dfi_wrdata_en             => dfi_wrdata_en(0),
      dfi_wrdata                => dfi_wrdata,
      dfi_wrdata_mask           => dfi_wrdata_mask,
      dfi_rddata_en             => dfi_rddata_en(0),
      dfi_dram_clk_disable      => dfi_dram_clk_disable,
      io_config_strobe          => io_config_strobe,
      io_config                 => io_config,
      pd_PSDONE                 => pd_PSDONE,
      dbg_wr_dqs_tap_set        => dbg_wr_dqs_tap_set,
      dbg_wr_dq_tap_set         => dbg_wr_dq_tap_set,
      dbg_wr_tap_set_en         => dbg_wr_tap_set_en,         
      dbg_idel_up_all           => dbg_idel_up_all,       
      dbg_idel_down_all         => dbg_idel_down_all,
      dbg_idel_up_cpt           => dbg_idel_up_cpt,
      dbg_idel_down_cpt         => dbg_idel_down_cpt,
      dbg_idel_up_rsync         => dbg_idel_up_rsync,
      dbg_idel_down_rsync       => dbg_idel_down_rsync,
      dbg_sel_idel_cpt          => dbg_sel_idel_cpt,
      dbg_sel_all_idel_cpt      => dbg_sel_all_idel_cpt,
      dbg_sel_idel_rsync        => dbg_sel_idel_rsync,
      dbg_sel_all_idel_rsync    => dbg_sel_all_idel_rsync,
      dbg_pd_off                => dbg_pd_off,
      dbg_pd_maintain_off       => dbg_pd_maintain_off,
      dbg_pd_maintain_0_only    => dbg_pd_maintain_0_only,
      dbg_pd_inc_cpt            => dbg_pd_inc_cpt,
      dbg_pd_dec_cpt            => dbg_pd_dec_cpt,
      dbg_pd_inc_dqs            => dbg_pd_inc_dqs,
      dbg_pd_dec_dqs            => dbg_pd_dec_dqs, 
      dbg_pd_disab_hyst         => dbg_pd_disab_hyst,
      dbg_pd_disab_hyst_0       => dbg_pd_disab_hyst_0,
      dbg_pd_msb_sel            => dbg_pd_msb_sel,
      dbg_pd_byte_sel           => dbg_pd_byte_sel,
      dbg_inc_rd_fps            => dbg_inc_rd_fps,
      dbg_dec_rd_fps            => dbg_dec_rd_fps
    );

end architecture arch;

-- Local Variables:
-- verilog-library-directories:("." "../phy" "../controller")
-- End:
