`include "i2c_master.sv"
`include "led_driver.sv"

`default_nettype none

module top (
    input  clk_27M,
    output logic led_out,
    output logic [5:0] leds,

    inout  wire       i2c_scl_pin,  // Declare I2C SCL as inout
    inout  wire       i2c_sda_pin   // Declare I2C SDA as inout
);

  // Clock frequency and 500-ms delay calculation.
  localparam CLK_FREQ     = 27000000;
  localparam NUM_LEDS     = 144;         // Number of LEDs in the chain
  localparam DELAY_CYCLES = CLK_FREQ/(NUM_LEDS);

`define TRANSFORM(n, NUM_LEDS) (((n) % ((NUM_LEDS) << 1) < (NUM_LEDS)) ? ((n) % ((NUM_LEDS) << 1)) : ((((NUM_LEDS) << 1) - 1) - ((n) % ((NUM_LEDS) << 1))))




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
      .led_out(led_out)
  );

// Host interface signals
    reg  [6:0]  cmd_address_reg;
    reg         cmd_start_reg;
    reg         cmd_read_reg;
    reg         cmd_write_reg;
    reg         cmd_write_multiple_reg;
    reg         cmd_stop_reg;
    reg         cmd_valid_reg;
    wire        cmd_ready;

    reg  [7:0]  data_tdata_reg;
    reg         data_tvalid_reg;
    reg         data_tlast_reg;
    wire        data_tready;

    wire [7:0]  m_axis_data_tdata;
    wire        m_axis_data_tvalid;
    wire        m_axis_data_tlast;
    reg         m_axis_data_tready_reg;

    // I2C interface signals (internal wires)
    wire        scl_i;
    wire        scl_o;
    wire        scl_t;
    wire        sda_i;
    wire        sda_o;
    wire        sda_t;

    // Status signals
    wire        busy;
    wire        bus_control;
    wire        bus_active;
    wire        missed_ack;

    // Configuration signals
    reg  [15:0] prescale_reg;
    reg         stop_on_idle_reg;

    // Instantiate the I2C master module
    i2c_master u_i2c_master (
        .clk                  (clk_27M),
        .rst                  (led_rst),

        .s_axis_cmd_address   (cmd_address_reg),
        .s_axis_cmd_start     (cmd_start_reg),
        .s_axis_cmd_read      (cmd_read_reg),
        .s_axis_cmd_write     (cmd_write_reg),
        .s_axis_cmd_write_multiple (cmd_write_multiple_reg),
        .s_axis_cmd_stop      (cmd_stop_reg),
        .s_axis_cmd_valid     (cmd_valid_reg),
        .s_axis_cmd_ready     (cmd_ready),

        .s_axis_data_tdata    (data_tdata_reg),
        .s_axis_data_tvalid   (data_tvalid_reg),
        .s_axis_data_tready   (data_tready),
        .s_axis_data_tlast    (data_tlast_reg),

        .m_axis_data_tdata    (m_axis_data_tdata),
        .m_axis_data_tvalid   (m_axis_data_tvalid),
        .m_axis_data_tready   (m_axis_data_tready_reg),
        .m_axis_data_tlast    (m_axis_data_tlast),

        .scl_i                (scl_i),
        .scl_o                (scl_o),
        .scl_t                (scl_t),
        .sda_i                (sda_i),
        .sda_o                (sda_o),
        .sda_t                (sda_t),

        .busy                 (busy),
        .bus_control          (bus_control),
        .bus_active           (bus_active),
        .missed_ack           (missed_ack),

        .prescale             (prescale_reg),
        .stop_on_idle         (stop_on_idle_reg)
    );

    // Tristate I2C bus connections:
    // Connect the external scl/sda pins to the internal signals using tristate logic.
    assign scl_i = i2c_scl_pin;
    assign i2c_scl_pin    = scl_t ? 1'bz : scl_o;

    assign sda_i = i2c_sda_pin;
    assign i2c_sda_pin    = sda_t ? 1'bz : sda_o;

  // Tie off unused outputs.
  assign leds[0] = busy;

  // Main state machine:
  // - In IDLE (update_in_progress == 0): count for 500 ms.
  // - Once delay expires, assert led_ready_reg to start a transfer cycle.
  // - During the transfer cycle, on each led_data_latched pulse, update rgb_data_reg.
  //   The LED whose index equals counter_9_bit is driven white (24'hFFFFFF) and others off.
  // - When the entire chain (NUM_LEDS words) has been updated, deassert led_ready_reg,
  //   finish the transfer, and increment counter_9_bit (wrapping around).
  always_ff @(posedge clk_27M) begin
    if (delay_reg < DELAY_CYCLES - 1) begin
      delay_reg <= delay_reg + 1;
    end

    if (!update_in_progress && !led_busy) begin
      // Not transferring: deassert ready.
      led_ready_reg <= 0;
      // Count the 500 ms delay.
      if (delay_reg >= DELAY_CYCLES - 1) begin
        delay_reg         <= 0;
        update_in_progress<= 1;
        send_index        <= 0;
        led_ready_reg     <= 1;  // Begin transfer cycle.
        // For the first LED in the chain, set rgb_data based on the current index.
        if (0 == counter_9_bit)
          rgb_data_reg <= 24'hFFFFFF;  // LED on (white)
        else
          rgb_data_reg <= 24'hFFFFFF;  // LED off
      end
    end
    else begin
      // In transfer cycle: each time data is latched, update for the next LED.
      if (led_data_latched) begin
        if (send_index < NUM_LEDS - 1) begin
          send_index <= send_index + 1;
          // Set the next LED's color: on (white) if its index equals counter_9_bit.
          if ((send_index + 1) == `TRANSFORM(counter_9_bit, NUM_LEDS))
            rgb_data_reg <= 24'hFFFFFF;
          else
            rgb_data_reg <= 24'hFFFFFF;
        end
        else begin
          // End of transfer: deassert ready and prepare for next cycle.
          update_in_progress <= 0;
          led_ready_reg      <= 0;
          counter_9_bit <= counter_9_bit + 1;
        end
      end
    end
  end

endmodule
