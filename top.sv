`include "i2c_master.sv"
`include "led_controller.sv"

module top (
    input  clk_27M,
    output logic led_out,
    output logic led_out2,
    output logic [5:0] leds,

    inout  wire       i2c_scl_pin,  // I2C SCL
    inout  wire       i2c_sda_pin   // I2C SDA
);

    reg [63:0] tsc;

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
    logic i2c_m_data_ready;

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
        .m_axis_data_tready(i2c_m_data_ready),
        .m_axis_data_tlast(i2c_rx_last),
        .scl_i(scl_i),
        .scl_o(scl_o),
        .scl_t(scl_t),
        .sda_i(sda_i),
        .sda_o(sda_o),
        .sda_t(sda_t),
        .busy(i2c_busy),
        .prescale(16'h00C8), // 27kHz @ 27MHz
        .stop_on_idle(1'b0)
    );

    `define SET_LEDS(cells, len, val) \
        for(int i = 0; i < len; i++) begin \
            cells[index].cell_type <= led_controller_defs::CELL_TYPE_LED; \
            cells[index].data.led_data.value <= val; \
            index++; \
        end


    `define SET_DISPLAY(cells, _digit_count, val) \
        cells[index].cell_type <= led_controller_defs::CELL_TYPE_DISPLAY; \
        cells[index].data.display_data.digit_count <= _digit_count; \
        cells[index].data.display_data.value <= val; \
        index++;

    `define TOGGLE_BUTTON(button, timer, read_value) \
        if(!read_value) begin \
            if(tsc - timer >= 2_700_000) begin \
                button <= !button; \
            end \
            timer <= tsc; \
        end

    localparam ARRAY_LENGTH = 39;

    reg il;
    reg [63:0] il_timer;
    reg wel;
    reg [63:0] wel_timer;
    reg wyl;
    reg [63:0] wyl_timer;
    reg wyad;
    reg [63:0] wyad_timer;
    reg wei;
    reg [63:0] wei_timer;
    reg _weak;
    reg [63:0] weak_timer;
    reg dod;
    reg [63:0] dod_timer;
    reg ode;
    reg [63:0] ode_timer;

    reg przep;
    reg [63:0] przep_timer;
    reg wyak;
    reg [63:0] wyak_timer;
    reg weja;
    reg [63:0] weja_timer;
    reg wea;
    reg [63:0] wea_timer;
    reg czyt;
    reg [63:0] czyt_timer;
    reg pisz;
    reg [63:0] pisz_timer;
    reg wes;
    reg [63:0] wes_timer;
    reg wys;
    reg [63:0] wys_timer;

    int index = 0;
    led_controller_defs::cell_t lc_cells[ARRAY_LENGTH];
    //led_controller_defs::cell_t lc_cells2[ARRAY_LENGTH];
    always_ff @(posedge clk_27M) begin
        begin
            // A Reg
            `SET_DISPLAY(lc_cells, 3, 420);

            // WEA button
            `SET_LEDS(lc_cells, 3, wea);

            // Line 0 index
            `SET_DISPLAY(lc_cells, 2, 13);
            // Line 0 value
            `SET_DISPLAY(lc_cells, 3, 37);
            // Line 0 instruction
            `SET_DISPLAY(lc_cells, 2, 69);

            // Czyt 0
            `SET_LEDS(lc_cells, 1, czyt);
            // Pisz 0
            `SET_LEDS(lc_cells, 1, pisz);
            // Pisz 1
            `SET_LEDS(lc_cells, 1, pisz);
            // Czyt 1
            `SET_LEDS(lc_cells, 1, czyt);

            // Line 1 instruction
            `SET_DISPLAY(lc_cells, 2, 69);
            // Line 1 value
            `SET_DISPLAY(lc_cells, 3, 37);
            // Line 1 index
            `SET_DISPLAY(lc_cells, 2, 13);

            // Line 2 index
            `SET_DISPLAY(lc_cells, 2, 13);
            // Line 2 value
            `SET_DISPLAY(lc_cells, 3, 37);
            // Line 2 instruction
            `SET_DISPLAY(lc_cells, 2, 69);

            // Line 3 index
            `SET_DISPLAY(lc_cells, 2, 13);
            // Line 3 value
            `SET_DISPLAY(lc_cells, 3, 37);
            // Line 3 instruction
            `SET_DISPLAY(lc_cells, 2, 69);

            // S Reg
            `SET_DISPLAY(lc_cells, 3, 69);

            // WES button
            `SET_LEDS(lc_cells, 9, wes);

            // WYS button
            `SET_LEDS(lc_cells, 9, wys);

            index = 0;
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

    // led_controller #(.ARRAY_LENGTH(ARRAY_LENGTH)) lc2 (
    //     .clk(clk_27M),
    //     .rst(reset),
    //     .cells(lc_cells2),
    //     .refresh_lock(0),
    //     .refresh(1),
    //     .led_out(led_out2)
    // );
    // State machine
    typedef enum {
        SOFT_RESET             ,
        SEND_RESET_DATA_REG    ,
        SEND_RESET_DATA_VAL    ,
        SET_READ_ADDR          ,
        SEND_ADDR_DATA         ,
        READ_STATUS            ,
        RECEIVE_DATA           ,

        // Finally: ECR
        SEND_ECR         ,
        SEND_ECR_REG     ,
        SEND_ECR_VAL     
    } state_t;


    state_t current_state = SOFT_RESET;

    always_ff @(posedge clk_27M) begin
        if (reset) begin
            current_state <= SOFT_RESET;
            leds <= 0;
            il <= 0;
            il_timer <= 0;
            wel <= 0;
            wel_timer <= 0;
            wyl <= 0;
            wyl_timer <= 0;
            wyad <= 0;
            wyad_timer <= 0;
            wei <= 0;
            wei_timer <= 0;
            _weak <= 0;
            weak_timer <= 0;
            dod <= 0;
            dod_timer <= 0;
            ode <= 0;
            ode_timer <= 0;

            przep <= 0;
            przep_timer <= 0;
            wyak <= 0;
            wyak_timer <= 0;
            weja <= 0;
            weja_timer <= 0;
            wea <= 0;
            wea_timer <= 0;
            czyt <= 0;
            czyt_timer <= 0;
            pisz <= 0;
            pisz_timer <= 0;
            wes <= 0;
            wes_timer <= 0;
            wys <= 0;
            wys_timer <= 0;
            tsc <= 0;
        end else begin
            leds[5:0] <= ~current_state;
            tsc <= tsc + 1;

            // Default values for I2C signals
            i2c_cmd_start <= 1'b0;
            i2c_cmd_read <= 1'b0;
            i2c_cmd_write <= 1'b0;
            i2c_cmd_stop <= 1'b0;
            i2c_cmd_valid <= 1'b0;
            i2c_data_valid <= 1'b0;
            i2c_data_last <= 1'b0;
            i2c_cmd_write_multiple <= 1'b0;
            i2c_m_data_ready <= 0;

            case (current_state)
                SOFT_RESET: begin
                    // Write to soft reset register (0x80)
                    if (i2c_cmd_valid && i2c_cmd_ready) begin
                        current_state <= SEND_RESET_DATA_REG;
                    end else begin
                        i2c_cmd_addr <= 7'h5A;          // MPR121 address
                        i2c_cmd_start <= 1'b1;
                        i2c_cmd_write_multiple <= 1'b1;
                        i2c_cmd_stop <= 1'b1;
                        i2c_cmd_valid <= 1'b1;
                    end
                end

                SEND_RESET_DATA_REG: begin
                    if (i2c_data_valid && i2c_data_ready) begin
                        current_state <= SEND_RESET_DATA_VAL;
                    end else begin
                        i2c_data_valid <= 1'b1;
                        i2c_data_tdata <= 8'h80;        // Register address
                    end
                end

                SEND_RESET_DATA_VAL: begin
                    if (i2c_data_valid && i2c_data_ready) begin
                        current_state <= SEND_ECR;
                    end else begin
                        i2c_data_valid <= 1'b1;
                        i2c_data_tdata <= 8'h63;        // Reset value
                        i2c_data_last <= 1'b1;
                    end
                end

                // ─── FINALLY: ENABLE ALL ELECTRODES (ECR) ──────────────────────────────────
                SEND_ECR: begin
                    if (i2c_cmd_valid && i2c_cmd_ready) begin
                        current_state <= SEND_ECR_REG;
                    end else begin
                        i2c_cmd_addr          <= 7'h5A;
                        i2c_cmd_start         <= 1'b1;
                        i2c_cmd_write_multiple<= 1'b1;
                        i2c_cmd_stop          <= 1'b1;
                        i2c_cmd_valid         <= 1'b1;
                    end
                end
                SEND_ECR_REG: begin
                    if (i2c_data_valid && i2c_data_ready) begin
                        current_state <= SEND_ECR_VAL;
                    end else begin
                        i2c_data_valid <= 1'b1;
                        i2c_data_tdata <= 8'h5E;    // MPR121_ECR
                    end
                end
                SEND_ECR_VAL: begin
                    if (i2c_data_valid && i2c_data_ready) begin
                        current_state <= SET_READ_ADDR;
                    end else begin
                        i2c_data_valid <= 1'b1;
                        i2c_data_tdata <= 8'b1000_1100; // 0x80 + 12 electrodes
                        i2c_data_last  <= 1'b1;
                    end
                end

                SET_READ_ADDR: begin
                    // Set address pointer to 0x00
                    if (i2c_cmd_valid && i2c_cmd_ready) begin
                        current_state <= SEND_ADDR_DATA;
                    end else begin
                        i2c_cmd_addr <= 7'h5A;
                        i2c_cmd_start <= 1'b1;
                        i2c_cmd_write <= 1'b1;
                        i2c_cmd_stop <= 1'b0;
                        i2c_cmd_valid <= 1'b1;
                    end
                end

                SEND_ADDR_DATA: begin
                    if (i2c_data_valid && i2c_data_ready) begin
                        current_state <= READ_STATUS;
                    end else begin
                        i2c_data_tdata <= 8'h00;        // Status register
                        i2c_data_valid <= 1'b1;
                    end
                end

                READ_STATUS: begin
                    // Read two status bytes
                    if (i2c_cmd_valid && i2c_cmd_ready) begin
                        current_state <= RECEIVE_DATA;
                    end else begin
                        i2c_cmd_addr <= 7'h5A;
                        i2c_cmd_start <= 1'b1;
                        i2c_cmd_read <= 1'b1;
                        i2c_cmd_stop <= 1'b1;
                        i2c_cmd_valid <= 1'b1;
                    end
                end

                RECEIVE_DATA: begin
                    if (i2c_m_data_ready && i2c_rx_valid) begin
                        current_state <= SET_READ_ADDR;
                        i2c_m_data_ready <= 0;
                        `TOGGLE_BUTTON(przep, przep_timer, i2c_rx_data[0]);
                        `TOGGLE_BUTTON(wyak, wyak_timer, i2c_rx_data[1]);
                        `TOGGLE_BUTTON(weja, weja_timer, i2c_rx_data[2]);
                        `TOGGLE_BUTTON(wea, wea_timer, i2c_rx_data[3]);
                        `TOGGLE_BUTTON(czyt, czyt_timer, i2c_rx_data[4]);
                        `TOGGLE_BUTTON(pisz, pisz_timer, i2c_rx_data[5]);
                        `TOGGLE_BUTTON(wes, wes_timer, i2c_rx_data[6]);
                        `TOGGLE_BUTTON(wys, wys_timer, i2c_rx_data[7]);
                    end else begin
                        i2c_m_data_ready <= 1;
                    end
                end
            endcase
        end
    end

endmodule