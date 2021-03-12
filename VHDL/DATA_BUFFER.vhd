library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CONSTANTS.all;

entity DATA_BUFFER is
	generic (
			ADDSET : integer;
			DATAST : integer
		);
	port(	
		clock           	: in std_logic;		
		reset				: in std_logic;				
		row_0		    	: out std_logic_vector(DATA_WIDTH-1 downto 0); -- First line of the buffer. Must be read constantly by the ip manager
		-- CPU INTERFACE
		cpu_data	    	: inout std_logic_vector(DATA_WIDTH-1 downto 0);
		cpu_addr        	: in std_logic_vector(ADD_WIDTH-1 downto 0);
		cpu_noe    			: in std_logic;	
		cpu_nwe    			: in std_logic;		
		cpu_ne1    			: in std_logic;	
		-- IP MANAGER INTERFACE
		ipm_data_in	  		: in std_logic_vector(DATA_WIDTH-1 downto 0);
		ipm_data_out		: out std_logic_vector(DATA_WIDTH-1 downto 0);
		ipm_addr     		: in std_logic_vector(ADD_WIDTH-1 downto 0);
		ipm_rw 				: in std_logic;
		ipm_enable  		: in std_logic;
		cpu_read_completed 	: out std_logic;
		cpu_write_completed : out std_logic
		);
end entity DATA_BUFFER;

architecture BEHAVIOURAL of DATA_BUFFER is

	-- 64 x 16 buffer
	type mem_type is array (0 to MEM_SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
	signal mem : mem_type := (others => (others => '0'));

	-- STATES OF THE FSM OF THE BUFFER
	type data_buffer_state_type is (IDLE, WAIT_ADDSET, MEMORY_OPERATION, WAIT_DATAST_WR, WAIT_DATAST_RD);
	signal data_buffer_state : data_buffer_state_type;

	--  INTERNAL COUNTER FOR WAITING STATES
	signal cnt : integer := 0;

	--  INTERNAL SIGNAL TO TEMPORARY STORE THE ADDRESS COMING FROM THE CPU
	signal address : std_logic_vector(ADD_WIDTH-1 downto 0);

begin

	process(clock) 
	begin
		if(reset = '1') then
			mem 			  <= (others => (others => '0'));
			data_buffer_state <= IDLE;
			cnt				  <= 0;
			address			  <= (others => '0');
		elsif(rising_edge(clock)) then
			-- possible writing from any IP
			if (ipm_enable = '1' and ipm_rw = '1') then
				mem(to_integer(unsigned(ipm_addr))) <= ipm_data_in;
			end if;
			-- FSM behavior
			case(data_buffer_state) is
			
				when IDLE => 
					cpu_data <= (others => 'Z');
					cpu_write_completed <= '0';
					cpu_read_completed  <= '0';
					if(cpu_ne1 = '0') then 
						data_buffer_state <= WAIT_ADDSET;
					end if;

				when WAIT_ADDSET => 
					if(cnt = ADDSET-1) then
						cnt 	    	  <= 0;
						address  		  <= cpu_addr;
						data_buffer_state <= MEMORY_OPERATION;	
					else
						cnt 			  <= cnt + 1;
						data_buffer_state <= WAIT_ADDSET;
					end if;

				when MEMORY_OPERATION =>
					if(cpu_nwe = '0') then
						data_buffer_state <= WAIT_DATAST_WR;
					else
						cpu_data          <= mem(to_integer(unsigned(address)));
						data_buffer_state <= WAIT_DATAST_RD;
					end if;

				when WAIT_DATAST_WR =>
					if(cnt >= DATAST-1 and cpu_ne1 = '1') then
						cnt 	    	  				   <= 0;
						mem(to_integer(unsigned(address))) <= cpu_data;
						cpu_write_completed				   <= '1';
						data_buffer_state 				   <= IDLE;
					else
						cnt 			  <= cnt + 1;
						data_buffer_state <= WAIT_DATAST_WR;
					end if;

				when WAIT_DATAST_RD =>
					if(cnt = DATAST-1) then
						cnt 	    	   <= 0;
						cpu_read_completed <= '1';
						data_buffer_state  <= IDLE;
					else
						cnt 			  <= cnt + 1;
						data_buffer_state <= WAIT_DATAST_RD;
					end if;

			end case;
		end if;
	end process; 

	-- row_0 is always assigned to the first word of the buffer  
	row_0 	 	 <= mem(0);
	-- READING ASSIGNMENTS
	ipm_data_out <= mem(to_integer(unsigned(ipm_addr))) when (ipm_enable = '1' and ipm_rw = '0') else (others => 'Z');

end architecture BEHAVIOURAL;






