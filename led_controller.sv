`include "led_driver_const_color.sv"
`include "display_decoder.sv"

package led_controller_defs;

typedef enum logic {
    CELL_TYPE_LED,
    CELL_TYPE_DISPLAY
} cell_type_t;

typedef struct packed {
    bit [16:0] padding;
    bit value;
} led_data_t;

typedef struct packed {
    bit [1:0] digit_count;
    bit [15:0] value;
} display_data_t;

typedef struct packed {
    cell_type_t cell_type;

    union packed {
        led_data_t led_data;
        display_data_t display_data;
    } data;
} cell_t;


endpackage

module led_decoder_multiplexer (
    input wire clk,
    input wire rst,
    input wire decode_next_led,
    input led_controller_defs::cell_t data,
    output wire busy,
    output wire led_out
);

wire dd_next_led;
wire [15:0] dd_data = data.data.display_data.value;
wire dd_busy;
wire [1:0] dd_digit_count;
wire dd_led_data;

assign led_out = data.cell_type == led_controller_defs::CELL_TYPE_DISPLAY ? dd_led_data : data.data.led_data.value;
assign dd_next_led = data.cell_type == led_controller_defs::CELL_TYPE_DISPLAY ? decode_next_led : 0;
assign busy = data.cell_type == led_controller_defs::CELL_TYPE_DISPLAY ? dd_busy : 0;
assign dd_digit_count = data.data.display_data.digit_count;

display_decoder dd (
    .clk(clk),
    .rst(rst),
    .digit_count(dd_digit_count),
    .data(dd_data),
    .next_led(dd_next_led),
    .led_data(dd_led_data),
    .busy(dd_busy)
);

endmodule

module led_controller #(
    parameter ARRAY_LENGTH = 400,
    parameter LED_COLOR = 24'h00ff00
)(
    input wire clk,
    input wire rst,
    input led_controller_defs::cell_t cells[ARRAY_LENGTH],
    input wire refresh_lock,
    input wire refresh,
    output wire led_out
);

typedef enum logic [1:0] {
    STATE_IDLE,
    STATE_PROCESSING_1,
    STATE_PROCESSING_2,
    STATE_PROCESSING_3
} state_t;
state_t state;

led_controller_defs::cell_t cells_reg[ARRAY_LENGTH];
reg refresh_reg;
reg [31:0] array_index;

led_controller_defs::cell_t current_cell;
assign current_cell = cells_reg[array_index];

reg ldm_decode_next_led;
led_controller_defs::cell_t ldm_data;
wire ldm_busy;
wire ldm_led_out;

assign ldm_data = current_cell;

led_decoder_multiplexer ldm(
    .clk(clk),
    .rst(rst),
    .decode_next_led(ldm_decode_next_led),
    .data(ldm_data),
    .busy(ldm_busy),
    .led_out(ldm_led_out)
);

wire ldcc_busy;
wire ldcc_data_latched;
wire ldcc_led_out;
reg ldcc_ready;
reg ldcc_data;

assign led_out = ldcc_led_out;

led_driver_const_color ldcc(
    .clk(clk),
    .rst(rst),
    .ready(ldcc_ready),
    .data(ldcc_data),
    .busy(ldcc_busy),
    .data_latched(ldcc_data_latched),
    .led_out(ldcc_led_out)
);

always_ff @(posedge clk) begin
    if(rst) begin
        refresh_reg <= 0;
        state <= STATE_IDLE;
    end else begin
        refresh_reg <= refresh_reg | refresh;
        ldm_decode_next_led <= 0;
        ldcc_ready <= 0;

        case(state)
            STATE_IDLE: begin
                if(refresh_reg && !refresh_lock) begin
                    state <= STATE_PROCESSING_1;
                    refresh_reg <= 0;
                    cells_reg <= cells;
                    array_index <= 0;
                end
            end
            STATE_PROCESSING_1: begin
                ldm_decode_next_led <= 1;
                ldcc_data <= ldm_led_out;
                state <= STATE_PROCESSING_2;
            end
            STATE_PROCESSING_2: begin
                ldcc_ready <= 1;

                if(ldcc_data_latched) begin
                    ldcc_data <= ldm_led_out;

                    if(ldm_busy) begin
                        ldm_decode_next_led <= 1;
                    end else begin
                        array_index <= array_index + 1;
                        if(array_index + 1 >= ARRAY_LENGTH) begin
                            state <= STATE_PROCESSING_3;
                        end
                    end
                end
            end
            STATE_PROCESSING_3: begin
                if(!ldcc_busy) begin
                    state <= STATE_IDLE;
                end
            end
            default: begin
                state <= STATE_IDLE;
            end
        endcase
    end
end

endmodule