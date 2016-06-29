library IEEE;
use IEEE.STD_LOGIC_1164.all;
package VCOMPONENTS is

-----------------------------------------
-----------   FPGA Globals --------------
-----------------------------------------
signal GSR : std_logic := '0';
signal GTS : std_logic := '0';
signal GWE : std_logic;
signal PLL_LOCKG : std_logic := 'H';
signal PROGB_GLBL : std_logic;
signal CCLKO_GLBL : std_logic;

-----------------------------------------
-----------   CPLD Globals --------------
-----------------------------------------
signal PRLD : std_logic := '0';

----- component BUFG -----
component BUFG
  port (
     O : out std_ulogic;
     I : in std_ulogic
  );
end component;

----- component OBUF -----
component OBUF
  generic (
     CAPACITANCE : string := "DONT_CARE";
     DRIVE : integer := 12;
     IOSTANDARD : string := "DEFAULT";
     SLEW : string := "SLOW"
  );
  port (
     O : out std_ulogic;
     I : in std_ulogic
  );
end component;

----- component OBUFDS -----
component OBUFDS
  generic (
     CAPACITANCE : string := "DONT_CARE";
     IOSTANDARD : string := "DEFAULT";
     SLEW : string := "SLOW"
  );
  port (
     O : out std_ulogic;
     OB : out std_ulogic;
     I : in std_ulogic
  );
end component;


----- component IBUFGDS -----
component IBUFGDS
  generic (
     CAPACITANCE : string := "DONT_CARE";
     DIFF_TERM : boolean := FALSE;
     IBUF_DELAY_VALUE : string := "0";
     IBUF_LOW_PWR : boolean := TRUE;
     IOSTANDARD : string := "DEFAULT"
  );
  port (
     O : out std_ulogic;
     I : in std_ulogic;
     IB : in std_ulogic
  );
end component;

----- component BUFIO -----
component BUFIO
  port (
     O : out std_ulogic;
     I : in std_ulogic
  );
end component;

----- component IOBUF -----
component IOBUF
  generic (
     CAPACITANCE : string := "DONT_CARE";
     DRIVE : integer := 12;
     IBUF_DELAY_VALUE : string := "0";
     IBUF_LOW_PWR : boolean := TRUE;
     IFD_DELAY_VALUE : string := "AUTO";
     IOSTANDARD : string := "DEFAULT";
     SLEW : string := "SLOW"
  );
  port (
     O : out std_ulogic;
     IO : inout std_ulogic;
     I : in std_ulogic;
     T : in std_ulogic
  );
end component;



----- component IOBUFDS_DIFF_OUT -----
component IOBUFDS_DIFF_OUT
  generic (
     DIFF_TERM : boolean := FALSE;
     IBUF_LOW_PWR : boolean := TRUE;
     IOSTANDARD : string := "DEFAULT"
  );
  port (
     O : out std_ulogic;
     OB : out std_ulogic;
     IO : inout std_ulogic;
     IOB : inout std_ulogic;
     I : in std_ulogic;
     TM : in std_ulogic;
     TS : in std_ulogic
  );
end component;

----- component BUFR -----
component BUFR
  generic (
     BUFR_DIVIDE : string := "BYPASS";
     SIM_DEVICE : string := "VIRTEX4"
  );
  port (
     O : out std_ulogic;
     CE : in std_ulogic;
     CLR : in std_ulogic;
     I : in std_ulogic
  );
end component;

----- component MMCM_ADV -----
component MMCM_ADV
  generic (
     BANDWIDTH : string := "OPTIMIZED";
     CLKFBOUT_MULT_F : real := 5.000;
     CLKFBOUT_PHASE : real := 0.000;
     CLKFBOUT_USE_FINE_PS : boolean := FALSE;
     CLKIN1_PERIOD : real := 0.000;
     CLKIN2_PERIOD : real := 0.000;
     CLKOUT0_DIVIDE_F : real := 1.000;
     CLKOUT0_DUTY_CYCLE : real := 0.500;
     CLKOUT0_PHASE : real := 0.000;
     CLKOUT0_USE_FINE_PS : boolean := FALSE;
     CLKOUT1_DIVIDE : integer := 1;
     CLKOUT1_DUTY_CYCLE : real := 0.500;
     CLKOUT1_PHASE : real := 0.000;
     CLKOUT1_USE_FINE_PS : boolean := FALSE;
     CLKOUT2_DIVIDE : integer := 1;
     CLKOUT2_DUTY_CYCLE : real := 0.500;
     CLKOUT2_PHASE : real := 0.000;
     CLKOUT2_USE_FINE_PS : boolean := FALSE;
     CLKOUT3_DIVIDE : integer := 1;
     CLKOUT3_DUTY_CYCLE : real := 0.500;
     CLKOUT3_PHASE : real := 0.000;
     CLKOUT3_USE_FINE_PS : boolean := FALSE;
     CLKOUT4_CASCADE : boolean := FALSE;
     CLKOUT4_DIVIDE : integer := 1;
     CLKOUT4_DUTY_CYCLE : real := 0.500;
     CLKOUT4_PHASE : real := 0.000;
     CLKOUT4_USE_FINE_PS : boolean := FALSE;
     CLKOUT5_DIVIDE : integer := 1;
     CLKOUT5_DUTY_CYCLE : real := 0.500;
     CLKOUT5_PHASE : real := 0.000;
     CLKOUT5_USE_FINE_PS : boolean := FALSE;
     CLKOUT6_DIVIDE : integer := 1;
     CLKOUT6_DUTY_CYCLE : real := 0.500;
     CLKOUT6_PHASE : real := 0.000;
     CLKOUT6_USE_FINE_PS : boolean := FALSE;
     CLOCK_HOLD : boolean := FALSE;
     COMPENSATION : string := "ZHOLD";
     DIVCLK_DIVIDE : integer := 1;
     REF_JITTER1 : real := 0.0;
     REF_JITTER2 : real := 0.0;
     STARTUP_WAIT : boolean := FALSE
  );
  port (
     CLKFBOUT : out std_ulogic := '0';
     CLKFBOUTB : out std_ulogic := '0';
     CLKFBSTOPPED : out std_ulogic := '0';
     CLKINSTOPPED : out std_ulogic := '0';
     CLKOUT0 : out std_ulogic := '0';
     CLKOUT0B : out std_ulogic := '0';
     CLKOUT1 : out std_ulogic := '0';
     CLKOUT1B : out std_ulogic := '0';
     CLKOUT2 : out std_ulogic := '0';
     CLKOUT2B : out std_ulogic := '0';
     CLKOUT3 : out std_ulogic := '0';
     CLKOUT3B : out std_ulogic := '0';
     CLKOUT4 : out std_ulogic := '0';
     CLKOUT5 : out std_ulogic := '0';
     CLKOUT6 : out std_ulogic := '0';
     DO : out std_logic_vector (15 downto 0);
     DRDY : out std_ulogic := '0';
     LOCKED : out std_ulogic := '0';
     PSDONE : out std_ulogic := '0';
     CLKFBIN : in std_ulogic;
     CLKIN1 : in std_ulogic;
     CLKIN2 : in std_ulogic;
     CLKINSEL : in std_ulogic;
     DADDR : in std_logic_vector(6 downto 0);
     DCLK : in std_ulogic;
     DEN : in std_ulogic;
     DI : in std_logic_vector(15 downto 0);
     DWE : in std_ulogic;
     PSCLK : in std_ulogic;
     PSEN : in std_ulogic;
     PSINCDEC : in std_ulogic;
     PWRDWN : in std_ulogic;
     RST : in std_ulogic
  );
end component;

----- component IDELAYCTRL -----
component IDELAYCTRL
  port (
     RDY : out std_ulogic;
     REFCLK : in std_ulogic;
     RST : in std_ulogic
  );
end component;

----- component IODELAYE1 -----
component IODELAYE1
  generic (
     CINVCTRL_SEL : boolean := FALSE;
     DELAY_SRC : string := "I";
     HIGH_PERFORMANCE_MODE : boolean := FALSE;
     IDELAY_TYPE : string := "DEFAULT";
     IDELAY_VALUE : integer := 0;
     ODELAY_TYPE : string := "FIXED";
     ODELAY_VALUE : integer := 0;
     REFCLK_FREQUENCY : real := 200.0;
     SIGNAL_PATTERN : string := "DATA"
  );
  port (
     CNTVALUEOUT : out std_logic_vector(4 downto 0);
     DATAOUT : out std_ulogic;
     C : in std_ulogic;
     CE : in std_ulogic;
     CINVCTRL : in std_ulogic;
     CLKIN : in std_ulogic;
     CNTVALUEIN : in std_logic_vector(4 downto 0);
     DATAIN : in std_ulogic;
     IDATAIN : in std_ulogic;
     INC : in std_ulogic;
     ODATAIN : in std_ulogic;
     RST : in std_ulogic;
     T : in std_ulogic
  );
end component;

----- component RAM32M -----
component RAM32M
  generic (
     INIT_A : bit_vector(63 downto 0) := X"0000000000000000";
     INIT_B : bit_vector(63 downto 0) := X"0000000000000000";
     INIT_C : bit_vector(63 downto 0) := X"0000000000000000";
     INIT_D : bit_vector(63 downto 0) := X"0000000000000000"
  );
  port (
     DOA : out std_logic_vector (1 downto 0);
     DOB : out std_logic_vector (1 downto 0);
     DOC : out std_logic_vector (1 downto 0);
     DOD : out std_logic_vector (1 downto 0);
     ADDRA : in std_logic_vector(4 downto 0);
     ADDRB : in std_logic_vector(4 downto 0);
     ADDRC : in std_logic_vector(4 downto 0);
     ADDRD : in std_logic_vector(4 downto 0);
     DIA : in std_logic_vector (1 downto 0);
     DIB : in std_logic_vector (1 downto 0);
     DIC : in std_logic_vector (1 downto 0);
     DID : in std_logic_vector (1 downto 0);
     WCLK : in std_ulogic;
     WE : in std_ulogic
  );
end component;


----- component RAM64X1D -----
component RAM64X1D
  generic (
     INIT : bit_vector(63 downto 0) := X"0000000000000000"
  );
  port (
     DPO : out std_ulogic;
     SPO : out std_ulogic;
     A0 : in std_ulogic;
     A1 : in std_ulogic;
     A2 : in std_ulogic;
     A3 : in std_ulogic;
     A4 : in std_ulogic;
     A5 : in std_ulogic;
     D : in std_ulogic;
     DPRA0 : in std_ulogic;
     DPRA1 : in std_ulogic;
     DPRA2 : in std_ulogic;
     DPRA3 : in std_ulogic;
     DPRA4 : in std_ulogic;
     DPRA5 : in std_ulogic;
     WCLK : in std_ulogic;
     WE : in std_ulogic
  );
end component;

----- component ISERDESE1 -----
component ISERDESE1
  generic (
     DATA_RATE : string := "DDR";
     DATA_WIDTH : integer := 4;
     DYN_CLKDIV_INV_EN : boolean := FALSE;
     DYN_CLK_INV_EN : boolean := FALSE;
     INIT_Q1 : bit := '0';
     INIT_Q2 : bit := '0';
     INIT_Q3 : bit := '0';
     INIT_Q4 : bit := '0';
     INTERFACE_TYPE : string := "MEMORY";
     IOBDELAY : string := "NONE";
     NUM_CE : integer := 2;
     OFB_USED : boolean := FALSE;
     SERDES_MODE : string := "MASTER";
     SRVAL_Q1 : bit := '0';
     SRVAL_Q2 : bit := '0';
     SRVAL_Q3 : bit := '0';
     SRVAL_Q4 : bit := '0'
  );
  port (
     O : out std_ulogic;
     Q1 : out std_ulogic;
     Q2 : out std_ulogic;
     Q3 : out std_ulogic;
     Q4 : out std_ulogic;
     Q5 : out std_ulogic;
     Q6 : out std_ulogic;
     SHIFTOUT1 : out std_ulogic;
     SHIFTOUT2 : out std_ulogic;
     BITSLIP : in std_ulogic;
     CE1 : in std_ulogic;
     CE2 : in std_ulogic;
     CLK : in std_ulogic;
     CLKB : in std_ulogic;
     CLKDIV : in std_ulogic;
     D : in std_ulogic;
     DDLY : in std_ulogic;
     DYNCLKDIVSEL : in std_ulogic;
     DYNCLKSEL : in std_ulogic;
     OCLK : in std_ulogic;
     OFB : in std_ulogic;
     RST : in std_ulogic;
     SHIFTIN1 : in std_ulogic;
     SHIFTIN2 : in std_ulogic
  );
end component;

----- component OSERDESE1 -----
component OSERDESE1
  generic (
     DATA_RATE_OQ : string := "DDR";
     DATA_RATE_TQ : string := "DDR";
     DATA_WIDTH : integer := 4;
     DDR3_DATA : integer := 1;
     INIT_OQ : bit := '0';
     INIT_TQ : bit := '0';
     INTERFACE_TYPE : string := "DEFAULT";
     ODELAY_USED : integer := 0;
     SERDES_MODE : string := "MASTER";
     SRVAL_OQ : bit := '0';
     SRVAL_TQ : bit := '0';
     TRISTATE_WIDTH : integer := 4
  );
  port (
     OCBEXTEND : out std_ulogic;
     OFB : out std_ulogic;
     OQ : out std_ulogic;
     SHIFTOUT1 : out std_ulogic;
     SHIFTOUT2 : out std_ulogic;
     TFB : out std_ulogic;
     TQ : out std_ulogic;
     CLK : in std_ulogic;
     CLKDIV : in std_ulogic;
     CLKPERF : in std_ulogic;
     CLKPERFDELAY : in std_ulogic;
     D1 : in std_ulogic;
     D2 : in std_ulogic;
     D3 : in std_ulogic;
     D4 : in std_ulogic;
     D5 : in std_ulogic;
     D6 : in std_ulogic;
     OCE : in std_ulogic;
     ODV : in std_ulogic;
     RST : in std_ulogic;
     SHIFTIN1 : in std_ulogic;
     SHIFTIN2 : in std_ulogic;
     T1 : in std_ulogic;
     T2 : in std_ulogic;
     T3 : in std_ulogic;
     T4 : in std_ulogic;
     TCE : in std_ulogic;
     WC : in std_ulogic
  );
end component;

----- component ODDR -----
component ODDR
  generic (
     DDR_CLK_EDGE : string := "OPPOSITE_EDGE";
     INIT : bit := '0';
     SRTYPE : string := "SYNC"
  );
  port (
     Q : out std_ulogic;
     C : in std_ulogic;
     CE : in std_ulogic;
     D1 : in std_ulogic;
     D2 : in std_ulogic;
     R : in std_ulogic := 'L';
     S : in std_ulogic := 'L'
  );
end component;

----- component FDRE -----
component FDRE
  generic (
     INIT : bit := '0'
  );
  port (
     Q : out std_ulogic;
     C : in std_ulogic;
     CE : in std_ulogic;
     D : in std_ulogic;
     R : in std_ulogic
  );
end component;

----- component FDSE -----
component FDSE
  generic (
     INIT : bit := '1'
  );
  port (
     Q : out std_ulogic;
     C : in std_ulogic;
     CE : in std_ulogic;
     D : in std_ulogic;
     S : in std_ulogic
  );
end component;


----- component FDRSE -----
component FDRSE
  generic (
     INIT : bit := '0'
  );
  port (
     Q : out std_ulogic;
     C : in std_ulogic;
     CE : in std_ulogic;
     D : in std_ulogic;
     R : in std_ulogic;
     S : in std_ulogic
  );
end component;

----- component SRLC32E -----
component SRLC32E
  generic (
     INIT : bit_vector := X"00000000"
  );
  port (
     Q : out STD_ULOGIC;
     Q31 : out STD_ULOGIC;
     A : in STD_LOGIC_VECTOR (4 downto 0);
     CE : in STD_ULOGIC;
     CLK : in STD_ULOGIC;
     D : in STD_ULOGIC
  );
end component;

----- component AND2B1L -----
component AND2B1L
  port (
     O : out std_ulogic;
     DI : in std_ulogic;
     SRI : in std_ulogic
  );
end component;

----- component MUXCY -----
component MUXCY
  port (
     O : out std_ulogic;
     CI : in std_ulogic;
     DI : in std_ulogic;
     S : in std_ulogic
  );
end component;

----- component OR2L -----
component OR2L
  port (
     O : out std_ulogic;
     DI : in std_ulogic;
     SRI : in std_ulogic
  );
end component;


----- component XORCY -----
component XORCY
  port (
     O : out std_ulogic;
     CI : in std_ulogic;
     LI : in std_ulogic
  );
end component;

----- component LUT4 -----
component LUT4
  generic (
     INIT : bit_vector := X"0000"
  );
  port (
     O : out std_ulogic;
     I0 : in std_ulogic;
     I1 : in std_ulogic;
     I2 : in std_ulogic;
     I3 : in std_ulogic
  );
end component;

----- component LUT6 -----
component LUT6
  generic (
     INIT : bit_vector := X"0000000000000000"
  );
  port (
     O : out std_ulogic;
     I0 : in std_ulogic;
     I1 : in std_ulogic;
     I2 : in std_ulogic;
     I3 : in std_ulogic;
     I4 : in std_ulogic;
     I5 : in std_ulogic
  );
end component;

----- component LUT6_2 -----
component LUT6_2
  generic (
     INIT : bit_vector := X"0000000000000000"
  );
  port (
     O5 : out std_ulogic;
     O6 : out std_ulogic;
     I0 : in std_ulogic;
     I1 : in std_ulogic;
     I2 : in std_ulogic;
     I3 : in std_ulogic;
     I4 : in std_ulogic;
     I5 : in std_ulogic
  );
end component;


-- END COMPONENT

end VCOMPONENTS;
