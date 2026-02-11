`timescale 1ns/1ps
`default_nettype none

module vector_reduce_tb;

  localparam DATA_WIDTH = 8;
  logic clk;
  logic rst_n;

  logic i_b_valid;
  logic [DATA_WIDTH-1:0] i_b;

  logic o_a_rden;
  logic [DATA_WIDTH-1:0] i_a;

  logic o_b_valid;
  logic [DATA_WIDTH-1:0] o_b;

  logic [DATA_WIDTH*3-1:0] o_c;
  
  vector_reduce #(.DATA_WIDTH(DATA_WIDTH)) dut (
    .i_clk(clk),
    .i_rst_n(rst_n),
    .i_clr('0),
    .i_b_valid(i_b_valid),
    .i_b(i_b),
    .o_a_rden(o_a_rden),
    .i_a(i_a),
    .o_b_valid(o_b_valid),
    .o_b(o_b),
    .o_c(o_c)
  );


  always #5 clk = ~clk;

  initial begin
    clk = 0;
    rst_n = 0;
    i_b_valid = 0;
    i_a = 0;
    i_b = 0;

    $display("Begin Test");

    #20 rst_n = 1;

    send(1,1);   
    send(2,2);   
    send(3,3); 
	send(4,4);   
    send(5,5);   
    send(6,6); 	
	send(7,7);   
    send(8,8);   
    send(9,9); 

    #40;

    $display("Final aoutput = %0d ", o_c);
    $finish;
  end


  task send(input [7:0] a, input [7:0] b);
    begin
      @(negedge clk);
      i_a <= a;
      i_b <= b;
      i_b_valid <= 1;

      @(negedge clk);
      i_b_valid <= 0;

      $display("A=%0d B=%0d, forwarded B=%0d,  C=%0d", a, b, o_b, o_c);
    end
  endtask

endmodule

`default_nettype wire
