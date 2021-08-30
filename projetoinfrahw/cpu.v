module cpu (
	input wire clk,
	input wire reset
);

	// Data wires
	wire [31:0] MEM_to_IR;// OUTPUT do MEM
	wire [31:26] OPCODE; //OUTPUT DO IR
	wire [25:21] RS; //OUTPUT DO IR
	wire [20:16] RT; //OUTPUT DO IR
	wire [15:0] OFFSET; //OUTPUT DO IR
	wire [31:0] PC_in; //entrada do PC e OUTPUT do Mux 11
	wire [31:0] PC_out; //OUTPUT do PC
	wire [31:0] ALUOUT_out; //OUTPUT do registrador ALUout
	wire [31:0] ALUResult_out; //OUTPUT da ALU
	wire [31:0] M2_out; //OUTPUT do Mux 2
	wire [31:0] M1_out; //OUTPUT do Mux 1 (registrador de exceções)
	wire [31:0] Reg_B_out; //OUTPUT do Registrador B
	wire [31:0] SS_out; //OUTPUT do StoreSize
	wire [31:0] M3_out; //OUTPUT do Mux 3
	wire [4:0] M4_out; //OUTPUT do Mux 4
	wire [31:0] M5_out; //OUTPUT do Mux 5.
	wire [31:0] BR_out_1; //OUTPUT do banco de registradores. vai para reg A.
	wire [31:0] BR_out_2; //OUTPUT do banco de registradores. vai para reg B.
	wire [31:0] LS_out; //OUTPUT do load size.
	wire [31:0] LO_out; //OUTPUT do LO.
	wire [31:0] RegD_out; //OUTPUT do registrador de deslocamento.
	wire [31:0] HI_out; //OUTPUT do HI.
	wire [31:0] M9_out; //OUTPUT do M9.
	wire [31:0] M8_out; //OUTPUT do M8
	wire [31:0] MULT_HI_out; //OUTPUT HI da caixa MULT
	wire [31:0] DIV_HI_out; //OUTPUT HI da caixa DIV
	wire [31:0] RegA_out; //OUTPUT do registrador A
	wire [31:0] RegB_out; //OUTPUT do registrador B
	wire [4:0] M10_out; //OUTPUT do M10
	wire [31:0] SL2_B_out; //OUTPUT do shift left 2 B
	wire [31:0] MDR_A_out; //OUTPUT do MDR A
	wire [31:0] SE_out; //OUTPUT do SignExtend
	wire [31:0] M7_out; //OUTPUT do mux 7
	wire [31:0] M6_out; //OUTPUT do mux 6
	wire [2:0] FTS_out; //OUTPUT do funct to shift
	wire [31:0] SL2_A_out; //OUTPUT do Shift Left 2 A
	wire [31:0] EPC_out; //OUTPUT do EPC
	wire [31:0] MDR_B_out; //OUTPUT do MDR B
	wire [2:0] M13_out; //OUTPUT do mux 13
	wire [31:0] LUI_out; //OUTPUT do LUI
	
	
	// Control wires
	wire IR_w; //sinal do instruction register
	wire PC_w; //sinal do pc
	wire [1:0] IorD_w; //sinal do mux 2
	wire M3_w; //sinal do mux 3
	wire MemWrite; //sinal da memória
	wire RegWrite; //sinal banco de registradores
	wire [2:0] MemToReg; //sinal do mux 5
	wire LO_w; //sinal para registrador LO
	wire HI_w; //sinal para registrador HI
	wire M8_w; //sinal do mux 8
	wire M9_w; //sinal do mux 9
	wire RegA_w; //sinal registrador A
	wire RegB_w; //sinal registrador B
	wire [1:0] M10_w; //sinal do mux 10
	wire [2:0] ALUSrcB; //sinal do mux 7
	wire [1:0] ALUSrcA; //sinal do mux 6
	wire ALUOUT_w; //sinal da ALUOUT
	wire [2:0] ALUOp; //sinal seletor da ALU
	wire ALUOverflow; //sinal de saída da ALU informando overflow aritmético (FLAG)
	wire ALUNegativo; //sinal de saída da ALU informando que o resultado é negativo (FLAG)
	wire ALUZero; //sinal de saída da ALU sinalizando que o valor que saiu é zero. (FLAG)
	wire ALUIgual; //sinal de saída da ALUsinalizando se as entradas são iguais. (FLAG)
	wire ALUMaior; //sinal de saída da ALU sinalizando se a entrada A é maior que a entrada B. (FLAG)
	wire ALUMenor; //sinal de saída da ALU sinalizando se a entrada A é menor que a entrada B (FLAG)
	wire [1:0] PCSource; //sinal para MUX 11
	wire EPCWrite; //sinal do EPC
	wire [1:0] RegDst; //sinal do mux4
	wire MDR_A_w; //sinal do Memory Data Register A
	wire MDR_B_w; //sinal do Memory Data Register B
	wire [1:0] M1_w; //sinal do mux 1
	wire PCWriteCond; //alterar na entrada do pc !!!!!!!!!!!!!!!
	wire PCWriteCond2; //alterar na entrada do pc !!!!!!!!!!!!!!
	wire [1:0] M13_w; //is
	
	
	Registrador PC (
		clk,
		reset,
		PC_w, //sinal do PC
		PC_in, //entrada do PC e saída do Mux 11
		PC_out //OUTPUT
	);
	
	MUX_1 M1 ( //JÁ TEM SAÍDA DECLARADA !!!!!!!!
		M1_w, //sinal do mux 1
		M1_out //OUTPUT
	);

	MUX_2 M2 (
		IorD_w, //sinal
		PC_out, //saída do PC
		ALUOUT_out, // saída do registrador da ULA
		ALUResult_out, // saída da ULA
		M1_out, // saída do registrador de exceções
		M2_out // OUTPUT
	);
	
	MUX_3 M3 (
		M3_w, //seletor do mux3
		Reg_B_out, //registrador B
		SS_out, // store size
		M3_out // OUTPUT
	);
	
	Memoria MEM (
		M2_out, //endereço da memória a ser lido.
		clk,
		MemWrite, // sinal. se for 0, é para ler. se for 1, é para escrever, conforme a explicação da caixa.
		M3_out, //valor lido quando MemWrite for 0.
		MEM_to_IR // OUTPUT
	);
	
	Registrador MDR_A (
		clk,
		reset,
		MDR_A_w, //sinal
		MEM_to_IR, //entrada que é a saída da Memória
		MDR_A_out //OUTPUT
	);
	
	Registrador MDR_B ( //Memory Data Register
		clk,
		reset,
		MDR_B_w, //sinal
		MEM_to_IR, //entrada que é a saída da Memória
		MDR_B_out //OUTPUT
	);
	
	
	Store_Size SS ( //JÁ TEM SAÍDA DECLARADA!!!!!!!!!
		MDR_B_out,
		RegB_out,
		SS_out
	);
	
	Load_Size LS (
		MDR_B_out, //saída do registrador MDR B
		LS_out //OUTPUT
	);
	
	MUX_4 M4 (
		RegDst, //sinal
		RT, //rt
		OFFSET[15:11], //rd
		M4_out //OUTPUT
	);

	Instr_Reg IR (
		clk,
		reset,
		IR_w, //sinal
		MEM_to_IR, //saída de MEM
		OPCODE, //OUTPUT
		RS, //OUTPUT
		RT, //OUTPUT
		OFFSET //OUTPUT
	);
	
	MUX_13 M13 (
		M13_w,
		FTS_out,
		M13_out
	
	);
	
	Registrador LO ( //JÁ TEM SAÍDA DECLARADA!!!!!!!!
		clk,
		reset,
		LO_w, //sinal do registrador LO.
		M9_out, //saída do mux 9
		LO_out //OUTPUT
	);
	
	Registrador HI ( //JÁ TEM SAÍDA DECLARADA!!!!!!!!
		clk,
		reset,
		HI_w, //sinal do registrador HI.
		M8_out, //saída do mux 8
		HI_out //OUTPUT
	);
	
	RegDesloc RegD (
		clk,
		reset,
		M13_out, //saída do funct to shift (SHIFT)
		M10_out, //saída do mux 10 (N)
		M6_out, //saída do registrador A (ENTRADA)
		RegD_out //OUTPUT
	);
	
	Registrador ALUOUT ( //JÁ TEM SAÍDA DECLARADA!!!!!!
		clk,
		reset,
		ALUOUT_w, //sinal da aluout
		ALUResult_out, //saída da ALU
		ALUOUT_out //OUTPUT
	);
	
	MUX_5 M5 (
		MemToReg, //sinal de 3 bits
		LS_out, //saída de load size.
		LO_out, //saída do registrador LO.
		ALUOUT_out, //saída do registrador ALUOUT.
		RegD_out, //saída do registrador de deslocamento.
		HI_out, //saída do registrador HI.
		LUI_out,
		M5_out //OUTPUT.
	);
	
	MUX_8 M8 (
		M8_w, //sinal mux 8
		DIV_HI_out, //saída HI de div
		MULT_HI_out, //saída HI de mult
		M8_out //OUTPUT que vai para registrador HI
	);
	
	MUX_9 M9 ( //JÁ TEM SAÍDA DECLARADA!!!!!!!!!!!!!
		M9_w, //sinal mux 9
		DIV_LO_out, //saída LO de div
		MULT_LO_out, //saída LO de mult
		M9_out //OUTPUT
	);
	
	//Mult_Operation MULT ( //JÁ TEM AS SAÍDAS DECLARADAS!!!!!!!
		//falta fazer
	//);
	
	//Div_Operation DIV( //JÁ TEM AS SAÍDAS DECLARADAS!!!!!!!!!!
		//falta fazer
	//);
	
	Banco_reg BR (
		clk,
		reset,
		RegWrite, //sinal que indica se é leitura ou escrita. 0 = leitura. 1 = escrita.
		RS, //read register 1. registrador 1 a ser lido, que é uma saída do IR.
		RT, //read register 2. registrador 2 a ser lido, que é uma saída do IR.
		M4_out, // write register. saída do mux 4. registrador a ser escrito. SE LIGAR PQ A ENTRADA É DE 5 BITS PARECE.!!!!!!!!!!!!!!!!!!!!!!!!
		M5_out, //write data. saída do mux 5. dado a ser escrito.
		BR_out_1, //OUTPUT. read data 1. é o que vai pro registrador A.
		BR_out_2 //OUTPUT. read data 2. é o que vai pro registrador B.
	);
	
	Registrador RegA (
		clk,
		reset,
		RegA_w, //sinal para carregar o valor ao registrador A.
		BR_out_1, //saída read data 1 do banco de registradores.
		RegA_out //OUTPUT
	);
	
	Registrador RegB (
		clk,
		reset,
		RegB_w, //sinal para carregar o valor ao registrador B.
		BR_out_2, //saída read data 2 do banco de registradores.
		RegB_out //OUTPUT	
	);
	
	ShiftLeft2A SL2_A (
		OFFSET,
		PC_out, //saída do PC
		SL2_A_out //OUTPUT
	);
	
	ShiftLeft2B SL2_B (
		SE_out, //saída do Sign Extend
		SL2_B_out //OUTPUT
	);
	
	SignExtend SE (
		OFFSET, //saída de 16 bits do IR
		SE_out //OUTPUT
	);
	
	MUX_10 M10 (
		M10_w, //sinal mux 10
		RegB_out[4:0], //registrador B
		OFFSET[10:6], //registrador rd
		MDR_A_out[4:0], //memoria
		M10_out //OUTPUT M10 que vai entrar no registrador de deslocamento. 5 bits
	);
	
	MUX_7 M7 (
		ALUSrcB, //sinal mux 7.
		RegB_out, //saída de B
		SL2_B_out, //saída do shift left 2 B
		MDR_A_out, //saída do MDR A
		SE_out, //saída de SignExtend
		M7_out //OUTPUT
	);
	
	MUX_6 M6 (
		ALUSrcA, //sinal mux 6
		PC_out, //saída de PC
		LS_out, //saída de LoadSize
		RegA_out, //saída do registrador A
		RegB_out, //saída do registrador B
		M6_out //OUTPUT
	);
	
	FunctToShift FTS (
		OFFSET[5:0], //valor de funct
		FTS_out //OUTPUT
	);
	
	ula32 ALU (
		M6_out, //entrada A da ULA
		M7_out, //entrada B da ULA
		ALUOp, //seletor da ULA
		ALUResult_out, //OUTPUT da ALU (SOMA, SUB, XOR, AND, NOT, INCREMENTO DE 1)
		ALUOverflow, //OUTPUT sinalizando overflow aritmetico
		ALUNegativo, //OUTPUT sinalizando que o valor é negativo
		ALUZero, //OUTPUT sinalizando que o valor que saiu é zero.
		ALUIgual, //OUTPUT sinalizando se as entradas são iguais.
		ALUMaior, //OUTPUT sinalizando se a entrada A é maior que a entrada B.
		ALUMenor //OUTPUT sinalizando se a entrada A é menor que a entrada B
	);
	
	MUX_11 M11 (
		PCSource, //seletor
		ALUResult_out, //pc + 4 (saída da alu)
		ALUOUT_out, //saída da ALUOut
		SL2_A_out, //endereço do jump, que é saída de SL2_A
		EPC_out, //saída do EPC
		PC_in //OUTPUT
	);
	
	Registrador EPC (
		clk,
		reset,
		EPCWrite, //sinal para carregar
		ALUOUT_out, //entrada do EPC
		EPC_out //OUTPUT
	);

	LUI Lui (
		OFFSET,
		LUI_out
	);
	
	UnidadeDeControle Ctrl_Unit (
		clk,
		reset,
		OPCODE,
		OFFSET[5:0], //funct
		ALUOverflow, //sinal de saída da ALU informando overflow aritmético (FLAG)
		ALUNegativo, //sinal de saída da ALU informando que o resultado é negativo (FLAG)
		ALUZero, //sinal de saída da ALU sinalizando que o valor que saiu é zero. (FLAG)
		ALUIgual, //sinal de saída da ALUsinalizando se as entradas são iguais. (FLAG)
		ALUMaior, //sinal de saída da ALU sinalizando se a entrada A é maior que a entrada B. (FLAG)
		ALUMenor, //sinal de saída da ALU sinalizando se a entrada A é menor que a entrada B (FLAG)
		IR_w, //sinal do instruction register
		PC_w, //sinal do pc
		IorD_w, //sinal do mux 2
		M3_w, //sinal do mux 3
		MemWrite, //sinal da memória
		RegWrite, //sinal banco de registradores
		MemToReg, //sinal do mux 5
		LO_w, //sinal para registrador LO
		HI_w, //sinal para registrador HI
		M8_w, //sinal do mux 8
		M9_w, //sinal do mux 9
		RegA_w, //sinal registrador A
		RegB_w, //sinal registrador B
		M10_w, //sinal do mux 10
		ALUSrcB, //sinal do mux 7
		ALUSrcA, //sinal do mux 6
		ALUOUT_w, //sinal da ALUOUT
		ALUOp, //sinal seletor da ALU
		PCSource, //sinal para MUX 11
		EPCWrite, //sinal do EPC
		RegDst, //sinal do mux4
		MDR_A_w, //sinal do Memory Data Register A
		MDR_B_w, //sinal do Memory Data Register B
		M1_w, //sinal do mux 1
		PCWriteCond,
		PCWriteCond2,
		M13_w
		
	);
	


endmodule 