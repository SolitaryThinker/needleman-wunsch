`include "constants.v"
`include "nw.v"

// Instantiate input fifo; we'll read input pairs one line at a time:
localparam DATA_WIDTH = 2*LENGTH*CWIDTH;
reg [DATA_WIDTH-1:0] rdata;

integer i = $fopen("in.fifo", "r");

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
reg once = 0;
always @(posedge clock.val) begin
  // Edge case: Stop running when the eof reached
  if ($feof(i)) begin
    //$fseek(i, 0, 0);
    $finish;
  end
  // Base case: Skip first input when fifo hasn't yet reported values
  if (!once) begin
    once <= 1;
    $fread(i, rdata);
  end
  else begin
    // Common case: Read next input if previous input is done
    if (done == 1) begin
      //$display("==================DONE");
      reset_b <= 1;
    end else begin
      if (reset_b == 1) begin
        reset_b <= 0;
        //$display("READING=====================");
        $fread(i, rdata);
      end
    end
  end
end
