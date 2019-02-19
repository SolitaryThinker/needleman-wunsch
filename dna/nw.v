// Grid Elements:
module YOUR_GRID_ELEMENT#(
// you may have similar parameters as the top level module here...
)(
//...
);
endmodule

// Grid:
module YOUR_TOP_LEVEL_MODULE#(
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
// ...
// you may find genvar and generate statements to be VERY useful here. 
endmodule
