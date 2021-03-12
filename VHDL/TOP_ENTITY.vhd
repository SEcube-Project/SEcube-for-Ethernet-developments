library ieee;
use ieee.std_logic_1164.all;
use work.LAN9211_CONSTANTS.all;
use work.ETH_SMB_CONSTANTS.all;
use work.CONSTANTS.all;

--IMPORTANT: The number of IPs must be written in the file CONSTANTS.vhd. The IPs core must be then connected at the end of this file
entity TOP_ENTITY is
	generic (
		ADDSET : integer := 2;
		DATAST : integer := 2
	);
	port(
			-- Signals between CPU and FPGA
			cpu_fpga_bus_a		: in std_logic_vector(ADD_WIDTH-1 downto 0);
			cpu_fpga_bus_d		: inout std_logic_vector(DATA_WIDTH-1 downto 0);
			cpu_fpga_bus_noe    : in std_logic;
			cpu_fpga_bus_nwe    : in std_logic;
			cpu_fpga_bus_ne1    : in std_logic;
			cpu_fpga_clk		: in std_logic;
			cpu_fpga_int_n      : out std_logic;
			cpu_fpga_rst		: in std_logic;


			-- Signals between FPGA and LAN9211
			fpga_eth_rstn				: out std_logic;
			fpga_eth_d					: inout std_logic_vector(LAN9211_DATA_WIDTH-1 downto 0);
			fpga_eth_a					: out std_logic_vector(LAN9211_ADDR_WIDTH downto 1);
			fpga_eth_rd_n				: out std_logic;
			fpga_eth_wr_n				: out std_logic;
			fpga_eth_cs_n				: out std_logic;
			fpga_eth_irq				: in std_logic;
			fpga_eth_fifo_sel			: out std_logic;
			--fpga_eth_pme				: in std_logic;

			-- DEBUG
			fpga_gpio_leds		: out std_logic_vector(7 downto 0)
			--fpga_gpio_btns	: in std_logic_vector(1 downto 0);
			--fpga_gpio			: out std_logic_vector(5 downto 0)
			);
end entity TOP_ENTITY;

architecture STRUCTURAL of TOP_ENTITY is

	--Signals between the buffer and the ip manager
	signal	row_0			  	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal	ipm_to_buf_data		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal	buf_to_ipm_data		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal	ipm_addr     		: std_logic_vector(ADD_WIDTH-1 downto 0);
	signal	ipm_rw				: std_logic;
	signal	ipm_buf_enable		: std_logic;
	signal  cpu_read_completed 	: std_logic;
	signal  cpu_write_completed : std_logic;
	--Signals between the IP manager and the various IP cores
	signal	ip_to_ipm_data      	 : data_array;
	signal	ipm_to_ip_data    		 : data_array;
	signal	addr_ip         		 : addr_array;
	signal	opcode_ip	    		 : opcode_array;
	signal	int_pol_ip				 : std_logic_vector(NUM_IPS-1 downto 0);
	signal	rw_ip		    		 : std_logic_vector(NUM_IPS-1 downto 0);
	signal	buf_enable_ip      		 : std_logic_vector(NUM_IPS-1 downto 0);
	signal  enable_ip				 : std_logic_vector(NUM_IPS-1 downto 0);
	signal	ack_ip         			 : std_logic_vector(NUM_IPS-1 downto 0);
	signal	interrupt_ip   			 : std_logic_vector(NUM_IPS-1 downto 0);
	signal	error_ip   				 : std_logic_vector(NUM_IPS-1 downto 0);
	signal 	cpu_read_completed_ip    : std_logic_vector(NUM_IPS-1 downto 0);
	signal 	cpu_write_completed_ip   : std_logic_vector(NUM_IPS-1 downto 0);
	signal eth_rstn_s	:std_logic;

	signal fpga_leds_s				: std_logic_vector(7 downto 0);
	signal fpga_eth_irq_s			: std_logic ;
begin
	fpga_eth_rstn <=eth_rstn_s;
	fpga_gpio_leds <= fpga_leds_s;
	fpga_eth_irq_s <= fpga_eth_irq;
	--fpga_gpio <= (others => '0');
	data_buff: entity work.DATA_BUFFER
		generic map(
			ADDSET => ADDSET,
			DATAST => DATAST
		)
		port map(
			clock               => cpu_fpga_clk,
			reset               => cpu_fpga_rst,
			row_0               => row_0,
			cpu_data            => cpu_fpga_bus_d,
			cpu_addr            => cpu_fpga_bus_a,
			cpu_noe             => cpu_fpga_bus_noe,
			cpu_nwe             => cpu_fpga_bus_nwe,
			cpu_ne1             => cpu_fpga_bus_ne1,
			ipm_data_in         => ipm_to_buf_data,
			ipm_data_out        => buf_to_ipm_data,
			ipm_addr            => ipm_addr,
			ipm_rw              => ipm_rw,
			ipm_enable          => ipm_buf_enable,
			cpu_read_completed  => cpu_read_completed,
			cpu_write_completed => cpu_write_completed
		);

	ip_man: entity work.IP_MANAGER
		port map(
			clock                  => cpu_fpga_clk,
			reset                  => cpu_fpga_rst,
			interrupt              => cpu_fpga_int_n,
			ne1 				   => cpu_fpga_bus_ne1,
			buf_data_out           => ipm_to_buf_data,
			buf_data_in            => buf_to_ipm_data,
			buf_addr               => ipm_addr,
			buf_rw                 => ipm_rw,
			buf_enable             => ipm_buf_enable,
			row_0                  => row_0,
			cpu_read_completed     => cpu_read_completed,
			cpu_write_completed    => cpu_write_completed,
			addr_ip                => addr_ip,
			data_in_ip             => ip_to_ipm_data,
			data_out_ip            => ipm_to_ip_data,
			opcode_ip              => opcode_ip,
			int_pol_ip             => int_pol_ip,
			rw_ip                  => rw_ip,
			buf_enable_ip          => buf_enable_ip,
			enable_ip              => enable_ip,
			ack_ip                 => ack_ip,
			interrupt_ip           => interrupt_ip,
			error_ip               => error_ip,
			cpu_read_completed_ip  => cpu_read_completed_ip,
			cpu_write_completed_ip => cpu_write_completed_ip
		);



	-- IMPORTANT: Instantiate here the IP cores.
	-- The port map is the same for every IP, only the indexes must be changed.

	-- SYNTHESIS
	----------------------------------------------------------------------------
	eth_smb : entity work.ETH_SM_TOPnew
		port map(
			clock             => cpu_fpga_clk,
			reset             => cpu_fpga_rst,
			data_in           => ipm_to_ip_data(ETH_SMB_ID),
			opcode            => opcode_ip(ETH_SMB_ID),
			enable            => enable_ip(ETH_SMB_ID),
			ack               => ack_ip(ETH_SMB_ID),
			interrupt_polling => int_pol_ip(ETH_SMB_ID),
			data_out          => ip_to_ipm_data(ETH_SMB_ID),
			buffer_enable     => buf_enable_ip(ETH_SMB_ID),
			address           => addr_ip(ETH_SMB_ID),
			rw                => rw_ip(ETH_SMB_ID),
			interrupt         => interrupt_ip(ETH_SMB_ID),
			error             => error_ip(ETH_SMB_ID),
			write_completed   => cpu_write_completed_ip(ETH_SMB_ID),
			read_completed    => cpu_read_completed_ip(ETH_SMB_ID),
			eth_rstn		  => eth_rstn_s,
			eth_d			  => fpga_eth_d,
			eth_a			  => fpga_eth_a,
			eth_rd_n	      => fpga_eth_rd_n,
			eth_wr_n		  => fpga_eth_wr_n,
			eth_cs_n		  => fpga_eth_cs_n,
			eth_irq			  => fpga_eth_irq_s,
			eth_fifo_sel	  => fpga_eth_fifo_sel
		);
		
		ip_blinker : entity work.IP_BLINKER
		port map(
			clock             => cpu_fpga_clk,
			reset             => cpu_fpga_rst,
			data_in           => ipm_to_ip_data(IP_BLINKER_ID),
			opcode            => opcode_ip(IP_BLINKER_ID),
			enable            => enable_ip(IP_BLINKER_ID),
			ack               => ack_ip(IP_BLINKER_ID),
			interrupt_polling => int_pol_ip(IP_BLINKER_ID),
			data_out          => ip_to_ipm_data(IP_BLINKER_ID),
			buffer_enable     => buf_enable_ip(IP_BLINKER_ID),
			address           => addr_ip(IP_BLINKER_ID),
			rw                => rw_ip(IP_BLINKER_ID),
			interrupt         => interrupt_ip(IP_BLINKER_ID),
			error             => error_ip(IP_BLINKER_ID),
			write_completed   => cpu_write_completed_ip(IP_BLINKER_ID),
			read_completed    => cpu_read_completed_ip(IP_BLINKER_ID),
			-- DEBUG
			leds			=> fpga_leds_s		
			);	

end architecture;
