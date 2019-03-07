// Grid Elements:
module Cell#(
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

reg [SWIDTH-1:0] interconnect[LENGTH-1:0][LENGTH-1:0];


//(*__file="file.mem"*)
//Memory#(LENGTH*LENGTH,SWIDTH) mem(
  //.clock(clk),  // Write data is latched on the posedge of this signal
  //.wen(1),// Assert to latch write data
  //,raddr1(),// Address to read data from

   //rdata1, // The value at raddr1, available this clock cycle
   //raddr2, // Ditto
   //rdata2, // Ditto
   //waddr,  // Address to write data to
   //wdata   // The value to write to waddr at the posedge of clock

//);


// generate some cell modules for the grid
generate
  genvar j, k;
  for (j=0; j < LENGTH; j = j + 1) begin: outer_cells
    for (k = 0; k < LENGTH; k = k + 1) begin: inner_cells

      if (j == 0 && k == 0) begin:s
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
          .a(s1[j*SWIDTH +:SWIDTH]),
          .b(s2[k*SWIDTH +:SWIDTH]),
          .above((k+1) * INDEL),
          .left((j+1) * INDEL),
          .corner(0),
          .score(interconnect[j][k])
        );
      end
      else if (j == 0) begin:s
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
          .a(s1[j*SWIDTH +:SWIDTH]),
          .b(s2[k*SWIDTH +:SWIDTH]),
          .above(k * INDEL),
          .left(interconnect[j][k-1]),
          .corner((k-1) * INDEL),
          .score(interconnect[j][k])
        );
      end
      else if (k == 0) begin:s
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
          .a(s1[j*SWIDTH +:SWIDTH]),
          .b(s2[k*SWIDTH +:SWIDTH]),
          .above(interconnect[j-1][k]),
          .left(j * INDEL),
          .corner((j-1) * INDEL),
          .score(interconnect[j][k])
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
          .a(s1[j*SWIDTH +:SWIDTH]),
          .b(s2[k*SWIDTH +:SWIDTH]),
          .above(interconnect[j-1][k]),
          .left(interconnect[j][k-1]),
          .corner(interconnect[j-1][k-1]),
          .score(interconnect[j][k])
        );
      end



    end
  end
endgenerate

assign score = interconnect[LENGTH - 1][LENGTH - 1];

//always @(posedge clk) begin
//end

// ...
// you may find genvar and generate statements to be VERY useful here.
endmodule

module Sequencer#(
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
  output reg signed[SWIDTH-1:0] score // out
)

// This buffer is used to store intermediate cell scores as the algorithm
// propagates from top left to bottom right of the grid.
//
// (probably not true anymore)
// Eventaully this buffer
// could probably be piggybacked onto the interconnect.
reg [SWIDTH-1:0] buffer[LENGTH*2 - 1:0];

Grid#(
  .LENGTH(LENGTH),
  .CWIDTH(CWIDTH),
  .SWIDTH(SWIDTH),
  .MATCH(MATCH),
  .INDEL(INDEL),
  .MISMATCH(MISMATCH)
) g(
  .clk(clock.val),
  .s1(s1),
  .s2(s2),
  .score(score)
);

always @(posedge clock.val) begin

end
endmodule
