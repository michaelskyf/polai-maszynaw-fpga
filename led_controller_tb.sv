`timescale 1ns/1ps

// Include any dependent source files if required by your simulation flow
`include "led_controller.sv"

// The typedefs and module definitions for cell_t, led_decoder_multiplexer, and led_controller
// are assumed to have been compiled along with the testbench.

module led_controller_tb;

  // Parameters for the led_controller
  localparam ARRAY_LENGTH = 400;
  localparam LED_COLOR    = 24'h00ff00;

  // Signals for clock, reset, and refresh control
  reg clk;
  reg rst;
  reg refresh_lock;
  reg refresh;

  // Cells array; note that cell_t is defined in the design files
  led_controller_defs::cell_t cells[ARRAY_LENGTH];

  // Internal clock generation: 10ns period (i.e. 100MHz clock)
  initial clk = 0;
  always #5 clk = ~clk;

  // Reset and refresh signal generation
  initial begin
    // Start with asserted reset
    rst = 1;
    refresh_lock = 0;
    refresh = 0;
    #20;
    rst = 0;
  end

  // Initialize the cells array with test values.
  // This example assigns even-indexed cells as LED type and odd-indexed cells as DISPLAY type.
  initial begin
    integer i;
    for (i = 0; i < ARRAY_LENGTH; i = i + 1) begin
      if (i % 2 == 0) begin
        // For LED cells: set the cell type and assign a sample value.
        cells[i].cell_type = CELL_TYPE_LED;
        cells[i].data.led_data.padding = 17'h0;
        cells[i].data.led_data.value   = 1'b1;
      end
      else begin
        // For DISPLAY cells: assign a digit count and a test 16-bit value.
        cells[i].cell_type = CELL_TYPE_DISPLAY;
        cells[i].data.display_data.digit_count = 2'b10;
        cells[i].data.display_data.value       = 16'hAAAA;
      end
    end
  end

  // Instantiate the led_controller DUT
  led_controller #(
    .ARRAY_LENGTH(ARRAY_LENGTH),
    .LED_COLOR(LED_COLOR)
  ) uut (
    .clk(clk),
    .rst(rst),
    .cells(cells),
    .refresh_lock(refresh_lock),
    .refresh(refresh)
  );

  // Generate a refresh pulse to trigger processing within the controller.
  // Adjust the timing as needed for your simulation.
  initial begin
    #50;
    refresh = 1;
    #10;
    refresh = 0;
  end

  // Dump waveforms to a VCD file for post-simulation analysis.
  initial begin
    $dumpfile("led_controller.vcd");
    $dumpvars(0, led_controller_tb);
    // Run simulation long enough to see multiple processing cycles.
    #10000;
    $finish;
  end

endmodule
