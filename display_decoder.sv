`define DIGIT_COUNT_WIDTH 2

module display_decoder (
    input wire clk,
    input wire rst,
    input wire [`DIGIT_COUNT_WIDTH-1:0] digit_count,
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

`define DECIMAL_DIGITS(W)  (  (((W)*1233 + 4095) / 4096)  )


reg [2:0] current_segment_reg = 0;
reg [3:0] current_digit_index_reg;
reg busy_reg = 0;
reg led_data_reg;
reg [1:0] digit_count_reg;
reg [15:0] data_reg;
wire [4:0] current_digit = data_reg % 10;

wire [6:0] segments;


assign busy = busy_reg;
assign led_data = segments[current_segment_reg];

assign segments = (current_digit == 4'd0) ? 7'b1111110 :
                  (current_digit == 4'd1) ? 7'b1000010 :
                  (current_digit == 4'd2) ? 7'b0110111 :
                  (current_digit == 4'd3) ? 7'b1100111 :
                  (current_digit == 4'd4) ? 7'b1001011 :
                  (current_digit == 4'd5) ? 7'b1101101 :
                  (current_digit == 4'd6) ? 7'b1111101 :
                  (current_digit == 4'd7) ? 7'b1000111 :
                  (current_digit == 4'd8) ? 7'b1111111 :
                  (current_digit == 4'd9) ? 7'b1101111 :
                  7'b1011110;

always_ff @(posedge clk) begin
    if(rst) begin
        state <= STATE_IDLE;
        busy_reg <= 0;
        current_digit_index_reg <= 0;
        current_segment_reg <= 0;
    end else begin
        case (state)
            STATE_IDLE: begin
                busy_reg <= 0;
                
                if(next_led) begin
                    digit_count_reg <= digit_count;
                    data_reg <= data;
                    current_digit_index_reg <= 0;
                    current_segment_reg <= 0;
                    busy_reg <= 1;
                    state <= STATE_PROCESSING;
                end
            end

            STATE_PROCESSING: begin
                if(next_led) begin
                    current_segment_reg <= current_segment_reg + 1;

                    if(digit_count_reg - current_digit_index_reg <= 1) begin // last iteration
                        if(current_segment_reg == 5) begin
                            state = STATE_IDLE;
                            busy_reg <= 0;
                        end
                    end else begin
                        if(current_segment_reg >= 6) begin
                            current_segment_reg <= 0;
                            current_digit_index_reg <= current_digit_index_reg + 1;
                            data_reg /= 10;
                        end
                    end
                end
            end
        endcase
    end
end

endmodule