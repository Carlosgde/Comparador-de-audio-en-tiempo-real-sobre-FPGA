library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity RgbLed is
   port(
      CLK : in std_logic;
      rstn_i : in std_logic;
      -- R, G and B signals connecting to the VGA controller
      -- to be displayed on the screen
      RED_OUT : out std_logic_vector(7 downto 0);
      GREEN_OUT : out std_logic_vector(7 downto 0);
      BLUE_OUT : out std_logic_vector(7 downto 0);
      aciertos_rgb   : in std_logic;
      fallos_rgb     : in std_logic;
      aciertos_fin   : in integer;
      fallos_fin     : in integer
   );
end RgbLed;

architecture Behavioral of RgbLed is

----------------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------------

-- Clock divider, will determine the frequency at which
-- the color components will increase/decrease
-- 100MHz/10000000 = 10Hz
constant CLK_DIV : integer := 10000000;
--Clock divider counter and signal
signal clkCnt : integer := 0;
signal slowClk : std_logic;

-- colorCnt will determine the PWM values to be sent to the RGB Led color components
-- colorCnt(9 downto 5) will be increasing and colorCnt(4 downto 0) will be decreasing
signal colorCnt : std_logic_vector(9 downto 0) := "0000011111";
-- specCnt determines which color components are swept
-- 0: decrease Red, increase Green
-- 1: decrease Green, increase Blue
-- 2: decrease Blue, increase Red
signal specCnt : integer range 0 to 2 := 0;

-- Red, Green and Blue data signals
signal red, green, blue : std_logic_vector(7 downto 0);
-- PWM Red, Green and BLue signals going to the RGB Leds;

-- State machine states definition
type state_type is (stIdle,   -- Both Leds are on, show sweeping color
                     stRed,   -- Show Red color only
                     stGreen, -- Show Green color only
                     stBlue  -- Show Blue color only
                     ); 
-- State machine signal definitions
signal state, nState : state_type;


begin
   

   RegisterOutputs: process(CLK, red, green, blue)
   begin
      if rising_edge(CLK) then
         RED_OUT  <= red;
         GREEN_OUT <= green;
         BLUE_OUT  <= blue;
      end if;
   end process RegisterOutputs;
   
   -- State machine registerred process
   SYNC_PROC: process(CLK)
   begin
      if rising_edge(CLK) then
         if rstn_i = '0' then
            state <= stIdle;
         else
            state <= nState;
         end if;        
      end if;
   end process;
   
   -- Next State decode process
   NEXT_STATE_DECODE: process(state)
   begin
 -- Default: Stay in the current state
         nState <= stIdle;      
   end process;
   
-- clock prescaler
   Prescaller: process(CLK)
   begin
      if rising_edge(CLK) then
         if rstn_i = '0' then
            clkCnt <= 0;
         elsif clkCnt = CLK_DIV-1 then
            clkCnt <= 0;
         else
            clkCnt <= clkCnt + 1;
         end if;
      end if;
   end process Prescaller;
   
   slowClk <= '1' when clkCnt = CLK_DIV-1 else '0';
      
   process(CLK)
   begin
      if rising_edge(CLK) then
         if rstn_i = '0' then
            colorCnt <= b"0000011111";
            specCnt <= 0;
         elsif slowClk = '1' then
            if colorCnt = b"1111000001" then -- at the end of the color sweeping, 
               colorCnt <= b"0000011111";    -- start over and change the colors which are swept
               if specCnt = 2 then 
                  specCnt <= 0;
               else
                  specCnt <= specCnt + 1;
               end if;
            else -- colorCnt (9 downto 5) will be increasing 
                 -- and colorCnt(4 downto 0) will be decreasing
               colorCnt <= colorCnt + b"0000011111";
            end if;
         end if;
      end if;
   end process;
   
   process(state, colorCnt, specCnt)
   begin
         case specCnt is 
            when 0 =>
               red   <= b"000" & colorCnt(4 downto 0); -- Decrease Red, increase Green
               green <= b"000" & colorCnt(9 downto 5);
               blue  <= b"0000" & b"0000";
            when 1 => 
               red   <= b"0000" & b"0000"; 
               green <= b"000" & colorCnt(4 downto 0); -- Decrease Green, increase Blue
               blue  <= b"000" & colorCnt(9 downto 5);
            when 2 => 
               red   <= b"000" & colorCnt(9 downto 5); -- Decrease Blue, increase Red
               green <= b"0000" & b"0000"; 
               blue  <= b"000" & colorCnt(4 downto 0);
            when others => 
               red   <= b"0000" & b"0000"; 
               green <= b"0000" & b"0000"; 
               blue  <= b"0000" & b"0000"; 
         end case;
   end process;
   
end Behavioral;

