# --------------------------------------------------------------------------------------------------
# Copyright (c) Lukas Vik. All rights reserved.
# --------------------------------------------------------------------------------------------------

create_ip -vlnv "xilinx.com:ip:fifo_generator:13.2" -module_name "vendor_fifo"
set_property -dict [list \
  "CONFIG.Clock_Type_AXI" "Independent_Clock" \
  "CONFIG.FIFO_Implementation_axis" "Independent_Clocks_Distributed_RAM" \
  "CONFIG.Fifo_Implementation" "Independent_Clocks_Distributed_RAM" \
  "CONFIG.INTERFACE_TYPE" "AXI_STREAM" \
  "CONFIG.Input_Depth_axis" "16" \
  "CONFIG.Performance_Options" "First_Word_Fall_Through" \
  "CONFIG.TDATA_NUM_BYTES" "4" \
  "CONFIG.TUSER_WIDTH" "0" \
] [get_ips "vendor_fifo"]
