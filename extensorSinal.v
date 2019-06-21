module extensorSinal (selectSize, imm17, imm22, imm9, imm18, out32);
	input [1:0]selectSize;
	input [15:0] imm17;
	input [21:0] imm22;
	input [11:0] imm9;
	input [17:0] imm18;
	output reg [31:0] out32;
	
	parameter i17 = 2'b0, i22 = 2'b01, i9 = 2'b10, i18 = 2'b11;
	
	always @ (*) begin
		case (selectSize)
			i17: out32 = {16'b0, imm17};
			i22: out32 = {9'b0, imm22};
			i9: out32 = {20'b0, imm9};
			i18: out32 = {14'b0, imm18};
		endcase
	end
endmodule
	 
	