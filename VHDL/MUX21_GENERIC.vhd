library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MUX21_GENERIC is 
	generic(N : integer := 32);
	port(A : in std_logic_vector(N-1 downto 0);
		 B : in std_logic_vector(N-1 downto 0);
		 SEL : in std_logic;
		 O : out std_logic_vector(N-1 downto 0));
end MUX21_GENERIC;

architecture BEHAVIORAL of MUX21_GENERIC is
begin

	with SEL select O <=
	A when '0',
	B when '1',
	(others => '0') when others;


end BEHAVIORAL;