module regFile(readReg1, readReg2, readReg3, writeReg, writeData, writeAddress, readData1, readData2, readData3, inCMD, ck, emit,
stored, endereco, stored_OK);
	input [5:0] readReg1, readReg2, readReg3;
	input [31:0] writeData;
	input [5:0] writeAddress;
	input stored;
	output reg stored_OK;
	input [31:0] endereco;
	input ck, writeReg, inCMD, emit;
	output reg [31:0] readData1, readData2, readData3;
	reg [31:0] registers[64:0];


	
	always @ (posedge ck) begin
		if(stored==1) begin
			registers[8] = endereco - 1;
			stored_OK = 1;
		end
		else if (writeReg) begin
			if(inCMD)
				registers[40] = writeData;
			else
				registers[writeAddress] = writeData;
			stored_OK = 0;
		end 
		else stored_OK = 0;
	end

always@(*) begin

	readData1 = registers[readReg1];
	readData2 = registers[readReg2];
	readData3 = registers[readReg3];
	
	if(emit)
		readData1 = registers[40];

		
end


endmodule