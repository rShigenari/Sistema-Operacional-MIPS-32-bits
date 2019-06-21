module mux6bits (DA, DB, Dout, flag);
	input [5:0] DA, DB;
	input flag;
	output reg [5:0] Dout;
	
	always @(*) begin
		if(flag)
			Dout = DA;
		else 
			Dout = DB;
	end

endmodule