`default_nettype none

module mmul_fifo #(
    parameter DATA_WIDTH = 8,
    parameter N = 8,
    parameter M = 8,
    parameter N_WIDTH = $clog2(N)
)(
    input  logic i_clk_wr_fifo,
    input  logic i_clk_mmul,
    input  logic i_rst_n,
    input  logic i_en_mmul,
    input  logic i_clr,
    
    /* Place values into FIFOs for a */
    input  logic [DATA_WIDTH-1:0] i_a [M],
    input  logic i_a_valid [M],
    output logic o_a_full [M],

    /* Place values into b's FIFO */
    input  logic [DATA_WIDTH-1:0] i_b,
    input  logic i_b_valid,
    output logic o_b_full,

    /* Output c values */
    output logic [DATA_WIDTH*3-1:0] o_c [M]
);

    logic _internal_a_rden [M];
    logic [DATA_WIDTH-1:0] _internal_a [M];
    logic _internal_b_rden;
    logic [DATA_WIDTH-1:0] _internal_b;

    mmul #(
        .DATA_WIDTH(DATA_WIDTH),
        .N(N),
        .M(M)
    ) mmul_inst (
        .i_clk(i_clk_mmul),
        .i_rst_n,
        .i_en(i_en_mmul),
        .i_clr,
        .o_a_rden(_internal_a_rden),
        .i_a(_internal_a),
        .o_b_rden(_internal_b_rden),
        .i_b(_internal_b),
        .o_c
    );

    fifo_ip fifo_b_inst (
        .aclr(i_clr),
        .data(i_b),
        .rdclk(i_clk_mmul),
        .rdreq(_internal_b_rden),
        .wrclk(i_clk_wr_fifo),
        .wrreq(i_b_valid),
        .q(_internal_b),
        .rdempty(),
        .wrfull(o_b_full)
    );

    genvar i;
    generate
        for (i = 0; i < M; i++) begin : gen_a_fifos
            fifo_ip inst (
                .aclr(i_clr),
                .data(i_a[i]),
                .rdclk(i_clk_mmul),
                .rdreq(_internal_a_rden[M - 1 - i]),
                .wrclk(i_clk_wr_fifo),
                .wrreq(i_a_valid[i]),
                .q(_internal_a[i]),
                .rdempty(),
                .wrfull(o_a_full[i])
            );
        end
    endgenerate

endmodule

