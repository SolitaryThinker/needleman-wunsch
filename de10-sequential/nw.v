// Grid Elements:
module Cell#(
  // Number of bits per character
  parameter CWIDTH = 2,
  // Number of bits per score
  parameter SWIDTH = 16,
  parameter X_CORD = -1,
  parameter Y_CORD = -1,
  parameter[1:0] TOP_DIR = 2'b00,
  parameter[1:0] LEFT_DIR = 2'b01,
  parameter[1:0] CORNER_DIR = 2'b10,
  // Weights
  parameter signed MATCH = 1,
  parameter signed INDEL = -1,
  parameter signed MISMATCH = -1
)(
  input wire clk,
  input wire reset,
  input wire [CWIDTH-1:0] c1,
  input wire [CWIDTH-1:0] c2,
  input wire v_above,
  input wire v_left,
  input wire v_corner,
  input wire signed[SWIDTH-1:0] above,
  input wire signed[SWIDTH-1:0] left,
  input wire signed[SWIDTH-1:0] corner, // score from top left corner
  //input wire back,
  output reg signed[SWIDTH-1:0] score, // out
  output reg [1:0] direction,
  output reg valid // out
);

//internal wires
wire signed[SWIDTH-1:0] above_score = above + INDEL;
wire signed[SWIDTH-1:0] left_score = left + INDEL;
reg signed[SWIDTH-1:0] corner_score;
always @(*) begin
    if (c1 == c2) begin
      corner_score = corner + MATCH;
    end else begin
      corner_score = corner + MISMATCH;
    end
end

always @(posedge clk) begin
//always @(*) begin
  if (reset == 0) begin
    //if (back == 0 && v_above == 1 && v_left == 1 && v_corner == 1) begin
    if (v_above == 1 && v_left == 1 && v_corner == 1) begin
      if (above_score > left_score && above_score > corner_score) begin
        score = above_score;
        direction = TOP_DIR;
      end else if (left_score > above_score && left_score > corner_score) begin
        score = left_score;
        direction = LEFT_DIR;
      end else begin
        score = corner_score;
        direction = CORNER_DIR;
      end
      valid = 1;
    end
  end else begin
    valid = 0;
    score = 0;
    direction = 2'b00;
  end
end
endmodule

module Grid#(
  // Number of characters per string
  parameter LENGTH = 10,
  // Number of bits per character
  parameter CWIDTH = 2,
  // Number of bits per score
  parameter SWIDTH = 16,
  // Number of bits per coordinate
  parameter CORD_LENGTH = 8,
  parameter MEM_SIZE = 9,
  parameter BYTE_SIZE = 2*CORD_LENGTH,
  parameter[1:0] TOP_DIR = 2'b00,
  parameter[1:0] LEFT_DIR = 2'b01,
  parameter[1:0] CORNER_DIR = 2'b10,

  // Weights
  parameter signed MATCH = 1,
  parameter signed INDEL = -1,
  parameter signed MISMATCH = -1
)(
  // Clock
  input wire clk,
  input wire reset,
  // Input strings
  input wire signed[LENGTH*CWIDTH-1:0] s1,
  input wire signed[LENGTH*CWIDTH-1:0] s2,
  // Match score
  output reg signed[SWIDTH-1:0] score,
  output reg valid
);

wire [SWIDTH-1:0] interconnect[LENGTH-1:0][LENGTH-1:0];
wire [1:0] directions[LENGTH-1:0][LENGTH-1:0];
wire valid_matrix[LENGTH-1:0][LENGTH-1:0];
//reg back = 0;

// generate some cell modules for the grid
generate
  genvar j, k;
  for (j=0; j < LENGTH; j = j + 1) begin: outer_cells
    for (k = 0; k < LENGTH; k = k + 1) begin: inner_cells

      if (j == 0 && k == 0) begin:s
        // top left corner
        Cell#(
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .X_CORD(k),
          .Y_CORD(j),
          .TOP_DIR(TOP_DIR),
          .LEFT_DIR(LEFT_DIR),
          .CORNER_DIR(CORNER_DIR),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .reset(reset),
          .c1(s1[((LENGTH-1)-j)*CWIDTH +:CWIDTH]),
          .c2(s2[((LENGTH-1)-k)*CWIDTH +:CWIDTH]),
          .v_above(1),
          .v_left(1),
          .v_corner(1),
          .above((k+1) * INDEL),
          .left((j+1) * INDEL),
          .corner(0),
          //.back(back),
          .score(interconnect[j][k]),
          .direction(directions[j][k]),
          .valid(valid_matrix[j][k])
        );
      end
      else if (j == 0) begin:s
        // top row
        Cell#(
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .X_CORD(k),
          .Y_CORD(j),
          .TOP_DIR(TOP_DIR),
          .LEFT_DIR(LEFT_DIR),
          .CORNER_DIR(CORNER_DIR),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .reset(reset),
          .c1(s1[((LENGTH-1)-j)*CWIDTH +:CWIDTH]),
          .c2(s2[((LENGTH-1)-k)*CWIDTH +:CWIDTH]),
          .v_above(1),
          .v_left(valid_matrix[j][k-1]),
          .v_corner(1),
          .above((k+1) * INDEL),
          .left(interconnect[j][k-1]),
          .corner((k) * INDEL),
          //.back(back),
          .score(interconnect[j][k]),
          .direction(directions[j][k]),
          .valid(valid_matrix[j][k])
        );
      end
      else if (k == 0) begin:s
        // left column
        Cell#(
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .X_CORD(k),
          .Y_CORD(j),
          .TOP_DIR(TOP_DIR),
          .LEFT_DIR(LEFT_DIR),
          .CORNER_DIR(CORNER_DIR),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .reset(reset),
          .c1(s1[((LENGTH-1)-j)*CWIDTH +:CWIDTH]),
          .c2(s2[((LENGTH-1)-k)*CWIDTH +:CWIDTH]),
          .v_above(valid_matrix[j-1][k]),
          .v_left(1),
          .v_corner(1),
          .above(interconnect[j-1][k]),
          .left((j+1) * INDEL),
          .corner((j) * INDEL),
          //.back(back),
          .score(interconnect[j][k]),
          .direction(directions[j][k]),
          .valid(valid_matrix[j][k])
        );
      end
      else begin:s
        // other cells
        Cell#(
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .X_CORD(k),
          .Y_CORD(j),
          .TOP_DIR(TOP_DIR),
          .LEFT_DIR(LEFT_DIR),
          .CORNER_DIR(CORNER_DIR),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .reset(reset),
          .c1(s1[((LENGTH-1)-j)*CWIDTH +:CWIDTH]),
          .c2(s2[((LENGTH-1)-k)*CWIDTH +:CWIDTH]),
          .v_above(valid_matrix[j-1][k]),
          .v_left(valid_matrix[j][k-1]),
          .v_corner(valid_matrix[j-1][k-1]),
          .above(interconnect[j-1][k]),
          .left(interconnect[j][k-1]),
          .corner(interconnect[j-1][k-1]),
          //.back(back),
          .score(interconnect[j][k]),
          .direction(directions[j][k]),
          .valid(valid_matrix[j][k])
        );
      end
    end
  end
endgenerate

reg [CORD_LENGTH-1:0] x = LENGTH-1;
reg [CORD_LENGTH-1:0] y = LENGTH-1;

integer o = $fopen("output.out");

always @(posedge clk) begin
  if (reset == 0) begin
    //if (back == 1) begin
  if (valid_matrix[LENGTH-1][LENGTH-1] == 1) begin
      //$display("=====================: %d", count);
      //$display("Writing [x:%d, y:%d]", x, y);
      $fwrite(o, "%d %d\n", x, y);
      if (x == 0 && y == 0) begin
        //$display("||||||||||||||||||||||||||");
        valid <= 1;
        //back <= 0;
      end else if (x == 0 || directions[y][x] == TOP_DIR) begin
        y <= y - 1;
      end else if (y == 0 || directions[y][x] == LEFT_DIR) begin
        x <= x - 1;
      end else if (directions[y][x] == CORNER_DIR) begin
        x <= x - 1;
        y <= y - 1;
      end
    end
  end else begin // if reset == 1
    if (valid_matrix[LENGTH-1][LENGTH-1] == 0) begin
      //$display("RESETTING>>>>>>>>>>>>>>>>>>>>>");
      x <= LENGTH-1;
      y <= LENGTH-1;
      valid <= 0;
      //back <= 0;
    end
  end
end
endmodule
