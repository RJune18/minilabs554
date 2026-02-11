`default_nettype none

module mmul_fifo_wrapper #(
    parameter DATA_WIDTH = 8,
    parameter N = 8,
    parameter M = 8,
    parameter N_WIDTH = $clog2(N)
)(
    input  wire i_clk_wr_fifo,
    input  wire i_clk_mmul,
    input  wire i_rst_n,
    input  wire i_en_mmul,
    input  wire i_clr,
    
    /* Place values into FIFOs for a */
    input  wire [DATA_WIDTH*M-1:0] i_a,
    input  wire [M-1:0] i_a_valid,
    output wire [M-1:0] o_a_full,

    /* Place values into b's FIFO */
    input  wire [DATA_WIDTH-1:0] i_b,
    input  wire i_b_valid,
    output wire o_b_full,

    /* Output c values */
    output wire [DATA_WIDTH*3*M-1:0] o_c
);

    logic [DATA_WIDTH-1:0] _internal_a [M];
    logic _internal_a_valid [M];
    logic _internal_a_full [M];
    logic [DATA_WIDTH*3-1:0] _internal_c [M];

    genvar i;
    generate
        for (i = 0; i < M; i++) begin : gen_signal_marshalling
            assign _internal_a[i] = i_a[i*DATA_WIDTH+:DATA_WIDTH];
            assign _internal_a_valid[i] = i_a_valid[i];
            assign o_a_full[i] = _internal_a_full[i];
            assign o_c[i*DATA_WIDTH*3+:DATA_WIDTH*3] = _internal_c[i];
        end
    endgenerate

    mmul_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .N(N),
        .M(M),
        .N_WIDTH(N_WIDTH)
    ) mull_fifo_inst (
        .i_clk_wr_fifo,
        .i_clk_mmul,
        .i_rst_n,
        .i_en_mmul,
        .i_clr,
        .i_a(_internal_a),
        .i_a_valid(_internal_a_valid),
        .o_a_full(_internal_a_full),
        .i_b,
        .i_b_valid,
        .o_b_full,
        .o_c(_internal_c)
    );

endmodule

