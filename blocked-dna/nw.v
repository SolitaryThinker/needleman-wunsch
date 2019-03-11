// Grid Elements:
module Cell#(
  // Number of characters per string
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
  input wire [CWIDTH-1:0] c1,
  input wire [CWIDTH-1:0] c2,
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
  if (c1 == c2)
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
  // Input scores
  //
  // pass in an extra score to account for the corner score needed by the top
  // left cell
  //
  // Use top_scores[0] to top_scores[LENGTH-1] as the corner input scores
  // Use top_scores[1] to top_scores[LENGTH] as the above input scores
  input wire signed[(LENGTH+1)*SWIDTH-1:0] top_scores,
  input wire signed[LENGTH*SWIDTH-1:0] left_scores,
  // Input strings
  input wire signed[LENGTH*CWIDTH-1:0] s1,
  input wire signed[LENGTH*CWIDTH-1:0] s2,
  //FIXME actually use this
  input wire valid,
  // Ouput score
  output wire signed[LENGTH*SWIDTH-1:0] bottom_scores,
  output wire signed[LENGTH*SWIDTH-1:0] right_scores,
  output wire done
);

reg signed[SWIDTH-1:0] interconnect[LENGTH-1:0][LENGTH-1:0];

// generate some cell modules for the grid
generate
  genvar j, k;
  for (j=0; j < LENGTH; j = j + 1) begin: outer_cells
    for (k = 0; k < LENGTH; k = k + 1) begin: inner_cells

      if (j == 0 && k == 0) begin:s
        Cell#(
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .c1(s1[j*CWIDTH +:CWIDTH]),
          .c2(s2[k*CWIDTH +:CWIDTH]),
          .above(top_scores[(k+1)*SWIDTH +:SWIDTH]),
          .left(left_scores[j*SWIDTH +:SWIDTH]),
          .corner(top_scores[k*SWIDTH +:SWIDTH]),
          .score(interconnect[j][k])
        );
      end else if (j == 0) begin:s
        Cell#(
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .c1(s1[j*CWIDTH +:CWIDTH]),
          .c2(s2[k*CWIDTH +:CWIDTH]),
          .above(top_scores[(k+1)*SWIDTH +:SWIDTH]),
          .left(interconnect[j][k-1]),
          .corner(top_scores[k*SWIDTH +:SWIDTH]),
          .score(interconnect[j][k])
        );
      end else if (k == 0) begin:s
        Cell#(
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .c1(s1[j*CWIDTH +:CWIDTH]),
          .c2(s2[k*CWIDTH +:CWIDTH]),
          .above(interconnect[j-1][k]),
          .left(left_scores[j*SWIDTH +:SWIDTH]),
          .corner(left_scores[(j-1)*SWIDTH +:SWIDTH]),
          .score(interconnect[j][k])
        );
      end else begin:s
        Cell#(
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .c1(s1[j*CWIDTH +:CWIDTH]),
          .c2(s2[k*CWIDTH +:CWIDTH]),
          .above(interconnect[j-1][k]),
          .left(interconnect[j][k-1]),
          .corner(interconnect[j-1][k-1]),
          .score(interconnect[j][k])
        );
      end

    end
  end
endgenerate


/*
*          Grid Chunk
*          xxxxx >
*          xxxxx > right_scores
*          xxxxx >
*          xxxxx >
*          vvvvv
*          bottom_scores
*
*    The bottom right corner cell's score is saved in both buffers but that's
*    ok
*/
generate
  genvar i;
  for (i=0; i < LENGTH; i=i+1) begin
    assign bottom_scores[i*SWIDTH +:SWIDTH] = interconnect[LENGTH - 1][i];
    assign right_scores[i*SWIDTH +:SWIDTH] = interconnect[i][LENGTH-1];
  end
endgenerate

//always @(posedge clk) begin
//might have to set a done bit to let outside know the the bottom right corner
//cell has changed?
//end

// ...
endmodule

module Sequencer#(
  // Number of characters per string
  parameter INT_WIDTH = 32,
  parameter MAX_LENGTH = 10,
  parameter CHUNK_LENGTH = 10,
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
  input wire [INT_WIDTH-1:0] dna_length,
  input wire [CWIDTH-1:0] s1,
  input wire [CWIDTH-1:0] s2,
  output reg signed[SWIDTH-1:0] score // out
);

// This buffer is used to store intermediate cell scores as the algorithm
// calculates chunks row by row or column by column
//
// (probably not true anymore)
// Eventaully this buffer
// could probably be piggybacked onto the interconnect.
reg [SWIDTH-1:0] buffer[CHUNK_LENGTH - 1:0];

Grid#(
  .LENGTH(CHUNK_LENGTH),
  .CWIDTH(CWIDTH),
  .SWIDTH(SWIDTH),
  .MATCH(MATCH),
  .INDEL(INDEL),
  .MISMATCH(MISMATCH)
) g(
  .clk(clk),
  .s1(s1),
  .s2(s2),
  .bottom_scores(score),
  .right_scores(score)
);

wire [INT_WIDTH-1:0]row_count = dna_length % MAX_LENGTH;
reg [INT_WIDTH-1:0]row_index = 0;
always @(posedge clk) begin
  $display("row_index %d", row_index);
end
endmodule
