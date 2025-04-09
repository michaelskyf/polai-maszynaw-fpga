`include "led_driver.sv"

module led_driver_const_color #(
    parameter CLK_FREQ = 27_000_000,  // Clock frequency in Hz
    parameter COLOR = 24'h000f00         // LED color in ON state
)(
    input  logic         clk,
    input  logic         rst,
    input  logic         ready,       // When high, continuously latch and transmit rgb_data
    input  logic         data,        // On/Off input
    output logic         busy,        // High while transmitting data/reset
    output logic         data_latched,// One-cycle pulse at each new latch of rgb_data
    output logic         led_out      // WS2812B serial output signal
);

wire [23:0] rgb_data;
assign rgb_data = data ? COLOR : 0;

led_driver #(.CLK_FREQ(CLK_FREQ)) drv (
    .clk(clk),
    .rst(rst),
    .ready(ready),
    .rgb_data(rgb_data),
    .busy(busy),
    .data_latched(data_latched),
    .led_out(led_out)
);

endmodule