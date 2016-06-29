--*****************************************************************************
-- (c) Copyright 2008-2009 Xilinx, Inc. All rights reserved.
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2000, 2001, 2002, 2003, 2004, 2005, 2008 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
--
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor                : Xilinx
-- \   \   \/     Version               : 3.92
--  \   \         Application           : MIG
--  /   /         Filename              : bank_state.vhd
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


-- Primary bank state machine.  All bank specific timing is generated here.
--
-- Conceptually, when a bank machine is assigned a request, conflicts are
-- checked.  If there is a conflict, then the new request is added
-- to the queue for that rank-bank.
--
-- Eventually, that request will find itself at the head of the queue for
-- its rank-bank.  Forthwith, the bank machine will begin arbitration to send an
-- activate command to the DRAM.  Once arbitration is successful and the
-- activate is sent, the row state machine waits the RCD delay.  The RAS
-- counter is also started when the activate is sent.
--
-- Upon completion of the RCD delay, the bank state machine will begin
-- arbitration for sending out the column command.  Once the column
-- command has been sent, the bank state machine waits the RTP latency, and
-- if the command is a write, the RAS counter is loaded with the WR latency.
--
-- When the RTP counter reaches zero, the pre charge wait state is entered.
-- Once the RAS timer reaches zero, arbitration to send a precharge command
-- begins.
--
-- Upon successful transmission of the precharge command, the bank state
-- machine waits the precharge period and then rejoins the idle list.
--
-- For an open rank-bank hit, a bank machine passes management of the rank-bank to
-- a bank machine that is managing the subsequent request to the same page.  A bank
-- machine can either be a "passer" or a "passee" in this handoff.  There
-- are two conditions that have to occur before an open bank can be passed.
-- A spatial condition, ie same rank-bank and row address.  And a temporal condition,
-- ie the passee has completed it work with the bank, but has not issued a precharge.
--
-- The spatial condition is signalled by pass_open_bank_ns.  The temporal condition
-- is when the column command is issued, or when the bank_wait_in_progress
-- signal is true.  Bank_wait_in_progress is true when the RTP timer is not
-- zero, or when the RAS/WR timer is not zero and the state machine is waiting
-- to send out a precharge command.
--
-- On an open bank pass, the passer transitions from the temporal condition
-- noted above and performs the end of request processing and eventually lands
-- in the act_wait_r state.
--
-- On an open bank pass, the passee lands in the col_wait_r state and waits
-- for its chance to send out a column command.
--
-- Since there is a single data bus shared by all columns in all ranks, there
-- is a single column machine.  The column machine is primarily in charge of
-- managing the timing on the DQ data bus.  It reserves states for data transfer,
-- driver turnaround states, and preambles.  It also has the ability to add
-- additional programmable delay for read to write changeovers.  This read to write
-- delay is generated in the column machine which inhibits writes via the
-- inhbt_wr_r signal.
--
-- There is a rank machine for every rank.  The rank machines are responsible
-- for enforcing rank specific timing such as FAW, and WTR.  RRD is guaranteed
-- in the bank machine since it is closely coupled to the operation of the
-- bank machine and is timing critical.
--
-- Since a bank machine can be working on a request for any rank, all rank machines
-- inhibits are input to all bank machines.  Based on the rank of the current
-- request, each bank machine selects the rank information corresponding
-- to the rank of its current request.
--
-- Since driver turnaround states and WTR delays are so severe with DDRIII, the
-- memory interface has the ability to promote requests that use the same
-- driver as the most recent request.  There is logic in this block that
-- detects when the driver for its request is the same as the driver for
-- the most recent request.  In such a case, this block will send out special
-- "same" request early enough to eliminate dead states when there is no
-- driver changeover.
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity bank_state is
   generic (
            TCQ                     : integer := 100;
            ADDR_CMD_MODE           : string := "1T";
            BM_CNT_WIDTH            : integer := 2;
            BURST_MODE              : string := "8";
            CWL                     : integer := 5;
            DATA_BUF_ADDR_WIDTH     : integer := 8;
            DRAM_TYPE               : string := "DDR3";
            ECC                     : string := "OFF";
            ID                      : integer := 0;
            nBANK_MACHS             : integer := 4;
            nCK_PER_CLK             : integer := 2;
            nCNFG2RD_EN             : integer := 2;
            nCNFG2WR                : integer := 2;
            nOP_WAIT                : integer := 0;
            nRAS_CLKS               : integer := 10;
            nRP                     : integer := 10;
            nRTP                    : integer := 4;
            nRCD                    : integer := 5;
            nWTP_CLKS               : integer := 5;
            ORDERING                : string := "NORM";
            RANKS                   : integer := 4;
            RANK_WIDTH              : integer := 4;
            RAS_TIMER_WIDTH         : integer := 5;
            STARVE_LIMIT            : integer := 2
           );
   port (
         start_rcd               : out std_logic;
         act_wait_r              : out std_logic;
         ras_timer_ns            : out std_logic_vector(RAS_TIMER_WIDTH - 1 downto 0);
         end_rtp                 : out std_logic;
         rd_half_rmw             : out std_logic;
         bank_wait_in_progress   : out std_logic;
         start_pre_wait          : out std_logic;
         op_exit_req             : out std_logic;
         pre_wait_r              : out std_logic;
         allow_auto_pre          : out std_logic;
         precharge_bm_end        : out std_logic;
         demand_act_priority     : out std_logic;
         rts_row                 : out std_logic;
         act_this_rank_r         : out std_logic_vector(RANKS - 1 downto 0);
         demand_priority         : out std_logic;
         rtc                     : out std_logic;
         col_rdy_wr              : out std_logic;
         rts_col                 : out std_logic;
         wr_this_rank_r          : out std_logic_vector(RANKS - 1 downto 0);
         rd_this_rank_r          : out std_logic_vector(RANKS - 1 downto 0);
         clk                     : in std_logic;
         rst                     : in std_logic;
         bm_end                  : in std_logic;
         pass_open_bank_r        : in std_logic;
         sending_row             : in std_logic;
         rcv_open_bank           : in std_logic;
         sending_col             : in std_logic;
         rd_wr_r                 : in std_logic;
         req_wr_r                : in std_logic;
         rd_data_addr            : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         req_data_buf_addr_r     : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         dfi_rddata_valid        : in std_logic;
         rd_rmw                  : in std_logic;
         ras_timer_ns_in         : in std_logic_vector((2 * (RAS_TIMER_WIDTH * nBANK_MACHS)) - 1 downto 0);
         rb_hit_busies_r         : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
         idle_r                  : in std_logic;
         passing_open_bank       : in std_logic;
         low_idle_cnt_r          : in std_logic;
         op_exit_grant           : in std_logic;
         tail_r                  : in std_logic;
         auto_pre_r              : in std_logic;
         pass_open_bank_ns       : in std_logic;
         req_rank_r              : in std_logic_vector(RANK_WIDTH - 1 downto 0);
         req_rank_r_in           : in std_logic_vector((RANK_WIDTH * nBANK_MACHS * 2) - 1 downto 0);
         start_rcd_in            : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
         inhbt_act_faw_r         : in std_logic_vector(RANKS - 1 downto 0);
         wait_for_maint_r        : in std_logic;
         head_r                  : in std_logic;
         sent_row                : in std_logic;
         demand_act_priority_in  : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
         order_q_zero            : in std_logic;
         sent_col                : in std_logic;
         q_has_rd                : in std_logic;
         q_has_priority          : in std_logic;
         req_priority_r          : in std_logic;
         idle_ns                 : in std_logic;
         demand_priority_in      : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
         io_config_strobe        : in std_logic;
         io_config_valid_r       : in std_logic;
         io_config               : in std_logic_vector(RANK_WIDTH downto 0);
         wtr_inhbt_config_r      : in std_logic_vector(RANKS - 1 downto 0);
         inhbt_rd_config         : in std_logic;
         inhbt_wr_config         : in std_logic;
         inhbt_rd_r              : in std_logic_vector(RANKS - 1 downto 0);
         dq_busy_data            : in std_logic
        );
end entity bank_state;

architecture trans of bank_state is

 
   function REDUCTION_AND( A: in std_logic_vector) return std_logic is
   variable tmp : std_logic := '1';
   begin
     for i in A'range loop
          tmp := tmp and A(i);
     end loop;
     return tmp;
   end function REDUCTION_AND;
                 
   function REDUCTION_OR( A: in std_logic_vector) return std_logic is
   variable tmp : std_logic := '0';
   begin
     for i in A'range loop
          tmp := tmp or A(i);
     end loop;
     return tmp;
   end function REDUCTION_OR;
   
   
   function REDUCTION_NOR( A: in std_logic_vector) return std_logic is
   variable tmp : std_logic := '0';
   begin
     for i in A'range loop
          tmp := tmp nor A(i);
     end loop;
     return tmp;
   end function REDUCTION_NOR;
                 
   function clogb2(size: integer) return integer is
   variable tmp : integer := 1;
   variable tmp_size : std_logic_vector (31 downto 0);
   begin
     tmp_size := std_logic_vector(TO_UNSIGNED((size - 1),32));
     while ( to_integer(UNSIGNED(tmp_size)) > 1 ) loop
       tmp_size := std_logic_vector(UNSIGNED(tmp_size) srl 1);
       tmp := tmp + 1;
     end loop;
     return tmp;
   end function clogb2;
   
   function fRCD_CLKS (nCK_PER_CLK: integer; nRCD : integer ; ADDR_CMD_MODE : string)
   return integer is
   begin
     if (nCK_PER_CLK = 1) then
         return (nRCD);
     else 
        if (ADDR_CMD_MODE = "2T") then
             return ( nRCD/2 + (nRCD mod 2));
        else
             return nRCD/2;
        end if;
     end if ;
   end function fRCD_CLKS;
   
   function fRTP_CLKS (nCK_PER_CLK: integer; nRTP : integer ; ADDR_CMD_MODE : string)
   return integer is
   begin
     if (nCK_PER_CLK = 1) then
         return (nRTP);
     else 
        if (ADDR_CMD_MODE = "2T") then
             return ( nRTP/2 + (nRTP mod 2));
        else
             return (nRTP/2 + 1);
        end if;
     end if ;
   end function fRTP_CLKS;
   
   function fRP_CLKS (nCK_PER_CLK: integer; nRP : integer )
   return integer is
   begin
     if (nCK_PER_CLK = 1) then
         return (nRP);
     else 
         return ( nRP/2 + (nRP mod 2));
     end if ;
   end function fRP_CLKS;
   
   function fRCD_CLKS_M2 (nRCD_CLKS: integer)
   return integer is
   begin
     if (nRCD_CLKS - 2 < 0) then
         return 0;
     else 
         return nRCD_CLKS-2;
     end if;
   end  fRCD_CLKS_M2;
   
   function fRTP_CLKS_M1 (nRTP_CLKS: integer)
   return integer is
   begin
     if (nRTP_CLKS - 1 <= 0) then
         return 0;
     else 
         return nRTP_CLKS-1;
     end if;
   end  fRTP_CLKS_M1;
    
   -- Subtract two because there are a minimum of two fabric states from
   -- end of RP timer until earliest possible arb to send act. 
   function fRP_CLKS_M2 (nRP_CLKS: integer)
   return integer is
   begin
     if (nRP_CLKS - 2 <= 0) then
         return 0;
     else 
         return nRP_CLKS-2;
     end if;
   end  fRP_CLKS_M2;

   signal bm_end_r1                : std_logic;
   signal col_wait_r               : std_logic;
   signal act_wait_r_lcl           : std_logic;
   signal start_rcd_lcl            : std_logic;
   signal act_wait_ns              : std_logic;
   
   -- RCD timer
   -- For nCK_PER_CLK == 2, since column commands are delayed one
   -- state relative to row commands, we don't need to add the remainder.
   -- Unless 2T mode, in which case we're not offset and the remainder
   -- must be added.
   constant nRCD_CLKS              : integer := fRCD_CLKS(nCK_PER_CLK,nRCD,ADDR_CMD_MODE);
   constant nRCD_CLKS_M2           : integer := fRCD_CLKS_M2(nRCD_CLKS);
   constant RCD_TIMER_WIDTH        : integer := clogb2(nRCD_CLKS_M2+1);
   constant ZERO                   : integer := 0;
   constant ONE                    : integer := 1;

   signal rcd_timer_r              : std_logic_vector(RCD_TIMER_WIDTH - 1 downto 0) := (others => '0' );
   signal end_rcd                  : std_logic;
   signal rcd_active_r             : std_logic := '0';
   -- Generated so that the config can be started during the RCD, if
   -- possible.
   signal allow_early_rd_config    : std_logic;
   signal allow_early_wr_config    : std_logic;
   signal rmw_rd_done              : std_logic := '0';
   signal rd_half_rmw_lcl          : std_logic := '0';
   signal rmw_wait_r               : std_logic := '0';
   signal col_wait_ns              : std_logic;

   -- Set up various RAS timer parameters, wires, etc.
   constant TWO                    : integer := 2;
   signal ras_timer_r              : std_logic_vector(RAS_TIMER_WIDTH - 1 downto 0);
   signal passed_ras_timer         : std_logic_vector(RAS_TIMER_WIDTH - 1 downto 0);
   signal i                        : integer;
   signal start_wtp_timer          : std_logic;
   signal ras_timer_passed_ns      : std_logic_vector(RAS_TIMER_WIDTH - 1 downto 0);
   signal ras_timer_zero_ns        : std_logic;
   signal ras_timer_zero_r         : std_logic;

   -- RTP timer.  Unless 2T mode, add one to account for fixed row command
   -- to column command offset of -1.
   constant nRTP_CLKS              : integer := fRTP_CLKS(nCK_PER_CLK,nRTP,ADDR_CMD_MODE);
   constant nRTP_CLKS_M1           : integer := fRTP_CLKS_M1(nRTP_CLKS);
   constant RTP_TIMER_WIDTH        : integer := clogb2(nRTP_CLKS_M1 + 1);
   signal rtp_timer_ns             : std_logic_vector(RTP_TIMER_WIDTH - 1 downto 0);
   signal rtp_timer_r              : std_logic_vector(RTP_TIMER_WIDTH - 1 downto 0);
   signal sending_col_not_rmw_rd   : std_logic;
   signal end_rtp_lcl              : std_logic;
   
   -- Optionally implement open page mode timer.
   constant OP_WIDTH               : integer := clogb2(nOP_WAIT + 1);
   signal start_pre                : std_logic;
   signal pre_wait_ns              : std_logic;
   signal pre_request              : std_logic;
   -- precharge timer.
   constant nRP_CLKS               : integer := fRP_CLKS(nCK_PER_CLK,nRP) ;
   constant nRP_CLKS_M2            : integer := fRP_CLKS_M2(nRP_CLKS); 
   constant RP_TIMER_WIDTH         : integer := clogb2(nRP_CLKS_M2 + 1);
   
   signal rp_timer_r               : std_logic_vector(RP_TIMER_WIDTH - 1 downto 0) :=(others => '0');
   signal inhbt_act_rrd            : std_logic;
   signal j                        : integer;
   signal my_inhbt_act_faw         : std_logic;
   signal act_req                  : std_logic;
   signal rts_act_denied           : std_logic;
   signal act_starve_limit_cntr_ns : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal act_starve_limit_cntr_r  : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal demand_act_priority_r    : std_logic;
   signal demand_act_priority_ns   : std_logic;
   signal act_demanded             : std_logic := '0';
   signal row_demand_ok            : std_logic;
   signal act_this_rank_ns         : std_logic_vector(RANKS - 1 downto 0);
   signal req_bank_rdy_ns          : std_logic;
   signal req_bank_rdy_r           : std_logic;
   signal rts_col_denied           : std_logic;
   constant STARVE_LIMIT_CNT       : integer := STARVE_LIMIT * nBANK_MACHS;
   constant STARVE_LIMIT_WIDTH     : integer := clogb2(STARVE_LIMIT_CNT);
   signal starve_limit_cntr_r      : std_logic_vector(STARVE_LIMIT_WIDTH - 1 downto 0);
   signal starve_limit_cntr_ns     : std_logic_vector(STARVE_LIMIT_WIDTH - 1 downto 0);
   signal starved                  : std_logic;
   signal demand_priority_r        : std_logic;
   signal demand_priority_ns       : std_logic;
   signal demanded                 : std_logic := '0';
   signal demanded_prior_r         : std_logic;
   signal demanded_prior_ns        : std_logic;
   signal demand_ok                : std_logic;
   signal pre_config_match_ns      : std_logic;
   signal pre_config_match_r       : std_logic;
   signal io_config_match          : std_logic;
   signal early_config             : std_logic;
   signal my_wtr_inhbt_config      : std_logic;
   signal my_inhbt_rd              : std_logic;
   signal allow_rw                 : std_logic;
   signal col_rdy                  : std_logic;
   signal col_cmd_rts              : std_logic;
   signal override_demand_ns       : std_logic;
   signal override_demand_r        : std_logic;
   signal wr_this_rank_ns          : std_logic_vector(RANKS - 1 downto 0);
   signal rd_this_rank_ns          : std_logic_vector(RANKS - 1 downto 0);
   
   signal rcd_timer_ns             : std_logic_vector(RCD_TIMER_WIDTH - 1 downto 0);
   signal end_rcd_ns               : std_logic;
   signal rcd_active_ns            : std_logic;
   signal op_wait_r                : std_logic;
   signal op_active                : std_logic;
   signal op_wait_ns               : std_logic;
   signal op_cnt_ns                : std_logic_vector(OP_WIDTH-1 downto 0);
   signal op_cnt_r                 : std_logic_vector(OP_WIDTH-1 downto 0);
   signal rp_timer_ns              : std_logic_vector(RP_TIMER_WIDTH -1 downto 0);
   
   -- Declare intermediate signals for referenced outputs
   signal act_wait_r_int0          : std_logic;
   signal ras_timer_ns_int1        : std_logic_vector(RAS_TIMER_WIDTH - 1 downto 0);
   signal start_pre_wait_int3      : std_logic;
   signal pre_wait_r_int1          : std_logic;
   signal my_rmw_rd_ns             : std_logic;
   signal rmw_wait_ns              : std_logic;
   signal inhbt_config             : std_logic;

   --Temporary signal added to hold the default value of the rd_half_rmw
   --signal when it is not driven
   signal rd_half_rmw_temp         : std_logic := '0';

   --Register dfi_rddata_valid and rd_rmw to align them to req_data_buf_addr_r
   signal dfi_rddata_valid_r       : std_logic;
   signal rd_rmw_r                 : std_logic;

begin 

    
   -- Drive referenced outputs
   act_wait_r <= act_wait_r_int0;
   start_pre_wait <= start_pre_wait_int3;
   pre_wait_r <= pre_wait_r_int1;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         bm_end_r1 <= bm_end after (TCQ)*1 ps;
      end if;
   end process;
   
   start_rcd_lcl <= act_wait_r_lcl and sending_row;
   start_rcd <= start_rcd_lcl;
   act_wait_ns <= rst or ((act_wait_r_lcl and not(start_rcd_lcl) and
                           not(rcv_open_bank)
                          ) or
                          bm_end_r1 or
                          (pass_open_bank_r and bm_end)
                         );
   process (clk)
   begin
      if (clk'event and clk = '1') then
         act_wait_r_lcl <= act_wait_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   act_wait_r_int0 <= act_wait_r_lcl;
   
   rcd_timer_1 : if (nRCD_CLKS <= 1) generate
      process (start_rcd_lcl)
      begin
         end_rcd <= start_rcd_lcl;
      end process;
      process (end_rcd)
      begin
         allow_early_rd_config <= end_rcd;
      end process;
      process (end_rcd)
      begin
         allow_early_wr_config <= end_rcd;
      end process;
   end generate;
   
   rcd_timer_2 : if (nRCD_CLKS = 2) generate
         process (start_rcd_lcl)
         begin
            end_rcd <= start_rcd_lcl;
         end process;
         
     int_i1:   if (nCNFG2RD_EN > 0) generate
            process (end_rcd)
            begin
               allow_early_rd_config <= end_rcd;
            end process;
         end generate;
         
     int_i2:   if (nCNFG2WR > 0) generate
            process (end_rcd)
            begin
               allow_early_wr_config <= end_rcd;
            end process;
      end generate;
    end generate; 

    rcd_timer_gt_2 : if (nRCD_CLKS > 2) generate

            process (rcd_timer_r, rst, start_rcd_lcl)
            variable rcd_timer_ns_v : std_logic_vector(RCD_TIMER_WIDTH - 1 downto 0);
            begin
               if (rst = '1') then
                  rcd_timer_ns_v := (others => '0');
               else
                  rcd_timer_ns_v := rcd_timer_r;
                  if (start_rcd_lcl = '1') then
                     rcd_timer_ns_v := std_logic_vector(TO_UNSIGNED(nRCD_CLKS_M2,RCD_TIMER_WIDTH));
                  elsif ((REDUCTION_OR(rcd_timer_r)) = '1') then
                     rcd_timer_ns_v := rcd_timer_r - std_logic_vector(TO_UNSIGNED(1,1));
                  end if;
               end if;
               rcd_timer_ns <= rcd_timer_ns_v;
            end process;
            
            process (clk)
            begin
               if (clk'event and clk = '1') then
                  rcd_timer_r <= rcd_timer_ns after (TCQ)*1 ps;
               end if;
            end process;
            
            end_rcd_ns <= '1' when (rcd_timer_ns = std_logic_vector(TO_UNSIGNED(1,RCD_TIMER_WIDTH))) else '0';
            process (clk)
            begin
               if (clk'event and clk = '1') then
                  end_rcd <= end_rcd_ns;
               end if;
            end process;
            
            rcd_active_ns <= REDUCTION_OR(rcd_timer_ns);
            
            process (clk)
            begin
               if (clk'event and clk = '1') then
                  rcd_active_r <= rcd_active_ns after (TCQ)*1 ps;
               end if;
            end process;
            
            allow_early_rd_config <= '1' when ((to_integer( UNSIGNED(rcd_timer_r)) <= nCNFG2RD_EN) and rcd_active_r = '1') or 
                                              ((nCNFG2RD_EN > nRCD_CLKS) and start_rcd_lcl = '1') else '0';

            allow_early_wr_config <= '1' when ((to_integer( UNSIGNED(rcd_timer_r)) <= nCNFG2WR) and rcd_active_r = '1') or 
                                              ((nCNFG2WR > nRCD_CLKS) and start_rcd_lcl = '1') else '0';
   end generate;
   
   rd_half_rmw <= rd_half_rmw_temp;
   rmw_on : if (not (ECC = "OFF")) generate
      -- Delay dfi_rddata_valid and rd_rmw by one cycle to align them
      -- to req_data_buf_addr_r so that rmw_wait_r clears properly
      process (clk)
      begin
         if (clk'event and clk = '1') then
            dfi_rddata_valid_r <= dfi_rddata_valid after (TCQ)*1 ps;
            rd_rmw_r <= rd_rmw after (TCQ)*1 ps;
         end if;
      end process;
	  my_rmw_rd_ns <= '1' when  ((dfi_rddata_valid_r = '1') and (rd_rmw_r = '1') and (rd_data_addr = req_data_buf_addr_r))
                      else '0';
      
      int12 : if (CWL = 8) generate
         process (my_rmw_rd_ns)
         begin
            rmw_rd_done <= my_rmw_rd_ns;
         end process;
      end generate;

      int13 : if (not(CWL = 8)) generate
         process (clk)
         begin
            if (clk'event and clk = '1') then
               rmw_rd_done <= my_rmw_rd_ns after (TCQ)*1 ps;
            end if;
         end process;
      end generate;

      -- Figure out if the read that's completing is for an RMW for
      -- this bank machine.  Delay by a state if CWL != 8 since the
      -- data is not ready in the RMW buffer for the early write
      -- data fetch that happens with ECC and CWL != 8.
      -- Create a state bit indicating we're waiting for the read
      -- half of the rmw to complete.
      process (rd_wr_r, req_wr_r)
      begin
         rd_half_rmw_lcl <= req_wr_r and rd_wr_r;
      end process;
      
      rd_half_rmw_temp <= rd_half_rmw_lcl;
      rmw_wait_ns <= not(rst) and ((rmw_wait_r and not(rmw_rd_done)) or (rd_half_rmw_lcl and sending_col));
      process (clk)
      begin
         if (clk'event and clk = '1') then
            rmw_wait_r <= rmw_wait_ns after (TCQ)*1 ps;
         end if;
      end process;
   end generate;

   -- column wait state machine.
   col_wait_ns <= not(rst) and ((col_wait_r and not(sending_col)) or end_rcd or rcv_open_bank or (rmw_rd_done and rmw_wait_r));
   process (clk)
   begin
      if (clk'event and clk = '1') then
         col_wait_r <= col_wait_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   -- On a bank pass, select the RAS timer from the passing bank machine.
   process (ras_timer_ns_in, rb_hit_busies_r)
   variable passed_ras_timer_v : std_logic_vector(RAS_TIMER_WIDTH - 1 downto 0);
   begin
      passed_ras_timer_v := (others => '0');
      for i in ID + 1 to  (ID + nBANK_MACHS) - 1 loop
         if ((rb_hit_busies_r(i)) = '1') then
            passed_ras_timer_v := ras_timer_ns_in(i * RAS_TIMER_WIDTH + RAS_TIMER_WIDTH - 1 downto i*RAS_TIMER_WIDTH);
         end if;
      end loop;
      passed_ras_timer <= passed_ras_timer_v;
   end process;

   -- RAS and (reused for) WTP timer.  When an open bank is passed, this
   -- timer is passed to the new owner.  The existing RAS prevents
   -- an activate from occuring too early.
   start_wtp_timer <= sending_col and not(rd_wr_r);
   
   process (bm_end_r1, ras_timer_r, rst, start_rcd_lcl, start_wtp_timer)
   variable ras_timer_ns_int2        : std_logic_vector(RAS_TIMER_WIDTH - 1 downto 0);
   begin
      if ((bm_end_r1 or rst) = '1') then
         ras_timer_ns_int2 := (others => '0');
      else
         ras_timer_ns_int2 := ras_timer_r;
         if (start_rcd_lcl = '1') then
            ras_timer_ns_int2 := std_logic_vector(TO_UNSIGNED(nRAS_CLKS, RAS_TIMER_WIDTH)) -
                                 std_logic_vector(TO_UNSIGNED(2,RAS_TIMER_WIDTH));
         end if;
         if (start_wtp_timer = '1') then
         --CR #534391
         --As the timer is being reused, it is essential to compare
         --before new value is loaded. There was case where timer(ras_timer_r)
         --is getting updated with a new value(nWTP_CLKS-2) at write 
         --command that was quite less than the timer value at that
         --time. This made the tRAS timer to expire earlier and resulted.
         --in tRAS timing violation.
            if ( to_integer(unsigned (ras_timer_r)) <=  nWTP_CLKS - 2 ) then
                ras_timer_ns_int2 := std_logic_vector(TO_UNSIGNED(nWTP_CLKS, RAS_TIMER_WIDTH)) -
                                     std_logic_vector(TO_UNSIGNED(2,RAS_TIMER_WIDTH));
            else
                ras_timer_ns_int2 := ras_timer_r - std_logic_vector(TO_UNSIGNED(1,RAS_TIMER_WIDTH));
            end if;
         end if;
         if ((REDUCTION_OR(ras_timer_r) and not(start_wtp_timer)) = '1') then
            ras_timer_ns_int2 := ras_timer_r - std_logic_vector(TO_UNSIGNED(1,RAS_TIMER_WIDTH));
         end if;
      end if;
      ras_timer_ns <= ras_timer_ns_int2;
      ras_timer_ns_int1 <= ras_timer_ns_int2;
   end process;

   ras_timer_passed_ns <= passed_ras_timer when (rcv_open_bank = '1') else
                          ras_timer_ns_int1;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         ras_timer_r <= ras_timer_passed_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   ras_timer_zero_ns <= '1' when (ras_timer_ns_int1 = 0) else '0';
   process (clk)
   begin
      if (clk'event and clk = '1') then
         ras_timer_zero_r <= ras_timer_zero_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   sending_col_not_rmw_rd <= sending_col and not(rd_half_rmw_lcl);
   
   process (pass_open_bank_r, rst, rtp_timer_r, sending_col_not_rmw_rd)
   variable rtp_timer_ns_v : std_logic_vector(RTP_TIMER_WIDTH - 1 downto 0);
   begin
      rtp_timer_ns_v := rtp_timer_r;
      if ((rst or pass_open_bank_r) = '1') then
         rtp_timer_ns_v := (others => '0');
      else
         if (sending_col_not_rmw_rd = '1') then
            rtp_timer_ns_v := std_logic_vector(TO_UNSIGNED(nRTP_CLKS_M1,RTP_TIMER_WIDTH)); --nRTP_CLKS_M1
         end if;
         if ((REDUCTION_OR(rtp_timer_r)) = '1') then
            rtp_timer_ns_v := rtp_timer_r - std_logic_vector(TO_UNSIGNED(1,RTP_TIMER_WIDTH ));
         end if;
      end if;
      rtp_timer_ns <= rtp_timer_ns_v;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         rtp_timer_r <= rtp_timer_ns after (TCQ)*1 ps;
      end if;
   end process;

   end_rtp_lcl <= '1' when  (pass_open_bank_r = '0' ) and 
                            ((rtp_timer_r = std_logic_vector(TO_UNSIGNED(1,RTP_TIMER_WIDTH))) or 
                            ((nRTP_CLKS_M1 = 0) and (sending_col_not_rmw_rd = '1'))) else '0';
   
   end_rtp <= end_rtp_lcl;
   
   op_mode_disabled : if (nOP_WAIT = 0) generate
      bank_wait_in_progress <= sending_col_not_rmw_rd or
                               REDUCTION_OR(rtp_timer_r) or
                               (pre_wait_r_int1 and
                               not(ras_timer_zero_r));
      start_pre_wait_int3 <= end_rtp_lcl;
      op_exit_req <= '0';
   end generate;
   
   op_mode_enabled : if (not(nOP_WAIT = 0)) generate

      bank_wait_in_progress <= sending_col or
                               REDUCTION_OR(rtp_timer_r) or
                               (pre_wait_r_int1 and
                               not(ras_timer_zero_r)) or op_wait_r;
      op_active <= not(rst) and not(passing_open_bank) and ((end_rtp_lcl and tail_r) or op_wait_r);
      op_wait_ns <= not (op_exit_grant)  and op_active ;
      
      process (clk)
      begin
         if (clk'event and clk = '1') then
            op_wait_r <= op_wait_ns after (TCQ)*1 ps;
         end if;
      end process;
      
      start_pre_wait_int3 <= op_exit_grant or (end_rtp_lcl and not(tail_r) and not(passing_open_bank));
      
      int16 : if (nOP_WAIT = -1) generate
         op_exit_req <= (low_idle_cnt_r and op_active);
      end generate;

      int17 : if (not(nOP_WAIT = -1)) generate

         op_cnt_ns <= (others => '0') when (passing_open_bank = '1' or op_exit_grant = '1'  or rst = '1') else
                      std_logic_vector(TO_UNSIGNED(nOP_WAIT,OP_WIDTH)) when (end_rtp_lcl = '1') else
                      op_cnt_r - std_logic_vector(TO_UNSIGNED(1,OP_WIDTH)) when ((REDUCTION_OR(op_cnt_r)) = '1') else
                      op_cnt_r;
         
         process (clk)
         begin
            if (clk'event and clk = '1') then
               op_cnt_r <= op_cnt_ns after (TCQ)*1 ps;
            end if;
         end process;
         --op_exit_req <= (low_idle_cnt_r and op_active) or (op_wait_r and REDUCTION_NOR(op_cnt_r));
         op_exit_req <= (op_wait_r and REDUCTION_NOR(op_cnt_r)); --Changed by KK for improving the 
                                                                 --effeciency in case of known patterns

      end generate;
   end generate;

   allow_auto_pre <= act_wait_r_lcl or rcd_active_r or (col_wait_r and not(sending_col) );
   
   -- precharge wait state machine.
   pre_wait_ns <= not(rst) and (not(pass_open_bank_ns) and (start_pre_wait_int3 or (pre_wait_r_int1 and not(start_pre))));
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         pre_wait_r_int1 <= pre_wait_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   pre_request <= pre_wait_r_int1 and ras_timer_zero_r and not(auto_pre_r);
   start_pre <= pre_wait_r_int1 and ras_timer_zero_r and (sending_row or auto_pre_r);

   int18 : if (nRP_CLKS_M2 > ZERO) generate
      process (rp_timer_r, rst, start_pre)
      begin
         if (rst = '1') then
            rp_timer_ns <= (others => '0');
         else
            rp_timer_ns <= rp_timer_r;
            if (start_pre = '1') then
               rp_timer_ns <= std_logic_vector(TO_UNSIGNED(nRP_CLKS_M2,RP_TIMER_WIDTH ));
            elsif ((REDUCTION_OR(rp_timer_r)) = '1') then
               rp_timer_ns <= rp_timer_r - std_logic_vector(TO_UNSIGNED(1,RP_TIMER_WIDTH ));
            end if;
         end if;
      end process;
      
      process (clk)
      begin
         if (clk'event and clk = '1') then
            rp_timer_r <= rp_timer_ns after (TCQ)*1 ps;
         end if;
      end process;
      
   end generate;
   precharge_bm_end <= '1' when (rp_timer_r = std_logic_vector(TO_UNSIGNED(1,RP_TIMER_WIDTH ))) or
                                (start_pre = '1'  and nRP_CLKS_M2 = 0) else '0';
   
   -- Compute RRD related activate inhibit.
   -- Compare this bank machine's rank with others, then
   -- select result based on grant.  An alternative is to
   -- select the just issued rank with the grant and simply
   -- compare against this bank machine's rank.  However, this
   -- serializes the selection of the rank and the compare processes.
   -- As implemented below, the compare occurs first, then the
   -- selection based on grant.  This is faster.
   int19 : if (RANKS = 1) generate
      process ( start_rcd_in)
      variable inhbt_act_rrd_tmp :std_logic;
      begin
         inhbt_act_rrd_tmp := '0';
         for j in (ID + 1) to  (ID + nBANK_MACHS) - 1 loop
            inhbt_act_rrd_tmp := inhbt_act_rrd_tmp or   start_rcd_in(j)  ;
         end loop;
         inhbt_act_rrd <= inhbt_act_rrd_tmp;
      end process;
   end generate;

   int20 : if (not(RANKS = 1)) generate
      process (req_rank_r, req_rank_r_in, start_rcd_in,rst)
      variable inhbt_act_rrd_tmp :std_logic;
      begin
         inhbt_act_rrd_tmp := '0';
         for j in (ID + 1) to  (ID + nBANK_MACHS) - 1 loop
            if (req_rank_r_in(j*RANK_WIDTH + RANK_WIDTH - 1 downto  j * RANK_WIDTH) = req_rank_r) then
               inhbt_act_rrd_tmp := inhbt_act_rrd_tmp or start_rcd_in(j) ;
            end if;
         end loop;
         inhbt_act_rrd <= inhbt_act_rrd_tmp;
      end process;
   end generate;

   -- Extract the activate command inhibit for the rank associated
   -- with this request.  FAW and RRD are computed separately so that
   -- gate level timing can be carefully managed.
   my_inhbt_act_faw <= inhbt_act_faw_r(conv_integer(req_rank_r));
   act_req <= not(idle_r) and head_r and act_wait_r_int0 and ras_timer_zero_r and not(wait_for_maint_r);
   
   -- Implement simple starvation avoidance for act requests.  Precharge
   -- requests don't need this because they are never gated off by
   -- timing events such as inhbt_act_rrd.  Priority request timeout
   -- is fixed at a single trip around the round robin arbiter.
   rts_act_denied <= act_req and sent_row and not(sending_row);
   process (act_req, act_starve_limit_cntr_r, rts_act_denied)
   begin
      act_starve_limit_cntr_ns <= act_starve_limit_cntr_r;
      if ((not(act_req)) = '1') then
         act_starve_limit_cntr_ns <= (others => '0');
      elsif ((rts_act_denied and REDUCTION_AND(act_starve_limit_cntr_r)) = '1') then
         act_starve_limit_cntr_ns <= act_starve_limit_cntr_r + '1';
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         act_starve_limit_cntr_r <= act_starve_limit_cntr_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   demand_act_priority_ns <= act_req and (demand_act_priority_r or
                             (rts_act_denied and REDUCTION_AND(act_starve_limit_cntr_r)));
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         demand_act_priority_r <= demand_act_priority_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   demand_act_priority <= demand_act_priority_r and not(sending_row);
   
   -- compute act_demanded from other demand_act_priorities
   int21 : if (nBANK_MACHS > 1) generate
      process (demand_act_priority_in((ID + nBANK_MACHS - 1) downto (ID + 1)))
      begin
         act_demanded <= REDUCTION_OR(demand_act_priority_in((ID + nBANK_MACHS - 1) downto (ID + 1)));
      end process;
   end generate;
   row_demand_ok <= demand_act_priority_r or not(act_demanded);
   
   -- Generate the Request To Send row arbitation signal.
   rts_row <= not(sending_row) and row_demand_ok and ((act_req and not(my_inhbt_act_faw) and
              not(inhbt_act_rrd)) or pre_request);
   
   -- Provide rank machines early knowledge that this bank machine is
   -- going to send an activate to the rank.  In this way, the rank
   -- machines just need to use the sending_row wire to figure out if
   -- they need to keep track of the activate.
   process (act_wait_r_int0, req_rank_r)
   begin
      act_this_rank_ns <= (others => '0');
      for i in 0 to  RANKS - 1 loop
         if (req_rank_r = std_logic_vector(TO_UNSIGNED(i, RANK_WIDTH))) then
              act_this_rank_ns(i) <= act_wait_r_int0;
         end if;
      end loop;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         act_this_rank_r <= act_this_rank_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   -- Generate request to send column command signal.
   req_bank_rdy_ns <= order_q_zero and col_wait_r;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         req_bank_rdy_r <= req_bank_rdy_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   -- Determine is we have been denied a column command request.
   rts_col_denied <= req_bank_rdy_r and sent_col and not(sending_col);
   
   -- Implement a starvation limit counter.  Count the number of times a
   -- request to send a column command has been denied.
   process (col_wait_r, rts_col_denied, starve_limit_cntr_r)
   begin
      if (col_wait_r = '0') then
         starve_limit_cntr_ns <= (others => '0');
      elsif (rts_col_denied = '1' and (starve_limit_cntr_r /= std_logic_vector(TO_UNSIGNED(STARVE_LIMIT_CNT - 1, STARVE_LIMIT_WIDTH)))) then
         starve_limit_cntr_ns <= starve_limit_cntr_r +  '1';
      else
         starve_limit_cntr_ns <= starve_limit_cntr_r;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         starve_limit_cntr_r <= starve_limit_cntr_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   -- Decide if this bank machine should demand priority.  Priority is demanded
   --  when starvation limit counter is reached, or a bit in the request.
   starved <= '1' when (starve_limit_cntr_r = std_logic_vector(TO_UNSIGNED(STARVE_LIMIT_CNT - 1, STARVE_LIMIT_WIDTH))) and
                       rts_col_denied = '1'
                  else '0';

   -- compute demanded from other demand_priorities
   demand_priority_ns <= not(idle_ns) and col_wait_ns and
                         (demand_priority_r or (order_q_zero and (req_priority_r or q_has_priority))
                          or (starved and (q_has_rd or not(req_wr_r)))
                         );
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         demand_priority_r <= demand_priority_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   int22 : if (nBANK_MACHS > 1) generate
      process (demand_priority_in((ID + nBANK_MACHS - 1) downto (ID + 1)))
      begin
         demanded <= REDUCTION_OR(demand_priority_in((ID + nBANK_MACHS - 1) downto (ID + 1)));
      end process;
   end generate;

   -- In order to make sure that there is no starvation amongst a possibly
   -- unlimited stream of priority requests, add a second stage to the demand
   -- priority signal.  If there are no other requests demanding priority, then
   -- go ahead and assert demand_priority.  If any other requests are asserting
   -- demand_priority, hold off asserting demand_priority until these clear, then
   -- assert demand priority.  Its possible to get multiple requests asserting
   -- demand priority simultaneously, but that's OK.  Those requests will be
   -- serviced, demanded will fall, and another group of requests will be
   -- allowed to assert demand_priority.
   demanded_prior_ns <= demanded and (demanded_prior_r or not(demand_priority_r));
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         demanded_prior_r <= demanded_prior_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   demand_priority <= demand_priority_r and not(demanded_prior_r) and not(sending_col);
   
   demand_ok <= demand_priority_r or not(demanded);
   
   -- Figure out if the request in this bank machine matches the current io
   -- configuration.
   pre_config_match_ns <= '1' when (io_config_valid_r = '1') and (io_config = not rd_wr_r & req_rank_r)
                              else '0';
   process (clk)
   begin
      if (clk'event and clk = '1') then
         pre_config_match_r <= pre_config_match_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   int23 : if (nCNFG2WR = 1) generate
      io_config_match <= pre_config_match_ns when ((not(rd_wr_r)) = '1') else
                         not(io_config_strobe) and pre_config_match_r;
      
   end generate;
   int24 : if (not(nCNFG2WR = 1)) generate
      io_config_match <= pre_config_match_r;
   end generate;

   -- Compute desire to send a column command independent of whether or not
   -- various DRAM timing parameters are met.  Ignoring DRAM timing parameters is
   -- necessary to insure priority.  This is used to drive the demand
   -- priority signal.
   early_config <= allow_early_wr_config when ((not(rd_wr_r)) = '1') else
                   allow_early_rd_config;
   
   -- Using rank state provided by the rank machines, figure out if
   -- a io configs should wait for WTR.
   my_wtr_inhbt_config <= wtr_inhbt_config_r(conv_integer(req_rank_r));
  
   inhbt_config <=  (not inhbt_wr_config) when ((not(rd_wr_r)) = '1') else
                    (not inhbt_rd_config);
  
   rtc <= not(io_config_match) and order_q_zero and 
          (col_wait_r or early_config) and 
          demand_ok and not(my_wtr_inhbt_config) and inhbt_config;
          
   -- Using rank state provided by the rank machines, figure out if
   -- a read requests should wait for WTR.
   my_inhbt_rd <= inhbt_rd_r(conv_integer(req_rank_r));
   
   allow_rw <= '1' when ((not(rd_wr_r)) = '1') else
               not(my_inhbt_rd);
   -- Column command is ready to arbitrate, except for databus restrictions.
   col_rdy <= '1' when (col_wait_r = '1' or 
                     ((nRCD_CLKS <= 1) and end_rcd = '1' ) or 
                      (rcv_open_bank = '1' and (DRAM_TYPE = "DDR2") and (BURST_MODE = "4"))) and order_q_zero = '1' else '0';
   
   -- Column command is ready to arbitrate for sending a write.  Used
   -- to generate early wr_data_addr for ECC mode.
   col_rdy_wr <= col_rdy and not(rd_wr_r);
   
   -- Figure out if we're ready to send a column command based on all timing
   -- constraints.  Use of io_config_match could be replaced by later versions
   -- if timing is an issue.
   col_cmd_rts <= col_rdy and not(dq_busy_data) and allow_rw and io_config_match;
  
  -- Disable priority feature for one state after a config to insure
  -- forward progress on the just installed io config.
  override_demand_ns <= io_config_strobe;
      
   process (clk)
   begin
      if (clk'event and clk = '1') then
         override_demand_r <= override_demand_ns;
      end if;
   end process;
   
   rts_col <= not(sending_col) and (demand_ok or override_demand_r) and col_cmd_rts;
   
   -- As in act_this_rank, wr/rd_this_rank informs rank machines
   -- that this bank machine is doing a write/rd.  Removes logic
   -- after the grant.
   process (rd_wr_r, req_rank_r)
   variable wr_this_rank_ns_v : std_logic_vector(RANKS - 1 downto 0);
   variable rd_this_rank_ns_v : std_logic_vector(RANKS - 1 downto 0);
   begin
      wr_this_rank_ns_v := (others => '0' );
      rd_this_rank_ns_v := (others => '0' );
      for i in 0 to  RANKS - 1 loop
         if (req_rank_r = std_logic_vector(TO_UNSIGNED(i,RANK_WIDTH))) then
            wr_this_rank_ns_v(i) := not rd_wr_r;
            rd_this_rank_ns_v(i) := rd_wr_r ;
         end if;
      end loop;
      wr_this_rank_ns <= wr_this_rank_ns_v;
      rd_this_rank_ns <= rd_this_rank_ns_v;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         wr_this_rank_r <= wr_this_rank_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         rd_this_rank_r <= rd_this_rank_ns after (TCQ)*1 ps;            -- bank_state
      end if;
   end process;
   
   
end architecture trans;
