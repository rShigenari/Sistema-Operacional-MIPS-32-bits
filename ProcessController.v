module ProcessController (clk, out_data, addr);
	input clk;
	input [3:0] addr;
	reg [31:0] data [9:0];
	output out_data;
	
	always @(posedge clk) begin
		data[0] = 32'b0;
		data[1] = 32'b0;
		data[2] = 32'b0;
		data[3] = 32'b0;
		data[4] = 32'b0;
		data[5] = 32'b0;
		data[6] = 32'b0;
		data[7] = 32'b0;
		data[8] = 32'b0;
		data[9] = 32'b0;	
	end
		
	assign out_data = data[addr];


endmodule
