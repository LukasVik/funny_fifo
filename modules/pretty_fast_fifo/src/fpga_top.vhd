-- -------------------------------------------------------------------------------------------------
-- Copyright (c) Lukas Vik. All rights reserved.
-- -------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity fpga_top is
  generic (
    data_width : positive;
    fifo_depth : positive;
    use_ready : boolean
  );
  port (
    write_clock : in std_ulogic;
    write_ready : out std_ulogic := '0';
    write_valid : in std_ulogic;
    write_data : in std_ulogic_vector(data_width-1 downto 0);
    --
    read_clock : in std_ulogic;
    read_ready : in std_ulogic;
    read_data : out std_ulogic := '0'
  );
end entity;

architecture a of fpga_top is

  -- Add FF shift registers between the FPGA pins and our FIFO design,
  -- so the placer has complete freedom to place the FIFO.
  -- I.e. pin timing shall not limit our max frequency.
  constant shift_register_length : positive := 32;

  signal write_ready_shift, write_valid_shift, read_ready_shift, read_valid_shift :
    std_ulogic_vector(shift_register_length - 1 downto 0) := (others => '0');
  signal write_ready_int, write_valid_int, read_ready_int, read_valid_int : std_ulogic := '0';

  type data_shift_t is array (shift_register_length - 1 downto 0) of std_ulogic_vector(
    data_width - 1 downto 0
  );
  signal write_data_shift, read_data_shift : data_shift_t := (others => (others => '0'));
  signal write_data_int, read_data_int : std_ulogic_vector(data_width-1 downto 0) := (
    others => '0'
  );

  attribute shreg_extract : string;

  attribute shreg_extract of write_ready_shift : signal is "no";
  attribute shreg_extract of write_valid_shift : signal is "no";
  attribute shreg_extract of read_ready_shift : signal is "no";
  attribute shreg_extract of read_valid_shift : signal is "no";

  attribute shreg_extract of write_data_shift : signal is "yes";
  attribute shreg_extract of read_data_shift : signal is "yes";

  attribute dont_touch : string;

  attribute dont_touch of write_ready_shift : signal is "true";
  attribute dont_touch of write_valid_shift : signal is "true";
  attribute dont_touch of read_ready_shift : signal is "true";
  attribute dont_touch of read_valid_shift : signal is "true";

  attribute dont_touch of write_ready_int : signal is "true";
  attribute dont_touch of write_valid_int : signal is "true";
  attribute dont_touch of read_ready_int : signal is "true";
  attribute dont_touch of read_valid_int : signal is "true";

  attribute dont_touch of write_data_shift : signal is "true";
  attribute dont_touch of read_data_shift : signal is "true";

  attribute dont_touch of write_data_int : signal is "true";
  attribute dont_touch of read_data_int : signal is "true";

begin

  ------------------------------------------------------------------------------
  write_shift_register : process
  begin
    wait until rising_edge(write_clock);

    write_ready_shift <= write_ready_int & write_ready_shift(write_ready_shift'high downto 1);
    write_valid_shift <= write_valid & write_valid_shift(write_valid_shift'high downto 1);
    write_data_shift <= write_data & write_data_shift(write_data_shift'high downto 1);

    read_ready_shift <= read_ready & read_ready_shift(read_ready_shift'high downto 1);
    read_valid_shift <= read_valid_int & read_valid_shift(read_valid_shift'high downto 1);
    read_data_shift <= read_data_int & read_data_shift(read_data_shift'high downto 1);
  end process;

  write_ready <= write_ready_shift(0);
  write_valid_int <= write_valid_shift(0);
  write_data_int <= write_data_shift(0);

  read_ready_int <= read_ready_shift(0);
  -- Reduce to just one bit so we don't have to have list so many package pins.
  read_data <= (xor read_data_shift(0)) xor read_valid_shift(0);


  ------------------------------------------------------------------------------
  select_ready_or_not : if use_ready generate

    ------------------------------------------------------------------------------
    pretty_fast_fifo_inst : entity work.pretty_fast_fifo
      generic map (
        data_width => data_width,
        fifo_depth => fifo_depth
      )
      port map (
        write_clock => write_clock,
        write_ready => write_ready_int,
        write_valid => write_valid_int,
        write_data => write_data_int,
        --
        read_clock => read_clock,
        read_ready => read_ready_int,
        read_valid => read_valid_int,
        read_data => read_data_int
      );


  ------------------------------------------------------------------------------
  else generate

    ------------------------------------------------------------------------------
    pretty_fast_fifo_no_ready_inst : entity work.pretty_fast_fifo_no_ready
      generic map (
        data_width => data_width,
        fifo_depth => fifo_depth
      )
      port map (
        write_clock => write_clock,
        write_valid => write_valid_int,
        write_data => write_data_int,
        --
        read_clock => read_clock,
        read_valid => read_valid_int,
        read_data => read_data_int
      );

  end generate;

end architecture;
