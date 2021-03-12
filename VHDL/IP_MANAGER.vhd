library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.CONSTANTS.all;

entity IP_MANAGER is
	port(	
            clock 					: in std_logic;
            reset          			: in std_logic;
            ne1						: in std_logic;
            interrupt       		: out std_logic;
            -- BUFFER INTERFACE		
            buf_data_out    		: out std_logic_vector(DATA_WIDTH-1 downto 0);
            buf_data_in     		: in std_logic_vector(DATA_WIDTH-1 downto 0);            
            buf_addr        		: out std_logic_vector(ADD_WIDTH-1 downto 0);
            buf_rw          		: out std_logic;
            buf_enable      		: out std_logic;
            row_0           		: in std_logic_vector (DATA_WIDTH-1 downto 0);
            cpu_read_completed  	: in std_logic; 
            cpu_write_completed 	: in std_logic; 
            -- IP INTERFACE
            addr_ip         	   : in addr_array;
            data_in_ip      	   : in data_array; 
            data_out_ip     	   : out data_array;                                         
            opcode_ip			   : out opcode_array;
            int_pol_ip			   : out std_logic_vector(NUM_IPS-1 downto 0);
            rw_ip		    	   : in std_logic_vector(NUM_IPS-1 downto 0);    
            buf_enable_ip   	   : in std_logic_vector(NUM_IPS-1 downto 0);    
            enable_ip      		   : out std_logic_vector(NUM_IPS-1 downto 0);
            ack_ip 	        	   : out std_logic_vector(NUM_IPS-1 downto 0);    
            interrupt_ip 		   : in std_logic_vector(NUM_IPS-1 downto 0);
            error_ip			   : in std_logic_vector(NUM_IPS-1 downto 0);
            cpu_read_completed_ip  : out std_logic_vector(NUM_IPS-1 downto 0);
			cpu_write_completed_ip : out std_logic_vector(NUM_IPS-1 downto 0)        	
		);
end entity IP_MANAGER;

architecture BEHAVIOURAL of IP_MANAGER is
	
	-- STATE OF THE INTERNAL FSM
	type ip_manager_state_type is (IDLE, 
								   MULTIPLEXING,
								   IRQ_FORWARDING,
								   ERROR_SIGNALING,
								   ERROR_SIGNALING_DONE
	);
	signal state : ip_manager_state_type;
	
	-- INTERNAL REGISTER OF THE ACTIVE IP (0 IF THE MANAGER ITSELF)
	signal active_ip : integer; 	
	
	-- OUTPUTS TO BUFFER when controlled directly by the manager (see assignment out of the process)
	signal buf_data_out_man : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal buf_addr_man     : std_logic_vector(ADD_WIDTH-1 downto 0);
	signal buf_rw_man       : std_logic;
    signal buf_enable_man   : std_logic;
    
    -- INTERNAL SIGNAL TO SAVE THE ID OF THE FAULTY IP
	signal faulty_ipaddress : integer;
   	
   	-- INTERNAL SIGNAL TO BRING FROM ONE STATE TO ANOTHER THE OPCODE OF THE CONTROL WORD
   	signal opcode : std_logic_vector(OPCODE_SIZE-1 downto 0);
   	
   	-- INTERNAL SIGNAL TO BRING FROM ONE STATE TO ANOTHER THE INTERRUPT/POLLING BIT
   	signal i_p : std_logic;
   	
   	-- INTERNAL FF TO SEE WHETHER THE PRESENT ERRORS HAVE BEEN COMMUNICATED TO THE CPU
   	signal signaled_errors : std_logic_vector(NUM_IPS-1 downto 0);
   	
   	-- INTERNAL FF TO SEE WHETHER THE PRESENT INTERRUPT REQUESTS HAVE BEEN COMMUNICATED TO THE CPU
   	signal signaled_interrupts : std_logic_vector(NUM_IPS-1 downto 0);
	
     
begin
	
	
	-- BEHAVIORAL PROCESS
	process (clock)
		-- INTERNAL VARIABLE TO TEMPORARY STORE THE ADDRESS OF AN IP 
   		variable ipaddress : integer;
   		-- INTERNAL FLAG TO SIGNAL IF THE INTERRUPT SIGNAL FOR AN IP CORE REQUEST HAS BEEN ASSERTED
   		variable interrupt_raised : boolean;
   		-- INTERNAL FLAG TO SIGNAL IF THE INTERRUPT SIGNAL FOR AN ERROR SIGNALING HAS BEEN ASSERTED
   		variable error_raised : boolean;
	begin 
		if(rising_edge(clock)) then 
			-- synchronous reset
			if(reset = '1') then                   			
				interrupt       	<= '0';
				-- BUFFER INTERFACE
				buf_data_out_man    <= (others => '0');
				buf_addr_man        <= (others => '0');
				buf_enable_man      <= '0';				
				buf_rw_man          <= '0';
				-- IP INTERFACE                      
				opcode_ip			<= (others => (others => '0'));
				enable_ip 			<= (others => '0');  
				ack_ip 	        	<= (others => '0');
				-- INTERNALS
				active_ip        	<= 0;
				state			 	<= IDLE; 
				ipaddress 		 	:= 0;
				interrupt_raised    := false;
				error_raised		:= false;
				faulty_ipaddress    <= 0;
				opcode			 	<= (others => '0');
				i_p				 	<= '0';
				signaled_errors  	<= (others => '0');
				signaled_interrupts <= (others => '0');
			else
				case state is
					when IDLE =>
						-- generic clock cycle, no reset, not doing anything else
						-- cases considered are, in order of importance:
						--		signaling an error 
						--		forwarding interrupt from the cores
						-- 		serving the CPU acknowledgment
						--		accepting the CPU request of open transaction
						-- elsif statement was used to mutually exclude cases
						-- when none of these cases, remains in IDLE state
						-- IDLE state is characterized by the fact that all is in a "quiescent state": no valid values for any signal
						buf_data_out_man 		<= (others => '0');
						buf_addr_man     		<= (others => '0');
						buf_enable_man   		<= '0';				
						buf_rw_man       		<= '0';                    
						opcode_ip		 		<= (others => (others => '0'));
						int_pol_ip		 		<= (others => '0');
						enable_ip 		 		<= (others => '0');  
						ack_ip 	         		<= (others => '0');
						active_ip        		<= 0;
						state			 		<= IDLE; 
						ipaddress 		 		:= 0;
						opcode			 		<= (others => '0');
						i_p				 		<= '0';
						-- flag of interrupt request or error signaling which has been acked can be cleared 
						for i in 0 to NUM_IPS-1 loop
							if(error_ip(i) = '0' and signaled_errors(i) = '1') then
								signaled_errors(i) <= '0';
							end if;
							if(interrupt_ip(i) = '0' and signaled_interrupts(i) = '1') then
								signaled_interrupts(i) <= '0';
							end if;
						end loop;
						-- CASE: AN ERROR SIGNAL ARRIVES
						-- if there is any IP that raised the error signal and no transactions are active
						if(unsigned(error_ip and not(signaled_errors)) > 0 and (ne1 = '1' or row_0(B_E_POS) = '0')) then
							-- there are 2 possible cases:
							-- 1) the interrupt is not raised and then I can proceed for the signaling of this error
							if(error_raised = false) then
								for i in 0 to NUM_IPS-1 loop
									exit when error_raised = true;	
									-- the IP error must be not already signaled  
									if(error_ip(i) = '1' and signaled_errors(i) = '0') then
									-- if match, raise the request and exit from the loop
									-- it is the manager itself that interrupts the CPU in this case
										buf_enable_man       <= '1';
										buf_rw_man 	         <= '1';
										buf_addr_man         <= (others => '0');
										buf_data_out_man   	 <= "000000000" & std_logic_vector(to_unsigned(0, IPADDR_SIZE)); -- it is me
										signaled_errors(i) 	 <= '1';
										faulty_ipaddress     <= i+1;
										state 			     <= IRQ_FORWARDING;
										-- if any interrupt request was present, it is preempted
										interrupt_raised 	:= false;
										signaled_interrupts <= (others => '0');
										-- break the loop
										error_raised   := true;
									end if;
								end loop;
							-- 2) the interrupt is raised, and so I have to wait for my turn, so I do nothing
							end if;	
						-- CASE: AN INTERRUPT REQUEST ARRIVES
						-- if no errors, no transactions and there is any IP that raised the interrupt signal 
						elsif(unsigned(interrupt_ip and not(signaled_interrupts)) > 0 and (ne1 = '1' or row_0(B_E_POS) = '0') and error_raised = false) then
							-- there are 2 possible cases:
							-- 1) the interrupt is not raised and then I can proceed in forwarding the request	
							if(interrupt_raised = false) then				
								-- scan all the IPs in order of priority
								for i in 0 to NUM_IPS-1 loop
									exit when interrupt_raised = true;
									if(interrupt_ip(i) = '1') then
										-- if match, raise the request and exit from the loop
										-- set signals to write in the buffer the interrupting IP ID in row0
										buf_enable_man   		 <= '1';
										buf_rw_man       		 <= '1';
										buf_addr_man     		 <= (others => '0');
										buf_data_out_man 		 <= "000000000" & std_logic_vector(to_unsigned(i+1, IPADDR_SIZE));
										signaled_interrupts(i)   <= '1';
										state 			 		 <= IRQ_FORWARDING;
										-- break the loop
										interrupt_raised := true;
									end if;
								end loop;
							-- 2) the interrupt is raised, and so I have to wait for my turn, so I do nothing
							end if;
						-- CASE: THE CPU SERVES AN ACKNOWLEDGMENT FROM THE CPU
						-- if no transaction is active, then enable the communication with the interrupting IP, acknowledging it
						elsif(row_0(B_E_POS) = '1' and row_0(ACK_POS) = '1' and active_ip = 0) then
							interrupt <= '0';
							ipaddress := to_integer(unsigned(row_0(IPADDR_POS downto 0)));
							if(ipaddress > 0 and ipaddress <= NUM_IPS) then
								interrupt_raised 	   := false;	
								enable_ip(ipaddress-1) <= '1';
								ack_ip(ipaddress-1)    <= '1';
								active_ip 			   <= ipaddress;
								state				   <= MULTIPLEXING;
							-- if the manager itself is acked, means that the CPU is serving an error signaling
							elsif(ipaddress = 0) then
								-- take control of the signals to the buffer by setting active_ip to 0
								-- write in row1 the address of the faulty IP
								error_raised	 := false;
								enable_ip 		 <= (others => '0');
								active_ip 		 <= 0;
								buf_enable_man 	 <= '1';
								buf_rw_man 		 <= '1';
								buf_addr_man 	 <= std_logic_vector(to_unsigned(1, ADD_WIDTH));
								buf_data_out_man <= "000000000" & std_logic_vector(to_unsigned(faulty_ipaddress, IPADDR_SIZE));
								state 			 <= ERROR_SIGNALING;
							end if;
						-- CASE: OPENING A TRANSACTION TO START TALKING WITH AN IP (NO INTERRUPT SERVING)
						-- if the CPU want to start a transaction 
						-- and no transactions are currently active and no interrupt requests are served, then it can be opened
						elsif(row_0(B_E_POS) = '1' and row_0(ACK_POS) = '0' and active_ip = 0) then
							-- if the address is referred to an existing IP core, then enable that IP
							ipaddress := to_integer(unsigned(row_0(IPADDR_POS downto 0)));
							if(ipaddress > 0 and ipaddress <= NUM_IPS) then
								enable_ip(ipaddress-1)  <= '1';
								active_ip 			    <= ipaddress;
								opcode_ip(ipaddress-1)  <= row_0(DATA_WIDTH-1 downto DATA_WIDTH-6);
								int_pol_ip(ipaddress-1) <= row_0(I_P_POS);
								state					<= MULTIPLEXING;
							-- else, address is out of range so do nothing
							else null; 	
							end if;
						-- NO MORE CASES ARE CONSIDERED
						end if;
					
					
					when MULTIPLEXING =>
						-- no need of assigning signals, they are already managed by the statements at the bottom
						-- when the transaction is ended, the B/E bit goes to 0
						if(row_0(B_E_POS) = '0') then
							-- disable that IP, take again control of all signals and go to IDLE
							active_ip		 <= 0;
							buf_data_out_man <= (others => '0');
							buf_addr_man     <= (others => '0');
							buf_enable_man   <= '0';				
							buf_rw_man       <= '0';                       
							opcode_ip		 <= (others => (others => '0'));
							int_pol_ip		 <= (others => '0');
							enable_ip 		 <= (others => '0');  
							ack_ip 	         <= (others => '0');
							state 			 <= IDLE;
						else
							-- communication not ended yet
							state 			 <= MULTIPLEXING;
						end if;
						
					when IRQ_FORWARDING =>
						interrupt		 <= '1';
						buf_enable_man   <= '0';
						buf_rw_man       <= '0';
						buf_addr_man     <= (others => '0');
						buf_data_out_man <= (others => '0');
						state 			 <= IDLE;
					
					when ERROR_SIGNALING =>
						buf_enable_man   				  <= '0';
						buf_rw_man       				  <= '0';
						buf_addr_man     				  <= (others => '0');
						buf_data_out_man 		          <= (others => '0');
						state 			 				  <= ERROR_SIGNALING_DONE;
							
					when ERROR_SIGNALING_DONE =>
						-- this idleness state is reached when the manager has communicated to the CPU the ID of the core in error
						-- simply turn off all signals and wait for the transaction to be closed
						buf_data_out_man <= (others => '0');
						buf_addr_man     <= (others => '0');
						buf_enable_man   <= '0';				
						buf_rw_man       <= '0';                    
						opcode_ip		 <= (others => (others => '0'));
						int_pol_ip		 <= (others => '0');
						enable_ip 		 <= (others => '0');  
						ack_ip 	         <= (others => '0');
						if(row_0(B_E_POS) = '0') then
							state <= IDLE;
						else
							state <= ERROR_SIGNALING_DONE;
						end if;
						
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
	-- MULTIPLEXING INTERFACE BETWEEN IP AND BUFFER (DEPENDING ON active_ip VALUE) 
	buf_data_out <= data_in_ip(active_ip-1)    when active_ip > 0 else buf_data_out_man;
	buf_addr 	 <= addr_ip(active_ip-1) 	   when active_ip > 0 else buf_addr_man;
	buf_rw 		 <= rw_ip(active_ip-1) 		   when active_ip > 0 else buf_rw_man;
	buf_enable 	 <= buf_enable_ip(active_ip-1) when active_ip > 0 else buf_enable_man;

	process(active_ip, buf_data_in, cpu_read_completed, cpu_write_completed)
	begin
		data_out_ip 	       <= (others => (others => '0'));
		cpu_read_completed_ip  <= (others => '0');
		cpu_write_completed_ip <= (others => '0');
		if(active_ip > 0) then
			data_out_ip(active_ip-1) 		    <= buf_data_in;
			cpu_read_completed_ip(active_ip-1)  <= cpu_read_completed; 
			cpu_write_completed_ip(active_ip-1) <= cpu_write_completed; 
		end if;
	end process;
	
end architecture;