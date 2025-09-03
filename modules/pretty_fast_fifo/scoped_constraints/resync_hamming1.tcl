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
