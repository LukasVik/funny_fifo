-- -------------------------------------------------------------------------------------------------
-- Copyright (c) Lukas Vik. All rights reserved.
-- -------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;
use work.funny_fifo_pkg.all;


entity funny_fifo_with_handshake is
  generic (
    -- Generics/parameters have to be uppercase to be set from cocotb.
    -- Unfortunately.
    DATA_WIDTH : positive;
    FIFO_DEPTH : positive
  );
  port (
    write_clock : in std_ulogic;
    write_ready : out std_ulogic := '0';
    write_valid : in std_ulogic;
    write_data : in std_ulogic_vector(data_width - 1 downto 0);
    --
    read_clock : in std_ulogic;
    read_ready : in std_ulogic;
    read_valid : out std_ulogic := '0';
    read_data : out std_ulogic_vector(data_width - 1 downto 0) := (others => '0')
  );
end entity;

architecture a of funny_fifo_with_handshake is

  constant ram_length : positive := fifo_depth + 1;
  constant address_width : natural := clog2(ram_length);

  subtype address_t is u_unsigned(address_width - 1 downto 0);
  constant next_address_lookup : address_lookup_t := get_next_address_lookup(
    address_width=>address_width
  );

  signal write_address, write_address_next, read_address_resync : address_t := (others => '0');
  signal read_address, read_address_next, write_address_resync : address_t := (others => '0');

  type ram_t is array (ram_length - 1 downto 0) of std_ulogic_vector(data_width - 1 downto 0);
  signal ram : ram_t := (others => (others => '0'));

  -- RAM shall be implemented as LUTRAM.
  attribute ram_style : string;
  attribute ram_style of ram : signal is "distributed";

begin

  ------------------------------------------------------------------------------
  assert is_power_of_two(ram_length)
    report "fifo_depth + 1 must be a power of two"
    severity failure;


  ------------------------------------------------------------------------------
  print : process
  begin
    for address_index in next_address_lookup'low to next_address_lookup'high loop
      report (
        "next_address_lookup("
        & integer'image(address_index)
        & ") = "
        & integer'image(to_integer(next_address_lookup(address_index)))
      );
    end loop;
    wait;
  end process;


  ------------------------------------------------------------------------------
  write_address_resync_hamming1_inst : entity work.resync_hamming1
    generic map (
      data_width => write_address'length
    )
    port map (
      input_clock => write_clock,
      input_clock_enable => write_ready and write_valid,
      input_data_next => write_address_next,
      input_data_ff => write_address,
      --
      result_clock => read_clock,
      result_data => write_address_resync
    );


  ------------------------------------------------------------------------------
  read_address_resync_hamming1_inst : entity work.resync_hamming1
    generic map (
      data_width => read_address'length
    )
    port map (
      input_clock => read_clock,
      input_clock_enable => read_ready and read_valid,
      input_data_next => read_address_next,
      input_data_ff => read_address,
      --
      result_clock => write_clock,
      result_data => read_address_resync
    );


  write_address_next <= next_address_lookup(to_integer(write_address));
  read_address_next <= next_address_lookup(to_integer(read_address));

  write_ready <= '1' when (write_address_next /= read_address_resync) else '0';
  read_valid <= '1' when (read_address /= write_address_resync) else '0';


  ------------------------------------------------------------------------------
  ram_process : process
  begin
    wait until rising_edge(write_clock);

    ram(to_integer(write_address)) <= write_data;
  end process;

  read_data <= ram(to_integer(read_address));

end architecture;
