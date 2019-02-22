// Grid Elements:
module Cell#(
// you may have similar parameters as the top level module here...
// Number of characters per string
parameter LENGTH = 10,
// Number of bits per character
parameter CWIDTH = 2,
// Number of bits per score
parameter SWIDTH = 16,
// Weights
parameter signed MATCH = 1,
parameter signed INDEL = -1,
parameter signed MISMATCH = -1
)(
input wire clk,
input wire signed[SWIDTH-1:0] above,
input wire signed[SWIDTH-1:0] left,
input wire signed[SWIDTH-1:0] corner, // score from top left corner
output reg signed[SWIDTH-1:0] score // out
);

//internal wires
reg signed[SWIDTH-1:0] above_score;
reg signed[SWIDTH-1:0] left_score;
reg signed[SWIDTH-1:0] corner_score;

//always @(above or left or corner)
always @(posedge clk)
begin:cell
    $display("above%d", above);
    $display("left%d", left);
    $display("corner%d", corner);
    above_score <= above + INDEL;
    left_score <= left + INDEL;
    corner_score <= corner + MISMATCH;
    $display("above_score %d", above_score);
    $display("left_score %d", left_score);
    $display("corner_score %d", corner_score);

    if (above_score > left_score && above_score > corner_score) begin
        score = above_score;
    end else if (left_score > above_score && left_score > corner_score) begin
        score = left_score;
    end else begin //if (corner_score >= left_score && corner_score >= above_score) begin
        score = corner_score;
    end
end
endmodule

// Grid:
module Grid#(
  // Number of characters per string
  parameter LENGTH = 10,
  // Number of bits per character
  parameter CWIDTH = 2,
  // Number of bits per score
  parameter SWIDTH = 16,
  // Weights
  parameter signed MATCH = 1,
  parameter signed INDEL = -1,
  parameter signed MISMATCH = -1
)(
  // Clock
  input wire clk,
  // Input strings
  input wire signed[LENGTH*CWIDTH-1:0] s1,
  input wire signed[LENGTH*CWIDTH-1:0] s2,
  input wire valid,
  // Match score
  output wire signed[SWIDTH-1:0] score,
  output wire done
);


Cell#(
    .LENGTH(LENGTH),
    .CWIDTH(CWIDTH),
    .SWIDTH(SWIDTH),
    .MATCH(MATCH),
    .INDEL(INDEL),
    .MISMATCH(MISMATCH)
) c (
    .clk(clk),
    .above(2),
    .left(-1),
    .corner(0),
    .score(score)
);

always @(posedge clk) begin
    $display("test");

end
//assign done = 1;

// ...
// you may find genvar and generate statements to be VERY useful here.
endmodule
