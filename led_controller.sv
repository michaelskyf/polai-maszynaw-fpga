`include "led_driver_const_color.sv"

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

module led_controller #(
    parameter ARRAY_LENGTH = 400,
    parameter LED_COLOR = 24'h00ff00
)(
    input cell_t [ARRAY_LENGTH:0] cells,
    input wire refresh_lock,
    input reg refresh
);

endmodule