`include "top.sv"

`timescale 1ns/1ps
module tb_top;

   // Clock period for 50 MHz clock = 20 ns.
   parameter CLK_FREQ = 27_000_000;
   parameter CLK_PERIOD = 1_000_000_000/CLK_FREQ; // ns

   // Testbench signals.
   logic clk;
   logic led_out;
   logic [5:0] leds;
   wire i2c_scl;
   wire i2c_sda;
   pullup(i2c_scl);
   pullup(i2c_sda);

   // Instantiate the led_driver
   top #() uut (
      .clk_27M(clk),
      .led_out(led_out),
      .leds(leds),
      .i2c_scl_pin(i2c_scl),
      .i2c_sda_pin(i2c_sda)
   );

   // Clock generation.
   always begin
      #(CLK_PERIOD/2) clk = ~clk;
   end

   // Test stimulus.
   initial begin
      // Enable waveform dump.
      $dumpfile("led_driver.vcd");
      $dumpvars(0, tb_top);

      // Initialize signals.
      clk       = 0;
      
      #100;
      
      #100
      
      #30000;
      
      // Wait enough time for the reset pulse (~50 us).
      #50000;
      
      #30000;
      
      // End simulation after a short delay.
      #1000000;
      $finish;
   end

   // Optional: Monitor signal changes.
   initial begin
      $display("Time\tclk\trst\tready\trgb_data\tbusy\tdata_latched\tled_out");
      $monitor("%t\t%b\t%b\t%b\t%h\t%b\t%b", 
                $time, clk, leds, i2c_scl, i2c_sda, led_out);
   end

endmodule
