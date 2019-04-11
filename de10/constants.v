// Output type
localparam OUTPUT_TYPE = 0;

// Number of characters per input
localparam LENGTH = 15;
// Number of bits per character
localparam CWIDTH = 2;

// Number of bits per coordinate
localparam CORD_LENGTH = 8;

// Number of elements in Memory file
localparam MEM_SIZE = 8;

// Character constants
localparam[CWIDTH-1:0] A = 2'b00;
localparam[CWIDTH-1:0] C = 2'b01;
localparam[CWIDTH-1:0] G = 2'b10;
localparam[CWIDTH-1:0] T = 2'b11;

//localparam[1:0] TOP_DIR = 2'b00;
//localparam[1:0] LEFT_DIR = 2'b01;
//localparam[1:0] CORNER_DIR = 2'b10;

// Number of bits per score
localparam SWIDTH = 16;

// Scoring constants
localparam signed[SWIDTH-1:0] MATCH = 1;
localparam signed[SWIDTH-1:0] INDEL = -1;
localparam signed[SWIDTH-1:0] MISMATCH = -1;
