module binToBCD(outputEnable, endereco, inputEnable, dataBin, dmilhao, milhao, cmilhar, dmilhar, milhar, centesimal, decimal, unidade);
	input [31:0] dataBin;
	input [11:0] endereco;
	input outputEnable, inputEnable;
	output reg [3:0] dmilhao , milhao, cmilhar, dmilhar, centesimal, milhar, decimal, unidade;
	integer i;
	
	always @(endereco) begin
	dmilhao = 4'd0;
	milhao = 4'd0;
	cmilhar =  4'd0;
	dmilhar =  4'd0;
	
		for(i = 11; i>=0; i = i-1 ) begin
		//adiciona 3
		if(dmilhao > 4)
			dmilhao = dmilhao + 3;
		if(milhao > 4)
			milhao = milhao + 3;
		if(cmilhar > 4)
			cmilhar = cmilhar + 3;
		if(dmilhar > 4)
			dmilhar = dmilhar + 3;
			
		//shift left 1
		dmilhao = dmilhao << 1;
		dmilhao [0] = milhao [3];
		
		milhao = milhao << 1;
		milhao [0] = cmilhar [3];

		
		cmilhar = cmilhar << 1;
		cmilhar [0] =  dmilhar [3];
		
		dmilhar = dmilhar << 1;
		dmilhar [0] =  endereco[i];
		end
	
	end
	
	always @(dataBin) begin


	milhar = 4'd0;
	centesimal = 4'd0;
	decimal = 4'd0;
	unidade = 4'd0;
	
		if (outputEnable == 0)
			begin
		
			if(inputEnable ==1) begin
				
				unidade = 4'b1011;
				decimal = 4'b1011;
				centesimal = 4'b1011;
				milhar = 4'b1011;


			end
		else
			begin
				unidade = 4'b1010;
				decimal = 4'b1010;
				centesimal = 4'b1010;
				milhar = 4'b1010;


			 end
	end

	
	else
		begin
	
	for(i = 31; i>=0; i = i-1 ) begin
		//adiciona 3

		

		if(milhar > 4)
			milhar = milhar + 3;
		if(centesimal > 4)
			centesimal = centesimal + 3;
		if(decimal > 4)
			decimal = decimal + 3;
		if (unidade > 4)
			unidade = unidade + 3;
			
		//shift left 1

		
		milhar = milhar << 1;
		milhar [0] = centesimal [3];
		
		centesimal = centesimal << 1;
		centesimal [0] = decimal [3];
		
		decimal = decimal << 1;
		decimal [0] = unidade [3];
		
		unidade = unidade <<1;
		unidade [0] = dataBin[i];
		end
	end
end	

endmodule
			