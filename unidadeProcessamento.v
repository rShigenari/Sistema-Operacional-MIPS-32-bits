	module unidadeProcessamento(LCD_ON,LCD_BLON, LCD_RW,LCD_EN, LCD_RS  ,
  LCD_DATA,start, switches, reset, zero, neg, overflow, nHLT,
  endereco, result, sdmilhao, smilhao, scmilhar, sdmilhar, smilhar ,
  scentesimal, sdecimal, sunidade, ck, ckin, returnMenu) ;

	output  [11:0] endereco;
	input start;
	input [16:0] switches;
  input wire ck, ckin;
	input wire nHLT;
	input wire returnMenu;
	wire [11:0]cpc;
	wire clk;
	wire pc_out, reset_pc, stored /*sinal quando o quantum estoura*/;
	wire halt_out, outmuxReg2, outmuxReg2_o;
	input wire reset;
	wire [31:0] DA, DB,DC;
	wire [31:0] instrucao, wd, outIM, outmuxdado, outMemInst;
	wire blockBIOS;
	wire [13:0] BUFFER_HD_OUTPUT;
	wire [13:0] HD_EFF_END;
	wire [1:0] flag_inst_type;
	wire zerarPC, emit;
	wire [4:0] pid; //valor do numero do processo
	wire onWriteReg, writeDataMem, outputEnable, onop, onskip, muxEnd;
	wire hlt, endPCorReg, flagCmd;
	wire [1:0] ctrlM5,  selectSize;
	wire [2:0] selectDado;
	wire selectD, outbios;
	wire [5:0] gravaEnd, reg1, ende, reg1_select,reg2_select;
	wire [31:0] outmux, outIOunit;
	wire [31:0] dadoLeitura;
	wire [11:0] outskip, skipEnd, pcin;
	wire  j, jmp, interrupt;
	wire inputEnable, selectRegFRST;
	output wire zero, neg;
	wire [3:0] controle;
	output wire overflow;
	wire [31:0] outOC;
	wire [3:0] dmilhao , milhao, cmilhar, dmilhar, centesimal, milhar, decimal, unidade;
	output wire[6:0] sdmilhao, smilhao, scmilhar, sdmilhar, smilhar ,scentesimal, sdecimal, sunidade;
	output wire [31:0]result;
	wire init;
   wire [31:0] copy_inst, outHD;
	wire write_hd;
	wire save_hd;
	wire init2, writeProcBuffer;
	wire [5:0] regMux;
	wire neg_nHLT, onWriteBuf;
	wire neg_reset, selectReg;
	wire [13:0] endereco_efetivo_HD;
	wire [31:0] firstPositionHD;

	//assign neg_nHLT =  ~nHLT;
	assign neg_reset = ~reset;
	wire [3:0] key;
	wire [8:0]ledg;
	wire [8:0]ledr;

	//para o display lcd
  output LCD_ON;    // LCD Power ON/OFF
  output LCD_BLON;    // LCD Back Light ON/OFF
  output LCD_RW;    // LCD Read/Write Select, 0 = Write, 1 = Read
  output LCD_EN;    // LCD Enable
  output LCD_RS;    // LCD Command/Data Select, 0 = Command, 1 = Data
  inout [7:0] LCD_DATA;    // LCD Data bus 8 bits
  wire [35:0] GPIO_0,GPIO_1;
  wire write_mem_inst, outIB;
  wire regType, stored_OK;

	DeBounce denbClk (.clk(ck),
				 .n_reset(1),
				 .button_in(nHLT),
				 .DB_out(neg_nHLT)
				 );

	Temporizador temp (.clkIn(ck),
							 .clkOut(clk));



	UC controlUnit(.opcode(instrucao[31:26]),
		 .onWriteReg(onWriteReg),
		 .writeDataMem(writeDataMem),
		 .outputEnable(outputEnable),
		 .onop(onop),
		 .outmuxReg2(outmuxReg2),
		 .onskip(onskip),
		 .muxEnd(muxEnd),
		 .ctrlM5(ctrlM5),
		 .zerarPC(zerarPC),
		 .selectSize(selectSize),
		 .selectDado(selectDado),
		 .selectD(selectD),
		 .HLT(hlt),
		 .flagCmd(flagCmd),
		 .inputEnable(inputEnable),
		 .endPCorReg(endPCorReg),
       .write_mem_inst(write_mem_inst),
		 .save_hd(save_hd),
		 .reset_pc(reset_pc),
		 .writeProcBuffer(writeProcBuffer),
		 .emit(emit),
		 .regType(regType),
		 .selectReg(selectReg),
		 .selectRegFRST(selectRegFRST),
		 .onWriteBuf(onWriteBuf),
		 .flag_inst_type(flag_inst_type),
		 .interrupt(interrupt)
);


	programCounter pc (
                     .ck (clk),
                     .jump(jmp),
                     .endereco(pcin),
                     .reset(neg_reset),
                     .hlt(hlt),
							.countPC(zerarPC),
							.CPCin(cpc),
							.output_cpc(cpc),
                     .nHLT(~neg_nHLT),
                     .OUTendereco(endereco),
							.stored(stored),
							.stored_OK(stored_OK),
							.returnMenu(~returnMenu),
							.interrupt(interrupt)
							);



  instructionMemory mem_inst(.ck(ck),
									 .clk(clk),
                            .write_enable(write_mem_inst),
                            .endereco(endereco),
                            .position(instrucao[11:0]),
                            .copy_inst(outHD),
									 .saida(instrucao)
									 );
									 

	muxEndereco mux_add(.ctrl(muxEnd),
					 .jIN(j),
					 .EA(outskip),
					 .EB(endereco),
					 .jOUT(jmp),
					 .Eout(pcin)
	);

	mux5bits mux_save_reg (.ctl(ctrlM5),
				 .DA(instrucao[25:21]),
				 .DB(instrucao[20:16]),
				 .DC(instrucao[15:11]),
				 .DD(instrucao[5:0]),
				 .outD(gravaEnd)
	);
	
	RegSizeSelector selector (.DA(instrucao[25:21]), 
									  .DB(instrucao[25:20]), 
									  
									  .controle(selectReg), 
									  .dataOut(reg1_select)
									  );
									  
									  
	RegSizeSelector selectorREG2 (.DA(instrucao[20:16]), 
									      .DB(instrucao[5:0]), 
									  
									  .controle(selectRegFRST), 
									  .dataOut(reg2_select)
									  );

	regFile Banco_de_Registradores(.readReg1(reg1_select),
			  .readReg2(reg2_select),
			  .readReg3(instrucao[15:11]),
			  .emit(emit),
			  .writeReg(onWriteReg),
			  .writeData(outmux),
			  .writeAddress(gravaEnd),
			  .readData1(DA),
			  .readData2(DB),
			  .readData3(DC),
			  .inCMD(flagCmd),
			  .ck(clk),
			  .stored(stored),
			  .endereco({10'b0, endereco}),
			  .stored_OK(stored_OK)
			  
	);

	extensorSinal Extensor_de_Sinal(.selectSize(selectSize),
											  .imm17(instrucao[15:0]),
											  .imm22(instrucao[20:0]),
											  .imm9(endereco),
											  .imm18(switches),
											  .out32(wd)
	);
	MUX mux1(.select(selectD),
				.DA(DB),
				.DB(wd),
				.outMUX(outIM)
	);
	controle2 OPcontrol(.nfuncao(instrucao[31:26]),
				 .onOP(onop),
				 .controle(controle)
	);
	ULA Unidade_Logica_Aritmetica(.controle(controle),
		 .DA(DA),
		 .DB(outIM),
		 .ULAresult(result),
		 .negativo(neg),
		 .zero(zero),
		 .overflow(overflow)
	);
	muxEnd PCorREG(.ctrl(endPCorReg),
						.EA(instrucao[11:0]),
						.EB(DA[11:0]),
						.Eout(skipEnd));

	controle1 opControl(.ONcontrole1(onskip),
				  .controle(instrucao[31:26]),
				  .jump(j),
				  .pc(endereco),
				  .endereco(skipEnd),
				  .zero(zero),
				  .negativo(neg),
				  .endout(outskip));

	MEMdados memoria_de_dados(.clk(clk),
									  .ONescrita(writeDataMem),
									  .dadoEscrita(DC),
									  .endereco(result[11:0]),
									  .dadoLeitura(dadoLeitura),
									  .ck(ck)
	);

	HD hard_disk(.clk(clk),
									  .pc(endereco),
									  .ONescrita(save_hd),
									  .dadoEscrita(DB),
									  .endereco(endereco_efetivo_HD),
									  .dadoLeitura(outHD),
									  .ck(ck)
									  );


	mux4 RAMorImm (.select(selectDado),
			.DA(result),
			.DB(DA),
			.DC(dadoLeitura),
			.DD(wd),
			.DE(outHD),
			.DF(firstPositionHD),
			.outD(outmux)
	);

	outputController outcontrol (.outputEnable(outputEnable),
										  .data(DA),
										  .out(outOC));

	
	HD_ADDR_BUFFER bufferAddr (.writeAddBuf(onWriteBuf), 
	
										.writeData(DB),
										.pos(DA), 
										.readData1(firstPositionHD),
										.ck(ck),
										.clk(clk)
										);
					


	somadorADDR sum(.index(instrucao[7:0]), 
					.pid_buffer(DA[13:0]), 
					.flag_inst_type(flag_inst_type), 
					.saida(endereco_efetivo_HD)
					);
				

	binToBCD BCDconversor(

				.dataBin(outOC),
				.endereco(pcin),
				.inputEnable(inputEnable),
				.outputEnable(outputEnable),
				.dmilhao(dmilhao),
				.milhao(milhao),
				.cmilhar(cmilhar),
				.dmilhar(dmilhar),
				.milhar(milhar),
				.centesimal(centesimal),
				.decimal(decimal),
				.unidade(unidade));

	display7segmentos H (.numero(dmilhao), .outDisplay(sdmilhao));

	display7segmentos G (.numero(milhao), .outDisplay(smilhao));

	display7segmentos F (.numero(cmilhar), .outDisplay(scmilhar));                               

	display7segmentos E (.numero(dmilhar), .outDisplay(sdmilhar));

	display7segmentos D (.numero(milhar), .outDisplay(smilhar));

	display7segmentos C (.numero(centesimal), .outDisplay(scentesimal));

	display7segmentos B (.numero(decimal), .outDisplay(sdecimal));

	display7segmentos A (.numero(unidade), .outDisplay(sunidade));

	lcdlab3 displayLCD(
		  .CLOCK_50(ck),    //    50 MHz clock
		  .LCD_ON(LCD_ON),    // LCD Power ON/OFF
		  .LCD_BLON(LCD_BLON),    // LCD Back Light ON/OFF
		  .LCD_RW(LCD_RW),    // LCD Read/Write Select, 0 = Write, 1 = Read
		  .LCD_EN(LCD_EN),    // LCD Enable
		  .LCD_RS(LCD_RS),    // LCD Command/Data Select, 0 = Command, 1 = Data
		  .LCD_DATA (LCD_DATA),   // LCD Data bus 8 bits
		  .ESTADO(DA),
		  .FLAG_MUDANCA_LCD(emit),
		  .opcode(instrucao[31:26])

);

endmodule
