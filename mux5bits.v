module mux5bits (ctl, DA, DB, DC, DD, outD);
	input [1:0] ctl;
	input [5:0] DA, DB, DC, DD;
	output reg [5:0] outD;
	
	always @ (*) begin
		case (ctl) 
			2'b00: outD = DA;
			2'b01: outD = DB;
			2'b10: outD = DC;
			2'b11: outD = DD;
		endcase
	end
endmodule