----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.05.2025 12:55:39
-- Design Name: 
-- Module Name: Comparador - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_1164.numeric_std;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Comparador is
  Port (CLK: in std_logic;
        rst: in std_logic;
        cs_mic: BUFFER std_logic_vector (0 downto 0);
        sck_mic:BUFFER std_logic ;
        miso_mic: in std_logic;
        LED: out std_logic;
        sd_data : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0);
        mic_data : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0);
        aciertos_com : out std_logic;
        fallos_com : out std_logic;
        rx : in std_logic;
        tx : out std_logic;
        LED_1 : out std_logic;
        rx_event : buffer std_logic
         );
end Comparador;

architecture Behavioral of Comparador is
    component SPI_master
        GENERIC(
        slaves  : INTEGER := 1;  --number of spi slaves
        d_width : INTEGER := 16); --data bus width
        PORT(
        clock   : IN     STD_LOGIC;                             --system clock
        reset_n : IN     STD_LOGIC;                             --asynchronous reset
        enable  : IN     STD_LOGIC;                             --initiate transaction
        cpol    : IN     STD_LOGIC;                             --spi clock polarity
        cpha    : IN     STD_LOGIC;                             --spi clock phase
        cont    : IN     STD_LOGIC;                             --continuous mode command
        clk_div : IN     INTEGER;                               --system clock cycles per 1/2 period of sclk
        addr    : IN     INTEGER;                               --address of slave
        tx_data : IN     STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --data to transmit
        miso    : IN     STD_LOGIC;                             --master in, slave out
        sclk    : BUFFER STD_LOGIC;                             --spi clock
        ss_n    : BUFFER STD_LOGIC_VECTOR(slaves-1 DOWNTO 0);   --slave select
        mosi    : OUT    STD_LOGIC;                             --master out, slave in
        busy    : OUT    STD_LOGIC;                             --busy / data ready signal
        rx_data : OUT    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --data received );
        rdy: OUT STD_LOGIC
        
        );
    end component;
    for all: SPI_master use entity work.spi_master(logic);
    
    component UART
     GENERIC (
        BAUD_CYCLES : integer := 869
    );
    PORT (
        clk         : IN STD_LOGIC;
        data_in     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        tx_send     : IN STD_LOGIC;
        tx_reset    : IN STD_LOGIC;
        rx          : IN STD_LOGIC;
                
        tx          : OUT STD_LOGIC;
        data_recv   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); 
        
        tx_event    : OUT STD_LOGIC;
        rx_event    : buffer STD_LOGIC
    );
    end component;
    
   for all: UART use entity work.UART(RTL);

    signal data_sd_par: std_logic_vector (7 downto 0);
    signal data_mic: std_logic_vector (15 downto 0);
    signal mosi_mic_l: std_logic_vector (15 downto 0);
    signal garbage:std_logic ;
    signal busy_sd: std_logic:='0';
    signal busy_mic: std_logic:= '0';
    signal rst_bttn: std_logic:= not rst; 
    
    signal rdy_mic: std_logic; 
    signal rdy_sd: std_logic; 
    
    signal enable: std_logic;
    
    constant THRESHOLD : integer := 300; --umbral de error
    signal diff : integer := 0;
    
    signal data_in_uart : std_logic_vector(7 DOWNTO 0);
    signal rx_uart : std_logic;
    constant cabecera : std_logic_vector(7 downto 0):= "10101010";
    constant tail : std_logic_vector(7 downto 0):= "10011001";
    signal data_rx_cont : std_logic_vector( 15 downto 0);
    signal data_rx_cont_ok : std_logic_vector( 15 downto 0);
    signal data_rx_ok_event : std_logic := '0';

    
    
begin
    Inst_mic_auds: SPI_master
        port map(
            clock => CLK,
            reset_n => rst_bttn,
            enable => '1',
            cpol => '0',
            cpha => '1',
            cont => '0',
            clk_div => 8,
            addr => 0,
            tx_data => mosi_mic_l,
            miso => miso_mic,
            sclk => sck_mic,
            ss_n => cs_mic,
            mosi => garbage,
            busy => busy_mic,
            rx_data => data_mic,
            rdy => rdy_mic
        );
    
    Inst_uart_sd: UART 
        port map(
            clk => CLK,
            data_in => data_in_uart,
            tx_send => '0',
            tx_reset => rst,
            rx => rx,
            tx => tx,
            data_recv => data_sd_par,
            tx_event => open,
            rx_event => rx_event
        );
        
        
    
process(rx_event, rst)
    variable id_iterator : std_logic_vector (1 downto 0) := "00";
begin
    if rst = '1' then
        id_iterator := "00";
        data_rx_ok_event <= '0';
    elsif rising_edge(rx_event) then
        data_rx_ok_event <= '0';  -- Por defecto

        case id_iterator is
            when "00" =>
                if data_sd_par = cabecera then
                    id_iterator := "01";
                else
                    id_iterator := "00";
                end if;

            when "01" =>
                data_rx_cont(7 downto 0) <= data_sd_par;
                id_iterator := "10";

            when "10" =>
                data_rx_cont(15 downto 8) <= data_sd_par;
                id_iterator := "11";

            when "11" =>
                if data_sd_par = tail then
                    data_rx_ok_event <= '1';
                    data_rx_cont_ok <= data_rx_cont;
                end if;
                id_iterator := "00";  -- Reiniciar tras trama
        end case;
    end if;
end process;
    
     process(CLK, rst_bttn)
        variable temp_diff : integer;
    begin
        if rst_bttn = '0' then
            LED <= '0';
            LED_1 <= '0';
            diff <= 0;
        
            
        elsif rising_edge(CLK) then
            if rdy_mic = '1' then
                mic_data <= data_mic;
                sd_data <= data_rx_cont_ok;
                if(data_rx_ok_event = '1') then
                    LED_1 <= '1';
                end if;
                -- Comparar solo una muestra (ejemplo: bit 15 downto 0)
                temp_diff := to_integer(signed(data_rx_cont_ok(11 downto 0))) - to_integer(signed(data_mic(11 downto 0)));
                diff <= abs(temp_diff);
                if diff < THRESHOLD then
                    LED <= '1';  -- Se consideran iguales
                    aciertos_com <= '1';
                    fallos_com <= '0';
                else
                    LED <= '0';  -- Diferencia significativa
                    fallos_com <= '1';
                    aciertos_com <= '0';
                end if;
            else
                LED <= '0';  -- SPI a�n ocupado
            end if;
        end if;
    end process;
   
end Behavioral;