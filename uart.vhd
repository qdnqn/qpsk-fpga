library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity uart is
	port( iclk: in std_logic;
			idata: in unsigned (31 downto 0);
			size: in unsigned (7 downto 0);
			tx: out std_logic:='1';
			wi: in std_logic;
			wc: out std_logic);
end uart;

architecture a_uart of uart is
signal data: unsigned (31 downto 0) := x"00000000";
signal dsize: unsigned (7 downto 0) := x"00";
begin
	process 
		variable state:integer:=0;
		variable pause:integer:=216;
		variable cnt:integer:=0;
		variable idx:integer:=0;
		
		variable baudrate:integer:=108;		--> 921600 Bauds -> 54 clocks of 50MHz
		--variable baudrate:integer:=434;		--> 115200 Bauds -> 434 clocks of 50MHz 
		
		begin
			if iclk'event and iclk='1' then
				if wi = '1' then
					dsize <= size;
					data <= idata;
					wc <= wi;
				end if;
				
			
				if dsize > 0 then
					cnt := cnt + 1;
					
					if(state = 0) then
						if(cnt = pause) then
							cnt := 0;
							state := state + 1;
							pause := baudrate; 
							
							-- start bit
							tx <= '0';
						end if;
					elsif(state <= 8) then
						if(cnt = pause) then
							cnt := 0;
							state := state + 1;
							pause := baudrate;
							
							-- data
							tx <= data(idx);
							idx := idx + 1;
						end if;
					elsif(state = 9) then
						if(cnt = pause) then
							cnt := 0;
							state := state + 1;
							pause := baudrate;
							
							-- stop bit
							tx <= '1';
						end if;	
					else
						if(cnt = pause) then
							cnt := 0;
							state := 0;
							pause := 10*baudrate;						-- pause between characters
							tx <= '1';
							
							--dsize <= dsize - 8;
							if idx >= to_integer(dsize) then
								dsize <= x"00";
								idx := 0;
								wc <= '0';
							end if;
						end if;	
					end if;
				end if;
			end if;	
	end process;	

end a_uart;

