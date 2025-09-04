-- -------------------------------------------------------------------------------------------------
-- Copyright (c) Lukas Vik. All rights reserved.
-- -------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pkg.all;


package pretty_fast_fifo_pkg is

  type address_lookup_t is array (integer range <>) of u_unsigned;
  function get_next_address_lookup(address_width : positive) return address_lookup_t;

end package;

package body pretty_fast_fifo_pkg is

  function get_next_address_lookup(address_width : positive) return address_lookup_t is
    variable result : address_lookup_t(2 ** address_width - 1 downto 0)(
      address_width - 1 downto 0
    ) := (others => (others => '0'));
    variable this_address, next_address : u_unsigned(address_width - 1 downto 0) := (others => '0');
  begin
    while true loop
      this_address := next_address;
      next_address := u_unsigned(to_gray(from_gray(std_ulogic_vector(this_address)) + 1));

      result(to_integer(this_address)) := next_address;

      if next_address = 0 then
        -- We are pointing back to the start address, meaning we've gone through all addresses.
        exit;
      end if;
    end loop;

    return result;
  end function;

end package body;
