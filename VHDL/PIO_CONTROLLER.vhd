library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.CONSTANTS.all;

use work.LAN9211_CONSTANTS.all;
use work.ETH_SMB_CONSTANTS.all;


entity PIO_CONTROLLER is
	port (
		-- Global signals
		clk					:	in		std_logic;
		rst					:	in		std_logic;
		pio_enable			:	in		std_logic;
		pio_opc				:	in 		std_logic_vector(1 downto 0);
		pio_op_completed	:	out 	std_logic;

		-- CSR unit interface
		csr_addr			:	in		std_logic_vector(7 downto 0);
		csr_datain			:	in		std_logic_vector(31 downto 0);
		csr_dataout 		:	out		std_logic_vector(31 downto 0);

		-- LAN9211 Interface
		eth_rd_n			: 	out 	std_logic;
		eth_wr_n			:	out 	std_logic;
		eth_cs_n			:	out		std_logic;
		eth_a				:	out 	std_logic_vector(7 downto 1);
		eth_d				: 	inout	std_logic_vector(15 downto 0);
		eth_fifo_sel		:	out		std_logic

	);
end entity;

architecture beh of PIO_CONTROLLER is

	type StateType is	(
						-- Global states
						OFF,
						DECODE_OPC,
						PIO_OP_COMPL,

						-- CSR unit states
						PIO_CSR_WAIT_RD_HIGH,
						PIO_CSR_LATCH_RD_HIGH,
						PIO_CSR_WAIT_RD_LOW,
						PIO_CSR_LATCH_RD_LOW,
						PIO_CSR_INC_ADDR,
						PIO_CSR_WAIT_WR_HIGH,
						PIO_CSR_WAIT_DEASS_HIGH,
						PIO_CSR_WAIT_WR_LOW,
						PIO_CSR_WAIT_DEASS_LOW

	);

	signal eth_datain		:	std_logic_vector(15 downto 0);
	signal eth_dataout		:	std_logic_vector(15 downto 0) := (others => '0');
	signal output_enable	:	std_logic := '0';
	signal input_enable		:	std_logic := '0';

	signal state			: StateType := OFF;

	signal opc_reg			: std_logic_vector(1 downto 0);

	signal cycles_counter	: integer := 0;

	signal eth_a_reg		: std_logic_vector(7 downto 0) := (others => '0');

	signal csr_dataout_reg	: std_logic_vector(31 downto 0) := (others => '0');


begin

	-- Inout data buffer
	eth_d <= eth_dataout when (output_enable = '1') else
			 (others => 'Z');
	eth_datain <= eth_d when (input_enable = '1') else
					x"0000";

	-- Address line
	eth_a <= eth_a_reg(7 downto 1);

	csr_dataout <= csr_dataout_reg;




	PIO_CONTROLLER: process(clk)
	begin
		if rst = '1' then
			cycles_counter <= 0;

			opc_reg <= "00";

			eth_rd_n <= '1';
			eth_wr_n <= '1';
			eth_cs_n <= '1';
			eth_dataout <= (others => '0');
			input_enable <= '0';
			output_enable <= '0';

			csr_dataout_reg <= (others => '0');

			pio_op_completed <= '0';

			eth_fifo_sel <= '0';

			state <= OFF;

		elsif rising_edge(clk) then
			-- Defaults
			cycles_counter <= 0;
			eth_rd_n <= '1';
			eth_wr_n <= '1';
			eth_cs_n <= '1';
			input_enable <= '0';
			output_enable <= '0';
			pio_op_completed <= '0';
			eth_fifo_sel <= '0';


			case state is
				-----------------------------------------------------------------------------
				-- Global states

				when OFF =>
					if pio_enable = '1' then
						opc_reg <= pio_opc;
						state <= DECODE_OPC;
					else
						state <= OFF;
					end if;

				when DECODE_OPC =>
					case opc_reg is
						when PIO_OPC_CSR_RD =>
							eth_a_reg <= csr_addr;
							state <= PIO_CSR_WAIT_RD_LOW;
						when PIO_OPC_CSR_WR =>
							eth_a_reg <= csr_addr;
							state <= PIO_CSR_WAIT_WR_LOW;
						when others =>
							state <= PIO_OP_COMPL;
						end case;

				when PIO_OP_COMPL =>
					pio_op_completed <= '1';
					if pio_enable = '1' then
						state <= PIO_OP_COMPL;
					else
						state <= OFF;
					end if;

				---------------------------------------------------------------------------
				-- CSR Read states

				when PIO_CSR_WAIT_RD_LOW =>
					eth_rd_n <= '0';
					eth_cs_n <= '0';
					if cycles_counter < rd_Tcsdv_WAIT_CYCLES  then
						cycles_counter <= cycles_counter +1;
						state <= PIO_CSR_WAIT_RD_LOW;
					else
						input_enable <= '1';
						state <= PIO_CSR_LATCH_RD_LOW;
					end if;
				when PIO_CSR_LATCH_RD_LOW =>
					eth_rd_n <= '0';
					eth_cs_n <= '0';
					input_enable <= '1';
					csr_dataout_reg(15 downto 0) <= eth_datain;
					eth_a_reg(1) <= '1';
					cycles_counter <= 0;
					state <= PIO_CSR_WAIT_RD_HIGH;
				when PIO_CSR_WAIT_RD_HIGH =>
					eth_rd_n <= '0';
					eth_cs_n <= '0';
					if cycles_counter < rd_Tadv_WAIT_CYCLES then
						cycles_counter <= cycles_counter +1;
						state <= PIO_CSR_WAIT_RD_HIGH;
					else
						input_enable <= '1';
						state <= PIO_CSR_LATCH_RD_HIGH;
					end if;
				when PIO_CSR_LATCH_RD_HIGH =>
					eth_rd_n <= '0';
					eth_cs_n <= '0';
					input_enable <= '1';
					csr_dataout_reg(31 downto 16) <= eth_datain;
					state <= PIO_OP_COMPL;

				---------------------------------------------------------------------------
				-- CSR Write states
				when PIO_CSR_WAIT_WR_LOW =>
					eth_wr_n <= '0';
					eth_cs_n <= '0';
					eth_dataout <= csr_datain(15 downto 0);
					output_enable <= '1';
					if cycles_counter < wr_Tcsl_WAIT_CYCLES then
						cycles_counter <= cycles_counter +1;
					else
						cycles_counter <= 0;
						state <= PIO_CSR_WAIT_DEASS_LOW;
					end if;
				when PIO_CSR_WAIT_DEASS_LOW =>
					eth_wr_n <= '1';
					eth_cs_n <= '1';
					eth_dataout <= csr_datain(15 downto 0);
					output_enable <= '1';
					if cycles_counter < wr_Tcsh_WAIT_CYCLES then
						cycles_counter <= cycles_counter +1;
						state <= PIO_CSR_WAIT_DEASS_LOW;
					else
						output_enable <= '0';
						eth_dataout <= csr_datain(31 downto 16);
						cycles_counter <= 0;
						state <= PIO_CSR_INC_ADDR;
					end if;

				-- Address and data setup
				when PIO_CSR_INC_ADDR =>
					eth_wr_n <= '1';
					eth_cs_n <= '1';
					eth_a_reg(1) <= '1';
					eth_dataout <= csr_datain(31 downto 16);
					output_enable <= '1';
					cycles_counter <= 0;
					state <= PIO_CSR_WAIT_WR_HIGH;
				when PIO_CSR_WAIT_WR_HIGH =>
					eth_wr_n <= '0';
					eth_cs_n <= '0';
					eth_dataout <= csr_datain(31 downto 16);
					output_enable <= '1';
					if cycles_counter < wr_Tcsl_WAIT_CYCLES then
						cycles_counter <= cycles_counter +1;
						state <= PIO_CSR_WAIT_WR_HIGH;
					else
						cycles_counter <= 0;
						state <= PIO_CSR_WAIT_DEASS_HIGH;
					end if;
				when PIO_CSR_WAIT_DEASS_HIGH =>
					eth_wr_n <= '1';
					eth_cs_n <= '1';
					eth_dataout <= csr_datain(31 downto 16);
					output_enable <= '1';
					if cycles_counter < wr_Tcsh_WAIT_CYCLES then
						cycles_counter <= cycles_counter+1;
					else
						state <= PIO_OP_COMPL;
					end if;

			end case;

		end if;

	end process;

end architecture;
