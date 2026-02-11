module FIFO
#(
  parameter DEPTH=8,
  parameter DATA_WIDTH=8
)
(
  input  logic clk,
  input  logic rst_n,
  input  logic rden,
  input  logic wren,
  input  logic [DATA_WIDTH-1:0] i_data,
  output logic [DATA_WIDTH-1:0] o_data,
  output logic full,
  output logic empty
);

logic [DEPTH-1:0] fifo [DATA_WIDTH-1:0];
logic [$clog2(DEPTH):0] read_ptr, write_ptr;

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		o_data <= '0;
		
		read_ptr <= '0;
		write_ptr <= '0;
	end
	else begin
		if (rden && !empty) begin
			o_data <= fifo[read_ptr[$clog2(DEPTH)-1:0]];
			read_ptr <= read_ptr + 1;
		end
		if (wren && !full) begin
			fifo[write_ptr[$clog2(DEPTH)-1:0]] <= i_data;
			write_ptr <= write_ptr + 1;
		end
	end
end

assign empty = read_ptr == write_ptr;
assign full = read_ptr != write_ptr && read_ptr[$clog2(DEPTH)-1:0] == write_ptr[$clog2(DEPTH)-1:0];

endmodule