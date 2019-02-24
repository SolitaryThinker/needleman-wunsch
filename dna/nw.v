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
  input wire [CWIDTH-1:0] a,
  input wire [CWIDTH-1:0] b,
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
  //$display("above%d", above);
  //$display("left%d", left);
  //$display("corner%d", corner);

  above_score <= above + INDEL;
  left_score <= left + INDEL;
  if (a == b)
    corner_score <= corner + MATCH;
  else
    corner_score <= corner + MISMATCH;

  if (above_score > left_score && above_score > corner_score) begin
    score = above_score;
  end else if (left_score > above_score && left_score > corner_score) begin
    score = left_score;
  end else begin //if (corner_score >= left_score && corner_score >= above_score) begin
    score = corner_score;
  end
  //$display("above_score %d", above_score);
  //$display("left_score %d", left_score);
  //$display("corner_score %d", corner_score);
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

reg [SWIDTH-1:0] interconnects[LENGTH-1:0][LENGTH-1:0];

// generate some cell modules for the grid
generate
  genvar j, k;
  for (j=1; j <= LENGTH; j = j + 1) begin: outer_cells
    for (k = 1; k <= LENGTH; k = k + 1) begin: inner_cells

      if (j == 1 && k == 1) begin:s
        // top left corner
        Cell#(
          .LENGTH(LENGTH),
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .a(s1[(j-1)*SWIDTH +:SWIDTH]),
          .b(s2[(k-1)*SWIDTH +:SWIDTH]),
          .above(k * INDEL),
          .left(j * INDEL),
          .corner(0),
          .score(interconnects[j-1][k-1])
        );
      end
      else if (j == 1) begin:s
        // top row
        Cell#(
          .LENGTH(LENGTH),
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .a(s1[(j-1)*SWIDTH +:SWIDTH]),
          .b(s2[(k-1)*SWIDTH +:SWIDTH]),
          .above(k * INDEL),
          .left(interconnects[j-1][k-2]),
          .corner((k-1) * INDEL),
          .score(interconnects[j-1][k-1])
        );
      end
      else if (k == 1) begin:s
        // left column
        Cell#(
          .LENGTH(LENGTH),
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .a(s1[(j-1)*SWIDTH +:SWIDTH]),
          .b(s2[(k-1)*SWIDTH +:SWIDTH]),
          .above(interconnects[j-2][k-1]),
          .left(j * INDEL),
          .corner((j-2) * INDEL),
          .score(interconnects[j-1][k-1])
        );
      end
      else begin:s
        // other cells
        Cell#(
          .LENGTH(LENGTH),
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .a(s1[(j-1)*SWIDTH +:SWIDTH]),
          .b(s2[(k-1)*SWIDTH +:SWIDTH]),
          .above(interconnects[j-2][k-1]),
          .left(interconnects[j-1][k-2]),
          .corner(interconnects[j-2][k-2]),
          .score(interconnects[j-1][k-1])
        );
      end



    end
  end
endgenerate

//always @(posedge clk) begin
//end

// ...
// you may find genvar and generate statements to be VERY useful here.
endmodule
