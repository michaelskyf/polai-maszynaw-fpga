module maszyna_w_core2 #(
    // CPU word width
    parameter WORD_WIDTH = 32,
    // CPU address bus width (<WORD_WIDTH)
    parameter ADDRESS_WIDTH = 16,
    // CPU instruction opcode width
    parameter KOD_WIDTH = WORD_WIDTH - ADDRESS_WIDTH
) (
    input clk,

    // Async active high reset
    input reset,

    // Input signal array
    input [31:0] signals,

    // Output signal error array, active high when signals are mismatched
    output [31:0] signal_errors,

    // Memory/register override interface
    // override_write high overrides machine cycle and writes override_word
    // to memory[override_address] or local register (most significant bit == 1)
    input override_write,
    input [ADDRESS_WIDTH-1 + 1:0] override_address,
    input [WORD_WIDTH-1:0] override_word,

    // Local registers' values
    output reg [ADDRESS_WIDTH-1:0] L,
    output reg [WORD_WIDTH-1:0] I,
    output reg [WORD_WIDTH-1:0] Ak,
    output reg [ADDRESS_WIDTH-1:0] A,
    output reg [WORD_WIDTH-1:0] S,

    // Bus values (async)
    output [ADDRESS_WIDTH-1:0] magA,
    output [WORD_WIDTH-1:0] magS,
    output [WORD_WIDTH-1:0] magAk,

    // Machine W flags
    output ZF,
    output ZAK,

    // Local registers' derivative registers
    output [KOD_WIDTH-1:0] KOD,
    output [ADDRESS_WIDTH-1:0] ADRES

);
    reg [WORD_WIDTH-1:0] memory [0:2**ADDRESS_WIDTH-1];

    assign ZF = Ak[WORD_WIDTH-1];
    assign ZAK = Ak == 0;
    assign KOD = I[KOD_WIDTH-1:0];
    assign ADRES = I[WORD_WIDTH-1:KOD_WIDTH];

    // Signals mapping (can be reordered)
    wire dod, ode, wweak, wyak;
    assign {dod, ode, wweak, wyak} = signals[3:0];

    wire wei, wyad;
    assign {wei, wyad} = signals[5:4];

    wire wel, wyl, il;
    assign {wel, wyl, il} = signals[8:6];

    wire pisz, czyt, wes, wys, wea;
    assign {pisz, czyt, wes, wys, wea} = signals[13:9];

    wire przep, weja;
    assign {przep, weja} = signals[15:14];

    // Signal errors detection (eg. more than one driver for a register)
    wire err_s;
    wire err_l;
    wire err_ak;

    assign err_s = (
        (czyt ? 2'b01 : 2'b00) +
        (wes ? 2'b01 : 2'b00)
    ) >= 2;

    assign err_l = (
        (wel ? 2'b01 : 2'b00) +
        (il ? 2'b01 : 2'b00)
    ) >= 2;

    assign err_ak = (
        (przep ? 2'b01 : 2'b00) +
        (dod ? 2'b01 : 2'b00) +
        (ode ? 2'b01 : 2'b00)
    ) >= 2;

    // Signal errors mapping
    assign signal_errors[12] = err_s;
    assign signal_errors[11] = err_s;

    assign signal_errors[8] = err_l;
    assign signal_errors[6] = err_l;

    assign signal_errors[15] = err_ak;
    assign signal_errors[3] = err_ak;
    assign signal_errors[2] = err_ak;

    assign signal_errors[31:16] = {16 {1'b0}};
    assign signal_errors[14:13] = {2 {1'b0}};
    assign signal_errors[10:9] = {2 {1'b0}};
    assign signal_errors[7] = {1 {1'b0}};
    assign signal_errors[5:4] = {2 {1'b0}};
    assign signal_errors[1:0] = {2 {1'b0}};

    // Sum-on-wire approach on magA
    assign magA[ADDRESS_WIDTH-1:0] = (
        ({ADDRESS_WIDTH {wyl}} & L) |
        ({ADDRESS_WIDTH {wyad}} & ADRES)
    );

    // Sum-on-wire approach on magS
    assign magS[WORD_WIDTH-1:0] = (
        ({WORD_WIDTH {wys}} & S) |
        ({WORD_WIDTH {wyak}} & Ak)
    );

    assign magAk[WORD_WIDTH-1:0] = (
        ({WORD_WIDTH {weja}} & magS)
    );

    always @(posedge clk or posedge reset)
    begin:pos_clk_rst_proc
        if(reset)
            begin:reset_proc
                L <= {ADDRESS_WIDTH {1'b0}};
                I <= {WORD_WIDTH {1'b0}};
                Ak <= {WORD_WIDTH {1'b0}};
                A <= {ADDRESS_WIDTH {1'b0}};
                S <= {WORD_WIDTH {1'b0}};
            end//:reset_proc
        else if(override_write)
            begin:override_proc

                // Most significant bit set to 1 determines local registers, 0 determines memory
                case (override_address)
                    ({{1'b1}, {ADDRESS_WIDTH {1'b0}}} + 3'd1): L <= override_word[ADDRESS_WIDTH-1:0];
                    ({{1'b1}, {ADDRESS_WIDTH {1'b0}}} + 3'd2): I <= override_word;
                    ({{1'b1}, {ADDRESS_WIDTH {1'b0}}} + 3'd3): Ak <= override_word;
                    ({{1'b1}, {ADDRESS_WIDTH {1'b0}}} + 3'd4): A <= override_word[ADDRESS_WIDTH-1:0];
                    ({{1'b1}, {ADDRESS_WIDTH {1'b0}}} + 3'd5): S <= override_word;

                    default: memory[override_address[ADDRESS_WIDTH-1:0]] <= override_word;
                endcase

            end//:override_proc
        else
            begin:machine_cycle_proc
                if(czyt)
                    S <= memory[A];
                else if(wes)
                    S <= magS;

                if(pisz)
                    memory[A] <= S;

                if(wea)
                    A <= magA;

                if(wel)
                    L <= magA;
                else if(il)
                    L <= L + 1;

                if(wei)
                    I <= magS;

                if(wweak)
                begin:ak_write_proc
                    if(przep)
                        Ak <= magAk;
                    else if(dod)
                        Ak <= Ak + magAk;
                    else if(ode)
                        Ak <= Ak - magAk;
                    else
                        Ak <= {WORD_WIDTH {1'b0}};
                end//:ak_write_proc

            end//:machine_cycle_proc
    end//:pos_clk_rst_proc

endmodule