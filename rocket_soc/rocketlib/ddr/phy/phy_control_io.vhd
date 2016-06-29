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
-- \   \   \/     Application: MIG                                
--  \   \         Filename: phy_control_io.vhd                    
--  /   /         Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- /___/   /\     Date Created: Aug 03 2009                       
-- \   \  /  \     
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--   Instantiates IOB blocks for output-only control/address signals to DRAM.
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_control_io.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_control_io.vhd,v $
--******************************************************************************
library unisim;
   use unisim.vcomponents.all;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_control_io is
   generic (
      TCQ                    : integer := 100;		-- clk->out delay (sim only)
      BANK_WIDTH             : integer := 2;		-- # of bank bits
      RANK_WIDTH             : integer := 1;		-- log2(CS_WIDTH)
      nCS_PER_RANK           : integer := 1;		-- # of unique CS outputs per rank
      CS_WIDTH               : integer := 1;		-- # of DRAM ranks
      CKE_WIDTH              : integer := 1;		-- # of DRAM ranks
      ROW_WIDTH              : integer := 14;		-- DRAM address bus width
      WRLVL                  : string := "OFF";		-- Enable write leveling
      nCWL                   : integer := 5;		-- Write Latency
      DRAM_TYPE              : string := "DDR3";	-- Memory I/F type: "DDR3", "DDR2"
      REG_CTRL               : string := "ON";		-- "ON" for registered DIMM
      REFCLK_FREQ            : real := 300.0;		-- IODELAY Reference Clock freq (MHz)
      IODELAY_HP_MODE        : string := "ON";		-- IODELAY High Performance Mode
      IODELAY_GRP            : string := "IODELAY_MIG";	-- May be assigned unique name
      							-- when mult IP cores in design
      DDR2_EARLY_CS          : integer := 0             -- set = 1 for >200 MHz DDR2 UDIMM designs
                                                        -- for early launch of CS

   );
   port (
      clk_mem                : in std_logic;-- full rate core clock    
      clk                    : in std_logic;-- half rate core clock    
      rst                    : in std_logic;-- half rate core clk reset
      mc_data_sel            : in std_logic;-- =1 for MC control, =0 for PHY 
      dfi_address0           : in std_logic_vector(ROW_WIDTH - 1 downto 0);
      dfi_address1           : in std_logic_vector(ROW_WIDTH - 1 downto 0);
      dfi_bank0              : in std_logic_vector(BANK_WIDTH - 1 downto 0);
      dfi_bank1              : in std_logic_vector(BANK_WIDTH - 1 downto 0);
      dfi_cas_n0             : in std_logic;
      dfi_cas_n1             : in std_logic;
      dfi_cke0               : in std_logic_vector(CKE_WIDTH - 1 downto 0);
      dfi_cke1               : in std_logic_vector(CKE_WIDTH - 1 downto 0);
      dfi_cs_n0              : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      dfi_cs_n1              : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      dfi_odt0               : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      dfi_odt1               : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      dfi_ras_n0             : in std_logic;
      dfi_ras_n1             : in std_logic;
      dfi_reset_n            : in std_logic;
      dfi_we_n0              : in std_logic;
      dfi_we_n1              : in std_logic;
      -- DFI address/control      
      phy_address0           : in std_logic_vector(ROW_WIDTH - 1 downto 0);
      phy_address1           : in std_logic_vector(ROW_WIDTH - 1 downto 0);
      phy_bank0              : in std_logic_vector(BANK_WIDTH - 1 downto 0);
      phy_bank1              : in std_logic_vector(BANK_WIDTH - 1 downto 0);
      phy_cas_n0             : in std_logic;
      phy_cas_n1             : in std_logic;
      phy_cke0               : in std_logic_vector(CKE_WIDTH - 1 downto 0);
      phy_cke1               : in std_logic_vector(CKE_WIDTH - 1 downto 0);
      phy_cs_n0              : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      phy_cs_n1              : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      phy_odt0               : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      phy_odt1               : in std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      phy_ras_n0             : in std_logic;
      phy_ras_n1             : in std_logic;
      phy_reset_n            : in std_logic;
      phy_we_n0              : in std_logic;
      phy_we_n1              : in std_logic;
      -- DDR3-side address/control
      ddr_addr               : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      ddr_ba                 : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      ddr_ras_n              : out std_logic;
      ddr_cas_n              : out std_logic;
      ddr_we_n               : out std_logic;
      ddr_cke                : out std_logic_vector(CKE_WIDTH - 1 downto 0);
      ddr_cs_n               : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      ddr_odt                : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      ddr_parity             : out std_logic;
      ddr_reset_n            : out std_logic
   );
end phy_control_io;

architecture arch_phy_control_io of phy_control_io is

   function CALC_SINGLE_RANK_CS return integer is
     begin
    if ((REG_CTRL = "ON") and (DRAM_TYPE = "DDR3") and (CS_WIDTH = 1) and (nCS_PER_RANK = 2)) then
      return 1;
    else
      return 0;
    end if;
   end function CALC_SINGLE_RANK_CS;
   
   function CALC_HIGH_PERFORMANCE_MODE return boolean is
   begin
      if (IODELAY_HP_MODE = "OFF") then
         return FALSE;
      else
         return TRUE;
      end if;
   end function CALC_HIGH_PERFORMANCE_MODE;
   
   function XOR_BR (val : std_logic_vector) return std_logic is
    variable rtn : std_logic := '0';
    begin
    for index in val'range loop
      rtn := rtn xor val(index);
    end loop;
    return(rtn);
  end function XOR_BR;

   -- Set performance mode for IODELAY (power vs. performance tradeoff)
   -- COMMENTED, 022009, RICHC. This is temporary pending IR 509123
   constant HIGH_PERFORMANCE_MODE  : boolean := CALC_HIGH_PERFORMANCE_MODE;
    
   -- local parameter for the single rank DDR3 dimm case. This parameter will be
   -- set when the number of chip selects is == 2 for a single rank registered 
   -- dimm.
   constant SINGLE_RANK_CS_REG     : integer := CALC_SINGLE_RANK_CS;
   
   signal mux_addr0         : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal mux_addr1         : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal mux_ba0           : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal mux_ba1           : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal mux_cas_n0        : std_logic;
   signal mux_cas_n1        : std_logic;
   signal mux_cke0          : std_logic_vector(CKE_WIDTH - 1 downto 0);
   signal mux_cke1          : std_logic_vector(CKE_WIDTH - 1 downto 0);
   signal mux_cs_n0         : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal mux_cs_n1         : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal mux_cs_d1         : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal mux_cs_d2         : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal mux_cs_d3         : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal mux_cs_d4         : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal mux_ioconfig      : std_logic_vector(0 downto 0);
   signal mux_ioconfig_en   : std_logic;
   signal mux_odt0          : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal mux_odt1          : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal mux_ras_n0        : std_logic;
   signal mux_ras_n1        : std_logic;
   signal mux_reset_n       : std_logic;
   signal mux_we_n0         : std_logic;
   signal mux_we_n1         : std_logic;
   signal oce_temp          : std_logic;
   signal parity0           : std_logic;
   signal parity1           : std_logic;
   signal rst_delayed       : std_logic_vector(3 downto 0);
   
   signal addr_odelay       : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal addr_oq           : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal ba_odelay         : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal ba_oq             : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal cas_n_odelay      : std_logic;
   signal cas_n_oq          : std_logic;
   signal cke_odelay        : std_logic_vector(CKE_WIDTH - 1 downto 0);
   signal cke_oq            : std_logic_vector(CKE_WIDTH - 1 downto 0);
   
   signal cs_n_odelay          : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal cs_n_oq              : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal odt_odelay           : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal odt_oq               : std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
   signal parity_odelay        : std_logic;
   signal parity_oq            : std_logic;
   signal reset_n_oq           : std_logic;
   signal ras_n_odelay         : std_logic;
   signal ras_n_oq             : std_logic;
   signal rst_cke_odt          : std_logic;
   signal rst_r		       : std_logic;
   signal oce_hack_r           : std_logic;
   signal oce_hack_r1          : std_logic;
   signal oce_hack_r2          : std_logic;
   signal oce_hack_r3          : std_logic;
   signal oce_hack_r4          : std_logic;
   signal oce_hack_r5          : std_logic;
   -- synthesis syn_keep = 1 
   signal we_n_odelay          : std_logic;
   signal we_n_oq              : std_logic;

   attribute IODELAY_GROUP : string;

begin

   -- XST attributes for local reset tree RST_R - prohibit equivalent 
   -- register removal on RST_R to prevent "sharing" w/ other local reset trees
   -- synthesis attribute shreg_extract of rst_r is "no";  
   -- synthesis attribute equivalent_register_removal of rst_r is "no"

   --***************************************************************************
   -- Reset pipelining - register reset signals to prevent large (and long)
   -- fanouts during physical compilation of the design. Create one local reset
   -- for most control/address OSERDES blocks - note that user may need to 
   -- change this if control/address are more "spread out" through FPGA
   --***************************************************************************

   process (clk)
   begin
      if (clk'event and clk = '1') then
         rst_r <= rst after (TCQ)*1 ps;	      
      end if;
   end process;
       	
   --***************************************************************************
   -- Generate delayed version of global reset. 
   --***************************************************************************
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         rst_delayed(0) <= rst after (TCQ)*1 ps;
         rst_delayed(1) <= rst_delayed(0) after (TCQ)*1 ps;
         rst_delayed(2) <= rst_delayed(1) after (TCQ)*1 ps;
         rst_delayed(3) <= rst_delayed(2) after (TCQ)*1 ps;
      end if;
   end process;
   
   
   -- Drive ODT and CKE OSERDES with these resets in order to ensure that 
   -- they remain low until after DDR_RESET_N is deasserted. This is done for
   -- simulation reasons only, as some memory models will issue an error if
   -- ODT/CKE are asserted prior to deassertion of RESET_N
   rst_cke_odt <= rst_delayed(3);
   
   --***************************************************************************
   
   -- The following logic is only required to support DDR2 simulation, and is
   -- done to prevent glitching on the ODT and CKE signals after "power-up".
   -- Certain models will flag glitches on these lines as errors. 
   -- To fix this, the OCE for OSERDES is used to prevent glitches. However, 
   -- this may lead to setup time issues when running this design through
   -- ISE - because the OCE setup is w/r/t to CLK (i.e. the "fast" clock).
   -- It can be problematic to meet timing - therefore this path should be
   -- marked as a false path (TIG) because it will be asserted long before
   -- the OSERDES outputs need to be valid. This logic is disabled for the
   -- DDR3 case because it is not required
   -- LOGIC DESCRIPTION: 
   -- Generating OCE for DDR2 ODT & CKE. The output of the OSERDES model toggles
   -- when it comes out of reset. This causes issues in simulation. Controlling 
   -- it OCE until there is a library fix. OCE will be asserted after 10 clks 
   -- after reset de-assertion
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         oce_hack_r  <= not(rst_delayed(3))  after TCQ*1 ps;
         oce_hack_r1 <= oce_hack_r after TCQ*1 ps;
         oce_hack_r2 <= oce_hack_r1 after TCQ*1 ps;
         oce_hack_r3 <= oce_hack_r2 after TCQ*1 ps;
         oce_hack_r4 <= oce_hack_r3 after TCQ*1 ps;
         oce_hack_r5 <= oce_hack_r4 after TCQ*1 ps;
      end if;
   end process;   
   
   -- Only use for DDR2. For DDR3, drive to constant high
   oce_temp <= oce_hack_r5 when (DRAM_TYPE = "DDR2") else
                  '1';
   
   --***************************************************************************  
   -- MUX to choose from either PHY or controller for DRAM control
   -- NOTE: May need to add pipeline register to meet timing
   --***************************************************************************  

   mux_addr0 <= dfi_address0 when (mc_data_sel = '1') else
                phy_address0;
   mux_addr1 <= dfi_address1 when (mc_data_sel = '1') else
                phy_address1;
   mux_ba0 <= dfi_bank0 when (mc_data_sel = '1') else
              phy_bank0;
   mux_ba1 <= dfi_bank1 when (mc_data_sel = '1') else
              phy_bank1;
   mux_cas_n0 <= dfi_cas_n0 when (mc_data_sel = '1') else
                 phy_cas_n0;
   mux_cas_n1 <= dfi_cas_n1 when (mc_data_sel = '1') else
                 phy_cas_n1;
   mux_cke0 <= dfi_cke0 when (mc_data_sel = '1') else
               phy_cke0;
   mux_cke1 <= dfi_cke1 when (mc_data_sel = '1') else
               phy_cke1;
   mux_odt0 <= dfi_odt0 when (mc_data_sel = '1') else
               phy_odt0;
   mux_odt1 <= dfi_odt1 when (mc_data_sel = '1') else
               phy_odt1;
   mux_ras_n0 <= dfi_ras_n0 when (mc_data_sel = '1') else
                 phy_ras_n0;
   mux_ras_n1 <= dfi_ras_n1 when (mc_data_sel = '1') else
                 phy_ras_n1;
   mux_reset_n <= dfi_reset_n when (mc_data_sel = '1') else
                  phy_reset_n;
   mux_we_n0 <= dfi_we_n0 when (mc_data_sel = '1') else
                phy_we_n0;
   mux_we_n1 <= dfi_we_n1 when (mc_data_sel = '1') else
                phy_we_n1;

   --***************************************************************************  
   -- assigning chip select values.
   -- For DDR3 Registered dimm's the chip select pins are toggled in a unique 
   -- way to differentiate between register programming and regular DIMM access.
   -- For a single rank registered dimm with two chip selects the chip select 
   -- will be toggled in the following manner:
   -- cs[0] =0, cs[1] = 0 the access is to the registered chip. On the 
   -- remaining combinations the access is to the DIMM. The SINGLE_RANK_CS_REG 
   -- parameter will be set for the above configurations and the chip select 
   -- pins will be toggled as per the DDR3 registered DIMM requirements. The 
   -- phy takes care of the register programming, and handles the chip 
   -- select's correctly for calibration and initialization. But the controller
   -- does not know about this mode, the controller cs[1] bits will be tied to 
   -- 1'b1; All the controller access will be to the DIMM and none to the 
   -- register chip. Rest of the DDR3 register dimm configurations are 
   -- handled well by the controller.
   --***************************************************************************     
   gen_single_rank : if (SINGLE_RANK_CS_REG = 1) generate
      process (mc_data_sel, dfi_cs_n0(0), dfi_cs_n1(0), phy_cs_n0(0), phy_cs_n1(0), phy_cs_n0(1), phy_cs_n1(1))
      begin
         if (mc_data_sel = '1') then
            mux_cs_n0(0) <= dfi_cs_n0(0);
            mux_cs_n1(0) <= dfi_cs_n1(0);
            mux_cs_n0(1) <= '1';
            mux_cs_n1(1) <= '1';
         else
            mux_cs_n0(0) <= phy_cs_n0(0);
            mux_cs_n1(0) <= phy_cs_n1(0);
            mux_cs_n0(1) <= phy_cs_n0(1);
            mux_cs_n1(1) <= phy_cs_n1(1);
         end if;
      end process;
      
   end generate;
   gen_mult_rank : if (SINGLE_RANK_CS_REG /= 1) generate
      process (mc_data_sel, dfi_cs_n0, dfi_cs_n1, phy_cs_n0, phy_cs_n1)
      begin
         if (mc_data_sel = '1') then
            mux_cs_n0 <= dfi_cs_n0;
            mux_cs_n1 <= dfi_cs_n1;
         else
            mux_cs_n0 <= phy_cs_n0;
            mux_cs_n1 <= phy_cs_n1;
         end if;
      end process;
      
   end generate;

   -- for DDR2 UDIMM designs the CS has to be launched early.
   -- Setting the OSERDES input based on the DDR2_EARLY_CS parameter.
   -- when this paramter is CS will be launched half a cycle early.
   -- Launching half a cycle early will cause simulation issues.
   -- Using synthesis options to control the assignment

   process (mux_cs_n0,mux_cs_n1) 
   begin
     if(DDR2_EARLY_CS = 1) then
       mux_cs_d1 <= mux_cs_n0;
       mux_cs_d2 <= mux_cs_n1;
       mux_cs_d3 <= mux_cs_n1;
       mux_cs_d4 <= mux_cs_n0;
     else 
       mux_cs_d1 <= mux_cs_n0;
       mux_cs_d2 <= mux_cs_n0;
       mux_cs_d3 <= mux_cs_n1;
       mux_cs_d4 <= mux_cs_n1;
     end if; -- else: !if(DDR2_EARLY_CS == 1)

     -- For simulation override the assignment for
     -- synthesis do not override
     -- synthesis translate_off
     mux_cs_d1 <= mux_cs_n0;
     mux_cs_d2 <= mux_cs_n0;
     mux_cs_d3 <= mux_cs_n1;
     mux_cs_d4 <= mux_cs_n1;  
     -- synthesis translate_on
   end process;

   -- parity for reg dimm. Have to check the timing impact.
   -- Generate only for DDR3 RDIMM.
   -- registring with negedge. Half cycle path.    
   gen_ddr3_parity : if ((DRAM_TYPE = "DDR3") and (REG_CTRL = "ON")) generate
      parity0 <= (XOR_BR(mux_addr0 & mux_ba0 & mux_cas_n0 & mux_ras_n0 & mux_we_n0));
      process (clk)
      begin
         if (clk'event and clk = '1') then
            parity1 <= (XOR_BR(mux_addr1 & mux_ba1 & mux_cas_n1 & mux_ras_n1 & mux_we_n1)) after (TCQ)*1 ps;
         end if;
      end process;   
   end generate;

   gen_ddr3_noparity : if (not(DRAM_TYPE = "DDR3") or not(REG_CTRL = "ON")) generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            parity0 <= '0' after (TCQ)*1 ps;
            parity1 <= '0' after (TCQ)*1 ps;
         end if;
      end process;      
   end generate;

   --*****************************************************************
   -- DDR3 reset: Note that this output is generated with an ODDR clocked
   -- by the internal div-by-2 clock. It can be generated using the same
   -- OSERDES structure as for the other control/address signals. However
   -- there are no specific setup/hold requirements on reset_n w/r/t CK.
   -- In addition, this an ODDR was used to prevent any glitching on reset_n
   -- during startup. This was done for simulation considerations only -
   -- the glitch causes warnings with the Denali DDR3 model (but will not
   -- cause any issues in hardware).
   --*****************************************************************
   u_out_reset_n : ODDR
      generic map (
         DDR_CLK_EDGE  => "SAME_EDGE",
         INIT          => '0',
         SRTYPE        => "ASYNC"
      )
      port map (
         Q   => reset_n_oq,
         C   => clk,
         CE  => '1',
         D1  => mux_reset_n,
         D2  => mux_reset_n,
         R   => rst_r,
         S   => '0'
      );

      u_reset_n_obuf : OBUF
        port map (
          I => reset_n_oq,
          O => ddr_reset_n
        );

   --*****************************************************************
   -- Note on generation of Control/Address signals - there are
   -- several possible configurations that affect the configuration
   -- of the OSERDES and possible ODELAY for each output (this will
   -- also affect the CK/CK# outputs as well
   --   1. DDR3, write-leveling: This is the simplest case. Use
   --      OSERDES without the ODELAY. Initially clock/control/address
   --      will be offset coming out of FPGA from DQ/DQS, but DQ/DQS
   --      will be adjusted so that DQS-CK alignment is established
   --   2. DDR2 or DDR3 (no write-leveling): Both DQS and DQ will use 
   --      ODELAY to delay output of OSERDES. To match this, 
   --      CK/control/address must also delay their outputs using ODELAY 
   --      (with delay = 0)
   --*****************************************************************
   
   --*****************************************************************
   -- RAS: = 1 at reset
   --*****************************************************************
   
   gen_ras_n_wrlvl : if ((DRAM_TYPE = "DDR3") and (WRLVL = "ON")) generate
      
      --*******************************************************
      -- CASE1: DDR3, write-leveling
      --*******************************************************
      u_ras_n_obuf : OBUF
        port map (
          I => ras_n_oq,
          O => ddr_ras_n
        );
   
   end generate;

   gen_ras_n_nowrlvl: if (not(DRAM_TYPE = "DDR3") or not(WRLVL = "ON")) generate

      attribute IODELAY_GROUP of  u_iodelay_ras_n : label is IODELAY_GRP;   
   begin   
      --*******************************************************
      -- CASE2: DDR3, no write-leveling
      --*******************************************************
      u_ras_n_obuf : OBUF
        port map (
          I => ras_n_odelay,
          O => ddr_ras_n
        );
          
      u_iodelay_ras_n : IODELAYE1
         generic map (
            CINVCTRL_SEL           => FALSE,
            DELAY_SRC              => "O",
            HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
            IDELAY_TYPE            => "FIXED",
            IDELAY_VALUE           => 0,
            ODELAY_TYPE            => "FIXED",
            ODELAY_VALUE           => 0,
            REFCLK_FREQUENCY       => REFCLK_FREQ,
            SIGNAL_PATTERN         => "DATA"
         )
         port map (
            DATAOUT      => ras_n_odelay,
            C            => '0',
            CE           => '0',
            DATAIN       => 'Z',
            IDATAIN      => 'Z',
            INC          => '0',
            ODATAIN      => ras_n_oq,
            RST          => '0',
            T            => 'Z',
            CNTVALUEIN   => "ZZZZZ",
            CNTVALUEOUT  => open,
            CLKIN        => 'Z',
            CINVCTRL     => '0'
         );            
   end generate;

   u_out_ras_n : OSERDESE1
      generic map (
         DATA_RATE_OQ     => "DDR",
         DATA_RATE_TQ     => "DDR",
         DATA_WIDTH       => 4,
         DDR3_DATA        => 0,
         INIT_OQ          => '1', -- 1 at reset  
         INIT_TQ          => '0',
         INTERFACE_TYPE   => "DEFAULT",
         ODELAY_USED      => 0,
         SERDES_MODE      => "MASTER",
         SRVAL_OQ         => '0',
         SRVAL_TQ         => '0',
         TRISTATE_WIDTH   => 4
      )
      port map (
         OCBEXTEND    => open,
         OFB          => open,
         OQ           => ras_n_oq,
         SHIFTOUT1    => open,
         SHIFTOUT2    => open,
         TQ           => open,
         CLK          => clk_mem,                  
         CLKDIV       => clk,                  
         CLKPERF      => 'Z',
         CLKPERFDELAY => 'Z',
         D1           => mux_ras_n0,
         D2           => mux_ras_n0,
         D3           => mux_ras_n1,
         D4           => mux_ras_n1,
         D5           => 'Z',
         D6           => 'Z',
         ODV          => '0',
         OCE          => '1',
         SHIFTIN1     => 'Z',
         SHIFTIN2     => 'Z',                 
         RST          => rst_r,
         T1           => '0',
         T2           => '0',
         T3           => '0',
         T4           => '0',
         TFB          => open,
         TCE          => '1',
	 WC           => '0'
      );
          
   --*******************************************************
   -- CAS: = 1 at reset 
   --*******************************************************
   gen_cas_n_wrlvl : if ((DRAM_TYPE = "DDR3") and (WRLVL = "ON")) generate

      u_cas_n_obuf : OBUF
        port map (
          I => cas_n_oq,
          O => ddr_cas_n
        );

   end generate;

   gen_cas_n_nowrlvl : if (not(DRAM_TYPE = "DDR3") or not(WRLVL = "ON")) generate

      attribute IODELAY_GROUP of  u_iodelay_cas_n : label is IODELAY_GRP;   
   begin   
      u_cas_n_obuf : OBUF
        port map (
          I => cas_n_odelay,
          O => ddr_cas_n
        );

      u_iodelay_cas_n : IODELAYE1
         generic map (
            CINVCTRL_SEL           => FALSE,
            DELAY_SRC              => "O",
            HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
            IDELAY_TYPE            => "FIXED",
            IDELAY_VALUE           => 0,
            ODELAY_TYPE            => "FIXED",
            ODELAY_VALUE           => 0,
            REFCLK_FREQUENCY       => REFCLK_FREQ,
            SIGNAL_PATTERN         => "DATA"
         )
         port map (
            DATAOUT      => cas_n_odelay,
            C            => '0',
            CE           => '0',
            DATAIN       => 'Z',
            IDATAIN      => 'Z',
            INC          => '0',
            ODATAIN      => cas_n_oq,
            RST          => '0',
            T            => 'Z',
            CNTVALUEIN   => "ZZZZZ",
            CNTVALUEOUT  => open,
            CLKIN        => 'Z',
            CINVCTRL     => '0'
         );
   end generate;	     
                                                                    
   u_out_cas_n : OSERDESE1
      generic map (
         DATA_RATE_OQ    => "DDR",
         DATA_RATE_TQ    => "DDR",
         DATA_WIDTH      => 4,
         DDR3_DATA       => 0, 
         INIT_OQ         => '1',   -- 1 at reset      
         INIT_TQ         => '0',
         INTERFACE_TYPE  => "DEFAULT",
         ODELAY_USED     => 0,
         SERDES_MODE     => "MASTER",
         SRVAL_OQ        => '0',
         SRVAL_TQ        => '0',
         TRISTATE_WIDTH  => 4
      )
      port map (
         OCBEXTEND     => open,
         OFB           => open,
         OQ            => cas_n_oq,
         SHIFTOUT1     => open,
         SHIFTOUT2     => open,
         TQ            => open,
         CLK           => clk_mem,                     
         CLKDIV        => clk,                     
         CLKPERF       => 'Z',
         CLKPERFDELAY  => 'Z',
         D1            => mux_cas_n0,
         D2            => mux_cas_n0,
         D3            => mux_cas_n1,
         D4            => mux_cas_n1,
         D5            => 'Z',
         D6            => 'Z',
         ODV           => '0',
         OCE           => '1',
         SHIFTIN1      => 'Z',
         SHIFTIN2      => 'Z',                     
         RST           => rst_r,
         T1            => '0',
         T2            => '0',
         T3            => '0',
         T4            => '0',
         TFB           => open,
         TCE           => '1',                     
         WC            => '0' 
      );

   --*******************************************************
   -- WE: = 1 at reset 
   --*******************************************************
   gen_we_n_wrlvl : if ((DRAM_TYPE = "DDR3") and (WRLVL = "ON")) generate

      u_we_n_obuf : OBUF
        port map (
          I => we_n_oq,
          O => ddr_we_n
        );

   end generate;

   gen_we_n_nowrlvl : if (not(DRAM_TYPE = "DDR3") or not(WRLVL = "ON")) generate

      attribute IODELAY_GROUP of  u_iodelay_we_n : label is IODELAY_GRP;   
   begin   
      u_we_n_obuf : OBUF
        port map (
          I => we_n_odelay,
          O => ddr_we_n
        );

      u_iodelay_we_n : IODELAYE1
         generic map (
            CINVCTRL_SEL           => FALSE,
            DELAY_SRC              => "O",
            HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
            IDELAY_TYPE            => "FIXED",
            IDELAY_VALUE           => 0,
            ODELAY_TYPE            => "FIXED",
            ODELAY_VALUE           => 0,
            REFCLK_FREQUENCY       => REFCLK_FREQ,
            SIGNAL_PATTERN         => "DATA"
         )
         port map (
            DATAOUT      => we_n_odelay,
            C            => '0',
            CE           => '0',
            DATAIN       => 'Z',
            IDATAIN      => 'Z',
            INC          => '0',
            ODATAIN      => we_n_oq,
            RST          => '0',
            T            => 'Z',
            CNTVALUEIN   => "ZZZZZ",
            CNTVALUEOUT  => open,
            CLKIN        => 'Z',
            CINVCTRL     => '0'
         );
   end generate;	     
                                                                    
   u_out_we_n : OSERDESE1
      generic map (
         DATA_RATE_OQ    => "DDR",
         DATA_RATE_TQ    => "DDR",
         DATA_WIDTH      => 4,
         DDR3_DATA       => 0, 
         INIT_OQ         => '1',   -- 1 at reset      
         INIT_TQ         => '0',
         INTERFACE_TYPE  => "DEFAULT",
         ODELAY_USED     => 0,
         SERDES_MODE     => "MASTER",
         SRVAL_OQ        => '0',
         SRVAL_TQ        => '0',
         TRISTATE_WIDTH  => 4
      )
      port map (
         OCBEXTEND     => open,
         OFB           => open,
         OQ            => we_n_oq,
         SHIFTOUT1     => open,
         SHIFTOUT2     => open,
         TQ            => open,
         CLK           => clk_mem,                     
         CLKDIV        => clk,                     
         CLKPERF       => 'Z',
         CLKPERFDELAY  => 'Z',
         D1            => mux_we_n0,
         D2            => mux_we_n0,
         D3            => mux_we_n1,
         D4            => mux_we_n1,
         D5            => 'Z',
         D6            => 'Z',
         ODV           => '0',
         OCE           => '1',
         SHIFTIN1      => 'Z',
         SHIFTIN2      => 'Z',                    
         RST           => rst_r,
         T1            => '0',
         T2            => '0',
         T3            => '0',
         T4            => '0',
         TFB           => open,
         TCE           => '1',                     
         WC            => '0' 
      );

   --*******************************************************
   -- CKE: = 0 at reset 
   --*******************************************************
   gen_cke: for cke_i in 0 to (CKE_WIDTH-1) generate   
      gen_cke_wrlvl : if ((DRAM_TYPE = "DDR3") and (WRLVL = "ON")) generate
         u_cke_obuf : OBUF
           port map (
             I => cke_oq(cke_i),
             O => ddr_cke(cke_i)
           );
      end generate;

      gen_cke_nowrlvl : if (not(DRAM_TYPE = "DDR3") or not(WRLVL = "ON")) generate
         attribute IODELAY_GROUP of  u_iodelay_cke : label is IODELAY_GRP;   
      begin   
         u_cke_obuf : OBUF
           port map (
             I => cke_odelay(cke_i),
             O => ddr_cke(cke_i)
           );

         u_iodelay_cke : IODELAYE1
            generic map (
               CINVCTRL_SEL           => FALSE,
               DELAY_SRC              => "O",
               HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
               IDELAY_TYPE            => "FIXED",
               IDELAY_VALUE           => 0,
               ODELAY_TYPE            => "FIXED",
               ODELAY_VALUE           => 0,
               REFCLK_FREQUENCY       => REFCLK_FREQ,
               SIGNAL_PATTERN         => "DATA"
            )
            port map (
               DATAOUT      => cke_odelay(cke_i),
               C            => '0',
               CE           => '0',
               DATAIN       => 'Z',
               IDATAIN      => 'Z',
               INC          => '0',
               ODATAIN      => cke_oq(cke_i),
               RST          => '0',
               T            => 'Z',
               CNTVALUEIN   => "ZZZZZ",
               CNTVALUEOUT  => open,
               CLKIN        => 'Z',
               CINVCTRL     => '0'
            );
      end generate;	     
                                                                       
      u_out_cke : OSERDESE1
         generic map (
            DATA_RATE_OQ    => "DDR",
            DATA_RATE_TQ    => "DDR",
            DATA_WIDTH      => 4,
            DDR3_DATA       => 0, 
            INIT_OQ         => '0',   -- 0 at reset      
            INIT_TQ         => '0',
            INTERFACE_TYPE  => "DEFAULT",
            ODELAY_USED     => 0,
            SERDES_MODE     => "MASTER",
            SRVAL_OQ        => '0',
            SRVAL_TQ        => '0',
            TRISTATE_WIDTH  => 4
         )
         port map (
            OCBEXTEND     => open,
            OFB           => open,
            OQ            => cke_oq(cke_i),
            SHIFTOUT1     => open,
            SHIFTOUT2     => open,
            TQ            => open,
            CLK           => clk_mem,                     
            CLKDIV        => clk,                     
            CLKPERF       => 'Z',
            CLKPERFDELAY  => 'Z',
            D1            => mux_cke0(cke_i),
            D2            => mux_cke0(cke_i),
            D3            => mux_cke1(cke_i),
            D4            => mux_cke1(cke_i),
            D5            => 'Z',
            D6            => 'Z',
            ODV           => '0',
            OCE           => oce_temp,
            -- Connect SHIFTIN1, SHIFTIN2 to 0 for simulation purposes
            -- (for all other OSERDES used in design, these are no-connects):
            -- ensures that CKE outputs are not X at start of simulation
            -- Certain DDR2 memory models may require that CK/CK# be valid
            -- throughout simulation
            SHIFTIN1      => '0',
            SHIFTIN2      => '0',                     
            RST           => rst_cke_odt,
            T1            => '0',
            T2            => '0',
            T3            => '0',
            T4            => '0',
            TFB           => open,
            TCE           => '1',                     
            WC            => '0' 
         );
   end generate;

   --*******************************************************
   -- chip select  = 1 at reset 
   --*******************************************************
   gen_cs_n: for cs_i in 0 to (CS_WIDTH*nCS_PER_RANK - 1) generate   
      gen_cs_n_wrlvl : if ((DRAM_TYPE = "DDR3") and (WRLVL = "ON")) generate
         u_cs_n_obuf : OBUF
           port map (
             I => cs_n_oq(cs_i),
             O => ddr_cs_n(cs_i)
           );
      end generate;

      gen_cs_n_nowrlvl : if (not(DRAM_TYPE = "DDR3") or not(WRLVL = "ON")) generate

         attribute IODELAY_GROUP of  u_iodelay_cs_n : label is IODELAY_GRP;   
      begin   
         u_cs_n_obuf : OBUF
           port map (
             I => cs_n_odelay(cs_i),
             O => ddr_cs_n(cs_i)
           );
                            
         u_iodelay_cs_n : IODELAYE1
            generic map (
               CINVCTRL_SEL           => FALSE,
               DELAY_SRC              => "O",
               HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
               IDELAY_TYPE            => "FIXED",
               IDELAY_VALUE           => 0,
               ODELAY_TYPE            => "FIXED",
               ODELAY_VALUE           => 0,
               REFCLK_FREQUENCY       => REFCLK_FREQ,
               SIGNAL_PATTERN         => "DATA"
            )
            port map (
               DATAOUT      => cs_n_odelay(cs_i),
               C            => '0',
               CE           => '0',
               DATAIN       => 'Z',
               IDATAIN      => 'Z',
               INC          => '0',
               ODATAIN      => cs_n_oq(cs_i),
               RST          => '0',
               T            => 'Z',
               CNTVALUEIN   => "ZZZZZ",
               CNTVALUEOUT  => open,
               CLKIN        => 'Z',
               CINVCTRL     => '0'
            );
      end generate;	     
                                                                       
      u_out_cs_n : OSERDESE1
         generic map (
            DATA_RATE_OQ    => "DDR",
            DATA_RATE_TQ    => "DDR",
            DATA_WIDTH      => 4,
            DDR3_DATA       => 0, 
            INIT_OQ         => '1',   -- 1 at reset      
            INIT_TQ         => '0',
            INTERFACE_TYPE  => "DEFAULT",
            ODELAY_USED     => 0,
            SERDES_MODE     => "MASTER",
            SRVAL_OQ        => '0',
            SRVAL_TQ        => '0',
            TRISTATE_WIDTH  => 4
         )
         port map (
            OCBEXTEND     => open,
            OFB           => open,
            OQ            => cs_n_oq(cs_i),
            SHIFTOUT1     => open,
            SHIFTOUT2     => open,
            TQ            => open,
            CLK           => clk_mem,                     
            CLKDIV        => clk,                     
            CLKPERF       => 'Z',
            CLKPERFDELAY  => 'Z',
            D1            => mux_cs_d1(cs_i),
            D2            => mux_cs_d2(cs_i),
            D3            => mux_cs_d3(cs_i),
            D4            => mux_cs_d4(cs_i),
            D5            => 'Z',
            D6            => 'Z',
            ODV           => '0',
            OCE           => '1',
            SHIFTIN1      => 'Z',
            SHIFTIN2      => 'Z',                  
            RST           => rst_r,
            T1            => '0',
            T2            => '0',
            T3            => '0',
            T4            => '0',
            TFB           => open,
            TCE           => '1',                     
            WC            => '0' 
         );
   end generate;

   --*******************************************************
   -- address = X at reset 
   --*******************************************************
   gen_addr: for addr_i in 0 to (ROW_WIDTH - 1) generate   
      gen_addr_wrlvl : if ((DRAM_TYPE = "DDR3") and (WRLVL = "ON")) generate
         u_addr_obuf : OBUF
           port map (
             I => addr_oq(addr_i),
             O => ddr_addr(addr_i)
           );
      end generate;

      gen_addr_nowrlvl : if (not(DRAM_TYPE = "DDR3") or not(WRLVL = "ON")) generate

         attribute IODELAY_GROUP of  u_iodelay_addr : label is IODELAY_GRP;   
      begin   
         u_addr_obuf : OBUF
           port map (
             I => addr_odelay(addr_i),
             O => ddr_addr(addr_i)
           );
                            
         u_iodelay_addr : IODELAYE1
            generic map (
               CINVCTRL_SEL           => FALSE,
               DELAY_SRC              => "O",
               HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
               IDELAY_TYPE            => "FIXED",
               IDELAY_VALUE           => 0,
               ODELAY_TYPE            => "FIXED",
               ODELAY_VALUE           => 0,
               REFCLK_FREQUENCY       => REFCLK_FREQ,
               SIGNAL_PATTERN         => "DATA"
            )
            port map (
               DATAOUT      => addr_odelay(addr_i),
               C            => '0',
               CE           => '0',
               DATAIN       => 'Z',
               IDATAIN      => 'Z',
               INC          => '0',
               ODATAIN      => addr_oq(addr_i),
               RST          => '0',
               T            => 'Z',
               CNTVALUEIN   => "ZZZZZ",
               CNTVALUEOUT  => open,
               CLKIN        => 'Z',
               CINVCTRL     => '0'
            );
      end generate;	     
                                                                       
      u_out_addr : OSERDESE1
         generic map (
            DATA_RATE_OQ    => "DDR",
            DATA_RATE_TQ    => "DDR",
            DATA_WIDTH      => 4,
            DDR3_DATA       => 0, 
            INIT_OQ         => '0',   -- 0 at reset      
            INIT_TQ         => '0',
            INTERFACE_TYPE  => "DEFAULT",
            ODELAY_USED     => 0,
            SERDES_MODE     => "MASTER",
            SRVAL_OQ        => '0',
            SRVAL_TQ        => '0',
            TRISTATE_WIDTH  => 4
         )
         port map (
            OCBEXTEND     => open,
            OFB           => open,
            OQ            => addr_oq(addr_i),
            SHIFTOUT1     => open,
            SHIFTOUT2     => open,
            TQ            => open,
            CLK           => clk_mem,                     
            CLKDIV        => clk,                     
            CLKPERF       => 'Z',
            CLKPERFDELAY  => 'Z',
            D1            => mux_addr0(addr_i),
            D2            => mux_addr0(addr_i),
            D3            => mux_addr1(addr_i),
            D4            => mux_addr1(addr_i),
            D5            => 'Z',
            D6            => 'Z',
            ODV           => '0',
            OCE           => '1',
            SHIFTIN1      => 'Z',
            SHIFTIN2      => 'Z',                    
            RST           => rst_r,
            T1            => '0',
            T2            => '0',
            T3            => '0',
            T4            => '0',
            TFB           => open,
            TCE           => '1',                     
            WC            => '0' 
         );
   end generate;

   --*******************************************************
   -- bank address = X at reset 
   --*******************************************************
   gen_ba: for ba_i in 0 to (BANK_WIDTH - 1) generate   
      gen_ba_wrlvl : if ((DRAM_TYPE = "DDR3") and (WRLVL = "ON")) generate
         u_ba_obuf : OBUF
           port map (
             I => ba_oq(ba_i),
             O => ddr_ba(ba_i)
           );
      end generate;

      gen_ba_nowrlvl : if (not(DRAM_TYPE = "DDR3") or not(WRLVL = "ON")) generate

         attribute IODELAY_GROUP of  u_iodelay_ba : label is IODELAY_GRP;   
      begin   
         u_ba_obuf : OBUF
           port map (
             I => ba_odelay(ba_i),
             O => ddr_ba(ba_i)
           );
                            
         u_iodelay_ba : IODELAYE1
            generic map (
               CINVCTRL_SEL           => FALSE,
               DELAY_SRC              => "O",
               HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
               IDELAY_TYPE            => "FIXED",
               IDELAY_VALUE           => 0,
               ODELAY_TYPE            => "FIXED",
               ODELAY_VALUE           => 0,
               REFCLK_FREQUENCY       => REFCLK_FREQ,
               SIGNAL_PATTERN         => "DATA"
            )
            port map (
               DATAOUT      => ba_odelay(ba_i),
               C            => '0',
               CE           => '0',
               DATAIN       => 'Z',
               IDATAIN      => 'Z',
               INC          => '0',
               ODATAIN      => ba_oq(ba_i),
               RST          => '0',
               T            => 'Z',
               CNTVALUEIN   => "ZZZZZ",
               CNTVALUEOUT  => open,
               CLKIN        => 'Z',
               CINVCTRL     => '0'
            );
      end generate;	     
                                                                       
      u_out_ba : OSERDESE1
         generic map (
            DATA_RATE_OQ    => "DDR",
            DATA_RATE_TQ    => "DDR",
            DATA_WIDTH      => 4,
            DDR3_DATA       => 0, 
            INIT_OQ         => '0',   -- 0 at reset      
            INIT_TQ         => '0',
            INTERFACE_TYPE  => "DEFAULT",
            ODELAY_USED     => 0,
            SERDES_MODE     => "MASTER",
            SRVAL_OQ        => '0',
            SRVAL_TQ        => '0',
            TRISTATE_WIDTH  => 4
         )
         port map (
            OCBEXTEND     => open,
            OFB           => open,
            OQ            => ba_oq(ba_i),
            SHIFTOUT1     => open,
            SHIFTOUT2     => open,
            TQ            => open,
            CLK           => clk_mem,                     
            CLKDIV        => clk,                     
            CLKPERF       => 'Z',
            CLKPERFDELAY  => 'Z',
            D1            => mux_ba0(ba_i),
            D2            => mux_ba0(ba_i),
            D3            => mux_ba1(ba_i),
            D4            => mux_ba1(ba_i),
            D5            => 'Z',
            D6            => 'Z',
            ODV           => '0',
            OCE           => '1',
            SHIFTIN1      => 'Z',
            SHIFTIN2      => 'Z',                     
            RST           => rst_r,
            T1            => '0',
            T2            => '0',
            T3            => '0',
            T4            => '0',
            TFB           => open,
            TCE           => '1',                     
            WC            => '0' 
         );
   end generate;

   --*****************************************************************
   -- ODT control = 0 at reset
   --*****************************************************************      
   gen_odt : for odt_i in 0 to  (CS_WIDTH*nCS_PER_RANK - 1) generate
      gen_odt_wrlvl : if ((DRAM_TYPE = "DDR3") and (WRLVL = "ON")) generate
         u_odt_obuf : OBUF
           port map (
             I => odt_oq(odt_i),
             O => ddr_odt(odt_i)
           );
      end generate;

      gen_odt_nowrlvl : if (not(DRAM_TYPE = "DDR3") or not(WRLVL = "ON")) generate

         attribute IODELAY_GROUP of  u_iodelay_odt : label is IODELAY_GRP;   
      begin   
         u_odt_obuf : OBUF
           port map (
             I => odt_odelay(odt_i),
             O => ddr_odt(odt_i)
           );

         u_iodelay_odt : IODELAYE1
            generic map (
               CINVCTRL_SEL           => FALSE,
               DELAY_SRC              => "O",
               HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
               IDELAY_TYPE            => "FIXED",
               IDELAY_VALUE           => 0,
               ODELAY_TYPE            => "FIXED",
               ODELAY_VALUE           => 0,
               REFCLK_FREQUENCY       => REFCLK_FREQ,
               SIGNAL_PATTERN         => "DATA"
            )
            port map (
               DATAOUT      => odt_odelay(odt_i),
               C            => '0',
               CE           => '0',
               DATAIN       => 'Z',
               IDATAIN      => 'Z',
               INC          => '0',
               ODATAIN      => odt_oq(odt_i),
               RST          => '0',
               T            => 'Z',
               CNTVALUEIN   => "ZZZZZ",
               CNTVALUEOUT  => open,
               CLKIN        => 'Z',
               CINVCTRL     => '0'
            );
      end generate;	     
                                                                       
      u_out_odt : OSERDESE1
         generic map (
            DATA_RATE_OQ    => "DDR",
            DATA_RATE_TQ    => "DDR",
            DATA_WIDTH      => 4,
            DDR3_DATA       => 0, 
            INIT_OQ         => '0',   -- 0 at reset      
            INIT_TQ         => '0',
            INTERFACE_TYPE  => "DEFAULT",
            ODELAY_USED     => 0,
            SERDES_MODE     => "MASTER",
            SRVAL_OQ        => '0',
            SRVAL_TQ        => '0',
            TRISTATE_WIDTH  => 4
         )
         port map (
            OCBEXTEND     => open,
            OFB           => open,
            OQ            => odt_oq(odt_i),
            SHIFTOUT1     => open,
            SHIFTOUT2     => open,
            TQ            => open,
            CLK           => clk_mem,                     
            CLKDIV        => clk,                     
            CLKPERF       => 'Z',
            CLKPERFDELAY  => 'Z',
            D1            => mux_odt0(odt_i),
            D2            => mux_odt0(odt_i),
            D3            => mux_odt1(odt_i),
            D4            => mux_odt1(odt_i),
            D5            => 'Z',
            D6            => 'Z',
            ODV           => '0',
            OCE           => oce_temp,
            -- Connect SHIFTIN1, SHIFTIN2 to 0 for simulation purposes
            -- (for all other OSERDES used in design, these are no-connects):
            -- ensures that ODT outputs are not X at start of simulation
            -- Certain DDR2 memory models may require that CK/CK# be valid
            -- throughout simulation
            SHIFTIN1      => '0',
            SHIFTIN2      => '0',                     
            RST           => rst_cke_odt,
            T1            => '0',
            T2            => '0',
            T3            => '0',
            T4            => '0',
            TFB           => open,
            TCE           => '1',                     
            WC            => '0' 
         );
   end generate;

   --*********************************************************************
   -- Parity for reg dimm. Parity output one cycle after the cs assertion     
   --*********************************************************************   
   gen_parity_wrlvl : if ((DRAM_TYPE = "DDR3") and (WRLVL = "ON")) generate

      u_parity_obuf : OBUF
        port map (
          I => parity_oq,
          O => ddr_parity
        );

   end generate;

   gen_parity_nowrlvl : if (not(DRAM_TYPE = "DDR3") or not(WRLVL = "ON")) generate

      attribute IODELAY_GROUP of  u_iodelay_parity : label is IODELAY_GRP;   
   begin   
      u_parity_obuf : OBUF
        port map (
          I => parity_odelay,
          O => ddr_parity
        );

      u_iodelay_parity : IODELAYE1
         generic map (
            CINVCTRL_SEL           => FALSE,
            DELAY_SRC              => "O",
            HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
            IDELAY_TYPE            => "FIXED",
            IDELAY_VALUE           => 0,
            ODELAY_TYPE            => "FIXED",
            ODELAY_VALUE           => 0,
            REFCLK_FREQUENCY       => REFCLK_FREQ,
            SIGNAL_PATTERN         => "DATA"
         )
         port map (
            DATAOUT      => parity_odelay,
            C            => '0',
            CE           => '0',
            DATAIN       => 'Z',
            IDATAIN      => 'Z',
            INC          => '0',
            ODATAIN      => parity_oq,
            RST          => '0',
            T            => 'Z',
            CNTVALUEIN   => "ZZZZZ",
            CNTVALUEOUT  => open,
            CLKIN        => 'Z',
            CINVCTRL     => '0'
         );
   end generate;	     
                                                                    
   u_out_parity : OSERDESE1
      generic map (
         DATA_RATE_OQ    => "DDR",
         DATA_RATE_TQ    => "DDR",
         DATA_WIDTH      => 4,
         DDR3_DATA       => 0, 
         INIT_OQ         => '1',   -- 1 at reset      
         INIT_TQ         => '0',
         INTERFACE_TYPE  => "DEFAULT",
         ODELAY_USED     => 0,
         SERDES_MODE     => "MASTER",
         SRVAL_OQ        => '0',
         SRVAL_TQ        => '0',
         TRISTATE_WIDTH  => 4
      )
      port map (
         OCBEXTEND     => open,
         OFB           => open,
         OQ            => parity_oq,
         SHIFTOUT1     => open,
         SHIFTOUT2     => open,
         TQ            => open,
         CLK           => clk_mem,                     
         CLKDIV        => clk,                     
         CLKPERF       => 'Z',
         CLKPERFDELAY  => 'Z',
         D1            => parity1,
         D2            => parity1,
         D3            => parity0,
         D4            => parity0,
         D5            => 'Z',
         D6            => 'Z',
         ODV           => '0',
         OCE           => '1',
         SHIFTIN1      => 'Z',
         SHIFTIN2      => 'Z',                    
         RST           => rst_r,
         T1            => '0',
         T2            => '0',
         T3            => '0',
         T4            => '0',
         TFB           => open,
         TCE           => '1',                     
         WC            => '0' 
      );
   
end arch_phy_control_io;


