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
--  /   /         Filename              : bank_queue.vhd
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
   use ieee.std_logic_arith.all;

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


-- Bank machine queue controller.
--
-- Bank machines are always associated with a queue.  When the system is
-- idle, all bank machines are in the idle queue.  As requests are
-- received, the bank machine at the head of the idle queue accepts
-- the request, removes itself from the idle queue and places itself
-- in a queue associated with the rank-bank of the new request.
--
-- If the new request is to an idle rank-bank, a new queue is created
-- for that rank-bank.  If the rank-bank is not idle, then the new
-- request is added to the end of the existing rank-bank queue.
--
-- When the head of the idle queue accepts a new request, all other
-- bank machines move down one in the idle queue.  When the idle queue
-- is empty, the memory interface deasserts its accept signal.
--
-- When new requests are received, the first step is to classify them
-- as to whether the request targets an already open rank-bank, and if
-- so, does the new request also hit on the already open page?  As mentioned
-- above, a new request places itself in the existing queue for a
-- rank-bank hit.  If it is also detected that the last entry in the
-- existing rank-bank queue has the same page, then the current tail
-- sets a bit telling itself to pass the open row when the column
-- command is issued.  The "passee" knows its in the head minus one
-- position and hence takes control of the rank-bank.
--
-- Requests are retired out of order to optimize DRAM array resources.
-- However it is required that the user cannot "observe" this out of
-- order processing as a data corruption.  An ordering queue is
-- used to enforce some ordering rules.  As controlled by a paramter,
-- there can be no ordering (RELAXED), ordering of writes only (NORM), and
-- strict (STRICT) ordering whereby input request ordering is
-- strictly adhered to.
--
-- Note that ordering applies only to column commands.  Row commands
-- such as activate and precharge are allowed to proceed in any order
-- with the proviso that within a rank-bank row commands are processed in
-- the request order.
--
-- When a bank machine accepts a new request, it looks at the ordering
-- mode.  If no ordering, nothing is done.  If strict ordering, then
-- it always places itself at the end of the ordering queue.  If "normal"
-- or write ordering, the row machine places itself in the ordering
-- queue only if the new request is a write.  The bank state machine
-- looks at the ordering queue, and will only issue a column
-- command when it sees itself at the head of the ordering queue.
--
-- When a bank machine has completed its request, it must re-enter the
-- idle queue.  This is done by setting the idle_r bit, and setting q_entry_r
-- to the idle count.
--
-- There are several situations where more than one bank machine
-- will enter the idle queue simultaneously.  If two or more
-- simply use the idle count to place themselves in the idle queue, multiple
-- bank machines will end up at the same location in the idle queue, which
-- is illegal.
--
-- Based on the bank machine instance numbers, a count is made of
-- the number of bank machines entering idle "below" this instance.  This
-- number is added to the idle count to compute the location in
-- idle queue.
--
-- There is also a single bit computed that says there were bank machines
-- entering the idle queue "above" this instance.  This is used to
-- compute the tail bit.
--
-- The word "queue" is used frequently to describe the behavior of the
-- bank_queue block.  In reality, there are no queues in the ordinary sense.
-- As instantiated in this block, each bank machine has a q_entry_r number.
-- This number represents the position of the bank machine in its current
-- queue.  At any given time, a bank machine may be in the idle queue,
-- one of the dynamic rank-bank queues, or a single entry manitenance queue.
-- A complete description of which queue a bank machine is currently in is
-- given by idle_r, its rank-bank, mainteance status and its q_entry_r number.
--
-- DRAM refresh and ZQ have a private single entry queue/channel.  However,
-- when a refresh request is made, it must be injected into the main queue
-- properly.  At the time of injection, the refresh rank is compared against
-- all entryies in the queue.  For those that match, if timing allows, and
-- they are the tail of the rank-bank queue, then the auto_pre bit is set.
-- Otherwise precharge is in progress.  This results in a fully precharged
-- rank.
--
--  At the time of injection, the refresh channel builds a bit
-- vector of queue entries that hit on the refresh rank.  Once all
-- of these entries finish, the refresh is forced in at the row arbiter.
--
-- New requests that come after the refresh request will notice that
-- a refresh is in progress for their rank and wait for the refresh
-- to finish before attempting to arbitrate to send an activate.
--
-- Injection of a refresh sets the q_has_rd bit for all queues hitting
-- on the refresh rank.  This insures a starved write request will not
-- indefinitely hold off a refresh.
--
-- Periodic reads are required to compare themselves against requests
-- that are in progress.  Adding a unique compare channel for this
-- is not worthwhile.  Periodic read requests inhibit the accept
-- signal and override any new request that might be trying to
-- enter the queue.
--
-- Once a periodic read has entered the queue it is nearly indistinguishable
-- from a normal read request.  The req_periodic_rd_r bit is set for
-- queue entry.  This signal is used to inhibit the rd_data_en signal.

entity bank_queue is
   generic (
      TCQ                    : integer := 100;
      BM_CNT_WIDTH           : integer := 2;
      nBANK_MACHS            : integer := 4;
      ORDERING               : string := "NORM";
      ID                     : integer := 0

   );
   port (
      
      head_r                 : out std_logic;
      
      -- Determine if this entry is the tail of its queue.  Note that
      -- an entry can be both head and tail.
      -- The order of the statements below is important in the case where
      -- another bank machine is retiring and this bank machine is accepting.
      -- if (nBANK_MACHS > 1)
      tail_r                 : out std_logic;
      
      -- Is this entry in the idle queue?
      idle_ns                : out std_logic;
      idle_r                 : out std_logic;
      
      -- Maintenance hitting on this active bank machine is in progress.
      
      -- Does new request hit on this bank machine while it is able to pass the
      -- open bank?
      
      -- Set pass open bank bit, but not if request preceded active maintenance.
      pass_open_bank_ns      : out std_logic;
      pass_open_bank_r       : out std_logic;
      
      -- Should the column command be sent with the auto precharge bit set?  This
      -- will happen when it is detected that next request is to a different row,
      -- or the next reqest is the next request is refresh to this rank.
      auto_pre_r             : out std_logic;
      
      -- Determine when the current request is finished.
      bm_end                 : out std_logic;
      
      -- Determine that the open bank should be passed to the successor bank machine.
      passing_open_bank      : out std_logic;
      
      ordered_issued         : out std_logic;
      
      -- Should never see accept_this_bm and adv_order_q at the same time.
      ordered_r              : out std_logic;
      
      -- Figure out when to advance the ordering queue.
      
      order_q_zero           : out std_logic;
      
      -- Keep track of which other bank machine are ahead of this one in a
      -- rank-bank queue.  This is necessary to know when to advance this bank
      -- machine in the queue, and when to update bank state machine counter upon
      -- passing a bank.
      rcv_open_bank          : out std_logic;           --= 1'b0;
      
      -- The clear_vector resets bits in the rb_hit_busies vector as bank machines
      -- completes requests.  rst also resets all the bits.
      
      -- As this bank machine takes on a new request, capture the vector of
      -- which other bank machines are in the same queue.
      
      -- Compute when to advance this queue entry based on seeing other bank machines
      -- in the same queue finish.
      
      -- Decide when to receive an open bank based on knowing this bank machine is
      -- one entry from the head, and a passing_open_bank hits on the
      -- rb_hit_busies vector.
      rb_hit_busies_r        : out std_logic_vector(nBANK_MACHS * 2 - 1 downto 0);
      
      -- Keep track if the queue this entry is in has priority content.
      q_has_rd               : out std_logic;
      
      q_has_priority         : out std_logic;
      
      -- Figure out if this entry should wait for maintenance to end.
      wait_for_maint_r       : out std_logic;
      clk                    : in std_logic;
      rst                    : in std_logic;
      accept_internal_r      : in std_logic;
      use_addr               : in std_logic;
      periodic_rd_ack_r      : in std_logic;
      bm_end_in              : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
      idle_cnt               : in std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      rb_hit_busy_cnt        : in std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      accept_req             : in std_logic;
      rb_hit_busy_r          : in std_logic;
      maint_idle             : in std_logic;
      maint_hit              : in std_logic;
      row_hit_r              : in std_logic;
      pre_wait_r             : in std_logic;
      allow_auto_pre         : in std_logic;
      sending_col            : in std_logic;
      bank_wait_in_progress  : in std_logic;
      precharge_bm_end       : in std_logic;
      req_wr_r               : in std_logic;
      rd_wr_r                : in std_logic;
      adv_order_q            : in std_logic;
      order_cnt              : in std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      rb_hit_busy_ns_in      : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
      passing_open_bank_in   : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
      was_wr                 : in std_logic;
      maint_req_r            : in std_logic;
      was_priority           : in std_logic
   );
end entity bank_queue;

architecture trans of bank_queue is

   constant    BM_CNT_ZERO          : std_logic_vector(BM_CNT_WIDTH - 1 downto 0) := (others => '0');
   constant    BM_CNT_ONE             : std_logic_vector(BM_CNT_WIDTH - 1 downto 0) := conv_std_logic_vector(1, BM_CNT_WIDTH);
   --     localparam [BM_CNT_WIDTH-1:0] BM_CNT_ONE = ONE[0+:BM_CNT_WIDTH];

--   FUNCTION or_br (
--      val : bit_vector) RETURN bit IS
--   
--      VARIABLE rtn : bit := '0';
--   BEGIN
--      FOR index IN val'RANGE LOOP
--         rtn := rtn OR val(index);
--      END LOOP;
--      RETURN(rtn);
--   END or_br;


function REDUCTION_NOR( A: in std_logic_vector) return std_logic is
  variable tmp : std_logic := '0';
begin
  for i in A'range loop
       tmp := tmp or A(i);
  end loop;
  return not tmp;
end function REDUCTION_NOR;
              
function REDUCTION_OR( A: in std_logic_vector) return std_logic is
  variable tmp : std_logic := '0';
begin
  for i in A'range loop
       tmp := tmp or A(i);
  end loop;
  return tmp;
end function REDUCTION_OR;

function CALC_IDLERS (idlers_below:in std_logic_vector; bm_end_in: in std_logic_vector)
return std_logic_vector is
variable idlers_below_tmp : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
begin
      idlers_below_tmp := idlers_below;
      for i in 0 to  ID - 1 loop
         idlers_below_tmp := idlers_below_tmp + bm_end_in(i);
      end loop;
      return idlers_below_tmp;
end function CALC_IDLERS;

   signal idle_r_lcl               : std_logic;
   signal head_r_lcl               : std_logic;
   signal bm_ready                 : std_logic;
   signal accept_this_bm           : std_logic;
   signal idlers_below             : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal i                        : integer;
   signal idlers_above             : std_logic;
   signal bm_end_lcl               : std_logic;
   signal adv_queue                : std_logic := '0';
   signal q_entry_r                : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal q_entry_ns               : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal head_ns                  : std_logic;
   signal tail_r_lcl               : std_logic := '1';
   signal clear_req                : std_logic;
   signal idle_ns_lcl              : std_logic;
   signal maint_hit_this_bm        : std_logic;
   signal pass_open_bank_eligible  : std_logic;
   signal wait_for_maint_r_lcl     : std_logic;
   signal pass_open_bank_r_lcl     : std_logic;
   signal pass_open_bank_ns_lcl    : std_logic;
   signal auto_pre_r_lcl           : std_logic;
   signal auto_pre_ns              : std_logic;
   signal sending_col_not_rmw_rd   : std_logic;
   signal pre_bm_end_r             : std_logic;
   signal pre_bm_end_ns            : std_logic;
   signal pre_passing_open_bank_r  : std_logic;
   signal pre_passing_open_bank_ns : std_logic;
   signal ordered_ns               : std_logic;
   signal set_order_q              : std_logic;
   signal ordered_issued_lcl       : std_logic;
   signal ordered_r_lcl            : std_logic;
   signal order_q_r                : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal order_q_ns               : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal rb_hit_busies_r_lcl      : std_logic_vector((nBANK_MACHS * 2) - 1 downto 0) := (others => '0');
   signal q_has_rd_r               : std_logic;
   signal q_has_rd_ns              : std_logic;
   signal q_has_priority_r         : std_logic;
   signal q_has_priority_ns        : std_logic;
   signal wait_for_maint_ns        : std_logic;
   
   signal tail_ns                  : std_logic;
   signal clear_vector             : std_logic_vector(nBANK_MACHS-2 downto 0);
   signal rb_hit_busies_ns         : std_logic_vector(ID+nBANK_MACHS-1 downto ID+1);
   -- X-HDL generated signals  `define BM_SHARED_BV (ID+nBANK_MACHS-1):(ID+1)

   signal adv_queue_value : std_logic;
   signal accep_req_value : std_logic;
   
   
   --constant BM_CNT_ONE
begin
  -- idle_r_lcl                                  OK
   bm_ready <= idle_r_lcl and head_r_lcl and accept_internal_r;
   accept_this_bm <= bm_ready and (use_addr or periodic_rd_ack_r);
   process (bm_end_in)
   begin
      --idlers_below <= (others => '0');
      --for i in 0 to  ID - 1 loop
      --   idlers_below <= idlers_below + bm_end_in(i);
      --end loop;
      idlers_below <= CALC_IDLERS(conv_std_logic_vector(0,BM_CNT_WIDTH),bm_end_in);
   end process;
   
   
   process (bm_end_in)
   begin
      idlers_above <= '0';
     -- for i in ID + 1 to  ID + nBANK_MACHS - 1 loop
         idlers_above <= REDUCTION_OR(bm_end_in(ID + nBANK_MACHS - 1 downto  ID +1));  -- need to come back
     -- end loop;
   end process;
   
   adv_queue_value <= '1' when (adv_queue = '1') else '0';
   process (accept_req, accept_this_bm, adv_queue, bm_end_lcl, idle_cnt, idle_r_lcl, idlers_below, q_entry_r, rb_hit_busy_cnt, rst)
   variable q_entry_ns_v : std_logic_vector(BM_CNT_WIDTH -1  downto 0);
   
   begin
      if (rst = '1') then
         q_entry_ns_v := conv_std_logic_vector(ID,BM_CNT_WIDTH );
      else
         q_entry_ns_v := q_entry_r;
         if ((idle_r_lcl = '0' and adv_queue = '1') or  (idle_r_lcl = '1'  and accept_req = '1' and accept_this_bm= '0')) then

              q_entry_ns_v := conv_std_logic_vector(conv_integer(q_entry_r) - 1,BM_CNT_WIDTH);
         end if;
         if (accept_this_bm = '1') then
            if (adv_queue = '1') then
                q_entry_ns_v := rb_hit_busy_cnt - '1';
            else
                q_entry_ns_v := rb_hit_busy_cnt ;
            end if;
            
         end if;
         if (bm_end_lcl = '1') then
            q_entry_ns_v := idle_cnt + idlers_below;
            if (accept_req = '1') then
               q_entry_ns_v := q_entry_ns_v - '1';
            end if;
         end if;
         
      end if;
         q_entry_ns <= q_entry_ns_v;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         q_entry_r <= q_entry_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   accep_req_value <= '1' when (accept_req = '1') else
                '0';
   -- accept_this_bm is not correct   
   --   bm_ready <= idle_r_lcl and head_r_lcl and accept_internal_r;
   --   accept_this_bm <= bm_ready and (use_addr or periodic_rd_ack_r);

   
   
   process (accept_req,accep_req_value, accept_this_bm, adv_queue, bm_end_lcl, head_r_lcl, idle_cnt, idle_r_lcl, idlers_below, q_entry_r, rb_hit_busy_cnt, rst,adv_queue_value)
   variable head_ns_v : std_logic;
   begin
      if (rst = '1') then
         head_ns_v :=  REDUCTION_NOR(conv_std_logic_vector(ID,BM_CNT_WIDTH ));
      else
         head_ns_v := head_r_lcl;
         if (accept_this_bm = '1') then
            head_ns_v :=  REDUCTION_NOR((rb_hit_busy_cnt - adv_queue_value));
         end if;
         if (((not(idle_r_lcl) and adv_queue) or (idle_r_lcl and accept_req and not(accept_this_bm))) = '1') then
            head_ns_v :=  REDUCTION_NOR((q_entry_r - BM_CNT_ONE));
            
         end if;
         if (bm_end_lcl = '1') then
            head_ns_v :=  REDUCTION_NOR(idle_cnt - accep_req_value) and REDUCTION_NOR(idlers_below);
         end if;
         
         
      end if;
      
      head_ns <= head_ns_v;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         head_r_lcl <= head_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   head_r <= head_r_lcl;
   
   
    xhdl3 : if (nBANK_MACHS > 1) generate
      process (accept_req, accept_this_bm, bm_end_in, bm_end_lcl, idle_r_lcl, idlers_above, rb_hit_busy_r, rst, tail_r_lcl)
      variable tail_ns_v : std_logic;
      begin
         if (rst = '1') then
            
            if (ID = nBANK_MACHS) then
                tail_ns_v := '1';
            else
                tail_ns_v := '0';
            end if;
         else
            tail_ns_v := tail_r_lcl;
            if ((accept_req = '1' and rb_hit_busy_r = '1' ) or
               (REDUCTION_OR(bm_end_in(ID + nBANK_MACHS - 1 downto ID + 1)) = '1' and idle_r_lcl = '1')) then

               tail_ns_v := '0';
            end if;
            if (accept_this_bm = '1' or (bm_end_lcl = '1'  and idlers_above = '0')) then
               tail_ns_v := '1';
            end if;
            
         end if;
         
         tail_ns <= tail_ns_v;
      end process;
      
      process (clk)
      begin
         if (clk'event and clk = '1') then
            tail_r_lcl <= tail_ns after (TCQ)*1 ps;
         end if;
      end process;
      
   end generate;
   tail_r <= tail_r_lcl;
   clear_req <= bm_end_lcl or rst;
   process (accept_this_bm, clear_req, idle_r_lcl)
   variable idle_ns_lcl_v : std_logic;
   begin
      idle_ns_lcl <= idle_r_lcl;
      if (accept_this_bm = '1') then
         idle_ns_lcl <= '0';
      end if;
      if (clear_req = '1') then
         idle_ns_lcl <= '1' after 1 ps;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         idle_r_lcl <= idle_ns_lcl after (TCQ)*1 ps;
      end if;
   end process;
   
   idle_ns <= idle_ns_lcl;
   idle_r <= idle_r_lcl;
   maint_hit_this_bm <= not(maint_idle) and maint_hit;
   
   --                                            ok
   pass_open_bank_eligible <= tail_r_lcl and rb_hit_busy_r and row_hit_r and not(pre_wait_r);
   pass_open_bank_ns_lcl <= not(clear_req) and (pass_open_bank_r_lcl or (accept_req and pass_open_bank_eligible and (not(maint_hit_this_bm) or wait_for_maint_r_lcl)));
   process (clk)
   begin
      if (clk'event and clk = '1') then
         pass_open_bank_r_lcl <= pass_open_bank_ns_lcl after (TCQ)*1 ps;
      end if;
   end process;
   
   pass_open_bank_ns <= pass_open_bank_ns_lcl;
   pass_open_bank_r <= pass_open_bank_r_lcl;
   process (accept_req, allow_auto_pre, auto_pre_r_lcl, clear_req, maint_hit_this_bm, rb_hit_busy_r, row_hit_r, tail_r_lcl, wait_for_maint_r_lcl)
   begin
      auto_pre_ns <= auto_pre_r_lcl;
      if (clear_req = '1') then
         auto_pre_ns <= '0';
      elsif ((accept_req and tail_r_lcl and allow_auto_pre and rb_hit_busy_r and (not(row_hit_r) or (maint_hit_this_bm and not(wait_for_maint_r_lcl)))) = '1') then
         auto_pre_ns <= '1';
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         auto_pre_r_lcl <= auto_pre_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   auto_pre_r <= auto_pre_r_lcl;
   sending_col_not_rmw_rd <= sending_col and not((req_wr_r and rd_wr_r));
   pre_bm_end_ns <= precharge_bm_end or (bank_wait_in_progress and pass_open_bank_ns_lcl);
   process (clk)
   begin
      if (clk'event and clk = '1') then
         pre_bm_end_r <= pre_bm_end_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   bm_end_lcl <= pre_bm_end_r or (sending_col_not_rmw_rd and pass_open_bank_r_lcl);
   bm_end <= bm_end_lcl;
   pre_passing_open_bank_ns <= bank_wait_in_progress and pass_open_bank_ns_lcl;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         pre_passing_open_bank_r <= pre_passing_open_bank_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   passing_open_bank <= pre_passing_open_bank_r or (sending_col_not_rmw_rd and pass_open_bank_r_lcl);
   
   set_order_q <= '1' when ((ORDERING = "STRICT") or ((ORDERING = "NORM") and req_wr_r = '1' )) and accept_this_bm = '1' else '0';
   ordered_issued_lcl <= '1' when sending_col_not_rmw_rd = '1'  and not(req_wr_r = '1' and rd_wr_r ='1') and 
                               ((ORDERING = "STRICT") or ((ORDERING = "NORM") and req_wr_r = '1')) 
                         else '0';
                         
   ordered_issued <= ordered_issued_lcl;
   process (ordered_issued_lcl, ordered_r_lcl, rst, set_order_q)
   begin
      if (rst = '1') then
         ordered_ns <= '0';
      else
         ordered_ns <= ordered_r_lcl;
         if (set_order_q = '1') then
            ordered_ns <= '1';
         end if;
         if (ordered_issued_lcl = '1') then
            ordered_ns <= '0';
         end if;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         ordered_r_lcl <= ordered_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   ordered_r <= ordered_r_lcl;
   process (adv_order_q, order_cnt, order_q_r, rst, set_order_q)
   begin
      order_q_ns <= order_q_r;
      if (rst = '1') then
         order_q_ns <= BM_CNT_ZERO;
      end if;
      if (set_order_q = '1') then
         if (adv_order_q = '1') then
            order_q_ns <= order_cnt - BM_CNT_ONE;
         else
            order_q_ns <= order_cnt;
         end if;
      end if;
      if ((adv_order_q and REDUCTION_OR(order_q_r)) = '1') then
         order_q_ns <= order_q_r - BM_CNT_ONE;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         order_q_r <= order_q_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   order_q_zero <= '1' when (REDUCTION_NOR(order_q_r)= '1' or 
                      (adv_order_q = '1' and ( order_q_r = conv_std_logic_vector(1,BM_CNT_WIDTH))) or 
                           (ORDERING = "NORM" and rd_wr_r = '1' )) else '0';
                           
                           
   xhdl4 : if (nBANK_MACHS > 1) generate
   
      clear_vector <= (others => '1') when rst = '1' else bm_end_in(ID + nBANK_MACHS - 1 downto ID + 1);
      
                          
                          
      process(clear_vector,rb_hit_busy_ns_in,idle_ns_lcl,rb_hit_busies_r_lcl)
      begin
      if (idle_ns_lcl = '1' ) then
            rb_hit_busies_ns <=  not (clear_vector) and rb_hit_busy_ns_in(ID + nBANK_MACHS - 1 downto ID + 1);
      else
            rb_hit_busies_ns <=  not (clear_vector) and rb_hit_busies_r_lcl(ID + nBANK_MACHS - 1 downto ID + 1);
      end if;
      end process;
                          
      process (clk)
      begin
         if (clk'event and clk = '1') then
            rb_hit_busies_r_lcl((ID + nBANK_MACHS - 1) downto (ID + 1)) <= rb_hit_busies_ns after (TCQ)*1 ps;
         end if;
      end process;

-- Compute when to advance this queue entry based on seeing other bank machines
-- in the same queue finish.

      
      process (bm_end_in, rb_hit_busies_r_lcl)
      begin
         adv_queue <= REDUCTION_OR((bm_end_in((ID + nBANK_MACHS - 1) downto (ID + 1)) and rb_hit_busies_r_lcl((ID + nBANK_MACHS - 1) downto (ID + 1))));
      end process;
      
      
-- Decide when to receive an open bank based on knowing this bank machine is
-- one entry from the head, and a passing_open_bank hits on the
-- rb_hit_busies vector.
     
      process (idle_r_lcl, passing_open_bank_in, q_entry_r, rb_hit_busies_r_lcl)
      begin
           
           if  (REDUCTION_OR(rb_hit_busies_r_lcl(ID + nBANK_MACHS - 1  downto ID + 1) and 
                             passing_open_bank_in(ID + nBANK_MACHS - 1 downto ID + 1)) = '1') and
                 (q_entry_r = conv_std_logic_vector(1,BM_CNT_WIDTH)) and (idle_r_lcl ='0') then
            
                 rcv_open_bank <= '1';
           else
                 rcv_open_bank <= '0';
           end if;
                              
      end process;
      
   end generate;
   rb_hit_busies_r <= rb_hit_busies_r_lcl;
   q_has_rd_ns <= not(clear_req) and (q_has_rd_r or (accept_req and rb_hit_busy_r and not(was_wr)) or (maint_req_r and maint_hit and not(idle_r_lcl)));
   process (clk)
   begin
      if (clk'event and clk = '1') then
         q_has_rd_r <= q_has_rd_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   q_has_rd <= q_has_rd_r;
   q_has_priority_ns <= not(clear_req) and (q_has_priority_r or (accept_req and rb_hit_busy_r and was_priority));
   process (clk)
   begin
      if (clk'event and clk = '1') then
         q_has_priority_r <= q_has_priority_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   q_has_priority <= q_has_priority_r;
   wait_for_maint_ns <= not(rst) and not(maint_idle) and (wait_for_maint_r_lcl or (maint_hit and accept_this_bm));
   process (clk)
   begin
      if (clk'event and clk = '1') then
         wait_for_maint_r_lcl <= wait_for_maint_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   wait_for_maint_r <= wait_for_maint_r_lcl;
   
end architecture trans;



-- bank_queue
