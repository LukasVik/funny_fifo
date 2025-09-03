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
