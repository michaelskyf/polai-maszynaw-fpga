`include "display_decoder.sv"

`timescale 1ns / 1ps

module display_decoder_tb;
    // Testbench signals for inputs (reg) and outputs (wire)
    reg         clk;
    reg         rst;
    reg  [1:0]  digit_count;
    reg  [15:0] data;
    reg         next_led;
    
    wire        led_data;
    wire        busy;
    
    // Instantiate the display_decoder module under test (UUT)
    display_decoder uut (
        .clk(clk),
        .rst(rst),
        .digit_count(digit_count),
        .data(data),
        .next_led(next_led),
        .led_data(led_data),
        .busy(busy)
    );
    
    // Clock generation: 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // toggle every 5 ns
    end
    
    // Stimulus process
    initial begin

        $dumpfile("display_decoder.vcd");
        $dumpvars(0, display_decoder_tb);
        $dumpvars(1, display_decoder_tb.uut);
        // Initialize inputs
        rst         = 1;
        digit_count = 2'b00;
        data        = 16'h0000;
        next_led    = 0;
        
        // Hold reset active for a few clock cycles
        #20;
        rst = 0;
        
        // Wait a few cycles after release of reset
        #10;
        
        // Test Case 1:
        // Provide a 2-digit display request with data "25".
        digit_count = 2'b10;  // two digits to display
        data        = 16'd1;  // data input
        #10;
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100;
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100;
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100;
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100;
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100;
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        #100
        next_led    = 1;       // trigger a new display update
        #10;
        next_led    = 0;       // return next_led to low
        
        // Allow sufficient time for processing through the segments/digits.
        #1000;
        
        // Test Case 2:
        // Provide a 3-digit display request with different data.
        digit_count = 2'b11;   // three digits to display (values: 0 to 3 supported by a 2-bit input)
        data        = 16'd678;  // data input; the module will use data % 10 for segment selection
        #10;
        next_led = 1;
        #10;
        next_led = 0;
        
        // Run simulation for a bit longer to observe the behavior.
        #20000;
        
        // End simulation
        $finish;
    end

endmodule
