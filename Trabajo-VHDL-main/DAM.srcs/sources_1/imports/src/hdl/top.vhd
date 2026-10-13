
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DAM is
   port(
      CLK          : in  std_logic;
      rstn_i       : in std_logic;
      btnc_i         : in  std_logic;
      -- leds
      LED            : out std_logic;

      -- VGA display
      vga_hs_o       : out std_logic;
      vga_vs_o       : out std_logic;
      vga_red_o      : out std_logic_vector(3 downto 0);
      vga_blue_o     : out std_logic_vector(3 downto 0);
      vga_green_o    : out std_logic_vector(3 downto 0);
      -- PDM microphone
      sck_mic      : buffer std_logic;
      miso_mic     : in  std_logic;
      cs_mic: BUFFER std_logic_vector (0 downto 0);
      -- sd microphone
      rx : in std_logic;
      tx : out std_logic;
      LED_1 : out std_logic
      
      
   );
end DAM;

architecture Behavioral of DAM is

----------------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------------  



component RgbLed is
port(
   CLK            : in  std_logic;
   rstn_i         : in std_logic;
   red_out        : out std_logic_vector (7 downto 0);
   green_out      : out std_logic_vector (7 downto 0);
   blue_out       : out std_logic_vector (7 downto 0);
   aciertos_rgb   : in std_logic;
   fallos_rgb     : in std_logic;
   aciertos_fin   : in integer;
   fallos_fin     : in integer
   );
end component;

COMPONENT Comparador is
  Port (CLK: in std_logic;
        rst: in std_logic;
        cs_mic: BUFFER std_logic_vector (0 downto 0);
        sck_mic:BUFFER std_logic ;
        miso_mic: in std_logic;
        LED: out std_logic;
        sd_data : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0);
        mic_data : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0);
        aciertos_com : in std_logic;
        fallos_com : in std_logic;
        rx : in std_logic;
        tx : out std_logic;
        LED_1 : out std_logic;
        rx_event : buffer std_logic
         );
end component;

COMPONENT Vga is
PORT( 
   CLK          : in  std_logic;
   vga_hs_o       : out std_logic;
   vga_vs_o       : out std_logic;
   vga_red_o      : out std_logic_vector(3 downto 0);
   vga_blue_o     : out std_logic_vector(3 downto 0);
   vga_green_o    : out std_logic_vector(3 downto 0);
   RGB_LED_RED    : in STD_LOGIC_VECTOR (7 downto 0);
   RGB_LED_GREEN  : in STD_LOGIC_VECTOR (7 downto 0);
   RGB_LED_BLUE   : in STD_LOGIC_VECTOR (7 downto 0);
   MIC_M_DATA_I   : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
   MIC_M_CLK_RISING  : buffer STD_LOGIC;
   MIC_M_DATA_SD   : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
   MIC_M_CLK_RISING_SD  : buffer STD_LOGIC;
   aciertos_vga : in integer;
   fallos_vga : in integer
   
   );
END COMPONENT;

----------------------------------------------------------------------------------
-- Signal Declarations
----------------------------------------------------------------------------------  
-- Inverted input reset signal
signal rst        : std_logic;
-- Reset signal conditioned by the PLL lock
signal reset      : std_logic;
signal resetn     : std_logic;
signal locked     : std_logic;

signal aciertos : std_logic;
signal fallos : std_logic;

signal aciertos_calc : integer;
signal fallos_calc : integer;

signal sd_data_aux : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal mic_data_aux : STD_LOGIC_VECTOR(15 DOWNTO 0);

-- Progressbar signal when recording
signal led_audio  : std_logic_vector(15 downto 0);

-- RGB LED signals
signal rgb_led_red: std_logic_vector (7 downto 0);
signal rgb_led_green: std_logic_vector (7 downto 0);
signal rgb_led_blue: std_logic_vector (7 downto 0);


-- pdm_clk and pdm_clk_rising are needed by the VGA controller
-- to display incoming microphone data
signal pdm_clk : std_logic;
signal pdm_clk_rising : std_logic;
signal rx_event : std_logic;


begin

   -- The Reset Button on the Nexys4 board is active-low,
   -- however many components need an active-high reset
   rst <= not rstn_i;

   -- Assign reset signals conditioned by the PLL lock
   reset <= rst or (not locked);
   -- active-low version of the reset signal
   resetn <= not reset;


   -- Assign pdm_clk output
  -- sck_mic <= pdm_clk;
   --sck_sd <= pdm_clk;


----------------------------------------------------------------------------------
-- Rgb Led Controller
----------------------------------------------------------------------------------    
   Inst_RGB: RgbLed
   port map(
      CLK          => CLK,
      rstn_i      => resetn,
      RED_OUT        => rgb_led_red,
      GREEN_OUT      => rgb_led_green,
      BLUE_OUT       => rgb_led_blue,
      aciertos_rgb => aciertos,
      fallos_rgb => fallos,
      aciertos_fin => aciertos_calc,
      fallos_fin => fallos_calc
      );


----------------------------------------------------------------------------------
-- VGA Controller
----------------------------------------------------------------------------------
   Inst_VGA: Vga
   port map(
      CLK          => CLK,
      vga_hs_o       => vga_hs_o,
      vga_vs_o       => vga_vs_o,
      vga_red_o      => vga_red_o,
      vga_blue_o     => vga_blue_o,
      vga_green_o    => vga_green_o,
      RGB_LED_RED    => rgb_led_red,
      RGB_LED_GREEN  => rgb_led_green,
      RGB_LED_BLUE   => rgb_led_blue,
      MIC_M_DATA_I   => mic_data_aux,
      MIC_M_CLK_RISING => sck_mic,
      MIC_M_DATA_SD   => sd_data_aux,
      MIC_M_CLK_RISING_SD => rx_event,
      aciertos_vga => aciertos_calc,
      fallos_vga => fallos_calc
      ); 
       
  Inst_Comparador: Comparador
  Port map(CLK => CLK,
        rst => btnc_i,
        cs_mic => cs_mic,
        sck_mic => sck_mic,
        miso_mic => miso_mic,
        LED => LED,
        sd_data => sd_data_aux,
        mic_data => mic_data_aux,
        aciertos_com => aciertos,
        fallos_com => fallos,
        rx => rx,
        tx => tx,
        LED_1 => LED_1,
        rx_event => rx_event
        );
end Behavioral;
