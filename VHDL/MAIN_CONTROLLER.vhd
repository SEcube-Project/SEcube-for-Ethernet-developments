library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.CONSTANTS.all;

use work.LAN9211_CONSTANTS.all;
use work.ETH_SMB_CONSTANTS.all;


entity MAIN_CONTROLLER is
	port(
			-------------------------------------------------------------------------------
			--IP Manager interface
			clock                   : in std_logic;
			reset 				    : in std_logic;
			data_in 				: in std_logic_vector(DATA_WIDTH-1 downto 0);
			opcode 					: in std_logic_vector(OPCODE_SIZE-1 downto 0);
			enable 					: in std_logic;
			ack 					: in std_logic;
			interrupt_polling		: in std_logic;
			data_out 				: out std_logic_vector(DATA_WIDTH-1 downto 0);
			buffer_enable 			: out std_logic;
			address 				: out std_logic_vector(ADD_WIDTH-1 downto 0);
			rw 						: out std_logic;
			interrupt  				: out std_logic;
			error 					: out std_logic;
			write_completed			: in std_logic;
			read_completed			: in std_logic;
			-------------------- reset signal for LAN9211 -------------------
			eth_rstn : out std_logic;
			--eth_irq : in std_logic;
			-------------------------------------------------------------------------------

			-- PIO Controller interface
			-- (Globals)
			pio_enable				: out std_logic;
			pio_opc					: out std_logic_vector(PIO_OPC_SIZE-1 downto 0);
			pio_op_completed		: in std_logic;
			-- (PIO CSR unit)
			pio_csr_addr			: out std_logic_vector(LAN9211_ADDR_WIDTH downto 0);
			pio_csr_datain			: out std_logic_vector(2*LAN9211_DATA_WIDTH-1 downto 0);
			pio_csr_dataout			: in  std_logic_vector(2*LAN9211_DATA_WIDTH-1 downto 0);
			leds : out std_logic_vector(7 downto 0)
			--------------------------------------------------------------------------------
		);

end entity;


architecture beh of MAIN_CONTROLLER is
	type Statetype is	(
						-- GLOBAL STATES
						 OFF,
						 DECODE_OPC,
						 WAIT_PIO_CSR_COMPLETED,
						 IDLE,
						 ------------------------------------------------------------------
						 -- CSR OPERATIONS
						 CSR_WAIT_ADDR_COMPLETED,
						 CSR_ADDR_LATCH,
						 CSR_ADDR_READ,

						 ------- CSR_WRITE STATES
						 CSR_WAIT_WR_DATAH_COMPLETED,
						 CSR_WR_DATAH_LATCH,
						 CSR_WR_DATAH_READ,
						 CSR_WAIT_WR_DATAL_COMPLETED,
						 CSR_WR_DATAL_LATCH,
						 CSR_WR_DATAL_READ,
						 CSR_WR_WAIT_CPU_LOCK,

						 -------- CSR_READ_STATES
						 CSR_WRITEBACK_DATAHIGH,
						 CSR_WRITEBACK_DATALOW,
						 CSR_RD_WAIT_CPU_LOCK,
						 CSR_WRITE_CPU_UNLOCK,
						 CSR_WAIT_CPU_UNLOCK,

						 --- RESET LAN STATES
						 LAN_HRST

				);


	signal state 			: StateType := OFF;

	signal opc_reg			: std_logic_vector(OPCODE_SIZE-1 downto 0)  := MAIN_OPC_NOP;
	signal eth_rstn_s : std_logic :='1';
	signal csr_addr_reg		: std_logic_vector(LAN9211_ADDR_WIDTH downto 0) := (others => '0');
	signal csr_dataout_reg  : std_logic_vector(2*LAN9211_DATA_WIDTH-1 downto 0):= (others => '0');
	signal csr_datain_reg	: std_logic_vector(2*LAN9211_DATA_WIDTH-1 downto 0):= (others => '0');
	signal pio_opc_reg		: std_logic_vector(PIO_OPC_SIZE-1 downto 0) := (others => '0');
	signal leds_s_reg				: std_logic_vector(7 downto 0);
	signal wait_lan_controller : integer := 0;
	signal word_reg : std_logic_vector(DATA_WIDTH-1 downto 0):= (others => '0');

	signal dbuff_addr_reg : std_logic_vector(ADD_WIDTH-1 downto 0) := (others => '0');
	signal byte_counter : integer :=0;


begin
	leds<= leds_s_reg;
	pio_csr_addr <= csr_addr_reg;
	pio_csr_datain <= csr_datain_reg;
	eth_rstn <= eth_rstn_s;
  	pio_opc <= pio_opc_reg;


	MAIN_CTRL: process(clock)
	begin
		if reset = '1' then
			state <= OFF;
			wait_lan_controller <= 0;
			opc_reg <= MAIN_OPC_NOP;

			buffer_enable <= '0';
			rw <= '0';
			address <= (others => '0');

			csr_addr_reg <= (others => '0');
			csr_datain_reg <= (others => '0');
			csr_dataout_reg <= (others => '0');

			pio_opc_reg <= (others => '0');
			pio_enable <= '0';

			word_reg <=  (others => '0');

			dbuff_addr_reg <= (others => '0');


		elsif rising_edge(clock) then
			-- Defaults
			eth_rstn_s <= '1';
			buffer_enable <= '0';
			rw <= '0';
			address <= ( others => '0');


			case state is
				-----------------------------------------------------------------------------------
				-- Global states
				when OFF =>
				pio_enable <='0';
					if enable = '1' then
						state <= DECODE_OPC;
						opc_reg <= opcode;
					else
						state <= OFF;
					end if;

				when DECODE_OPC =>
				-- Opcode decode stage

					case opc_reg is
						when MAIN_OPC_CSR_RD =>
							state <= CSR_WAIT_ADDR_COMPLETED;
						when MAIN_OPC_CSR_WR =>
							state <= CSR_WAIT_ADDR_COMPLETED;
						when others =>
							state <= IDLE;
						end case;

				when IDLE =>
				pio_enable <='0';
					if enable = '1' then
						state <= IDLE;
					else
						state <= OFF;
					end if;

--			when LAN_HRST =>
						-- Reset the LAN9211 controller after a rst of the IPC
						-- has occurred
--					eth_rstn_s <= '0';
--					if wait_lan_controller < hrst_PULSEWIDTH_CYCLES then
--						wait_lan_controller <= wait_lan_controller+1;
--						state <= LAN_HRST;
--					else
--						state <= OFF;
--					end if;

				-------------------------------------------------------------------------------------
				-- PIO global states
				when CSR_WAIT_ADDR_COMPLETED =>
					if write_completed = '1' then
						buffer_enable <= '1';
						rw <= '0';
						address <= std_logic_vector(to_unsigned(ETH_SMB_ADDRREG,ADD_WIDTH));
						state <= CSR_ADDR_LATCH;
					else
						state <= CSR_WAIT_ADDR_COMPLETED;
					end if;
				when CSR_ADDR_LATCH =>
					buffer_enable <= '1';
					rw <= '0';
					address <= std_logic_vector(to_unsigned(ETH_SMB_ADDRREG,ADD_WIDTH));
					state <= CSR_ADDR_READ;

				when CSR_ADDR_READ =>
					csr_addr_reg <= data_in(7 downto 0);
					if opc_reg = MAIN_OPC_CSR_RD then
						state <= CSR_RD_WAIT_CPU_LOCK;
					elsif opc_reg = MAIN_OPC_CSR_WR then
						state <= CSR_WAIT_WR_DATAH_COMPLETED;
					end if;

				when WAIT_PIO_CSR_COMPLETED =>
					case opc_reg is
						when MAIN_OPC_CSR_RD =>
							if pio_op_completed = '1' then
								csr_dataout_reg  <= pio_csr_dataout;
								state <= CSR_WRITEBACK_DATAHIGH;
							else
								state <= WAIT_PIO_CSR_COMPLETED;
							end if;
						when MAIN_OPC_CSR_WR =>
							if pio_op_completed = '1' then
								state <= CSR_WRITE_CPU_UNLOCK;
							else
								state <= WAIT_PIO_CSR_COMPLETED;
							end if;
						when others =>
							state <= IDLE;
					end case;
					when CSR_WRITE_CPU_UNLOCK =>
						buffer_enable <= '1';
						rw <= '1';
						address <= std_logic_vector(to_unsigned(ETH_SMB_LOCKREG,ADD_WIDTH));
						data_out <= ETH_SMB_UNLOCK_CWD;
						state <= CSR_WAIT_CPU_UNLOCK;
					when CSR_WAIT_CPU_UNLOCK =>
						if read_completed = '1' then
							state <= IDLE;
						else
							state <= CSR_WAIT_CPU_UNLOCK;
						end if;

				-------------------------------------------------------------------------------
				-- CSR Read States
				when CSR_RD_WAIT_CPU_LOCK =>
				pio_opc_reg<= PIO_OPC_CSR_RD;
				pio_enable<='1';
					if write_completed = '1' then
						state <= WAIT_PIO_CSR_COMPLETED;
					else
						state <= CSR_RD_WAIT_CPU_LOCK;
					end if;
				when CSR_WRITEBACK_DATAHIGH =>
					buffer_enable <= '1';
					rw <= '1';
					address <= std_logic_vector(to_unsigned(ETH_SMB_DATAREG_H,ADD_WIDTH));
					data_out <= csr_dataout_reg(31 downto 16);
					state <= CSR_WRITEBACK_DATALOW;
				when CSR_WRITEBACK_DATALOW =>
					buffer_enable <= '1';
					rw <= '1';
					address <= std_logic_vector(to_unsigned(ETH_SMB_DATAREG_L,ADD_WIDTH));
					data_out <= csr_dataout_reg(15 downto 0);
					state <= CSR_WRITE_CPU_UNLOCK;

				----------------------------------------------------------------------------------
				-- CSR Write states
				when CSR_WAIT_WR_DATAH_COMPLETED  =>
					if write_completed = '1' then
						buffer_enable <= '1';
						rw <= '0';
						address <= std_logic_vector(to_unsigned(ETH_SMB_DATAREG_H,ADD_WIDTH));
						state <= CSR_WR_DATAH_LATCH;
					else
						state <= CSR_WAIT_WR_DATAH_COMPLETED;
					end if;
				when CSR_WR_DATAH_LATCH =>
					buffer_enable <= '1';
					rw <= '0';
					address <= std_logic_vector(to_unsigned(ETH_SMB_DATAREG_H,ADD_WIDTH));
					state <= CSR_WR_DATAH_READ;
				when CSR_WR_DATAH_READ =>
					csr_datain_reg(31 downto 16) <= data_in;
					state <= CSR_WAIT_WR_DATAL_COMPLETED;
				when CSR_WAIT_WR_DATAL_COMPLETED  =>
					if write_completed = '1' then
						buffer_enable <= '1';
						rw <= '0';
						address <= std_logic_vector(to_unsigned(ETH_SMB_DATAREG_L,ADD_WIDTH));
						state <= CSR_WR_DATAL_LATCH;
					else
						state <= CSR_WAIT_WR_DATAL_COMPLETED;
					end if;
				when CSR_WR_DATAL_LATCH =>
					buffer_enable <= '1';
					rw <= '0';
					address <= std_logic_vector(to_unsigned(ETH_SMB_DATAREG_L,ADD_WIDTH));
					state <= CSR_WR_DATAL_READ;
				when CSR_WR_DATAL_READ =>
					csr_datain_reg(15 downto 0) <= data_in;
					state <= CSR_WR_WAIT_CPU_LOCK;
				when CSR_WR_WAIT_CPU_LOCK =>
						pio_enable<='1';
						pio_opc_reg <= PIO_OPC_CSR_WR;
						if write_completed = '1' then
							state <= WAIT_PIO_CSR_COMPLETED;
						else
							state <= CSR_WR_WAIT_CPU_LOCK;
						end if;
				when others =>
					state <= IDLE;
				end case;

		end if;

	end process;


end architecture;
