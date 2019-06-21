module HD_ADDR_BUFFER(writeAddBuf, writeData,pos, readData1,ck, clk);
	input [31:0] writeData;
	input [5:0] pos;
	input ck, clk, writeAddBuf;
	output [31:0] readData1;
	reg [31:0] registers[63:0];

	always @ (posedge clk) begin
		
		if (writeAddBuf)
			registers[pos] = writeData;
	end

	assign readData1 = registers[pos];
endmodule