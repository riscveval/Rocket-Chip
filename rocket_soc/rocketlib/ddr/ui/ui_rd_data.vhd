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
--  /   /         Filename              : ui_rd_data.v
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

-- User interface read buffer.  Re orders read data returned from the
-- memory controller back to the request order.
--
-- Consists of a large buffer for the data, a status RAM and two counters.
--
-- The large buffer is implemented with distributed RAM in 6 bit wide,
-- 1 read, 1 write mode.  The status RAM is implemented with a distributed
-- RAM configured as 2 bits wide 1 read/write, 1 read mode.
--
-- As read requests are received from the application, the data_buf_addr
-- counter supplies the data_buf_addr sent into the memory controller.
-- With each read request, the counter is incremented, eventually rolling
-- over.  This mechanism labels each read request with an incrementing number.
--
-- When the memory controller returns read data, it echos the original
-- data_buf_addr with the read data.
--
-- The status RAM is indexed with the same address as the data buffer
-- RAM.  Each word of the data buffer RAM has an associated status bit
-- and "end" bit.  Requests of size 1 return a data burst on two consecutive
-- states.  Requests of size zero return with a single assertion of rd_data_en.
--
-- Upon returning data, the status and end bits are updated for each
-- corresponding location in the status RAM indexed by the data_buf_addr
-- echoed on the rd_data_addr field.
--
-- The other side of the status and data RAMs is indexed by the rd_buf_indx.
-- The rd_buf_indx constantly monitors the status bit it is currently
-- pointing to.  When the status becomes set to the proper state (more on
-- this later) read data is returned to the application, and the rd_buf_indx
-- is incremented.
--
-- At rst the rd_buf_indx is initialized to zero.  Data will not have been
-- returned from the memory controller yet, so there is nothing to return
-- to the application. Evenutally, read requests will be made, and the
-- memory controller will return the corresponding data.  The memory
-- controller may not return this data in the request order.  In which
-- case, the status bit at location zero, will not indicate
-- the data for request zero is ready.  Eventually, the memory controller
-- will return data for request zero.  The data is forwarded on to the
-- application, and rd_buf_indx is incremented to point to the next status
-- bits and data in the buffers.  The status bit will be examined, and if
-- data is valid, this data will be returned as well.  This process
-- continues until the status bit indexed by rd_buf_indx indicates data
-- is not ready.  This may be because the rd_data_buf
-- is empty, or that some data was returned out of order.   Since rd_buf_indx
-- always increments sequentially, data is always returned to the application
-- in request order.
--
-- Some further discussion of the status bit is in order.  The rd_data_buf
-- is a circular buffer.  The status bit is a single bit.  Distributed RAM
-- supports only a single write port.  The write port is consumed by
-- memory controller read data updates.  If a simple '1' were used to
-- indicate the status, when rd_data_indx rolled over it would immediately
-- encounter a one for a request that may not be ready.
--
-- This problem is solved by causing read data returns to flip the
-- status bit, and adding hi order bit beyond the size required to
-- index the rd_data_buf.  Data is considered ready when the status bit
-- and this hi order bit are equal.
--
-- The status RAM needs to be initialized to zero after reset.  This is
-- accomplished by cycling through all rd_buf_indx valus and writing a
-- zero to the status bits directly following deassertion of reset.  This
-- mechanism is used for similar purposes
-- for the wr_data_buf.
--
-- When ORDERING == "STRICT", read data reordering is unnecessary.  For thi
-- case, most of the logic in the block is not generated.

-- User interface read data.
LIBRARY ieee;
   USE ieee.std_logic_1164.all;
   USE ieee.std_logic_unsigned.all;
   USE ieee.numeric_std.all;
LIBRARY unisim;
   USE unisim.VCOMPONENTS.all;

ENTITY ui_rd_data IS
   GENERIC (
            TCQ                   : INTEGER := 100;
            APP_DATA_WIDTH        : INTEGER := 256;
            ECC                   : STRING := "OFF";
            ORDERING              : STRING := "NORM"
           );
   PORT (
         ram_init_done_r       : OUT STD_LOGIC;
         ram_init_addr         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         app_rd_data_valid     : OUT STD_LOGIC;
         app_rd_data_end       : OUT STD_LOGIC;
         app_rd_data           : OUT STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
         app_ecc_multiple_err  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         rd_buf_full           : OUT STD_LOGIC;
         rd_data_buf_addr_r    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         rst                   : IN STD_LOGIC;
         clk                   : IN STD_LOGIC;
         rd_data_en            : IN STD_LOGIC;
         rd_data_addr          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         rd_data_offset        : IN STD_LOGIC;
         rd_data_end           : IN STD_LOGIC;
         rd_data               : IN STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
         ecc_multiple          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         rd_accepted           : IN STD_LOGIC
        );
END ENTITY ui_rd_data;

ARCHITECTURE trans OF ui_rd_data IS

   SIGNAL rd_buf_indx_r              : STD_LOGIC_VECTOR(5 DOWNTO 0);
   SIGNAL ram_init_done_r_lcl        : STD_LOGIC;
   SIGNAL app_rd_data_valid_ns       : STD_LOGIC;
   SIGNAL app_rd_data_valid_copy     : STD_LOGIC;
   SIGNAL single_data                : STD_LOGIC;
   SIGNAL app_ecc_multiple_err_r     : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
   
   FUNCTION CALC_RD_BUF_WIDTH ( APP_DATA_WIDTH : integer; ECC : string) RETURN integer is
   BEGIN
     IF ( ECC = "OFF" ) THEN
        RETURN APP_DATA_WIDTH;
     ELSE
        RETURN APP_DATA_WIDTH + 4;
     END IF;
   END FUNCTION CALC_RD_BUF_WIDTH;



   FUNCTION CALC_RAM_CNT ( FULL_RAM_CNT,REMAINDER: integer) RETURN integer is
   BEGIN
     IF ( REMAINDER = 0 ) THEN
         RETURN FULL_RAM_CNT;
     ELSE
         RETURN FULL_RAM_CNT + 1;
     END IF;
   END FUNCTION CALC_RAM_CNT;

   -- Compute dimensions of read data buffer.  Depending on width of
   -- DQ bus and DRAM CK
   -- to fabric ratio, number of RAM32Ms is variable.  RAM32Ms are used in
   -- single write, single read, 6 bit wide mode.
   CONSTANT RD_BUF_WIDTH             : INTEGER := CALC_RD_BUF_WIDTH(APP_DATA_WIDTH,ECC);
   CONSTANT FULL_RAM_CNT             : INTEGER := (RD_BUF_WIDTH/6);
   CONSTANT REMAINDER                : INTEGER := (RD_BUF_WIDTH mod 6);
   CONSTANT RAM_CNT                  : INTEGER := CALC_RAM_CNT(FULL_RAM_CNT,REMAINDER);
   CONSTANT RAM_WIDTH                : INTEGER := (RAM_CNT * 6);

   -- X-HDL generated signals
   SIGNAL xhdl11                     : STD_LOGIC_VECTOR(1 DOWNTO 0);
   SIGNAL upd_rd_buf_indx            : STD_LOGIC;
   SIGNAL ram_init_done_ns           : STD_LOGIC;
   SIGNAL rd_buf_indx_ns             : STD_LOGIC_VECTOR (5 DOWNTO 0);
   SIGNAL rd_data_buf_addr_ns        : STD_LOGIC_VECTOR (3 DOWNTO 0);
   SIGNAL rd_data_buf_addr_r_lcl     : STD_LOGIC_VECTOR ( 3 DOWNTO 0);
   SIGNAL rd_buf_wr_addr             : STD_LOGIC_VECTOR (4 DOWNTO 0);
   SIGNAL rd_status                  : STD_LOGIC_VECTOR (1 DOWNTO 0);
   SIGNAL status_ram_wr_addr_ns      : STD_LOGIC_VECTOR (4 DOWNTO 0);
   SIGNAL status_ram_wr_addr_r       : STD_LOGIC_VECTOR (4 DOWNTO 0);
   SIGNAL wr_status                  : STD_LOGIC_VECTOR (1 DOWNTO 0);
   SIGNAL wr_status_r1               : STD_LOGIC;
   SIGNAL status_ram_wr_data_ns      : STD_LOGIC_VECTOR (1 DOWNTO 0);
   SIGNAL status_ram_wr_data_r       : STD_LOGIC_VECTOR (1 DOWNTO 0);
   SIGNAL rd_buf_we_r1               : STD_LOGIC;
   SIGNAL rd_buf_out_data            : STD_LOGIC_VECTOR (RAM_WIDTH-1 DOWNTO 0);
   SIGNAL rd_buf_indx_copy_r         : STD_LOGIC_VECTOR ( 4 DOWNTO 0 );
   SIGNAL rd_buf_in_data             : STD_LOGIC_VECTOR (RAM_WIDTH-1 DOWNTO 0);
   SIGNAL rd_data_rdy                : STD_LOGIC;
   SIGNAL bypass                     : STD_LOGIC;
   SIGNAL app_rd_data_end_ns         : STD_LOGIC;
   SIGNAL app_rd_data_ns             : STD_LOGIC_VECTOR (APP_DATA_WIDTH-1 DOWNTO 0);
   SIGNAL app_ecc_multiple_err_ns    : STD_LOGIC_VECTOR (3 DOWNTO 0);
   SIGNAL free_rd_buf                : STD_LOGIC;
   SIGNAL occ_cnt_r                  : STD_LOGIC_VECTOR (4 DOWNTO 0);
   SIGNAL occ_minus_one              : STD_LOGIC_VECTOR (4 DOWNTO 0);
   SIGNAL occ_plus_one               : STD_LOGIC_VECTOR (4 DOWNTO 0);
   SIGNAL occ_cnt_ns                 : STD_LOGIC_VECTOR (4 DOWNTO 0);
   SIGNAL rd_buf_we                  : STD_LOGIC;
   SIGNAL app_rd_data_end_int        : STD_LOGIC;

   ATTRIBUTE equivalent_register_removal : string;
   ATTRIBUTE equivalent_register_removal of rd_buf_indx_copy_r : signal is "no";
   ATTRIBUTE equivalent_register_removal of app_rd_data_valid_copy : SIGNAL IS "no";
BEGIN

   --This signal is added have the internal usage of the port
   --app_rd_data_end
   app_rd_data_end <= app_rd_data_end_int;

   -- rd_buf_indx points to the status and data storage rams for
   -- reading data out to the app.
   ram_init_done_r <= ram_init_done_r_lcl;
   upd_rd_buf_indx <= NOT(ram_init_done_r_lcl) OR app_rd_data_valid_ns;

   -- Loop through all status write addresses once after rst.  Initializes
   -- the status and pointer RAMs.
   ram_init_done_ns <= NOT(rst) when (rd_buf_indx_r(4 DOWNTO 0) = "11111") else NOT(rst) AND ram_init_done_r_lcl ;
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         ram_init_done_r_lcl <= ram_init_done_ns AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   PROCESS (rd_buf_indx_r, rst, single_data, upd_rd_buf_indx)
   BEGIN
      rd_buf_indx_ns <= rd_buf_indx_r;
      IF (rst = '1') THEN
         rd_buf_indx_ns <= "000000";
      ELSIF (upd_rd_buf_indx = '1') THEN
         rd_buf_indx_ns <= rd_buf_indx_r + "000001" + ("00000" & single_data);
      END IF;
   END PROCESS;
   
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         rd_buf_indx_r <= rd_buf_indx_ns AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   ram_init_addr <= rd_buf_indx_r(3 DOWNTO 0);
   app_ecc_multiple_err <= app_ecc_multiple_err_r;
   xhdl0 : IF (ORDERING = "STRICT") GENERATE
      app_rd_data_valid_ns <= '0';
      single_data <= '0';
      rd_buf_full <= '0';
      rd_data_buf_addr_ns <= "0000" WHEN (rst = '1') ELSE
                             rd_data_buf_addr_r_lcl + ("000" & rd_accepted);

      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            rd_data_buf_addr_r_lcl <= rd_data_buf_addr_ns AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;
      
      rd_data_buf_addr_r <= rd_data_buf_addr_ns;
      
      -- app_* signals required to be registered.      
      xhdl1 : IF (ECC = "OFF") GENERATE
         PROCESS (rd_data)
         BEGIN
            app_rd_data <= rd_data;
         END PROCESS;
         
         PROCESS (rd_data_en)
         BEGIN
            app_rd_data_valid <= rd_data_en;
         END PROCESS;
         
         PROCESS (rd_data_end)
         BEGIN
            app_rd_data_end_int <= rd_data_end;
         END PROCESS;
         
      END GENERATE;
      
      xhdl2 : IF (NOT(ECC = "OFF")) GENERATE
         PROCESS (clk)
         BEGIN
            IF (clk'EVENT AND clk = '1') THEN
               app_rd_data <= rd_data AFTER (TCQ)*1 ps;
            END IF;
         END PROCESS;
         
         PROCESS (clk)
         BEGIN
            IF (clk'EVENT AND clk = '1') THEN
               app_rd_data_valid <= rd_data_en AFTER (TCQ)*1 ps;
            END IF;
         END PROCESS;
         
         PROCESS (clk)
         BEGIN
            IF (clk'EVENT AND clk = '1') THEN
               app_rd_data_end_int <= rd_data_end AFTER (TCQ)*1 ps;
            END IF;
         END PROCESS;
         
         PROCESS (clk)
         BEGIN
            IF (clk'EVENT AND clk = '1') THEN
               app_ecc_multiple_err_r <= ecc_multiple AFTER (TCQ)*1 ps;
            END IF;
         END PROCESS;
      END GENERATE;
   END GENERATE;
   
   xhdl3 : IF (NOT(ORDERING = "STRICT")) GENERATE
      rd_buf_we <= NOT(ram_init_done_r_lcl) OR rd_data_en;
      rd_buf_wr_addr <= (rd_data_addr & rd_data_offset);
      -- Instantiate status RAM.  One bit for status and one for "end".
      -- Turns out read to write back status is a timing path.  Update
      -- the status in the ram on the state following the read.  Bypass
      -- the write data into the status read path.
      status_ram_wr_addr_ns <= rd_buf_wr_addr WHEN (ram_init_done_r_lcl = '1') ELSE
                               rd_buf_indx_r(4 DOWNTO 0);

      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            status_ram_wr_addr_r <= status_ram_wr_addr_ns AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;
      
      -- Not guaranteed to write second status bit.  If it is written, always
      -- copy in the first status bit.
      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            wr_status_r1 <= wr_status(0) AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;
      
      status_ram_wr_data_ns <= "00" WHEN ( ram_init_done_r_lcl = '0') ELSE
                               (rd_data_end & NOT( wr_status_r1 )) WHEN (rd_data_offset = '1') ELSE
                               (rd_data_end & NOT( wr_status(0) ));
      
      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            status_ram_wr_data_r <= status_ram_wr_data_ns AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;
      
      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            rd_buf_we_r1 <= rd_buf_we AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;
      
      RAM32M0 : RAM32M
         GENERIC MAP (
            init_a  => "0000000000000000000000000000000000000000000000000000000000000000",
            init_b  => "0000000000000000000000000000000000000000000000000000000000000000",
            init_c  => "0000000000000000000000000000000000000000000000000000000000000000",
            init_d  => "0000000000000000000000000000000000000000000000000000000000000000"
         )
         PORT MAP (
            doa    => rd_status,
            dob    => open,
            doc    => wr_status,
            dod    => open,
            dia    => status_ram_wr_data_r,
            dib    => "00",
            dic    => status_ram_wr_data_r,
            did    => status_ram_wr_data_r,
            addra  => rd_buf_indx_r(4 DOWNTO 0),
            addrb  => "00000",
            addrc  => status_ram_wr_addr_ns,
            addrd  => status_ram_wr_addr_r,
            we     => rd_buf_we_r1,
            wclk   => clk
         );
      -- block: status_ram
      
      xhdl4 : IF (REMAINDER = 0) GENERATE
      
         xhdl5 : IF (ECC = "OFF") GENERATE
            rd_buf_in_data <=  rd_data;
         END GENERATE;
         
         xhdl6 : IF (NOT(ECC = "OFF")) GENERATE
         SIGNAL ecc_multiple_rd_data : STD_LOGIC_VECTOR ( APP_DATA_WIDTH + 3 DOWNTO 0 );
         BEGIN
            ecc_multiple_rd_data <= (ecc_multiple & rd_data);
            rd_buf_in_data <= ecc_multiple_rd_data(RAM_WIDTH - 1 DOWNTO 0);
         END GENERATE;
         
      END GENERATE;
      
      xhdl7 : IF (NOT(REMAINDER = 0)) GENERATE
      
         xhdl8 : IF (ECC = "OFF") GENERATE
         SIGNAL zero_rd_data : STD_LOGIC_VECTOR ( 6-REMAINDER+APP_DATA_WIDTH-1 DOWNTO 0);
         BEGIN
            zero_rd_data <= (std_logic_vector(to_unsigned(0,6-REMAINDER)) & rd_data);
            rd_buf_in_data <= zero_rd_data (RAM_WIDTH-1 DOWNTO 0);
         END GENERATE;
         
         xhdl9 : IF (NOT(ECC = "OFF")) GENERATE
         SIGNAL zero_ecc_multiple_rd_data : STD_LOGIC_VECTOR ( 6-REMAINDER+APP_DATA_WIDTH+3 DOWNTO 0);
         BEGIN
            zero_ecc_multiple_rd_data <= (std_logic_vector(to_unsigned(0,6-REMAINDER)) & ecc_multiple & rd_data);
            rd_buf_in_data <= zero_ecc_multiple_rd_data(RAM_WIDTH - 1 DOWNTO 0);
         END GENERATE;
         
      END GENERATE;
      

      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
           rd_buf_indx_copy_r <= rd_buf_indx_ns (4 DOWNTO 0);
         END IF;
      END PROCESS;
         
      rd_buffer_ram : FOR i IN 0 TO  RAM_CNT - 1 GENERATE
         
         RAM32M0 : RAM32M
            GENERIC MAP (
               init_a  => "0000000000000000000000000000000000000000000000000000000000000000",
               init_b  => "0000000000000000000000000000000000000000000000000000000000000000",
               init_c  => "0000000000000000000000000000000000000000000000000000000000000000",
               init_d  => "0000000000000000000000000000000000000000000000000000000000000000"
            )
            PORT MAP (
               doa    => rd_buf_out_data(((i * 6) + 4) + 1 DOWNTO ((i * 6) + 4)),
               dob    => rd_buf_out_data(((i * 6) + 2) + 1 DOWNTO ((i * 6) + 2)),
               doc    => rd_buf_out_data(((i * 6) + 0) + 1 DOWNTO ((i * 6) + 0)),
               dod    => open,
               dia    => rd_buf_in_data(((i * 6) + 4) + 1 DOWNTO ((i * 6) + 4)),
               dib    => rd_buf_in_data(((i * 6) + 2) + 1 DOWNTO ((i * 6) + 2)),
               dic    => rd_buf_in_data(((i * 6) + 0) + 1 DOWNTO ((i * 6) + 0)),
               did    => "00",
               addra  => rd_buf_indx_copy_r(4 DOWNTO 0),
               addrb  => rd_buf_indx_copy_r(4 DOWNTO 0),
               addrc  => rd_buf_indx_copy_r(4 DOWNTO 0),
               addrd  => rd_buf_wr_addr,
               we     => rd_buf_we,
               wclk   => clk
            );
         -- block: rd_buffer_ram
      END GENERATE;
      
      rd_data_rdy <= '1' when (rd_status(0) = rd_buf_indx_r(5)) else '0';
      bypass <= rd_data_en when (rd_buf_wr_addr(4 DOWNTO 0) = rd_buf_indx_r(4 DOWNTO 0)) else '0';
      app_rd_data_valid_ns <= ram_init_done_r_lcl AND (bypass OR rd_data_rdy);
      app_rd_data_end_ns <= rd_data_end WHEN (bypass = '1') ELSE
                            rd_status(1);
                            
      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            app_rd_data_valid <= app_rd_data_valid_ns AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;
      
      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            app_rd_data_end_int <= app_rd_data_end_ns AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;
      
      single_data <= app_rd_data_valid_ns AND app_rd_data_end_ns AND NOT(rd_buf_indx_r(0));
      
      app_rd_data_ns <= rd_data WHEN (bypass = '1') ELSE
                        rd_buf_out_data(APP_DATA_WIDTH - 1 DOWNTO 0);
      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            app_rd_data <= app_rd_data_ns AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;
      
      xhdl10 : IF ( NOT(ECC = "OFF")) GENERATE
         app_ecc_multiple_err_ns <= ecc_multiple WHEN (bypass = '1') ELSE
                                    rd_buf_out_data(APP_DATA_WIDTH + 3 DOWNTO APP_DATA_WIDTH);
         PROCESS (clk)
         BEGIN
            IF (clk'EVENT AND clk = '1') THEN
               app_ecc_multiple_err_r <= app_ecc_multiple_err_ns AFTER (TCQ)*1 ps;
            END IF;
         END PROCESS;
         -- Keep track of how many entries in the queue hold data.
      END GENERATE;

      --Added to fix timing. The signal app_rd_data_valid has 
      --a very high fanout. So making a dedicated copy for usage
      --with the occ_cnt counter. 
      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            app_rd_data_valid_copy <= app_rd_data_valid_ns AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;

      free_rd_buf <= app_rd_data_valid_copy AND app_rd_data_end_int; --changed to use registered version
                                                                     --of the signals in ordered to fix timing
      occ_minus_one <= occ_cnt_r - "00001";
      occ_plus_one <= occ_cnt_r + "00001";
      xhdl11 <= rd_accepted & free_rd_buf;

      PROCESS (free_rd_buf, occ_cnt_r, rd_accepted, rst, occ_minus_one, occ_plus_one,xhdl11)
      BEGIN
         occ_cnt_ns <= occ_cnt_r;
         IF (rst = '1') THEN
            occ_cnt_ns <= "00000";
         ELSE
            CASE xhdl11 IS
               WHEN "01" =>
                  occ_cnt_ns <= occ_minus_one;
               WHEN "10" =>		-- case ({wr_data_end, new_rd_data})
                  occ_cnt_ns <= occ_plus_one;
               WHEN OTHERS =>
                  occ_cnt_ns <= occ_cnt_r;
            END CASE;
         END IF;
      END PROCESS;
      
      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            occ_cnt_r <= occ_cnt_ns AFTER (TCQ)*1 ps;
         END IF;
      END PROCESS;
      
      rd_buf_full <= occ_cnt_ns(4);
      
      -- block: occupied_counter
      
      -- Generate the data_buf_address written into the memory controller
      -- for reads.  Increment with each accepted read, and rollover at 0xf.
      rd_data_buf_addr_r <= rd_data_buf_addr_r_lcl;
      PROCESS (rd_accepted, rd_data_buf_addr_r_lcl, rst)
      BEGIN
         rd_data_buf_addr_ns <= rd_data_buf_addr_r_lcl;
         IF (rst = '1') THEN
            rd_data_buf_addr_ns <= "0000";
         ELSIF (rd_accepted = '1') THEN
            rd_data_buf_addr_ns <= rd_data_buf_addr_r_lcl + "0001";
         END IF;
      END PROCESS;
      
      PROCESS (clk)
      BEGIN
         IF (clk'EVENT AND clk = '1') THEN
            rd_data_buf_addr_r_lcl <= rd_data_buf_addr_ns AFTER (TCQ)*1 ps;		-- block: data_buf_addr
         END IF;
      END PROCESS;
      
      -- block: not_strict_mode
   END GENERATE;
   
   		-- ui_rd_data
END ARCHITECTURE trans;
