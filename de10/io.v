integer s = $fopen("in.fifo");
reg[31:0] x = 0;

always @(posedge clock.val) begin
  //$fread(s, x);
  $display("what");
  $display(x);
  $finish;
  if ($feof(s)) begin
    $finish;
  end
  $display(x);
end

