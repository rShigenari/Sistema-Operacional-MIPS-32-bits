module mux4 (select, DA, DB,DC, DD, DE, DF, outD);
input [2:0] select;
input [31:0] DA, DB, DC, DD, DE, DF;
output reg [31:0] outD;
	
always @ (*) begin
 case (select)
	3'b0: outD = DA;	
	3'b01: outD = DB;
	3'b10: outD = DC;
	3'b11: outD = DD;
	3'b100: outD = DE;
	3'b101: outD = DF;
	default: outD = 0;
 endcase
end
endmodule