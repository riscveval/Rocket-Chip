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
--  /   /         Filename              : mc.vhd
-- /___/   /\     Date Last Modified    : $date$
-- \   \  /  \    Date Created          : Tue Jun 30 2009
--  \___\/\___\
--
--Device            : Virtex-6
--Design Name       : DDR3 SDRAM
--Purpose           :
--Reference         :
--Revision History  :
--*****************************************************************************

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;


-- Top level memory sequencer structural block.  This block
-- instantiates the rank, bank, and column machines.

entity mc is
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
      --DELAY_WR_DATA_CNTRL        : integer := 0; --Making it as a constant
      nREFRESH_BANK              : integer := 8; --Reverted back to 8
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
      PHASE_DETECT               : string := "OFF"; --Added to control periodic reads
      ROW_WIDTH                  : integer := 16;
      RTT_NOM                    : string := "40";
      RTT_WR                     : string := "120";
      STARVE_LIMIT               : integer := 2;
      SLOT_0_CONFIG              : std_logic_vector(7 downto 0) := "00000101";
      SLOT_1_CONFIG              : std_logic_vector(7 downto 0) := "00001010";
      nSLOTS                     : integer := 2;
      tCK                        : integer := 2500;		    -- pS
      tFAW                       : integer := 40000;		-- pS
      tPRDI                      : integer := 1000000;		-- pS
      tRAS                       : integer := 37500;		-- pS
      tRCD                       : integer := 12500;		-- pS
      tREFI                      : integer := 7800000;		-- pS
      tRFC                       : integer := 110000;		-- pS
      tRP                        : integer := 12500;		-- pS
      tRRD                       : integer := 10000;		-- pS
      tRTP                       : integer := 7500;		    -- pS
      tWTR                       : integer := 7500;		    -- pS
      tZQI                       : integer := 128000000;	-- nS
      tZQCS                      : integer := 64		    -- CKs
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
end entity mc;

architecture trans of mc is

   function fRD_EN2CNFG_WR (CL: integer; DRAM_TYPE: string) return integer is
   begin
     if ( DRAM_TYPE = "DDR2" ) then
        return 5;
     elsif ( CL <= 6 ) then
        return 7;
     elsif ( (CL = 7) or (CL = 8) ) then
        return 8;
     else
        return 9;
     end if;
   end function fRD_EN2CNFG_WR;

   function fPHY_WRLAT (CWL: integer) return integer is
   begin
     if ( CWL < 7 ) then --modified "<=" to '<' to fix CR #531967 (tPHY_WRLAT issue)
       return 0;
     else
       return 1;
     end if;
   end function fPHY_WRLAT;

   function cdiv (num,div: integer) return integer is
   variable tmp : integer;
   begin
      tmp := (num/div);
      if ( (num mod div) > 0 ) then
        tmp := tmp + 1;
      end if;
      return tmp;
   end function cdiv;

   function fRRD ( nRRD_CK: integer; DRAM_TYPE: string) return integer is
   begin
      if ( DRAM_TYPE = "DDR3" ) then
        if ( nRRD_CK < 4 ) then
           return 4;
        else
           return nRRD_CK;
        end if;
      else
        if ( nRRD_CK < 2 ) then
           return 2;
        else
           return nRRD_CK;
        end if;
      end if;
   end function fRRD;

   function fWTR ( nWTR_CK: integer; DRAM_TYPE: string) return integer is
   begin
      if ( DRAM_TYPE = "DDR3" ) then
        if ( nWTR_CK < 4 ) then
           return 4;
        else
           return nWTR_CK;
        end if;
      else
        if ( nWTR_CK < 2 ) then
           return 2;
        else
           return nWTR_CK;
        end if;
      end if;
   end function fWTR;

   function fRTP ( nRTP_CK: integer; DRAM_TYPE: string) return integer is
   begin
      if ( DRAM_TYPE = "DDR3" ) then
        if ( nRTP_CK < 4 ) then
           return 4;
        else
           return nRTP_CK;
        end if;
      else
        if ( nRTP_CK < 2 ) then
           return 2;
        else
           return nRTP_CK;
        end if;
      end if;
   end function fRTP;

   function fEARLY_WR_DATA_ADDR (ECC: string; CWL: integer) return string is
   begin
     if ( (ECC = "ON") and (CWL < 7) ) then
        return "ON";
     else
        return "OFF";
     end if;
   end function fEARLY_WR_DATA_ADDR;

   function fnWR ( nWR_CK : integer) return integer is
   begin
     if ( nWR_CK = 9 ) then
        return 10;
     elsif ( nWR_CK = 11 ) then
        return 12;
     else
        return nWR_CK;
     end if;
   end function fnWR;

  function fDELAY_WR_DATA_CNTRL (ECC: string; CWL: integer) return integer is
  begin
    if ( (ECC = "ON") or (CWL < 7) ) then
        return 0;
    else
        return 1;
    end if;
  end function fDELAY_WR_DATA_CNTRL;


   constant nRD_EN2CNFG_WR       : integer := fRD_EN2CNFG_WR(CL,DRAM_TYPE);
   constant nWR_EN2CNFG_RD       : integer := 4;
   constant nWR_EN2CNFG_WR       : integer := 4;
   constant nCNFG2RD_EN          : integer := 2;
   constant nCNFG2WR             : integer := 2;
   constant nPHY_WRLAT           : integer := fPHY_WRLAT(CWL);
   constant nRCD                 : integer := cdiv(tRCD,tCK);
   constant nRP                  : integer := cdiv(tRP,  tCK);
   constant nRAS                 : integer := cdiv(tRAS, tCK);
   constant nFAW                 : integer := cdiv(tFAW, tCK);
   constant nRRD_CK              : integer := cdiv(tRRD, tCK);
   
   --As per specification, Write recover for autoprecharge ( cycles) doesn't support 
   --values of 9 and 11. Rounding off the value 9, 11 to next integer.
   constant nWR_CK               : integer := cdiv(15000, tCK);
   constant nWR                  : integer := fnWR(nWR_CK);
   constant nRRD                 : integer := fRRD(nRRD_CK,DRAM_TYPE);
   constant nWTR_CK              : integer := cdiv(tWTR,tCK);
   constant nWTR                 : integer := fWTR(nWTR_CK,DRAM_TYPE);
   constant nRTP_CK              : integer := cdiv(tRTP, tCK);
   constant nRTP                 : integer := fRTP(nRTP_CK,DRAM_TYPE);
   constant nRFC                 : integer := cdiv(tRFC,tCK);
   constant EARLY_WR_DATA_ADDR   : string  := fEARLY_WR_DATA_ADDR(ECC,CWL);

   --DELAY_WR_DATA_CNTRL is made as localprameter as the values of this
   --parameter are fixed for pirticular ECC-CWL combinations.
   constant DELAY_WR_DATA_CNTRL  : integer := fDELAY_WR_DATA_CNTRL ( ECC,CWL);

   --constant nSLOTS               : integer := 1 + 1 when (or_br(SLOT_1_CONFIG) /= 0) else
   --                                           0;
   --This constant nSLOTS is changed as generic

   
   -- Maintenance functions.
   constant MAINT_PRESCALER_PERIOD     : integer := 200000;		-- 200 nS nominal.
   constant MAINT_PRESCALER_DIV        : integer := MAINT_PRESCALER_PERIOD / (tCK * nCK_PER_CLK);		-- Round down.
   constant REFRESH_TIMER_DIV          : integer := (tREFI )/ MAINT_PRESCALER_PERIOD;
   --constant nREFRESH_BANK              : integer := 8; --This constant is made as generic inorder to give a
                                                         --flexibiity to override it for super users.
   constant PERIODIC_RD_TIMER_DIV      : integer := tPRDI / MAINT_PRESCALER_PERIOD;
   constant MAINT_PRESCALER_PERIOD_NS  : integer := MAINT_PRESCALER_PERIOD / 1000;
   constant ZQ_TIMER_DIV               : integer := tZQI / MAINT_PRESCALER_PERIOD_NS;
      
      -- Reserved feature control.
      
      -- Open page wait mode is reserved.
      -- nOP_WAIT is the number of states a bank machine will park itself
      -- on an otherwise inactive open page before closing the page.  If
      -- nOP_WAIT == 0, open page wait mode is disabled.  If nOP_WAIT == -1,
      -- the bank machine will remain parked until the pool of idle bank machines
      -- are less than LOW_IDLE_CNT.  At which point parked bank machines
      -- is selected to exit until the number of idle bank machines exceeds
      -- the LOW_IDLE_CNT.
      -- Note: Setting this value to a value greater than zero may result in 
      -- better efficiency for specific traffic patterns as the controller will
      -- attempt to keep the page open for this time value.  However, this should
      -- only be used in situations where the number of bank machines (nBANK_MACH)
      -- is equal to or greater than the number of pages that will be open.
      -- If the user attempts to open more pages than bank machines, the controller
      -- will stall for a time period up to the value set which will likely result
      -- in a serious efficiency degradation.  Increasing the number of bank
      -- machines may result in difficulty meeting timing closure.
      -- Check timing closure in the ISE tools before increasing the
      -- number of bank machines.
   constant nOP_WAIT                   : integer := 0;
   constant LOW_IDLE_CNT               : integer := 0;
   constant RANK_BM_BV_WIDTH           : integer := nBANK_MACHS * RANKS;

   component ecc_buf is
   generic (
      TCQ                        : integer := 100;
      PAYLOAD_WIDTH              : integer := 64;
      DATA_BUF_ADDR_WIDTH        : integer := 4;
      DATA_BUF_OFFSET_WIDTH      : integer := 1;
      DATA_WIDTH                 : integer := 64
   );
   port (
      rd_merge_data              : out std_logic_vector(4 * DATA_WIDTH - 1 downto 0);
      clk                        : in std_logic;
      rst                        : in std_logic;
      rd_data_addr               : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      rd_data_offset             : in std_logic_vector(DATA_BUF_OFFSET_WIDTH - 1 downto 0);
      wr_data_addr               : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      wr_data_offset             : in std_logic_vector(DATA_BUF_OFFSET_WIDTH - 1 downto 0);
      rd_data                    : in std_logic_vector(4 * PAYLOAD_WIDTH - 1 downto 0);
      wr_ecc_buf                 : in std_logic
   );
   end component;

   component ecc_dec_fix is
   generic (
      TCQ                        : integer := 100;
      PAYLOAD_WIDTH              : integer := 64;
      CODE_WIDTH                 : integer := 72;
      DATA_WIDTH                 : integer := 64;
      DQ_WIDTH                   : integer := 72;
      ECC_WIDTH                  : integer := 8
   );
   port (
      rd_data                    : out std_logic_vector(4 * PAYLOAD_WIDTH - 1 downto 0);
      ecc_single                 : out std_logic_vector(3 downto 0);
      ecc_multiple               : out std_logic_vector(3 downto 0);
      clk                        : in std_logic;
      rst                        : in std_logic;
      h_rows                     : in std_logic_vector(CODE_WIDTH * ECC_WIDTH - 1 downto 0);
      dfi_rddata                 : in std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
      correct_en                 : in std_logic;
      ecc_status_valid           : in std_logic
   );
end component;

   component ecc_gen is
   generic (
      CODE_WIDTH                 : integer := 72;
      ECC_WIDTH                  : integer := 8;
      DATA_WIDTH                 : integer := 64
   );
   port (
      h_rows                     : out std_logic_vector(CODE_WIDTH * ECC_WIDTH - 1 downto 0)
   );
end component;

   component ecc_merge_enc is
   generic (
      TCQ                        : integer := 100;
      PAYLOAD_WIDTH              : integer := 64;
      CODE_WIDTH                 : integer := 72;
      DATA_BUF_ADDR_WIDTH        : integer := 4;
      DATA_BUF_OFFSET_WIDTH      : integer := 1;
      DATA_WIDTH                 : integer := 64;
      DQ_WIDTH                   : integer := 72;
      ECC_WIDTH                  : integer := 8
   );
   port (
      dfi_wrdata                 : out std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
      dfi_wrdata_mask            : out std_logic_vector(4 * DQ_WIDTH / 8 - 1 downto 0);
      clk                        : in std_logic;
      rst                        : in std_logic;
      wr_data                    : in std_logic_vector(4 * PAYLOAD_WIDTH - 1 downto 0);
      wr_data_mask               : in std_logic_vector(4 * DATA_WIDTH / 8 - 1 downto 0);
      rd_merge_data              : in std_logic_vector(4 * DATA_WIDTH - 1 downto 0);
      h_rows                     : in std_logic_vector(CODE_WIDTH * ECC_WIDTH - 1 downto 0);
      raw_not_ecc                : in std_logic_vector(3 downto 0)
   );
end component;

   component bank_mach is
      generic (
         TCQ                        : integer := 100;
         ADDR_CMD_MODE              : string := "1T";
         BANK_WIDTH                 : integer := 3;
         BM_CNT_WIDTH               : integer := 2;
         BURST_MODE                 : string := "8";
         COL_WIDTH                  : integer := 12;
         CS_WIDTH                   : integer := 4;
         CWL                        : integer := 5;
         DATA_BUF_ADDR_WIDTH        : integer := 8;
         DRAM_TYPE                  : string := "DDR3";
         EARLY_WR_DATA_ADDR         : string := "OFF";
         ECC                        : string := "OFF";
         LOW_IDLE_CNT               : integer := 1;
         nBANK_MACHS                : integer := 4;
         nCK_PER_CLK                : integer := 2;
         nCNFG2RD_EN                : integer := 2;
         nCNFG2WR                   : integer := 2;
         nCS_PER_RANK               : integer := 1;
         nOP_WAIT                   : integer := 0;
         nRAS                       : integer := 20;
         nRCD                       : integer := 5;
         nRFC                       : integer := 44;
         nRTP                       : integer := 4;
         nRP                        : integer := 10;
         nSLOTS                     : integer := 2;
         nWR                        : integer := 6;
         ORDERING                   : string := "NORM";
         RANK_BM_BV_WIDTH           : integer := 16;
         RANK_WIDTH                 : integer := 2;
         RANKS                      : integer := 4;
         ROW_WIDTH                  : integer := 16;
         RTT_NOM                    : string := "40";
         RTT_WR                     : string := "120";
         STARVE_LIMIT               : integer := 2;
         SLOT_0_CONFIG              : std_logic_vector(7 downto 0) := "00000101";
         SLOT_1_CONFIG              : std_logic_vector(7 downto 0) := "00001010";
         tZQCS                      : integer := 64

      );
      port (
         maint_wip_r                : out std_logic;
         insert_maint_r1            : out std_logic;
         dfi_we_n1                  : out std_logic;
         dfi_we_n0                  : out std_logic;
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
         col_wr_data_buf_addr       : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         col_size                   : out std_logic;
         col_row                    : out std_logic_vector(ROW_WIDTH - 1 downto 0);
         col_rmw                    : out std_logic;
         col_ra                     : out std_logic_vector(RANK_WIDTH - 1 downto 0);
         col_periodic_rd            : out std_logic;
         col_data_buf_addr          : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         col_ba                     : out std_logic_vector(BANK_WIDTH - 1 downto 0);
         col_a                      : out std_logic_vector(ROW_WIDTH - 1 downto 0);
         bank_mach_next             : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
         accept_ns                  : out std_logic;
         accept                     : out std_logic;
         io_config                  : out std_logic_vector(RANK_WIDTH downto 0);
         io_config_strobe           : out std_logic;
         sending_row                : out std_logic_vector(nBANK_MACHS - 1 downto 0);
         sending_col                : out std_logic_vector(nBANK_MACHS - 1 downto 0);
         sent_col                   : out std_logic;
         periodic_rd_ack_r          : out std_logic;
         act_this_rank_r            : out std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
         wr_this_rank_r             : out std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
         rd_this_rank_r             : out std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
         rank_busy_r                : out std_logic_vector((RANKS * nBANK_MACHS) - 1 downto 0);
         wtr_inhbt_config_r         : in std_logic_vector(RANKS - 1 downto 0);
         use_addr                   : in std_logic;
         slot_1_present             : in std_logic_vector(7 downto 0);
         slot_0_present             : in std_logic_vector(7 downto 0);
         size                       : in std_logic;
         rst                        : in std_logic;
         row                        : in std_logic_vector(ROW_WIDTH - 1 downto 0);
         rd_rmw                     : in std_logic;
         rd_data_addr               : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         rank                       : in std_logic_vector(RANK_WIDTH - 1 downto 0);
         periodic_rd_rank_r         : in std_logic_vector(RANK_WIDTH - 1 downto 0);
         periodic_rd_r              : in std_logic;
         maint_zq_r                 : in std_logic;
         maint_req_r                : in std_logic;
         maint_rank_r               : in std_logic_vector(RANK_WIDTH - 1 downto 0);
         inhbt_wr_config            : in std_logic;
         inhbt_rd_r                 : in std_logic_vector(RANKS - 1 downto 0);
         inhbt_rd_config            : in std_logic;
         inhbt_act_faw_r            : in std_logic_vector(RANKS - 1 downto 0);
         hi_priority                : in std_logic;
         dq_busy_data               : in std_logic;
         dfi_rddata_valid           : in std_logic;
         dfi_init_complete          : in std_logic;
         data_buf_addr              : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         col                        : in std_logic_vector(COL_WIDTH - 1 downto 0);
         cmd                        : in std_logic_vector(2 downto 0);
         clk                        : in std_logic;
         bank                       : in std_logic_vector(BANK_WIDTH - 1 downto 0)
      );
   end component;
   
   component rank_mach is
      generic (
         BURST_MODE                 : string := "8";
         CS_WIDTH                   : integer := 4;
         DRAM_TYPE                  : string := "DDR3";
         MAINT_PRESCALER_DIV        : integer := 40;
         nBANK_MACHS                : integer := 4;
         nCK_PER_CLK                : integer := 2;
         CL                         : integer := 5;
         nFAW                       : integer := 30;
         nREFRESH_BANK              : integer := 8;
         nRRD                       : integer := 4;
         nWTR                       : integer := 4;
         PERIODIC_RD_TIMER_DIV      : integer := 20;
         RANK_BM_BV_WIDTH           : integer := 16;
         RANK_WIDTH                 : integer := 2;
         RANKS                      : integer := 4;
         PHASE_DETECT               : string := "OFF";
         REFRESH_TIMER_DIV          : integer := 39;
         ZQ_TIMER_DIV               : integer := 640000
      );
      port (
         periodic_rd_rank_r         : out std_logic_vector(RANK_WIDTH - 1 downto 0);
         periodic_rd_r              : out std_logic;
         maint_req_r                : out std_logic;
         inhbt_act_faw_r            : out std_logic_vector(RANKS - 1 downto 0);
         inhbt_rd_r                 : out std_logic_vector(RANKS - 1 downto 0);
         wtr_inhbt_config_r         : out std_logic_vector(RANKS - 1 downto 0);
         maint_rank_r               : out std_logic_vector(RANK_WIDTH - 1 downto 0);
         maint_zq_r                 : out std_logic;
         wr_this_rank_r             : in std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
         slot_1_present             : in std_logic_vector(7 downto 0);
         slot_0_present             : in std_logic_vector(7 downto 0);
         sending_row                : in std_logic_vector(nBANK_MACHS - 1 downto 0);
         sending_col                : in std_logic_vector(nBANK_MACHS - 1 downto 0);
         rst                        : in std_logic;
         rd_this_rank_r             : in std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
         rank_busy_r                : in std_logic_vector((RANKS * nBANK_MACHS) - 1 downto 0);
         periodic_rd_ack_r          : in std_logic;
         maint_wip_r                : in std_logic;
         insert_maint_r1            : in std_logic;
         dfi_init_complete          : in std_logic;
         clk                        : in std_logic;
         app_zq_req                 : in std_logic;
         app_ref_req                : in std_logic;
         app_periodic_rd_req        : in std_logic;
         act_this_rank_r            : in std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0)
      );
   end component;
   
   component col_mach is
      generic (
         TCQ                        : integer := 100;
         BANK_WIDTH                 : integer := 3;
         BURST_MODE                 : string := "8";
         COL_WIDTH                  : integer := 12;
         CS_WIDTH                   : integer := 4;
         DATA_BUF_ADDR_WIDTH        : integer := 8;
         DATA_BUF_OFFSET_WIDTH      : integer := 1;
         DELAY_WR_DATA_CNTRL        : integer := 0;
         DQS_WIDTH                  : integer := 8;
         DRAM_TYPE                  : string := "DDR3";
         EARLY_WR_DATA_ADDR         : string := "OFF";
         ECC                        : string := "OFF";
         MC_ERR_ADDR_WIDTH          : integer := 31;
         nCK_PER_CLK                : integer := 2;
         nPHY_WRLAT                 : integer := 0;
         nRD_EN2CNFG_WR             : integer := 6;
         nWR_EN2CNFG_RD             : integer := 4;
         nWR_EN2CNFG_WR             : integer := 4;
         RANK_WIDTH                 : integer := 2;
         ROW_WIDTH                  : integer := 16
      );
      port (
         dq_busy_data               : out std_logic;
         wr_data_offset             : out std_logic_vector(DATA_BUF_OFFSET_WIDTH - 1 downto 0);
         dfi_wrdata_en              : out std_logic_vector(DQS_WIDTH - 1 downto 0);
         wr_data_en                 : out std_logic;
         wr_data_addr               : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         dfi_rddata_en              : out std_logic_vector(DQS_WIDTH - 1 downto 0);
         inhbt_wr_config            : out std_logic;
         inhbt_rd_config            : out std_logic;
         rd_rmw                     : out std_logic;
         ecc_err_addr               : out std_logic_vector(MC_ERR_ADDR_WIDTH - 1 downto 0);
         ecc_status_valid           : out std_logic;
         wr_ecc_buf                 : out std_logic;
         rd_data_end                : out std_logic;
         rd_data_addr               : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         rd_data_offset             : out std_logic_vector(DATA_BUF_OFFSET_WIDTH - 1 downto 0);
         rd_data_en                 : out std_logic;
         clk                        : in std_logic;
         rst                        : in std_logic;
         sent_col                   : in std_logic;
         col_size                   : in std_logic;
         io_config                  : in std_logic_vector(RANK_WIDTH downto 0);
         col_wr_data_buf_addr       : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         dfi_rddata_valid           : in std_logic;
         col_periodic_rd            : in std_logic;
         col_data_buf_addr          : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         col_rmw                    : in std_logic;
         col_ra                     : in std_logic_vector(RANK_WIDTH - 1 downto 0);
         col_ba                     : in std_logic_vector(BANK_WIDTH - 1 downto 0);
         col_row                    : in std_logic_vector(ROW_WIDTH - 1 downto 0);
         col_a                      : in std_logic_vector(ROW_WIDTH - 1 downto 0)
      );
   end component;


   signal act_this_rank_r        : std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
   signal col_a                  : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal col_ba                 : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal col_data_buf_addr      : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
   signal col_periodic_rd        : std_logic;
   signal col_ra                 : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal col_rmw                : std_logic;
   signal col_row                : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal col_size               : std_logic;
   signal col_wr_data_buf_addr   : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
   signal dq_busy_data           : std_logic;
   signal ecc_status_valid       : std_logic;
   signal inhbt_act_faw_r        : std_logic_vector(RANKS - 1 downto 0);
   signal inhbt_rd_config        : std_logic;
   signal inhbt_rd_r             : std_logic_vector(RANKS - 1 downto 0);
   signal inhbt_wr_config        : std_logic;
   signal insert_maint_r1        : std_logic;
   signal maint_rank_r           : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal maint_req_r            : std_logic;
   signal maint_wip_r            : std_logic;
   signal maint_zq_r             : std_logic;
   signal periodic_rd_ack_r      : std_logic;
   signal periodic_rd_r          : std_logic;
   signal periodic_rd_rank_r     : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal rank_busy_r            : std_logic_vector((RANKS * nBANK_MACHS) - 1 downto 0);
   signal rd_rmw                 : std_logic;
   signal rd_this_rank_r         : std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
   signal sending_col            : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal sending_row            : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal sent_col               : std_logic;
   signal wr_ecc_buf             : std_logic;
   signal wr_this_rank_r         : std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
   signal wtr_inhbt_config_r     : std_logic_vector(RANKS - 1 downto 0);
   signal mc_rddata_valid        : std_logic;
   constant CODE_WIDTH           : integer := DATA_WIDTH + ECC_WIDTH;
   
   -- Declare intermediate signals for referenced outputs
   signal wr_data_en_ns       : std_logic;
   signal rd_data_end_int31      : std_logic;
   signal rd_data_en_int30       : std_logic;
   signal io_config_strobe_ns : std_logic;
   signal ecc_err_addr_int23     : std_logic_vector(MC_ERR_ADDR_WIDTH - 1 downto 0);
   signal dfi_wrdata_en_ns    : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dfi_we_n1_ns        : std_logic;
   signal dfi_we_n0_ns        : std_logic;
   signal dfi_rddata_en_ns    : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dfi_ras_n1_ns       : std_logic;
   signal dfi_ras_n0_ns       : std_logic;
   signal dfi_odt_wr1_ns      : std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
   signal dfi_odt_wr0_ns      : std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
   signal dfi_odt_nom1_ns     : std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
   signal dfi_odt_nom0_ns     : std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
   signal dfi_cs_n1_ns        : std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
   signal dfi_cs_n0_ns         : std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
   signal dfi_cas_n1_ns        : std_logic;
   signal dfi_cas_n0_ns        : std_logic;
   signal dfi_bank1_ns         : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal dfi_bank0_ns         : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal dfi_address1_ns      : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal dfi_address0_ns      : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal bank_mach_next_int2    : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal accept_ns_int1         : std_logic;
   signal accept_int0            : std_logic;
   signal io_config_ns        : std_logic_vector(RANK_WIDTH downto 0);
   signal rd_data_addr_int29     : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
   signal rd_data_offset_int32   : std_logic_vector(DATA_BUF_OFFSET_WIDTH - 1 downto 0);
   signal wr_data_addr_ns     : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
   signal wr_data_offset_ns   : std_logic_vector(DATA_BUF_OFFSET_WIDTH - 1 downto 0);
   signal dfi_wrdata_int20       : std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
   signal dfi_wrdata_mask_int22  : std_logic_vector((4 * DQ_WIDTH / 8) - 1 downto 0);
   signal rd_data_int28          : std_logic_vector(4 * PAYLOAD_WIDTH - 1 downto 0);
   signal ecc_single_int25       : std_logic_vector(3 downto 0);
   signal ecc_multiple_int24     : std_logic_vector(3 downto 0);
   signal rst_reg                    : std_logic_vector(9 downto 0);
   signal rst_final                  : std_logic;
   attribute max_fanout              : string;
   attribute max_fanout of rst_final : signal is "10";
begin
   -- Drive referenced outputs
   rd_data_end <= rd_data_end_int31;
   rd_data_en <= rd_data_en_int30;
   ecc_err_addr <= ecc_err_addr_int23;
   bank_mach_next <= bank_mach_next_int2;
   accept_ns <= accept_ns_int1;
   accept <= accept_int0;
   dfi_dram_clk_disable <= '0';
   dfi_reset_n <= '1';
   rd_data_addr <= rd_data_addr_int29;
   rd_data_offset <= rd_data_offset_int32;
   dfi_wrdata <= dfi_wrdata_int20;
   dfi_wrdata_mask <= dfi_wrdata_mask_int22;
   rd_data <= rd_data_int28;
   ecc_single <= ecc_single_int25;
   ecc_multiple <= ecc_multiple_int24;
   
   PROCESS (clk) 
   BEGIN
     IF ( clk'EVENT AND clk = '1') THEN
        rst_reg <= (rst_reg(8 DOWNTO 0) & rst);
     END IF;
   END PROCESS;

   PROCESS (clk) 
   BEGIN
     IF ( clk'EVENT AND clk = '1') THEN
        rst_final <= rst_reg(9);
     END IF;
   END PROCESS;
   
   rank_mach0 : rank_mach
      generic map (
         BURST_MODE             => BURST_MODE,
         CS_WIDTH               => CS_WIDTH,
         DRAM_TYPE              => DRAM_TYPE,
         MAINT_PRESCALER_DIV    => MAINT_PRESCALER_DIV,
         nBANK_MACHS            => nBANK_MACHS,
         nCK_PER_CLK            => nCK_PER_CLK,
         CL                     => CL,
         nFAW                   => nFAW,
         nREFRESH_BANK          => nREFRESH_BANK,
         nRRD                   => nRRD,
         nWTR                   => nWTR,
         PERIODIC_RD_TIMER_DIV  => PERIODIC_RD_TIMER_DIV,
         RANK_BM_BV_WIDTH       => RANK_BM_BV_WIDTH,
         RANK_WIDTH             => RANK_WIDTH,
         RANKS                  => RANKS,
         PHASE_DETECT           => PHASE_DETECT,
         REFRESH_TIMER_DIV      => REFRESH_TIMER_DIV,
         ZQ_TIMER_DIV           => ZQ_TIMER_DIV
      )
      port map (
         maint_req_r          => maint_req_r,
         periodic_rd_r        => periodic_rd_r,
         periodic_rd_rank_r   => periodic_rd_rank_r(RANK_WIDTH - 1 downto 0),
         inhbt_act_faw_r      => inhbt_act_faw_r(RANKS - 1 downto 0),
         inhbt_rd_r           => inhbt_rd_r(RANKS - 1 downto 0),
         wtr_inhbt_config_r   => wtr_inhbt_config_r(RANKS - 1 downto 0),
         maint_rank_r         => maint_rank_r(RANK_WIDTH - 1 downto 0),
         maint_zq_r           => maint_zq_r,
         act_this_rank_r      => act_this_rank_r(RANK_BM_BV_WIDTH - 1 downto 0),
         app_periodic_rd_req  => app_periodic_rd_req,
         app_ref_req          => app_ref_req,
         app_zq_req           => app_zq_req,
         clk                  => clk,
         dfi_init_complete    => dfi_init_complete,
         insert_maint_r1      => insert_maint_r1,
         maint_wip_r          => maint_wip_r,
         periodic_rd_ack_r    => periodic_rd_ack_r,
         rank_busy_r          => rank_busy_r((RANKS * nBANK_MACHS) - 1 downto 0),
         rd_this_rank_r       => rd_this_rank_r(RANK_BM_BV_WIDTH - 1 downto 0),
         rst                  => rst_final,
         sending_col          => sending_col(nBANK_MACHS - 1 downto 0),
         sending_row          => sending_row(nBANK_MACHS - 1 downto 0),
         slot_0_present       => slot_0_present(7 downto 0),
         slot_1_present       => slot_1_present(7 downto 0),
         wr_this_rank_r       => wr_this_rank_r(RANK_BM_BV_WIDTH - 1 downto 0)
      );
   
  
 cmd_pipe_plus: if (CMD_PIPE_PLUS1 = "ON") generate 
      process (clk)
      begin
        if (clk'event and clk = '1') then
            dfi_we_n1           <=  dfi_we_n1_ns after (TCQ)*1 ps;
            dfi_we_n0           <=  dfi_we_n0_ns after (TCQ)*1 ps;
            dfi_ras_n1          <=  dfi_ras_n1_ns after (TCQ)*1 ps;
            dfi_ras_n0          <=  dfi_ras_n0_ns after (TCQ)*1 ps;
            dfi_odt_wr1         <=  dfi_odt_wr1_ns after (TCQ)*1 ps;
            dfi_odt_wr0         <=  dfi_odt_wr0_ns after (TCQ)*1 ps;
            dfi_odt_nom1        <=  dfi_odt_nom1_ns after (TCQ)*1 ps;
            dfi_odt_nom0        <=  dfi_odt_nom0_ns after (TCQ)*1 ps;
            dfi_cs_n1           <=  dfi_cs_n1_ns after (TCQ)*1 ps;
            dfi_cs_n0           <=  dfi_cs_n0_ns after (TCQ)*1 ps;
            dfi_cas_n1          <=  dfi_cas_n1_ns after (TCQ)*1 ps;
            dfi_cas_n0          <=  dfi_cas_n0_ns after (TCQ)*1 ps;
            dfi_bank1           <=  dfi_bank1_ns after (TCQ)*1 ps;
            dfi_bank0           <=  dfi_bank0_ns after (TCQ)*1 ps;
            dfi_address1        <=  dfi_address1_ns after (TCQ)*1 ps;
            dfi_address0        <=  dfi_address0_ns after (TCQ)*1 ps;
            io_config           <=  io_config_ns after (TCQ)*1 ps;
            io_config_strobe    <=  io_config_strobe_ns after (TCQ)*1 ps;
            dfi_wrdata_en       <=  dfi_wrdata_en_ns after (TCQ)*1 ps;
            dfi_rddata_en       <=  dfi_rddata_en_ns after (TCQ)*1 ps;
            wr_data_en          <=  wr_data_en_ns after (TCQ)*1 ps;
            wr_data_addr        <=  wr_data_addr_ns after (TCQ)*1 ps;
            wr_data_offset      <=  wr_data_offset_ns after (TCQ)*1 ps;
        end if;
      end process;
    end generate; --end cmd_pipe_plus
 cmd_pipe_plus0: if (not(CMD_PIPE_PLUS1 = "ON")) generate
      process (dfi_address0_ns , dfi_address1_ns
               , dfi_bank0_ns , dfi_bank1_ns , dfi_cas_n0_ns
               , dfi_cas_n1_ns , dfi_cs_n0_ns , dfi_cs_n1_ns
               , dfi_odt_nom0_ns , dfi_odt_nom1_ns , dfi_odt_wr0_ns
               , dfi_odt_wr1_ns , dfi_ras_n0_ns , dfi_ras_n1_ns
               , dfi_rddata_en_ns , dfi_we_n0_ns , dfi_we_n1_ns
               , dfi_wrdata_en_ns , io_config_ns
               , io_config_strobe_ns , wr_data_addr_ns
               , wr_data_en_ns , wr_data_offset_ns)
        begin
        dfi_we_n1           <=  dfi_we_n1_ns after (TCQ)*1 ps;
        dfi_we_n0           <=  dfi_we_n0_ns after (TCQ)*1 ps;
        dfi_ras_n1          <=  dfi_ras_n1_ns after (TCQ)*1 ps;
        dfi_ras_n0          <=  dfi_ras_n0_ns after (TCQ)*1 ps;
        dfi_odt_wr1         <=  dfi_odt_wr1_ns after (TCQ)*1 ps;
        dfi_odt_wr0         <=  dfi_odt_wr0_ns after (TCQ)*1 ps;
        dfi_odt_nom1        <=  dfi_odt_nom1_ns after (TCQ)*1 ps;
        dfi_odt_nom0        <=  dfi_odt_nom0_ns after (TCQ)*1 ps;
        dfi_cs_n1           <=  dfi_cs_n1_ns after (TCQ)*1 ps;
        dfi_cs_n0           <=  dfi_cs_n0_ns after (TCQ)*1 ps;
        dfi_cas_n1          <=  dfi_cas_n1_ns after (TCQ)*1 ps;
        dfi_cas_n0          <=  dfi_cas_n0_ns after (TCQ)*1 ps;
        dfi_bank1           <=  dfi_bank1_ns after (TCQ)*1 ps;
        dfi_bank0           <=  dfi_bank0_ns after (TCQ)*1 ps;
        dfi_address1        <=  dfi_address1_ns after (TCQ)*1 ps;
        dfi_address0        <=  dfi_address0_ns after (TCQ)*1 ps;
        io_config           <=  io_config_ns after (TCQ)*1 ps;
        io_config_strobe    <=  io_config_strobe_ns after (TCQ)*1 ps;
        dfi_wrdata_en       <=  dfi_wrdata_en_ns after (TCQ)*1 ps;
        dfi_rddata_en       <=  dfi_rddata_en_ns after (TCQ)*1 ps;
        wr_data_en          <=  wr_data_en_ns after (TCQ)*1 ps;
        wr_data_addr        <=  wr_data_addr_ns after (TCQ)*1 ps;
        wr_data_offset      <=  wr_data_offset_ns after (TCQ)*1 ps;
      end process;
  end generate; --block: cmd_pipe_plus0

   bank_mach0 : bank_mach
      generic map (
         TCQ                  => TCQ,
         ADDR_CMD_MODE        => ADDR_CMD_MODE,
         BANK_WIDTH           => BANK_WIDTH,
         BM_CNT_WIDTH         => BM_CNT_WIDTH,
         BURST_MODE           => BURST_MODE,
         COL_WIDTH            => COL_WIDTH,
         CS_WIDTH             => CS_WIDTH,
         CWL                  => CWL,
         DATA_BUF_ADDR_WIDTH  => DATA_BUF_ADDR_WIDTH,
         DRAM_TYPE            => DRAM_TYPE,
         EARLY_WR_DATA_ADDR   => EARLY_WR_DATA_ADDR,
         ECC                  => ECC,
         LOW_IDLE_CNT         => LOW_IDLE_CNT,
         nBANK_MACHS          => nBANK_MACHS,
         nCK_PER_CLK          => nCK_PER_CLK,
         nCNFG2RD_EN          => nCNFG2RD_EN,
         nCNFG2WR             => nCNFG2WR,
         nCS_PER_RANK         => nCS_PER_RANK,
         nOP_WAIT             => nOP_WAIT,
         nRAS                 => nRAS,
         nRCD                 => nRCD,
         nRFC                 => nRFC,
         nRTP                 => nRTP,
         nRP                  => nRP,
         nSLOTS               => nSLOTS,
         nWR                  => nWR,
         ORDERING             => ORDERING,
         RANK_BM_BV_WIDTH     => RANK_BM_BV_WIDTH,
         RANK_WIDTH           => RANK_WIDTH,
         RANKS                => RANKS,
         ROW_WIDTH            => ROW_WIDTH,
         RTT_NOM              => RTT_NOM,
         RTT_WR               => RTT_WR,
         STARVE_LIMIT         => STARVE_LIMIT,
         SLOT_0_CONFIG        => SLOT_0_CONFIG,
         SLOT_1_CONFIG        => SLOT_1_CONFIG,
         tZQCS                => tZQCS
      )
      port map (
         accept                => accept_int0,
         accept_ns             => accept_ns_int1,
         bank_mach_next        => bank_mach_next_int2(BM_CNT_WIDTH - 1 downto 0),
         col_a                 => col_a(ROW_WIDTH - 1 downto 0),
         col_ba                => col_ba(BANK_WIDTH - 1 downto 0),
         col_data_buf_addr     => col_data_buf_addr(DATA_BUF_ADDR_WIDTH - 1 downto 0),
         col_periodic_rd       => col_periodic_rd,
         col_ra                => col_ra(RANK_WIDTH - 1 downto 0),
         col_rmw               => col_rmw,
         col_row               => col_row(ROW_WIDTH - 1 downto 0),
         col_size              => col_size,
         col_wr_data_buf_addr  => col_wr_data_buf_addr(DATA_BUF_ADDR_WIDTH - 1 downto 0),
         dfi_address0          => dfi_address0_ns(ROW_WIDTH - 1 downto 0),
         dfi_address1          => dfi_address1_ns(ROW_WIDTH - 1 downto 0),
         dfi_bank0             => dfi_bank0_ns(BANK_WIDTH - 1 downto 0),
         dfi_bank1             => dfi_bank1_ns(BANK_WIDTH - 1 downto 0),
         dfi_cas_n0            => dfi_cas_n0_ns,
         dfi_cas_n1            => dfi_cas_n1_ns,
         dfi_cs_n0             => dfi_cs_n0_ns((CS_WIDTH * nCS_PER_RANK) - 1 downto 0),
         dfi_cs_n1             => dfi_cs_n1_ns((CS_WIDTH * nCS_PER_RANK) - 1 downto 0),
         dfi_odt_nom0          => dfi_odt_nom0_ns((nSLOTS * nCS_PER_RANK) - 1 downto 0),
         dfi_odt_nom1          => dfi_odt_nom1_ns((nSLOTS * nCS_PER_RANK) - 1 downto 0),
         dfi_odt_wr0           => dfi_odt_wr0_ns((nSLOTS * nCS_PER_RANK) - 1 downto 0),
         dfi_odt_wr1           => dfi_odt_wr1_ns((nSLOTS * nCS_PER_RANK) - 1 downto 0),
         dfi_ras_n0            => dfi_ras_n0_ns,
         dfi_ras_n1            => dfi_ras_n1_ns,
         dfi_we_n0             => dfi_we_n0_ns,
         dfi_we_n1             => dfi_we_n1_ns,
         insert_maint_r1       => insert_maint_r1,
         maint_wip_r           => maint_wip_r,
         io_config             => io_config_ns(RANK_WIDTH downto 0),
         io_config_strobe      => io_config_strobe_ns,
         sending_row           => sending_row(nBANK_MACHS - 1 downto 0),
         sending_col           => sending_col(nBANK_MACHS - 1 downto 0),
         sent_col              => sent_col,
         periodic_rd_ack_r     => periodic_rd_ack_r,
         act_this_rank_r       => act_this_rank_r(RANK_BM_BV_WIDTH - 1 downto 0),
         wr_this_rank_r        => wr_this_rank_r(RANK_BM_BV_WIDTH - 1 downto 0),
         rd_this_rank_r        => rd_this_rank_r(RANK_BM_BV_WIDTH - 1 downto 0),
         rank_busy_r           => rank_busy_r((RANKS * nBANK_MACHS) - 1 downto 0),
         bank                  => bank(BANK_WIDTH - 1 downto 0),
         clk                   => clk,
         cmd                   => cmd(2 downto 0),
         col                   => col(COL_WIDTH - 1 downto 0),
         data_buf_addr         => data_buf_addr(DATA_BUF_ADDR_WIDTH - 1 downto 0),
         dfi_init_complete     => dfi_init_complete,
         dfi_rddata_valid      => dfi_rddata_valid,
         dq_busy_data          => dq_busy_data,
         hi_priority           => hi_priority,
         inhbt_act_faw_r       => inhbt_act_faw_r(RANKS - 1 downto 0),
         inhbt_rd_config       => inhbt_rd_config,
         inhbt_rd_r            => inhbt_rd_r(RANKS - 1 downto 0),
         inhbt_wr_config       => inhbt_wr_config,
         maint_rank_r          => maint_rank_r(RANK_WIDTH - 1 downto 0),
         maint_req_r           => maint_req_r,
         maint_zq_r            => maint_zq_r,
         periodic_rd_r         => periodic_rd_r,
         periodic_rd_rank_r    => periodic_rd_rank_r(RANK_WIDTH - 1 downto 0),
         rank                  => rank(RANK_WIDTH - 1 downto 0),
         rd_data_addr          => rd_data_addr_int29(DATA_BUF_ADDR_WIDTH - 1 downto 0),
         rd_rmw                => rd_rmw,
         row                   => row(ROW_WIDTH - 1 downto 0),
         rst                   => rst_final,
         size                  => size,
         slot_0_present        => slot_0_present(7 downto 0),
         slot_1_present        => slot_1_present(7 downto 0),
         use_addr              => use_addr,
         wtr_inhbt_config_r    => wtr_inhbt_config_r(RANKS - 1 downto 0)
      );
   
   
   col_mach0 : col_mach
      generic map (
         TCQ                    => TCQ,
         BANK_WIDTH             => BANK_WIDTH,
         BURST_MODE             => BURST_MODE,
         COL_WIDTH              => COL_WIDTH,
         CS_WIDTH               => CS_WIDTH,
         DATA_BUF_ADDR_WIDTH    => DATA_BUF_ADDR_WIDTH,
         DATA_BUF_OFFSET_WIDTH  => DATA_BUF_OFFSET_WIDTH,
         DELAY_WR_DATA_CNTRL    => DELAY_WR_DATA_CNTRL,
         DQS_WIDTH              => DQS_WIDTH,
         DRAM_TYPE              => DRAM_TYPE,
         EARLY_WR_DATA_ADDR     => EARLY_WR_DATA_ADDR,
         ECC                    => ECC,
         MC_ERR_ADDR_WIDTH      => MC_ERR_ADDR_WIDTH,
         nCK_PER_CLK            => nCK_PER_CLK,
         nPHY_WRLAT             => nPHY_WRLAT,
         nRD_EN2CNFG_WR         => nRD_EN2CNFG_WR,
         nWR_EN2CNFG_RD         => nWR_EN2CNFG_RD,
         nWR_EN2CNFG_WR         => nWR_EN2CNFG_WR,
         RANK_WIDTH             => RANK_WIDTH,
         ROW_WIDTH              => ROW_WIDTH
      )
      port map (
         dq_busy_data          => dq_busy_data,
         wr_data_offset        => wr_data_offset_ns(DATA_BUF_OFFSET_WIDTH - 1 downto 0),
         dfi_wrdata_en         => dfi_wrdata_en_ns(DQS_WIDTH - 1 downto 0),
         wr_data_en            => wr_data_en_ns,
         wr_data_addr          => wr_data_addr_ns(DATA_BUF_ADDR_WIDTH - 1 downto 0),
         dfi_rddata_en         => dfi_rddata_en_ns(DQS_WIDTH - 1 downto 0),
         inhbt_wr_config       => inhbt_wr_config,
         inhbt_rd_config       => inhbt_rd_config,
         rd_rmw                => rd_rmw,
         ecc_err_addr          => ecc_err_addr_int23(MC_ERR_ADDR_WIDTH - 1 downto 0),
         ecc_status_valid      => ecc_status_valid,
         wr_ecc_buf            => wr_ecc_buf,
         rd_data_end           => rd_data_end_int31,
         rd_data_addr          => rd_data_addr_int29(DATA_BUF_ADDR_WIDTH - 1 downto 0),
         rd_data_offset        => rd_data_offset_int32(DATA_BUF_OFFSET_WIDTH - 1 downto 0),
         rd_data_en            => rd_data_en_int30,
         clk                   => clk,
         rst                   => rst_final,
         sent_col              => sent_col,
         col_size              => col_size,
         io_config             => io_config_ns(RANK_WIDTH downto 0),
         col_wr_data_buf_addr  => col_wr_data_buf_addr(DATA_BUF_ADDR_WIDTH - 1 downto 0),
         dfi_rddata_valid      => dfi_rddata_valid,
         col_periodic_rd       => col_periodic_rd,
         col_data_buf_addr     => col_data_buf_addr(DATA_BUF_ADDR_WIDTH - 1 downto 0),
         col_rmw               => col_rmw,
         col_ra                => col_ra(RANK_WIDTH - 1 downto 0),
         col_ba                => col_ba(BANK_WIDTH - 1 downto 0),
         col_row               => col_row(ROW_WIDTH - 1 downto 0),
         col_a                 => col_a(ROW_WIDTH - 1 downto 0)
      );
   int36 : if (ECC = "OFF") generate
      rd_data_int28 <= dfi_rddata;
      dfi_wrdata_int20 <= wr_data;
      dfi_wrdata_mask_int22 <= wr_data_mask;
      ecc_single_int25 <= "0000";
      ecc_multiple_int24 <= "0000";
   end generate;
   int37 : if (not(ECC = "OFF")) generate

   signal rd_merge_data : std_logic_vector (4*DATA_WIDTH - 1 downto 0);
   signal h_rows        : std_logic_vector (CODE_WIDTH * ECC_WIDTH - 1 downto 0);
      -- Parameters
      
   begin
      ecc_merge_enc0 : ecc_merge_enc
         generic map (
            tcq                    => TCQ,
            payload_width          => PAYLOAD_WIDTH,
            code_width             => CODE_WIDTH,
            data_buf_addr_width    => DATA_BUF_ADDR_WIDTH,
            data_buf_offset_width  => DATA_BUF_OFFSET_WIDTH,
            data_width             => DATA_WIDTH,
            dq_width               => DQ_WIDTH,
            ecc_width              => ECC_WIDTH
         )
         port map (
            -- Outputs
            dfi_wrdata       => dfi_wrdata_int20(4 * DQ_WIDTH - 1 downto 0),
            dfi_wrdata_mask  => dfi_wrdata_mask_int22(4 * DQ_WIDTH / 8 - 1 downto 0),
            -- Inputs
            clk              => clk,
            rst              => rst_final,
            wr_data          => wr_data(4 * PAYLOAD_WIDTH - 1 downto 0),
            wr_data_mask     => wr_data_mask(4 * DATA_WIDTH / 8 - 1 downto 0),
            rd_merge_data    => rd_merge_data(4 * DATA_WIDTH - 1 downto 0),
            h_rows           => h_rows(CODE_WIDTH * ECC_WIDTH - 1 downto 0),
            raw_not_ecc      => raw_not_ecc(3 downto 0)
         );
      
      
      
      ecc_dec_fix0 : ecc_dec_fix
         generic map (
            tcq            => TCQ,
            payload_width  => PAYLOAD_WIDTH,
            code_width     => CODE_WIDTH,
            data_width     => DATA_WIDTH,
            dq_width       => DQ_WIDTH,
            ecc_width      => ECC_WIDTH
         )
         port map (
            -- Outputs
            rd_data           => rd_data_int28(4 * PAYLOAD_WIDTH - 1 downto 0),
            ecc_single        => ecc_single_int25(3 downto 0),
            ecc_multiple      => ecc_multiple_int24(3 downto 0),
            -- Inputs
            clk               => clk,
            rst               => rst_final,
            h_rows            => h_rows(CODE_WIDTH * ECC_WIDTH - 1 downto 0),
            dfi_rddata        => dfi_rddata(4 * DQ_WIDTH - 1 downto 0),
            correct_en        => correct_en,
            ecc_status_valid  => ecc_status_valid
         );
      
      
      
      ecc_buf0 : ecc_buf
         generic map (
            tcq                    => TCQ,
            payload_width          => PAYLOAD_WIDTH,
            data_buf_addr_width    => DATA_BUF_ADDR_WIDTH,
            data_buf_offset_width  => DATA_BUF_OFFSET_WIDTH,
            data_width             => DATA_WIDTH
         )
         port map (
            -- Outputs
            rd_merge_data   => rd_merge_data(4 * DATA_WIDTH - 1 downto 0),
            -- Inputs
            clk             => clk,
            rst             => rst_final,
            rd_data_addr    => rd_data_addr_int29(DATA_BUF_ADDR_WIDTH - 1 downto 0),
            rd_data_offset  => rd_data_offset_int32(DATA_BUF_OFFSET_WIDTH - 1 downto 0),
            wr_data_addr    => wr_data_addr_ns(DATA_BUF_ADDR_WIDTH - 1 downto 0),
            wr_data_offset  => wr_data_offset_ns(DATA_BUF_OFFSET_WIDTH - 1 downto 0),
            rd_data         => rd_data_int28(4 * PAYLOAD_WIDTH - 1 downto 0),
            wr_ecc_buf      => wr_ecc_buf
         );
      
      
      
      ecc_gen0 : ecc_gen
         generic map (
            code_width  => CODE_WIDTH,
            ecc_width   => ECC_WIDTH,
            data_width  => DATA_WIDTH
         )
         port map (
            -- Outputs
            h_rows  => h_rows(CODE_WIDTH * ECC_WIDTH - 1 downto 0)
         );
      
   end generate;
   
   		-- mc
end architecture trans;
