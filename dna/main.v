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
YOUR_TOP_LEVEL_MODULE#(
  .LENGTH(LENGTH),
  .CWIDTH(CWIDTH),
  .SWIDTH(SWIDTH),
  .MATCH(MATCH),
  .INDEL(INDEL),
  .MISMATCH(MISMATCH) 
) grid (
  .s1(s1),
  .s2(s2),
  .score(score)
);

// While there are still inputs coming out of the fifo, print the results:
reg once = 0;
always @(posedge clock.val) begin
  // Base case: Skip first input when fifo hasn't yet reported values
  if (!once) begin 
    once <= 1;
  end 
  // Edge case: Stop running when the fifo reports empty
  else if (empty) begin
    $finish(1);
  end 
  // Common case: Print results as they become available
  else begin
    $display("align(%h,%h) = %d", s1, s2, score);
  end
end
