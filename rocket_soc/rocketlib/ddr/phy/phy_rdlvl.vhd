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
-- \   \   \/     Version:
--  \   \         Application: MIG
--  /   /         Filename: phy_rdlvl.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:13 $
-- \   \  /  \    Date Created:
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--  Read leveling calibration logic
--  NOTES:
--    1. DQ per-bit deskew is not yet supported
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_rdlvl.vhd,v 1.1 2011/06/02 07:18:13 mishra Exp $
--**$Date: 2011/06/02 07:18:13 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_rdlvl.vhd,v $
--******************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_rdlvl is
   generic (
      TCQ                       : integer := 100;	-- clk->out delay (sim only)
      nCK_PER_CLK               : integer := 2;		-- # of memory clocks per CLK
      CLK_PERIOD                : integer := 3333;	-- Internal clock period (in ps)
      REFCLK_FREQ               : integer := 300;	-- IODELAY Reference Clock freq (MHz)
      DQ_WIDTH                  : integer := 64;	-- # of DQ (data)
      DQS_CNT_WIDTH             : integer := 3;		-- = ceil(log2(DQS_WIDTH))
      DQS_WIDTH                 : integer := 8;		-- # of DQS (strobe)
      DRAM_WIDTH                : integer := 8;		-- # of DQ per DQS
      DRAM_TYPE                 : string  := "DDR3";    -- Memory I/F type: "DDR3", "DDR2"
      PD_TAP_REQ                : integer := 10;	-- # of IODELAY taps reserved for PD
      nCL                       : integer := 5;		-- Read CAS latency (in clk cyc)
      SIM_CAL_OPTION            : string := "NONE";	-- Skip various calibration steps
      REG_CTRL                  : string  := "ON";      -- "ON" for registered DIMM
      DEBUG_PORT                : string := "OFF"	-- Enable debug port
      );
   port (
      clk                       : in std_logic;
      rst                       : in std_logic;
      -- Calibration status, control signals
      rdlvl_start               : in std_logic_vector(1 downto 0);
      rdlvl_clkdiv_start        : in std_logic;
      rdlvl_rd_active           : in std_logic;
      rdlvl_done                : out std_logic_vector(1 downto 0);
      rdlvl_clkdiv_done         : out std_logic;
      rdlvl_err                 : out std_logic_vector(1 downto 0);
      rdlvl_prech_req           : out std_logic;
      prech_done                : in std_logic;
      -- Captured data in resync clock domain
      rd_data_rise0             : in std_logic_vector(DQ_WIDTH - 1 downto 0);
      rd_data_fall0             : in std_logic_vector(DQ_WIDTH - 1 downto 0);
      rd_data_rise1             : in std_logic_vector(DQ_WIDTH - 1 downto 0);
      rd_data_fall1             : in std_logic_vector(DQ_WIDTH - 1 downto 0);
      -- Stage 1 calibration outputs
      dlyce_cpt                 : out std_logic_vector(DQS_WIDTH - 1 downto 0);
      dlyinc_cpt                : out std_logic;
      dlyce_rsync               : out std_logic_vector(3 downto 0);
      dlyinc_rsync              : out std_logic;
      dlyval_dq                 : out std_logic_vector(5*DQS_WIDTH - 1 downto 0);
      dlyval_dqs                : out std_logic_vector(5*DQS_WIDTH - 1 downto 0);
      -- Stage 2 calibration inputs/outputs
      rd_bitslip_cnt            : out std_logic_vector(2*DQS_WIDTH - 1 downto 0);
      rd_clkdly_cnt             : out std_logic_vector(2*DQS_WIDTH - 1 downto 0);
      rd_active_dly             : out std_logic_vector(4 downto 0);
      rdlvl_pat_resume          : in std_logic;						-- resume pattern cal
      rdlvl_pat_err             : out std_logic;                                        -- error during pattern cal
      rdlvl_pat_err_cnt         : out std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);     -- erroring DQS group
      -- Resynchronization clock (clkinv_inv) calibration outputs
      rd_clkdiv_inv             : out std_logic_vector(DQS_WIDTH - 1 downto 0);
      -- Debug Port
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
end entity phy_rdlvl;

architecture arch of phy_rdlvl is
   -- Function to 'and' all the bits of a signal
   function AND_BR(inp_sig: std_logic_vector)
            return std_logic is
      variable return_var : std_logic := '1';		    
   begin
      for index in inp_sig'range loop
	 return_var := return_var and inp_sig(index);
      end loop;
      return return_var;
   end function;

   -- Function to 'OR' all the bits of a signal
   function OR_BR(inp_sig: std_logic_vector(DQS_WIDTH-1 downto 0))
            return std_logic is
      variable return_var : std_logic := '0';		    
   begin
      for index in inp_sig'range loop
	 return_var := return_var or inp_sig(index);
      end loop;     
      return return_var;
   end function;

--   function calc_cnt_idel_dec_cpt (second_edge_taps_r, first_edge_taps_r: std_logic_vector) return std_logic_vector is
--      variable tmp : std_logic_vector (5 downto 0);
--   begin
--      tmp := std_logic_vector(unsigned(second_edge_taps_r - first_edge_taps_r) srl 1);
--      tmp := tmp + '1';
--      return tmp;
--   end function;
   function calc_cnt_idel_dec_cpt (second_edge_taps_r, first_edge_taps_r: std_logic_vector) return std_logic_vector is
      variable tmp : std_logic_vector (6 downto 0);
   begin
      tmp := std_logic_vector(to_unsigned(to_integer(signed('0' & second_edge_taps_r)) - 
                              to_integer(signed('0' & first_edge_taps_r)), 7) srl 1) + '1';
      return tmp(5 downto 0);
   end function;

   function add_vectors (opd1, opd2: std_logic_vector) return std_logic_vector is
      variable tmp : std_logic_vector (5 downto 0);
   begin
      tmp := opd1 + ('0' & opd2); 
      return tmp(4 downto 0);
   end function;

   function subtract_vectors (opd1, opd2: std_logic_vector) return std_logic_vector is
      variable tmp : std_logic_vector (5 downto 0);
   begin
      tmp := opd1 - ('0' & opd2);
      return tmp(4 downto 0);
   end function;

   -- minimum time (in IDELAY taps) for which capture data must be stable for
   -- algorithm to consider a valid data eye to be found. The read leveling 
   -- logic will ignore any window found smaller than this value. Limitations
   -- on how small this number can be is determined by: (1) the algorithmic
   -- limitation of how many taps wide the data eye can be (3 taps), and (2)
   -- how wide regions of "instability" that occur around the edges of the
   -- read valid window can be (i.e. need to be able to filter out "false"
   -- windows that occur for a short # of taps around the edges of the true
   -- data window, although with multi-sampling during read leveling, this is
   -- not as much a concern) - the larger the value, the more protection 
   -- against "false" windows
   function MIN_EYE_SIZE_CALC return integer is
   begin
      if (DRAM_TYPE = "DDR3") then
         return 3;
      else
         return 6;
      end if;
   end function;
  
   constant MIN_EYE_SIZE              : integer := MIN_EYE_SIZE_CALC;

   -- # of clock cycles to wait after changing IDELAY value or read data MUX
   -- to allow both IDELAY chain to settle, and for delayed input to
   -- propagate thru ISERDES
   constant PIPE_WAIT_CNT             : integer := 16;
   -- Length of calibration sequence (in # of words)
   constant CAL_PAT_LEN               : integer := 8;
   -- Read data shift register length
   constant RD_SHIFT_LEN              : integer := CAL_PAT_LEN / (2*nCK_PER_CLK);
   -- Amount to shift by if one edge found (= 0.5*(bit_period)). Limit to 31
   constant IODELAY_TAP_RES           : integer := 1000000 / (REFCLK_FREQ * 64);

  --Function to compare two vectors and return value if both vectors have true values (either 0s or 1s)
   function ADVANCE_COMP(
                   input_a     :  std_logic_vector; 
                   input_b     :  std_logic_vector  
   ) return std_logic is
  	variable temp :  std_logic_vector(RD_SHIFT_LEN-1 downto 0 ) := (others => '1');
  begin
  	for i in input_a'range loop
		if(((input_a(i) = '0') and (input_b(i) = '0')) or ((input_a(i) = '1') and (input_b(i) = '1'))) then
			temp(i) := '1' ;
		else	
			temp(i) := '0' ;
		end if ;	
       end loop;
	
	if((AND_BR(temp)) = '1' ) then
	 return '1' ;
	else  
         return '0';
	end if ; 
  end;


    function CACL_TBY4_TAPS return integer is
    begin
       if ( ((CLK_PERIOD/nCK_PER_CLK/4) / IODELAY_TAP_RES) > 31) then
          return (31);
       else
          return ((CLK_PERIOD/nCK_PER_CLK/4) / IODELAY_TAP_RES);
       end if;
    end function;

    constant TBY4_TAPS                 : integer := CACL_TBY4_TAPS;

   -- Maximum amount to wait after read issued until read data returned
   constant MAX_RD_DLY_CNT            : integer := 32;
   -- # of cycles to wait after changing RDEN count value
   constant RDEN_WAIT_CNT             : integer := 8;
   -- used during read enable calibration - difference between what the
   -- calibration logic measured read enable delay to be, and what it needs
   -- to set the value of the read active delay control to be
   constant RDEN_DELAY_OFFSET         : integer := 5;
   -- # of read data samples to examine when detecting whether an edge has 
   -- occured during stage 1 calibration. Width of local param must be
   -- changed as appropriate. Note that there are two counters used, each
   -- counter can be changed independently of the other - they are used in
   -- cascade to create a larger counter
   constant DETECT_EDGE_SAMPLE_CNT0   : std_logic_vector(11 downto 0) := X"FFF";
   constant DETECT_EDGE_SAMPLE_CNT1   : std_logic_vector(11 downto 0) := X"001";
   -- # of taps in IDELAY chain. When the phase detector taps are reserved
   -- before the start of calibration, reduce half that amount from the
   -- total available taps.
   constant IODELAY_TAP_LEN           : integer := 32 - (PD_TAP_REQ/2);
   -- Half the PD taps
   constant PD_HALF_TAP               : integer := (PD_TAP_REQ/2);
   
   -- Type declarations for multi-dimensional arrays	
   type type_6 is array (0 to DQS_WIDTH-1) of std_logic_vector(4 downto 0);
   type type_5 is array (3 downto 0) of std_logic_vector(RD_SHIFT_LEN - 1 downto 0);
   type type_3 is array (DQS_WIDTH-1 downto 0) of std_logic_vector(4 downto 0);
   type type_4 is array (DRAM_WIDTH-1 downto 0) of std_logic_vector(RD_SHIFT_LEN-1 downto 0);

   constant CAL1_IDLE                 : std_logic_vector(4 downto 0) := "00000";
   constant CAL1_NEW_DQS_WAIT         : std_logic_vector(4 downto 0) := "00001";
   constant CAL1_IDEL_STORE_FIRST     : std_logic_vector(4 downto 0) := "00010";
   constant CAL1_DETECT_EDGE          : std_logic_vector(4 downto 0) := "00011";
   constant CAL1_IDEL_STORE_OLD       : std_logic_vector(4 downto 0) := "00100";
   constant CAL1_IDEL_INC_CPT         : std_logic_vector(4 downto 0) := "00101";
   constant CAL1_IDEL_INC_CPT_WAIT    : std_logic_vector(4 downto 0) := "00110";
   constant CAL1_CALC_IDEL            : std_logic_vector(4 downto 0) := "00111";
   constant CAL1_IDEL_DEC_CPT         : std_logic_vector(4 downto 0) := "01000";
   constant CAL1_NEXT_DQS             : std_logic_vector(4 downto 0) := "01001";
   constant CAL1_DONE                 : std_logic_vector(4 downto 0) := "01010";
   constant CAL1_RST_CPT              : std_logic_vector(4 downto 0) := "01011";
   constant CAL1_DETECT_EDGE_DQ       : std_logic_vector(4 downto 0) := "01100";
   constant CAL1_IDEL_INC_DQ          : std_logic_vector(4 downto 0) := "01101";
   constant CAL1_IDEL_INC_DQ_WAIT     : std_logic_vector(4 downto 0) := "01110";
   constant CAL1_CALC_IDEL_DQ         : std_logic_vector(4 downto 0) := "01111";
   constant CAL1_IDEL_INC_DQ_CPT      : std_logic_vector(4 downto 0) := "10000";
   constant CAL1_IDEL_INC_PD_CPT      : std_logic_vector(4 downto 0) := "10001";
   constant CAL1_IDEL_PD_ADJ          : std_logic_vector(4 downto 0) := "10010";
   constant CAL1_SKIP_RDLVL_INC_IDEL  : std_logic_vector(4 downto 0) := "11111"; -- Only for simulation
   
   constant CAL2_IDLE                 : std_logic_vector(2 downto 0) := "000";
   constant CAL2_READ_WAIT            : std_logic_vector(2 downto 0) := "001";
   constant CAL2_DETECT_MATCH         : std_logic_vector(2 downto 0) := "010";
   constant CAL2_BITSLIP_WAIT         : std_logic_vector(2 downto 0) := "011";
   constant CAL2_NEXT_DQS             : std_logic_vector(2 downto 0) := "100";
   constant CAL2_DONE                 : std_logic_vector(2 downto 0) := "101";
   constant CAL2_ERROR_TO             : std_logic_vector(2 downto 0) := "110";

   constant CAL_CLKDIV_IDLE                   : std_logic_vector(3 downto 0) := "0000";
   constant CAL_CLKDIV_NEW_DQS_WAIT           : std_logic_vector(3 downto 0) := "0001";
   constant CAL_CLKDIV_IDEL_STORE_REF         : std_logic_vector(3 downto 0) := "0010";
   constant CAL_CLKDIV_DETECT_EDGE            : std_logic_vector(3 downto 0) := "0011";
   constant CAL_CLKDIV_IDEL_INCDEC_RSYNC      : std_logic_vector(3 downto 0) := "0100";
   constant CAL_CLKDIV_IDEL_INCDEC_RSYNC_WAIT : std_logic_vector(3 downto 0) := "0101";
   constant CAL_CLKDIV_IDEL_SET_MIDPT_RSYNC   : std_logic_vector(3 downto 0) := "0110";
   constant CAL_CLKDIV_NEXT_CHECK             : std_logic_vector(3 downto 0) := "0111";
   constant CAL_CLKDIV_NEXT_DQS               : std_logic_vector(3 downto 0) := "1000";
   constant CAL_CLKDIV_DONE                   : std_logic_vector(3 downto 0) := "1001";

   signal cal_clkdiv_clkdiv_inv_r     : std_logic;
   signal cal_clkdiv_cnt_clkdiv_r     : std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);      
   signal cal_clkdiv_dlyce_rsync_r    : std_logic;
   signal cal_clkdiv_dlyinc_rsync_r   : std_logic;
   signal cal_clkdiv_idel_rsync_inc_r : std_logic;
   signal cal_clkdiv_prech_req_r      : std_logic;
   signal cal_clkdiv_store_sr_req_r   : std_logic;
   signal cal_clkdiv_state_r          : std_logic_vector(3 downto 0);
   signal cal1_cnt_cpt_r           : std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
   signal cal1_dlyce_cpt_r         : std_logic;
   signal cal1_dlyinc_cpt_r        : std_logic;
   signal cal1_dq_tap_cnt_r        : std_logic_vector(4 downto 0);
   signal cal1_dq_taps_inc_r       : std_logic;
   signal cal1_prech_req_r         : std_logic;
   signal cal1_found_edge          : std_logic;
   signal cal1_state_r             : std_logic_vector(4 downto 0);
   signal cal1_store_sr_req_r      : std_logic;
   signal cal2_clkdly_cnt_r        : std_logic_vector(2*DQS_WIDTH - 1 downto 0);
   signal cal2_cnt_bitslip_r       : std_logic_vector(1 downto 0);
   signal cal2_cnt_rd_dly_r        : std_logic_vector(4 downto 0);
   signal cal2_cnt_rden_r          : std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);
   signal cal2_deskew_err_r        : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal cal2_dly_cnt_delta_r     : type_3;
   signal cal2_done_r              : std_logic;
   signal cal2_done_r1             : std_logic;
   signal cal2_done_r2             : std_logic;
   signal cal2_done_r3             : std_logic;
   signal cal2_dly_cnt_r           : std_logic_vector(5*DQS_WIDTH - 1 downto 0);
   signal cal2_en_dqs_skew_r       : std_logic;
   signal cal2_max_cnt_rd_dly_r    : std_logic_vector(4 downto 0);
   signal cal2_prech_req_r         : std_logic;
   signal cal2_rd_active_dly_r     : std_logic_vector(4 downto 0);
   signal cal2_rd_bitslip_cnt_r    : std_logic_vector(2*DQS_WIDTH - 1 downto 0);
   signal cal2_state_r             : std_logic_vector(2 downto 0);
   signal clkdiv_inv_r             : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal cnt_eye_size_r           : std_logic_vector(2 downto 0);
   signal cnt_idel_dec_cpt_r       : std_logic_vector(5 downto 0);
   signal cnt_idel_inc_cpt_r       : std_logic_vector(4 downto 0);
   signal cnt_idel_skip_idel_r     : std_logic_vector(4 downto 0);
   signal cnt_pipe_wait_r          : std_logic_vector(3 downto 0);
   signal cnt_rden_wait_r          : std_logic_vector(2 downto 0);
   signal cnt_shift_r              : std_logic_vector(3 downto 0);
   signal detect_edge_cnt0_r       : std_logic_vector(11 downto 0);
   signal detect_edge_cnt1_en_r    : std_logic;
   signal detect_edge_cnt1_r       : std_logic_vector(11 downto 0);
   signal detect_edge_done_r       : std_logic;
   signal detect_edge_start_r      : std_logic;
   signal dlyce_or                 : std_logic;
   signal dlyval_dq_reg_r          : std_logic_vector(5*DQS_WIDTH - 1 downto 0);
   signal first_edge_taps_r        : std_logic_vector(4 downto 0);
   signal found_edge_r             : std_logic;
   signal found_edge_latched_r     : std_logic;
   signal found_edge_valid_r       : std_logic;
   signal found_dq_edge_r          : std_logic;
   signal found_first_edge_r       : std_logic;
   signal found_jitter_latched_r   : std_logic;
   signal found_second_edge_r      : std_logic;
   signal found_stable_eye_r       : std_logic;
   signal found_two_edge_r         : std_logic;
   signal idel_tap_cnt_cpt_r       : std_logic_vector(4 downto 0);
   signal idel_tap_delta_rsync_r   : std_logic_vector(4 downto 0);
   signal idel_tap_limit_cpt_r     : std_logic;
   signal idel_tap_limit_dq_r      : std_logic;
   signal last_tap_jitter_r        : std_logic;
   signal min_rsync_marg_r         : std_logic_vector(4 downto 0);
   signal mux_rd_fall0_r           : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal mux_rd_fall1_r           : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal mux_rd_rise0_r           : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal mux_rd_rise1_r           : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal new_cnt_clkdiv_r         : std_logic;
   signal new_cnt_cpt_r            : std_logic;
   signal old_sr_fall0_r           : type_4;
   signal old_sr_fall1_r           : type_4;
   signal old_sr_rise0_r           : type_4;
   signal old_sr_rise1_r           : type_4;
   signal old_sr_valid_r           : std_logic;
   signal pat_data_match_r         : std_logic;
   signal pat_fall0                : type_5;
   signal pat_fall1                : type_5;
   signal pat_match_fall0_r        : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal pat_match_fall0_and_r    : std_logic;
   signal pat_match_fall1_r        : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal pat_match_fall1_and_r    : std_logic;
   signal pat_match_rise0_r        : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal pat_match_rise0_and_r    : std_logic;
   signal pat_match_rise1_r        : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal pat_match_rise1_and_r    : std_logic;
   signal pat_rise0                : type_5;
   signal pat_rise1                : type_5;
   signal pipe_wait                : std_logic;
   signal pol_min_rsync_marg_r     : std_logic;    
   signal prev_found_edge_r        : std_logic;
   signal prev_found_edge_valid_r  : std_logic;
   signal prev_match_fall0_and_r   : std_logic;
   signal prev_match_fall0_r       : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal prev_match_fall1_and_r   : std_logic;
   signal prev_match_fall1_r       : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal prev_match_rise0_and_r   : std_logic;
   signal prev_match_rise0_r       : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal prev_match_rise1_and_r   : std_logic;
   signal prev_match_rise1_r       : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal prev_match_valid_r       : std_logic;
   signal prev_match_valid_r1      : std_logic;
   signal prev_sr_fall0_r          : type_4;
   signal prev_sr_fall1_r          : type_4;
   signal prev_sr_rise0_r          : type_4;
   signal prev_sr_rise1_r          : type_4;
   signal rd_mux_sel_r             : std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);
   signal rd_active_posedge_r      : std_logic;
   signal rd_active_r              : std_logic;
   signal rden_wait_r              : std_logic;
   signal right_edge_taps_r        : std_logic_vector(4 downto 0);
   signal second_edge_taps_r       : std_logic_vector(4 downto 0);
   signal second_edge_dq_taps_r    : std_logic_vector(4 downto 0);
   signal sr_fall0_r               : type_4;
   signal sr_fall1_r               : type_4;
   signal sr_rise0_r               : type_4;
   signal sr_rise1_r               : type_4;
   signal sr_match_fall0_and_r     : std_logic;
   signal sr_match_fall0_r         : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal sr_match_fall1_and_r     : std_logic;
   signal sr_match_fall1_r         : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal sr_match_valid_r         : std_logic;
   signal sr_match_valid_r1        : std_logic;
   signal sr_match_rise0_and_r     : std_logic;
   signal sr_match_rise0_r         : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal sr_match_rise1_and_r     : std_logic;
   signal sr_match_rise1_r         : std_logic_vector(DRAM_WIDTH - 1 downto 0);
   signal store_sr_done_r          : std_logic;
   signal store_sr_r               : std_logic;
   signal store_sr_req             : std_logic;
   signal sr_valid_r               : std_logic;
   signal tby4_r                   : std_logic_vector(5 downto 0);
   signal dbg_phy_clk              : std_logic;
   
   -- Debug
   signal dbg_cpt_first_edge_taps  : type_6;
   signal dbg_cpt_second_edge_taps : type_6;
   
   -- Declare intermediate signals for referenced outputs
   signal rdlvl_clkdiv_done_1      : std_logic;
   signal rdlvl_done_1             : std_logic_vector(1 downto 0);
   signal rdlvl_err_2              : std_logic_vector(1 downto 0);

   -- Declare intermediate signals for referenced outputs
   signal rd_mux_sel_r_index       : std_logic_vector(1 downto 0);
     
begin

   -- Drive referenced outputs
   rdlvl_done <= rdlvl_done_1;
   rdlvl_err <= rdlvl_err_2;
   rdlvl_clkdiv_done <= rdlvl_clkdiv_done_1;
   
  --***************************************************************************
   -- Debug
   --***************************************************************************
   dbg_phy_rdlvl(1 downto 0) 	<= rdlvl_start(1 downto 0);
   dbg_phy_rdlvl(2) 		<= found_edge_r;
   dbg_phy_rdlvl(3) 		<= pat_data_match_r;
   dbg_phy_rdlvl(6 downto 4) 	<= cal2_state_r(2 downto 0);
   dbg_phy_rdlvl(8 downto 7) 	<= cal2_cnt_bitslip_r(1 downto 0);
   dbg_phy_rdlvl(13 downto 9) 	<= cal1_state_r(4 downto 0);
   dbg_phy_rdlvl(20 downto 14) 	<= ('0' & cnt_idel_dec_cpt_r);
   dbg_phy_rdlvl(21) 		<= found_first_edge_r;
   dbg_phy_rdlvl(22) 		<= found_second_edge_r;
   dbg_phy_rdlvl(23) 		<= old_sr_valid_r;
   dbg_phy_rdlvl(24) 		<= store_sr_r;
   dbg_phy_rdlvl(32 downto 25) 	<= (sr_fall1_r(0)(1 downto 0) & sr_rise1_r(0)(1 downto 0) & 
   				   sr_fall0_r(0)(1 downto 0) & sr_rise0_r(0)(1 downto 0));
   dbg_phy_rdlvl(40 downto 33) 	<= (old_sr_fall1_r(0)(1 downto 0) & old_sr_rise1_r(0)(1 downto 0) & 
   				   old_sr_fall0_r(0)(1 downto 0) & old_sr_rise0_r(0)(1 downto 0));
   dbg_phy_rdlvl(41) 		<= sr_valid_r;
   dbg_phy_rdlvl(42) 		<= found_stable_eye_r;
   dbg_phy_rdlvl(47 downto 43) 	<= idel_tap_cnt_cpt_r;
   dbg_phy_rdlvl(48) 		<= idel_tap_limit_cpt_r;
   dbg_phy_rdlvl(53 downto 49) 	<= first_edge_taps_r;
   dbg_phy_rdlvl(58 downto 54) 	<= second_edge_taps_r;
   dbg_phy_rdlvl(64 downto 59) 	<= tby4_r;
   dbg_phy_rdlvl(67 downto 65) 	<= cnt_eye_size_r;
   dbg_phy_rdlvl(72 downto 68) 	<= cal1_dq_tap_cnt_r;
   dbg_phy_rdlvl(73) 		<= found_dq_edge_r;
   dbg_phy_rdlvl(74) 		<= found_edge_valid_r;
   gen_72width: if (DQS_CNT_WIDTH < 5) generate
      dbg_phy_rdlvl(75+DQS_CNT_WIDTH-1 downto 75) <= cal1_cnt_cpt_r;
      dbg_phy_rdlvl(78 downto 75+DQS_CNT_WIDTH)   <= (others => '0');
      dbg_phy_rdlvl(79+DQS_CNT_WIDTH-1 downto 79) <= cal2_cnt_rden_r;
      dbg_phy_rdlvl(82 downto 79+DQS_CNT_WIDTH)   <= (others => '0');
   end generate;   
   gen_144width: if (DQS_CNT_WIDTH = 5) generate
      dbg_phy_rdlvl(78 downto 75) <= cal1_cnt_cpt_r(DQS_CNT_WIDTH-2 downto 0);
      dbg_phy_rdlvl(82 downto 79) <= cal2_cnt_rden_r(DQS_CNT_WIDTH-2 downto 0);
   end generate;   
   dbg_phy_rdlvl(83)	         <= cal1_dlyce_cpt_r;
   dbg_phy_rdlvl(84)             <= cal1_dlyinc_cpt_r;
   dbg_phy_rdlvl(85)	         <= found_edge_r;
   dbg_phy_rdlvl(86)	         <= found_first_edge_r;
   dbg_phy_rdlvl(91 downto 87)   <= right_edge_taps_r;
   dbg_phy_rdlvl(96 downto 92)   <= second_edge_dq_taps_r;
   dbg_phy_rdlvl(102 downto 97)  <= tby4_r;
   dbg_phy_rdlvl(103)            <= cal_clkdiv_clkdiv_inv_r;
   dbg_phy_rdlvl(104)            <= cal_clkdiv_dlyce_rsync_r;
   dbg_phy_rdlvl(105)            <= cal_clkdiv_dlyinc_rsync_r;
   dbg_phy_rdlvl(106)            <= cal_clkdiv_idel_rsync_inc_r;
   dbg_phy_rdlvl(107)            <= pol_min_rsync_marg_r;
   dbg_phy_rdlvl(111 downto 108) <= cal_clkdiv_state_r;
   gen_dbg_cal_clkdiv_cnt_clkdiv_r_lt4: if (DQS_CNT_WIDTH < 4) generate
      dbg_phy_rdlvl(112+DQS_CNT_WIDTH-1 downto 112) <= cal_clkdiv_cnt_clkdiv_r;
      dbg_phy_rdlvl(115 downto 112+DQS_CNT_WIDTH)   <= (others => '0');
   end generate;
   gen_dbg_cal_clkdiv_cnt_clkdiv_r_ge4: if (DQS_CNT_WIDTH >= 4) generate
      dbg_phy_rdlvl(115 downto 112) <= cal_clkdiv_cnt_clkdiv_r(3 downto 0);
   end generate;
   dbg_phy_rdlvl(120 downto 116) <= idel_tap_delta_rsync_r;
   dbg_phy_rdlvl(125 downto 121) <= min_rsync_marg_r;
   gen_dbg_clkdiv_inv_r_lt9: if (DQS_WIDTH < 9) generate
     dbg_phy_rdlvl(126+DQS_WIDTH-1 downto 126) <= clkdiv_inv_r;
     dbg_phy_rdlvl(134 downto 126+DQS_WIDTH)   <= (others => '0');
   end generate;
   gen_dbg_clkdiv_inv_r_ge9: if (DQS_WIDTH >= 9) generate   
     dbg_phy_rdlvl(134 downto 126) <= clkdiv_inv_r(8 downto 0);
   end generate;     
   dbg_phy_rdlvl(135)            <= rdlvl_clkdiv_start;
   dbg_phy_rdlvl(136)            <= rdlvl_clkdiv_done_1;
   dbg_phy_rdlvl(255 downto 137) <= (others => '0');
   
   --***************************************************************************
   -- Debug output
   --***************************************************************************
   
   -- Record first and second edges found during CPT calibration
   gen_dbg_cpt_edge : for ce_i in 0 to  (DQS_WIDTH-1) generate
      dbg_cpt_first_edge_cnt((5*ce_i)+4 downto (5*ce_i))  <= dbg_cpt_first_edge_taps(ce_i);
      dbg_cpt_second_edge_cnt((5*ce_i)+4 downto (5*ce_i)) <= dbg_cpt_second_edge_taps(ce_i);
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst = '1') then
               dbg_cpt_first_edge_taps(ce_i)  <= (others => '0') after (TCQ)*1 ps;
               dbg_cpt_second_edge_taps(ce_i) <= (others => '0') after (TCQ)*1 ps;
            else
               -- Record tap counts of first and second edge edges during
               -- CPT calibration for each DQS group. If neither edge has
               -- been found, then those taps will remain 0
               if ((cal1_state_r = CAL1_CALC_IDEL) or (cal1_state_r = CAL1_RST_CPT)) then
                  if (found_first_edge_r = '1' and (TO_INTEGER(unsigned(cal1_cnt_cpt_r)) = ce_i)) then
                     dbg_cpt_first_edge_taps(ce_i) <= first_edge_taps_r after (TCQ)*1 ps;
                  end if;
                  if (found_second_edge_r = '1' and (TO_INTEGER(unsigned(cal1_cnt_cpt_r)) = ce_i)) then
                     dbg_cpt_second_edge_taps(ce_i) <= second_edge_taps_r after (TCQ)*1 ps;
                  end if;
               end if;
            end if;
         end if;
      end process;
      
   end generate;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         dbg_rd_active_dly <= cal2_rd_active_dly_r after (TCQ)*1 ps;
         dbg_rd_clkdly_cnt <= cal2_clkdly_cnt_r after (TCQ)*1 ps;
      end if;
   end process;
   
   
   -- cal2_rd_bitslip_cnt_r is only 2*DQS_WIDTH (2 bits per DQS group), but
   -- is expanded to 3 bits per DQS group to maintain width compatibility with
   -- previous definition of dbg_rd_bitslip_cnt (not a huge issue, should
   -- align these eventually - minimize impact on debug designs)
   gen_dbg_rd_bitslip : for d_i in 0 to  DQS_WIDTH-1 generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            dbg_rd_bitslip_cnt(3*d_i+1 downto 3*d_i) <= cal2_rd_bitslip_cnt_r(2*d_i+1 downto 2*d_i) after (TCQ)*1 ps;
            dbg_rd_bitslip_cnt(3*d_i+2) <= '0' after (TCQ)*1 ps;
         end if;
      end process;
      
   end generate;
   
   --***************************************************************************
   -- Data mux to route appropriate bit to calibration logic - i.e. calibration
   -- is done sequentially, one bit (or DQS group) at a time
   --***************************************************************************
   rd_mux_sel_r_index <= rdlvl_clkdiv_done_1 & rdlvl_done_1(0);

   process (clk)
   begin
      if (clk'event and clk = '1') then
         --(* full_case, parallel_case *) 
         case (rd_mux_sel_r_index) is
            when "00" =>
               rd_mux_sel_r <= cal1_cnt_cpt_r after (TCQ)*1 ps;
            when "01" =>
               rd_mux_sel_r <= cal_clkdiv_cnt_clkdiv_r after (TCQ)*1 ps;
            when "10" =>
               rd_mux_sel_r <= cal2_cnt_rden_r after (TCQ)*1 ps;  -- don't care
            when "11" =>
               rd_mux_sel_r <= cal2_cnt_rden_r after (TCQ)*1 ps;
            when others =>
	       null;
         end case;
      end if;
   end process;
   
   
   -- Register outputs for improved timing.
   -- NOTE: Will need to change when per-bit DQ deskew is supported.
   --       Currenly all bits in DQS group are checked in aggregate
   gen_mux_rd : for mux_i in 0 to  DRAM_WIDTH-1 generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            mux_rd_rise0_r(mux_i) <= rd_data_rise0(DRAM_WIDTH*to_integer(unsigned(rd_mux_sel_r)) + mux_i) after (TCQ)*1 ps;
            mux_rd_fall0_r(mux_i) <= rd_data_fall0(DRAM_WIDTH*to_integer(unsigned(rd_mux_sel_r)) + mux_i) after (TCQ)*1 ps;
            mux_rd_rise1_r(mux_i) <= rd_data_rise1(DRAM_WIDTH*to_integer(unsigned(rd_mux_sel_r)) + mux_i) after (TCQ)*1 ps;
            mux_rd_fall1_r(mux_i) <= rd_data_fall1(DRAM_WIDTH*to_integer(unsigned(rd_mux_sel_r)) + mux_i) after (TCQ)*1 ps;
         end if;
      end process;
      
   end generate;
   
   --***************************************************************************
   -- Demultiplexor to control IODELAY tap values
   --***************************************************************************
   
   -- Capture clock
   process (clk)
   begin
      if (clk'event and clk = '1') then
         dlyce_cpt <= (others => '0') after (TCQ)*1 ps;
         dlyinc_cpt <= '0' after (TCQ)*1 ps;

         if (cal1_dlyce_cpt_r = '1') then
            if ((SIM_CAL_OPTION = "NONE") or (SIM_CAL_OPTION = "FAST_WIN_DETECT")) then
               -- Change only specified DQS group's capture clock
               dlyce_cpt(to_integer(unsigned(rd_mux_sel_r))) <= '1' after (TCQ)*1 ps;
               dlyinc_cpt    <= cal1_dlyinc_cpt_r after (TCQ)*1 ps;
            elsif ((SIM_CAL_OPTION = "FAST_CAL") or (SIM_CAL_OPTION = "SKIP_CAL")) then
               -- if simulating, and "shortcuts" for calibration enabled, apply 
               -- results to all other elements (i.e. assume delay on all 
               -- bits/bytes is same). Also do the same if skipping calibration 
               -- (the logic will still increment IODELAY to the "hardcoded" value)
               dlyce_cpt  <= (others => '1') after (TCQ)*1 ps;
               dlyinc_cpt <= cal1_dlyinc_cpt_r after (TCQ)*1 ps;
            end if;
         elsif (DEBUG_PORT = "ON") then
            -- simultaneously inc/dec all CPT idelays
            if ((dbg_idel_up_all or dbg_idel_down_all or dbg_sel_all_idel_cpt) = '1') then
               dlyce_cpt  <= (others => (dbg_idel_up_all or dbg_idel_down_all or dbg_idel_up_cpt or dbg_idel_down_cpt)) after (TCQ)*1 ps;
               dlyinc_cpt <= dbg_idel_up_all or dbg_idel_up_cpt after (TCQ)*1 ps;
            else
               -- select specific cpt clock for adjustment
               if (to_integer(unsigned(dbg_sel_idel_cpt)) < DQS_WIDTH) then
                  dlyce_cpt(to_integer(unsigned(dbg_sel_idel_cpt))) <= dbg_idel_up_cpt or dbg_idel_down_cpt after (TCQ)*1 ps;
	       end if;	  
               dlyinc_cpt <= dbg_idel_up_cpt after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;
   
   
   -- Resync clock
   process (clk)
   begin
      if (clk'event and clk = '1') then
         dlyce_rsync <= (others => '0') after (TCQ)*1 ps;
         dlyinc_rsync <= '0' after (TCQ)*1 ps;

         if (cal_clkdiv_dlyce_rsync_r = '1') then
            -- When shifting RSYNC, shift all BUFR IODELAYs. This is allowed
            -- because only one DQS-group's data is being checked at any one
            -- time, and at the end of calibration, all of the BUFR IODELAYs
            -- will be reset to the starting tap value          
            dlyce_rsync  <= (others => '1') after (TCQ)*1 ps;
            dlyinc_rsync <= cal_clkdiv_dlyinc_rsync_r after (TCQ)*1 ps; 
         elsif (DEBUG_PORT = "ON") then
            -- simultaneously inc/dec all RSYNC idelays
            if ((dbg_idel_up_all or dbg_idel_down_all or dbg_sel_all_idel_rsync) = '1') then
               dlyce_rsync <= (others => (dbg_idel_up_all or dbg_idel_down_all or dbg_idel_up_rsync or dbg_idel_down_rsync)) after (TCQ)*1 ps;
               dlyinc_rsync <= dbg_idel_up_all or dbg_idel_up_rsync after (TCQ)*1 ps;
            else
               -- select specific rsync clock for adjustment
               if (to_integer(unsigned(dbg_sel_idel_rsync)) < 4) then
		  dlyce_rsync(to_integer(unsigned(dbg_sel_idel_rsync))) <= (dbg_idel_up_rsync or dbg_idel_down_rsync) after (TCQ)*1 ps;
	       end if;	  
               dlyinc_rsync <= dbg_idel_up_rsync after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;
   
   
   -- DQ parallel load tap values
   -- Currently no debug port option to change DQ taps
   -- NOTE: This values are not initially assigned after reset - until
   --  a particular byte is being calibrated, the IDELAY dlyval values from 
   --  this module will be X's in simulation - this will be okay - those 
   --  IDELAYs won't be used until the byte is calibrated
   process (clk)
   begin
      if (clk'event and clk = '1') then
         -- If read leveling is not complete, calibration logic has complete
         -- control of loading of DQ IDELAY taps
         if ((SIM_CAL_OPTION = "NONE") or (SIM_CAL_OPTION = "FAST_WIN_DETECT")) then
            -- Load all IDELAY value for all bits in that byte with the same
            -- value. Eventually this will be changed to accomodate different
            -- tap counts across the bits in a DQS group (i.e. "per-bit" cal)
            for i in 0 to 4 loop
     	       dlyval_dq_reg_r(5*to_integer(unsigned(cal1_cnt_cpt_r))+ i) <= cal1_dq_tap_cnt_r(i) after (TCQ)*1 ps;
            end loop;
         elsif (SIM_CAL_OPTION = "FAST_CAL") then
            -- For simulation purposes, to reduce time associated with
            -- calibration, calibrate only one DQS group, and load all IODELAY 
            -- values for all DQS groups with same value     
	    for idx in 0 to (DQS_WIDTH-1) loop
               dlyval_dq_reg_r(5*idx+4 downto 5*idx) <= cal1_dq_tap_cnt_r after (TCQ)*1 ps;
	    end loop;
         elsif (SIM_CAL_OPTION = "SKIP_CAL") then
            -- If skipping calibration altogether (only for simulation), set
            -- all the DQ IDELAY delay values to 0
            dlyval_dq_reg_r <= (others => '0') after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   
   -- Register for timing (help with logic placement) - we're gonna need 
   -- all the help we can get
   -- dlyval_dqs is assigned the value of dq taps. It is used in the PD module.
   -- Changes will be made to this assignment when perbit deskew is done.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         dlyval_dq  <= dlyval_dq_reg_r after (TCQ)*1 ps;
         dlyval_dqs <= dlyval_dq_reg_r after (TCQ)*1 ps;
      end if;
   end process;
   
   --***************************************************************************
   -- Generate signal used to delay calibration state machine - used when:
   --  (1) IDELAY value changed
   --  (2) RD_MUX_SEL value changed
   -- Use when a delay is necessary to give the change time to propagate
   -- through the data pipeline (through IDELAY and ISERDES, and fabric
   -- pipeline stages)
   --***************************************************************************
   -- combine requests to modify any of the IDELAYs into one
   dlyce_or <=  '1' when (cal1_state_r = CAL1_IDEL_INC_DQ) else 
		(cal1_dlyce_cpt_r or new_cnt_cpt_r or
                 cal_clkdiv_dlyce_rsync_r or new_cnt_clkdiv_r);
   
   -- NOTE: Can later recode to avoid combinational path, but be careful about
   --   timing effect on main state logic
   pipe_wait <=  '1' when (to_integer(unsigned(cnt_pipe_wait_r)) /= (PIPE_WAIT_CNT-1)) else dlyce_or;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            cnt_pipe_wait_r <= "0000" after (TCQ)*1 ps;
         elsif (dlyce_or = '1') then
            cnt_pipe_wait_r <= "0000" after (TCQ)*1 ps;
         elsif (to_integer(unsigned(cnt_pipe_wait_r)) /= (PIPE_WAIT_CNT-1)) then
            cnt_pipe_wait_r <= cnt_pipe_wait_r + "0001" after (TCQ)*1 ps;
         end if;
      end if;
   end process;
               
   --***************************************************************************
   -- generate request to PHY_INIT logic to issue precharged. Required when
   -- calibration can take a long time (during which there are only constant
   -- reads present on this bus). In this case need to issue perioidic
   -- precharges to avoid tRAS violation. This signal must meet the following
   -- requirements: (1) only transition from 0->1 when prech is first needed,
   -- (2) stay at 1 and only transition 1->0 when RDLVL_PRECH_DONE asserted
   --***************************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            rdlvl_prech_req <= '0' after (TCQ)*1 ps;
         else
            -- Combine requests from all stages here
            rdlvl_prech_req <= cal1_prech_req_r or cal2_prech_req_r or
                               cal_clkdiv_prech_req_r after (TCQ)*1 ps;
         end if;
      end if;
   end process;

   --***************************************************************************
   -- Shift register to store last RDDATA_SHIFT_LEN cycles of data from ISERDES
   -- NOTE: Written using discrete flops, but SRL can be used if the matching
   --   logic does the comparison sequentially, rather than parallel
   --***************************************************************************
   gen_sr : for rd_i in 0 to  DRAM_WIDTH-1 generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            sr_rise0_r(rd_i) <= sr_rise0_r(rd_i)(RD_SHIFT_LEN - 2 downto 0) & mux_rd_rise0_r(rd_i) after (TCQ)*1 ps;
            sr_fall0_r(rd_i) <= sr_fall0_r(rd_i)(RD_SHIFT_LEN - 2 downto 0) & mux_rd_fall0_r(rd_i) after (TCQ)*1 ps;
            sr_rise1_r(rd_i) <= sr_rise1_r(rd_i)(RD_SHIFT_LEN - 2 downto 0) & mux_rd_rise1_r(rd_i) after (TCQ)*1 ps;
            sr_fall1_r(rd_i) <= sr_fall1_r(rd_i)(RD_SHIFT_LEN - 2 downto 0) & mux_rd_fall1_r(rd_i) after (TCQ)*1 ps;
         end if;
      end process;      
   end generate;
   
   --***************************************************************************
   -- First stage calibration: Capture clock
   --***************************************************************************
   
   --*****************************************************************
   -- Free-running counter to keep track of when to do parallel load of
   -- data from memory
   --*****************************************************************   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            cnt_shift_r <= (others => '0') after (TCQ)*1 ps;
            sr_valid_r  <= '0' after (TCQ)*1 ps;
         else
            if (to_integer(unsigned(cnt_shift_r)) = (RD_SHIFT_LEN-1)) then
               sr_valid_r  <= '1' after (TCQ)*1 ps;
               cnt_shift_r <= (others => '0') after (TCQ)*1 ps;
            else
               sr_valid_r  <= '0' after (TCQ)*1 ps;
               cnt_shift_r <= cnt_shift_r + "0001" after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;
   
   
   --*****************************************************************
   -- Logic to determine when either edge of the data eye encountered
   -- Pre- and post-IDELAY update data pattern is compared, if they
   -- differ, than an edge has been encountered. Currently no attempt
   -- made to determine if the data pattern itself is "correct", only
   -- whether it changes after incrementing the IDELAY (possible
   -- future enhancement)
   --*****************************************************************

   store_sr_req <= cal1_store_sr_req_r or cal_clkdiv_store_sr_req_r;
   
   -- Simple handshaking - when calib state machines want the OLD SR
   -- value to get loaded, it requests for it to be loaded. One the
   -- next sr_valid_r pulse, it does get loaded, and store_sr_done_r
   -- is then pulsed asserted to indicate this, and we all go on our
   -- merry way
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            store_sr_done_r <= '0' after (TCQ)*1 ps;
            store_sr_r <= '0' after (TCQ)*1 ps;
         else
            store_sr_done_r <= sr_valid_r and store_sr_r;
            if (store_sr_req = '1') then
               store_sr_r <= '1' after (TCQ)*1 ps;
            elsif ((sr_valid_r and store_sr_r) = '1') then
               store_sr_r <= '0' after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;
  
   -- Determine if the comparison logic is putting out a valid
   -- output - as soon as a request is made to load in a new value
   -- for the OLD_SR shift register, the valid pipe is cleared. It
   -- then gets asserted once the new value gets loaded into the
   -- OLD_SR register
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            sr_match_valid_r  <= '0' after (TCQ)*1 ps;
            sr_match_valid_r1 <= '0' after (TCQ)*1 ps;
            old_sr_valid_r    <= '0' after (TCQ)*1 ps;
         else
            -- Flag to indicate whether data in OLD_SR register is valid
            if (store_sr_req = '1') then
               old_sr_valid_r <= '0' after (TCQ)*1 ps;
            elsif (store_sr_done_r = '1') then
               -- Immediately flush valid pipe to prevent any logic from
               -- acting on compare results using previous OLD_SR data
               old_sr_valid_r <= '1' after (TCQ)*1 ps;
            end if;
            if (store_sr_req = '1') then
               sr_match_valid_r <= '0' after (TCQ)*1 ps;
               sr_match_valid_r1 <= '0' after (TCQ)*1 ps;
            else
               sr_match_valid_r <= old_sr_valid_r and sr_valid_r after (TCQ)*1 ps;
               sr_match_valid_r1 <= sr_match_valid_r after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;

   -- Create valid qualifier for previous sample compare - might not
   -- be needed - check previous sample compare timing 
   process(clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then     
            prev_match_valid_r  <= '0' after (TCQ)*1 ps;	
            prev_match_valid_r1 <= '0' after (TCQ)*1 ps;
         else   
            prev_match_valid_r  <= sr_valid_r after (TCQ)*1 ps;	
            prev_match_valid_r1 <= prev_match_valid_r after (TCQ)*1 ps;
         end if;
      end if;
   end process;     

   -- Transfer current data to old data, prior to incrementing IDELAY
   gen_old_sr : for z in 0 to  DRAM_WIDTH-1 generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (sr_valid_r = '1') then
	       -- Load last sample (i.e. from current sampling interval)	    
               prev_sr_rise0_r(z) <= sr_rise0_r(z) after (TCQ)*1 ps;
               prev_sr_fall0_r(z) <= sr_fall0_r(z) after (TCQ)*1 ps;
               prev_sr_rise1_r(z) <= sr_rise1_r(z) after (TCQ)*1 ps;
               prev_sr_fall1_r(z) <= sr_fall1_r(z) after (TCQ)*1 ps;
            end if;   
            if ((sr_valid_r and store_sr_r) = '1') then   
               old_sr_rise0_r(z)  <= sr_rise0_r(z) after (TCQ)*1 ps;
               old_sr_fall0_r(z)  <= sr_fall0_r(z) after (TCQ)*1 ps;
               old_sr_rise1_r(z)  <= sr_rise1_r(z) after (TCQ)*1 ps;
               old_sr_fall1_r(z)  <= sr_fall1_r(z) after (TCQ)*1 ps;
            end if;
         end if;
      end process;
      
   end generate;
   
   --*******************************************************
   -- Match determination occurs over 3 cycles - pipelined for better timing
   --*******************************************************
   
   -- CYCLE1: Compare all bits in DQS grp, generate separate term for each
   --  bit for each cycle of training seq. For example, if training seq = 4
   --  words, and there are 8-bits per DQS group, then there is total of
   --  8*4 = 32 terms generated in this cycle
   gen_sr_match : for sh_i in 0 to  DRAM_WIDTH-1 generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (sr_valid_r = '1') then
               -- Structure HDL such that X on data bus will result in a mismatch
               -- This is required for memory models that can drive the bus with
               -- X's to model uncertainty regions (e.g. Denali)

	       -- Check current sample vs. sample from last IODELAY tap	    
               --if (sr_rise0_r(sh_i) = old_sr_rise0_r(sh_i)) then
               if (ADVANCE_COMP(sr_rise0_r(sh_i),old_sr_rise0_r(sh_i)) = '1') then
                  sr_match_rise0_r(sh_i) <= '1' after (TCQ)*1 ps;
               else                  
                  sr_match_rise0_r(sh_i) <= '0' after (TCQ)*1 ps;
               end if;
               --if (sr_fall0_r(sh_i) = old_sr_fall0_r(sh_i)) then
               if (ADVANCE_COMP(sr_fall0_r(sh_i),old_sr_fall0_r(sh_i)) = '1') then
                  sr_match_fall0_r(sh_i) <= '1' after (TCQ)*1 ps;
               else                  
                  sr_match_fall0_r(sh_i) <= '0' after (TCQ)*1 ps;
               end if;
               --if (sr_rise1_r(sh_i) = old_sr_rise1_r(sh_i)) then
               if (ADVANCE_COMP(sr_rise1_r(sh_i),old_sr_rise1_r(sh_i)) = '1') then
                  sr_match_rise1_r(sh_i) <= '1' after (TCQ)*1 ps;
               else                  
                  sr_match_rise1_r(sh_i) <= '0' after (TCQ)*1 ps;
               end if;
               --if (sr_fall1_r(sh_i) = old_sr_fall1_r(sh_i)) then
               if (ADVANCE_COMP(sr_fall1_r(sh_i),old_sr_fall1_r(sh_i)) = '1') then
                  sr_match_fall1_r(sh_i) <= '1' after (TCQ)*1 ps;
               else
                  sr_match_fall1_r(sh_i) <= '0' after (TCQ)*1 ps;
               end if;

	       -- Check current sample vs. sample from current IODELAY tap
               --if (sr_rise0_r(sh_i) = prev_sr_rise0_r(sh_i)) then
               if (ADVANCE_COMP(sr_rise0_r(sh_i),prev_sr_rise0_r(sh_i)) = '1') then
                  prev_match_rise0_r(sh_i) <= '1' after (TCQ)*1 ps;
               else                  
                  prev_match_rise0_r(sh_i) <= '0' after (TCQ)*1 ps;
               end if;
               --if (sr_fall0_r(sh_i) = prev_sr_fall0_r(sh_i)) then
               if (ADVANCE_COMP(sr_fall0_r(sh_i),prev_sr_fall0_r(sh_i)) = '1') then
                  prev_match_fall0_r(sh_i) <= '1' after (TCQ)*1 ps;
               else                  
                  prev_match_fall0_r(sh_i) <= '0' after (TCQ)*1 ps;
               end if;
               --if (sr_rise1_r(sh_i) = prev_sr_rise1_r(sh_i)) then
               if (ADVANCE_COMP(sr_rise1_r(sh_i),prev_sr_rise1_r(sh_i)) = '1') then
                  prev_match_rise1_r(sh_i) <= '1' after (TCQ)*1 ps;
               else                  
                  prev_match_rise1_r(sh_i) <= '0' after (TCQ)*1 ps;
               end if;
               --if (sr_fall1_r(sh_i) = prev_sr_fall1_r(sh_i)) then
               if (ADVANCE_COMP(sr_fall1_r(sh_i),prev_sr_fall1_r(sh_i)) = '1') then
                  prev_match_fall1_r(sh_i) <= '1' after (TCQ)*1 ps;
               else
                  prev_match_fall1_r(sh_i) <= '0' after (TCQ)*1 ps;
               end if;

            end if;
         end if;
      end process;
      
   end generate;
   
   -- CYCLE 2: Logical AND match terms from all bits in DQS group together
   process (clk)
   begin
      if (clk'event and clk = '1') then
	 -- Check current sample vs. sample from last IODELAY tap     
         sr_match_rise0_and_r <= AND_BR(sr_match_rise0_r) after (TCQ)*1 ps;
         sr_match_fall0_and_r <= AND_BR(sr_match_fall0_r) after (TCQ)*1 ps;
         sr_match_rise1_and_r <= AND_BR(sr_match_rise1_r) after (TCQ)*1 ps;
         sr_match_fall1_and_r <= AND_BR(sr_match_fall1_r) after (TCQ)*1 ps;

	 -- Check current sample vs. sample from current IODELAY tap
         prev_match_rise0_and_r <= AND_BR(prev_match_rise0_r) after (TCQ)*1 ps;
         prev_match_fall0_and_r <= AND_BR(prev_match_fall0_r) after (TCQ)*1 ps;
         prev_match_rise1_and_r <= AND_BR(prev_match_rise1_r) after (TCQ)*1 ps;
         prev_match_fall1_and_r <= AND_BR(prev_match_fall1_r) after (TCQ)*1 ps;
	 
      end if;
   end process;
   
   
   -- CYCLE 3: During the third cycle of compare, the comparison output
   --  over all the cycles of the training sequence is output  
   process (clk)
   begin
      if (clk'event and clk = '1') then
         -- Found edge only asserted if OLD_SR shift register contents are valid
         -- and a match has not occurred - since we're using this shift register
         -- scheme, we need to qualify the match with the valid signals because 
         -- the "old" and "current" shift register contents can't be compared on 
         -- every clock cycle, only when the shift register is "fully loaded"
         found_edge_r <= ((not(sr_match_rise0_and_r) or not(sr_match_fall0_and_r) or 
			   not(sr_match_rise1_and_r) or not(sr_match_fall1_and_r)) and 
			  (sr_match_valid_r1)) after (TCQ)*1 ps;
         found_edge_valid_r <= sr_match_valid_r1 after (TCQ)*1 ps;

         prev_found_edge_r <= ((not(prev_match_rise0_and_r) or not(prev_match_fall0_and_r) or 
			        not(prev_match_rise1_and_r) or not(prev_match_fall1_and_r)) and 
			       (prev_match_valid_r1)) after (TCQ)*1 ps;
         prev_found_edge_valid_r <= prev_match_valid_r1 after (TCQ)*1 ps;
      end if;
   end process;
  
   --*******************************************************
   -- Counters for tracking # of samples compared
   -- For each comparision point (i.e. to determine if an edge has
   -- occurred after each IODELAY increment when read leveling),
   -- multiple samples are compared in order to average out the effects
   -- of jitter. If any one of these samples is different than the "old"
   -- sample corresponding to the previous IODELAY value, then an edge
   -- is declared to be detected. 
   --*******************************************************
   
   -- Two counters are used to keep track of # of samples compared, in 
   -- order to make it easier to meeting timing on these paths
   
   -- First counter counts the number of samples directly 
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            detect_edge_cnt0_r <= (others => '0') after (TCQ)*1 ps;
         else
            if (detect_edge_start_r = '1') then
               detect_edge_cnt0_r <= (others => '0') after (TCQ)*1 ps;
            elsif (found_edge_valid_r = '1') then
               detect_edge_cnt0_r <= detect_edge_cnt0_r + '1' after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            detect_edge_cnt1_en_r <= '0' after (TCQ)*1 ps;
         else
            if (((SIM_CAL_OPTION = "FAST_CAL") or (SIM_CAL_OPTION = "FAST_WIN_DETECT")) and (detect_edge_cnt0_r = X"001")) then
               -- Bypass multi-sampling for stage 1 when simulating with
               -- either fast calibration option, or with multi-sampling
               -- disabled
               detect_edge_cnt1_en_r <= '1' after (TCQ)*1 ps;
            elsif (detect_edge_cnt0_r = DETECT_EDGE_SAMPLE_CNT0) then
               detect_edge_cnt1_en_r <= '1' after (TCQ)*1 ps;
            else
               detect_edge_cnt1_en_r <= '0' after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;
   
   
   -- Counter #2
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            detect_edge_cnt1_r <= (others => '0') after (TCQ)*1 ps;
         else
            if (detect_edge_start_r = '1') then
               detect_edge_cnt1_r <= (others => '0') after (TCQ)*1 ps;
            elsif (detect_edge_cnt1_en_r = '1') then
               detect_edge_cnt1_r <= detect_edge_cnt1_r + '1' after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;
   
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            detect_edge_done_r <= '0' after (TCQ)*1 ps;
         else
            if (detect_edge_start_r = '1') then
               detect_edge_done_r <= '0' after (TCQ)*1 ps;
            elsif (((SIM_CAL_OPTION = "FAST_CAL") or (SIM_CAL_OPTION = "FAST_WIN_DETECT")) and (detect_edge_cnt1_r = X"001")) then
               -- Bypass multi-sampling for stage 1 when simulating with
               -- either fast calibration option, or with multi-sampling
               -- disabled
               detect_edge_done_r <= '1' after (TCQ)*1 ps;
            elsif (detect_edge_cnt1_r = DETECT_EDGE_SAMPLE_CNT1) then
               detect_edge_done_r <= '1' after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;
   
   --*****************************************************************
   -- Keep track of how long we've been in the same data eye
   -- (i.e. over how many taps we have not yet found an eye)
   --*****************************************************************

   -- An actual edge occurs when either: (1) difference in read data between
   -- current IODELAY tap and previous IODELAY tap (yes, this is confusing,
   -- since this condition is represented by found_edge_latched_r), (2) if
   -- the previous IODELAY tap read data was jittering (in which case it
   -- doesn't matter what the current IODELAY tap sample looks like)
   cal1_found_edge <= found_edge_latched_r or last_tap_jitter_r;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         -- Reset to 0 every time we begin processing a new DQS group
         if ((cal1_state_r = CAL1_IDLE) or (cal1_state_r = CAL1_NEXT_DQS)) then
            cnt_eye_size_r         <= "000" after (TCQ)*1 ps;
            found_stable_eye_r     <= '0' after (TCQ)*1 ps;
            last_tap_jitter_r      <= '0' after (TCQ)*1 ps;
            found_edge_latched_r   <= '0' after (TCQ)*1 ps;
            found_jitter_latched_r <= '0' after (TCQ)*1 ps;
	 elsif (not(cal1_state_r = CAL1_DETECT_EDGE)) then   
	    -- Reset "latched" signals before looking for an edge	 
            found_edge_latched_r   <= '0' after (TCQ)*1 ps;
            found_jitter_latched_r <= '0' after (TCQ)*1 ps;
         elsif (cal1_state_r = CAL1_DETECT_EDGE) then
            if (not(detect_edge_done_r = '1')) then
               -- While sampling: 
               -- Latch if we've found an edge (i.e. difference between current
               -- and previous IODELAY tap), and/or jitter (difference between
               -- current and previous sample - on the same IODELAY tap). It is
               -- possible to find an edge, and not jitter, but not vice versa
               if (found_edge_r = '1') then
		  found_edge_latched_r <= '1' after (TCQ)*1 ps;
	       end if;	  
               if (prev_found_edge_r = '1') then
		  found_jitter_latched_r <= '1' after (TCQ)*1 ps;
	       end if;	  
            else   
               -- Once the sample interval is over, it's time for housekeeping:

               -- If jitter found during current tap, record for future compares
               last_tap_jitter_r <= found_jitter_latched_r after (TCQ)*1 ps;

               -- If we found an edge, or if the previous IODELAY tap had jitter
               -- then reset stable window counter to 0 - obviously we're not in
               -- the data valid window. Note that we care about whether jitter
               -- occurred during the previous tap because it's possible to not
               -- find an edge (in terms of how it's determined in found_edge_r)
               -- even though jitter occured during the previous tap. 		 
               if (cal1_found_edge = '1') then
                  cnt_eye_size_r <= "000" after (TCQ)*1 ps;
                  found_stable_eye_r <= '0' after (TCQ)*1 ps;
               else
                  -- Otherwise, everytime we look for an edge, and don't find
                  -- one, increment counter until minimum eye size encountered - 
                  -- note this counter does not track the eye size, but only if 
                  -- it exceeded minimum size
                  if (to_integer(unsigned(cnt_eye_size_r)) = (MIN_EYE_SIZE-1)) then
                     found_stable_eye_r <= '1' after (TCQ)*1 ps;
                  else
                     found_stable_eye_r <= '0' after (TCQ)*1 ps;
                     cnt_eye_size_r <= cnt_eye_size_r + '1' after (TCQ)*1 ps;
                  end if;
               end if;
            end if;   
         end if;
      end if;
   end process;
   
   --*****************************************************************
   -- keep track of edge tap counts found, and current capture clock
   -- tap count
   --*****************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            idel_tap_cnt_cpt_r <= (others => '0') after (TCQ)*1 ps;
            idel_tap_limit_cpt_r <= '0' after (TCQ)*1 ps;
         else
            if (new_cnt_cpt_r = '1') then
               idel_tap_cnt_cpt_r <= "00000" after (TCQ)*1 ps;
               idel_tap_limit_cpt_r <= '0' after (TCQ)*1 ps;
            elsif (cal1_dlyce_cpt_r = '1') then
               if (cal1_dlyinc_cpt_r = '1') then
                  idel_tap_cnt_cpt_r <= idel_tap_cnt_cpt_r + '1' after (TCQ)*1 ps;
               else
                  -- Assert if tap limit has been reached
                  idel_tap_cnt_cpt_r <= idel_tap_cnt_cpt_r - '1' after (TCQ)*1 ps;
               end if;
               if ((to_integer(unsigned(idel_tap_cnt_cpt_r)) = (IODELAY_TAP_LEN-2)) and (cal1_dlyinc_cpt_r = '1')) then
                  idel_tap_limit_cpt_r <= '1' after (TCQ)*1 ps;
               else
                  idel_tap_limit_cpt_r <= '0' after (TCQ)*1 ps;
               end if;
            end if;
         end if;
      end if;
   end process;
   
   --*****************************************************************
   -- keep track of when DQ tap limit is reached 
   --*****************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            idel_tap_limit_dq_r <= '0' after (TCQ)*1 ps;
         else
            if (new_cnt_cpt_r = '1') then
               idel_tap_limit_dq_r <= '0' after (TCQ)*1 ps;
            elsif (to_integer(unsigned(cal1_dq_tap_cnt_r)) = (IODELAY_TAP_LEN-1)) then
               idel_tap_limit_dq_r <= '1' after (TCQ)*1 ps;
            end if;
         end if;
      end if;
   end process;
  
   --*****************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            cal1_cnt_cpt_r 	<= (others => '0') after (TCQ)*1 ps;
            cal1_dlyce_cpt_r 	<= '0' after (TCQ)*1 ps;
            cal1_dlyinc_cpt_r 	<= '0' after (TCQ)*1 ps;
            cal1_dq_tap_cnt_r 	<= "00000" after (TCQ)*1 ps;
            cal1_dq_taps_inc_r 	<= '0' after (TCQ)*1 ps;
            cal1_prech_req_r	<= '0' after (TCQ)*1 ps;
            cal1_store_sr_req_r <= '0' after (TCQ)*1 ps;
            cal1_state_r 	<= CAL1_IDLE after (TCQ)*1 ps;
            cnt_idel_dec_cpt_r 	<= "XXXXXX" after (TCQ)*1 ps;
            cnt_idel_inc_cpt_r 	<= "XXXXX" after (TCQ)*1 ps;
            cnt_idel_skip_idel_r<= "XXXXX" after (TCQ)*1 ps;
            detect_edge_start_r <= '0' after (TCQ)*1 ps;
            found_dq_edge_r 	<= '0' after (TCQ)*1 ps;
            found_two_edge_r 	<= '0' after (TCQ)*1 ps;
            found_first_edge_r 	<= '0' after (TCQ)*1 ps;
            found_second_edge_r <= '0' after (TCQ)*1 ps;
            first_edge_taps_r   <= "XXXXX" after (TCQ)*1 ps;
            new_cnt_cpt_r 	<= '0' after (TCQ)*1 ps;
            rdlvl_done_1(0) 	<= '0' after (TCQ)*1 ps;
            rdlvl_err_2(0) 	<= '0' after (TCQ)*1 ps;
            right_edge_taps_r   <= "XXXXX" after (TCQ)*1 ps;
            second_edge_taps_r  <= "XXXXX" after (TCQ)*1 ps;
            second_edge_dq_taps_r <= "XXXXX" after (TCQ)*1 ps;
         else
            -- default (inactive) states for all "pulse" outputs
            cal1_prech_req_r 	<= '0' after (TCQ)*1 ps;
            cal1_dlyce_cpt_r 	<= '0' after (TCQ)*1 ps;
            cal1_dlyinc_cpt_r 	<= '0' after (TCQ)*1 ps;
            cal1_store_sr_req_r <= '0' after (TCQ)*1 ps;
            detect_edge_start_r <= '0' after (TCQ)*1 ps;
            new_cnt_cpt_r 	<= '0' after (TCQ)*1 ps;   
            
            case (cal1_state_r) is

               when CAL1_IDLE =>
                  if ((rdlvl_start(0)) = '1') then
                     if (SIM_CAL_OPTION = "SKIP_CAL") then
                        -- "Hardcoded" calibration option  
                        cnt_idel_skip_idel_r <= std_logic_vector(to_unsigned(TBY4_TAPS, 5)) after (TCQ)*1 ps;
                        cal1_state_r         <= CAL1_SKIP_RDLVL_INC_IDEL after (TCQ)*1 ps;
                     else
                        new_cnt_cpt_r <= '1' after (TCQ)*1 ps;
                        cal1_state_r <= CAL1_NEW_DQS_WAIT after (TCQ)*1 ps;
                     end if;
                  end if;
		  
               -- Wait for various MUXes associated with a new DQS group to
               -- change - also gives time for the read data shift register
               -- to load with the updated data for the new DQS group               
               when CAL1_NEW_DQS_WAIT =>
                  if (pipe_wait = '0') then
                     cal1_state_r <= CAL1_IDEL_STORE_FIRST after (TCQ)*1 ps;
                  end if;          
       
               -- When first starting calibration for a DQS group, save the
               -- current value of the read data shift register, and use this
               -- as a reference. Note that for the first iteration of the
               -- edge detection loop, we will in effect be checking for an edge
               -- at IODELAY taps = 0 - normally, we are comparing the read data
               -- for IODELAY taps = N, with the read data for IODELAY taps = N-1
               -- An edge can only be found at IODELAY taps = 0 if the read data
               -- is changing during this time (possible due to jitter)
               when CAL1_IDEL_STORE_FIRST =>
                  cal1_store_sr_req_r <= '1' after (TCQ)*1 ps;
                  detect_edge_start_r <= '1' after (TCQ)*1 ps;
                  if (store_sr_done_r = '1') then
                     if (cal1_dq_taps_inc_r = '1') then		-- if using dq taps
                        cal1_state_r <= CAL1_DETECT_EDGE_DQ after (TCQ)*1 ps;
                     else
                        cal1_state_r <= CAL1_DETECT_EDGE after (TCQ)*1 ps;
                     end if;
                  end if;		 

               -- Check for presence of data eye edge		  
               when CAL1_DETECT_EDGE =>
                  if (detect_edge_done_r = '1') then
		     if (cal1_found_edge = '1') then	  
                        -- Sticky bit - asserted after we encounter an edge, although
                        -- the current edge may not be considered the "first edge" this
                        -- just means we found at least one edge			  
                        found_first_edge_r <= '1' after (TCQ)*1 ps;
                        -- For use during "low-frequency" edge detection: 
                        -- Prevent underflow if we find an edge right away - at any
                        -- rate, if we do, and later we don't find a second edge by
                        -- using DQ taps, then we're running at a very low
                        -- frequency, and we really don't care about whether the
                        -- first edge found is a "left" or "right" edge - we have
                        -- more margin to absorb any inaccuracy
			if (found_first_edge_r = '0') then
			   if (idel_tap_cnt_cpt_r = "00000") then
			      right_edge_taps_r <= "00000" after (TCQ)*1 ps;
		           else
			      right_edge_taps_r <= (idel_tap_cnt_cpt_r - '1') after (TCQ)*1 ps;
		           end if;   
              		end if;   

                        -- Both edges of data valid window found:
                        -- If we've found a second edge after a region of stability
                        -- then we must have just passed the second ("right" edge of
                        -- the window. Record this second_edge_taps = current tap-1, 
                        -- because we're one past the actual second edge tap, where 
                        -- the edge taps represent the extremes of the data valid 
                        -- window (i.e. smallest & largest taps where data still valid
                        if ((found_first_edge_r and found_stable_eye_r) = '1') then
                           found_second_edge_r <= '1' after (TCQ)*1 ps;
                           second_edge_taps_r <= idel_tap_cnt_cpt_r - '1' after (TCQ)*1 ps;
                           cal1_state_r <= CAL1_CALC_IDEL after (TCQ)*1 ps;
                        else
                           -- Otherwise, an edge was found (just not the "second" edge)
                           -- then record current tap count - this may be the "left"
                           -- edge of the current data valid window
                           first_edge_taps_r <= idel_tap_cnt_cpt_r after (TCQ)*1 ps;
                           -- If we haven't run out of taps, then keep incrementing        
                           if (idel_tap_limit_cpt_r = '0') then
                              cal1_state_r <= CAL1_IDEL_STORE_OLD after (TCQ)*1 ps;
  		           else
                              -- If we ran out of taps moving the capture clock, and we
                              -- haven't found second edge, then try to find edges by
                              -- moving the DQ IODELAY taps
                              cal1_state_r <= CAL1_RST_CPT after (TCQ)*1 ps;
                              -- Using this counter to reset the CPT taps to zero
                              -- taps + any PD taps
                              cnt_idel_dec_cpt_r <= std_logic_vector(to_unsigned((IODELAY_TAP_LEN-1), 6)) after (TCQ)*1 ps;
                           end if;
                        end if;
		     else
                        -- Otherwise, if we haven't found an edge.... 
                        if (idel_tap_limit_cpt_r = '0') then
                        -- If we still have taps left to use, then keep incrementing
                           cal1_state_r <= CAL1_IDEL_STORE_OLD after (TCQ)*1 ps;
                        else
                           -- If we ran out of taps moving the capture clock, and we
                           -- haven't found even one or second edge, then try to find
                           -- edges by moving the DQ IODELAY taps
                           cal1_state_r <= CAL1_RST_CPT after (TCQ)*1 ps;
                           -- Using this counter to reset the CPT taps to zero 
                           -- taps + any PD taps
                           cnt_idel_dec_cpt_r <= std_logic_vector(to_unsigned((IODELAY_TAP_LEN-1), 6)) after (TCQ)*1 ps;
                        end if;
                     end if;                                            
                  end if;
               -- Store the current read data into the read data shift register
               -- before incrementing the tap count and doing this again		  
               when CAL1_IDEL_STORE_OLD =>
                  cal1_store_sr_req_r <= '1' after (TCQ)*1 ps;
                  if (store_sr_done_r = '1') then
                     if (cal1_dq_taps_inc_r = '1') then		-- if using dq taps
                        cal1_state_r <= CAL1_IDEL_INC_DQ after (TCQ)*1 ps;
                     else
                        cal1_state_r <= CAL1_IDEL_INC_CPT after (TCQ)*1 ps;
                     end if;
                  end if;
               
               -- Increment IDELAY for both capture and resync clocks		  
               when CAL1_IDEL_INC_CPT =>
                  cal1_dlyce_cpt_r <= '1' after (TCQ)*1 ps;
                  cal1_dlyinc_cpt_r <= '1' after (TCQ)*1 ps;
                  cal1_state_r <= CAL1_IDEL_INC_CPT_WAIT after (TCQ)*1 ps;
               
               -- Wait for IDELAY for both capture and resync clocks, and internal
               -- nodes within ISERDES to settle, before checking again for an edge  
               when CAL1_IDEL_INC_CPT_WAIT =>
                  detect_edge_start_r <= '1' after (TCQ)*1 ps;
                  if (pipe_wait = '0') then
                     cal1_state_r <= CAL1_DETECT_EDGE after (TCQ)*1 ps;
                  end if;

               -- Calculate final value of IDELAY. At this point, one or both
               -- edges of data eye have been found, and/or all taps have been
               -- exhausted looking for the edges
               -- NOTE: We're calculating the amount to decrement by, not the
               --  absolute setting for DQ IDELAY
               when CAL1_CALC_IDEL =>
                  --*******************************************************
                  -- Now take care of IDELAY for capture clock:
                  -- Explanation of calculations:
                  --  1. If 2 edges found, final IDELAY value =
                  --       TAPS = FE_TAPS + ((SE_TAPS-FE_TAPS)/2)
                  --  2. If 1 edge found, final IDELAY value is either:
                  --       TAPS = FE_TAPS - TBY4_TAPS, or
                  --       TAPS = FE_TAPS + TBY4_TAPS
                  --     Depending on which is achievable without overflow
                  --     (and with bias toward having fewer taps)
                  --  3. If no edges found, then final IDELAY value is:
                  --       TAPS = 15
                  --     This is the best we can do with the information we
                  --     have it guarantees we have at least 15 taps of
                  --     margin on either side of calibration point 
                  -- How the final IDELAY tap is reached:
                  --  1. If 2 edges found, current tap count = SE_TAPS + 1
                  --       * Decrement by [(SE_TAPS-FE_TAPS)/2] + 1
                  --  2. If 1 edge found, current tap count = 31
                  --       * Decrement by 31 - FE_TAPS - TBY4, or
                  --       * Decrement by 31 - FE_TAPS + TBY4
                  --  3. If no edges found
                  --       * Decrement by 16
                  --*******************************************************
                  
                  -- CASE1: If 2 edges found.
                  -- Only CASE1 will be true. Due to the low frequency fixes
                  -- the SM will not transition to this state when two edges are not
                  -- found. 		  
                  if (found_second_edge_r = '1') then
                     -- SYNTHESIS_NOTE: May want to pipeline this operation
                     -- over multiple cycles for better timing. If so, need
                     -- to add delay state in CAL1 state machine 
                     cnt_idel_dec_cpt_r <=  calc_cnt_idel_dec_cpt(second_edge_taps_r,first_edge_taps_r) after (TCQ)*1 ps;

                  -- CASE 2: 1 edge found 
                  -- NOTE: Need to later add logic to prevent decrementing below 0		     
                  elsif (found_first_edge_r = '1') then
                     if ( to_integer(unsigned(first_edge_taps_r)) >= (IODELAY_TAP_LEN/2) and 
		          ((to_integer(unsigned(first_edge_taps_r)) + TBY4_TAPS) < (IODELAY_TAP_LEN - 1)) ) then
                        -- final IDELAY value = [FIRST_EDGE_TAPS-CLK_MEM_PERIOD/2]
                        cnt_idel_dec_cpt_r <= std_logic_vector(to_unsigned(((IODELAY_TAP_LEN-1) - 
					                       to_integer(unsigned(first_edge_taps_r)) - TBY4_TAPS), 6)) after (TCQ)*1 ps;
                     else
                        -- final IDELAY value = [FIRST_EDGE_TAPS+CLK_MEM_PERIOD/2]	     
                        cnt_idel_dec_cpt_r <= std_logic_vector(to_unsigned(((IODELAY_TAP_LEN-1) - 
					                       to_integer(unsigned(first_edge_taps_r)) + TBY4_TAPS), 6)) after (TCQ)*1 ps;
                     end if;
                  else
                     -- CASE 3: No edges found, decrement by half tap length
                     cnt_idel_dec_cpt_r <= std_logic_vector(to_unsigned(IODELAY_TAP_LEN/2, 6)) after (TCQ)*1 ps;
                  end if;
                  -- Now use the value we just calculated to decrement CPT taps
                  -- to the desired calibration point		  
                  cal1_state_r <= CAL1_IDEL_DEC_CPT after (TCQ)*1 ps;

               -- decrement capture clock IDELAY for final adjustment - center
               -- capture clock in middle of data eye. This adjustment will occur
               -- only when both the edges are found usign CPT taps. Must do this
               -- incrementally to avoid clock glitching (since CPT drives clock
               -- divider within each ISERDES)		  
               when CAL1_IDEL_DEC_CPT =>
                  cal1_dlyce_cpt_r <= '1' after (TCQ)*1 ps;
                  cal1_dlyinc_cpt_r <= '0' after (TCQ)*1 ps;
                  -- once adjustment is complete, we're done with calibration for
                  -- this DQS, repeat for next DQS		  
                  cnt_idel_dec_cpt_r <= cnt_idel_dec_cpt_r - "000001" after (TCQ)*1 ps;
                  if ((cnt_idel_dec_cpt_r) = "1") then
                     cal1_state_r <= CAL1_IDEL_PD_ADJ after (TCQ)*1 ps;
                  end if;
                             
	       -- Determine whether we're done, or have more DQS's to calibrate
               -- Also request precharge after every byte, as appropriate		              
               when CAL1_NEXT_DQS =>
                  cal1_prech_req_r   <= '1' after (TCQ)*1 ps;
                  -- Prepare for another iteration with next DQS group
                  found_dq_edge_r    <= '0' after (TCQ)*1 ps;
                  found_two_edge_r   <= '0' after (TCQ)*1 ps;
                  found_first_edge_r <= '0' after (TCQ)*1 ps;
                  found_second_edge_r<= '0' after (TCQ)*1 ps;
                  cal1_dq_taps_inc_r <= '0' after (TCQ)*1 ps;

                  -- Wait until precharge that occurs in between calibration of
                  -- DQS groups is finished		  
                  if (prech_done = '1') then
                     if ((to_integer(unsigned(cal1_cnt_cpt_r)) >= (DQS_WIDTH-1)) or (SIM_CAL_OPTION = "FAST_CAL")) then
                        cal1_state_r <= CAL1_DONE after (TCQ)*1 ps;
                     else
			-- Process next DQS group     
                        new_cnt_cpt_r <= '1' after (TCQ)*1 ps;
                        cal1_dq_tap_cnt_r <= "00000" after (TCQ)*1 ps;
                        cal1_cnt_cpt_r <= cal1_cnt_cpt_r + '1' after (TCQ)*1 ps;
                        cal1_state_r <= CAL1_NEW_DQS_WAIT after (TCQ)*1 ps;
                     end if;
                  end if;
               
               when CAL1_RST_CPT =>        		       
                  cal1_dq_taps_inc_r <= '1' after (TCQ)*1 ps;

                  -- If we never found even one edge by varying CPT taps, then
                  -- as an approximation set first edge tap indicators to 31. This
                  -- will be used later in the low-frequency portion of calibration
		  if (found_first_edge_r = '0') then 
                    first_edge_taps_r <= std_logic_vector(to_unsigned((IODELAY_TAP_LEN- 1), 5)) after (TCQ)*1 ps;
                    right_edge_taps_r <= std_logic_vector(to_unsigned((IODELAY_TAP_LEN- 1), 5)) after (TCQ)*1 ps;
	          end if;
          
                  if ((cnt_idel_dec_cpt_r) = "000000") then
                     -- once the decerement is done. Go back to the CAL1_NEW_DQS_WAIT
                     -- state to load the correct data for comparison and to start
                     -- with DQ taps.			  
                     cal1_state_r <= CAL1_NEW_DQS_WAIT after (TCQ)*1 ps;
                     -- Start with a DQ tap value of 0
                     cal1_dq_tap_cnt_r <= "00000" after (TCQ)*1 ps;
                  else
                     -- decrement both CPT taps to initial value. 
                     -- DQ IODELAY taps will be used to find the edges
                     cal1_dlyce_cpt_r   <= '1' after (TCQ)*1 ps;
                     cal1_dlyinc_cpt_r  <= '0' after (TCQ)*1 ps;
                     cnt_idel_dec_cpt_r <= cnt_idel_dec_cpt_r - "000001" after (TCQ)*1 ps;
                  end if;
                              
	       -- When two edges are not found using CPT taps, finding edges
               -- using DQ taps.               
               when CAL1_DETECT_EDGE_DQ =>
	          if (detect_edge_done_r = '1') then
                     -- when using DQ taps make sure the window size is atleast 10.
                     -- DQ taps used only in low frequency designs. 		       
                     if (((found_edge_r)) = '1' and ((found_first_edge_r = '0') or (tby4_r > "000101"))) then
                        -- Sticky bit - asserted after we encounter first edge
                        -- If we've found a second edge(using dq taps) after a region 
                        -- of stability ( using tby4_r count) then this must be the 
                        -- second ("using dq taps") edge of the window 			  
                        found_dq_edge_r <= '1' after (TCQ)*1 ps;
                        found_two_edge_r <= found_first_edge_r after (TCQ)*1 ps;
                        cal1_state_r <= CAL1_CALC_IDEL_DQ after (TCQ)*1 ps;
                        -- Recording the dq taps when an edge is found. Account for
                        -- the case when an edge is found at DQ IODELAY = 0 taps -
                        -- possible because of jitter
			if (not(cal1_dq_tap_cnt_r = "00000")) then
                           second_edge_dq_taps_r <= (cal1_dq_tap_cnt_r - '1') after (TCQ)*1 ps;
                        else
                           second_edge_dq_taps_r <= "00000" after (TCQ)*1 ps;
 		        end if;  
                     else
                        -- No more DQ taps to increment - set left edge tap distance
                        -- to 31 as an approximation, and move on to figuring out
                        -- what needs to be done to center (or approximately center)
                        -- sampling point in middle of read window
		        if (idel_tap_limit_dq_r = '1') then 
                           cal1_state_r <= CAL1_CALC_IDEL_DQ after (TCQ)*1 ps;
                           second_edge_dq_taps_r <= std_logic_vector(to_unsigned((IODELAY_TAP_LEN- 1), 5)) after (TCQ)*1 ps;
                        else 
                           cal1_state_r <= CAL1_IDEL_STORE_OLD after (TCQ)*1 ps;
		        end if;   
                     end if;
	          end if;   

               when CAL1_IDEL_INC_DQ =>
                  cal1_dq_tap_cnt_r <= cal1_dq_tap_cnt_r + "00001" after (TCQ)*1 ps;
                  cal1_state_r <= CAL1_IDEL_INC_DQ_WAIT after (TCQ)*1 ps;

               -- Wait for IDELAY for DQ, and internal nodes within ISERDES
               -- to settle, before checking again for an edge   		  
               when CAL1_IDEL_INC_DQ_WAIT =>
                  detect_edge_start_r <= '1' after (TCQ)*1 ps;
                  if (pipe_wait = '0') then
                     cal1_state_r <= CAL1_DETECT_EDGE_DQ after (TCQ)*1 ps;
                  end if;

               when CAL1_CALC_IDEL_DQ =>
                  cal1_state_r <= CAL1_IDEL_INC_DQ_CPT after (TCQ)*1 ps;
                  cal1_dq_tap_cnt_r <= "00000" after (TCQ)*1 ps;
                  cnt_idel_inc_cpt_r <= "00000" after (TCQ)*1 ps;
                  --------------------------------------------------------------
                  -- Determine whether to move DQ or CPT IODELAY taps to best
                  -- position sampling point in data valid window. In general,
                  -- we want to avoid setting DQ IODELAY taps to a nonzero value
                  -- in order to avoid adding IODELAY pattern-dependent jitter.
                  --------------------------------------------------------------
                  -- At this point, we have the following products of calibration:
                  --   1. right_edge_taps_r: distance in IODELAY taps from start 
                  --      position to right margin of current data valid window.
                  --      Measured using CPT IODELAY. 
                  --   2. first_edge_taps_r: distance in IODELAY taps from start 
                  --      position to start of left edge of next data valid window. 
                  --      Note that {first_edge_taps_r - right_edge_taps_r} = width 
                  --      of the uncertainty or noise region between consecutive 
                  --      data eyes. Measured using CPT IODELAY. 
                  --   3. second_edge_dq_taps_r: distance in IODELAY taps from left 
                  --      edge of current data valid window. Measured using DQ
                  --      IODELAY. 
                  --   4. tby4_r: half the width of the eye as calculated by
                  --      {second_edge_dq_taps_r + first_edge_taps_r}
                  -- ------------------------------------------------------------
                  -- If two edges are found (one each from moving CPT, and DQ 
                  -- IODELAYs), then the following cases are considered for setting
                  -- final DQ and CPT delays (in the following order):
                  --   1. second_edge_dq_taps_r <= tby4_r:
                  --       * incr. CPT taps by {second_edge_dq_taps_r - tby4_r}
                  --      this means that there is more taps available to the right
                  --      of the starting position
                  --   2. first_edge_taps_r + tby4_r <= 31 taps (IODELAY length)
                  --       * incr CPT taps by {tby4_r}
                  --      this means we have enough CPT taps available to us to
                  --      position the sampling point in the middle of the next
                  --      sampling window. Alternately, we could have instead
                  --      positioned ourselves in the middle of the current window
                  --      by using DQ taps, but if possible avoid using DQ taps
                  --      because of pattern-dependent jitter
                  --   3. otherwise, our only recourse is to move DQ taps in order
                  --      to center the sampling point in the middle of the current
                  --      data valid window
                  --       * set DQ taps to {tby4_r - right_edge_taps_r}
                  -- ------------------------------------------------------------
                  -- Note that the case where only one edge is found, either using
                  -- CPT or DQ IODELAY taps is a subset of the above 3 cases, which
                  -- can be approximated by setting either right_edge_taps_r = 31, 
                  -- or second_edge_dq_taps_r = 31. This doesn't result in an exact
                  -- centering, but this will only occur at an extremely low
                  -- frequency, and exact centering is not required
                  -- ------------------------------------------------------------
                  if (('0' & second_edge_dq_taps_r) <= tby4_r) then
                     cnt_idel_inc_cpt_r <= subtract_vectors(tby4_r, second_edge_dq_taps_r) after (TCQ)*1 ps;
                  elsif ((('0' & first_edge_taps_r) + tby4_r) <= std_logic_vector(to_unsigned(IODELAY_TAP_LEN - 1, 6))) then
                     cnt_idel_inc_cpt_r <= add_vectors(tby4_r, first_edge_taps_r) after (TCQ)*1 ps;
	          else
                     cal1_dq_tap_cnt_r <= subtract_vectors(tby4_r, right_edge_taps_r) after (TCQ)*1 ps;
                  end if;

               -- increment capture clock IDELAY for final adjustment - center
               -- capture clock in middle of data eye. This state transition will
               -- occur when only one edge or no edge is found using CPT taps			                    
               when CAL1_IDEL_INC_DQ_CPT =>
                  if (cnt_idel_inc_cpt_r = "00000") then
                     -- once adjustment is complete, we're done with calibration for
                     -- this DQS, repeat for next DQS.     			  
                     cal1_state_r <= CAL1_IDEL_PD_ADJ after (TCQ)*1 ps;
                  else
                     cal1_dlyce_cpt_r <= '1' after (TCQ)*1 ps;
                     cal1_dlyinc_cpt_r <= '1' after (TCQ)*1 ps;
                     cnt_idel_inc_cpt_r <= cnt_idel_inc_cpt_r - '1' after (TCQ)*1 ps;
                  end if;

               when CAL1_IDEL_PD_ADJ =>
	          -- If CPT is < than half the required PD taps then move the
                  -- CPT taps the DQ taps togather 		       
                  if (to_integer(unsigned(idel_tap_cnt_cpt_r)) < PD_HALF_TAP) then
                     cal1_dlyce_cpt_r <= '1' after (TCQ)*1 ps;
                     cal1_dlyinc_cpt_r <= '1' after (TCQ)*1 ps;
                     cal1_dq_tap_cnt_r <= cal1_dq_tap_cnt_r + "00001" after (TCQ)*1 ps;
                  else
                     cal1_state_r <= CAL1_NEXT_DQS after (TCQ)*1 ps;
                  end if;

               -- Done with this stage of calibration
               -- if used, allow DEBUG_PORT to control taps               
               when CAL1_DONE =>
                  rdlvl_done_1(0) <= '1' after (TCQ)*1 ps;

               -- Used for simulation only - hardcode IDELAY values for all rdlvl
               -- associated IODELAYs - kind of a cheesy way of providing for
               -- simulation, but I don't feel like modifying PHY_DQ_IOB to add
               -- extra parameters just for simulation. This part shouldn't get
               -- synthesized.               
               when CAL1_SKIP_RDLVL_INC_IDEL =>
                  cal1_dlyce_cpt_r     <= '1' after (TCQ)*1 ps;
                  cal1_dlyinc_cpt_r    <= '1' after (TCQ)*1 ps;
                  cnt_idel_skip_idel_r <= cnt_idel_skip_idel_r - '1' after (TCQ)*1 ps;
                  if (cnt_idel_skip_idel_r = "00001") then
                     cal1_state_r <= CAL1_DONE after (TCQ)*1 ps;
                  end if;

	       when others =>
	          null;

            end case;
         end if;
      end if;
   end process;
   
   --***************************************************************************
   -- Calculates the window size during calibration.
   -- Value is used only when two edges are not found using the CPT taps.    
   -- cal1_dq_tap_cnt_r deceremented by 1 to account for the correct window.  
   --***************************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (cal1_dq_tap_cnt_r > "00000") then
            tby4_r <= std_logic_vector(unsigned(('0' & cal1_dq_tap_cnt_r) + ('0' & right_edge_taps_r) - 1) srl 1) after (TCQ)*1 ps;
	 else	 
            tby4_r <= std_logic_vector(unsigned(('0' & cal1_dq_tap_cnt_r) + ('0' & right_edge_taps_r)) srl 1) after (TCQ)*1 ps;
         end if;   
      end if;
   end process;
            
   --***************************************************************************
   -- Stage 2 calibration: Read Enable
   -- Read enable calibration determines the "round-trip" time (in # of CLK
   -- cycles) between when a read command is issued by the controller, and
   -- when the corresponding read data is synchronized by into the CLK domain
   --***************************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         rd_active_r <= rdlvl_rd_active after (TCQ)*1 ps;
         rd_active_posedge_r <= rdlvl_rd_active and not(rd_active_r) after (TCQ)*1 ps;
      end if;
   end process;
   
   --*****************************************************************
   -- Expected data pattern when properly aligned through bitslip
   -- Based on pattern of ({rise,fall}) =
   --   0xF, 0x0, 0xA, 0x5, 0x5, 0xA, 0x9, 0x6
   -- Examining only the LSb of each DQS group, pattern is =
   --   bit3: 1, 0, 1, 0, 0, 1, 1, 0
   --   bit2: 1, 0, 0, 1, 1, 0, 0, 1
   --   bit1: 1, 0, 1, 0, 0, 1, 0, 1
   --   bit0: 1, 0, 0, 1, 1, 0, 1, 0
   -- Change the hard-coded pattern below accordingly as RD_SHIFT_LEN
   -- and the actual training pattern contents change
   --*****************************************************************
   
   pat_rise0(3) <= "10";
   pat_fall0(3) <= "01";
   pat_rise1(3) <= "11";
   pat_fall1(3) <= "00";
   
   pat_rise0(2) <= "11";
   pat_fall0(2) <= "00";
   pat_rise1(2) <= "00";
   pat_fall1(2) <= "11";
   
   pat_rise0(1) <= "10";
   pat_fall0(1) <= "01";
   pat_rise1(1) <= "10";
   pat_fall1(1) <= "01";
   
   pat_rise0(0) <= "11";
   pat_fall0(0) <= "00";
   pat_rise1(0) <= "01";
   pat_fall1(0) <= "10";
   
   --*****************************************************************
   -- Do not need to look at sr_valid_r - the pattern can occur anywhere
   -- during the shift of the data shift register - as long as the order
   -- of the bits in the training sequence is correct. Each bit of each
   -- byte is compared to expected pattern - this is not strictly required.
   -- This was done to prevent (and "drastically decrease") the chance that
   -- invalid data clocked in when the DQ bus is tri-state (along with a
   -- combination of the correct data) will resemble the expected data
   -- pattern. A better fix for this is to change the training pattern and/or
   -- make the pattern longer.
   --*****************************************************************
   gen_pat_match : for pt_i in 0 to  DRAM_WIDTH-1 generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (sr_rise0_r(pt_i) = pat_rise0(pt_i mod 4)) then
               pat_match_rise0_r(pt_i) <= '1' after (TCQ)*1 ps;
            else
               
               pat_match_rise0_r(pt_i) <= '0' after (TCQ)*1 ps;
            end if;
            if (sr_fall0_r(pt_i) = pat_fall0(pt_i mod 4)) then
               pat_match_fall0_r(pt_i) <= '1' after (TCQ)*1 ps;
            else
               
               pat_match_fall0_r(pt_i) <= '0' after (TCQ)*1 ps;
            end if;
            if (sr_rise1_r(pt_i) = pat_rise1(pt_i mod 4)) then
               pat_match_rise1_r(pt_i) <= '1' after (TCQ)*1 ps;
            else
               
               pat_match_rise1_r(pt_i) <= '0' after (TCQ)*1 ps;
            end if;
            if (sr_fall1_r(pt_i) = pat_fall1(pt_i mod 4)) then
               pat_match_fall1_r(pt_i) <= '1' after (TCQ)*1 ps;
            else
               pat_match_fall1_r(pt_i) <= '0' after (TCQ)*1 ps;
            end if;
         end if;
      end process;
      
   end generate;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         pat_match_rise0_and_r <= AND_BR(pat_match_rise0_r) after (TCQ)*1 ps;
         pat_match_fall0_and_r <= AND_BR(pat_match_fall0_r) after (TCQ)*1 ps;
         pat_match_rise1_and_r <= AND_BR(pat_match_rise1_r) after (TCQ)*1 ps;
         pat_match_fall1_and_r <= AND_BR(pat_match_fall1_r) after (TCQ)*1 ps;
         pat_data_match_r <= (pat_match_rise0_and_r and pat_match_fall0_and_r and 
			      pat_match_rise1_and_r and pat_match_fall1_and_r) after (TCQ)*1 ps;
      end if;
   end process;
   
   
   -- Generic counter to force wait after either bitslip value or
   -- CNT_RDEN is changed - allows time for old contents of read pipe
   -- to flush out
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            rden_wait_r <= '0' after (TCQ)*1 ps;
            cnt_rden_wait_r <= (others => '0') after (TCQ)*1 ps;
         else
            if (to_integer(unsigned(cal2_state_r)) /= CAL2_READ_WAIT) then
               rden_wait_r <= '1' after (TCQ)*1 ps;
               cnt_rden_wait_r <= (others => '0') after (TCQ)*1 ps;
            else
               cnt_rden_wait_r <= cnt_rden_wait_r + '1' after (TCQ)*1 ps;
               if (cnt_rden_wait_r = std_logic_vector(to_unsigned(RDEN_WAIT_CNT - 1, 3))) then
                  rden_wait_r <= '0' after (TCQ)*1 ps;
               end if;
            end if;
         end if;
      end if;
   end process;
   
   
   -- Register output for timing purposes
   process (clk)
   begin
      if (clk'event and clk = '1') then
         rd_bitslip_cnt <= cal2_rd_bitslip_cnt_r after (TCQ)*1 ps;
         rd_active_dly  <= cal2_rd_active_dly_r after (TCQ)*1 ps;
      end if;
   end process;

   --*****************************************************************
   -- Calibration state machine for determining polarity of ISERDES
   -- CLKDIV invert control on a per-DQS group basis
   -- This stage is used to choose the best phase of the resync clock 
   -- (on a per-DQS group basis) - "best phase" meaning the phase that
   -- results in the largest possible margin in the CLK-to-RSYNC clock
   -- domain transfer within the ISERDES. 
   -- NOTE: This stage actually takes place after stage 1 calibration.
   -- For the time being, the signal naming convention associated with
   -- this stage will be known as "cal_clkdiv". However, it really is 
   -- another stage of calibration - should be stage 2, and what is
   -- currently stage 2 (rd_active_dly calibration) should be changed
   -- to stage 3. 
   --*****************************************************************

   rd_clkdiv_inv     <= clkdiv_inv_r;
   dbg_rd_clkdiv_inv <= clkdiv_inv_r;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            cal_clkdiv_clkdiv_inv_r     <= '0' after (TCQ)*1 ps;
            cal_clkdiv_cnt_clkdiv_r     <= (others => '0') after (TCQ)*1 ps;      
            cal_clkdiv_dlyce_rsync_r    <= '0' after (TCQ)*1 ps;
            cal_clkdiv_dlyinc_rsync_r   <= '0' after (TCQ)*1 ps;
            cal_clkdiv_idel_rsync_inc_r <= '0' after (TCQ)*1 ps;
            cal_clkdiv_prech_req_r      <= '0' after (TCQ)*1 ps;
            cal_clkdiv_state_r          <= CAL_CLKDIV_IDLE after (TCQ)*1 ps;
            cal_clkdiv_store_sr_req_r   <= '0' after (TCQ)*1 ps;
            clkdiv_inv_r                <= (others => '0') after (TCQ)*1 ps;
            idel_tap_delta_rsync_r      <= "00000" after (TCQ)*1 ps;
            min_rsync_marg_r            <= "XXXXX" after (TCQ)*1 ps;
            new_cnt_clkdiv_r            <= '0' after (TCQ)*1 ps;
            pol_min_rsync_marg_r        <= '0' after (TCQ)*1 ps;    
            rdlvl_clkdiv_done_1         <= '0' after (TCQ)*1 ps;
         else
            -- default (inactive) states for all "pulse" outputs
            cal_clkdiv_dlyce_rsync_r  <= '0' after (TCQ)*1 ps;
            cal_clkdiv_prech_req_r    <= '0' after (TCQ)*1 ps;
            cal_clkdiv_store_sr_req_r <= '0' after (TCQ)*1 ps;
            new_cnt_clkdiv_r          <= '0' after (TCQ)*1 ps;
      
            case (cal_clkdiv_state_r) is       
        
               when CAL_CLKDIV_IDLE =>      
                  if (rdlvl_clkdiv_start = '1') then
                     if (SIM_CAL_OPTION = "SKIP_CAL") then
                        -- "Hardcoded" calibration option - for all DQS groups
                        -- do not invert rsync clock  
                        clkdiv_inv_r       <= (others => '0') after (TCQ)*1 ps;
                        cal_clkdiv_state_r <= CAL_CLKDIV_DONE after (TCQ)*1 ps;
                     else
                        new_cnt_clkdiv_r   <= '1' after (TCQ)*1 ps;
                        cal_clkdiv_state_r <= CAL_CLKDIV_NEW_DQS_WAIT after (TCQ)*1 ps;
                     end if;
                  end if;          

               -- Wait for various MUXes associated with a new DQS group to
               -- change - also gives time for the read data shift register
               -- to load with the updated data for the new DQS group
               when CAL_CLKDIV_NEW_DQS_WAIT =>
                  -- Reset smallest recorded margin
                  min_rsync_marg_r     <= "10000" after (TCQ)*1 ps;
                  pol_min_rsync_marg_r <= '0' after (TCQ)*1 ps;
                  if (pipe_wait = '0') then
                     cal_clkdiv_state_r <= CAL_CLKDIV_IDEL_STORE_REF after (TCQ)*1 ps;
                  end if;

               -- For a given polarity of the rsync clock, save the initial data
               -- value and use this as a reference to decide when an "edge" has 
               -- been encountered as the rsync clock is shifted
               when CAL_CLKDIV_IDEL_STORE_REF => 
                  cal_clkdiv_store_sr_req_r <= '1' after (TCQ)*1 ps;
                  if (store_sr_done_r = '1') then
                     cal_clkdiv_state_r <= CAL_CLKDIV_DETECT_EDGE after (TCQ)*1 ps;
                  end if;

               -- Check for presence of cpt-rsync clock synchronization "edge"
               -- This occurs when the captured data sequence changes as the RSYNC
               -- clock is shifted
               when CAL_CLKDIV_DETECT_EDGE =>
                  if (found_edge_valid_r = '1') then
                     -- If an edge found, or we've run out of taps looking for an 
                     -- edge, then:
                     --  (1) If the current margin found is the smallest, then
                     --      record it, as well as whether the CLKDIV was inverted
                     --      or not when this margin was measured
                     --  (2) Reverse the direction of IDEL_RSYNC_INC and/or invert
                     --      CLKDIV. We only invert CLKDIV if we just finished
                     --      incrementing the RSYNC IODELAY with CLKDIV not inverted
                     --  (3) Restore the original RSYNC clock delay in preparation
                     --      for either further measurements with the current DQS
                     --      group, or with the next DQS group       
                     if ((idel_tap_delta_rsync_r = "01111") or (found_edge_r = '1')) then
                        -- record the margin if it's the smallest found so far
                        if (idel_tap_delta_rsync_r < min_rsync_marg_r) then 
                           min_rsync_marg_r     <= idel_tap_delta_rsync_r after (TCQ)*1 ps;
                           pol_min_rsync_marg_r <= cal_clkdiv_clkdiv_inv_r after (TCQ)*1 ps;
                        end if;
                        -- Reverse direction of RSYNC inc/dec
                        cal_clkdiv_idel_rsync_inc_r <= not(cal_clkdiv_idel_rsync_inc_r) after (TCQ)*1 ps;
                        -- Check whether to also invert CLKDIV (see above comments)
                        if (cal_clkdiv_idel_rsync_inc_r = '1') then
                           cal_clkdiv_clkdiv_inv_r <= not(cal_clkdiv_clkdiv_inv_r) after (TCQ)*1 ps;
                           clkdiv_inv_r(to_integer(unsigned(cal_clkdiv_cnt_clkdiv_r))) <= not(cal_clkdiv_clkdiv_inv_r) after (TCQ)*1 ps;
                        end if;
                        -- Proceed to restoring original RSYNC clock delay
                        cal_clkdiv_state_r <= CAL_CLKDIV_IDEL_SET_MIDPT_RSYNC after (TCQ)*1 ps;
                     else
                        -- Otherwise, increment or decrement RSYNC phase, keep 
                        -- looking for an edge
                        cal_clkdiv_state_r <= CAL_CLKDIV_IDEL_INCDEC_RSYNC after (TCQ)*1 ps;
                     end if;
                  end if;
            
               -- Increment or decrement RSYNC IODELAY by 1
               when CAL_CLKDIV_IDEL_INCDEC_RSYNC =>
                  cal_clkdiv_dlyce_rsync_r     <= '1' after (TCQ)*1 ps;
                  cal_clkdiv_dlyinc_rsync_r    <= cal_clkdiv_idel_rsync_inc_r after (TCQ)*1 ps;
                  cal_clkdiv_state_r           <= CAL_CLKDIV_IDEL_INCDEC_RSYNC_WAIT after (TCQ)*1 ps;
                  idel_tap_delta_rsync_r       <= idel_tap_delta_rsync_r + '1' after (TCQ)*1 ps;
        
               -- Wait for RSYNC IODELAY, internal nodes within ISERDES, and 
               -- comparison logic shift register to settle, before checking again 
               -- for an edge
               when CAL_CLKDIV_IDEL_INCDEC_RSYNC_WAIT =>
                  if (pipe_wait = '0') then
                     cal_clkdiv_state_r <= CAL_CLKDIV_DETECT_EDGE after (TCQ)*1 ps;
                  end if;
        
               -- Restore RSYNC IODELAY to starting value
               when CAL_CLKDIV_IDEL_SET_MIDPT_RSYNC =>
                  -- Check case if we found an edge at starting tap (possible if 
                  -- we start at or near (near enough for jitter to affect us) 
                  -- the transfer point between the CLK and RSYNC clock domains
                  if (idel_tap_delta_rsync_r = "00000") then
                     cal_clkdiv_state_r <= CAL_CLKDIV_NEXT_CHECK after (TCQ)*1 ps;
                  else
                     cal_clkdiv_dlyce_rsync_r <= '1' after (TCQ)*1 ps;
                     -- inc/dec the RSYNC IODELAY in the opposite directionas
                     -- the just-finished search. This is a bit confusing, but note
                     -- that after finishing the search, we always invert 
                     -- IDEL_RSYNC_INC prior to arriving at this state  
                     cal_clkdiv_dlyinc_rsync_r <= cal_clkdiv_idel_rsync_inc_r after (TCQ)*1 ps;
                     idel_tap_delta_rsync_r <= idel_tap_delta_rsync_r - '1' after (TCQ)*1 ps;
                     if (idel_tap_delta_rsync_r = "00001") then
                       cal_clkdiv_state_r <= CAL_CLKDIV_NEXT_CHECK after (TCQ)*1 ps;
                     end if;
                  end if;
          
               -- Determine where to go next:
               --  (1) start looking for an edge in the other direction (CLKDIV
               --      polarity unchanged)
               --  (2) change CLKDIV polarity, resample and record a reference
               --      data value, and start looking for an edge
               --  (3) if we've searched all 4 possibilities (CLKDIV inverted, 
               --      not inverted, RSYNC shifted in left and right directions) 
               --      then decide which clock polarity is best to use for CLKDIV
               --      and proceed to next DQS
               -- NOTE: When we're comparing the current "state" (using both
               --       IDEL_RSYNC_INC and CLKDIV_INV) we are comparing what the
               --       next value of these signals will be, not what they were
               --       for the phase of edge detection just finished. Therefore
               --       IDEL_RSYNC_INC=0 and CLKDIV_INV=1 means we are about to
               --       decrement RSYNC with CLKDIV inverted (or in other words,
               --       we just searched with incrementing RSYNC, and CLKDIV not
               --       inverted)
               when CAL_CLKDIV_NEXT_CHECK =>
                  -- Wait for any residual change effects (CLKDIV inversion, RSYNC
                  -- IODELAY inc/dec) from previous state to finish
                  if (pipe_wait = '0') then
                     if ((cal_clkdiv_idel_rsync_inc_r = '0') and (cal_clkdiv_clkdiv_inv_r = '0')) then
                        -- If we've searched all 4 possibilities, then decide which
                        -- is the "best" clock polarity (which is to say, whichever 
                        -- polarity which DID NOT result in the minimum margin found) 
                        -- to use and proceed to next DQS
                        if (SIM_CAL_OPTION = "FAST_CAL") then
                           -- if simulating, and "shortcuts" for calibration enabled, 
                           -- apply results to all other elements (i.e. assume delay 
                           -- on all bits/bytes is same)
                           clkdiv_inv_r <= (others => not(pol_min_rsync_marg_r)) after (TCQ)*1 ps;
                        else
                           -- Otherwise, apply result only to current DQS group
                           clkdiv_inv_r(to_integer(unsigned(cal_clkdiv_cnt_clkdiv_r))) <= not(pol_min_rsync_marg_r) after (TCQ)*1 ps;
                        end if;                           
                        cal_clkdiv_state_r <= CAL_CLKDIV_NEXT_DQS after (TCQ)*1 ps;
                     elsif ((cal_clkdiv_idel_rsync_inc_r = '0') and (cal_clkdiv_clkdiv_inv_r = '1')) then
                        -- If we've finished searching with CLKDIV not inverted
                        -- Now store a new reference value for edge-detection
                        -- comparison purposes and begin looking for an edge
                        cal_clkdiv_state_r <= CAL_CLKDIV_IDEL_STORE_REF after (TCQ)*1 ps;
                     else
                        -- Otherwise, we've just finished checking by decrementing
                        -- RSYNC. Now look for an edge by incrementing RSYNC 
                        -- (keep the CLKDIV polarity unchanged)  
                        cal_clkdiv_state_r <= CAL_CLKDIV_DETECT_EDGE after (TCQ)*1 ps;       
                     end if;
                  end if;

               -- Determine whether we're done, or have more DQS's to calibrate
               -- Also request precharge after every byte
               when CAL_CLKDIV_NEXT_DQS =>
                  cal_clkdiv_prech_req_r <= '1' after (TCQ)*1 ps;

                  -- Wait until precharge that occurs in between calibration of
                  -- DQS groups is finished
                  if (prech_done = '1') then
                     if (((to_integer(unsigned(cal_clkdiv_cnt_clkdiv_r))) >= DQS_WIDTH-1) or (SIM_CAL_OPTION = "FAST_CAL")) then
                        -- If FAST_CAL enabled, only cal first DQS group - the results
                        -- (aka CLKDIV invert) have been applied to all DQS groups
                        cal_clkdiv_state_r <= CAL_CLKDIV_DONE after (TCQ)*1 ps;         
                     else
                        -- Otherwise increment DQS group counter and keep going
                        new_cnt_clkdiv_r  <= '1' after (TCQ)*1 ps;
                        cal_clkdiv_cnt_clkdiv_r <= cal_clkdiv_cnt_clkdiv_r + '1' after (TCQ)*1 ps;
                        cal_clkdiv_state_r      <= CAL_CLKDIV_NEW_DQS_WAIT after (TCQ)*1 ps;
                     end if;
                  end if;
            
               -- Done with this stage of calibration
               when CAL_CLKDIV_DONE =>
                  rdlvl_clkdiv_done_1 <= '1' after (TCQ)*1 ps;

	       when others =>
	          null;

            end case;
         end if;
      end if;
   end process;
      
   --*****************************************************************
   -- Stage 2 state machine
   --*****************************************************************
   
   -- when calibrating, check to see which clock cycle (after the read is
   -- issued) does the expected data pattern arrive. Record this result
   -- NOTES:
   --  1. An error condition can occur due to two reasons:
   --    a. If the matching logic waits a long enough amount of time
   --       and the expected data pattern is not received (longer than
   --       the theoretical maximum time that the data can take, factoring
   --       in CAS latency, prop delays, etc.), then flag an error.
   --       However, the error may be "recoverable" in that the write
   --       logic is still calibrating itself (in this case part of the
   --       write calibration is intertwined with the this stage of read
   --       calibration - write logic writes a pattern to the memory, then
   --       relies on rdlvl to find that pattern - if it doesn't, wrlvl
   --       changes its timing and tries again. By design, if the write path
   --       timing is incorrect, the rdlvl logic will never find the
   --       pattern). Because of this, there is a mechanism to restart
   --       this stage of rdlvl if an "error" is found.
   --    b. If the delay between different DQS groups is too large.
   --       There will be a maximum "skew" between different DQS groups
   --       based on routing, clock skew, etc.
   
   -- NOTE: Can add error checking here in case valid data not found on any
   --  of the available pipeline stages
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            cal2_cnt_bitslip_r 	  <= (others => '0') after (TCQ)*1 ps;
            cal2_cnt_rd_dly_r	  <= (others => '0') after (TCQ)*1 ps;
            cal2_cnt_rden_r  	  <= (others => '0') after (TCQ)*1 ps;
            cal2_done_r 	  <= '0' after (TCQ)*1 ps;
            cal2_en_dqs_skew_r 	  <= '0' after (TCQ)*1 ps;
            cal2_max_cnt_rd_dly_r <= (others => '0') after (TCQ)*1 ps;
            cal2_prech_req_r      <= '0' after (TCQ)*1 ps;
            cal2_rd_bitslip_cnt_r <= (others => '0') after (TCQ)*1 ps;
            cal2_state_r 	  <= CAL2_IDLE after (TCQ)*1 ps;
            rdlvl_pat_err 	  <= '0' after (TCQ)*1 ps;
         else            
            cal2_prech_req_r <= '0' after (TCQ)*1 ps;

            case (cal2_state_r) is
               
               when CAL2_IDLE =>
                  if ((rdlvl_start(1)) = '1') then
                     if ((SIM_CAL_OPTION = "SKIP_CAL") and (REG_CTRL = "ON")) then
                        -- If skip rdlvl, then proceed to end. Also hardcode bitslip
                        -- values based on CAS latency			     
     			cal2_state_r <= CAL2_DONE after (TCQ)*1 ps;

 		        for idx in 0 to (DQS_WIDTH-1) loop
                           case nCL is
                              when 3 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "01" after (TCQ)*1 ps;
                              when 4 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "11" after (TCQ)*1 ps;
                              when 5 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "01" after (TCQ)*1 ps;
                              when 6 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "11" after (TCQ)*1 ps;
                              when 7 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "01" after (TCQ)*1 ps;
                              when 8 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "11" after (TCQ)*1 ps;
                              when 9 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "01" after (TCQ)*1 ps;
                              when 10 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "11" after (TCQ)*1 ps;
                              when 11 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "01" after (TCQ)*1 ps;
		              when others =>
				 null;
                           end case;
			end loop;
                     elsif (SIM_CAL_OPTION = "SKIP_CAL") then
                        -- If skip rdlvl, then proceed to end. Also hardcode bitslip
                        -- values based on CAS latency			     
     			cal2_state_r <= CAL2_DONE after (TCQ)*1 ps;

 		        for idx in 0 to (DQS_WIDTH-1) loop
                           case nCL is
                              when 3 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "11" after (TCQ)*1 ps;
                              when 4 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "01" after (TCQ)*1 ps;
                              when 5 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "11" after (TCQ)*1 ps;
                              when 6 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "01" after (TCQ)*1 ps;
                              when 7 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "11" after (TCQ)*1 ps;
                              when 8 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "01" after (TCQ)*1 ps;
                              when 9 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "11" after (TCQ)*1 ps;
                              when 10 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "01" after (TCQ)*1 ps;
                              when 11 =>
                                 cal2_rd_bitslip_cnt_r(2*idx+1 downto 2*idx) <= "11" after (TCQ)*1 ps;
		              when others =>
				 null;
                           end case;
			end loop;
                     else
                        cal2_state_r <= CAL2_READ_WAIT after (TCQ)*1 ps;
                     end if;
                  end if;

               -- General wait state to wait for read pipe contents to settle
               -- either after bitslip is changed		  
               when CAL2_READ_WAIT =>
               	  -- Reset read delay counter after bitslip is changed - with every
                  -- new bitslip setting, we need to remeasure the read delay		       
                  cal2_cnt_rd_dly_r <= "00000" after (TCQ)*1 ps;
                  -- Wait for rising edge of synchronized rd_active signal from
                  -- controller, then starts counting clock cycles until the correct
                  -- pattern is returned from memory. Also make sure that we've
                  -- waited long enough after incrementing CNT_RDEN to allow data
                  -- to change, and ISERDES pipeline to flush out           
                  if ((rd_active_posedge_r = '1') and (not(rden_wait_r)) = '1') then
                     cal2_state_r <= CAL2_DETECT_MATCH after (TCQ)*1 ps;
                  end if;
               
               -- Wait until either a match is found, or until enough cycles
               -- have passed that there could not possibly be a match		  
               when CAL2_DETECT_MATCH =>
                  -- Increment delay counter for every cycle we're in this state		       
                  cal2_cnt_rd_dly_r <= cal2_cnt_rd_dly_r + '1' after (TCQ)*1 ps;

                  if (pat_data_match_r = '1') then
                     -- If found data match, then move on to next DQS group
                     cal2_state_r <= CAL2_NEXT_DQS after (TCQ)*1 ps;
                  elsif (to_integer(unsigned(cal2_cnt_rd_dly_r)) = MAX_RD_DLY_CNT-1) then
                     if (cal2_cnt_bitslip_r /= "11") then
                        -- If we've waited enough cycles for worst possible "round-trip"
               		-- delay, then try next bitslip setting, and repeat this process			     
                        cal2_state_r <= CAL2_READ_WAIT after (TCQ)*1 ps;
                        cal2_cnt_bitslip_r <= cal2_cnt_bitslip_r + "01" after (TCQ)*1 ps;
                        -- Update bitslip count for current DQS group
                        if (SIM_CAL_OPTION = "FAST_CAL") then
                           -- Increment bitslip count - for simulation, update bitslip
                           -- count for all DQS groups with same value				
                           loop_sim_bitslip: for i in 0 to  DQS_WIDTH-1 loop
                              cal2_rd_bitslip_cnt_r((2*i)+1 downto 2*i) <= cal2_rd_bitslip_cnt_r((2*i)+1 downto 2*i) + '1' after (TCQ)*1 ps;
                           end loop;
                        else
                           -- Otherwise, increment only for current DQS group	                            
        	           if ( cal2_rd_bitslip_cnt_r(2*to_integer(unsigned(cal2_cnt_rden_r))) = '1' ) then
                              cal2_rd_bitslip_cnt_r(2*to_integer(unsigned(cal2_cnt_rden_r))+0) <= '0' after (TCQ)*1 ps;	   
                              cal2_rd_bitslip_cnt_r(2*to_integer(unsigned(cal2_cnt_rden_r))+1) <= 
        						cal2_rd_bitslip_cnt_r(2*to_integer(unsigned(cal2_cnt_rden_r))+1) xor '1' after (TCQ)*1 ps;
                           else
                              cal2_rd_bitslip_cnt_r(2*to_integer(unsigned(cal2_cnt_rden_r))+0) <= '1' after (TCQ)*1 ps;
        		   end if;
                        end if;
                     else
                        -- Otherwise, if we've already exhausted all bitslip settings
                        -- and still haven't found a match, the boat has **possibly **
                        -- sunk (may be an error due to write calibration still
                        -- figuring out its own timing)			     
                        cal2_state_r <= CAL2_ERROR_TO after (TCQ)*1 ps;
                     end if;
                  end if;
               
               -- Final processing for current DQS group. Move on to next group
               -- Determine read enable delay between current DQS and DQS[0]		  
               when CAL2_NEXT_DQS =>
                  -- At this point, we've just found the correct pattern for the
                  -- current DQS group. Now check to see how long it took for the
                  -- pattern to return. Record the current delay time, as well as
                  -- the maximum time required across all the bytes
                  if (cal2_cnt_rd_dly_r > cal2_max_cnt_rd_dly_r) then
                     cal2_max_cnt_rd_dly_r <= cal2_cnt_rd_dly_r after (TCQ)*1 ps;
                  end if;
                  if (SIM_CAL_OPTION = "FAST_CAL") then
                     -- For simulation, update count for all DQS groups               	       
                     for j in 0 to  DQS_WIDTH - 1 loop
                        cal2_dly_cnt_r(5*j+4 downto 5*j) <= cal2_cnt_rd_dly_r after (TCQ)*1 ps;
                     end loop;
                  else
		     for idx in 0 to 4 loop	  
                        cal2_dly_cnt_r(5*to_integer(unsigned(cal2_cnt_rden_r))+idx) <= cal2_cnt_rd_dly_r(idx) after (TCQ)*1 ps;
		     end loop;
                  end if;

                  -- Request bank/row precharge, and wait for its completion. Always
                  -- precharge after each DQS group to avoid tRAS(max) violation		  
                  cal2_prech_req_r <= '1' after (TCQ)*1 ps;
                  if (prech_done = '1') then
                     if (((DQS_WIDTH = 1) or (SIM_CAL_OPTION = "FAST_CAL")) or (to_integer(unsigned(cal2_cnt_rden_r)) >= (DQS_WIDTH-1))) then
                        -- If either FAST_CAL is enabled and first DQS group is 
                        -- finished, or if the last DQS group was just finished,
                        -- then indicate that we can switch to final values for
                        -- byte skews, and signal end of stage 2 calibration
                        cal2_en_dqs_skew_r <= '1' after (TCQ)*1 ps;
                        cal2_state_r       <= CAL2_DONE after (TCQ)*1 ps;
                     else
                        -- Continue to next DQS group                        
                        cal2_cnt_rden_r <= cal2_cnt_rden_r + '1' after (TCQ)*1 ps;
                        cal2_cnt_bitslip_r <= "00" after (TCQ)*1 ps;
                        cal2_state_r <= CAL2_READ_WAIT after (TCQ)*1 ps;
                     end if;
                  end if;
               
               -- Finished with read enable calibration				     
               when CAL2_DONE =>
                  cal2_done_r <= '1' after (TCQ)*1 ps;

               -- Error detected due to timeout from waiting for expected data pat
               -- Also assert error in this case, but also allow opportunity for
               -- external control logic to resume the calibration at this point
               when CAL2_ERROR_TO =>
                  -- Assert error even though error might be temporary (until write
                  -- calibration logic asserts RDLVL_PAT_RESUME   
                  rdlvl_pat_err <= '1' after (TCQ)*1 ps;
                  -- Wait for resume signal from write calibration logic
                  if (rdlvl_pat_resume = '1') then
                     -- Similarly, reset bitslip control for current DQS group to 0
                     cal2_rd_bitslip_cnt_r(2*to_integer(unsigned(cal2_cnt_rden_r))+1) <= '0' after (TCQ)*1 ps;
                     cal2_rd_bitslip_cnt_r(2*to_integer(unsigned(cal2_cnt_rden_r))+0) <= '0' after (TCQ)*1 ps;
                     cal2_cnt_bitslip_r <= (others => '0') after (TCQ)*1 ps;
                     cal2_state_r <= CAL2_READ_WAIT after (TCQ)*1 ps;
                     rdlvl_pat_err <= '0' after (TCQ)*1 ps;
                  end if;

	       when others =>
	          null;

            end case;
         end if;
      end if;
   end process;
   
   
   -- Display which DQS group failed when timeout error occurs during pattern
   -- calibration. NOTE: Only valid when rdlvl_pat_err = 1
   rdlvl_pat_err_cnt <= cal2_cnt_rden_r;
   
   -- Final output: determine amount to delay rd_active signal by
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (SIM_CAL_OPTION = "SKIP_CAL") then
            -- Hardcoded option (for simulation only). The results are very
            -- specific for a testbench w/o additional net delays using a Micron
            -- memory model. Any other configuration may not work.
            case nCL is
               when 5 =>
                  cal2_rd_active_dly_r <= "01010" after (TCQ)*1 ps;
               when 6 =>
                  cal2_rd_active_dly_r <= "01010" after (TCQ)*1 ps;
               when 7 =>
                  cal2_rd_active_dly_r <= "01011" after (TCQ)*1 ps;
               when 8 =>
                  cal2_rd_active_dly_r <= "01011" after (TCQ)*1 ps;
               when 9 =>
                  cal2_rd_active_dly_r <= "01100" after (TCQ)*1 ps;
               when 10 =>
                  cal2_rd_active_dly_r <= "01100" after (TCQ)*1 ps;
               when 11 =>
                  cal2_rd_active_dly_r <= "01101" after (TCQ)*1 ps;
	       when others =>
	          null;	       
            end case;
         elsif (rdlvl_done_1(1) = '0') then
            -- Before calibration is complete, set RD_ACTIVE to minimum delay
            cal2_rd_active_dly_r <= (others => '0') after (TCQ)*1 ps;
         else
            -- Set RD_ACTIVE based on maximum DQS group delay            
            cal2_rd_active_dly_r <= cal2_max_cnt_rd_dly_r - std_logic_vector(to_unsigned(RDEN_DELAY_OFFSET, 5)) after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   gen_dly : for dqs_i in 0 to  DQS_WIDTH-1 generate
      -- Determine difference between delay for each DQS group, and the
      -- DQS group with the maximum delay 
      process (clk)
      begin
         if (clk'event and clk = '1') then
            cal2_dly_cnt_delta_r(dqs_i) <= cal2_max_cnt_rd_dly_r - cal2_dly_cnt_r(5*dqs_i+4 downto 5*dqs_i) after (TCQ)*1 ps;
         end if;
      end process;

      -- Delay those DQS groups with less than the maximum delay      
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst = '1') then
               cal2_clkdly_cnt_r(2*dqs_i+1 downto 2*dqs_i) <= "00" after (TCQ)*1 ps;
               cal2_deskew_err_r(dqs_i) <= '0' after (TCQ)*1 ps;
            elsif (cal2_en_dqs_skew_r = '0') then
               -- While calibrating, do not skew individual bytes
               cal2_clkdly_cnt_r(2*dqs_i+1 downto 2*dqs_i) <= "00" after (TCQ)*1 ps;
               cal2_deskew_err_r(dqs_i) <= '0' after (TCQ)*1 ps;
            else
               -- Once done calibrating, go ahead and skew individual bytes
               case cal2_dly_cnt_delta_r(dqs_i) is
                  when "00000" =>
                     cal2_clkdly_cnt_r(2*dqs_i+1 downto 2*dqs_i) <= "00" after (TCQ)*1 ps;
                     cal2_deskew_err_r(dqs_i) <= '0' after (TCQ)*1 ps;
                  when "00001" =>
                     cal2_clkdly_cnt_r(2*dqs_i+1 downto 2*dqs_i) <= "01" after (TCQ)*1 ps;
                     cal2_deskew_err_r(dqs_i) <= '0' after (TCQ)*1 ps;
                  when "00010" =>
                     cal2_clkdly_cnt_r(2*dqs_i+1 downto 2*dqs_i) <= "10" after (TCQ)*1 ps;
                     cal2_deskew_err_r(dqs_i) <= '0' after (TCQ)*1 ps;
                  when "00011" =>
                     cal2_clkdly_cnt_r(2*dqs_i+1 downto 2*dqs_i) <= "11" after (TCQ)*1 ps;
                     cal2_deskew_err_r(dqs_i) <= '0' after (TCQ)*1 ps;
                  -- If there's more than 3 cycles of skew between different
                  -- then flag error
                  when others =>
                     cal2_clkdly_cnt_r(2*dqs_i+1 downto 2*dqs_i) <= "XX" after (TCQ)*1 ps;
                     cal2_deskew_err_r(dqs_i) <= '1' after (TCQ)*1 ps;
               end case;
            end if;
         end if;
      end process;
      
   end generate;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then         
         rd_clkdly_cnt <= cal2_clkdly_cnt_r after (TCQ)*1 ps;
      end if;
   end process;
   
   -- Assert when non-recoverable error occurs during stage 2 cal
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            rdlvl_err_2(1) <= '0' after (TCQ)*1 ps;
         else
            -- Combine errors from each of the individual DQS group deskews
            rdlvl_err_2(1) <= or_br(cal2_deskew_err_r) after (TCQ)*1 ps;
         end if;
      end if;
   end process;

   -- Delay assertion of RDLVL_DONE for stage 2 by a few cycles after
   -- we've reached CAL2_DONE to account for fact that the proper deskew
   -- delays still need to be calculated, and driven to the individual
   -- DQ/DQS delay blocks. It's not an exact science, the # of delay cycles
   -- is sufficient. Feel free to add more delay if the calculation or FSM 
   -- logic is later changed.    
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            cal2_done_r1    <= '0' after (TCQ)*1 ps;
            cal2_done_r2    <= '0' after (TCQ)*1 ps;
            cal2_done_r3    <= '0' after (TCQ)*1 ps;
            rdlvl_done_1(1) <= '0' after (TCQ)*1 ps;
         else
            cal2_done_r1    <= cal2_done_r after (TCQ)*1 ps;
            cal2_done_r2    <= cal2_done_r1 after (TCQ)*1 ps;
            cal2_done_r3    <= cal2_done_r2 after (TCQ)*1 ps;
            rdlvl_done_1(1) <= cal2_done_r3 after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   
end architecture arch;



