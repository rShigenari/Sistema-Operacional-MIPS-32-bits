module MEMdados(clk, ONescrita, dadoEscrita, endereco, dadoLeitura, ck);
	input clk, ONescrita, ck, clk;
	input [6:0] endereco;

	input [31:0] dadoEscrita;
	output reg [31:0] dadoLeitura;
	reg [31:0] memoria [128:0];


	always @ (posedge clk) begin	
		if (ONescrita)
				memoria[endereco] = dadoEscrita;

	end

	always @ (posedge ck) begin
		dadoLeitura = memoria[endereco];
	end

endmodule
