-- -------------------------------------------------------------------------------------------------
-- Copyright (c) Lukas Vik. All rights reserved.
-- -------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


package math_pkg is

  function clog2(value : positive) return natural;

  function is_power_of_two(value : positive) return boolean;

  function to_gray(value : u_unsigned) return std_ulogic_vector;
  function from_gray(code : std_ulogic_vector) return u_unsigned;

  function hamming_distance(data1, data2 : std_ulogic_vector) return natural;

end package;

package body math_pkg is

  function clog2(value : positive) return natural is
  begin
    return natural(ceil(log2(real(value))));
  end function;

  function is_power_of_two(value : positive) return boolean is
  begin
    return 2**clog2(value) = value;
  end function;

  function to_gray(value : u_unsigned) return std_ulogic_vector is
    variable value_slv, result : std_ulogic_vector(value'range) := (others => '0');
  begin
    value_slv := std_ulogic_vector(value);
    result := value_slv xor "0" & value_slv(value_slv'high downto 1);

    return result;
  end function;

  function from_gray(code : std_ulogic_vector) return u_unsigned is
    variable result : u_unsigned(code'range) := (others => '0');
  begin
    result(code'high) := code(code'high);
    for bit_num in code'high - 1 downto 0 loop
      result(bit_num) := result(bit_num + 1) xor code(bit_num);
    end loop;

    return result;
  end function;

  function hamming_distance(data1, data2 : std_ulogic_vector) return natural is
    constant xor_value : std_ulogic_vector(data1'range) := data1 xor data2;
    variable result : natural range 0 to data1'length := 0;
  begin
    assert data1'length = data2'length report "Arguments must be of equal length" severity failure;

    for value_index in xor_value'range loop
      if xor_value(value_index) then
        result := result + 1;
      end if;
    end loop;

    return result;
  end function;

end package body;


-- -------------------------------------------------------------------------------------------------
-- Copyright (c) Lukas Vik. All rights reserved.
-- -------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;


entity resync_hamming1 is
  generic (
    data_width : positive
  );
  port (
    input_clock : in std_ulogic;
    input_clock_enable : in std_ulogic := '1';
    input_data_next : in u_unsigned(data_width-1 downto 0);
    input_data_ff : out u_unsigned(data_width-1 downto 0) := (others => '0');
    --
    result_clock : in std_ulogic;
    result_data : out u_unsigned(data_width-1 downto 0) := (others => '0')
  );
end entity;

architecture a of resync_hamming1 is

  signal input_data_sampled, result_data_m1, result_data_m0 : u_unsigned(
    data_width-1 downto 0
  ) := (others => '0');

  -- Constraints are applied to these.
  -- Make sure nothing is optimized away or moved.
  attribute dont_touch : string;
  attribute dont_touch of input_data_sampled : signal is "true";

  -- Ensure FFs are not optimized/modified, and placed in the same slice to minimize MTBF.
  attribute async_reg : string;
  attribute async_reg of result_data_m0 : signal is "true";
  attribute async_reg of result_data_m1 : signal is "true";

begin

  ------------------------------------------------------------------------------
  input_process : process
  begin
    wait until rising_edge(input_clock);

    assert (
        hamming_distance(
          std_ulogic_vector(input_data_sampled), std_ulogic_vector(input_data_next)
        ) <= 1
        or input_clock_enable = '0'
    )
      report "Input data changed by more than 1 bit between clock edges"
      severity failure;

    if input_clock_enable then
      input_data_sampled <= input_data_next;
    end if;
  end process;

  input_data_ff <= input_data_sampled;


  ------------------------------------------------------------------------------
  result_process : process
  begin
    wait until rising_edge(result_clock);

    -- CDC path into async_reg chain.
    result_data_m0 <= result_data_m1;
    result_data_m1 <= input_data_sampled;
  end process;

  result_data <= result_data_m0;

end architecture;


-- -------------------------------------------------------------------------------------------------
-- Copyright (c) Lukas Vik. All rights reserved.
-- -------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.math_pkg.all;


entity pretty_fast_fifo is
  generic (
    -- Generics/parameters have to be uppercase to be set from cocotb.
    -- Unfortunately.
    DATA_WIDTH : positive := 16;
    FIFO_DEPTH : positive := 15
  );
  port (
    write_clock : in std_ulogic;
    write_ready : out std_ulogic := '0';
    write_valid : in std_ulogic;
    write_data : in std_ulogic_vector(data_width-1 downto 0);
    --
    read_clock : in std_ulogic;
    read_ready : in std_ulogic;
    read_valid : out std_ulogic := '0';
    read_data : out std_ulogic_vector(data_width-1 downto 0) := (others => '0')
  );
end entity;

architecture a of pretty_fast_fifo is

  constant ram_length : positive := fifo_depth + 1;
  constant address_width : natural := clog2(ram_length);

  subtype address_t is u_unsigned(address_width - 1 downto 0);
  type address_lookup_t is array (ram_length - 1 downto 0) of address_t;

  function get_next_address_lookup return address_lookup_t is
    variable result : address_lookup_t := (others => (others => '0'));
    variable this_address, next_address : address_t := (others => '0');
  begin
    while true loop
      this_address := next_address;
      next_address := address_t(to_gray(from_gray(std_ulogic_vector(this_address)) + 1));

      result(to_integer(this_address)) := next_address;

      if next_address = 0 then
        -- We are pointing back to the start address, meaning we've gone through all addresses.
        exit;
      end if;
    end loop;

    return result;
  end function;
  constant next_address_lookup : address_lookup_t := get_next_address_lookup;

  signal write_address, write_address_next, read_address_resync : address_t := (others => '0');
  signal read_address, read_address_next, write_address_resync : address_t := (others => '0');

  type ram_t is array (ram_length - 1 downto 0) of std_ulogic_vector(data_width - 1 downto 0);
  signal ram : ram_t := (others => (others => '0'));

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

  ram(to_integer(write_address)) <= write_data when rising_edge(write_clock);
  read_data <= ram(to_integer(read_address));

end architecture;
