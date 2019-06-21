module programCounter (ck, jump, countPC, endereco, reset, hlt, nHLT, OUTendereco, CPCin, output_cpc,interrupt, stored, stored_OK, returnMenu);
	input ck, jump, hlt, nHLT, reset, countPC, stored_OK, returnMenu,interrupt;
	input [11:0] endereco;
	reg [11:0] address;
	output reg[11:0] OUTendereco;
	input [11:0] CPCin;
	reg [11:0] CPCout;
	output reg [11:0] output_cpc;
	reg lastState;
	output reg stored;
	always @ (posedge ck) begin

	
		if(interrupt) begin
			CPCout = 12'b111111111111;
			stored = 0;
			address = endereco + 1;
		end
	  else if (CPCin == 12'b110010) begin
			address = endereco;
			stored = 1;
			CPCout = CPCin + 1;
		end 
		
		else if (stored_OK)  begin
			address = 12'b110101001;//427
			CPCout = 12'b1111111111;
			stored = 0;
		end
		 else if(countPC) begin
			CPCout = 0;
			address = endereco + 1;
			stored = 0;
		end 

		else if(returnMenu) begin
			address = 12'b100010; 
			CPCout = CPCin + 1;
			stored = 0;
		end
	else if(jump) begin
			address = endereco;
			stored = 0;
			CPCout = CPCin + 1;
		end 
	

		else if(nHLT && !lastState) begin
			address = endereco + 1;
			CPCout = CPCin + 1;
			stored = 0;
		end 
		
		else if(hlt) begin
			stored = 0;
		                                                                                                                                                                                                                                                                                                            
		end
		else if(reset) begin
			address = 0;
			stored = 0;
		end

		else  begin
			address = endereco + 1;
			CPCout = CPCin + 1;
			stored = 0;
		end
			output_cpc <= CPCout;
			lastState<= nHLT;
			OUTendereco <= address;	
			
	end

endmodule