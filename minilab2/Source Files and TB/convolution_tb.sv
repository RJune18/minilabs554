`timescale 1ns/1ps

module tb_convolution;

  // ----------------------------
  // Parameters / DUT I/O
  // ----------------------------
  localparam int DATA_WIDTH = 12;
  localparam int IMG_W      = 8;
  localparam int IMG_H      = 8;

  logic                   i_clk;
  logic                   i_rst_n;
  logic                   i_val_valid;
  logic [DATA_WIDTH-1:0]  i_val;
  logic                   o_val_valid;
  logic [DATA_WIDTH-1+3:0] o_val;   // matches your module: [DATA_WIDTH-1+3:0]

  // ----------------------------
  // Instantiate DUT
  // ----------------------------
  convolution #(.DATA_WIDTH(DATA_WIDTH)) dut (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_val_valid(i_val_valid),
    .i_val(i_val),
    .o_val_valid(o_val_valid),
    .o_val(o_val)
  );

  // ----------------------------
  // Clock
  // ----------------------------
  initial i_clk = 1'b0;
  always  #5 i_clk = ~i_clk; // 100 MHz

  // ----------------------------
  // Golden model bookkeeping
  // We'll build windows from input stream.
  // ----------------------------

  // Store entire image (optional, but nice for debug)
  logic [DATA_WIDTH-1:0] img   [0:IMG_H-1][0:IMG_W-1];

  // Rolling line buffers for reference (3 rows)
  logic [DATA_WIDTH-1:0] row0 [0:IMG_W-1];
  logic [DATA_WIDTH-1:0] row1 [0:IMG_W-1];
  logic [DATA_WIDTH-1:0] row2 [0:IMG_W-1];

  int r, c;

  // Kernel (signed)
  localparam int K00=-4, K01=0, K02=4;
  localparam int K10=-8, K11=0, K12=8;
  localparam int K20=-4, K21=0, K22=4;

  // Expected output queue (store raw bits as DUT outputs them)
  logic signed [DATA_WIDTH+3:0] exp_q[$]; // DATA_WIDTH+4 bits wide signed (since o_val is DATA_WIDTH+4 bits)
  int exp_count = 0;
  int got_count = 0;

  // Helper: compute signed convolution for window ending at (r,c) i.e. uses (r-2..r, c-2..c)
  function automatic logic signed [DATA_WIDTH+3:0] conv3x3_at(input int rr, input int cc);
    int signed acc;
    int signed p00, p01, p02, p10, p11, p12, p20, p21, p22;
    begin
      // pull pixels as ints
      p00 = row0[cc-2]; p01 = row0[cc-1]; p02 = row0[cc];
      p10 = row1[cc-2]; p11 = row1[cc-1]; p12 = row1[cc];
      p20 = row2[cc-2]; p21 = row2[cc-1]; p22 = row2[cc];

      acc = 0;
      acc += K00*p00 + K01*p01 + K02*p02;
      acc += K10*p10 + K11*p11 + K12*p12;
      acc += K20*p20 + K21*p21 + K22*p22;

      // Cast/pack to the DUT's output width (two's complement)
      conv3x3_at = logic'(acc[DATA_WIDTH+3:0]);
    end
  endfunction

  // ----------------------------
  // Drive one pixel
  // ----------------------------
  task automatic drive_pixel(input logic [DATA_WIDTH-1:0] px, input bit bubble = 0);
    begin
      // Optional bubble cycle where valid=0
      if (bubble) begin
        @(posedge i_clk);
        i_val_valid <= 1'b0;
        i_val       <= '0;
      end

      @(posedge i_clk);
      i_val_valid <= 1'b1;
      i_val       <= px;
    end
  endtask

  // ----------------------------
  // Reference model update on each accepted input
  // ----------------------------
  task automatic ref_accept_pixel(input logic [DATA_WIDTH-1:0] px, input int rr, input int cc);
    logic signed [DATA_WIDTH+3:0] exp;
    begin
      // Shift rows as we progress down the image:
      // We maintain row0=row(rr-2), row1=row(rr-1), row2=row(rr)
      // When starting a new row rr, if cc==0, rotate rows.
      if (cc == 0) begin
        // move row1->row0, row2->row1, clear row2 for new row
        for (int x=0; x<IMG_W; x++) begin
          row0[x] = row1[x];
          row1[x] = row2[x];
          row2[x] = '0;
        end
      end

      // Write current pixel into current row2 at column cc
      row2[cc] = px;

      // If we have a full 3x3 window (rr>=2 and cc>=2), compute expected output
      if (rr >= 2 && cc >= 2) begin
        exp = conv3x3_at(rr, cc);
        exp_q.push_back(exp);
        exp_count++;
      end
    end
  endtask

  // ----------------------------
  // Scoreboard: compare whenever DUT says output valid
  // ----------------------------
  always_ff @(posedge i_clk) begin
    if (!i_rst_n) begin
      // clear on reset
      exp_q.delete();
      exp_count <= 0;
      got_count <= 0;
    end else begin
      if (o_val_valid) begin
        got_count++;
        if (exp_q.size() == 0) begin
          $error("DUT produced o_val_valid but expected queue is empty at time %0t! o_val=0x%0h",
                 $time, o_val);
          $stop;
        end else begin
          logic signed [DATA_WIDTH+3:0] exp;
          exp = exp_q.pop_front();

          // Compare bit-exact (two's complement)
          if (o_val !== exp[DATA_WIDTH+3:0]) begin
            $error("MISMATCH #%0d at time %0t: DUT o_val=0x%0h (%0d) exp=0x%0h (%0d)",
                   got_count, $time,
                   o_val, $signed(o_val),
                   exp[DATA_WIDTH+3:0], exp);
            $stop;
          end
        end
      end
    end
  end

  // ----------------------------
  // Test sequence
  // ----------------------------
  initial begin
    // init
    i_rst_n     = 1'b0;
    i_val_valid = 1'b0;
    i_val       = '0;

    // init rows
    for (int x=0; x<IMG_W; x++) begin
      row0[x] = '0;
      row1[x] = '0;
      row2[x] = '0;
    end

    // reset
    repeat (5) @(posedge i_clk);
    i_rst_n <= 1'b1;
    @(posedge i_clk);

    // Build a simple deterministic test image (gradient + step)
    for (r = 0; r < IMG_H; r++) begin
      for (c = 0; c < IMG_W; c++) begin
        img[r][c] = logic'(((r*IMG_W + c) * 17) & ((1<<DATA_WIDTH)-1));
        if (c >= IMG_W/2) img[r][c] ^= 12'h3A5; // add some edges
      end
    end

    // Drive image in raster order
    for (r = 0; r < IMG_H; r++) begin
      for (c = 0; c < IMG_W; c++) begin
        // Optional: insert bubbles sometimes to test valid gating
        bit bubble = ((r==2 && c==3) || (r==5 && c==0));
        drive_pixel(img[r][c], bubble);

        // Update reference model only on cycles we asserted valid (i.e., accepted input)
        // NOTE: If you ever add ready/handshake later, you’d gate this on ready too.
        ref_accept_pixel(img[r][c], r, c);
      end
    end

    // Deassert valid after last pixel
    @(posedge i_clk);
    i_val_valid <= 1'b0;
    i_val       <= '0;

    // Let pipeline flush
    repeat (200) @(posedge i_clk);

    // Check we got everything we expected (rough sanity)
    if (got_count != exp_count) begin
      $error("COUNT MISMATCH: got_count=%0d exp_count=%0d (DUT valid timing differs from reference assumptions)",
             got_count, exp_count);
      $stop;
    end

    $display("PASS: matched %0d convolution outputs.", got_count);
    $finish;
  end

endmodule
