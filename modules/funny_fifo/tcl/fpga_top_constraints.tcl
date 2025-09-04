# --------------------------------------------------------------------------------------------------
# Copyright (c) Lukas Vik. All rights reserved.
# --------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Clock setup.
# ------------------------------------------------------------------------------
set write_clock_port [get_ports "write_clock"];
set read_clock_port [get_ports "read_clock"];

set clock_frequency_ghz [expr 10.0 * 66 / 64 / 16];
set clock_period_ns [expr 1.0 / ${clock_frequency_ghz}];
set write_clock [
  create_clock \
    -name [get_property "NAME" ${write_clock_port}] \
    -period ${clock_period_ns} \
    ${write_clock_port}
];
set read_clock [
  create_clock \
    -name [get_property "NAME" ${read_clock_port}] \
    -period ${clock_period_ns} \
    ${read_clock_port};
];

set_property "PACKAGE_PIN" "AE23" ${write_clock_port};
set_property "PACKAGE_PIN" "AD22" ${read_clock_port};


# ------------------------------------------------------------------------------
# Misc ports.
# ------------------------------------------------------------------------------
set_property "PACKAGE_PIN" "AG24" [get_ports "write_ready"];
set_property "PACKAGE_PIN" "AH24" [get_ports "write_valid"];
set_property "PACKAGE_PIN" "AG22" [get_ports "read_ready"];
set_property "PACKAGE_PIN" "AF23" [get_ports "read_data"];


# ------------------------------------------------------------------------------
# write_data.
# ------------------------------------------------------------------------------
set data_width [llength [get_ports "write_data[*]"]];

set write_data_pins {
  "AE28"
  "AF28"
  "AF27"
  "AG28"
  "AE25"
  "AE26"
  "AG27"
  "AH27"
  "AF25"
  "AF26"
  "AH25"
  "AH26"
  "AG25"
  "AE20"
  "AE21"
  "AE19"
  "AF20"
  "AG20"
  "AH20"
  "AF18"
  "AG18"
  "AG19"
  "AH19"
  "AF17"
  "AG17"
  "AE18"
  "AB22"
  "AC22"
  "AD18"
  "AD19"
  "AC21"
  "AD21"
  "AB17"
  "AC17"
  "AC19"
  "AC20"
  "AB18"
  "AB19"
  "AD17"
  "AB20"
  "AC18"
  "AE22"
  "AF19"
  "AG24"
  "AH24"
  "AH21"
  "AH22"
  "AF23"
  "AG23"
  "AF21"
  "AF22"
  "AC26"
  "AD27"
  "AB23"
  "AB24"
  "AC27"
  "AD28"
  "AC24"
  "AD24"
  "AB27"
  "AB28"
  "AB25"
  "AC25"
  "AD26"
}

for {set data_idx 0} {${data_idx} < ${data_width}} {incr data_idx} {
  set write_data_pin [lindex ${write_data_pins} ${data_idx}];
  set write_data_port [get_ports "write_data[${data_idx}]"];
  puts "Constraining ${write_data_port} to ${write_data_pin}";
  set_property "PACKAGE_PIN" ${write_data_pin} ${write_data_port};
}


# ------------------------------------------------------------------------------
# Default voltage for all banks.
# ------------------------------------------------------------------------------
set_property "IOSTANDARD" "LVCMOS18" [get_ports];


# ------------------------------------------------------------------------------
# Timing exception on the theoretical timing path from 'WE' and 'WDATA' to 'RDATA'
# if we are writing and reading at the same time.
# Assumes a LUTRAM implementation.
# Note that, for a LUTRAM, writes are registered but reads are combinatorial.
# Same constraint as:
# https://github.com/hdl-modules/hdl-modules/blob/main/modules/fifo/scoped_constraints/asynchronous_fifo.tcl
# ------------------------------------------------------------------------------
if {${write_clock} == ""} {
  puts "ERROR: Could not find 'write_clock'.";
  error;
}

set read_data [
  get_cells \
    -quiet \
    -filter {PRIMITIVE_GROUP==FLOP_LATCH || PRIMITIVE_GROUP==REGISTER} \
    "read_data_shift_reg*"
]

set_false_path -setup -hold -from ${write_clock} -to ${read_data};
