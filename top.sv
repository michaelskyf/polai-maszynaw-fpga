module top (
    input  clk_27M,
    output logic [7:0] buttons,
    output logic [5:0] leds
);

  // Clock frequency and 500-ms delay calculation.
  localparam CLK_FREQ     = 27000000;
  localparam DELAY_CYCLES = CLK_FREQ/144;
  localparam NUM_LEDS     = 144;         // Number of LEDs in the chain

  // Delay counter for 500 ms period.
  reg [31:0] delay_reg = 0;
  // Flag indicating if a transfer cycle is in progress.
  reg        update_in_progress = 0;
  // Counter used to step through each LED during a transfer cycle.
  reg [31:0]  send_index = 0;
  // This counter holds the index (0 to NUM_LEDS-1) of the LED to be turned on.
  reg [31:0]  counter_9_bit = 0;

  // 24-bit register for the RGB data to be sent.
  reg [23:0] rgb_data_reg = 0;
  wire [23:0] rgb_data = rgb_data_reg;

  // LED driver control signals.
  // 'led_ready_reg' is our driveable ready signal.
  reg        led_ready_reg = 0;
  reg        led_rst = 0;
  wire       led_data_latched; // Pulses high for 1 clock when data is latched.
  wire       led_busy;         // (Not used in this example)

  // Instantiate the LED driver. Note that we pass our internal 'led_ready_reg' as the ready signal.
  led_driver #(.CLK_FREQ(CLK_FREQ)) uut (
      .clk(clk_27M),
      .rst(led_rst),
      .ready(led_ready_reg),
      .rgb_data(rgb_data),
      .busy(led_busy),
      .data_latched(led_data_latched),
      .led_out(buttons[0])
  );

  // Tie off unused outputs.
  assign leds = 6'b0;
  assign buttons[1] = buttons[0];
  assign buttons[7:2] = 7'b0;

  // Main state machine:
  // - In IDLE (update_in_progress == 0): count for 500 ms.
  // - Once delay expires, assert led_ready_reg to start a transfer cycle.
  // - During the transfer cycle, on each led_data_latched pulse, update rgb_data_reg.
  //   The LED whose index equals counter_9_bit is driven white (24'hFFFFFF) and others off.
  // - When the entire chain (NUM_LEDS words) has been updated, deassert led_ready_reg,
  //   finish the transfer, and increment counter_9_bit (wrapping around).
  always_ff @(posedge clk_27M) begin
    if (!update_in_progress && !led_busy) begin
      // Not transferring: deassert ready.
      led_ready_reg <= 0;
      // Count the 500 ms delay.
      if (delay_reg < DELAY_CYCLES - 1)
        delay_reg <= delay_reg + 1;
      else begin
        delay_reg         <= 0;
        update_in_progress<= 1;
        send_index        <= 0;
        led_ready_reg     <= 1;  // Begin transfer cycle.
        // For the first LED in the chain, set rgb_data based on the current index.
        if (0 == counter_9_bit)
          rgb_data_reg <= 24'hFF0000;  // LED on (white)
        else
          rgb_data_reg <= 24'h000000;  // LED off
      end
    end
    else begin
      // In transfer cycle: each time data is latched, update for the next LED.
      if (led_data_latched) begin
        if (send_index < NUM_LEDS - 1) begin
          send_index <= send_index + 1;
          // Set the next LED's color: on (white) if its index equals counter_9_bit.
          if ((send_index + 1) == counter_9_bit)
            rgb_data_reg <= 24'hFF0000;
          else
            rgb_data_reg <= 24'h000000;
        end
        else begin
          // End of transfer: deassert ready and prepare for next cycle.
          update_in_progress <= 0;
          led_ready_reg      <= 0;
          // Advance the lit LED index, wrapping around.
          if (counter_9_bit < NUM_LEDS - 1)
            counter_9_bit <= counter_9_bit + 1;
          else
            counter_9_bit <= 0;
        end
      end
    end
  end

endmodule
