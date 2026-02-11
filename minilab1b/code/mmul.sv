`default_nettype none

module mmul #(
    parameter DATA_WIDTH = 8,
    parameter N = 8,
    parameter M = 8
)(
    input  logic i_clk,
    input  logic i_rst_n,
    input  logic i_en,
    input  logic i_clr,

    /* Request and recieve b values from FIFO */
    output logic o_b_rden,
    input  logic [DATA_WIDTH-1:0] i_b,

    /* Request and recieve a values from FIFOs */
    output logic o_a_rden [M],
    input  logic [DATA_WIDTH-1:0] i_a [M-1:0],

    /* Output c values */
    output logic [DATA_WIDTH*3-1:0] o_c [M-1:0]
);

    localparam N_WIDTH = $clog2(N) + 1;

    /* Counter wide enough for N; request N entries from the FIFOs */
    logic [N_WIDTH-1:0] N_counter; 

    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            N_counter <= '0;
        end
        else if (i_clr) begin
            N_counter <= '0;
        end
        else if (i_en) begin
            N_counter <= N_WIDTH'(N);
        end 
        else if (N_counter > 0) begin
            N_counter <= N_counter - N_WIDTH'(1);
        end
    end

    assign o_b_rden = N_counter > 0;

    /* Instantiate vector reducers for each row */
    logic _internal_b_valid [N - 1 + 1:0];
    logic [DATA_WIDTH-1:0] _internal_b [N - 1 + 1:0];

    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            _internal_b_valid[0] <= '0;
        end
        else begin
            _internal_b_valid[0] <= N_counter > 0;
        end
    end
    assign _internal_b[0] = i_b;

    genvar i;
    generate
        for (i = 0; i < M; i++) begin : gen_vector_reducers
            vector_reduce #(DATA_WIDTH) vector_reduce_inst (
                .i_clk,
                .i_rst_n,
                .i_clr,
                .i_b_valid(_internal_b_valid[i]),
                .i_b(_internal_b[i]),
                .o_a_rden(o_a_rden[i]),
                .i_a(i_a[i]),
                .o_b_valid(_internal_b_valid[i + 1]),
                .o_b(_internal_b[i + 1]),
                .o_c(o_c[i])
            );
        end
    endgenerate

endmodule

