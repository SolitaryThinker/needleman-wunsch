// Grid Elements:
module Cell#(
  // you may have similar parameters as the top level module here...
  // Number of bits per character
  parameter CWIDTH = 2,
  // Number of bits per score
  parameter SWIDTH = 16,
  parameter X_CORD = -1,
  parameter Y_CORD = -1,
  // Weights
  parameter signed MATCH = 1,
  parameter signed INDEL = -1,
  parameter signed MISMATCH = -1
)(
  input wire clk,
  input wire reset,
  input wire [CWIDTH-1:0] c1,
  input wire [CWIDTH-1:0] c2,
  input reg v_above,
  input reg v_left,
  input reg v_corner,
  output reg b_above,
  output reg b_left,
  output reg b_corner,
  input wire signed[SWIDTH-1:0] above,
  input wire signed[SWIDTH-1:0] left,
  input wire signed[SWIDTH-1:0] corner, // score from top left corner
  input reg back,
  output reg signed[SWIDTH-1:0] score, // out
  output reg valid, // out
  input wire align
);

//internal wires
reg signed[SWIDTH-1:0] above_score;
reg signed[SWIDTH-1:0] left_score;
reg signed[SWIDTH-1:0] corner_score;
reg [3:0] count = 0;
reg [1:0] direction = 2'b10;

always @(posedge clk)
begin:cell
  //$display("above%d", above);
  //$display("left%d", left);
  //$display("corner%d", corner);

  if (back == 0 && v_above == 1 && v_left == 1 && v_corner == 1) begin
      //v_left = 0;
    above_score <= above + INDEL;
    left_score <= left + INDEL;
    if (c1 == c2)
      corner_score <= corner + MATCH;
    else
      corner_score <= corner + MISMATCH;

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
    //$display("above_score %d", above_score);
    //$display("left_score %d", left_score);
    //$display("corner_score %d", corner_score);
    $display("CORD=== %d %d", X_CORD, Y_CORD);
    $display("back %b ", back);
    //count = count + 1;
    valid = 1;
  end

  // propagating back to find alignment. 0 is now valid while 1 is now invalid
  if (back == 1) begin
      if (align == 1) begin
          $display("CORD=== %d %d", X_CORD, Y_CORD);
          $display("back %b ", back);
          if (direction == TOP_DIR) begin
              b_above = 1;
              $display("top");
          end
          if (direction == LEFT_DIR) begin
              b_left = 1;
              $display("left");
          end
          if (direction == CORNER_DIR) begin
              b_corner = 1;
              $display("corner");
          end
      end
  end

end
always @(reset) begin
  valid = 0;
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
  input wire reset,
  // Input strings
  input wire signed[LENGTH*CWIDTH-1:0] s1,
  input wire signed[LENGTH*CWIDTH-1:0] s2,
  // Match score
  output wire signed[SWIDTH-1:0] score,
  output reg valid
);


Fifo#(LENGTH * 2, 8) alignment (
  .clock(clock.val),
  .rreq(!empty),
  .rdata(rdata),
  .empty(empty)
);

reg [SWIDTH-1:0] interconnect[LENGTH-1:0][LENGTH-1:0];
reg valid_matrix[LENGTH-1:0][LENGTH-1:0];
reg align_matrix[LENGTH-1:0][LENGTH-1:0];
wire tmp = 1;
wire tmp2 = 0;
reg back = 0;

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
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .reset(reset),
          .c1(s1[j*CWIDTH +:CWIDTH]),
          .c2(s2[k*CWIDTH +:CWIDTH]),
          .v_above(tmp),
          .v_left(tmp),
          .v_corner(tmp),
          .b_above(tmp2),
          .b_left(tmp2),
          .b_corner(tmp2),
          .above((k+1) * INDEL),
          .left((j+1) * INDEL),
          .corner(0),
          .back(back),
          .score(interconnect[j][k]),
          .valid(valid_matrix[j][k]),
          .align(align_matrix[j][k])
        );
      end
      else if (j == 0) begin:s
        // top row
        Cell#(
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .X_CORD(k),
          .Y_CORD(j),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .reset(reset),
          .c1(s1[j*CWIDTH +:CWIDTH]),
          .c2(s2[k*CWIDTH +:CWIDTH]),
          .v_above(tmp),
          .v_left(valid_matrix[j][k-1]),
          .v_corner(tmp),
          .b_above(tmp2),
          .b_left(align_matrix[j][k-1]),
          .b_corner(tmp2),
          .above((k+1) * INDEL),
          .left(interconnect[j][k-1]),
          .corner((k) * INDEL),
          .back(back),
          .score(interconnect[j][k]),
          .valid(valid_matrix[j][k]),
          .align(align_matrix[j][k])
        );
      end
      else if (k == 0) begin:s
        // left column
        Cell#(
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .X_CORD(k),
          .Y_CORD(j),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .reset(reset),
          .c1(s1[j*CWIDTH +:CWIDTH]),
          .c2(s2[k*CWIDTH +:CWIDTH]),
          .v_above(valid_matrix[j-1][k]),
          .v_left(tmp),
          .v_corner(tmp),
          .b_above(align_matrix[j-1][k]),
          .b_left(tmp2),
          .b_corner(tmp2),
          .above(interconnect[j-1][k]),
          .left((j+1) * INDEL),
          .corner((j) * INDEL),
          .back(back),
          .score(interconnect[j][k]),
          .valid(valid_matrix[j][k]),
          .align(align_matrix[j][k])
        );
      end
      else begin:s
        // other cells
        Cell#(
          .CWIDTH(CWIDTH),
          .SWIDTH(SWIDTH),
          .X_CORD(k),
          .Y_CORD(j),
          .MATCH(MATCH),
          .INDEL(INDEL),
          .MISMATCH(MISMATCH)
        ) c (
          .clk(clk),
          .reset(reset),
          .c1(s1[j*CWIDTH +:CWIDTH]),
          .c2(s2[k*CWIDTH +:CWIDTH]),
          .v_above(valid_matrix[j-1][k]),
          .v_left(valid_matrix[j][k-1]),
          .v_corner(valid_matrix[j-1][k-1]),
          .b_above(align_matrix[j-1][k]),
          .b_left(align_matrix[j][k-1]),
          .b_corner(align_matrix[j-1][k-1]),
          .above(interconnect[j-1][k]),
          .left(interconnect[j][k-1]),
          .corner(interconnect[j-1][k-1]),
          .back(back),
          .score(interconnect[j][k]),
          .valid(valid_matrix[j][k]),
          .align(align_matrix[j][k])
        );
      end
    end
  end
endgenerate


assign score = interconnect[LENGTH-1][LENGTH-1];

reg [3:0] count = 0;
reg once = 0;
always @(posedge clk) begin
  $display("REE");
  $display("reset %b", reset);
  $display("valid %b", valid_matrix[0][0]);
  count = count + 1;
  $display("count in grid: %d", count);
  if (once == 0 && valid_matrix[LENGTH-1][LENGTH-1] == 1) begin
      once <= 1;
  end
  if (once == 1 && valid_matrix[LENGTH-1][LENGTH-1] == 1) begin
  //if (valid_matrix[LENGTH-1][LENGTH-1] == 1) begin
    $display("REEEEEEEEEEEEEEEEEEEEEEEEEEE: %d", count);
    //valid = 1;
    back = 1;
    //valid_matrix[LENGTH-1][LENGTH-1] = 0;
    align_matrix[LENGTH-1][LENGTH-1]=1;
  end
  if (align_matrix[0][0] == 1) begin
      valid = 1;
  end
end

always @(reset) begin
  valid = 0;
end

// reset both valid_matrix and align_matrix
generate
    for(j = 0; j < LENGTH; j=j+1) begin: r
        for(k = 0; k < LENGTH; k=k+1)begin: r_in
            always @(reset) begin
                valid_matrix[j][k] = 0;
                align_matrix[j][k] = 0;
            end
        end
    end
endgenerate


// ...
// you may find genvar and generate statements to be VERY useful here.
endmodule
