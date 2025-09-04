-- -------------------------------------------------------------------------------------------------
-- Copyright (c) Lukas Vik. All rights reserved.
-- -------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity pretty_fast_fifo_no_ready is
  generic (
    data_width : positive;
    fifo_depth : positive
  );
  port (
    write_clock : in std_ulogic;
    write_valid : in std_ulogic;
    write_data : in std_ulogic_vector(data_width-1 downto 0);
    --
    read_clock : in std_ulogic;
    read_valid : out std_ulogic := '0';
    read_data : out std_ulogic_vector(data_width-1 downto 0) := (others => '0')
  );
end entity;

architecture a of pretty_fast_fifo_no_ready is
begin

  ------------------------------------------------------------------------------
  pretty_fast_fifo_inst : entity work.pretty_fast_fifo
    generic map (
      data_width => data_width,
      fifo_depth => fifo_depth
    )
    port map (
      write_clock => write_clock,
      write_ready => open,
      write_valid => write_valid,
      write_data => write_data,
      --
      read_clock => read_clock,
      read_ready => '1',
      read_valid => read_valid,
      read_data => read_data
    );

end architecture;
