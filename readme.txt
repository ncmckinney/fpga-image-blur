This project utilizes a weighted averaging filter to blur an 256 by 256 gray-scale image displayed on 
an VGA monitor. Developed on an NEXYS 4 DDR dev board in verilog. A VGA monitor and keyboard are required.
With keyboard attached to the FPGA board, each press of the ‘0’ key would run the image through the filter
and display the resulting image onto the monitor. Low Pass Filter operations are repeatable, 
with successive filtering causing the image to appear more blurred. The goal of this task was
to learn general principles behind storing, retrieving, and processing image data.

To run:
clone files to directory of your choice
in Vivado Design Suite, run build.tcl found in root