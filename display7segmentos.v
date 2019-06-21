module display7segmentos(numero, outDisplay);	

	input [3:0] numero;
	output reg [6:0] outDisplay;
	
	always@(*)
		case(numero)
			4'b0000 : outDisplay = ~7'b1111110;
			4'b0001 : outDisplay = ~7'b0110000;
			4'b0010 : outDisplay = ~7'b1101101;
			4'b0011 : outDisplay = ~7'b1111001;
			4'b0100 : outDisplay = ~7'b0110011;
			4'b0101 : outDisplay = ~7'b1011011;
			4'b0110 : outDisplay = ~7'b1011111;
			4'b0111 : outDisplay = ~7'b1110000;
			4'b1000 : outDisplay = ~7'b1111111;
			4'b1001 : outDisplay = ~7'b1111011;
			4'b1011 : outDisplay = ~7'b0000001;// -- ---- --
			default : outDisplay = ~7'b0000000;
		endcase

endmodule 