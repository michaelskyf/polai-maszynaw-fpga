`include "led_driver.sv"

`timescale 1ns/1ps
module tb_led_driver;

   // Clock period for 50 MHz clock = 20 ns.
   parameter CLK_FREQ = 50_000_000;
   parameter CLK_PERIOD = 1_000_000_000/CLK_FREQ; // ns

   // Testbench signals.
   logic clk;
   logic rst;
   logic ready;
   logic [23:0] rgb_data;
   logic busy;
   logic data_latched;
   logic led_out;

   // Instantiate the led_driver
   led_driver #(.CLK_FREQ(CLK_FREQ)) uut (
      .clk(clk),
      .rst(rst),
      .ready(ready),
      .rgb_data(rgb_data),
      .busy(busy),
      .data_latched(data_latched),
      .led_out(led_out)
   );

   // Clock generation.
   always begin
      #(CLK_PERIOD/2) clk = ~clk;
   end

   // Test stimulus.
   initial begin
      // Enable waveform dump.
      $dumpfile("led_driver.vcd");
      $dumpvars(0, tb_led_driver);

      // Initialize signals.
      clk       = 0;
      rst       = 1;
      ready     = 0;
      rgb_data  = 24'hFF00FF; // Start with purple.
      
      // Hold reset for 100 ns.
      #100;
      rst = 0;
      
      // First transmission cycle: ready is high.
      ready = 1;
      #100
      
      // Change the rgb_data while ready remains high.
      rgb_data = 24'h00FF00; // Change to green.
      #30000;
      
      // Now, set ready low to trigger a reset pulse.
      ready = 0;
      // Wait enough time for the reset pulse (~50 us).
      #50000;
      
      // Reassert ready to begin a new transmission cycle.
      ready = 1;
      rgb_data = 24'h0000FF; // Change to blue.
      #30000;
      
      // End simulation after a short delay.
      #10000;
      $finish;
   end

   // Optional: Monitor signal changes.
   initial begin
      $display("Time\tclk\trst\tready\trgb_data\tbusy\tdata_latched\tled_out");
      $monitor("%t\t%b\t%b\t%b\t%h\t%b\t%b\t%b", 
                $time, clk, rst, ready, rgb_data, busy, data_latched, led_out);
   end

endmodule
