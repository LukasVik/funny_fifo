# --------------------------------------------------------------------------------------------------
# Copyright (c) Lukas Vik. All rights reserved.
# --------------------------------------------------------------------------------------------------

set write_clock_port [get_ports -quiet "write_clock"];
set write_clock [get_clocks -quiet -of_objects ${write_clock_port}];

if {${write_clock_port} == "" || ${write_clock} == ""} {
  puts "ERROR: Could not find 'write_clock'.";
  error;
}

set read_data [
  get_cells \
    -quiet \
    -filter {PRIMITIVE_GROUP==FLOP_LATCH || PRIMITIVE_GROUP==REGISTER} \
    "ram_reg*"
]

if {${write_clock_port} == "" || ${write_clock} == ""} {
  puts "ERROR: Could not find 'ram_reg'.";
  error;
}

set_false_path -setup -hold -from ${write_clock} -to ${read_data};
