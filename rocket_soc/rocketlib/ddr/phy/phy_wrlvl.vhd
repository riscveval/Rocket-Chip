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
--  /   /         Filename: phy_wrlvl.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:13 $
-- \   \  /  \    Date Created: Mon Jun 23 2008 
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
--    3. ODT not supported
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_wrlvl.vhd,v 1.1 2011/06/02 07:18:13 mishra Exp $
--**$Date: 2011/06/02 07:18:13 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_wrlvl.vhd,v $
--******************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;
library std;
   use std.textio.all;

entity phy_wrlvl is
   generic (
      TCQ             	: integer := 100;
      DQS_CNT_WIDTH   	: integer := 3;		
      DQ_WIDTH       	: integer := 64;	
      SHIFT_TBY4_TAP    : integer := 7;	
      DQS_WIDTH     	: integer := 8; 
      DRAM_WIDTH	: integer := 8;   
      CS_WIDTH		: integer := 1;
      CAL_WIDTH		: string  := "HALF";
      DQS_TAP_CNT_INDEX	: integer := 42;
      SIM_CAL_OPTION    : string  := "NONE"
   );
   port (
      clk    	        	: in std_logic;  
      rst       		: in std_logic; 
      calib_width      		: in std_logic_vector(2 downto 0); 
      rank_cnt          	: in std_logic_vector(1 downto 0);
      wr_level_start   		: in std_logic; 
      wl_sm_start   		: in std_logic; 
      rd_data_rise0   		: in std_logic_vector((DQ_WIDTH-1) downto 0);
      -- indicates read level stage 2 error
      rdlvl_error		: in std_logic;
      -- read level stage 2 failing byte 
      rdlvl_err_byte		: in std_logic_vector((DQS_CNT_WIDTH-1) downto 0);
      wr_level_done		: out std_logic;
      -- to phy_init for cs logic
      wrlvl_rank_done  		: out std_logic;
      dlyval_wr_dqs    		: out std_logic_vector(DQS_TAP_CNT_INDEX downto 0);
      dlyval_wr_dq      	: out std_logic_vector(DQS_TAP_CNT_INDEX downto 0);
      inv_dqs       		: out std_logic_vector((DQS_WIDTH-1) downto 0);
      -- resume read level stage 2 with write bit slip adjust
      rdlvl_resume		: out std_logic;
      -- write bit slip adjust
      wr_calib_dly		: out std_logic_vector((2*DQS_WIDTH-1) downto 0);
      wrcal_err			: out std_logic;
      wrlvl_err			: out std_logic;
      -- Debug ports
      dbg_wl_tap_cnt		: out std_logic_vector(4 downto 0);
      dbg_wl_edge_detect_valid	: out std_logic;
      dbg_rd_data_edge_detect	: out std_logic_vector((DQS_WIDTH-1) downto 0);
      dbg_rd_data_inv_edge_detect: out std_logic_vector((DQS_WIDTH-1) downto 0);
      dbg_dqs_count		: out std_logic_vector(DQS_CNT_WIDTH downto 0);
      dbg_wl_state		: out std_logic_vector(3 downto 0)
   );
end phy_wrlvl;

architecture trans of phy_wrlvl is

   -- Array type declarations
   type two_dim_array1 is array (0 to (CS_WIDTH-1)) of std_logic_vector((DQS_WIDTH-1) downto 0);
   type two_dim_array2 is array (0 to (CS_WIDTH-1)) of std_logic_vector((5*DQS_WIDTH-1) downto 0);
   type two_dim_array3 is array (0 to (CS_WIDTH-1)) of std_logic_vector((2*DQS_WIDTH-1) downto 0);
   type three_dim_array1 is array (0 to (DQS_WIDTH-1)) of std_logic_vector(4 downto 0);
   type three_dim_array2 is array (0 to (CS_WIDTH-1)) of three_dim_array1;

   function OR_BR (inp_val: std_logic_vector) return std_logic is
   variable rtn_val : std_logic := '0';
   begin
      for i in inp_val'range loop
         rtn_val := rtn_val or inp_val(i);
      end loop;
      return rtn_val;
   end function OR_BR;

   constant WL_IDLE  	  : std_logic_vector(3 downto 0) := "0000"; 
   constant WL_INIT  	  : std_logic_vector(3 downto 0) := "0001"; 
   constant WL_DEL_INC    : std_logic_vector(3 downto 0) := "0010"; 
   constant WL_WAIT  	  : std_logic_vector(3 downto 0) := "0011"; 
   constant WL_EDGE_CHECK : std_logic_vector(3 downto 0) := "0100"; 
   constant WL_DQS_CHECK  : std_logic_vector(3 downto 0) := "0101"; 
   constant WL_DQS_CNT    : std_logic_vector(3 downto 0) := "0110"; 
   constant WL_INV_DQS    : std_logic_vector(3 downto 0) := "0111"; 
   constant WL_WAIT_DQ    : std_logic_vector(3 downto 0) := "1000";
    
   signal dqs_count_r       		: std_logic_vector(DQS_CNT_WIDTH downto 0);
   signal dqs_count_rep1       		: std_logic_vector(DQS_CNT_WIDTH downto 0);
   signal dqs_count_rep2       		: std_logic_vector(DQS_CNT_WIDTH downto 0);
   signal rdlvl_err_byte_r     		: std_logic_vector((DQS_CNT_WIDTH-1) downto 0);
   signal rank_cnt_r        		: std_logic_vector(1 downto 0);
   signal rd_data_rise_wl_r         	: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal rd_data_previous_r     	: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal rd_data_inv_dqs_previous_r    : std_logic_vector((DQS_WIDTH-1) downto 0);
   signal rd_data_edge_detect_r         : std_logic_vector((DQS_WIDTH-1) downto 0);
   signal rd_data_inv_edge_detect_r     : std_logic_vector((DQS_WIDTH-1) downto 0);
   signal wr_level_done_r     		: std_logic;
   signal wrlvl_rank_done_r             : std_logic;
   signal wr_level_start_r	  	: std_logic;
   signal wl_state_r	  		: std_logic_vector(3 downto 0);
   signal wl_state_r1	  		: std_logic_vector(3 downto 0);
   signal wl_edge_detect_valid_r	: std_logic;
   signal wl_tap_count_r	  	: std_logic_vector(4 downto 0);
   signal wl_dqs_tap_count_r	  	: two_dim_array2;
   signal rdlvl_error_r	  		: std_logic;
   signal rdlvl_error_r1	  	: std_logic;
   signal rdlvl_resume_r	  	: std_logic;
   signal rdlvl_resume_r1	  	: std_logic;
   signal rdlvl_resume_r2	  	: std_logic;
   signal wr_calib_dly_r	  	: std_logic_vector((2*DQS_WIDTH-1) downto 0);
   signal set_one_flag	  		: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal set_two_flag	  		: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal inv_dqs_wl	  		: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal inv_dqs_r	  		: two_dim_array1;
   signal dlyval_wr_dqs_r	  	: two_dim_array2;
   signal dlyval_wr_dq_r	  	: two_dim_array2;
   signal inv_dqs_wl_r	  		: two_dim_array1;
   signal wr_calib_dly_r1	  	: two_dim_array3;
   signal dq_tap_wl	  		: three_dim_array1;
   signal dq_tap		  	: three_dim_array2;
   signal dq_cnt_inc		  	: std_logic;
   signal wrcal_err_xhdl	  	: std_logic;
   signal stable_cnt                    : std_logic_vector(1 downto 0);
   signal inv_stable_cnt                : std_logic_vector(1 downto 0);

begin

   -- drive the outputs with intermediate signals
   wrcal_err <= wrcal_err_xhdl;
	
   -- Debug ports
   dbg_wl_edge_detect_valid   <= wl_edge_detect_valid_r;
   dbg_rd_data_edge_detect    <= rd_data_edge_detect_r;
   dbg_rd_data_inv_edge_detect<= rd_data_inv_edge_detect_r;
   dbg_wl_tap_cnt             <= wl_tap_count_r;
   dbg_dqs_count	      <= dqs_count_r;
   dbg_wl_state		      <= wl_state_r;

   dlyval_wr_dqs <= dlyval_wr_dqs_r(TO_INTEGER(unsigned(rank_cnt))) when (TO_INTEGER(unsigned(rank_cnt)) < CS_WIDTH) else 
                                              (others => '0');
   dlyval_wr_dq <= dlyval_wr_dq_r(TO_INTEGER(unsigned(rank_cnt))) when (TO_INTEGER(unsigned(rank_cnt)) < CS_WIDTH) else 
                                             (others => '0');
   inv_dqs       <= inv_dqs_wl_r(TO_INTEGER(unsigned(rank_cnt))) when (TO_INTEGER(unsigned(rank_cnt)) < CS_WIDTH) else (others => '0');
   wr_calib_dly  <= wr_calib_dly_r1(TO_INTEGER(unsigned(rank_cnt))) when (TO_INTEGER(unsigned(rank_cnt)) < CS_WIDTH) else (others => '0');

   gen_rank: for cal_i in 0 to (CS_WIDTH-1) generate
   begin
      process (clk)
      begin
         if (clk'event and clk = '1') then
   	    if (rst = '1') then
	       inv_dqs_wl_r(cal_i)    <= (others => '0') after TCQ*1 ps;
	       dlyval_wr_dqs_r(cal_i) <= (others => '0') after TCQ*1 ps; 
	    else
	       inv_dqs_wl_r(cal_i)    <= inv_dqs_r(cal_i) after TCQ*1 ps;
	       dlyval_wr_dqs_r(cal_i) <= wl_dqs_tap_count_r(cal_i) after TCQ*1 ps;
	    end if;
	 end if;
      end process;
   end generate;
	    
cw_width_2 : if ( CS_WIDTH = 2 ) generate
   process (clk)
   begin
    if (clk'event and clk = '1') then
	   if (rst = '1') then
           rst_wr_calib_dly_r1_loop: for i in 0 to (CS_WIDTH-1) loop
             	wr_calib_dly_r1(i) <= (others => '0') after TCQ*1 ps;
	       end loop;
       else
	      if (TO_INTEGER(unsigned(rank_cnt)) < CS_WIDTH) then	    
              wr_calib_dly_r1(TO_INTEGER(unsigned(rank_cnt))) <= wr_calib_dly_r after TCQ*1 ps;
          end if;
          wr_calib_dly_r1(1) <= wr_calib_dly_r1(0) after TCQ*1 ps;
	   end if;
    end if;
   end process;
end generate;
	    
cw_width_3 : if ( CS_WIDTH = 3 ) generate
   process (clk)
   begin
    if (clk'event and clk = '1') then
	   if (rst = '1') then
           rst_wr_calib_dly_r1_loop: for i in 0 to (CS_WIDTH-1) loop
             	wr_calib_dly_r1(i) <= (others => '0') after TCQ*1 ps;
	       end loop;
       else
	      if (TO_INTEGER(unsigned(rank_cnt)) < CS_WIDTH) then	    
              wr_calib_dly_r1(TO_INTEGER(unsigned(rank_cnt))) <= wr_calib_dly_r after TCQ*1 ps;
          end if;
          wr_calib_dly_r1(1) <= wr_calib_dly_r1(0) after TCQ*1 ps;
          wr_calib_dly_r1(2) <= wr_calib_dly_r1(0) after TCQ*1 ps;
	   end if;
    end if;
   end process;
end generate;
	    
cw_width_4 : if ( CS_WIDTH = 4 ) generate
   process (clk)
   begin
    if (clk'event and clk = '1') then
	   if (rst = '1') then
           rst_wr_calib_dly_r1_loop: for i in 0 to (CS_WIDTH-1) loop
             	wr_calib_dly_r1(i) <= (others => '0') after TCQ*1 ps;
	       end loop;
       else
	  if (TO_INTEGER(unsigned(rank_cnt)) < CS_WIDTH) then	    
             wr_calib_dly_r1(TO_INTEGER(unsigned(rank_cnt))) <= wr_calib_dly_r after TCQ*1 ps;
          end if;
          wr_calib_dly_r1(1) <= wr_calib_dly_r1(0) after TCQ*1 ps;
          wr_calib_dly_r1(2) <= wr_calib_dly_r1(0) after TCQ*1 ps;
          wr_calib_dly_r1(3) <= wr_calib_dly_r1(0) after TCQ*1 ps;
       end if;
    end if;
   end process;
end generate;

cw_width_others : if ((CS_WIDTH /= 4) and (CS_WIDTH /= 3) and (CS_WIDTH /= 2)) generate
   process (clk)
   begin
    if (clk'event and clk = '1') then
       if (rst = '1') then
          rst_wr_calib_dly_r1_loop: for i in 0 to (CS_WIDTH-1) loop
       	     wr_calib_dly_r1(i) <= (others => '0') after TCQ*1 ps;
	  end loop;
       else
	  if (TO_INTEGER(unsigned(rank_cnt)) < CS_WIDTH) then	    
             wr_calib_dly_r1(TO_INTEGER(unsigned(rank_cnt))) <= wr_calib_dly_r after TCQ*1 ps;
          end if;
       end if;
    end if;
   end process;
end generate;
	    
   wr_level_done   <= wr_level_done_r;
   wrlvl_rank_done <= wrlvl_rank_done_r;

   -- only storing the rise data for checking. The data comming back during
   -- write leveling will be a static value. Just checking for rise data is
   -- enough. 		    
   gen_rd: for rd_i in 0 to (DQS_WIDTH-1) generate
   begin
      process (clk)
      begin
	 if (clk'event and clk = '1')  then
            rd_data_rise_wl_r(rd_i) <= OR_BR(rd_data_rise0(((rd_i*DRAM_WIDTH)+DRAM_WIDTH-1) downto rd_i*DRAM_WIDTH));         
	 end if;
      end process;
   end generate;



   -- storing the previous data for checking later
   process (clk)
   begin
      if (clk'event and clk = '1')  then
         if ((inv_dqs_wl(TO_INTEGER(unsigned(dqs_count_rep2))) = '0') and ((wl_state_r = WL_INIT) or
             ((wl_state_r = WL_EDGE_CHECK) and (wl_edge_detect_valid_r = '1')))) then
           rd_data_previous_r <= rd_data_rise_wl_r after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1')  then
         if ((inv_dqs_wl(TO_INTEGER(unsigned(dqs_count_rep2))) = '1') and
             ((wl_state_r = WL_EDGE_CHECK) and (wl_edge_detect_valid_r = '1'))) then
           rd_data_inv_dqs_previous_r <= rd_data_rise_wl_r after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   -- Counter to track stable value of feedback data to mitigate
   -- false edge detection in unstable jitter region
   process (clk)
   begin
      if (clk'event and clk = '1')  then
         if ((rst = '1') or (wl_state_r = WL_DQS_CNT)) then
           stable_cnt <= "00" after TCQ*1 ps;
	 elsif ((inv_dqs_wl(TO_INTEGER(unsigned(dqs_count_rep2))) = '0') and (wl_tap_count_r > "00000") and
             ((wl_state_r = WL_EDGE_CHECK) and (wl_edge_detect_valid_r = '1'))) then            
            if ((rd_data_previous_r(TO_INTEGER(unsigned(dqs_count_rep1))) = rd_data_rise_wl_r(TO_INTEGER(unsigned(dqs_count_rep1))))
               and (stable_cnt < "11")) then
              stable_cnt <= (stable_cnt + '1') after TCQ*1 ps;
            elsif (rd_data_previous_r(TO_INTEGER(unsigned(dqs_count_rep1))) /= rd_data_rise_wl_r(TO_INTEGER(unsigned(dqs_count_rep1)))) then
              stable_cnt <= "00" after TCQ*1 ps;
            end if;
         end if;	    
      end if;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1')  then
         if ((rst = '1') or (wl_state_r = WL_DQS_CNT)) then
           inv_stable_cnt <= "00" after TCQ*1 ps;
	 elsif ((inv_dqs_wl(TO_INTEGER(unsigned(dqs_count_rep2))) = '1') and (wl_tap_count_r > "00000") and
	     ((wl_state_r = WL_EDGE_CHECK) and (wl_edge_detect_valid_r = '1'))) then            
            if ((rd_data_inv_dqs_previous_r(TO_INTEGER(unsigned(dqs_count_rep1))) = rd_data_rise_wl_r(TO_INTEGER(unsigned(dqs_count_rep1))))
               and (inv_stable_cnt < "11")) then
              inv_stable_cnt <= (inv_stable_cnt + '1') after TCQ*1 ps;
            elsif (rd_data_inv_dqs_previous_r(TO_INTEGER(unsigned(dqs_count_rep1))) /= rd_data_rise_wl_r(TO_INTEGER(unsigned(dqs_count_rep1)))) then
              inv_stable_cnt <= "00" after TCQ*1 ps;
            end if;
         end if;	    
      end if;
   end process;   
 
   -- checking for transition from 0 to 1
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
	    rst_edge_detect: for l in 0 to (DQS_WIDTH-1) loop
	       rd_data_inv_edge_detect_r(l) <= '0' after TCQ*1 ps;	    
	       rd_data_edge_detect_r(l)     <= '0' after TCQ*1 ps;
            end loop;	       
         elsif (inv_dqs_wl(TO_INTEGER(unsigned(dqs_count_rep2))) = '1') then
            if (inv_stable_cnt = "11") then
            for i in rd_data_rise_wl_r'range loop
	        rd_data_inv_edge_detect_r(i) <= (not(rd_data_inv_dqs_previous_r(i)) and 
					        rd_data_rise_wl_r(i)) after TCQ*1 ps;
	    end loop;
	    else
	        rd_data_inv_edge_detect_r <= (others => '0') after TCQ*1 ps;
	    end if;
         elsif (inv_dqs_wl(TO_INTEGER(unsigned(dqs_count_rep2))) = '0') then
            if (stable_cnt = "11") then
            for i in rd_data_rise_wl_r'range loop
	        rd_data_edge_detect_r(i) <= (not(rd_data_previous_r(i)) and 
					        rd_data_rise_wl_r(i)) after TCQ*1 ps;
	    end loop;
	    else
	        rd_data_edge_detect_r <= (others => '0') after TCQ*1 ps;
	    end if;
	 end if;
      end if;
   end process;      

   -- Below 320 MHz it can take less than SHIFT_TBY4_TAP taps for DQS
   -- to be aligned to CK resulting in an underflow for DQ IODELAY taps
   -- (DQS taps-SHIFT_TBY4_TAP). In this case DQ will be set to 0 taps. 
   -- This is non-optimal because DQS and DQ are not exactly 90 degrees 
   -- apart. Since there is relatively more margin at frequencies below 
   -- 320 MHz this setting should be okay.
   gen_cs: if ((CS_WIDTH /= 4) and (CS_WIDTH /= 2)) generate 
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst = '1') then
               tap_offset_rank: for e in 0 to (CS_WIDTH-1) loop
                  tap_offset_dqs_cnt: for f in 0 to (DQS_WIDTH-1) loop
                     dq_tap(e)(f) <= "00000" after TCQ*1 ps;
                  end loop;
               end loop;
            elsif (wr_level_done_r = '0') then
               if ((TO_INTEGER(unsigned(rank_cnt_r)) < CS_WIDTH) and (TO_INTEGER(unsigned(dqs_count_r)) < DQS_WIDTH)) then	    
                  dq_tap(TO_INTEGER(unsigned(rank_cnt_r)))(TO_INTEGER(unsigned(dqs_count_r))) <=
           						dq_tap_wl(TO_INTEGER(unsigned(dqs_count_r))) after TCQ*1 ps;
               end if;
            elsif ((SIM_CAL_OPTION = "FAST_CAL") and (wr_level_done_r = '1')) then
               dq_tap_rank: for n in 0 to (CS_WIDTH-1) loop
                  dq_tap_dqs_cnt: for p in 0 to (DQS_WIDTH-1) loop
                      dq_tap(n)(p) <= dq_tap_wl(0) after TCQ*1 ps;
                  end loop;
               end loop;  
            end if;   
         end if;	 
      end process;
   end generate;

   gen_cs_4: if (CS_WIDTH = 4) generate 
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst = '1') then
               tap_offset_rank: for e in 0 to (CS_WIDTH-1) loop
                  tap_offset_dqs_cnt: for f in 0 to (DQS_WIDTH-1) loop
                     dq_tap(e)(f) <= "00000" after TCQ*1 ps;
                  end loop;
               end loop;
            elsif (wr_level_done_r = '0') then
               if ((TO_INTEGER(unsigned(rank_cnt_r)) < CS_WIDTH) and (TO_INTEGER(unsigned(dqs_count_r)) < DQS_WIDTH)) then	    
                  dq_tap(TO_INTEGER(unsigned(rank_cnt_r)))(TO_INTEGER(unsigned(dqs_count_r))) <=
           						dq_tap_wl(TO_INTEGER(unsigned(dqs_count_r))) after TCQ*1 ps;
               end if;
            elsif ((SIM_CAL_OPTION = "FAST_CAL") and (wr_level_done_r = '1')) then
               dq_tap_rank: for n in 0 to (CS_WIDTH-1) loop
                  dq_tap_dqs_cnt: for p in 0 to (DQS_WIDTH-1) loop
                      dq_tap(n)(p) <= dq_tap_wl(0) after TCQ*1 ps;
                  end loop;
               end loop;   
            elsif ((wr_level_done_r = '1') and (CAL_WIDTH = "HALF")) then
               rank_dqs_cnt: for g in 0 to (DQS_WIDTH-1) loop
                  dq_tap(CS_WIDTH-2)(g) <= dq_tap(CS_WIDTH-4)(g) after TCQ*1 ps;
                  dq_tap(CS_WIDTH-1)(g) <= dq_tap(CS_WIDTH-3)(g) after TCQ*1 ps;
               end loop;   
            end if;   
         end if;	 
      end process;
   end generate;

   gen_cs_2: if (CS_WIDTH = 2) generate 
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst = '1') then
               tap_offset_rank: for e in 0 to (CS_WIDTH-1) loop
                  tap_offset_dqs_cnt: for f in 0 to (DQS_WIDTH-1) loop
                     dq_tap(e)(f) <= "00000" after TCQ*1 ps;
                  end loop;
               end loop;
            elsif (wr_level_done_r = '0') then
               if ((TO_INTEGER(unsigned(rank_cnt_r)) < CS_WIDTH) and (TO_INTEGER(unsigned(dqs_count_r)) < DQS_WIDTH)) then	    
                  dq_tap(TO_INTEGER(unsigned(rank_cnt_r)))(TO_INTEGER(unsigned(dqs_count_r))) <=
           						dq_tap_wl(TO_INTEGER(unsigned(dqs_count_r))) after TCQ*1 ps;
               end if;
            elsif ((SIM_CAL_OPTION = "FAST_CAL") and (wr_level_done_r = '1')) then
               dq_tap_rank: for n in 0 to (CS_WIDTH-1) loop
                  dq_tap_dqs_cnt: for p in 0 to (DQS_WIDTH-1) loop
                      dq_tap(n)(p) <= dq_tap_wl(0) after TCQ*1 ps;
                  end loop;
               end loop;   
            elsif ((wr_level_done_r = '1') and (CAL_WIDTH = "HALF")) then
               dqs_cnt: for h in 0 to (DQS_WIDTH-1) loop
                  dq_tap(CS_WIDTH-1)(h) <= dq_tap(CS_WIDTH-2)(h) after TCQ*1 ps;
               end loop;   
            end if;
         end if;	 
      end process;
   end generate;

   -- registring the write level start signal
   process (clk)
   begin
      if (clk'event and clk = '1') then
         wr_level_start_r <= wr_level_start after TCQ*1 ps;
      end if;
   end process;

   -- Storing inv_dqs values during DQS write leveling
   case_2_2: if ( CS_WIDTH = 2 ) generate
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            rst_inv_dqs_r_loop: for j in 0 to (CS_WIDTH-1) loop
               inv_dqs_r(j) <= (others => '0') after TCQ*1 ps;
            end loop;
         elsif ((wl_state_r = WL_INV_DQS) or (wl_state_r = WL_EDGE_CHECK)) then
        	if (TO_INTEGER(unsigned(rank_cnt_r)) < CS_WIDTH) then	    
           		inv_dqs_r(TO_INTEGER(unsigned(rank_cnt_r))) <= inv_dqs_wl after TCQ*1 ps;
            end if;
         elsif ((SIM_CAL_OPTION = "FAST_CAL") and (wl_state_r = WL_DQS_CHECK)) then
            inv_rank: for q in 0 to (CS_WIDTH-1) loop
               inv_dqs_cnt: for r in 0 to (DQS_WIDTH-1) loop
                   inv_dqs_r(q)(r) <= inv_dqs_wl(0) after TCQ*1 ps;
               end loop;
            end loop;
         elsif ((wr_level_done_r = '1') and (CAL_WIDTH = "HALF") ) then
        	inv_dqs_r(CS_WIDTH-1) <= inv_dqs_r(CS_WIDTH-2) after TCQ*1 ps;
         end if;
      end if;
   end process;
   end generate;
   
   case_2_4: if ( CS_WIDTH = 4 ) generate
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            rst_inv_dqs_r_loop: for j in 0 to (CS_WIDTH-1) loop
               inv_dqs_r(j) <= (others => '0') after TCQ*1 ps;
            end loop;
         elsif ((wl_state_r = WL_INV_DQS) or (wl_state_r = WL_EDGE_CHECK)) then
        	if (TO_INTEGER(unsigned(rank_cnt_r)) < CS_WIDTH) then	    
           		inv_dqs_r(TO_INTEGER(unsigned(rank_cnt_r))) <= inv_dqs_wl after TCQ*1 ps;
            end if;
         elsif ((SIM_CAL_OPTION = "FAST_CAL") and (wl_state_r = WL_DQS_CHECK)) then
            inv_rank: for q in 0 to (CS_WIDTH-1) loop
               inv_dqs_cnt: for r in 0 to (DQS_WIDTH-1) loop
                   inv_dqs_r(q)(r) <= inv_dqs_wl(0) after TCQ*1 ps;
               end loop;
            end loop;
         elsif ((wr_level_done_r = '1') and (CAL_WIDTH = "HALF") ) then
        	inv_dqs_r(CS_WIDTH-2) <= inv_dqs_r(CS_WIDTH-4) after TCQ*1 ps;
            inv_dqs_r(CS_WIDTH-1) <= inv_dqs_r(CS_WIDTH-3) after TCQ*1 ps;
         end if;
      end if;
   end process;
   end generate;
   
   case_2_others: if ( (CS_WIDTH /= 2) and (CS_WIDTH /= 4) ) generate
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            rst_inv_dqs_r_loop: for j in 0 to (CS_WIDTH-1) loop
               inv_dqs_r(j) <= (others => '0') after TCQ*1 ps;
            end loop;
         elsif ((wl_state_r = WL_INV_DQS) or (wl_state_r = WL_EDGE_CHECK)) then
            if (TO_INTEGER(unsigned(rank_cnt_r)) < CS_WIDTH) then	    
           		inv_dqs_r(TO_INTEGER(unsigned(rank_cnt_r))) <= inv_dqs_wl after TCQ*1 ps;
            end if;
         elsif ((SIM_CAL_OPTION = "FAST_CAL") and (wl_state_r = WL_DQS_CHECK)) then
            inv_rank: for q in 0 to (CS_WIDTH-1) loop
               inv_dqs_cnt: for r in 0 to (DQS_WIDTH-1) loop
                   inv_dqs_r(q)(r) <= inv_dqs_wl(0) after TCQ*1 ps;
               end loop;
            end loop;
         end if;
      end if;
   end process;
   end generate;


-- Storing DQS tap values at the end of each DQS write leveling
case_3_2: if ( CS_WIDTH = 2 ) generate
   process (clk)
   begin
      if (clk'event and clk = '1') then
     -- MODIFIED, RC, 060908
         if (rst = '1') then
            rst_wl_dqs_tap_count_loop: for k in 0 to (CS_WIDTH-1) loop
               wl_dqs_tap_count_r(k) <= (others => '0') after TCQ*1 ps;
        	end loop;
         elsif ((wl_state_r = WL_DQS_CNT) or (wl_state_r = WL_WAIT)) then
            for idx in 0 to 4 loop
           		if ((TO_INTEGER(unsigned(rank_cnt_r)) < CS_WIDTH) and (TO_INTEGER(unsigned(dqs_count_r)) < DQS_WIDTH)) then	    
     	          wl_dqs_tap_count_r(TO_INTEGER(unsigned(rank_cnt_r)))(5*(TO_INTEGER(unsigned(dqs_count_r))) + idx)
               		<= wl_tap_count_r(idx) after TCQ*1 ps;
               	end if;				
        	end loop;
         elsif ((SIM_CAL_OPTION = "FAST_CAL") and (wl_state_r = WL_DQS_CHECK)) then
            dqs_tap_rank: for s in 0 to (CS_WIDTH-1) loop
               dqs_tap_dqs_cnt: for t in 0 to (DQS_WIDTH-1) loop
                  wl_dqs_tap_count_r(s)(5*t+4 downto 5*t) <=
                  wl_tap_count_r after TCQ*1 ps;
               end loop;
            end loop;
         elsif ((wr_level_done_r = '1') and (CAL_WIDTH = "HALF") 
                 and (SIM_CAL_OPTION /= "FAST_CAL")) then
        	wl_dqs_tap_count_r(CS_WIDTH-1) <= wl_dqs_tap_count_r(CS_WIDTH-2) after TCQ*1 ps;
         end if;
      end if;
   end process;
end generate;

case_3_4: if ( CS_WIDTH = 4 ) generate
   process (clk)
   begin
      if (clk'event and clk = '1') then
     -- MODIFIED, RC, 060908
         if (rst = '1') then
            rst_wl_dqs_tap_count_loop: for k in 0 to (CS_WIDTH-1) loop
               wl_dqs_tap_count_r(k) <= (others => '0') after TCQ*1 ps;
        	end loop;
         elsif ((wl_state_r = WL_DQS_CNT) or (wl_state_r = WL_WAIT)) then
            for idx in 0 to 4 loop
           		if ((TO_INTEGER(unsigned(rank_cnt_r)) < CS_WIDTH) and (TO_INTEGER(unsigned(dqs_count_r)) < DQS_WIDTH)) then	    
     	          wl_dqs_tap_count_r(TO_INTEGER(unsigned(rank_cnt_r)))(5*(TO_INTEGER(unsigned(dqs_count_r))) + idx)
               		<= wl_tap_count_r(idx) after TCQ*1 ps;
               	end if;				
        	end loop;
         elsif ((SIM_CAL_OPTION = "FAST_CAL") and (wl_state_r = WL_DQS_CHECK)) then
            dqs_tap_rank: for s in 0 to (CS_WIDTH-1) loop
               dqs_tap_dqs_cnt: for t in 1 to (DQS_WIDTH-1) loop
                  wl_dqs_tap_count_r(s)(5*t+4 downto 5*t) <=
                  wl_tap_count_r after TCQ*1 ps;
               end loop;
            end loop;
         elsif ((wr_level_done_r = '1') and (CAL_WIDTH = "HALF")
                 and (SIM_CAL_OPTION /= "FAST_CAL")) then
        	wl_dqs_tap_count_r(CS_WIDTH-2) <= wl_dqs_tap_count_r(CS_WIDTH-4) after TCQ*1 ps;
            wl_dqs_tap_count_r(CS_WIDTH-1) <= wl_dqs_tap_count_r(CS_WIDTH-3) after TCQ*1 ps;
         end if;
      end if;
   end process;
end generate;

case_3_others: if ( (CS_WIDTH /= 2) and (CS_WIDTH /= 4) ) generate
   process (clk)
   begin
      if (clk'event and clk = '1') then
     -- MODIFIED, RC, 060908
         if (rst = '1') then
            rst_wl_dqs_tap_count_loop: for k in 0 to (CS_WIDTH-1) loop
               wl_dqs_tap_count_r(k) <= (others => '0') after TCQ*1 ps;
        	end loop;
         elsif ((wl_state_r = WL_DQS_CNT) or (wl_state_r = WL_WAIT)) then
            for idx in 0 to 4 loop
               if ((TO_INTEGER(unsigned(rank_cnt_r)) < CS_WIDTH) and (TO_INTEGER(unsigned(dqs_count_r)) < DQS_WIDTH)) then	    
     	          wl_dqs_tap_count_r(TO_INTEGER(unsigned(rank_cnt_r)))(5*(TO_INTEGER(unsigned(dqs_count_r))) + idx)
               		<= wl_tap_count_r(idx) after TCQ*1 ps;
               	end if;				
       	    end loop;
         elsif ((SIM_CAL_OPTION = "FAST_CAL") and (wl_state_r = WL_DQS_CHECK)) then
            dqs_tap_rank: for s in 0 to (CS_WIDTH-1) loop
               dqs_tap_dqs_cnt: for t in 0 to (DQS_WIDTH-1) loop
                  wl_dqs_tap_count_r(s)(5*t+4 downto 5*t) <=
                  wl_tap_count_r after TCQ*1 ps;
               end loop;
            end loop;
         end if;
      end if;
   end process;
end generate;


   -- assign DQS output tap count to DQ with the 90 degree offset
      gen_dq_rank: for rank_i in 0 to (CS_WIDTH-1) generate
      begin     
         gen_dq_tap_cnt: for dq_i in 0 to (DQS_WIDTH-1) generate
	 begin
            -- MODIFIED, RC, 060908 - timing when DQ IODELAY value is changed
            -- does not need to be precise as long as we're not changing while
            -- looking for edge on DQ		 
            process (clk)
	    begin
               if (clk'event and clk = '1') then
                  dlyval_wr_dq_r(rank_i)(5*dq_i+4 downto 5*dq_i) <= dq_tap(rank_i)(dq_i) after TCQ*1 ps;
	       end if;
	    end process;
	 end generate;
      end generate;

   -- state machine to initiate the write leveling sequence
   -- The state machine operates on one byte at a time.
   -- It will increment the delays to the DQS OSERDES
   -- and sample the DQ from the memory. When it detects
   -- a transition from 1 to 0 then the write leveling is considered
   -- done.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
	    tap_offset_wl_rst: for m in 0 to (DQS_WIDTH-1) loop
	       dq_tap_wl(m) <= (others => '0') after TCQ*1 ps;
            end loop;	       
            wrlvl_err              <= '0' after TCQ*1 ps;
            wr_level_done_r        <= '0' after TCQ*1 ps;
            wrlvl_rank_done_r      <= '0' after TCQ*1 ps;
            inv_dqs_wl             <= (others => '0') after TCQ*1 ps;
            dqs_count_r            <= (others => '0') after TCQ*1 ps;
            dqs_count_rep1         <= (others => '0') after TCQ*1 ps;
            dqs_count_rep2         <= (others => '0') after TCQ*1 ps;
            dq_cnt_inc             <= '1' after TCQ*1 ps;
            rank_cnt_r             <= (others => '0') after TCQ*1 ps;
            wl_state_r             <= WL_IDLE after TCQ*1 ps;
            wl_state_r1            <= WL_IDLE after TCQ*1 ps;
            wl_edge_detect_valid_r <= '0' after TCQ*1 ps;
            wl_tap_count_r         <= (others => '0') after TCQ*1 ps;

	 else 
            wl_state_r1            <= wl_state_r after TCQ*1 ps;

	    case wl_state_r is 

               when WL_IDLE =>
		  inv_dqs_wl <= (others => '0') after TCQ*1 ps;
		  wrlvl_rank_done_r <= '0' after TCQ*1 ps;
		  if ((wr_level_done_r = '0') and (wr_level_start_r = '1') and (wl_sm_start = '1')) then
                     wl_state_r <= WL_INIT after TCQ*1 ps;
		  end if;

	       when WL_INIT =>
	          wl_edge_detect_valid_r <= '0' after TCQ*1 ps;
		  wrlvl_rank_done_r      <= '0' after TCQ*1 ps;
		  if (wl_sm_start = '1') then
		     wl_state_r <= WL_EDGE_CHECK after TCQ*1 ps;  --WL_DEL_INC;
		  end if;

	       when WL_DEL_INC =>	-- Inc DQS ODELAY tap 
                  wl_state_r <= WL_WAIT after TCQ*1 ps;
                  wl_edge_detect_valid_r <= '0' after TCQ*1 ps;
                  wl_tap_count_r <= (wl_tap_count_r + '1') after TCQ*1 ps;

	       when WL_WAIT =>
    	          if (wl_sm_start = '1') then 
                     wl_state_r <= WL_WAIT_DQ after TCQ*1 ps;
		  end if;

	       when WL_WAIT_DQ =>
    	          if (wl_sm_start = '1') then 
                     wl_state_r <= WL_EDGE_CHECK after TCQ*1 ps;
		  end if;

	       when WL_EDGE_CHECK =>	-- Look for the edge
    	          if (wl_edge_detect_valid_r = '0') then 
                     wl_state_r <= WL_WAIT after TCQ*1 ps;
                     wl_edge_detect_valid_r <= '1' after TCQ*1 ps;
		  -- 0->1 transition detected with non-inv DQS   
                  -- Minimum of 8 taps between DQS and DQ when
                  -- SHIFT_TBY4_TAP > 10
		  elsif ((rd_data_edge_detect_r(TO_INTEGER(unsigned(dqs_count_r))) = '1') and
		         ((wl_tap_count_r >= SHIFT_TBY4_TAP) or ((wl_tap_count_r > "00111") and (SHIFT_TBY4_TAP > 10))) and 
			 (wl_edge_detect_valid_r = '1')) then
                     wl_state_r <= WL_DQS_CNT after TCQ*1 ps;
	             if (TO_INTEGER(unsigned(dqs_count_rep2)) < DQS_WIDTH) then     
                        inv_dqs_wl(TO_INTEGER(unsigned(dqs_count_rep2))) <= '0' after TCQ*1 ps;
		     end if;	
		     wl_tap_count_r <= wl_tap_count_r after TCQ*1 ps;
                     if (wl_tap_count_r < SHIFT_TBY4_TAP) then
			dq_tap_wl(TO_INTEGER(unsigned(dqs_count_r))) <= (others => '0') after TCQ*1 ps;
		     else
		        dq_tap_wl(TO_INTEGER(unsigned(dqs_count_r))) <= wl_tap_count_r - std_logic_vector(to_unsigned(SHIFT_TBY4_TAP,5));
	             end if;		

		  -- 0->1 transition detected with inv DQS
                  -- Minimum of 8 taps between DQS and DQ when
                  -- SHIFT_TBY4_TAP > 10		     
		  elsif ((rd_data_inv_edge_detect_r(TO_INTEGER(unsigned(dqs_count_r))) = '1') and
		         ((wl_tap_count_r >= SHIFT_TBY4_TAP) or ((wl_tap_count_r > "00111") and (SHIFT_TBY4_TAP > 10))) and 
			 (wl_edge_detect_valid_r = '1')) then
                     wl_state_r <= WL_DQS_CNT after TCQ*1 ps;
	             if (TO_INTEGER(unsigned(dqs_count_rep2)) < DQS_WIDTH) then     
                        inv_dqs_wl(TO_INTEGER(unsigned(dqs_count_rep2))) <= '1' after TCQ*1 ps;
		     end if;	
		     wl_tap_count_r <= wl_tap_count_r after TCQ*1 ps;
                     if (wl_tap_count_r < SHIFT_TBY4_TAP) then
			dq_tap_wl(TO_INTEGER(unsigned(dqs_count_r))) <= (others => '0') after TCQ*1 ps;
		     else
		        dq_tap_wl(TO_INTEGER(unsigned(dqs_count_r))) <= wl_tap_count_r - std_logic_vector(to_unsigned(SHIFT_TBY4_TAP,5));
	             end if;
     		     
	          elsif (wl_tap_count_r > "11110") then
		     wrlvl_err <= '1' after TCQ*1 ps;
		  else
		     wl_state_r <= WL_INV_DQS after TCQ*1 ps;
		  end if;

	       when WL_INV_DQS =>
	          if (TO_INTEGER(unsigned(dqs_count_rep2)) < DQS_WIDTH) then     
		     inv_dqs_wl(TO_INTEGER(unsigned(dqs_count_rep2))) <= 
					not (inv_dqs_wl(TO_INTEGER(unsigned(dqs_count_rep2)))) after TCQ*1 ps;
                  end if;   
		  wl_edge_detect_valid_r <= '0' after TCQ*1 ps;
		  if (inv_dqs_wl(TO_INTEGER(unsigned(dqs_count_rep2))) = '1') then
		     wl_state_r <= WL_DEL_INC after TCQ*1 ps;
		  else
		     wl_state_r <= WL_WAIT after TCQ*1 ps;
		  end if;

	       when WL_DQS_CNT =>
   	          if ((SIM_CAL_OPTION = "FAST_CAL") or 
   	          (TO_INTEGER(unsigned((dqs_count_r))) = (DQS_WIDTH-1))) then
		     dqs_count_r    <= dqs_count_r after TCQ*1 ps;
		     dqs_count_rep1 <= dqs_count_rep1 after TCQ*1 ps;
		     dqs_count_rep2 <= dqs_count_rep2 after TCQ*1 ps;
		     dq_cnt_inc     <= '0' after TCQ*1 ps;
		  else
		     dqs_count_r    <= (dqs_count_r + '1') after TCQ*1 ps;
		     dqs_count_rep1 <= (dqs_count_rep1 + '1') after TCQ*1 ps;
		     dqs_count_rep2 <= (dqs_count_rep2 + '1') after TCQ*1 ps;
		     dq_cnt_inc <= '1' after TCQ*1 ps;
		  end if;
		  wl_state_r     <= WL_DQS_CHECK after TCQ*1 ps;
		  wl_edge_detect_valid_r <= '0' after TCQ*1 ps;

	       when WL_DQS_CHECK =>	-- check if all DQS have been calibrated
  	          wl_tap_count_r <= "00000" after TCQ*1 ps;
  	          if (dq_cnt_inc = '0') then
		     wrlvl_rank_done_r <= '1' after TCQ*1 ps;
		     wl_state_r        <= WL_IDLE after TCQ*1 ps;
		     if ((SIM_CAL_OPTION = "FAST_CAL") or 
		    (TO_INTEGER(unsigned(rank_cnt_r)) = (calib_width -1))) then
		        wr_level_done_r <= '1' after TCQ*1 ps;
		        rank_cnt_r      <= "00" after TCQ*1 ps;
		     else
		        wr_level_done_r <= '0' after TCQ*1 ps;
		        rank_cnt_r      <= rank_cnt_r + '1' after TCQ*1 ps;
		        dqs_count_r     <= (others => '0') after TCQ*1 ps;
		        dqs_count_rep1  <= (others => '0') after TCQ*1 ps;
		        dqs_count_rep2  <= (others => '0') after TCQ*1 ps;
		     end if;
		  else
		     wl_state_r <= WL_INIT after TCQ*1 ps;

		  end if;
		
	       when others =>
		  null;

	    end case;
	 end if;
      end if;
   end process;

   -- Write calibration during/after stage 2 read leveling
   -- synthesis translate_off
   process (rdlvl_error)
      variable out_data : line;
   begin
      if (rdlvl_error'event and rdlvl_error = '1') then
         if ((rst = '0') and (rdlvl_error = '1') and (rdlvl_error_r = '0') and
	     (wr_calib_dly_r(2*TO_INTEGER(unsigned(rdlvl_err_byte_r))+0) = '1') and
	     (wr_calib_dly_r(2*TO_INTEGER(unsigned(rdlvl_err_byte_r))+1) = '1') ) then
            write(out_data, string'("PHY_WRLVL: Write Calibration Error at "));
            write(out_data, now);
            writeline(output, out_data);	    
         end if;
      end if;
   end process;

   -- synthesis translate_on
   process (clk)
   begin
      if (clk'event and clk = '1') then
         rdlvl_err_byte_r <= rdlvl_err_byte after TCQ*1 ps;
      end if;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            rdlvl_error_r   <= '0' after TCQ*1 ps;
            rdlvl_error_r1  <= '0' after TCQ*1 ps;
            rdlvl_resume    <= '0' after TCQ*1 ps;
            rdlvl_resume_r  <= '0' after TCQ*1 ps;
            rdlvl_resume_r1 <= '0' after TCQ*1 ps;
            rdlvl_resume_r2 <= '0' after TCQ*1 ps;
	 else
            rdlvl_error_r   <= rdlvl_error after TCQ*1 ps;
            rdlvl_error_r1  <= rdlvl_error_r after TCQ*1 ps;
            rdlvl_resume    <= (rdlvl_resume_r or rdlvl_resume_r1 or rdlvl_resume_r2) after TCQ*1 ps;
            rdlvl_resume_r  <= rdlvl_error_r and not(rdlvl_error_r1) after TCQ*1 ps;
            rdlvl_resume_r1 <= rdlvl_resume_r after TCQ*1 ps;
            rdlvl_resume_r2 <= rdlvl_resume_r1 after TCQ*1 ps;
	 end if;
      end if;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            wrcal_err_xhdl <= '0' after TCQ*1 ps;
	 elsif ((rdlvl_error = '1') and (rdlvl_error_r = '0') and
	        (wr_calib_dly_r(2*TO_INTEGER(unsigned(rdlvl_err_byte_r))+0) = '1') and 
	        (wr_calib_dly_r(2*TO_INTEGER(unsigned(rdlvl_err_byte_r))+1) = '1')) then
            wrcal_err_xhdl <= '1' after TCQ*1 ps;
	 else
	    wrcal_err_xhdl <= wrcal_err_xhdl after TCQ*1 ps;
	 end if;
      end if;
   end process;

   -- wr_calib_dly only increments from 0 to a max value of 3
   -- Write bitslip logic only supports upto 3 clk_mem cycles
   process (clk)
   begin
      if (clk'event and clk = '1') then
	 if (rst = '1') then
	    wr_calib_dly_r <= (others => '0');
         elsif ((rdlvl_error = '1') and (rdlvl_error_r = '0')) then
  	    if (set_two_flag(TO_INTEGER(unsigned(rdlvl_err_byte_r))) = '1') then
               wr_calib_dly_r(2*TO_INTEGER(unsigned(rdlvl_err_byte_r))+0) <= '1' after TCQ*1 ps;  
               wr_calib_dly_r(2*TO_INTEGER(unsigned(rdlvl_err_byte_r))+1) <= '1' after TCQ*1 ps;  
            elsif (set_one_flag(TO_INTEGER(unsigned(rdlvl_err_byte_r))) = '1') then
               wr_calib_dly_r(2*TO_INTEGER(unsigned(rdlvl_err_byte_r))+0) <= '0' after TCQ*1 ps;  
               wr_calib_dly_r(2*TO_INTEGER(unsigned(rdlvl_err_byte_r))+1) <= '1' after TCQ*1 ps;
	    else  
               wr_calib_dly_r(2*TO_INTEGER(unsigned(rdlvl_err_byte_r))+0) <= '1' after TCQ*1 ps;  
               wr_calib_dly_r(2*TO_INTEGER(unsigned(rdlvl_err_byte_r))+1) <= '0' after TCQ*1 ps;
            end if;
         end if;
      end if;
   end process;

   -- set_one_flag determines if wr_calib_dly_r must be incremented to '2'
   gen_wcal_set_one: for wcal_i in 0 to (DQS_WIDTH-1) generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst = '1') then
               set_one_flag(wcal_i) <= '0' after TCQ*1 ps;
            elsif ((set_one_flag(wcal_i) = '0') and (rdlvl_error_r = '1') and
	           (rdlvl_error_r1 = '0') and (TO_INTEGER(unsigned(rdlvl_err_byte_r)) = wcal_i)) then
               set_one_flag(wcal_i) <= '1' after TCQ*1 ps;
	    end if;
	 end if;
      end process;
   end generate;

   -- set_two_flag determines if wr_calib_dly_r must be incremented to '3'
   gen_wcal_set_two: for two_i in 0 to (DQS_WIDTH-1) generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst = '1') then
               set_two_flag(two_i) <= '0' after TCQ*1 ps;
            elsif ((set_one_flag(two_i) = '1') and (rdlvl_error_r = '1') and
	           (rdlvl_error_r1 = '0') and (TO_INTEGER(unsigned(rdlvl_err_byte_r)) = two_i)) then
               set_two_flag(two_i) <= '1' after TCQ*1 ps;
	    end if;
	 end if;
      end process;
   end generate;   

end trans;

