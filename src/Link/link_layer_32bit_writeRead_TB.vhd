-- Hannah D. Mohr
-- 04/20/2017
-- This test bench runs the Link Layer through a basic write followed by a basic read of the same data (encoded) with the CRC appended.
-- This test is under optimal condition, where there are no pauses, holds, or errors interrupting the data
-- The expected outcome of this test bench is that the read will move into states GoodCRC and GoodEnd, and the data held in arrays data_to_write_TB and
-- data_read_TB will be equal. The latter condition is reported and used to determine if the test is successful or failed. 

library ieee;
use ieee.std_logic_1164.all;
use work.sata_defines.all;
use ieee.numeric_std.all;

entity link_layer_32bit_TB is
end entity;

architecture link_layer_32bit_TB_arch of link_layer_32bit_TB is

	type data_array is array (6 downto 0) of std_logic_vector(31 downto 0);
	signal  data_to_write_TB	: data_array := (x"00000000",x"00000004",x"00000003",x"00000002",x"00000001",x"0000000A", x"00000039");		-- ignore the last value (placeholder for crc)
	signal 	data_written_TB		: data_array; 
	signal	data_read_TB		: data_array; 
	constant t_clk_per : time := 50 ns;

  component link_layer_32bit
   port(-- Input
			clk						:	in std_logic;
			rst_n					:	in std_logic;

			--Interface with Transport Layer
			trans_status_in	:	in std_logic_vector(7 downto 0);
			trans_status_out 	:	out std_logic_vector(7 downto 0);
			tx_data_in		:	in std_logic_vector(31 downto 0);
			rx_data_out		:	out std_logic_vector(31 downto 0);

			--Interface with Physical Layer
			tx_data_out			:	out std_logic_vector(31 downto 0);
			rx_data_in		:	in std_logic_vector(31 downto 0);
			phy_status_in		:	in std_logic_vector(3 downto 0);
			phy_status_out		:	out std_logic_vector(1 downto 0);		-- [primitive, clear status signals]
			perform_init	:	out std_logic);
  end component;


 -- Test bench signals
  signal clk_TB   				: std_logic;
  signal rst_n_TB 				: std_logic;

  signal trans_status_in_TB  	: std_logic_vector(7 downto 0);
  signal trans_status_out_TB  	: std_logic_vector(7 downto 0);
  signal tx_data_in_TB			: std_logic_vector(31 downto 0);
  signal rx_data_out_TB			: std_logic_vector(31 downto 0);

  signal tx_data_out_TB			: std_logic_vector(31 downto 0);
  signal rx_data_in_TB			: std_logic_vector(31 downto 0);
  signal phy_status_in_TB		: std_logic_vector(3 downto 0);
  signal phy_status_out_TB		: std_logic_vector(1 downto 0);	


begin

  DUT1 : link_layer_32bit port map (
			-- Input
			clk						=> clk_TB,
			rst_n					=> rst_n_TB,

			--Interface with Transport Layer
			trans_status_in 	=> trans_status_in_TB,
			trans_status_out	=> trans_status_out_TB,
			tx_data_in		=> tx_data_in_TB,
			rx_data_out		=> rx_data_out_TB,

			--Interface with Physical Layer
			tx_data_out			=> tx_data_out_TB,
			rx_data_in		=> rx_data_in_TB,
			phy_status_in		=> phy_status_in_TB,
			phy_status_out		=> phy_status_out_TB);

-----------------------------------------------
      CLOCK_STIM : process
       begin
          clk_TB <= '0'; wait for 0.5*t_clk_per;
          clk_TB <= '1'; wait for 0.5*t_clk_per;
       end process;
-----------------------------------------------
      RESET_STIM : process
       begin
          rst_n_TB <= '0'; wait for 1.5*t_clk_per;
          rst_n_TB <= '1'; wait;
       end process;
-----------------------------------------------
	  DIN_STIM : process
       begin
			-- reset
			trans_status_in_TB 						<= "00000000";
			phy_status_in_TB 						<= "0000";
			rx_data_in_TB 							<= x"00000000";
			tx_data_in_TB 							<= x"00000000";
			data_read_TB							<= (x"00000000",x"AAAAAAA0", x"AAAAAAA1",x"AAAAAAA2",x"AAAAAAA3",x"AAAAAAA4",x"AAAAAAA5");
			data_written_TB							<= (x"00000000",x"AAAAAAA0", x"AAAAAAA1",x"AAAAAAA2",x"AAAAAAA3",x"AAAAAAA4",x"AAAAAAA5");

			wait for 3.5*t_clk_per; 											-- wait for reset

			-- initialize
			phy_status_in_TB(c_l_phyrdy) 			<= '1';						-- PHYRDY goes high --> the communication channel has been established
			wait for 3.0*t_clk_per; 											-- wait for the Link Layer to transition through SendAlign and Idle states
			
			-- start write
			trans_status_in_TB(c_l_transmit_request)<= '1';						-- Transport Request
			tx_data_in_TB							<= data_to_write_TB(0);		-- FIS header
			wait for 4.0*t_clk_per;												-- wait for response from device
			
			rx_data_in_TB							<= R_RDYp;					-- device is ready
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			wait for 2.0*t_clk_per;	
			
			rx_data_in_TB							<= CONTp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			
			tx_data_in_TB							<= data_to_write_TB(1);		-- send data
			wait for 1.0*t_clk_per;
			
			rx_data_in_TB							<= R_IPp;					-- device is receiving data
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			
			tx_data_in_TB							<= data_to_write_TB(2);		-- send data
			--data_written_TB(0)						<= tx_data_out_TB;
			wait for 1.0*t_clk_per;
			
			tx_data_in_TB							<= data_to_write_TB(3);		-- send data
			data_written_TB(0)						<= tx_data_out_TB;
			wait for 1.0*t_clk_per;
			
			tx_data_in_TB							<= data_to_write_TB(4);		-- send data
			data_written_TB(1)						<= tx_data_out_TB;
			wait for 1.0*t_clk_per;	
			
			tx_data_in_TB							<= data_to_write_TB(5);		-- send data
			data_written_TB(2)						<= tx_data_out_TB;
			wait for 1.0*t_clk_per;	
			
			trans_status_in_TB( c_l_transmit_request) 		<= '0';				-- data done
			data_written_TB(3)						<= tx_data_out_TB;
			-- wait for CRC
			wait for 1.0*t_clk_per;
			data_written_TB(4)						<= tx_data_out_TB;
			wait for 1.0*t_clk_per;
			data_written_TB(5)						<= tx_data_out_TB;
			wait for 1.0*t_clk_per;
			data_written_TB(6)						<= tx_data_out_TB;
			-- Physical received data
			rx_data_in_TB							<= R_OKp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			wait for 2.0*t_clk_per;
			rx_data_in_TB							<= CONTp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			wait for 1.0*t_clk_per;
			rx_data_in_TB							<= x"A0A0A0A0";
			phy_status_in_TB(c_l_primitive_in) 		<= '0';
			rx_data_in_TB							<= SYNCp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			wait for 2.0*t_clk_per;
			rx_data_in_TB							<= CONTp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			wait for 1.0*t_clk_per;
			rx_data_in_TB							<= x"A0A0A0A0";
			phy_status_in_TB(c_l_primitive_in) 		<= '0';
			wait for 5.0*t_clk_per;

			---------------------------------------------------------
			
			-- start read
			rx_data_in_TB							<= X_RDYp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			trans_status_in_TB(c_l_fifo_ready)	 	<= '1';
			wait for 2.0*t_clk_per;
			rx_data_in_TB							<= CONTp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			wait for 1.0*t_clk_per;
			rx_data_in_TB							<= x"A0A0A0A0";
			phy_status_in_TB(c_l_primitive_in) 		<= '0';
			wait for 2.0*t_clk_per;
			
			-- send data
			rx_data_in_TB							<= SOFp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			wait for 1.0*t_clk_per;
			phy_status_in_TB(c_l_primitive_in) 		<= '0';
			rx_data_in_TB							<= data_written_TB(0);
			wait for 1.0*t_clk_per;
			rx_data_in_TB							<= data_written_TB(1);
			wait for 1.0*t_clk_per;
			--data_read_TB(0)							<= rx_data_out_TB;
			rx_data_in_TB							<= data_written_TB(2);
			wait for 1.0*t_clk_per;
			data_read_TB(0)							<= rx_data_out_TB;
			rx_data_in_TB							<= data_written_TB(3);
			wait for 1.0*t_clk_per;
			data_read_TB(1)							<= rx_data_out_TB;
			phy_status_in_TB(c_l_primitive_in) 		<= '0';
			rx_data_in_TB							<= data_written_TB(4);
			wait for 1.0*t_clk_per;
			data_read_TB(2)							<= rx_data_out_TB;
			rx_data_in_TB							<= data_written_TB(5);
			wait for 1.0*t_clk_per;
			data_read_TB(3)							<= rx_data_out_TB;
			rx_data_in_TB							<= data_written_TB(6);	--crc
			wait for 1.0*t_clk_per;
			data_read_TB(4)							<= rx_data_out_TB;
			rx_data_in_TB							<= EOFp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			wait for 1.0*t_clk_per;
			data_read_TB(5)							<= rx_data_out_TB;
			rx_data_in_TB							<= WTRMp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			wait for 2.0*t_clk_per;
			rx_data_in_TB							<= CONTp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			wait for 1.0*t_clk_per;
			rx_data_in_TB							<= x"A0A0A0A0";
			phy_status_in_TB(c_l_primitive_in) 		<= '0';
			wait for 2.0*t_clk_per;
			rx_data_in_TB							<= SYNCp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			wait for 2.0*t_clk_per;
			rx_data_in_TB							<= CONTp;
			phy_status_in_TB(c_l_primitive_in) 		<= '1';
			wait for 1.0*t_clk_per;
			rx_data_in_TB							<= x"A0A0A0A0";
			phy_status_in_TB(c_l_primitive_in) 		<= '0';
			
			-----------------------------------------
			
			-- reporting 
			
			if (data_to_write_TB(5 downto 0) = data_read_TB(5 downto 0)) then 				-- unscrambled read data matches original write data
				report "The data from the read was equal to the data written. Test SUCCESSFUL." severity NOTE;
			else 
				report "The data from the read was NOT equal to the data written. Test FAILED." severity ERROR;
			end if; 

            wait;
       end process;

end architecture;

