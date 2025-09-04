# --------------------------------------------------------------------------------------------------
# Copyright (c) Lukas Vik. All rights reserved.
# --------------------------------------------------------------------------------------------------

set input_clock_port [get_ports -quiet "input_clock"];
set input_clock [get_clocks -quiet -of_objects ${input_clock_port}];

if {${input_clock_port} == "" || ${input_clock} == ""} {
  puts "ERROR: Could not find 'input_clock'.";
  error;
}


set result_clock_port [get_ports -quiet "result_clock"];
set result_clock [get_clocks -quiet -of_objects ${result_clock_port}];

if {${result_clock_port} == "" || ${result_clock} == ""} {
  puts "ERROR: Could not find 'result_clock'.";
  error;
}


set input_clock_period [get_property "PERIOD" ${input_clock}]
set result_clock_period [get_property "PERIOD" ${result_clock}]
set min_period [expr {min(${input_clock_period}, ${result_clock_period})}]
puts "INFO: Using calculated min period: ${min_period}."


set input_registers [get_cells "input_data_sampled_reg*"]
set first_resync_registers [get_cells "result_data_m1_reg*"]


# Timing exception. With max delay to impose a latency limit.
set max_delay [expr ${min_period} / 2];
set_max_delay -datapath_only -from ${input_registers} -to ${first_resync_registers} ${max_delay}
