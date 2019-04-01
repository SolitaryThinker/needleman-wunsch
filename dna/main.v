include constants.v;
include nw.v;

// Instantiate input fifo; we'll read input pairs one line at a time:
localparam DATA_WIDTH = 2*LENGTH*CWIDTH;
wire [DATA_WIDTH-1:0] rdata;
wire empty;
(*__target="sw", __file="in.fifo"*)
Fifo#(1, DATA_WIDTH) in (
  .clock(clock.val),
  .rreq(!empty),
  .rdata(rdata),
  .empty(empty)
);

// Instantiate compute grid:
wire [LENGTH*CWIDTH-1:0] s1 = rdata[2*LENGTH*CWIDTH-1:1*LENGTH*CWIDTH];
wire [LENGTH*CWIDTH-1:0] s2 = rdata[1*LENGTH*CWIDTH-1:0*LENGTH*CWIDTH];
wire signed[SWIDTH-1:0] score;
wire done;
reg reset_b = 0;
Grid#(
  .LENGTH(LENGTH),
  .CWIDTH(CWIDTH),
  .SWIDTH(SWIDTH),
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
reg once = 0;
reg [3:0]count = 0;
always @(posedge clock.val) begin
  $display("test");
  // Base case: Skip first input when fifo hasn't yet reported values
  if (!once) begin
    $display("ONCE=====================");
    once <= 1;
  end
  // Edge case: Stop running when the fifo reports empty
  //else if (empty) begin
    //$finish(1);
  //end
  // Common case: Print results as they become available
  else begin
    //$display("decimal input char count  %h", rdata);
    //$display("decimal align(%d,%d) = %d", s1, s2, score);
    //$display("align(%h,%h) = %d", s1, s2, score);
    $display("=======================================================");
    $display("h: %h", s1);
    $display("h: %h", s2);
    $display("%d %d %d %d", g.outer_cells[0].inner_cells[0].s.c.score,
      g.outer_cells[0].inner_cells[1].s.c.score,
      g.outer_cells[0].inner_cells[2].s.c.score,
      g.outer_cells[0].inner_cells[3].s.c.score
    );
    $display("%d %d %d %d", g.outer_cells[1].inner_cells[0].s.c.score,
      g.outer_cells[1].inner_cells[1].s.c.score,
      g.outer_cells[1].inner_cells[2].s.c.score,
      g.outer_cells[1].inner_cells[3].s.c.score
    );
    $display("%d %d %d %d", g.outer_cells[2].inner_cells[0].s.c.score,
      g.outer_cells[2].inner_cells[1].s.c.score,
      g.outer_cells[2].inner_cells[2].s.c.score,
      g.outer_cells[2].inner_cells[3].s.c.score
    );
    $display("%d %d %d %d", g.outer_cells[3].inner_cells[0].s.c.score,
      g.outer_cells[3].inner_cells[1].s.c.score,
      g.outer_cells[3].inner_cells[2].s.c.score,
      g.outer_cells[3].inner_cells[3].s.c.score
    );
    $display("-----------------------");
    $display("%d %d %d %d", g.outer_cells[0].inner_cells[0].s.c.align,
      g.outer_cells[0].inner_cells[1].s.c.align,
      g.outer_cells[0].inner_cells[2].s.c.align,
      g.outer_cells[0].inner_cells[3].s.c.align
    );
    $display("%d %d %d %d", g.outer_cells[1].inner_cells[0].s.c.align,
      g.outer_cells[1].inner_cells[1].s.c.align,
      g.outer_cells[1].inner_cells[2].s.c.align,
      g.outer_cells[1].inner_cells[3].s.c.align
    );
    $display("%d %d %d %d", g.outer_cells[2].inner_cells[0].s.c.align,
      g.outer_cells[2].inner_cells[1].s.c.align,
      g.outer_cells[2].inner_cells[2].s.c.align,
      g.outer_cells[2].inner_cells[3].s.c.align
    );
    $display("%d %d %d %d", g.outer_cells[3].inner_cells[0].s.c.align,
      g.outer_cells[3].inner_cells[1].s.c.align,
      g.outer_cells[3].inner_cells[2].s.c.align,
      g.outer_cells[3].inner_cells[3].s.c.align
    );
    if (done == 1) begin
      $display("==================DONE");
      reset_b = 1;
    end

    if (reset_b == 1) reset_b = 0;

    $display("=====count %d", count);
    count <= (count + 1);
    if ((&count)) begin
        $finish(1);
    end
    $display("h: %h", s1);
    $display("h: %h", s2);
    $display("align(%h,%h) = %d", s1, s2, score);
  end
end
