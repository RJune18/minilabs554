`default_nettype none
module MAC #
(
  parameter DATA_WIDTH = 8
)
(
  input  logic clk,
  input  logic rst_n,
  input  logic En,
  input  logic Clr,
  input  logic [DATA_WIDTH-1:0] Ain,
  input  logic [DATA_WIDTH-1:0] Bin,
  output logic [DATA_WIDTH*3-1:0] Cout
);

  wire [2*DATA_WIDTH-1:0] prod;
  wire [DATA_WIDTH*3-1:0] prod_ext;
  wire [DATA_WIDTH*3-1:0] sum;

  assign prod_ext = {{(DATA_WIDTH*3-2*DATA_WIDTH){1'b0}}, prod};

  localparam PIPELINE_DELAY = 1;
  logic [PIPELINE_DELAY-1:0] delay;
  
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      delay <= '0;
    end
    else begin
      // TODO: use if PIPELINE_DELAY > 1, delay <= {delay[PIPELINE_DELAY-2:0], En};
      delay <= En;
    end
  end

  logic valid;
  assign valid = delay[PIPELINE_DELAY-1];

  generate
    if (PIPELINE_DELAY == 0) begin
      mult_ip u_mult (
        .dataa  (Ain),
        .datab  (Bin),
        .result (prod)
      );
    end
    else begin
      mult_ip2 u_mult (
        .clock(clk),
        .dataa(Ain),
        .datab(Bin),
        .result(prod)
      );
    end
  endgenerate

  add_ip u_add (
    .dataa  (Cout),
    .datab  (prod_ext),
    .result (sum)
  );

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      Cout <= '0;
    else if (Clr)
      Cout <= '0;
    else if (valid)
      Cout <= sum;
    else
      Cout <= Cout;
  end

endmodule
