`default_nettype none

module vector_reduce #(
    parameter DATA_WIDTH = 8
)(
    input  logic i_clk,
    input  logic i_rst_n,
    input  logic i_clr,

    /* Recieve b value from previous vector reducer */
    input  logic i_b_valid,
    input  logic [DATA_WIDTH-1:0] i_b,

    /* Request and recieve a values from FIFO */
    output logic o_a_rden,
    input  logic [DATA_WIDTH-1:0] i_a,

    /* Output b value for next vector reducer */
    output logic o_b_valid,
    output logic [DATA_WIDTH-1:0] o_b,
    
    /* Output c value */
    output logic [DATA_WIDTH*3-1:0] o_c
);

    MAC #(DATA_WIDTH) mac_inst (
        .clk(i_clk),
        .rst_n(i_rst_n),
        /* 
         * Reading from o_b* instead of i_b*, as there is a 1 cycle delay
         * between asserting o_a_rden and i_a becoming valid
         */
        .En(o_b_valid),
        .Clr(i_clr),
        .Ain(i_a),
        .Bin(o_b),
        .Cout(o_c)
    );

    assign o_a_rden = i_b_valid;

    always_ff @(posedge i_clk, negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_b_valid <= '0;
            o_b <= '0;
        end
        else begin
            o_b_valid <= i_b_valid;
            o_b <= i_b;
        end
    end

endmodule

