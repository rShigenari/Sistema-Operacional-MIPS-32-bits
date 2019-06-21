module ULA  (controle, DA, DB, ULAresult, negativo, zero, overflow);
  input [3:0] controle;
  input [31:0] DA;
  input [31:0] DB;
  output reg [31:0] ULAresult;
  output zero;
  output negativo;
  integer i;
  reg [63:0] multResult;
  output reg overflow;
  reg [32:0] resultOF;
  
	parameter adc = 4'b0, sub = 4'b1, e = 4'b10, ou = 4'b11, n = 4'b100, 
	slel = 4'b101, sril = 4'b110, beq = 4'b111, bneq = 4'b1000, 
	blz = 4'b1001, slet =4'b1010, sgrt = 4'b1011, mult = 4'b1100, div = 4'b1101;

  always @ (controle, DA, DB) begin
    case(controle)
      adc: begin 
		resultOF = DA + DB; //ADC
		overflow = 0;
		if(resultOF[32] == 1) begin
			overflow = 1;
			resultOF = 0;
		end
		ULAresult = resultOF;
		end
		
      sub: begin //sub
			if(DA>DB)
				ULAresult = DA - DB;	
			else
				ULAresult = DB - DA;	
			overflow = 0;
			end
		
      e: begin ULAresult = DA & DB; //AND 
			overflow = 0;
			end
      ou: begin ULAresult = DA | DB; //OR
			overflow = 0;
			end
      n: begin ULAresult = !DA;
			overflow = 0;
			end
		sril: begin ULAresult = DA >> DB; //set right logical
				overflow = 0;
				end
      slel: begin 
			ULAresult = DA << DB;
			overflow = 0;
		end
      beq: begin 
				if (DA == DB) ULAresult = 0; //branch equal
				else ULAresult = 1;
				overflow = 0;
			 end
      bneq: begin
					if(DA != DB) ULAresult = 1; //branch not equal
					else ULAresult = 0;
					overflow = 0;
				end
      blz: begin 
			  ULAresult = DA;
			  overflow = 0;
			  end
      sgrt: begin if (DA > DB) ULAresult = 1; //set greater than
				else ULAresult =0;
				overflow = 0;
				end
      slet:  begin if (DA < DB) ULAresult = 1; //set less than
				else ULAresult =0;
				overflow = 0;
				end
		mult: begin
			overflow = 0;
				multResult = DA * DB;
				i = 32;
				while(i <= 63) begin
					if (multResult[i]) begin
						overflow = 1;
						multResult = 0;
					end
					i= i + 1;
				end
				ULAresult = multResult [31:0];
		end
		div: begin
			ULAresult = DA/DB;
			overflow = 0;
		end
		default: begin
			ULAresult = 0;
			overflow = 0;
		end
    endcase
    end
		
	assign zero = (ULAresult==0);
	assign negativo = ($signed (ULAresult) < 0);

endmodule
