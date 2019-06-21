module systemInitializer (init, out, biosInst, memInst); //multiplexador entre bios ou memoria de instrucoes
	input init;
	input [31:0] biosInst, memInst;
	output reg [31:0] out;
	
	always @(*) begin
		if(init)
			out = memInst; //senao executar a memoria de instrucoes 
			
		else 
			out = biosInst; //se ainda ha instrucoes na bios, executar a bios 
	
	end
endmodule 