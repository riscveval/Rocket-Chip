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
--  /   /         Filename: phy_rddata_sync.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:13 $
-- \   \  /  \    Date Created: Aug 03 2009 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--   Synchronization of captured read data along with appropriately delayed
--   valid signal (both in clk_rsync domain) to MC/PHY rdlvl logic clock (clk) 
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_rddata_sync.vhd,v 1.1 2011/06/02 07:18:13 mishra Exp $
--**$Date: 2011/06/02 07:18:13 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_rddata_sync.vhd,v $
--******************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_rddata_sync is
   generic (
      TCQ             	: integer := 100;	-- clk->out delay (sim only)
      DQ_WIDTH       	: integer := 64;	-- # of DQ (data)
      DQS_WIDTH     	: integer := 8; 	-- # of DQS (strobe)
      DRAM_WIDTH     	: integer := 8; 	-- # # of DQ per DQS
      nDQS_COL0		: integer := 4;		-- # DQS groups in I/O column #1
      nDQS_COL1		: integer := 4;		-- # DQS groups in I/O column #2
      nDQS_COL2		: integer := 4;		-- # DQS groups in I/O column #3
      nDQS_COL3		: integer := 4;		-- # DQS groups in I/O column #4
      DQS_LOC_COL0               : std_logic_vector(143 downto 0) := X"11100F0E0D0C0B0A09080706050403020100";
      								-- DQS grps in col #1
      DQS_LOC_COL1               : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
							        -- DQS grps in col #2
      DQS_LOC_COL2               : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
							        -- DQS grps in col #3
      DQS_LOC_COL3               : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000"
   );
   port (
      clk    	        	: in std_logic;  
      clk_rsync	        	: in std_logic_vector(3 downto 0);  
      rst_rsync       		: in std_logic_vector(3 downto 0); 
      -- Captured data in resync clock domain
      rd_data_rise0		: in std_logic_vector((DQ_WIDTH-1) downto 0);
      rd_data_fall0		: in std_logic_vector((DQ_WIDTH-1) downto 0);
      rd_data_rise1		: in std_logic_vector((DQ_WIDTH-1) downto 0);
      rd_data_fall1		: in std_logic_vector((DQ_WIDTH-1) downto 0);
      rd_dqs_rise0	        : in std_logic_vector((DQS_WIDTH-1) downto 0);
      rd_dqs_fall0	        : in std_logic_vector((DQS_WIDTH-1) downto 0);
      rd_dqs_rise1	        : in std_logic_vector((DQS_WIDTH-1) downto 0);
      rd_dqs_fall1	        : in std_logic_vector((DQS_WIDTH-1) downto 0);
      --  Synchronized data/valid back to MC/PHY rdlvl logic
      dfi_rddata		: out std_logic_vector((4*DQ_WIDTH-1) downto 0);
      dfi_rd_dqs		: out std_logic_vector((4*DQS_WIDTH-1) downto 0)
   );
end phy_rddata_sync;

architecture trans of phy_rddata_sync is

   function CALC_COL0_VECT_WIDTH return integer is
   begin
      if (nDQS_COL0 > 0) then
	 return (nDQS_COL0);
      else
	 return 1;
      end if;
   end function CALC_COL0_VECT_WIDTH;
	
   function CALC_COL1_VECT_WIDTH return integer is
   begin
      if (nDQS_COL1 > 0) then
	 return (nDQS_COL1);
      else
	 return 1;
      end if;
   end function CALC_COL1_VECT_WIDTH;

   function CALC_COL2_VECT_WIDTH return integer is
   begin
      if (nDQS_COL2 > 0) then
	 return (nDQS_COL2);
      else
	 return 1;
      end if;
   end function CALC_COL2_VECT_WIDTH;

   function CALC_COL3_VECT_WIDTH return integer is
   begin
      if (nDQS_COL3 > 0) then
	 return (nDQS_COL3);
      else
	 return 1;
      end if;
   end function CALC_COL3_VECT_WIDTH;

   -- Ensure nonzero width for certain buses to prevent syntax errors
   -- during compile in the event they are not used (e.g. buses that have to
   -- do with column #2 in a single column design never get used, although
   -- those buses still will get declared)
   constant COL0_VECT_WIDTH  	  : integer := CALC_COL0_VECT_WIDTH; 
   constant COL1_VECT_WIDTH  	  : integer := CALC_COL1_VECT_WIDTH; 
   constant COL2_VECT_WIDTH  	  : integer := CALC_COL2_VECT_WIDTH; 
   constant COL3_VECT_WIDTH	  : integer := CALC_COL3_VECT_WIDTH; 

   signal data_c0     			: std_logic_vector((4*DRAM_WIDTH*COL0_VECT_WIDTH-1) downto 0);
   signal data_c1     			: std_logic_vector((4*DRAM_WIDTH*COL1_VECT_WIDTH-1) downto 0);
   signal data_c2     			: std_logic_vector((4*DRAM_WIDTH*COL2_VECT_WIDTH-1) downto 0);
   signal data_c3     			: std_logic_vector((4*DRAM_WIDTH*COL3_VECT_WIDTH-1) downto 0);
   signal data_fall0_sync		: std_logic_vector((DQ_WIDTH-1) downto 0);
   signal data_fall1_sync		: std_logic_vector((DQ_WIDTH-1) downto 0);
   signal data_rise0_sync		: std_logic_vector((DQ_WIDTH-1) downto 0);
   signal data_rise1_sync		: std_logic_vector((DQ_WIDTH-1) downto 0);
   signal data_sync_c0 			: std_logic_vector((4*DRAM_WIDTH*COL0_VECT_WIDTH-1) downto 0);
   signal data_sync_c1 			: std_logic_vector((4*DRAM_WIDTH*COL1_VECT_WIDTH-1) downto 0);
   signal data_sync_c2 			: std_logic_vector((4*DRAM_WIDTH*COL2_VECT_WIDTH-1) downto 0);
   signal data_sync_c3 			: std_logic_vector((4*DRAM_WIDTH*COL3_VECT_WIDTH-1) downto 0);
   signal dqs_c0 			: std_logic_vector((4*COL0_VECT_WIDTH-1) downto 0);
   signal dqs_c1 			: std_logic_vector((4*COL1_VECT_WIDTH-1) downto 0);
   signal dqs_c2 			: std_logic_vector((4*COL2_VECT_WIDTH-1) downto 0);
   signal dqs_c3 			: std_logic_vector((4*COL3_VECT_WIDTH-1) downto 0);
   signal dqs_fall0_sync		: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal dqs_fall1_sync		: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal dqs_rise0_sync		: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal dqs_rise1_sync		: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal dqs_sync_c0		        : std_logic_vector((4*COL0_VECT_WIDTH-1) downto 0);
   signal dqs_sync_c1		        : std_logic_vector((4*COL1_VECT_WIDTH-1) downto 0);
   signal dqs_sync_c2		        : std_logic_vector((4*COL2_VECT_WIDTH-1) downto 0);
   signal dqs_sync_c3		        : std_logic_vector((4*COL3_VECT_WIDTH-1) downto 0);
   -- Declare the intermediate signals for the inputs of circ buffer
   signal wdata_xhdl3			: std_logic_vector((4*COL3_VECT_WIDTH)+(4*DRAM_WIDTH*COL3_VECT_WIDTH)-1 downto 0);
   signal rdata_xhdl3			: std_logic_vector((4*COL3_VECT_WIDTH)+(4*DRAM_WIDTH*COL3_VECT_WIDTH)-1 downto 0);
   signal wdata_xhdl2			: std_logic_vector((4*COL2_VECT_WIDTH)+(4*DRAM_WIDTH*COL2_VECT_WIDTH)-1 downto 0);
   signal rdata_xhdl2			: std_logic_vector((4*COL2_VECT_WIDTH)+(4*DRAM_WIDTH*COL2_VECT_WIDTH)-1 downto 0);
   signal wdata_xhdl1			: std_logic_vector((4*COL1_VECT_WIDTH)+(4*DRAM_WIDTH*COL1_VECT_WIDTH)-1 downto 0);
   signal rdata_xhdl1			: std_logic_vector((4*COL1_VECT_WIDTH)+(4*DRAM_WIDTH*COL1_VECT_WIDTH)-1 downto 0);
   signal wdata_xhdl0			: std_logic_vector((4*COL0_VECT_WIDTH)+(4*DRAM_WIDTH*COL0_VECT_WIDTH)-1 downto 0);
   signal rdata_xhdl0			: std_logic_vector((4*COL0_VECT_WIDTH)+(4*DRAM_WIDTH*COL0_VECT_WIDTH)-1 downto 0);

--------- circ buffer component ---------   
   component circ_buffer
      generic (
         TCQ                    : integer := 100;
         DATA_WIDTH             : integer := 1;
         BUF_DEPTH              : integer := 5		-- valid values are 5, 6, 7, and 8
      );
      port (
         rdata                  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
         wdata                  : in std_logic_vector(DATA_WIDTH - 1 downto 0);
	 rclk                   : in std_logic;
         wclk                   : in std_logic;
         rst                    : in std_logic
      );
   end component;

begin

   --***************************************************************************
   -- Synchronization of both data and active/valid signal from clk_rsync to
   -- clk domain
   -- NOTES:
   --  1. For now, assume both rddata_valid0 and rddata_valid1 are driven at
   --     same time. PHY returns data aligned in this manner
   --  2. Circular buffer implementation is preliminary (i.e. shortcuts have
   --     been taken!). Will later need some sort of calibration.
   --       - Substitute this with enhanced circular buffer design for
   --         release (5 deep design)
   --  3. Up to 4 circular buffers are used, one for each CLK_RSYNC[x] domain.
   --  4. RD_ACTIVE synchronized to CLK_RSYNC[0] circular buffer. This is
   --     TEMPORARY only. For release, do not need this - RD_ACTIVE will
   --     remain totally in the
   -- A single circular buffer is used for the entire data bus. This will
   --     be an issue in H/W - will need to examine this based on clock
   --     frequency, and skew matching achievable in H/W.
   --***************************************************************************

   gen_c0: if(nDQS_COL0 > 0 ) generate	
   begin
     gen_loop_c0: for c0_i in 0 to (nDQS_COL0-1) generate
     begin
     -- Steer data to circular buffer - merge FALL/RISE data into single bus
        process (rd_dqs_fall0, rd_dqs_fall1, rd_dqs_rise0,
                 rd_dqs_rise1)
        begin	   
        dqs_c0(4*(c0_i+1)-1 downto 4*(c0_i+1)-4) <= rd_dqs_fall1(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))) &
        						  rd_dqs_rise1(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))) &
             					  rd_dqs_fall0(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))) &
             					  rd_dqs_rise0(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i))));
        end process;
     
        process (rd_data_rise0, rd_data_rise1, rd_data_fall0,
                 rd_data_fall1)
        begin 
        data_c0(4*DRAM_WIDTH*(c0_i+1)-1 downto 4*DRAM_WIDTH*c0_i) <= 
        					rd_data_fall1(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))  )) &
        					rd_data_rise1(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))  )) &
        					rd_data_fall0(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))  )) &
        					rd_data_rise0(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))  ));
        end process;
     
        -- Reassemble data from circular buffer
        process (dqs_sync_c0(4*c0_i), dqs_sync_c0(4*c0_i+1),
                 dqs_sync_c0(4*c0_i+2), dqs_sync_c0(4*c0_i+3))
        begin
           dqs_fall1_sync(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))) <= dqs_sync_c0(4*c0_i+3);
           dqs_rise1_sync(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))) <= dqs_sync_c0(4*c0_i+2);
           dqs_fall0_sync(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))) <= dqs_sync_c0(4*c0_i+1);
           dqs_rise0_sync(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))) <= dqs_sync_c0(4*c0_i+0);
        end process;      							
     
        process (data_sync_c0((4*DRAM_WIDTH*c0_i)+DRAM_WIDTH-1   downto 4*DRAM_WIDTH*c0_i),
                 data_sync_c0((4*DRAM_WIDTH*c0_i)+2*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c0_i + DRAM_WIDTH),
                 data_sync_c0((4*DRAM_WIDTH*c0_i)+3*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c0_i + 2*DRAM_WIDTH),
                 data_sync_c0((4*DRAM_WIDTH*c0_i)+4*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c0_i + 3*DRAM_WIDTH)
                )
        begin 
        data_fall1_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))))
             	<= data_sync_c0((4*DRAM_WIDTH*c0_i)+4*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c0_i + 3*DRAM_WIDTH); 
        data_rise1_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))))
             	<= data_sync_c0((4*DRAM_WIDTH*c0_i)+3*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c0_i + 2*DRAM_WIDTH); 
        data_fall0_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))))
             	<= data_sync_c0((4*DRAM_WIDTH*c0_i)+2*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c0_i + 1*DRAM_WIDTH); 
        data_rise0_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL0((8*(c0_i+1))-1 downto 8*c0_i)))))
             	<= data_sync_c0((4*DRAM_WIDTH*c0_i)+DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c0_i); 		
        end process;
     end generate;
     
     u_rddata_sync_c0: circ_buffer
     generic map (
     		TCQ  => TCQ,
	  	DATA_WIDTH => (4*nDQS_COL0)+(4*DRAM_WIDTH*nDQS_COL0),
	  	BUF_DEPTH => 6
	  )
     port map (
	      	rclk  => clk,
	  	wclk  => clk_rsync(0),
	  	rst   => rst_rsync(0),	    
	  	wdata => wdata_xhdl0,
	  	rdata => rdata_xhdl0
	  );
   end generate;

   gen_c1: if (nDQS_COL1 > 0) generate
   begin
      gen_loop_c1: for c1_i in 0 to (nDQS_COL1-1) generate
      begin	      
      -- Steer data to circular buffer - merge FALL/RISE data into single bus
         process (rd_dqs_fall0, rd_dqs_fall1, rd_dqs_rise0,
                  rd_dqs_rise1)
         begin	   
         dqs_c1(4*(c1_i+1)-1 downto 4*(c1_i+1)-4) <= rd_dqs_fall1(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))) &
         					     rd_dqs_rise1(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))) &
              					     rd_dqs_fall0(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))) &
              					     rd_dqs_rise0(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i))));
         end process;

         process (rd_data_rise0, rd_data_rise1, rd_data_fall0,
                  rd_data_fall1)
         begin 
         data_c1(4*DRAM_WIDTH*(c1_i+1)-1 downto 4*DRAM_WIDTH*c1_i) <= 
         				rd_data_fall1(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))  )) &
         				rd_data_rise1(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))  )) &
         				rd_data_fall0(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))  )) &
         				rd_data_rise0(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))  ));
         end process;

         -- Reassemble data from circular buffer
         process (dqs_sync_c1(4*c1_i), dqs_sync_c1(4*c1_i+1),
                  dqs_sync_c1(4*c1_i+2), dqs_sync_c1(4*c1_i+3))
         begin
            dqs_fall1_sync(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))) <= dqs_sync_c1(4*c1_i+3);
            dqs_rise1_sync(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))) <= dqs_sync_c1(4*c1_i+2);
            dqs_fall0_sync(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))) <= dqs_sync_c1(4*c1_i+1);
            dqs_rise0_sync(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))) <= dqs_sync_c1(4*c1_i+0);
         end process;      							

         process (data_sync_c1((4*DRAM_WIDTH*c1_i)+DRAM_WIDTH-1   downto 4*DRAM_WIDTH*c1_i),
                  data_sync_c1((4*DRAM_WIDTH*c1_i)+2*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c1_i + DRAM_WIDTH),
                  data_sync_c1((4*DRAM_WIDTH*c1_i)+3*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c1_i + 2*DRAM_WIDTH),
                  data_sync_c1((4*DRAM_WIDTH*c1_i)+4*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c1_i + 3*DRAM_WIDTH)
                 )
         begin 
         data_fall1_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))+1) - 1 downto  							   DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))))
              	      <= data_sync_c1((4*DRAM_WIDTH*c1_i)+4*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c1_i + 3*DRAM_WIDTH); 
         data_rise1_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))+1) - 1 downto  							   DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))))
              	      <= data_sync_c1((4*DRAM_WIDTH*c1_i)+3*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c1_i + 2*DRAM_WIDTH); 
         data_fall0_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))+1) - 1 downto  							   DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))))
              	      <= data_sync_c1((4*DRAM_WIDTH*c1_i)+2*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c1_i + 1*DRAM_WIDTH); 
         data_rise0_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))+1) - 1 downto  							   DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL1((8*(c1_i+1))-1 downto 8*c1_i)))))
              	      <= data_sync_c1((4*DRAM_WIDTH*c1_i)+DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c1_i); 		
         end process;
      end generate;

         u_rddata_sync_c1: circ_buffer
         generic map (
         		TCQ  => TCQ,
              	DATA_WIDTH => (4*nDQS_COL1)+(4*DRAM_WIDTH*nDQS_COL1),
              	BUF_DEPTH => 6
              )
         port map (
                rclk  => clk,
              	wclk  => clk_rsync(1),
              	rst   => rst_rsync(1),	    
              	wdata => wdata_xhdl1,
              	rdata => rdata_xhdl1
              );

   end generate;


   gen_c2: if (nDQS_COL2 > 0) generate
   begin
      gen_loop_c2: for c2_i in 0 to (nDQS_COL2-1) generate
      begin	      
      -- Steer data to circular buffer - merge FALL/RISE data into single bus
         process (rd_dqs_fall0, rd_dqs_fall1, rd_dqs_rise0,
                  rd_dqs_rise1)
         begin	   
         dqs_c2(4*(c2_i+1)-1 downto 4*(c2_i+1)-4) <= rd_dqs_fall1(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))) &
         					     rd_dqs_rise1(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))) &
              					     rd_dqs_fall0(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))) &
              					     rd_dqs_rise0(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i))));
         end process;

         process (rd_data_rise0, rd_data_rise1, rd_data_fall0,
                  rd_data_fall1)
         begin 
         data_c2(4*DRAM_WIDTH*(c2_i+1)-1 downto 4*DRAM_WIDTH*c2_i) <= 
         				rd_data_fall1(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))  )) &
         				rd_data_rise1(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))  )) &
         				rd_data_fall0(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))  )) &
         				rd_data_rise0(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))  ));
         end process;

         -- Reassemble data from circular buffer
         process (dqs_sync_c2(4*c2_i), dqs_sync_c2(4*c2_i+1),
                  dqs_sync_c2(4*c2_i+2), dqs_sync_c2(4*c2_i+3))
         begin
            dqs_fall1_sync(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))) <= dqs_sync_c2(4*c2_i+3);
            dqs_rise1_sync(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))) <= dqs_sync_c2(4*c2_i+2);
            dqs_fall0_sync(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))) <= dqs_sync_c2(4*c2_i+1);
            dqs_rise0_sync(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))) <= dqs_sync_c2(4*c2_i+0);
         end process;      							

         process (data_sync_c2((4*DRAM_WIDTH*c2_i)+DRAM_WIDTH-1   downto 4*DRAM_WIDTH*c2_i),
                  data_sync_c2((4*DRAM_WIDTH*c2_i)+2*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c2_i + DRAM_WIDTH),
                  data_sync_c2((4*DRAM_WIDTH*c2_i)+3*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c2_i + 2*DRAM_WIDTH),
                  data_sync_c2((4*DRAM_WIDTH*c2_i)+4*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c2_i + 3*DRAM_WIDTH)
                 )
         begin 
         data_fall1_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))+1) - 1 downto  							   DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))))
              	      <= data_sync_c2((4*DRAM_WIDTH*c2_i)+4*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c2_i + 3*DRAM_WIDTH); 
         data_rise1_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))+1) - 1 downto  							   DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))))
              	      <= data_sync_c2((4*DRAM_WIDTH*c2_i)+3*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c2_i + 2*DRAM_WIDTH); 
         data_fall0_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))+1) - 1 downto  							   DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))))
              	      <= data_sync_c2((4*DRAM_WIDTH*c2_i)+2*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c2_i + 1*DRAM_WIDTH); 
         data_rise0_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))+1) - 1 downto  							   DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL2((8*(c2_i+1))-1 downto 8*c2_i)))))
              	      <= data_sync_c2((4*DRAM_WIDTH*c2_i)+DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c2_i); 		
         end process;
      end generate;

         u_rddata_sync_c2: circ_buffer
         generic map (
         	TCQ  => TCQ,
              	DATA_WIDTH => (4*nDQS_COL2)+(4*DRAM_WIDTH*nDQS_COL2),
              	BUF_DEPTH => 6
              )
         port map (
                rclk  => clk,
              	wclk  => clk_rsync(2),
              	rst   => rst_rsync(2),	    
              	wdata => wdata_xhdl2,
              	rdata => rdata_xhdl2
              );

   end generate;


   gen_c3: if (nDQS_COL3 > 0) generate
   begin
      gen_loop_c3: for c3_i in 0 to (nDQS_COL3-1) generate
      begin	      
      -- Steer data to circular buffer - merge FALL/RISE data into single bus
         process (rd_dqs_fall0, rd_dqs_fall1, rd_dqs_rise0,
                  rd_dqs_rise1)
         begin	   
         dqs_c3(4*(c3_i+1)-1 downto 4*(c3_i+1)-4) <= rd_dqs_fall1(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))) &
         					     rd_dqs_rise1(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))) &
              					     rd_dqs_fall0(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))) &
              					     rd_dqs_rise0(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i))));
         end process;

         process (rd_data_rise0, rd_data_rise1, rd_data_fall0,
                  rd_data_fall1)
         begin 
         data_c3(4*DRAM_WIDTH*(c3_i+1)-1 downto 4*DRAM_WIDTH*c3_i) <= 
         				rd_data_fall1(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))  )) &
         				rd_data_rise1(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))  )) &
         				rd_data_fall0(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))  )) &
         				rd_data_rise0(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))+1) - 1 downto  							DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))  ));
         end process;

         -- Reassemble data from circular buffer
         process (dqs_sync_c3(4*c3_i), dqs_sync_c3(4*c3_i+1),
                  dqs_sync_c3(4*c3_i+2), dqs_sync_c3(4*c3_i+3))
         begin
            dqs_fall1_sync(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))) <= dqs_sync_c3(4*c3_i+3);
            dqs_rise1_sync(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))) <= dqs_sync_c3(4*c3_i+2);
            dqs_fall0_sync(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))) <= dqs_sync_c3(4*c3_i+1);
            dqs_rise0_sync(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))) <= dqs_sync_c3(4*c3_i+0);
         end process;      							

         process (data_sync_c3((4*DRAM_WIDTH*c3_i)+DRAM_WIDTH-1   downto 4*DRAM_WIDTH*c3_i),
                  data_sync_c3((4*DRAM_WIDTH*c3_i)+2*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c3_i + DRAM_WIDTH),
                  data_sync_c3((4*DRAM_WIDTH*c3_i)+3*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c3_i + 2*DRAM_WIDTH),
                  data_sync_c3((4*DRAM_WIDTH*c3_i)+4*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c3_i + 3*DRAM_WIDTH)
                 )
         begin 
         data_fall1_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))+1) - 1 downto  							   DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))))
              	      <= data_sync_c3((4*DRAM_WIDTH*c3_i)+4*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c3_i + 3*DRAM_WIDTH); 
         data_rise1_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))+1) - 1 downto  							   DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))))
              	      <= data_sync_c3((4*DRAM_WIDTH*c3_i)+3*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c3_i + 2*DRAM_WIDTH); 
         data_fall0_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))+1) - 1 downto  							   DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))))
              	      <= data_sync_c3((4*DRAM_WIDTH*c3_i)+2*DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c3_i + 1*DRAM_WIDTH); 
         data_rise0_sync(DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))+1) - 1 downto  							   DRAM_WIDTH*(TO_INTEGER(unsigned(DQS_LOC_COL3((8*(c3_i+1))-1 downto 8*c3_i)))))
              	      <= data_sync_c3((4*DRAM_WIDTH*c3_i)+DRAM_WIDTH-1 downto 4*DRAM_WIDTH*c3_i); 		
         end process;
      end generate;

         u_rddata_sync_c3: circ_buffer
         generic map (
         	TCQ  => TCQ,
              	DATA_WIDTH => (4*nDQS_COL3)+(4*DRAM_WIDTH*nDQS_COL3),
              	BUF_DEPTH => 6
              )
         port map (
                rclk  => clk,
              	wclk  => clk_rsync(3),
              	rst   => rst_rsync(3),	    
              	wdata => wdata_xhdl3,
              	rdata => rdata_xhdl3
              );

   end generate;

   --*******************************************************************************

   -- Pipeline stage only required if timing not met otherwise
   process (clk)
   begin
      if (clk'event and clk = '1') then
         dfi_rddata  <= (data_fall1_sync & data_rise1_sync & data_fall0_sync & data_rise0_sync) after TCQ*1 ps;
         dfi_rd_dqs  <= (dqs_fall1_sync & dqs_rise1_sync & dqs_fall0_sync & dqs_rise0_sync) after TCQ*1 ps;
      end if;
   end process;

   -- Drive the inputs of circular buffer  
   wdata_xhdl0 <= (dqs_c0 & data_c0);    
   dqs_sync_c0  <= rdata_xhdl0(((4*COL0_VECT_WIDTH)+(4*DRAM_WIDTH*COL0_VECT_WIDTH)-1) downto (4*DRAM_WIDTH*COL0_VECT_WIDTH));
   data_sync_c0  <= rdata_xhdl0(((4*DRAM_WIDTH*COL0_VECT_WIDTH)-1) downto 0 );

   wdata_xhdl1 <= (dqs_c1 & data_c1);    
   dqs_sync_c1  <= rdata_xhdl1(((4*COL1_VECT_WIDTH)+(4*DRAM_WIDTH*COL1_VECT_WIDTH)-1) downto (4*DRAM_WIDTH*COL1_VECT_WIDTH));
   data_sync_c1  <= rdata_xhdl1(((4*DRAM_WIDTH*COL1_VECT_WIDTH)-1) downto 0 );

   wdata_xhdl2 <= (dqs_c2 & data_c2);    
   dqs_sync_c2  <= rdata_xhdl2(((4*COL2_VECT_WIDTH)+(4*DRAM_WIDTH*COL2_VECT_WIDTH)-1) downto (4*DRAM_WIDTH*COL2_VECT_WIDTH));
   data_sync_c2  <= rdata_xhdl2(((4*DRAM_WIDTH*COL2_VECT_WIDTH)-1) downto 0 );

   wdata_xhdl3 <= (dqs_c3 & data_c3);    
   dqs_sync_c3  <= rdata_xhdl3(((4*COL3_VECT_WIDTH)+(4*DRAM_WIDTH*COL3_VECT_WIDTH)-1) downto (4*DRAM_WIDTH*COL3_VECT_WIDTH));
   data_sync_c3  <= rdata_xhdl3(((4*DRAM_WIDTH*COL3_VECT_WIDTH)-1) downto 0 );

end trans;





