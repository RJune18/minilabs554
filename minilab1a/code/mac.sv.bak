`default_nettype none
module MAC #
(
parameter DATA_WIDTH = 8
)
(
input logic clk,
input logic rst_n,
input logic En,
input logic Clr,
input logic [DATA_WIDTH-1:0] Ain,
input logic [DATA_WIDTH-1:0] Bin,
output logic [DATA_WIDTH*3-1:0] Cout
);


always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		Cout <= '0;
	else if (Clr)
		Cout <= '0;
	else if (En)
		Cout <= Cout + Ain * Bin;
	else
		Cout <= Cout;
end


endmodule
