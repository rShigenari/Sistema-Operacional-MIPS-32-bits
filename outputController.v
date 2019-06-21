module outputController (outputEnable, data, out);
	input outputEnable;
	input [31:0] data;
	output reg [31:0] out;
	
	always @ (*) begin
		if(outputEnable)
			out = data;
		else 
			out = 0;
	end
endmodule