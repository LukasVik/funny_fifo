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
