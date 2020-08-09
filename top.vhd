library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity top is
	Port (  dtx : out std_logic;	-- uart tx pin		
			fclk: in  std_logic 	-- fpga clock pin
	);		
end top;

architecture arc_top of top is
component uart
	port( iclk: in std_logic;
			idata: in unsigned (31 downto 0);
			size: in unsigned (7 downto 0);
			tx: out std_logic:='1';
			wi: in std_logic;
			wc: out std_logic);
end component;

signal cnt: integer := 0;
signal data_idx: integer := 0;
signal uart_state: integer:=0;
signal usize: unsigned (7 downto 0) := x"00";
signal udata: unsigned (31 downto 0) := x"00000000";
signal tdata: unsigned (31 downto 0) := x"00000000";
signal uwi: std_logic := '0';
signal uwc: std_logic;

signal psk_idx: integer := 0;
type psk_array is array (0 to 7) of unsigned (7 downto 0);
signal psk_data: psk_array := ( 0 => x"00",
1 => x"01",
2 => x"02",
3 => x"03",
4 => x"02",
5 => x"00",
6 => x"01",
7 => x"03");


-- Ratio of signal frequency and sampling frequency 1/10

type uart_array is array (0 to 9) of unsigned (31 downto 0);
signal sine: uart_array :=  (0 => "00000000000000000000000001111111",
1 => "00000000000000000000000011001010",
2 => "00000000000000000000000011111000",
3 => "00000000000000000000000011111000",
4 => "00000000000000000000000011001010",
5 => "00000000000000000000000001111111",
6 => "00000000000000000000000000110100",
7 => "00000000000000000000000000000110",
8 => "00000000000000000000000000000110",
9 => "00000000000000000000000000110100");

signal cosine: uart_array :=  (0 => "00000000000000000000000011111110",
1 => "00000000000000000000000011100110",
2 => "00000000000000000000000010100110",
3 => "00000000000000000000000001011000",
4 => "00000000000000000000000000011000",
5 => "00000000000000000000000000000000",
6 => "00000000000000000000000000011000",
7 => "00000000000000000000000001011000",
8 => "00000000000000000000000010100110",
9 => "00000000000000000000000011100110");

begin
	inst_uart: uart port map (iclk=>fclk, idata=>udata, size=>usize, tx=>dtx, wi=>uwi, wc=>uwc);

uart_tx: process
	variable inverse_idx: integer := 0;
	
	begin
	if rising_edge(fclk) then
		if cnt < 5000 then -- 0.0001 second
			cnt <= cnt + 1;
		else
			if uart_state = 0 then				-- send '#'
				--tdata <= uart_data(data_idx);
				
				--if psk_data(psk_idx) = 0 then
					--udata <= tdata;
				--elsif psk_data(psk_idx) = 1 then
					--udata <= shift_right(unsigned(tdata), 1) + 64;
				--elsif psk_data(psk_idx) = 2 then
					--udata <= shift_right(unsigned(tdata), 2) + 96;
				--elsif psk_data(psk_idx) = 3 then
					--udata <= shift_right(unsigned(tdata), 3) + 112;
				--end if;
				
				if psk_data(psk_idx) = 0 then
					udata <= sine(data_idx);
				elsif psk_data(psk_idx) = 1 then
					udata <= cosine(data_idx);
				elsif psk_data(psk_idx) = 2 then
					inverse_idx := 10 - data_idx; -- -sine

					if inverse_idx = 10 then
						inverse_idx := 0;
					end if;

					udata <= sine(inverse_idx);
				elsif psk_data(psk_idx) = 3 then
					if data_idx >= 5 then
						inverse_idx := data_idx - 5;
					else
						inverse_idx := data_idx + 5;
					end if;

					udata <= cosine(inverse_idx);
				end if;
					
				data_idx <= data_idx + 1;
				usize <= x"08";
				uwi <= '1';
				uart_state <= uart_state + 1;
			elsif uart_state = 1 then	
				if uwc = '1' then				-- wait for tx to complete
					uwi <= '0';
					uart_state <= uart_state + 1;
					
				end if;	
			elsif uart_state = 2 then
				if uwc = '0' then				-- tx one 32 bit value
					uart_state <= 3;
					
					if data_idx > 19 then
						data_idx <= 0;
						psk_idx <= psk_idx + 1;
					end if;
				end if;
			elsif uart_state = 3 then
				if uwc = '0' then				-- tx one 32 bit value
					cnt <= 0;
					uart_state <= 0;
					if psk_idx > 7 then
						psk_idx <= 0;
					end if;
				end if;
			end if;
		end if;
	
	
	end if;
end process;


end arc_top;

