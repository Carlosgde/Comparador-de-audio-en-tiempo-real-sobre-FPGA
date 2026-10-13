LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY UART IS
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
END UART;

ARCHITECTURE RTL OF UART IS
    SIGNAL div_clk          : STD_LOGIC := '0';   
    SIGNAL tx_buffer_data   : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL rx_buffer_data : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS=>'0');
    SIGNAL rx_out_data : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS=>'0');
    
BEGIN
    tx_buffer_data <= '1' & data_in & '0';
    data_recv <= rx_out_data;
   
    baud_clk_divider        : PROCESS(clk)
    VARIABLE baud_current : integer RANGE 0 TO BAUD_CYCLES := 0;
    BEGIN
        IF rising_edge(clk) THEN
            IF baud_current < (BAUD_CYCLES-1) THEN
                baud_current := baud_current + 1;
                div_clk <= '0'; 
            ELSE
                div_clk <= '1';
                baud_current := 0;
            END IF;
        END IF;
    END PROCESS;

    tx_process : PROCESS(div_clk, tx_reset)
    VARIABLE tx_current_bit : integer RANGE 0 TO 9 := 0;
    BEGIN
        tx_event <= '0';
        IF tx_reset = '1' THEN                    -- [TXRESET] --
            tx <= '1';
            tx_current_bit  := 0;
        ELSIF rising_edge(div_clk) THEN           -- [TXIDLE] --
            IF tx_send = '0' THEN
                tx <= '1';
            ELSE                                  -- [TXSEND] --
                tx <= tx_buffer_data(tx_current_bit);
                IF tx_current_bit < 9 THEN
                    tx_current_bit := tx_current_bit + 1;
                ELSE                              -- [TXSTOP] --
                    tx_event <= '1';
                    tx_current_bit := 0;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    rx_process: PROCESS(div_clk)
    VARIABLE rx_current_bit : integer RANGE 0 TO 9 := 0;
    BEGIN
        rx_event <= '0';
        IF rising_edge(div_clk) THEN
            IF rx_current_bit = 9 THEN             -- [RXSTOP] --
                rx_current_bit := 0;
                IF rx = '1' THEN
                    rx_event <= '1';
                    rx_out_data <= rx_buffer_data;
                END IF;
            ELSIF rx_current_bit > 0 THEN          -- [RXRECV] --
                rx_buffer_data(rx_current_bit-1) <= rx;
                rx_current_bit := rx_current_bit + 1;
            ELSIF rx = '0' THEN                    -- [RXSTART] --
                rx_current_bit := 1;
            END IF;                                -- [RXIDLE] -- ( rx = '1' )
        END IF;
    END PROCESS;
        
END RTL;