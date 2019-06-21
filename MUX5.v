module MUX5 (R1, R2, select, saida);
	input [4:0] R1, R2;
	input select;
	output reg[4:0] saida;
	
	always @(*) begin
		case (select)
			1'b0: saida = R1;
			1'b1: saida = R2;
		endcase
	end
endmodule
			