module RegSizeSelector (DA, DB, controle, dataOut);

	input [5:0] DA, DB;
	output reg [5:0] dataOut;
	input controle;

	always @ (*) begin
		case (controle) 
			0: dataOut = DA;
			1:dataOut = DB;
		endcase
	end


endmodule 