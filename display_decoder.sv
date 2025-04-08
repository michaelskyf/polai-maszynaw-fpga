module display_decoder (
    input wire clk,
    input wire rst,
    input wire [1:0] digit_count,
    input wire [15:0] data,
    input wire next_led,
    output wire led_data,
    output wire busy
);

typedef enum logic {
    STATE_IDLE,
    STATE_PROCESSING
} state_t;
state_t state;

reg [2:0] current_segment_reg;
reg [3:0] current_digit_index_reg;
reg busy_reg = 0;
reg led_data_reg;
reg [1:0] digit_count_reg;
reg [15:0] data_reg;
wire [4:0] current_digit = data_reg % 10;

reg [6:0] segments;


assign busy = busy_reg;
assign led_data = led_data_reg;

always_comb begin
    case(current_digit)
        4'd0: segments = 7'b1111110;
        4'd1: segments = 7'b1000010;
        4'd2: segments = 7'b0110111;
        4'd3: segments = 7'b0100101;
        4'd4: segments = 7'b1001011;
        4'd5: segments = 7'b1101101;
        4'd6: segments = 7'b1111101;
        4'd7: segments = 7'b1000111;
        4'd8: segments = 7'b1111111;
        4'd9: segments = 7'b1101111;
        default: segments = 7'b1111111;
    endcase
end

always_ff @(posedge clk) begin
    if(rst) begin
        state <= STATE_IDLE;
        busy_reg <= 0;
        current_digit_index_reg <= 0;
    end else begin
        case (state)
            STATE_IDLE: begin
                busy_reg <= 0;

                if(next_led) begin
                    digit_count_reg <= digit_count;
                    data_reg <= data;
                    busy_reg <= 1;
                    current_segment_reg <= 1;
                    current_digit_index_reg <= 0;
                    led_data_reg <= segments[0];
                    state <= STATE_PROCESSING;
                end
            end

            STATE_PROCESSING: begin
                if(next_led) begin
                    led_data_reg <= segments[current_segment_reg];
                    current_segment_reg <= current_segment_reg + 1;

                    if(current_segment_reg >= 6) begin
                        current_segment_reg <= 0;
                        current_digit_index_reg <= current_digit_index_reg + 1;

                        if(current_digit_index_reg + 1 >= digit_count_reg) begin
                            state = STATE_IDLE;
                            busy_reg <= 0;
                        end
                    end
                end
            end
        endcase
    end
end

endmodule