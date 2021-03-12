library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity REGISTER_GENERIC is
	generic (N : integer := 32);
	port (RST : IN std_logic;
		  CLK : IN std_logic;
		  CE  : IN std_logic; 
		  D   : IN std_logic_vector(N-1 downto 0);
		  Q   : OUT std_logic_vector(N-1 downto 0));
end REGISTER_GENERIC;

architecture BEHAVIORAL of REGISTER_GENERIC is
begin

	process (RST, CLK, CE, D)
	begin
		if(RST = '1') then
			Q <= (others => '0');
		elsif(CLK'event and CLK = '1') then
			if(CE = '1') then
				Q <= D;
			end if;
		end if;
	end process;

end BEHAVIORAL;