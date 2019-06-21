/*M´odulo que armazena o valor do processo corrente
sempre referenciado pelo registardor 26
*/

module PID_BUFFER (clk, DA, flag_saveProc, process);
	input clk;
	input [31:0] DA;
	reg [3:0] buffer; //buffer que armazena o processo corrente
	input flag_saveProc; //flag vindo das UC que indica que ´e uma instrucao de saveProc
	output reg [3:0] process;
	
	always @(clk) begin 
	
		if(flag_saveProc)
			buffer<= DA; // vindo do registrador 26
			
		process <=buffer; //valor do processo corrente;
	end
	
endmodule 