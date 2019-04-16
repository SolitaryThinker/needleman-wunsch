include constants.v;
include open_loop_nw.v;

// Instantiate input fifo; we'll read input pairs one line at a time:
localparam DATA_WIDTH = 2*LENGTH*CWIDTH;
reg [4:0]raddr = 0;
reg [DATA_WIDTH-1:0] rdata[32-1:0];
reg rreq = 1;
wire empty;

initial begin
rdata[0]= 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[1] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[2] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[3] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[4] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[5] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[6] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[7] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[8] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[9] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[10] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[11] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[12] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[13] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[14] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[15] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[16] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[17] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[18] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[19] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[20] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[21] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[22] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[23] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[24] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[25] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[26] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[27] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[28] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[29] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[30] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
rdata[31] = 60'b001110100011100001110100001110110011110001100011001101111101001101111101111111100011011111010011;
end

// Instantiate compute grid:
wire [LENGTH*CWIDTH-1:0] s1 = rdata[raddr][2*LENGTH*CWIDTH-1:1*LENGTH*CWIDTH];
wire [LENGTH*CWIDTH-1:0] s2 = rdata[raddr][1*LENGTH*CWIDTH-1:0*LENGTH*CWIDTH];
wire signed[SWIDTH-1:0] score;
wire done;
reg reset_b = 0;
Grid#(
  .LENGTH(LENGTH),
  .CWIDTH(CWIDTH),
  .SWIDTH(SWIDTH),
  .CORD_LENGTH(CORD_LENGTH),
  .MEM_SIZE(MEM_SIZE),
  .MATCH(MATCH),
  .INDEL(INDEL),
  .MISMATCH(MISMATCH)
) g (
  .clk(clock.val),
  .reset(reset_b),
  .s1(s1),
  .s2(s2),
  .score(score),
  .valid(done)
);

// While there are still inputs coming out of the fifo, print the results:
reg once = 1;
reg [5:0]count = 0;
always @(posedge clock.val) begin
  // Base case: Skip first input when fifo hasn't yet reported values
  if (!once) begin
    //$display("ONCE=====================");
    once <= 1;
  end
  // Edge case: Stop running when the fifo reports empty
  else if (empty) begin
    $finish(1);
  end
  // Common case: Print results as they become available
  else begin
    if (rreq == 1) begin
        //$display("clearing rreq=============");
        rreq <= 0;
        //valid = 1;
    end
    //$display("decimal input char count  %h", rdata);

    //$display("decimal align(%d,%d) = %d", s1, s2, score);
    //$display("align(%h,%h) = %d", s1, s2, score);

    //$display("=======================================================");
    //$display("h: %h", s1);
    //$display("h: %h", s2);
    //$display("h: %b", s1);
    //$display("h: %b", s2);
    //$display("%d %d %d %d", g.outer_cells[0].inner_cells[0].s.c.score,
      //g.outer_cells[0].inner_cells[1].s.c.score,
      //g.outer_cells[0].inner_cells[2].s.c.score,
      //g.outer_cells[0].inner_cells[3].s.c.score
    //);
    //$display("%d %d %d %d", g.outer_cells[1].inner_cells[0].s.c.score,
      //g.outer_cells[1].inner_cells[1].s.c.score,
      //g.outer_cells[1].inner_cells[2].s.c.score,
      //g.outer_cells[1].inner_cells[3].s.c.score
    //);
    //$display("%d %d %d %d", g.outer_cells[2].inner_cells[0].s.c.score,
      //g.outer_cells[2].inner_cells[1].s.c.score,
      //g.outer_cells[2].inner_cells[2].s.c.score,
      //g.outer_cells[2].inner_cells[3].s.c.score
    //);
    //$display("%d %d %d %d", g.outer_cells[3].inner_cells[0].s.c.score,
      //g.outer_cells[3].inner_cells[1].s.c.score,
      //g.outer_cells[3].inner_cells[2].s.c.score,
      //g.outer_cells[3].inner_cells[3].s.c.score
    //);
    //$display("-----------------------");
    //$display("%d %d %d %d", g.outer_cells[0].inner_cells[0].s.c.align,
      //g.outer_cells[0].inner_cells[1].s.c.align,
      //g.outer_cells[0].inner_cells[2].s.c.align,
      //g.outer_cells[0].inner_cells[3].s.c.align
    //);
    //$display("%d %d %d %d", g.outer_cells[1].inner_cells[0].s.c.align,
      //g.outer_cells[1].inner_cells[1].s.c.align,
      //g.outer_cells[1].inner_cells[2].s.c.align,
      //g.outer_cells[1].inner_cells[3].s.c.align
    //);
    //$display("%d %d %d %d", g.outer_cells[2].inner_cells[0].s.c.align,
      //g.outer_cells[2].inner_cells[1].s.c.align,
      //g.outer_cells[2].inner_cells[2].s.c.align,
      //g.outer_cells[2].inner_cells[3].s.c.align
    //);
    //$display("%d %d %d %d", g.outer_cells[3].inner_cells[0].s.c.align,
      //g.outer_cells[3].inner_cells[1].s.c.align,
      //g.outer_cells[3].inner_cells[2].s.c.align,
      //g.outer_cells[3].inner_cells[3].s.c.align
    //);

    if (done == 1) begin
      //$display("==================DONE");
      reset_b <= 1;
      raddr <= raddr + 1;
    end

    if (reset_b == 1) begin
        reset_b <= 0;
        rreq <= 1;
    end

    //$display("h: %h", s1);
    //$display("h: %h", s2);
    //$display("=====count %d", count);
    //count <= (count + 1);
    if ((&count)) begin
        $finish(1);
    end
    //$display("align(%h,%h) = %d", s1, s2, score);
  end
end
