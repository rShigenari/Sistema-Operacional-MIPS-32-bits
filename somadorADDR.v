//modulo que calcula o endereco efetivo

module somadorADDR (index, pid_buffer, flag_inst_type, saida);

	input [13:0]pid_buffer; //valor base 
	input [7:0] index; //index
	input [1:0] flag_inst_type; //valor da UC 
	output reg [13:0] saida; //endereco efetivo para o HD 
	
	always @(*) begin	
		case(flag_inst_type)
			2'b0: begin //instrucao de copia
				saida = pid_buffer;//o valor do inicio + posicoes seguintes 
			end 
			2'b1: begin //instrucao de SR LR
				saida = 500 + 40*pid_buffer + index;
			end 
			2'b10: begin //instrucao de store e load page 
				saida =  800 + 40*pid_buffer + index;                 
			end 
			default: saida = 0;
		endcase
	end 

endmodule
