include constants.v;
include nw.v;

// We're going to use a hard-wired length of 4 here
localparam HLENGTH = 4;

// Instantiate compute grid with hard-wired inputs 
wire [HLENGTH*CWIDTH-1:0] s1 = {A, T, C, G};
wire [HLENGTH*CWIDTH-1:0] s2 = {A, T, C, G};
wire signed[SWIDTH-1:0] score;
wire done;
YOUR_TOP_LEVEL_MODULE#(
  .LENGTH(HLENGTH),
  .CWIDTH(CWIDTH),
  .SWIDTH(SWIDTH),
  .MATCH(MATCH),
  .INDEL(INDEL),
  .MISMATCH(MISMATCH) 
) g (
  .clk(clock.val),
  .s1(s1),
  .s2(s2),
  .valid(1),
  .score(score),
  .done(done)
);

// Time out after 16 cycles
reg [3:0] count = 0;

// Print the result. We should see:
//  1  0 -1 -2
//  0  2  1  0
// -1  1  3  2
// -2  0  2  4
// after you replace the "..." below with signals for the 
// grid elements in your top level module
always @(posedge clock.val) begin
  $display("%d %d %d %d", ...);
  $display("%d %d %d %d", ...);
  $display("%d %d %d %d", ...);
  $display("%d %d %d %d", ...);
  $display("");
  
  count <= (count + 1);
  if (done | (&count)) begin
    $finish(1);
  end
end
