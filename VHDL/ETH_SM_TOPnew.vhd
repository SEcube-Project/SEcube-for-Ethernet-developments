library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.CONSTANTS.all;

use work.LAN9211_CONSTANTS.all;
use work.ETH_SMB_CONSTANTS.all;


entity ETH_SM_TOPnew is
	port(
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

			--LAN9211 interface
			eth_rstn				: out std_logic;
			eth_d					: inout std_logic_vector(LAN9211_DATA_WIDTH-1 downto 0);
			eth_a					: out std_logic_vector(LAN9211_ADDR_WIDTH downto 1);
			eth_rd_n				: out std_logic;
			eth_wr_n				: out std_logic;
			eth_cs_n				: out std_logic;
			eth_irq					: in std_logic;
			eth_fifo_sel			: out std_logic;
			--eth_pme					: in std_logic;

			-- DEBUG
			leds_out			: out std_logic_vector(7 downto 0)
		);

end ETH_SM_TOPnew;

architecture struct of ETH_SM_TOPnew is

	component TX_RAM
		port (WrAddress: in  std_logic_vector(9 downto 0);
			RdAddress: in  std_logic_vector(9 downto 0);
			Data: in  std_logic_vector(15 downto 0); WE: in  std_logic;
			RdClock: in  std_logic; RdClockEn: in  std_logic;
			Reset: in  std_logic; WrClock: in  std_logic;
			WrClockEn: in  std_logic; Q: out  std_logic_vector(15 downto 0));
	end component;

	----	signals between MAIN and PIO	---------------
	signal main_pio_csr_addr : std_logic_vector(LAN9211_ADDR_WIDTH downto 0);
	signal main_pio_csr_datain : std_logic_vector(2*LAN9211_DATA_WIDTH-1 downto 0);
	signal main_pio_csr_dataout : std_logic_vector(2*LAN9211_DATA_WIDTH-1 downto 0);
	signal main_arbiter_done : std_logic;
	signal main_arbiter_grant : std_logic;
	signal main_arbiter_csr_rd_req : std_logic;
	signal main_arbiter_csr_wr_req : std_logic;

	signal s_pio_op_completed : std_logic ;
	signal s_pio_enable: std_logic ;
	signal s_pio_opcode: std_logic_vector(PIO_OPC_SIZE-1 downto 0);
--	signal tx_size :std_logic_vector(TX_MAX_CNT_WIDTH-1 downto 0);
	signal eth_rstn_s:std_logic;

	--signal eth_rstn_s : std_logic := '1';
	signal eth_int : std_logic ;

	signal tmp_leds : std_logic_vector(7 downto 0) := (others => '0');
	signal tmp2_leds : std_logic_vector(7 downto 0) := (others => '1');
	signal interrupt_s : std_logic := '0';
begin
	eth_rstn<=eth_rstn_s;
	error <= '0';
	interrupt <= interrupt_s;


--	leds_out <= leds_out_reg;
	MAIN_CONTR: entity work.MAIN_CONTROLLER
	port map (
		clock => clock,
		reset => reset,
		data_in => data_in,
		opcode 	=> opcode,
		enable 	=> enable,
		ack => ack,
		interrupt_polling	=> interrupt_polling,
		data_out => data_out,
		buffer_enable => buffer_enable,
		address => address,
		rw =>	rw,
		interrupt => interrupt_s,
		write_completed => write_completed,
		read_completed => read_completed,
		eth_rstn =>eth_rstn_s,

		pio_op_completed=>s_pio_op_completed,
		pio_enable=>s_pio_enable,
		pio_opc=>s_pio_opcode,

		pio_csr_addr => main_pio_csr_addr,
		pio_csr_datain => main_pio_csr_datain,
		pio_csr_dataout => main_pio_csr_dataout,

		leds =>leds_out
	);
	PIO_CONTR:entity work.PIO_CONTROLLER
		port map (
			clk => clock,
			rst => reset,
			pio_enable => s_pio_enable,
			pio_opc => s_pio_opcode,
			pio_op_completed => s_pio_op_completed,
				-- CSR unit interface
			csr_addr =>	main_pio_csr_addr,
			csr_datain => main_pio_csr_datain,
			csr_dataout => main_pio_csr_dataout,

				-- LAN9211 Interface
			eth_rd_n => eth_rd_n,
			eth_wr_n => eth_wr_n,
			eth_cs_n =>	eth_cs_n,
			eth_a	=> eth_a,
			eth_d	=> eth_d,
			eth_fifo_sel=> eth_fifo_sel
		);

end struct;
