--LIBRARY xtek;
--   USE xtek.XHDL_std_logic.all;
LIBRARY ieee;
   USE ieee.std_logic_1164.all;
   USE ieee.std_logic_unsigned.all;
   USE ieee.numeric_std.all;
LIBRARY unisim;
   USE unisim.VCOMPONENTS.all;
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
--  /   /         Filename              : ui_wr_data.v
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

-- User interface write data buffer.  Consists of four counters,
-- a pointer RAM and the write data storage RAM.
--
-- All RAMs are implemented with distributed RAM.
--
-- Whe ordering is set to STRICT or NORM, data moves through
-- the write data buffer in strictly FIFO order.  In RELAXED
-- mode, data may be retired from the write data RAM in any
-- order relative to the input order.  This implementation
-- supports all ordering modes.
--
-- The pointer RAM stores a list of pointers to the write data storage RAM.
-- This is a list of vacant entries.  As data is written into the RAM, a
-- pointer is pulled from the pointer RAM and used to index the write
-- operation.  In a semi autonomously manner, pointers are also pulled, in
-- the same order, and provided to the command port as the data_buf_addr.
--
-- When the MC reads data from the write data buffer, it uses the
-- data_buf_addr provided with the command to extract the data from the
-- write data buffer.  It also writes this pointer into the end
-- of the pointer RAM.
--
-- The occupancy counter keeps track of how many entries are valid
-- in the write data storage RAM.  app_wdf_rdy and app_rdy will be
-- de-asserted when there is no more storage in the write data buffer.
--
-- Three sequentially incrementing counters/indexes are used to maintain
-- and use the contents of the pointer RAM.
--
-- The write buffer write data address index generates the pointer
-- used to extract the write data address from the pointer RAM.  It
-- is incremented with each buffer write.  The counter is actually one
-- ahead of the current write address so that the actual data buffer
-- write address can be registered to give a full state to propagate to
-- the write data distributed RAMs.
--
-- The data_buf_addr counter is used to extract the data_buf_addr for
-- the command port.  It is incremented as each command is written
-- into the MC.
--
-- The read data index points to the end of the list of free
-- buffers.  When the MC fetches data from the write data buffer, it
-- provides the buffer address.  The buffer address is used to fetch
-- the data, but is also written into the pointer at the location indicated
-- by the read data index.
--
-- Enter and exiting a buffer full condition generates corner cases.  Upon
-- entering a full condition, incrementing the write buffer write data
-- address index must be inhibited.  When exiting the full condition,
-- the just arrived pointer must propagate through the pointer RAM, then
-- indexed by the current value of the write buffer write data
-- address counter, the value is registered in the write buffer write
-- data address register, then the counter can be advanced.
--
-- The pointer RAM must be initialized with valid data after reset.  This is
-- accomplished by stepping through each pointer RAM entry and writing
-- the locations address into the pointer RAM.  For the FIFO modes, this means
-- that buffer address will always proceed in a sequential order.  In the
-- RELAXED mode, the original write traversal will be in sequential
-- order, but once the MC begins to retire out of order, the entries in
-- the pointer RAM will become randomized.  The ui_rd_data module provides
-- the control information for the initialization process.

ENTITY ui_wr_data IS
   GENERIC (
      TCQ                   : INTEGER := 100;
      APP_DATA_WIDTH        : INTEGER := 256;
      APP_MASK_WIDTH        : INTEGER := 32;
      ECC                   : STRING := "OFF";
      ECC_TEST              : STRING := "OFF";
      CWL                   : INTEGER := 5
   );
   PORT (
      -- Outputs
      -- Inputs
      
      -- Be explicit about the latch enable on these registers.
      
      -- The signals wr_data_addr and wr_data_offset come at different
      -- times depending on ECC and the value of CWL.  The data portion
      -- always needs to look a the raw wires, the control portion needs
      -- to look at a delayed version when ECC is on and CWL != 8.
      
      -- rd_data_cnt is the pointer RAM index for data read from the write data
      -- buffer.  Ie, its the data on its way out to the DRAM.
      
      -- data_buf_addr_cnt generates the pointer for the pointer RAM on behalf
      -- of data buf address that comes with the wr_data_en.
      -- The data buf address is written into the memory
      -- controller along with the command and address.
      
      -- Control writing data into the write data buffer.
      
      -- For pointer RAM.  Initialize to one since this is one ahead of
      -- what's being registered in wb_wr_data_addr.  Assumes pointer RAM
      -- has been initialized such that address equals contents.
      
      -- Take pointer from pointer RAM and set into the write data address.
      -- Needs to be split into zeroth bit and everything else because synthesis
      -- tools don't always allow assigning bit vectors seperately.  Bit zero of the
      -- address is computed via an entirely different algorithm.
      
      -- If we see the first getting accepted, then
      -- second half is unconditionally accepted.
      
      -- Keep track of how many entries in the queue hold data.
      app_wdf_rdy           : OUT STD_LOGIC;
      -- case ({wr_data_end, rd_data_upd_indx_r})
      
      -- block: occupied_counter
      
      -- Keep track of how many write requests are in the memory controller.  We
      -- must limit this to 16 because we only have that many data_buf_addrs to
      -- hand out.  Since the memory controller queue and the write data buffer
      -- queue are distinct, the number of valid entries can be different.
      -- Throttle request acceptance once there are sixteen write requests in
      -- the memory controller.  Note that there is still a requirement
      -- for a write reqeusts corresponding write data to be written into the
      -- write data queue with two states of the request.
      wr_req_16             : OUT STD_LOGIC;
      -- case ({wr_accepted, rd_data_upd_indx_r})
      
      -- block: wr_req_counter
      
      -- Instantiate pointer RAM.  Made up of RAM32M in single write, two read
      -- port mode, 2 bit wide mode.
      wr_data_buf_addr      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      -- block : rams
      -- block: pointer_ram
      
      -- Instantiate write data buffer.  Depending on width of DQ bus and
      -- DRAM CK to fabric ratio, number of RAM32Ms is variable.  RAM32Ms are
      -- used in single write, single read, 6 bit wide mode.
      
      -- block: wr_buffer_ram
      
      wr_data               : OUT STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
      wr_data_mask          : OUT STD_LOGIC_VECTOR(APP_MASK_WIDTH - 1 DOWNTO 0);
      raw_not_ecc           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      rst                   : IN STD_LOGIC;
      clk                   : IN STD_LOGIC;
      app_wdf_data          : IN STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
      app_wdf_mask          : IN STD_LOGIC_VECTOR(APP_MASK_WIDTH - 1 DOWNTO 0);
      app_raw_not_ecc       : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      app_wdf_wren          : IN STD_LOGIC;
      app_wdf_end           : IN STD_LOGIC;
      wr_data_offset        : IN STD_LOGIC;
      wr_data_addr          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      wr_data_en            : IN STD_LOGIC;
      wr_accepted           : IN STD_LOGIC;
      ram_init_done_r       : IN STD_LOGIC;
      ram_init_addr         : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
   );
END ENTITY ui_wr_data;

ARCHITECTURE trans OF ui_wr_data IS
   SIGNAL app_wdf_data_r1            : STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
   SIGNAL app_wdf_mask_r1            : STD_LOGIC_VECTOR(APP_MASK_WIDTH - 1 DOWNTO 0);
   SIGNAL app_raw_not_ecc_r1         : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
   SIGNAL app_wdf_wren_r1            : STD_LOGIC;
   SIGNAL app_wdf_end_r1             : STD_LOGIC;
   SIGNAL app_wdf_rdy_r              : STD_LOGIC;
   SIGNAL app_wdf_data_ns1           : STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
   SIGNAL app_wdf_mask_ns1           : STD_LOGIC_VECTOR(APP_MASK_WIDTH - 1 DOWNTO 0);
   SIGNAL app_wdf_wren_ns1           : STD_LOGIC;
   SIGNAL app_wdf_end_ns1            : STD_LOGIC;
   SIGNAL wr_data_offset_r           : STD_LOGIC;
   SIGNAL wr_data_addr_r             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL new_rd_data                : STD_LOGIC;
   SIGNAL rd_data_indx_r             : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL rd_data_upd_indx_r         : STD_LOGIC;
   SIGNAL data_buf_addr_cnt_r        : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL wdf_rdy_ns                 : STD_LOGIC;
   SIGNAL wr_data_end                : STD_LOGIC;
   SIGNAL wr_data_pntr               : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL wb_wr_data_addr            : STD_LOGIC_VECTOR(4 DOWNTO 0);
   SIGNAL wr_data_indx_r             : STD_LOGIC_VECTOR(3 DOWNTO 0);

   CONSTANT PNTR_RAM_CNT             : INTEGER := 2;

   FUNCTION CALC_WR_BUF_WIDTH (APP_DATA_WIDTH,APP_MASK_WIDTH: INTEGER; ECC_TEST: STRING) RETURN INTEGER is
   BEGIN
     IF ( ECC_TEST = "OFF" ) THEN
        RETURN APP_DATA_WIDTH + APP_MASK_WIDTH;
     ELSE
        RETURN APP_DATA_WIDTH + APP_MASK_WIDTH + 4;
     END IF;
   END FUNCTION CALC_WR_BUF_WIDTH;
   
   FUNCTION CALC_RAM_CNT ( FULL_RAM_CNT,REMAINDER: integer) RETURN integer is
   BEGIN
    IF ( REMAINDER = 0 ) THEN
        RETURN FULL_RAM_CNT;
    ELSE
        RETURN FULL_RAM_CNT + 1;
    END IF;
   END FUNCTION CALC_RAM_CNT;

   CONSTANT WR_BUF_WIDTH             : INTEGER := CALC_WR_BUF_WIDTH(APP_DATA_WIDTH,APP_MASK_WIDTH,ECC_TEST);
   CONSTANT FULL_RAM_CNT             : INTEGER := (WR_BUF_WIDTH / 6);
   CONSTANT REMAINDER                : INTEGER := WR_BUF_WIDTH MOD 6;
   CONSTANT RAM_CNT                  : INTEGER := CALC_RAM_CNT(FULL_RAM_CNT,REMAINDER);
   CONSTANT RAM_WIDTH                : INTEGER := (RAM_CNT * 6);
   SIGNAL wr_buf_out_data            : STD_LOGIC_VECTOR(RAM_WIDTH - 1 DOWNTO 0);
   -- X-HDL generated signals

   SIGNAL xhdl6 : STD_LOGIC_VECTOR(1 DOWNTO 0);
   SIGNAL xhdl7 : STD_LOGIC_VECTOR(1 DOWNTO 0);
   SIGNAL xhdl8 : STD_LOGIC_VECTOR(4 DOWNTO 0);
   SIGNAL xhdl9 : STD_LOGIC_VECTOR(4 DOWNTO 0);
   SIGNAL xhdl10 : STD_LOGIC_VECTOR(4 DOWNTO 0);
   
   -- Declare intermediate signals for referenced outputs
   SIGNAL wr_data_buf_addr_xhdl1     : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL wr_data_xhdl0              : STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
   SIGNAL wr_data_mask_xhdl2         : STD_LOGIC_VECTOR(APP_MASK_WIDTH - 1 DOWNTO 0);
   SIGNAL rd_data_indx_ns            : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL data_buf_addr_cnt_ns       : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL wr_data_addr_le            : STD_LOGIC;
   SIGNAL wr_data_indx_ns            : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL wb_wr_data_addr_r          : STD_LOGIC_VECTOR(4 DOWNTO 1);
   SIGNAL wb_wr_data_addr_ns         : STD_LOGIC_VECTOR(4 DOWNTO 1);
   SIGNAL occ_cnt_r                  : STD_LOGIC_VECTOR(4 DOWNTO 0);
   SIGNAL occ_cnt                    : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL occ_cnt_ns                 : STD_LOGIC_VECTOR(4 DOWNTO 0);
   SIGNAL wb_wr_data_addr0_ns        : STD_LOGIC;
   SIGNAL wb_wr_data_addr0_r         : STD_LOGIC;
   SIGNAL wr_req_cnt_r               : STD_LOGIC_VECTOR(4 DOWNTO 0);
   SIGNAL wr_req_cnt_ns              : STD_LOGIC_VECTOR(4 DOWNTO 0);
   SIGNAL pointer_wr_data            : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL pointer_we                 : STD_LOGIC;
   SIGNAL pointer_wr_addr            : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL wr_buf_in_data             : STD_LOGIC_VECTOR(RAM_WIDTH-1 DOWNTO 0);
   SIGNAL rd_addr_r                  : STD_LOGIC_VECTOR(4 DOWNTO 0);

   --Adding few copies of the app_wdf_rdy_r signal in order to meet
   --timing. This is signal has a very high fanout. So grouped into
   --few functional groups and alloted one copy per group.
   SIGNAL app_wdf_rdy_r_copy1        : STD_LOGIC;
   SIGNAL app_wdf_rdy_r_copy2        : STD_LOGIC;
   SIGNAL app_wdf_rdy_r_copy3        : STD_LOGIC;
   SIGNAL app_wdf_rdy_r_copy4        : STD_LOGIC;

   ATTRIBUTE equivalent_register_removal : string;
   ATTRIBUTE equivalent_register_removal of app_wdf_rdy_r_copy1 : SIGNAL IS "no";
   ATTRIBUTE equivalent_register_removal of app_wdf_rdy_r_copy2 : SIGNAL IS "no";
   ATTRIBUTE equivalent_register_removal of app_wdf_rdy_r_copy3 : SIGNAL IS "no";
   ATTRIBUTE equivalent_register_removal of app_wdf_rdy_r_copy4 : SIGNAL IS "no";
BEGIN
   -- Drive referenced outputs
   wr_data_buf_addr <= wr_data_buf_addr_xhdl1;
   wr_data <= wr_data_xhdl0;
   wr_data_mask <= wr_data_mask_xhdl2;
   app_wdf_data_ns1 <= app_wdf_data_r1 WHEN ((NOT(app_wdf_rdy_r_copy2)) = '1') ELSE
                       app_wdf_data;
   app_wdf_mask_ns1 <= app_wdf_mask_r1 WHEN ((NOT(app_wdf_rdy_r_copy2)) = '1') ELSE
                       app_wdf_mask;
   app_wdf_wren_ns1 <= NOT(rst) AND app_wdf_wren_r1 WHEN ((NOT(app_wdf_rdy_r_copy2)) = '1') ELSE
                       NOT(rst) AND app_wdf_wren;
   app_wdf_end_ns1 <= NOT(rst) AND app_wdf_end_r1 WHEN ((NOT(app_wdf_rdy_r_copy2)) = '1') ELSE
                      NOT(rst) AND app_wdf_end;

   PROCESS (clk)
   BEGIN
     IF (clk'EVENT AND clk = '1') THEN
        app_wdf_rdy_r_copy1 <= wdf_rdy_ns AFTER (TCQ)*1 ps;
        app_wdf_rdy_r_copy2 <= wdf_rdy_ns AFTER (TCQ)*1 ps;
        app_wdf_rdy_r_copy3 <= wdf_rdy_ns AFTER (TCQ)*1 ps;
        app_wdf_rdy_r_copy4 <= wdf_rdy_ns AFTER (TCQ)*1 ps;
     END IF;
   END PROCESS;

   xhdl3 : IF (not(ECC_TEST = "OFF")) GENERATE
      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            app_raw_not_ecc_r1 <= app_raw_not_ecc AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;
      
   END GENERATE;
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         app_wdf_data_r1 <= app_wdf_data_ns1 AFTER (TCQ)*1 ps;
         app_wdf_mask_r1 <= app_wdf_mask_ns1 AFTER (TCQ)*1 ps;
         app_wdf_wren_r1 <= app_wdf_wren_ns1 AFTER (TCQ)*1 ps;
         app_wdf_end_r1 <= app_wdf_end_ns1 AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   xhdl4 : IF ((ECC = "OFF") OR CWL >= 7) GENERATE
      PROCESS (wr_data_offset)
      BEGIN
         wr_data_offset_r <= wr_data_offset;
      END PROCESS;
      
      PROCESS (wr_data_addr)
      BEGIN
         wr_data_addr_r <= wr_data_addr;
      END PROCESS;
      
   END GENERATE;
   xhdl5 : IF (NOT((ECC = "OFF") OR CWL >= 7)) GENERATE
      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            wr_data_offset_r <= wr_data_offset AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;
      
      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            wr_data_addr_r <= wr_data_addr AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;
      
   END GENERATE;
   new_rd_data <= wr_data_en AND NOT(wr_data_offset_r);
   PROCESS (new_rd_data, rd_data_indx_r, rst)
   BEGIN
      rd_data_indx_ns <= rd_data_indx_r;
      IF (rst = '1') THEN
         rd_data_indx_ns <= "0000";
      ELSIF (new_rd_data = '1') THEN
         rd_data_indx_ns <= rd_data_indx_r + "0001";
      END IF;
   END PROCESS;
   
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         rd_data_indx_r <= rd_data_indx_ns AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         rd_data_upd_indx_r <= new_rd_data AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   PROCESS (data_buf_addr_cnt_r, rst, wr_accepted)
   BEGIN
      data_buf_addr_cnt_ns <= data_buf_addr_cnt_r;
      IF (rst = '1') THEN
         data_buf_addr_cnt_ns <= "0000";
      ELSIF (wr_accepted = '1') THEN
         data_buf_addr_cnt_ns <= data_buf_addr_cnt_r + "0001";
      END IF;
   END PROCESS;
   
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         data_buf_addr_cnt_r <= data_buf_addr_cnt_ns AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   wr_data_end <= app_wdf_end_r1 AND app_wdf_rdy_r_copy1 AND app_wdf_wren_r1;
   wr_data_addr_le <= (wr_data_end AND wdf_rdy_ns) OR (rd_data_upd_indx_r AND NOT(app_wdf_rdy_r_copy1));
   PROCESS (rst, wr_data_addr_le, wr_data_indx_r)
   BEGIN
      wr_data_indx_ns <= wr_data_indx_r;
      IF (rst = '1') THEN
         wr_data_indx_ns <= "0001";
      ELSIF (wr_data_addr_le = '1') THEN
         wr_data_indx_ns <= wr_data_indx_r + "0001";
      END IF;
   END PROCESS;
   
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         wr_data_indx_r <= wr_data_indx_ns AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   PROCESS (rst, wb_wr_data_addr_r, wr_data_addr_le, wr_data_pntr)
   BEGIN
      wb_wr_data_addr_ns <= wb_wr_data_addr_r;
      IF (rst = '1') THEN
         wb_wr_data_addr_ns <= "0000";
      ELSIF (wr_data_addr_le = '1') THEN
         wb_wr_data_addr_ns <= wr_data_pntr;
      END IF;
   END PROCESS;
   
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         wb_wr_data_addr_r <= wb_wr_data_addr_ns AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   wb_wr_data_addr0_ns <= NOT(rst) AND ((app_wdf_rdy_r_copy3 AND app_wdf_wren_r1 AND NOT(app_wdf_end_r1)) OR (wb_wr_data_addr0_r AND NOT(app_wdf_wren_r1)));
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         wb_wr_data_addr0_r <= wb_wr_data_addr0_ns AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   wb_wr_data_addr <= (wb_wr_data_addr_r & wb_wr_data_addr0_r);
   --xhdl6 <= wr_data_end & rd_data_upd_indx_r;
   --PROCESS (occ_cnt_r, rd_data_upd_indx_r, rst, wr_data_end,xhdl6)
   --BEGIN
   --   occ_cnt_ns <= occ_cnt_r;
   --   IF (rst = '1') THEN
   --      occ_cnt_ns <= "00000";
   --   ELSE
   --      CASE xhdl6 IS
   --         WHEN "01" =>
   --            occ_cnt_ns <= occ_cnt_r - "00001";
   --         WHEN "10" =>
   --            occ_cnt_ns <= occ_cnt_r + "00001";
   --         WHEN OTHERS =>
   --            occ_cnt_ns <= occ_cnt_r;
   --      END CASE;
   --   END IF;
   --END PROCESS;
   --
   --PROCESS (clk)
   --BEGIN
   --   IF (clk'EVENT AND clk = '1') THEN
   --      occ_cnt_r <= occ_cnt_ns AFTER (TCQ)*1 ps;
   --   END IF;
   --END PROCESS;
   --
   --wdf_rdy_ns <= NOT((rst OR NOT(ram_init_done_r) OR occ_cnt_ns(4)));
   xhdl6 <= wr_data_end & rd_data_upd_indx_r;
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
        IF ( rst = '1' ) THEN
          occ_cnt <= X"0001" AFTER (TCQ)*1 ps;
        ELSE
            CASE xhdl6 IS
              WHEN "01" => occ_cnt <= ('0' & occ_cnt(15 downto 1)) AFTER (TCQ)*1 ps;
              WHEN "10" => occ_cnt <= (occ_cnt(14 downto 0) & '1') AFTER (TCQ)*1 ps;
              WHEN OTHERS => null;
            END CASE;
        END IF;
      END IF;
   END PROCESS;

   wdf_rdy_ns <= NOT ( rst OR NOT(ram_init_done_r) OR (occ_cnt(14) AND wr_data_end AND NOT(rd_data_upd_indx_r))
                       OR (occ_cnt(15) AND NOT(rd_data_upd_indx_r)) );
   
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         app_wdf_rdy_r <= wdf_rdy_ns AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   app_wdf_rdy <= app_wdf_rdy_r;
   xhdl7 <= wr_accepted & rd_data_upd_indx_r;
   PROCESS (rd_data_upd_indx_r, rst, wr_accepted, wr_req_cnt_r,xhdl7)
   BEGIN
      wr_req_cnt_ns <= wr_req_cnt_r;
      IF (rst = '1') THEN
         wr_req_cnt_ns <= "00000";
      ELSE
         CASE xhdl7 IS
            WHEN "01" =>
               wr_req_cnt_ns <= wr_req_cnt_r - "00001";
            WHEN "10" =>
               wr_req_cnt_ns <= wr_req_cnt_r + "00001";
            WHEN OTHERS =>
                wr_req_cnt_ns <= wr_req_cnt_r;
         END CASE;
      END IF;
   END PROCESS;
   
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         wr_req_cnt_r <= wr_req_cnt_ns AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   wr_req_16 <= '1' when ((wr_req_cnt_ns = "10000")) else '0';
   pointer_we <= new_rd_data OR NOT(ram_init_done_r);
   pointer_wr_data <= wr_data_addr_r WHEN (ram_init_done_r = '1') ELSE
                      ram_init_addr;
   pointer_wr_addr <= rd_data_indx_r WHEN (ram_init_done_r = '1') ELSE
                      ram_init_addr;
   rams : FOR i IN 0 TO  PNTR_RAM_CNT - 1 GENERATE
      
      
      xhdl8 <= ('0' & data_buf_addr_cnt_r);
      xhdl9 <= ('0' & wr_data_indx_r);
      xhdl10 <= ('0' & pointer_wr_addr);
      RAM32M0 : RAM32M
         GENERIC MAP (
            init_a  => "0000000000000000000000000000000000000000000000000000000000000000",
            init_b  => "0000000000000000000000000000000000000000000000000000000000000000",
            init_c  => "0000000000000000000000000000000000000000000000000000000000000000",
            init_d  => "0000000000000000000000000000000000000000000000000000000000000000"
         )
         PORT MAP (
            doa    => open,
            dob    => wr_data_buf_addr_xhdl1(i * 2 + 1 DOWNTO i * 2),
            doc    => wr_data_pntr(i * 2 + 1 DOWNTO i * 2),
            dod    => open,
            dia    => "00",
            dib    => pointer_wr_data(i * 2 + 1 DOWNTO i * 2),
            dic    => pointer_wr_data(i * 2 + 1 DOWNTO i * 2),
            did    => "00",
            addra  => "00000",
            addrb  => xhdl8,
            addrc  => xhdl9,
            addrd  => xhdl10,
            we     => pointer_we,
            wclk   => clk
         );
   END GENERATE;
   xhdl11 : IF (REMAINDER = 0) GENERATE
      xhdl12 : IF (ECC_TEST = "OFF") GENERATE
         wr_buf_in_data <= (app_wdf_mask_r1 & app_wdf_data_r1);
      END GENERATE;
      xhdl13 : IF (NOT(ECC_TEST = "OFF")) GENERATE
      SIGNAL sig_concat :STD_LOGIC_VECTOR ( APP_MASK_WIDTH + APP_DATA_WIDTH + 3 DOWNTO 0 ); 
      BEGIN
         sig_concat <= (app_raw_not_ecc_r1 & app_wdf_mask_r1 & app_wdf_data_r1);
         wr_buf_in_data <= sig_concat(RAM_WIDTH - 1 DOWNTO 0);
      END GENERATE;
   END GENERATE;
   xhdl14 : IF (NOT(REMAINDER = 0)) GENERATE
      xhdl15 : IF (ECC_TEST = "OFF") GENERATE
      SIGNAL sig_concat : STD_LOGIC_VECTOR (6-REMAINDER+APP_DATA_WIDTH+APP_MASK_WIDTH-1 DOWNTO 0);
      BEGIN
         sig_concat <= (std_logic_vector(to_unsigned(0,6-REMAINDER)) & app_wdf_mask_r1 & app_wdf_data_r1);
         wr_buf_in_data <= sig_concat(RAM_WIDTH - 1 DOWNTO 0);
      END GENERATE;
      xhdl16 : IF (NOT(ECC_TEST = "OFF")) GENERATE
      SIGNAL sig_concat : STD_LOGIC_VECTOR (6-REMAINDER+APP_DATA_WIDTH+APP_MASK_WIDTH+3 DOWNTO 0);
      BEGIN
         sig_concat <= (std_logic_vector(to_unsigned(0,6-REMAINDER)) & app_raw_not_ecc_r1 & app_wdf_mask_r1 & app_wdf_data_r1);
         wr_buf_in_data <= sig_concat(RAM_WIDTH - 1 DOWNTO 0);
      END GENERATE;
   END GENERATE;
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         rd_addr_r <= (wr_data_addr & wr_data_offset) AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   wr_buffer_ram : FOR i IN 0 TO  RAM_CNT - 1 GENERATE
      
      
      RAM32M0 : RAM32M
         GENERIC MAP (
            init_a  => "0000000000000000000000000000000000000000000000000000000000000000",
            init_b  => "0000000000000000000000000000000000000000000000000000000000000000",
            init_c  => "0000000000000000000000000000000000000000000000000000000000000000",
            init_d  => "0000000000000000000000000000000000000000000000000000000000000000"
         )
         PORT MAP (
            doa    => wr_buf_out_data(((i * 6) + 4) + 1 DOWNTO ((i * 6) + 4)),
            dob    => wr_buf_out_data(((i * 6) + 2) + 1 DOWNTO ((i * 6) + 2)),
            doc    => wr_buf_out_data(((i * 6) + 0) + 1 DOWNTO ((i * 6) + 0)),
            dod    => open,
            dia    => wr_buf_in_data(((i * 6) + 4) + 1 DOWNTO ((i * 6) + 4)),
            dib    => wr_buf_in_data(((i * 6) + 2) + 1 DOWNTO ((i * 6) + 2)),
            dic    => wr_buf_in_data(((i * 6) + 0) + 1 DOWNTO ((i * 6) + 0)),
            did    => "00",
            addra  => rd_addr_r,
            addrb  => rd_addr_r,
            addrc  => rd_addr_r,
            addrd  => wb_wr_data_addr,
            we     => app_wdf_rdy_r_copy4,
            wclk   => clk
         );
   END GENERATE;
   wr_data_xhdl0 <= wr_buf_out_data(APP_DATA_WIDTH - 1 DOWNTO 0);
   wr_data_mask_xhdl2 <= wr_buf_out_data(APP_DATA_WIDTH + APP_MASK_WIDTH - 1 DOWNTO APP_DATA_WIDTH);
   xhdl17 : IF (ECC_TEST = "OFF") GENERATE
      raw_not_ecc <= "0000";
   END GENERATE;
   xhdl18 : IF (NOT(ECC_TEST = "OFF")) GENERATE
      raw_not_ecc <= wr_buf_out_data(WR_BUF_WIDTH - 1 DOWNTO WR_BUF_WIDTH-4);
   END GENERATE;
   
   		-- ui_wr_data
END ARCHITECTURE trans;


