`timescale 1ns/1ps
`include "led_controller.sv"

//------------------------------------------------------------------------------
// Testbench for led_decoder_multiplexer with VCD dump
//------------------------------------------------------------------------------
module tb_led_decoder_multiplexer;
    // Signal declarations
    logic clk;
    logic rst;
    logic decode_next_led;
    cell_t data;
    wire busy;
    wire led_out;
    
    // Instantiate the Unit Under Test (UUT)
    led_decoder_multiplexer uut (
        .clk(clk),
        .rst(rst),
        .decode_next_led(decode_next_led),
        .data(data),
        .busy(busy),
        .led_out(led_out)
    );
    
    // Clock generation: 10ns period (5ns high, 5ns low)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize inputs
        rst = 1;
        decode_next_led = 0;
        data = 0; // initialize all bits to 0

        // Apply reset for a few cycles
        #20;
        rst = 0;

        // Test Case 1: LED cell type 
        $display("Starting LED cell test...");
        data.cell_type = CELL_TYPE_LED;
        data.data.led_data.value = 1'b1;  // set LED high
        decode_next_led = 1; // start decode
        #10;
        decode_next_led = 0;
        
        // Wait until busy signal is deasserted
        wait(busy == 0)
        $display("LED cell test complete at time %t, led_out = %b", $time, led_out);
        
        // Delay before next test case
        #20;
        
        // Test Case 2: DISPLAY cell type
        $display("Starting DISPLAY cell test...");
        data.cell_type = CELL_TYPE_DISPLAY;
        data.data.display_data.digit_count = 1;
        data.data.display_data.value = 16'hA5A5;
        
        #10
        decode_next_led = 1;  // start the decoding process
        #10;
        decode_next_led = 0;
        #10;
        decode_next_led = 1;  // start the decoding process
        #10;
        decode_next_led = 0;
        #10;
        decode_next_led = 1;  // start the decoding process
        #10;
        decode_next_led = 0;
        #10;
        decode_next_led = 1;  // start the decoding process
        #10;
        decode_next_led = 0;
        #10;
        decode_next_led = 1;  // start the decoding process
        #10;
        decode_next_led = 0;
        #10;
        decode_next_led = 1;  // start the decoding process
        #10;
        decode_next_led = 0;
        #10;
        decode_next_led = 1;  // start the decoding process
        #10;
        decode_next_led = 0;
        #10;

        // Wait until busy is deasserted
        $display("DISPLAY cell test complete at time %t, led_out = %b", $time, led_out);
        
        // End simulation after a short delay
        #20;
        $finish;
    end
    
    // Waveform dumping: Save the waveform to a VCD file.
    initial begin
        $dumpfile("tb_led_decoder_multiplexer.vcd");
        $dumpvars(0, tb_led_decoder_multiplexer);
    end
    
endmodule
