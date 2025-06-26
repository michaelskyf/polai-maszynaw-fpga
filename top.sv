// `include "i2c_master.sv"
`include "led_controller.sv"
`include "uart_rx.sv"
`include "maszyna_w_core2.sv"

module top (
    input  clk_27M,
    input  uart_rx,
    output uart_tx,
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

    localparam ARRAY_LENGTH = 39;
    localparam ARRAY_LENGTH2 = 100;

    reg il;
    reg wel;
    reg wyl;
    reg wyad;
    reg wei;
    reg _weak;
    reg dod;
    reg ode;

    reg przep;
    reg wyak;
    reg weja;
    reg wea;
    reg czyt;
    reg pisz;
    reg wes;
    reg wys;
    reg takt;

    // Registers
    wire [63:0] l_reg;
    wire [63:0] i_reg;
    wire [63:0] ak_reg;
    wire [63:0] a_reg;
    wire [63:0] s_reg;
    wire [63:0] a_mag;
    wire [63:0] s_mag;
    wire [63:0] ak_mag;
    wire [31:0] pao [0:255];

    wire stop_flag;
    wire zf_flag;


    int index = 0;
    led_controller_defs::cell_t lc_cells[ARRAY_LENGTH];
    led_controller_defs::cell_t lc_cells2[ARRAY_LENGTH2];
    always_ff @(posedge clk_27M) begin
        begin

            // A Reg
            `SET_DISPLAY(lc_cells, 3, a_reg);

            // WEA button
            `SET_LEDS(lc_cells, 3, wea);

            // Line 0 index
            `SET_DISPLAY(lc_cells, 2, 0);
            // Line 0 value
            `SET_DISPLAY(lc_cells, 3, pao[0]);
            // Line 0 instruction
            `SET_DISPLAY(lc_cells, 2, 0);

            // Czyt 0
            `SET_LEDS(lc_cells, 1, czyt);
            // Pisz 0
            `SET_LEDS(lc_cells, 1, pisz);
            // Pisz 1
            `SET_LEDS(lc_cells, 1, pisz);
            // Czyt 1
            `SET_LEDS(lc_cells, 1, czyt);

            // Line 1 instruction
            `SET_DISPLAY(lc_cells, 2, 0);
            // Line 1 value
            `SET_DISPLAY(lc_cells, 3, pao[1]);
            // Line 1 index
            `SET_DISPLAY(lc_cells, 2, 1);

            // Line 2 index
            `SET_DISPLAY(lc_cells, 2, 2);
            // Line 2 value
            `SET_DISPLAY(lc_cells, 3, pao[2]);
            // Line 2 instruction
            `SET_DISPLAY(lc_cells, 2, 0);

            // Line 3 index
            `SET_DISPLAY(lc_cells, 2, 3);
            // Line 3 value
            `SET_DISPLAY(lc_cells, 3, pao[3]);
            // Line 3 instruction
            `SET_DISPLAY(lc_cells, 2, 0);

            // S Reg
            `SET_DISPLAY(lc_cells, 3, s_reg);

            // WES button
            `SET_LEDS(lc_cells, 9, wes);

            // WYS button
            `SET_LEDS(lc_cells, 9, wys);

            index = 0;

            // Licznik
            `SET_DISPLAY(lc_cells2, 3, l_reg);

            // WEL
            `SET_LEDS(lc_cells2, 3, 0);

            // WYL
            `SET_LEDS(lc_cells2, 3, 1);

            // IL
            `SET_LEDS(lc_cells2, 3, 0);

            // Magistrala jakaś
            `SET_LEDS(lc_cells2, 35, 1);

            // STOP
            `SET_LEDS(lc_cells2, 8, stop_flag);

            // Kolejna część magistralii
            `SET_LEDS(lc_cells2, 8, 1);

            // I
            `SET_DISPLAY(lc_cells2, 3, i_reg);

            // Przycisk
            `SET_LEDS(lc_cells2, 3, 1);

            // Przycisk
            `SET_LEDS(lc_cells2, 4, 0);

            // Przycisk
            `SET_LEDS(lc_cells2, 1, 0);

            // Przycisk
            `SET_LEDS(lc_cells2, 1, 0);

            // Przycisk
            `SET_LEDS(lc_cells2, 1, 0);

            // Przycisk
            `SET_LEDS(lc_cells2, 1, 0);

            // Przycisk
            `SET_LEDS(lc_cells2, 1, 0);

            // Przycisk
            `SET_LEDS(lc_cells2, 1, 0);

            // Przycisk
            `SET_LEDS(lc_cells2, 1, 0);

            // Przycisk
            `SET_LEDS(lc_cells2, 1, 0);

            index = 0;
        end
    end

    // led_controller #(.ARRAY_LENGTH(ARRAY_LENGTH)) lc (
    //     .clk(clk_27M),
    //     .rst(reset),
    //     .cells(lc_cells),
    //     .refresh_lock(0),
    //     .refresh(1),
    //     .led_out(led_out)
    // );

    // led_controller #(.ARRAY_LENGTH(ARRAY_LENGTH2)) lc2 (
    //     .clk(clk_27M),
    //     .rst(reset),
    //     .cells(lc_cells2),
    //     .refresh_lock(0),
    //     .refresh(1),
    //     .led_out(led_out2)
    // );

    wire [31:0] mwc2_signals;
    wire [31:0] mwc2_signal_error;
    wire [63:0] kod;
    wire [63:0] address;

    assign mwc2_signals[3:0] = {dod, ode, _weak, wyak};
    assign mwc2_signals[5:4] = {wei, wyad}; 
    assign mwc2_signals[8:6] = {wel, wyl, il};
    assign mwc2_signals[13:9] = {pisz, czyt, wes, wys, wea};
    assign mwc2_signals[15:14] = {przep, weja};

    maszyna_w_core2 mwc2(
        .clk(clk_27M),
        .reset(reset),
        .signals(0),
        .signal_errors(mwc2_signal_error),
        .override_write(0),
        .override_address(0),
        .override_word(0),
        .L(l_reg),
        .I(i_reg),
        .Ak(ak_reg),
        .A(a_reg),
        .S(s_reg),
        .magA(a_mag),
        .magS(s_mag),
        .magAk(ak_mag),
        .ZF(zf_flag),
        .ZAK(stop_flag),
        .KOD(kod),
        .ADRES(address),
        .pao(pao)
    );

    wire[7:0] uart_data_rev;
    wire[7:0] uart_data = {<<{uart_data_rev}};
    wire uart_complete;
    wire uart_break;
    reg [7:0] uart_data_reg;
    reg [7:0] rx_state;
    reg [63:0] uart_tsc;
    reg uart_en;

    assign uart_tx = uart_rx;

    uart_rx uartrx (
        .clk(clk_27M),
        .resetn(~reset),
        .uart_rxd(uart_rx),
        .uart_rx_en(uart_en),
        .uart_rx_data(uart_data),
        .uart_rx_valid(uart_complete),
        .uart_rx_break(uart_break)
    );

    reg [63:0] counter = 0;
    assign uart_tx = uart_rx;

    always_ff @(posedge clk_27M) begin
        if (reset) begin
            leds <= 6'b0;
            il <= 0;
            wel <= 0;
            wyl <= 0;
            wyad <= 0;
            wei <= 0;
            _weak <= 0;
            dod <= 0;
            ode <= 0;
            takt <= 0;

            przep <= 0;
            wyak <= 0;
            weja <= 0;
            wea <= 0;
            czyt <= 0;
            pisz <= 0;
            wes <= 0;
            wys <= 0;
            tsc <= 0;
            counter <= 0;
            rx_state <= 0;
            uart_en <= 0;
        end else begin
            leds[5:0] <= ~{przep, wyak, weja, czyt, pisz, wes};
            tsc <= tsc + 1;
            takt <= 0;

            case (rx_state)
                0: begin
                    uart_en <= 1;
                    if(uart_complete) begin
                        uart_data_reg <= uart_data;
                        uart_tsc <= tsc;
                        rx_state <= 1;
                        uart_en <= 0;
                    end
                end

                1: begin
                    rx_state <= 0;

                    case (uart_data_reg)
                        "i": il    <= ~il;      // toggle il
                        "e": wel   <= ~wel;     // toggle wel
                        "y": wyl   <= ~wyl;     // toggle wyl
                        "A": wyad  <= ~wyad;    // toggle wyad
                        "f": wei   <= ~wei;     // toggle wei
                        "k": _weak <= ~_weak;   // toggle _weak
                        "d": dod   <= ~dod;     // toggle dod
                        "o": ode   <= ~ode;     // toggle ode
                        "p": przep <= ~przep;   // toggle przep
                        "a": wyak  <= ~wyak;    // toggle wyak
                        "j": weja  <= ~weja;    // toggle weja
                        "w": wea   <= ~wea;     // toggle wea
                        "c": czyt  <= ~czyt;    // toggle czyt
                        "z": pisz  <= ~pisz;    // toggle pisz
                        "s": wes   <= ~wes;     // toggle wes
                        "x": wys   <= ~wys;     // toggle wys
                        "t": begin // Run maszyna W clock
                            takt <= 1;

                            rx_state <= 2;
                        end
                    endcase
                end

                2: begin
                    il <= 0;
                    wel <= 0;
                    wyl <= 0;
                    wyad <= 0;
                    wei <= 0;
                    _weak <= 0;
                    dod <= 0;
                    ode <= 0;

                    przep <= 0;
                    wyak <= 0;
                    weja <= 0;
                    wea <= 0;
                    czyt <= 0;
                    pisz <= 0;
                    wes <= 0;
                    wys <= 0;

                    rx_state <= 0;
                end

                default: begin
                    rx_state <= 0;
                end
            endcase

            
        end
    end

endmodule