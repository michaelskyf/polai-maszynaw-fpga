`include "i2c_master.sv"
`include "led_controller.sv"

module top (
    input  clk_27M,
    output logic led_out,
    output logic [5:0] leds,

    inout  wire       i2c_scl_pin,  // I2C SCL
    inout  wire       i2c_sda_pin   // I2C SDA
);

    // Reset generation
    logic reset = 1'b1;
    logic [3:0] reset_counter = 4'd0;
    always_ff @(posedge clk_27M) begin
        if (reset_counter < 4'd15) begin
            reset_counter <= reset_counter + 4'd1;
            reset <= 1'b1;
        end else begin
            reset <= 1'b0;
        end
    end

    // I2C signal declarations
    wire scl_i, scl_o, scl_t;
    wire sda_i, sda_o, sda_t;

    // I2C tristate buffers
    assign i2c_scl_pin = scl_t ? 1'bz : scl_o;
    assign i2c_sda_pin = sda_t ? 1'bz : sda_o;
    assign scl_i = i2c_scl_pin;
    assign sda_i = i2c_sda_pin;

    // I2C master interface signals
    logic [6:0] i2c_cmd_addr;
    logic i2c_cmd_start, i2c_cmd_read, i2c_cmd_write, i2c_cmd_write_multiple;
    logic i2c_cmd_stop, i2c_cmd_valid;
    wire i2c_cmd_ready;
    logic [7:0] i2c_data_tdata;
    logic i2c_data_valid, i2c_data_last;
    wire i2c_data_ready;
    wire [7:0] i2c_rx_data;
    wire i2c_rx_valid, i2c_rx_last;
    wire i2c_busy;

    // Instantiate I2C master
    i2c_master i2c (
        .clk(clk_27M),
        .rst(reset),
        .s_axis_cmd_address(i2c_cmd_addr),
        .s_axis_cmd_start(i2c_cmd_start),
        .s_axis_cmd_read(i2c_cmd_read),
        .s_axis_cmd_write(i2c_cmd_write),
        .s_axis_cmd_write_multiple(i2c_cmd_write_multiple),
        .s_axis_cmd_stop(i2c_cmd_stop),
        .s_axis_cmd_valid(i2c_cmd_valid),
        .s_axis_cmd_ready(i2c_cmd_ready),
        .s_axis_data_tdata(i2c_data_tdata),
        .s_axis_data_tvalid(i2c_data_valid),
        .s_axis_data_tready(i2c_data_ready),
        .s_axis_data_tlast(i2c_data_last),
        .m_axis_data_tdata(i2c_rx_data),
        .m_axis_data_tvalid(i2c_rx_valid),
        .m_axis_data_tready(1'b1),
        .m_axis_data_tlast(i2c_rx_last),
        .scl_i(scl_i),
        .scl_o(scl_o),
        .scl_t(scl_t),
        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_t(sda_t),
        .busy(i2c_busy),
        .prescale(16'h0043), // 100kHz @ 27MHz
        .stop_on_idle(1'b0)
    );

    localparam ARRAY_LENGTH = 11;

    led_controller_defs::cell_t lc_cells[ARRAY_LENGTH];
    reg [9:0] counterxx;
    reg [31:0] timerxx;
    always_ff @(posedge clk_27M) begin
        begin
            timerxx <= timerxx + 1;
            if(timerxx == 27_000_000) begin
                timerxx <= 0;
                counterxx <= counterxx + 1;
            end
            lc_cells[0].cell_type <= led_controller_defs::CELL_TYPE_LED;
            lc_cells[0].data.led_data.value <= 1;
            lc_cells[1].cell_type <= led_controller_defs::CELL_TYPE_LED;
            lc_cells[1].data.led_data.value <= 0;
            lc_cells[2].cell_type <= led_controller_defs::CELL_TYPE_LED;
            lc_cells[2].data.led_data.value <= 1;
            lc_cells[3].cell_type <= led_controller_defs::CELL_TYPE_LED;
            lc_cells[3].data.led_data.value <= 0;

            lc_cells[4].cell_type <= led_controller_defs::CELL_TYPE_DISPLAY;
            lc_cells[4].data.display_data.value <= counterxx;
            lc_cells[4].data.display_data.digit_count <= 2;
            lc_cells[5].cell_type <= led_controller_defs::CELL_TYPE_DISPLAY;
            lc_cells[5].data.display_data.value <= counterxx;
            lc_cells[6].data.display_data.digit_count <= 2;

            lc_cells[6].cell_type <= led_controller_defs::CELL_TYPE_LED;
            lc_cells[6].data.led_data.value <= 1;
            lc_cells[7].cell_type <= led_controller_defs::CELL_TYPE_LED;
            lc_cells[7].data.led_data.value <= 0;
            lc_cells[8].cell_type <= led_controller_defs::CELL_TYPE_LED;
            lc_cells[8].data.led_data.value <= 1;
            lc_cells[9].cell_type <= led_controller_defs::CELL_TYPE_LED;
            lc_cells[9].data.led_data.value <= 0;
            lc_cells[10].cell_type <= led_controller_defs::CELL_TYPE_LED;
            lc_cells[10].data.led_data.value <= 1;
        end
    end

    led_controller #(.ARRAY_LENGTH(ARRAY_LENGTH)) lc (
        .clk(clk_27M),
        .rst(reset),
        .cells(lc_cells),
        .refresh_lock(0),
        .refresh(1),
        .led_out(led_out)
    );

    // State machine
    typedef enum {
        INIT,
        SOFT_RESET,
        SEND_RESET_DATA_REG,
        SEND_RESET_DATA_VAL,
        WRITE_THRESHOLDS,
        SEND_THRESHOLD_DATA_REG,
        SEND_THRESHOLD_DATA_VAL,
        ENABLE_ELECTRODE,
        SEND_ENABLE_DATA_REG,
        SEND_ENABLE_DATA_VAL,
        SET_READ_ADDR,
        SEND_ADDR_DATA,
        READ_STATUS,
        RECEIVE_DATA,
        UPDATE_LED,
        DELAY
    } state_t;

    state_t current_state = INIT, next_state = INIT;

    // Data buffers
    logic [7:0] touch_status_low, touch_status_high;
    logic [2:0] data_counter;
    logic [23:0] delay_counter;

    always_ff @(posedge clk_27M or posedge reset) begin
        if (reset) begin
            current_state <= INIT;
            data_counter <= 0;
            touch_status_low <= 0;
            touch_status_high <= 0;
            leds <= 0;
            delay_counter <= 0;
        end else begin
            current_state <= next_state;

            // Default values for I2C signals
            i2c_cmd_start <= 1'b0;
            i2c_cmd_read <= 1'b0;
            i2c_cmd_write <= 1'b0;
            i2c_cmd_stop <= 1'b0;
            i2c_cmd_valid <= 1'b0;
            i2c_data_valid <= 1'b0;
            i2c_data_last <= 1'b0;
            i2c_cmd_write_multiple <= 1'b0;

            case (current_state)
                INIT: begin
                    data_counter <= 0;
                    next_state <= SOFT_RESET;
                end

                SOFT_RESET: begin
                    if (i2c_cmd_ready) begin
                        // Write to soft reset register (0x80)
                        i2c_cmd_addr <= 7'h5A;          // MPR121 address
                        i2c_cmd_start <= 1'b1;
                        i2c_cmd_write_multiple <= 1'b1;
                        i2c_cmd_stop <= 1'b1;
                        i2c_cmd_valid <= 1'b1;
                        next_state <= SEND_RESET_DATA_REG;
                    end
                end

                SEND_RESET_DATA_REG: begin
                    if (i2c_data_ready) begin
                        i2c_data_valid <= 1'b1;
                        i2c_data_tdata <= 8'h80;        // Register address
                        next_state <= SEND_RESET_DATA_VAL;
                    end
                end

                SEND_RESET_DATA_VAL: begin
                    if (i2c_data_ready) begin
                        i2c_data_valid <= 1'b1;
                        i2c_data_tdata <= 8'h63;        // Reset value
                        i2c_data_last <= 1'b1;
                        next_state <= WRITE_THRESHOLDS;
                    end
                end

                WRITE_THRESHOLDS: begin
                    if (i2c_cmd_ready) begin
                        // Set touch threshold (0x41) to 0x0F
                        i2c_cmd_addr <= 7'h5A;
                        i2c_cmd_start <= 1'b1;
                        i2c_cmd_write_multiple <= 1'b1;
                        i2c_cmd_stop <= 1'b1;
                        i2c_cmd_valid <= 1'b1;
                        i2c_data_tdata <= 8'h41;        // Touch threshold reg
                        next_state <= SEND_THRESHOLD_DATA_REG;
                    end
                end

                SEND_THRESHOLD_DATA_REG: begin
                    if (i2c_data_ready) begin
                        i2c_data_valid <= 1'b1;
                        i2c_data_tdata <= 8'h41;        // Touch threshold reg
                        next_state <= SEND_THRESHOLD_DATA_VAL;
                    end
                end

                SEND_THRESHOLD_DATA_VAL: begin
                    if (i2c_data_ready) begin
                        i2c_data_valid <= 1'b1;
                        i2c_data_tdata <= 8'h0F;        // Threshold value
                        i2c_data_last <= 1'b1;
                        next_state <= ENABLE_ELECTRODE;
                    end
                end

                ENABLE_ELECTRODE: begin
                    if (i2c_cmd_ready) begin
                        // Enable electrode 0 (0x5E = 0x00)
                        i2c_cmd_addr <= 7'h5A;
                        i2c_cmd_start <= 1'b1;
                        i2c_cmd_write_multiple <= 1'b1;
                        i2c_cmd_stop <= 1'b1;
                        i2c_cmd_valid <= 1'b1;
                        i2c_data_tdata <= 8'h5E;        // ECR register
                        next_state <= SEND_ENABLE_DATA_REG;
                    end
                end

                SEND_ENABLE_DATA_REG: begin
                    if (i2c_data_ready) begin
                        i2c_data_valid <= 1'b1;
                        i2c_data_tdata <= 8'h5E;        // ECR register
                        next_state <= SEND_ENABLE_DATA_VAL;
                    end
                end

                SEND_ENABLE_DATA_VAL: begin
                    if (i2c_data_ready) begin
                        i2c_data_valid <= 1'b1;
                        i2c_data_tdata <= 8'h0f;
                        i2c_data_last <= 1'b1;
                        next_state <= SET_READ_ADDR;
                    end
                end

                SET_READ_ADDR: begin
                    if (i2c_cmd_ready) begin
                        // Set address pointer to 0x00
                        i2c_cmd_addr <= 7'h5A;
                        i2c_cmd_start <= 1'b1;
                        i2c_cmd_write <= 1'b1;
                        i2c_cmd_stop <= 1'b0;
                        i2c_cmd_valid <= 1'b1;
                        i2c_data_tdata <= 8'h00;        // Status register
                        next_state <= SEND_ADDR_DATA;
                    end
                end

                SEND_ADDR_DATA: begin
                    if (i2c_data_ready) begin
                        i2c_data_valid <= 1'b1;
                        next_state <= READ_STATUS;
                    end
                end

                READ_STATUS: begin
                    if (i2c_cmd_ready) begin
                        // Read two status bytes
                        i2c_cmd_addr <= 7'h5A;
                        i2c_cmd_start <= 1'b1;
                        i2c_cmd_read <= 1'b1;
                        i2c_cmd_stop <= 1'b1;
                        i2c_cmd_write <= 1'b0;
                        i2c_cmd_valid <= 1'b1;
                        next_state <= RECEIVE_DATA;
                    end
                end

                RECEIVE_DATA: begin
                    if (i2c_rx_valid) begin
                        next_state <= DELAY;
                        leds[5:0] <= i2c_rx_data;
                    end
                end

                DELAY: begin
                    // Wait before next read
                    if (delay_counter == 24'h000FFF) begin
                        delay_counter <= 0;
                        next_state <= SET_READ_ADDR;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end

                default: next_state <= INIT;
            endcase
        end
    end

endmodule