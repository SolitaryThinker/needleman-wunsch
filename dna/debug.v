include constants.v;
include nw.v;

// We're going to use a hard-wired length of 4 here
localparam HLENGTH = 4;

// Instantiate compute grid with hard-wired inputs
wire [HLENGTH*CWIDTH-1:0] s1 = {A, T, C, G};
wire [HLENGTH*CWIDTH-1:0] s2 = {A, T, C, G};
wire signed[SWIDTH-1:0] score;
wire done;
Grid#(
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
  $display("=======================================================");
  $display("%d %d %d %d", g.outer_cells[0].inner_cells[0].s.c.score,
                          g.outer_cells[0].inner_cells[1].s.c.score,
                          g.outer_cells[0].inner_cells[2].s.c.score,
                          g.outer_cells[0].inner_cells[3].s.c.score
  );
  $display("%d %d %d %d", g.outer_cells[1].inner_cells[0].s.c.score,
                          g.outer_cells[1].inner_cells[1].s.c.score,
                          g.outer_cells[1].inner_cells[2].s.c.score,
                          g.outer_cells[1].inner_cells[3].s.c.score
  );
  $display("%d %d %d %d", g.outer_cells[2].inner_cells[0].s.c.score,
                          g.outer_cells[2].inner_cells[1].s.c.score,
                          g.outer_cells[2].inner_cells[2].s.c.score,
                          g.outer_cells[2].inner_cells[3].s.c.score
  );
  $display("%d %d %d %d", g.outer_cells[3].inner_cells[0].s.c.score,
                          g.outer_cells[3].inner_cells[1].s.c.score,
                          g.outer_cells[3].inner_cells[2].s.c.score,
                          g.outer_cells[3].inner_cells[3].s.c.score
  );

  count <= (count + 1);
  if (done | (&count)) begin
    $finish(1);
  end
end
