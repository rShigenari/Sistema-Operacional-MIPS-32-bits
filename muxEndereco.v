module muxEndereco (ctrl, jIN, EA,EB, jOUT, Eout);
	input ctrl, jIN;
	input [11:0] EA, EB;
	output reg jOUT;
	output reg [11:0] Eout;
	
	always @(*) begin
		case (ctrl)
			1'b0: begin Eout = EA;	
							jOUT = jIN;
					end
			1'b1: begin Eout = EB;
							jOUT = 0;
					end
		endcase
	end
endmodule