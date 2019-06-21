module controle1 (ONcontrole1, controle, jump, pc, endereco, zero, negativo, endout);
	input ONcontrole1;
	input [5:0] controle;
	input [11:0] endereco, pc;
	input zero, negativo;
	output reg jump;
	output reg [11:0] endout;
	reg [11:0] add;
	
	parameter beq = 6'b01111, bneq = 6'b10000, blz = 6'b10001, jmp = 6'b01101, jmpr = 6'b01110, jal = 6'b11010;
	
	
	always @ (*) begin 
		add = pc;
		if (ONcontrole1) begin
		case (controle)
			beq:
				if(zero==1) begin
					endout = add + endereco;
					jump =1;
				end
				else begin 
					endout = add;
					jump = 0;
				end
			bneq:
				if(zero == 0) begin
					endout = endereco;
					jump =1;
				end
				else begin 
					endout = add;
					jump = 0;
				end
			blz:
				if(negativo==1) begin
					endout = add + endereco;
					jump = 1;
				end
				else begin 
					endout = add;
					jump = 0;
				end
			jmp: begin
				endout = endereco;
				jump = 1;
			end
			jmpr: begin
				endout = endereco +1;
				jump = 1;
			end
			jal: begin
				endout = endereco;
				jump = 1;
			end
			default: begin
				endout = endereco;
				jump = 1;
				
			end
		endcase	
	end
	else begin
		endout = 0;
		jump = 0;
	end 
	end
endmodule 