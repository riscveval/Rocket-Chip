--*****************************************************************************
-- (c) Copyright 2008 - 2010 Xilinx, Inc. All rights reserved.
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
--  /   /         Filename              : arb_mux.vhd
-- /___/   /\     Date Last Modified    : $date$
-- \   \  /  \    Date Created          : 
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


entity arb_mux is
   generic (
      TCQ                      : integer := 100;
      ADDR_CMD_MODE            : string := "1T";
      BANK_VECT_INDX           : integer := 11;
      BANK_WIDTH               : integer := 3;
      BURST_MODE               : string := "8";
      CS_WIDTH                 : integer := 4;
      DATA_BUF_ADDR_VECT_INDX  : integer := 31;
      DATA_BUF_ADDR_WIDTH      : integer := 8;
      DRAM_TYPE                : string := "DDR3";
      EARLY_WR_DATA_ADDR       : string := "OFF";
      ECC                      : string := "OFF";
      nBANK_MACHS              : integer := 4;
      nCK_PER_CLK              : integer := 2;          -- # DRAM CKs per fabric CLKs
      nCS_PER_RANK             : integer := 1;
      nCNFG2WR                 : integer := 2;
      nSLOTS                   : integer := 2;
      RANK_VECT_INDX           : integer := 15;
      RANK_WIDTH               : integer := 2;
      ROW_VECT_INDX            : integer := 63;
      ROW_WIDTH                : integer := 16;
      RTT_NOM                  : string := "40";
      RTT_WR                   : string := "120";
      SLOT_0_CONFIG            : std_logic_vector(7 downto 0) := "00000101";
      SLOT_1_CONFIG            : std_logic_vector(7 downto 0) := "00001010"
   );
   port (

      sent_row                 : out std_logic;         -- From arb_row_col0 of arb_row_col.v
      sent_col                 : out std_logic;
      sending_row              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      io_config_valid_r        : out std_logic;
      io_config_strobe_ns      : out std_logic;
      io_config                : out std_logic_vector(RANK_WIDTH downto 0);
      dfi_we_n1                : out std_logic;
      dfi_we_n0                : out std_logic;
      dfi_ras_n1               : out std_logic;
      dfi_ras_n0               : out std_logic;
      dfi_odt_wr1              : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_wr0              : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_nom1             : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_nom0             : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_cs_n1                : out std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
      dfi_cs_n0                : out std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
      dfi_cas_n1               : out std_logic;
      dfi_cas_n0               : out std_logic;
      dfi_bank1                : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      dfi_bank0                : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      dfi_address1             : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      dfi_address0             : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      col_wr_data_buf_addr     : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      col_size                 : out std_logic;
      col_row                  : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      col_rmw                  : out std_logic;
      col_ra                   : out std_logic_vector(RANK_WIDTH - 1 downto 0);
      col_periodic_rd          : out std_logic;
      col_data_buf_addr        : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      col_ba                   : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      col_a                    : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      
      sending_col              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      io_config_strobe         : out std_logic;
      insert_maint_r1          : out std_logic;
      slot_1_present           : in std_logic_vector(7 downto 0);
      slot_0_present           : in std_logic_vector(7 downto 0);
      rts_row                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      rts_col                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      rtc                      : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      row_cmd_wr               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      row_addr                 : in std_logic_vector(ROW_VECT_INDX downto 0);
      req_wr_r                 : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_size_r               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_row_r                : in std_logic_vector(ROW_VECT_INDX downto 0);
      req_ras                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_rank_r               : in std_logic_vector(RANK_VECT_INDX downto 0);
      req_periodic_rd_r        : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_data_buf_addr_r      : in std_logic_vector(DATA_BUF_ADDR_VECT_INDX downto 0);
      req_cas                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_bank_r               : in std_logic_vector(BANK_VECT_INDX downto 0);
      rd_wr_r                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      maint_zq_r               : in std_logic;
      maint_rank_r             : in std_logic_vector(RANK_WIDTH - 1 downto 0);
      insert_maint_r           : in std_logic;
      force_io_config_rd_r       : in std_logic;
      col_rdy_wr               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      col_addr                 : in std_logic_vector(ROW_VECT_INDX downto 0);
      clk                      : in std_logic;
      rst                      : in std_logic
   );
end entity arb_mux;

architecture trans of arb_mux is



component arb_select 
   generic (
      TCQ                      : integer := 100;
      ADDR_CMD_MODE            : string := "1T";
      BANK_VECT_INDX           : integer := 11;
      BANK_WIDTH               : integer := 3;
      BURST_MODE               : string := "8";
      CS_WIDTH                 : integer := 4;
      DATA_BUF_ADDR_VECT_INDX  : integer := 31;
      DATA_BUF_ADDR_WIDTH      : integer := 8;
      DRAM_TYPE                : string := "DDR3";
      EARLY_WR_DATA_ADDR       : string := "OFF";
      ECC                      : string := "OFF";
      nBANK_MACHS              : integer := 4;
      nCK_PER_CLK              : integer := 2;
      nCS_PER_RANK             : integer := 1;
      nSLOTS                   : integer := 2;
      RANK_VECT_INDX           : integer := 15;
      RANK_WIDTH               : integer := 2;
      ROW_VECT_INDX            : integer := 63;
      ROW_WIDTH                : integer := 16;
      RTT_NOM                  : string := "40";
      RTT_WR                   : string := "120";
      SLOT_0_CONFIG            : std_logic_vector(7 downto 0) := "00000101";
      SLOT_1_CONFIG            : std_logic_vector(7 downto 0) := "00001010"
      -- Inputs
      
   );
   port (
      
      col_periodic_rd          : out std_logic;
      col_ra                   : out std_logic_vector(RANK_WIDTH - 1 downto 0);
      col_ba                   : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      col_a                    : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      col_rmw                  : out std_logic;
      col_size                 : out std_logic;
      col_row                  : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      col_data_buf_addr        : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      col_wr_data_buf_addr     : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      dfi_bank0                : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      dfi_address0             : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      dfi_ras_n0               : out std_logic;
      dfi_cas_n0               : out std_logic;
      dfi_we_n0                : out std_logic;
      dfi_bank1                : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      dfi_address1             : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      dfi_ras_n1               : out std_logic;
      dfi_cas_n1               : out std_logic;
      dfi_we_n1                : out std_logic;
      
      dfi_cs_n0                : out std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
      dfi_cs_n1                : out std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
      
      io_config                : out std_logic_vector(RANK_WIDTH downto 0);
      
      dfi_odt_nom0             : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_wr0              : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_nom1             : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_wr1              : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      clk                      : in std_logic;
      rst                      : in std_logic;
      req_rank_r               : in std_logic_vector(RANK_VECT_INDX downto 0);
      req_bank_r               : in std_logic_vector(BANK_VECT_INDX downto 0);
      req_ras                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_cas                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_wr_r                 : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      grant_row_r              : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      row_addr                 : in std_logic_vector(ROW_VECT_INDX downto 0);
      row_cmd_wr               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      insert_maint_r1          : in std_logic;
      maint_zq_r               : in std_logic;
      maint_rank_r             : in std_logic_vector(RANK_WIDTH - 1 downto 0);
      req_periodic_rd_r        : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_size_r               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      rd_wr_r                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_row_r                : in std_logic_vector(ROW_VECT_INDX downto 0);
      col_addr                 : in std_logic_vector(ROW_VECT_INDX downto 0);
      req_data_buf_addr_r      : in std_logic_vector(DATA_BUF_ADDR_VECT_INDX downto 0);
      grant_col_r              : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      grant_col_wr             : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      send_cmd0_col            : in std_logic;
      send_cmd1_row            : in std_logic;
      cs_en0                   : in std_logic;
      cs_en1                   : in std_logic;
      force_io_config_rd_r1    : in std_logic;
      grant_config_r           : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      io_config_strobe         : in std_logic;
      slot_0_present           : in std_logic_vector(7 downto 0);
      slot_1_present           : in std_logic_vector(7 downto 0)
   );

end component;


component  arb_row_col 
   generic (
      TCQ                      : integer := 100;
      ADDR_CMD_MODE            : string := "1T";
      EARLY_WR_DATA_ADDR       : string := "OFF";
      nBANK_MACHS              : integer := 4;
      nCK_PER_CLK              : integer := 2;
      nCNFG2WR                 : integer := 2
   );
   port (
      grant_row_r              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      sent_row                 : out std_logic;
      sending_row              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      grant_config_r           : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      io_config_strobe_ns      : out std_logic;
      io_config_strobe         : out std_logic;
      force_io_config_rd_r1    : out std_logic;
      io_config_valid_r        : out std_logic;
      grant_col_r              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      sending_col              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      sent_col                 : out std_logic;
      grant_col_wr             : out std_logic_vector(nBANK_MACHS - 1 downto 0);     
      send_cmd0_col            : out std_logic;  
      send_cmd1_row            : out std_logic;  
      
      cs_en0                   : out std_logic;  
      cs_en1                   : out std_logic;  
      
      insert_maint_r1          : out std_logic;
      clk                      : in std_logic;
      rst                      : in std_logic;
      rts_row                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      insert_maint_r           : in std_logic;
      rts_col                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      rtc                      : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      force_io_config_rd_r     : in std_logic;
      col_rdy_wr               : in std_logic_vector(nBANK_MACHS - 1 downto 0)
   ); 

end component;

   signal cs_en0                     : std_logic;
   signal cs_en1                     : std_logic;
   signal grant_col_r                : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal grant_col_wr               : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal grant_config_r             : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal grant_row_r                : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal send_cmd0_col              : std_logic;
   signal send_cmd1_row              : std_logic;
   
   -- Declare intermediate signals for referenced outputs
   signal force_io_config_rd_r1   : std_logic;
   signal sent_row_int            : std_logic;
   signal sent_col_int            : std_logic;
   signal sending_row_int         : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal io_config_valid_r_int   : std_logic;
   signal io_config_strobe_ns_int : std_logic;
   signal io_config_int           : std_logic_vector(RANK_WIDTH downto 0);
   signal dfi_we_n1_int           : std_logic;
   signal dfi_we_n0_int           : std_logic;
   signal dfi_ras_n1_int          : std_logic;
   signal dfi_ras_n0_int          : std_logic;
   signal dfi_odt_wr1_int         : std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
   signal dfi_odt_wr0_int         : std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
   signal dfi_odt_nom1_int        : std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
   signal dfi_odt_nom0_int        : std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
   signal dfi_cs_n1_int           : std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
   signal dfi_cs_n0_int           : std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
   signal dfi_cas_n1_int          : std_logic;
   signal dfi_cas_n0_int          : std_logic;
   signal dfi_bank1_int           : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal dfi_bank0_int           : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal dfi_address1_int        : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal dfi_address0_int         : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal col_wr_data_buf_addr_int : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
   signal col_size_int             : std_logic;
   signal col_row_int              : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal col_rmw_int              : std_logic;
   signal col_ra_int               : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal col_periodic_rd_int      : std_logic;
   signal col_data_buf_addr_int    : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
   signal col_ba_int               : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal col_a_int                : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal sending_col_int         : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal io_config_strobe_int    : std_logic;
   signal insert_maint_r1_int     : std_logic;
begin
   -- Drive referenced outputs
   sent_row <= sent_row_int;
   sent_col <= sent_col_int;
   sending_row <= sending_row_int;
   io_config_valid_r <= io_config_valid_r_int;
   io_config_strobe_ns <= io_config_strobe_ns_int;
   io_config <= io_config_int;
   dfi_we_n1 <= dfi_we_n1_int;
   dfi_we_n0 <= dfi_we_n0_int;
   dfi_ras_n1 <= dfi_ras_n1_int;
   dfi_ras_n0 <= dfi_ras_n0_int;
   dfi_odt_wr1 <= dfi_odt_wr1_int;
   dfi_odt_wr0 <= dfi_odt_wr0_int;
   dfi_odt_nom1 <= dfi_odt_nom1_int;
   dfi_odt_nom0 <= dfi_odt_nom0_int;
   dfi_cs_n1 <= dfi_cs_n1_int;
   dfi_cs_n0 <= dfi_cs_n0_int;
   dfi_cas_n1 <= dfi_cas_n1_int;
   dfi_cas_n0 <= dfi_cas_n0_int;
   dfi_bank1 <= dfi_bank1_int;
   dfi_bank0 <= dfi_bank0_int;
   dfi_address1 <= dfi_address1_int;
   dfi_address0 <= dfi_address0_int;
   col_wr_data_buf_addr <= col_wr_data_buf_addr_int;
   col_size <= col_size_int;
   col_row <= col_row_int;
   col_rmw <= col_rmw_int;
   col_ra <= col_ra_int;
   col_periodic_rd <= col_periodic_rd_int;
   col_data_buf_addr <= col_data_buf_addr_int;
   col_ba <= col_ba_int;
   col_a <= col_a_int;
   sending_col <= sending_col_int;
   io_config_strobe <= io_config_strobe_int;
   insert_maint_r1 <= insert_maint_r1_int;
   
   -- Parameters
   
   
   arb_row_col0 : arb_row_col
      generic map (
         tcq                 => TCQ,
         addr_cmd_mode       => ADDR_CMD_MODE,
         early_wr_data_addr  => EARLY_WR_DATA_ADDR,
         nbank_machs         => nBANK_MACHS,
         nck_per_clk         => nCK_PER_CLK,
         ncnfg2wr            => nCNFG2WR
      )
      port map (
         -- Outputs
         grant_row_r            => grant_row_r(nBANK_MACHS - 1 downto 0),
         sent_row               => sent_row_int,
         sending_row            => sending_row_int(nBANK_MACHS - 1 downto 0),
         grant_config_r         => grant_config_r(nBANK_MACHS - 1 downto 0),
         io_config_strobe_ns    => io_config_strobe_ns_int,
         io_config_strobe       => io_config_strobe_int,
         force_io_config_rd_r1  => force_io_config_rd_r1,
         io_config_valid_r      => io_config_valid_r_int,
         grant_col_r            => grant_col_r(nBANK_MACHS - 1 downto 0),
         sending_col            => sending_col_int(nBANK_MACHS - 1 downto 0),
         sent_col               => sent_col_int,
         grant_col_wr           => grant_col_wr(nBANK_MACHS - 1 downto 0),
         send_cmd0_col          => send_cmd0_col,
         send_cmd1_row          => send_cmd1_row,
         cs_en0                 => cs_en0,
         cs_en1                 => cs_en1,
         insert_maint_r1        => insert_maint_r1_int,
         -- Inputs
         clk                    => clk,
         rst                    => rst,
         rts_row                => rts_row(nBANK_MACHS - 1 downto 0),
         insert_maint_r         => insert_maint_r,
         rts_col                => rts_col(nBANK_MACHS - 1 downto 0),
         rtc                    => rtc(nBANK_MACHS - 1 downto 0),
         force_io_config_rd_r   => force_io_config_rd_r,
         col_rdy_wr             => col_rdy_wr(nBANK_MACHS - 1 downto 0)
      );
   
   -- Parameters
   
   
   arb_select0 : arb_select
      generic map (
         tcq                      => TCQ,
         addr_cmd_mode            => ADDR_CMD_MODE,
         bank_vect_indx           => BANK_VECT_INDX,
         bank_width               => BANK_WIDTH,
         burst_mode               => BURST_MODE,
         cs_width                 => CS_WIDTH,
         data_buf_addr_vect_indx  => DATA_BUF_ADDR_VECT_INDX,
         data_buf_addr_width      => DATA_BUF_ADDR_WIDTH,
         dram_type                => DRAM_TYPE,
         early_wr_data_addr       => EARLY_WR_DATA_ADDR,
         ecc                      => ECC,
         nbank_machs              => nBANK_MACHS,
         nck_per_clk              => nCK_PER_CLK,
         ncs_per_rank             => nCS_PER_RANK,
         nslots                   => nSLOTS,
         rank_vect_indx           => RANK_VECT_INDX,
         rank_width               => RANK_WIDTH,
         row_vect_indx            => ROW_VECT_INDX,
         row_width                => ROW_WIDTH,
         rtt_nom                  => RTT_NOM,
         rtt_wr                   => RTT_WR,
         slot_0_config            => SLOT_0_CONFIG,
         slot_1_config            => SLOT_1_CONFIG
      )
      port map (
         -- Outputs
         col_periodic_rd       => col_periodic_rd_int,
         col_ra                => col_ra_int(RANK_WIDTH - 1 downto 0),
         col_ba                => col_ba_int(BANK_WIDTH - 1 downto 0),
         col_a                 => col_a_int(ROW_WIDTH - 1 downto 0),
         col_rmw               => col_rmw_int,
         col_size              => col_size_int,
         col_row               => col_row_int(ROW_WIDTH - 1 downto 0),
         col_data_buf_addr     => col_data_buf_addr_int(DATA_BUF_ADDR_WIDTH - 1 downto 0),
         col_wr_data_buf_addr  => col_wr_data_buf_addr_int(DATA_BUF_ADDR_WIDTH - 1 downto 0),
         dfi_bank0             => dfi_bank0_int(BANK_WIDTH - 1 downto 0),
         dfi_address0          => dfi_address0_int(ROW_WIDTH - 1 downto 0),
         dfi_ras_n0            => dfi_ras_n0_int,
         dfi_cas_n0            => dfi_cas_n0_int,
         dfi_we_n0             => dfi_we_n0_int,
         dfi_bank1             => dfi_bank1_int(BANK_WIDTH - 1 downto 0),
         dfi_address1          => dfi_address1_int(ROW_WIDTH - 1 downto 0),
         dfi_ras_n1            => dfi_ras_n1_int,
         dfi_cas_n1            => dfi_cas_n1_int,
         dfi_we_n1             => dfi_we_n1_int,
         dfi_cs_n0             => dfi_cs_n0_int((CS_WIDTH * nCS_PER_RANK) - 1 downto 0),
         dfi_cs_n1             => dfi_cs_n1_int((CS_WIDTH * nCS_PER_RANK) - 1 downto 0),
         io_config             => io_config_int(RANK_WIDTH downto 0),
         dfi_odt_nom0          => dfi_odt_nom0_int((nSLOTS * nCS_PER_RANK) - 1 downto 0),
         dfi_odt_wr0           => dfi_odt_wr0_int((nSLOTS * nCS_PER_RANK) - 1 downto 0),
         dfi_odt_nom1          => dfi_odt_nom1_int((nSLOTS * nCS_PER_RANK) - 1 downto 0),
         dfi_odt_wr1           => dfi_odt_wr1_int((nSLOTS * nCS_PER_RANK) - 1 downto 0),
         -- Inputs
         clk                   => clk,
         rst                   => rst,
         req_rank_r            => req_rank_r(RANK_VECT_INDX downto 0),
         req_bank_r            => req_bank_r(BANK_VECT_INDX downto 0),
         req_ras               => req_ras(nBANK_MACHS - 1 downto 0),
         req_cas               => req_cas(nBANK_MACHS - 1 downto 0),
         req_wr_r              => req_wr_r(nBANK_MACHS - 1 downto 0),
         grant_row_r           => grant_row_r(nBANK_MACHS - 1 downto 0),
         row_addr              => row_addr(ROW_VECT_INDX downto 0),
         row_cmd_wr            => row_cmd_wr(nBANK_MACHS - 1 downto 0),
         insert_maint_r1       => insert_maint_r1_int,
         maint_zq_r            => maint_zq_r,
         maint_rank_r          => maint_rank_r(RANK_WIDTH - 1 downto 0),
         req_periodic_rd_r     => req_periodic_rd_r(nBANK_MACHS - 1 downto 0),
         req_size_r            => req_size_r(nBANK_MACHS - 1 downto 0),
         rd_wr_r               => rd_wr_r(nBANK_MACHS - 1 downto 0),
         req_row_r             => req_row_r(ROW_VECT_INDX downto 0),
         col_addr              => col_addr(ROW_VECT_INDX downto 0),
         req_data_buf_addr_r   => req_data_buf_addr_r(DATA_BUF_ADDR_VECT_INDX downto 0),
         grant_col_r           => grant_col_r(nBANK_MACHS - 1 downto 0),
         grant_col_wr          => grant_col_wr(nBANK_MACHS - 1 downto 0),
         send_cmd0_col         => send_cmd0_col,
         send_cmd1_row         => send_cmd1_row,
         cs_en0                => cs_en0,
         cs_en1                => cs_en1,
         force_io_config_rd_r1 => force_io_config_rd_r1,
         grant_config_r        => grant_config_r(nBANK_MACHS - 1 downto 0),
         io_config_strobe      => io_config_strobe_int,
         slot_0_present        => slot_0_present(7 downto 0),
         slot_1_present        => slot_1_present(7 downto 0)
      );
   
end architecture trans;


