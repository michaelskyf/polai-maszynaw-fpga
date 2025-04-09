`timescale 1ns/1ps
module led_driver #(
    parameter CLK_FREQ = 27_000_000  // Clock frequency in Hz
)(
    input  logic         clk,
    input  logic         rst,
    input  logic         ready,       // When high, continuously latch and transmit rgb_data
    input  logic [23:0]  rgb_data,    // Single 24-bit RGB color input
    output logic         busy,        // High while transmitting data/reset
    output logic         data_latched,// One-cycle pulse at each new latch of rgb_data
    output logic         led_out      // WS2812B serial output signal
);

   // WS2812B timing specifications (in seconds):
   //   T0H: ~0.35 µs, T1H: ~0.9 µs, total bit time: ~1.25 µs, reset pulse: >50 µs.
   localparam real T0H_time   = 0.4e-6;
   localparam real T1H_time   = 0.8e-6;
   localparam real T0L_time   = 0.85e-6;
   localparam real T1L_time   = 0.45e-6;
   localparam real BIT_time   = 1.25e-6;
   localparam real RESET_time = 50e-6;

   // Calculate timing parameters (in clock cycles) based on CLK_FREQ.
   localparam int T0H          = $rtoi(T0H_time   * CLK_FREQ + 0.5);
   localparam int T0L          = $rtoi(T0L_time * CLK_FREQ + 0.5);
   localparam int T1H          = $rtoi(T1H_time   * CLK_FREQ + 0.5);
   localparam int T1L          = $rtoi(T1L_time * CLK_FREQ + 0.5);
   localparam int BIT_TOTAL    = $rtoi(BIT_time   * CLK_FREQ + 0.5);
   localparam int RESET_CYCLES = $rtoi(RESET_time * CLK_FREQ + 0.5);

   // Only one LED's worth of data (24 bits)
   localparam int TOTAL_BITS = 24;

   // Define state machine states.
   typedef enum logic [1:0] {
      IDLE, 
      SEND_BIT, 
      RESET_PULSE
   } state_t;
   state_t state;

   // Counters and registers.
   reg [15:0] bit_index;
   reg [15:0] cycle_count;
   reg current_bit;

   reg busy_reg;
   assign busy = busy_reg;

   reg data_latched_reg;
   assign data_latched = data_latched_reg;

   reg [23:0] latched_data;

   // State machine.
   always_ff @(posedge clk) begin
      if (rst) begin
         state            <= IDLE;
         bit_index        <= 0;
         cycle_count      <= 0;
         led_out          <= 0;
         busy_reg         <= 0;
         data_latched_reg <= 0;
      end else begin
         // Default: no latch pulse.
         data_latched_reg <= 0;
         case (state)
            IDLE: begin
               busy_reg <= 0;
               led_out  <= 0;
               // If ready is high, start a new transmission cycle.
               if (ready) begin
                  bit_index        <= 0;
                  cycle_count      <= 0;
                  busy_reg         <= 1;
                  data_latched_reg <= 1;  // One-cycle pulse: new data latched.
                  latched_data     <= {rgb_data[15:8], rgb_data[23:16], rgb_data[7:0]};
                  state            <= SEND_BIT;
               end
            end

            SEND_BIT: begin
               busy_reg <= 1;
               if (cycle_count == 0) begin
                  // Load current bit (transmit MSB first).
                  current_bit <= latched_data[23 - bit_index];
                  led_out     <= 1;  // Start the bit with a high pulse.
               end else begin
                  // For a '1' bit, hold high for T1H cycles; for a '0' bit, for T0H cycles.
                  if (current_bit) begin
                     if (cycle_count == T1H)
                        led_out <= 0;
                  end else begin
                     if (cycle_count == T0H)
                        led_out <= 0;
                  end
               end

               // At the end of the bit period:
               if (cycle_count == BIT_TOTAL - 1) begin
                  if (bit_index == TOTAL_BITS - 1) begin
                     // Finished transmitting all 24 bits.
                     cycle_count <= 0;
                     // If ready is high, immediately start a new transmission cycle.
                     if (ready) begin
                        bit_index        <= 0;
                        data_latched_reg <= 1; // Latch new data (one-cycle pulse)
                        state            <= SEND_BIT;
                        latched_data     <= {rgb_data[15:8], rgb_data[23:16], rgb_data[7:0]};
                     end else begin
                        state <= RESET_PULSE;
                     end
                  end else begin
                     // Move on to the next bit.
                     bit_index   <= bit_index + 1;
                     cycle_count <= 0;
                  end
               end else begin
                  cycle_count <= cycle_count + 1;
               end
            end

            RESET_PULSE: begin
               busy_reg <= 1;
               led_out  <= 0;
               if (cycle_count < RESET_CYCLES - 1)
                  cycle_count <= cycle_count + 1;
               else begin
                  cycle_count <= 0;
                  state <= IDLE;
               end
            end

            default: state <= IDLE;
         endcase
      end
   end

endmodule
