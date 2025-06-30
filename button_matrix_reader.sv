module button_matrix_reader (
    input  clk,        // 27 MHz system clock (Tang Nano 9K)
    input  reset,      // Reset signal
    output reg [3:0] rows,   // Row outputs (active low)
    input [3:0] cols,        // Column inputs
    output reg [15:0] button_state // 16-bit button states (1=pressed)
);

// Clock divider: 27 MHz -> 1 kHz (period = 1 ms)
reg [14:0] clk_div;
reg slow_clk_en;  // 1 kHz clock enable

always @(posedge clk or posedge reset) begin
    if (reset) begin
        clk_div <= 0;
        slow_clk_en <= 0;
    end else begin
        if (clk_div == 26999) begin // 27,000 cycles - 1
            clk_div <= 0;
            slow_clk_en <= 1;
        end else begin
            clk_div <= clk_div + 1;
            slow_clk_en <= 0;
        end
    end
end

// Row counter (0 to 3)
reg [1:0] row_counter;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        row_counter <= 0;
    end else if (slow_clk_en) begin
        row_counter <= row_counter + 1;
    end
end

// Drive rows: Active-low scanning
always @(posedge clk or posedge reset) begin
    if (reset) begin
        rows <= 4'b1111;
    end else begin
        rows <= ~(4'b0001 << row_counter);
    end
end

// Register column inputs
reg [3:0] col_reg;

always @(posedge clk) begin
    if (slow_clk_en) begin
        col_reg <= cols;
    end
end

// Capture button state for current row
reg [15:0] raw_button_state;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        raw_button_state <= 0;
    end else if (slow_clk_en) begin
        case (row_counter)
            2'd0: raw_button_state[3:0]   <= ~col_reg; // Invert: 0=pressed->1
            2'd1: raw_button_state[7:4]   <= ~col_reg;
            2'd2: raw_button_state[11:8]  <= ~col_reg;
            2'd3: raw_button_state[15:12] <= ~col_reg;
        endcase
    end
end

// Frame update pulse (triggered after last row scan)
wire frame_update = (slow_clk_en && (row_counter == 2'd3));

// Debounce registers
reg [15:0] current_frame_state;
reg [15:0] stored_frame_state;
reg [4:0] debounce_count; // Debounce counter (0-20 ms)

always @(posedge clk) begin
    if (frame_update) begin
        current_frame_state <= raw_button_state;
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        stored_frame_state <= 0;
        debounce_count <= 0;
    end else if (frame_update) begin
        if (current_frame_state == stored_frame_state) begin
            if (debounce_count < 5) debounce_count <= debounce_count + 1;
        end else begin
            stored_frame_state <= current_frame_state;
            debounce_count <= 0;
        end
    end
end

// Update debounced button state
always @(posedge clk or posedge reset) begin
    if (reset) begin
        button_state <= 0;
    end else if (frame_update && (debounce_count == 5)) begin
        button_state <= stored_frame_state;
    end
end

endmodule