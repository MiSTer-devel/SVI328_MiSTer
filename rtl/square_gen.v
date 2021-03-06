
module square_gen(
  input clk,
  input Q,
  input start,
  input [7:0] din,
  input extend,
  output reg done,
  output dout
);

parameter STP = 24'hF0D; //For clk = 42,666/2 Mhz

reg [23:0] div;
reg [3:0] nbit;
reg [8:0] data;
reg [1:0] cnt;
reg en, pulse;

initial begin
  en = 0;
  nbit = 0;
  cnt = 0;
  div = 0;
end

assign dout = data[8] ? ~cnt[0] : ~cnt[1];

reg q_r;


always @(posedge clk) begin
  if (Q==1 && q_r ==0) begin
    if (start) div <= 24'd0;
	 else if (en) { pulse, div } <= div + STP;
  end
  q_r<=Q; 
end


reg pulse_r,start_r;

always @(posedge clk) begin
  if ((pulse_r ==0 && pulse==1) || (start_r ==0 && start==1)) begin
  if (start) begin
    en <= 1'b1;
    done <= 1'b0;
    nbit <= 1'b0;
    data <= extend ? {1'b0,din} : {din,1'b0};
  end
  else if (en) begin
    cnt <= cnt + 2'd1;
    if ({ ~data[8], 1'b1 } == cnt)  begin
      cnt <= 2'd0;
      nbit <= nbit + 4'd1;
      data <= { data[7:0], 1'b0 };
      if (nbit == 4'd7 + extend) begin
        en <= 1'b0;
        done <= 1'b1;
      end
    end
  end
  end
	pulse_r<=pulse;
	start_r<=start;
 
end

endmodule