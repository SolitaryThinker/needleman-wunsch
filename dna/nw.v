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
reg [1:0] direction = 2'b00;

always @(posedge clk) begin
  if (back == 0 && v_above == 1 && v_left == 1 && v_corner == 1) begin
    above_score <= above + INDEL;
    left_score <= left + INDEL;
    if (c1 == c2) begin
      corner_score <= corner + MATCH;
    end else begin
      corner_score <= corner + MISMATCH;
    end

    if (above_score > left_score && above_score > corner_score) begin
      score <= above_score;
      direction <= TOP_DIR;
    end else if (left_score > above_score && left_score > corner_score) begin
      score <= left_score;
      direction <= LEFT_DIR;
    end else begin
      score <= corner_score;
      direction <= CORNER_DIR;
    end
    //$display("above_score %d", above_score);
    //$display("left_score %d", left_score);
    //$display("corner_score %d", corner_score);

    //$display("CORD=== %d %d", X_CORD, Y_CORD);
    //$display("back %b ", back);
    //count = count + 1;
    valid <= 1;
  end

  // propagating back to find alignment. 0 is now valid while 1 is now invalid
  if (back == 1) begin
      if (align == 1) begin
          //$display("CORD=== %d %d", X_CORD, Y_CORD);
          if (direction == TOP_DIR) begin
              b_above <= 1;
              //$display("top");
          end
          if (direction == LEFT_DIR) begin
              b_left <= 1;
              //$display("left");
          end
          if (direction == CORNER_DIR) begin
              b_corner <= 1;
              //$display("corner");
          end
      end
  end
end
always @(reset) begin
    //$display("CELL RESET");
    valid <= 0;
    b_above <= 0;
    b_left <= 0;
    b_corner <= 0;
    score <= 0;
    direction <= 2'b00;
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

//reg wreq = 0;
//wire [7:0]wdata;

//Fifo#(LENGTH * 2, 8) alignment (
  //.clock(clock.val),
  //.rreq(!empty),
  //.rdata(rdata),
  //.wreq(wreq),
  //.wdata(wdata),
  //.empty(empty)
//);
//

reg wen = 0;
reg [MEM_SIZE-1:0] waddr = 0;
reg [BYTE_SIZE-1:0] wdata;
(*__file="file.mem"*)
Memory#(MEM_SIZE, BYTE_SIZE) mem (
    .clock(clk),
    .wen(wen),
    .waddr(waddr),
    .wdata(wdata)
);

reg [SWIDTH-1:0] interconnect[LENGTH-1:0][LENGTH-1:0];
reg valid_matrix[LENGTH-1:0][LENGTH-1:0];
reg align_matrix[LENGTH-1:0][LENGTH-1:0];
reg tmp = 1;
reg tmp2 = 0;
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
          .TOP_DIR(TOP_DIR),
          .LEFT_DIR(LEFT_DIR),
          .CORNER_DIR(CORNER_DIR),
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
          .TOP_DIR(TOP_DIR),
          .LEFT_DIR(LEFT_DIR),
          .CORNER_DIR(CORNER_DIR),
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
          .TOP_DIR(TOP_DIR),
          .LEFT_DIR(LEFT_DIR),
          .CORNER_DIR(CORNER_DIR),
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
          .TOP_DIR(TOP_DIR),
          .LEFT_DIR(LEFT_DIR),
          .CORNER_DIR(CORNER_DIR),
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


reg [3:0] count = 0;
reg once = 0;
reg [CORD_LENGTH-1:0] x = LENGTH-1;
reg [CORD_LENGTH-1:0] y = LENGTH-1;
reg [1:0] direction = 2'b00;

generate
    for (j = 0; j < LENGTH; j=j+1) begin: wd
        for (k = 0; k < LENGTH; k=k+1) begin: wd_i
            always @(posedge x, y) begin
                if (x == k && y == j && back == 1) begin
                    direction <= outer_cells[j].inner_cells[k].s.c.direction;
                    //$display("WE MATCH %d %d", j, k);
                    //$display("WE DIRECTION %b", direction);
                end
            end
        end
    end
endgenerate

always @(valid_matrix[LENGTH-1][LENGTH-1]) begin
    if (valid_matrix[LENGTH-1][LENGTH-1] == 1) begin
        back = 1;
        //once <= 1;
    end
end

reg last = 0;
always @(posedge clk) begin
  count <= count + 1;
  $display("count in grid: %d", count);
  //if (once == 0 && valid_matrix[LENGTH-1][LENGTH-1] == 1) begin
      //back <= 1;
      //once <= 1;
  //end
  if (back == 1) begin
          $display("=====================: %d", count);
          //score = interconnect[LENGTH-1][LENGTH-1];
          align_matrix[LENGTH-1][LENGTH-1] <= 1;
          wdata[0+:CORD_LENGTH] <= x;
          wdata[CORD_LENGTH+:CORD_LENGTH] <= y;
          $display("Writing [x:%d, y:%d] hex: %h to mem %d", x, y, wdata, waddr);
          wen <= 1;
          waddr <= waddr + 1;
          if (x == 0 && y == 0) begin
              $display("||||||||||||||||||||||||||");
              last <= 0;
              valid <= 1;
              wen <= 0;
              back <= 0;
          end else
          if (x == 0 || direction == TOP_DIR) begin
              y <= y - 1;
              //$display("top");
          end else
          if (y == 0 || direction == LEFT_DIR) begin
              x <= x - 1;
              //$display("left");
          end else
          if (direction == CORNER_DIR) begin
              x <= x - 1;
              y <= y - 1;
              //$display("corner");
          end
  end
end

always @(reset) begin
    //$display("RESETTING");
    valid <= 0;
    once <= 0;
    x <= LENGTH-1;
    y <= LENGTH-1;
end

// reset both valid_matrix and align_matrix
generate
    for(j = 0; j < LENGTH; j=j+1) begin: r
        for(k = 0; k < LENGTH; k=k+1)begin: r_in
            always @(reset) begin
                //$display("RESETTING");
                valid_matrix[j][k] <= 0;
                align_matrix[j][k] <= 0;
                interconnect[j][k] <= 0;
            end
        end
    end
endgenerate


// ...
// you may find genvar and generate statements to be VERY useful here.
endmodule
