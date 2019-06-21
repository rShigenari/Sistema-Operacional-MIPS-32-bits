	module tripleMUX (ctrl,DA, DB, DC, outMUX);
	input [1:0] ctrl;
	input [31:0] DA, DB, DC;
	output reg [31:0] outMUX;
	
	always@(*) begin
		case (ctrl)
			2'b00: outMUX = DA;
			2'b01: outMUX = DB;
			2'b10: outMUX = DC;
			default: outMUX = 32'bx;
		endcase
	end
endmodule
