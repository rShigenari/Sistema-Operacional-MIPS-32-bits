module controle2(nfuncao, onOP, controle);
	input [5:0] nfuncao;
	input onOP;
	output reg [3:0] controle;

	parameter adc = 6'b00000, sub = 6'b00001, adci = 6'b00010, subi = 6'b00011, e = 6'b00100,
	ou = 6'b00101, n = 6'b00110, lowo = 6'b00111 , stwo = 6'b01000, slel = 6'b01011,
	sril = 6'b01100, beq = 6'b01111, bneq = 6'b10000, blz = 6'b10001, slet = 6'b10010,
	sgrt = 6'b10011, mult = 6'b11000, multi = 6'b11001, div = 6'b11011;
	
	always @(*) begin
		if(onOP) begin
			case (nfuncao)
				adc: controle = 4'b0;
				sub: controle = 4'b1;
				adci: controle = 4'b0;
				subi: controle = 4'b1;
				e: controle = 4'b10;
				ou: controle = 4'b11;
				n: controle = 4'b100;
				lowo: controle = 4'b0;
				stwo: controle = 4'b0;
				slel: controle = 4'b101;
				sril: controle = 4'b110;
				beq: controle = 4'b111;
				bneq: controle = 4'b1000;
				blz: controle = 4'b1001;
				slet: controle = 4'b1010;
				sgrt: controle = 4'b1011;
				mult: controle = 4'b1100;
				multi: controle = 4'b1100;
				div: controle = 4'b1101;
				default: controle = 4'bx;
				endcase
			end
		else controle = 5'bx;
	end
endmodule 