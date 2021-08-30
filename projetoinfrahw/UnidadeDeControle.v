module UnidadeDeControle (

	//inputs
	input wire clk,
	input wire reset,
    
	input wire [5:0] OPCODE,
	input wire [5:0] FUNCT,
	
	input wire ALUOverflow, //sinal de saída da ALU informando overflow aritmético (FLAG)
	input wire ALUNegativo, //sinal de saída da ALU informando que o resultado é negativo (FLAG)
	input wire ALUZero, //sinal de saída da ALU sinalizando que o valor que saiu é zero. (FLAG)
	input wire ALUIgual, //sinal de saída da ALUsinalizando se as entradas são iguais. (FLAG)
	input wire ALUMaior, //sinal de saída da ALU sinalizando se a entrada A é maior que a entrada B. (FLAG)
	input wire ALUMenor, //sinal de saída da ALU sinalizando se a entrada A é menor que a entrada B (FLAG)
    
    //flags da ULA (inputs)
    //sinais de 1 bit (outputs)
    //sinais de mais de 1 bit (outputs)
    //sinais dos muxes (outputs)
	 
	 //outputs
	 
	output reg IR_w, //sinal do instruction register
	output reg PC_w, //sinal do pc
	output reg [1:0] IorD_w, //sinal do mux 2
	output reg M3_w, //sinal do mux 3
	output reg MemWrite, //sinal da memória
	output reg RegWrite, //sinal banco de registradores
	output reg [2:0] MemToReg, //sinal do mux 5
	output reg LO_w, //sinal para registrador LO
	output reg HI_w, //sinal para registrador HI
	output reg M8_w, //sinal do mux 8
	output reg M9_w, //sinal do mux 9
	output reg RegA_w, //sinal registrador A
	output reg RegB_w, //sinal registrador B
	output reg [1:0] M10_w, //sinal do mux 10
	output reg [2:0] ALUSrcB, //sinal do mux 7
	output reg [1:0] ALUSrcA, //sinal do mux 6
	output reg ALUOUT_w, //sinal da ALUOUT
	output reg [2:0] ALUOp, //sinal seletor da ALU
	output reg [1:0] PCSource, //sinal para MUX 11
	output reg EPCWrite, //sinal do EPC
	output reg [1:0] RegDst, //sinal do mux4
	output reg MDR_A_w, //sinal do Memory Data Register A
	output reg MDR_B_w, //sinal do Memory Data Register B
	output reg [1:0] M1_w, //sinal do mux 1 
	output reg PCWriteCond,
	output reg PCWriteCond2,
	output reg [1:0] M13_w

);


	//Variáveis
	reg [5:0] STATE;
	reg [3:0] COUNTER;

	//Estado de Fetch e Decode
	parameter ST_COMMON = 6'b000000;

	//Estados das instruções do tipo R
	parameter ST_ADD = 6'b000010;
	parameter ST_AND = 6'b000011;
	parameter ST_DIV = 6'b000100;
	parameter ST_MULT = 6'b000101;
	parameter ST_JR = 6'b000110;
	parameter ST_MFHI = 6'b000111;
	parameter ST_MFLO = 6'b001000;
	parameter ST_SLL = 6'b001001;
	parameter ST_SLLV = 6'b001010;
	parameter ST_SLT = 6'b001011;
	parameter ST_SRA = 6'b001100;
	parameter ST_SRAV = 6'b001101;
	parameter ST_SRL = 6'b001110;
	parameter ST_SUB = 6'b001111;
	parameter ST_BREAK = 6'b010000;
	parameter ST_RTE = 6'b010001;
	parameter ST_ADDM = 6'b010010;

	//Estados das instruções do tipo I
	parameter ST_ADDI = 6'b010011;
	parameter ST_ADDIU = 6'b010100;
	parameter ST_BEQ = 6'b010101;
	parameter ST_BNE = 6'b010110;
	parameter ST_BLE = 6'b010111;
	parameter ST_BGT = 6'b011000;
	parameter ST_SLLM = 6'b011001;
	parameter ST_LB = 6'b011010;
	parameter ST_LH = 6'b011011;
	parameter ST_LUI = 6'b011100;
	parameter ST_LW = 6'b011101;
	parameter ST_SB = 6'b011110;
	parameter ST_SH = 6'b011111;
	parameter ST_SLTI = 6'b100000;
	parameter ST_SW = 6'b100001;

	//Estados das instruções do tipo J
	parameter ST_J = 6'b100010;
	parameter ST_JAL = 6'b100011;

	//Estados das exceções
	parameter ST_OPCODE_EXC = 6'b100100; //Opcode inválido
	parameter ST_FUNCT_EXC = 6'b100101; //Funct inválido


	//Opcode das instruções de tipo R
	parameter TYPE_R = 6'b000000;

	//Opcodes das instruções de tipo I
	parameter ADDI = 6'b001000;
	parameter ADDIU = 6'b001001;
	parameter BEQ = 6'b000100;
	parameter BNE = 6'b000101;
	parameter BLE = 6'b000110;
	parameter BGT = 6'b000111;
	parameter SLLM = 6'b000001;
	parameter LB = 6'b100000;
	parameter LH = 6'b100001;
	parameter LUI = 6'b001111;
	parameter LW = 6'b100011;
	parameter SB = 6'b101000;
	parameter SH = 6'b101001;
	parameter SLTI = 6'b001010;
	parameter SW = 6'b101011;

	//Opcodes das instruções de tipo J
	parameter J = 6'b000010;
	parameter JAL = 6'b000011;

	//Campos funct das instruções de tipo R
	parameter F_ADD = 6'b100000;
	parameter F_AND = 6'b100100;
	parameter F_DIV = 6'b011010;
	parameter F_MULT = 6'b011000;
	parameter F_JR = 6'b001000;
	parameter F_MFHI = 6'b010000;
	parameter F_MFLO = 6'b010010;
	parameter F_SLL = 6'b000000;
	parameter F_SLLV = 6'b000100;
	parameter F_SLT = 6'b101010;
	parameter F_SRA = 6'b000011;
	parameter F_SRAV = 6'b000111;
	parameter F_SRL = 6'b000010;
	parameter F_SUB = 6'b100010;
	parameter F_BREAK = 6'b001101;
	parameter F_RTE = 6'b010011;
	parameter F_ADDM = 6'b000101;



	always @(posedge clk) begin
	  if (reset == 1'b1) begin 		
			STATE = ST_COMMON;
			IR_w = 1'b0;
			PC_w = 1'b0;
			IorD_w = 2'b00;
			M3_w = 1'b0;
			MemWrite = 1'b0;
			RegWrite = 1'b0;
			MemToReg = 3'b101; //escrever 227 no registrador 29
			LO_w = 1'b0;
			HI_w = 1'b0;
			M8_w = 1'b0;
			M9_w = 1'b0;
			RegA_w = 1'b0;
			RegB_w = 1'b0;
			M10_w = 2'b00;
			ALUSrcB = 3'b000;
			ALUSrcA = 2'b00;
			ALUOUT_w = 1'b0;
			ALUOp = 3'b000;
			PCSource = 2'b00;
			EPCWrite = 1'b0;
			RegDst = 2'b01; // escrever 227 no registrador 29
			MDR_A_w = 1'b0;
			MDR_B_w = 1'b0;
			M1_w = 2'b00;
			PCWriteCond = 1'b0;
			PCWriteCond2 = 1'b0;
			M13_w = 2'b00;
			COUNTER = 4'b0000;
	  end
	  else begin 
		 case (STATE)
			  ST_COMMON: begin 
				 if (COUNTER == 4'b0000) begin 
					STATE = ST_COMMON; 
					IR_w = 1'b1; //
					PC_w = 1'b1; //
					IorD_w = 2'b00; //
					M3_w = 1'b0;
					MemWrite = 1'b0; //
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b1;
					RegB_w = 1'b1;
					M10_w = 2'b00;
					ALUSrcB = 3'b011; //
					ALUSrcA = 2'b00; //
					ALUOUT_w = 1'b0;
					ALUOp = 3'b001;
					PCSource = 2'b00; //
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					M13_w = 2'b00;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0001 || COUNTER == 4'b0010) begin //adicionei isso 
					STATE = ST_COMMON; 
					IR_w = 1'b1; //
					PC_w = 1'b0; //
					IorD_w = 2'b00; //
					M3_w = 1'b0;
					MemWrite = 1'b0; //
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b1;
					RegB_w = 1'b1;
					M10_w = 2'b00;
					ALUSrcB = 3'b011; //
					ALUSrcA = 2'b00; //
					ALUOUT_w = 1'b0;
					ALUOp = 3'b001;
					PCSource = 2'b00; //
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					M13_w = 2'b00;
					COUNTER = COUNTER + 1;
				 end //até aqui
				 else if (COUNTER == 4'b0011) begin 
					STATE = ST_COMMON;
					IR_w = 1'b0;//
					PC_w = 1'b0;//
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					M13_w = 2'b00;
					COUNTER = COUNTER + 1;
				 end
				 
				 else if (COUNTER == 4'b0100) begin 
					case (OPCODE)
					  TYPE_R: begin
						 case (FUNCT) 
							F_ADD: begin
							  STATE = ST_ADD;
							end
							F_AND: begin
							  STATE = ST_AND;
							end
							F_DIV: begin
							  STATE = ST_DIV;
							end
							F_MULT: begin
							  STATE = ST_MULT;
							end
							F_JR: begin
							  STATE = ST_JR;
							end
							F_MFHI: begin
							  STATE = ST_MFHI;
							end
							F_MFLO: begin
							  STATE = ST_MFLO;
							end
							F_SLL: begin
							  STATE = ST_SLL;
							end
							F_SLLV: begin
							  STATE = ST_SLLV;
							end
							F_SLT: begin
							  STATE = ST_SLT;
							end
							F_SRA: begin
							  STATE = ST_SRA;
							end
							F_SRAV: begin
							  STATE = ST_SRAV;
							end
							F_SRL: begin
							  STATE = ST_SRL;
							end
							F_SUB: begin
							  STATE = ST_SUB;
							end
							F_BREAK: begin
							  STATE = ST_BREAK;
							end
							F_RTE: begin
							  STATE = ST_RTE;
							end
							F_ADDM: begin
							  STATE = ST_ADDM;
							end
							default: begin
							  STATE = ST_FUNCT_EXC;
							end
						 endcase
					  end
					  ADDI: begin
						 STATE = ST_ADDI;
					  end
					  ADDIU: begin
						 STATE = ST_ADDIU;
					  end
					  BEQ: begin
						 STATE = ST_BEQ;
					  end
					  BNE: begin
						 STATE = ST_BNE;
					  end
					  BLE: begin
						 STATE = ST_BLE;
					  end
					  BGT: begin
						 STATE = ST_BGT;
					  end
					  SLLM: begin
						 STATE = ST_SLLM;
					  end
					  LB: begin
						 STATE = ST_LB;
					  end
					  LH: begin
						 STATE = ST_LH;
					  end
					  LUI: begin
						 STATE = ST_LUI;
					  end
					  LW: begin
						 STATE = ST_LW;
					  end
					  SB: begin
						 STATE = ST_SB;
					  end
					  SH: begin
						 STATE = ST_SH;
					  end
					  SLTI: begin
						 STATE = ST_SLTI;
					  end
					  SW: begin
						 STATE = ST_SW;
					  end
					  J: begin
						 STATE = ST_J;
					  end
					  JAL: begin
						 STATE = ST_JAL;
					  end
					  default: begin
						 STATE = ST_OPCODE_EXC;
					  end
					endcase
						IR_w = 1'b0;
						PC_w = 1'b0;
						IorD_w = 2'b00; 
						M3_w = 1'b0;
						MemWrite = 1'b0;
						RegWrite = 1'b0;
						MemToReg = 3'b000;
						LO_w = 1'b0;
						HI_w = 1'b0;
						M8_w = 1'b0;
						M9_w = 1'b0;
						RegA_w = 1'b0;
						RegB_w = 1'b0;
						M10_w = 2'b00;
						ALUSrcB = 3'b111; //
						ALUSrcA = 2'b00;
						ALUOUT_w = 1'b1; //
						ALUOp = 3'b001;
						PCSource = 2'b00;
						EPCWrite = 1'b0;
						RegDst = 2'b00;
						MDR_A_w = 1'b0;
						MDR_B_w = 1'b0;
						M1_w = 2'b00;
						PCWriteCond = 1'b0;
						PCWriteCond2 = 1'b0;
						M13_w = 2'b00;
						COUNTER = 4'b0000; 
				 end
			  end
			  ST_ADD: begin 
					if (COUNTER == 4'b0000) begin
					STATE = ST_ADD;
					IR_w = 1'b0; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
               PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0001) begin
					STATE = ST_ADD;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b1;
					RegB_w = 1'b1;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00; ////
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0010) begin
					STATE = ST_ADD;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0; //
					MemToReg = 3'b000; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;
					ALUOUT_w = 1'b1;
					ALUOp = 3'b001;
					PCSource = 2'b00; //
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0; //
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0011) begin
					STATE = ST_ADD;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b010; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00; //
					EPCWrite = 1'b0;
					RegDst = 2'b11;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0; //
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;//
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end 
			  ST_AND: begin 
				 if (COUNTER == 4'b0000) begin
					STATE = ST_AND;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b1;
					RegB_w = 1'b1;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;
					ALUOUT_w = 1'b1;
					ALUOp = 3'b011;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0001) begin
					STATE = ST_AND;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1;
					MemToReg = 3'b010;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000; //
					ALUSrcA = 2'b00;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0010) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0; //
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_DIV: begin
				 
			  end
			  ST_MULT: begin
				 
			  end
			  ST_JR: begin
				 
			  end
			  ST_MFHI: begin
				 
			  end
			  ST_MFLO: begin
				 
			  end
			  ST_SLL: begin
				 if (COUNTER == 4'b0000) begin
				   STATE = ST_SLL;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b1;
					RegB_w = 1'b1;
					M10_w = 2'b01;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b11; //
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					M13_w = 2'b10;
				   COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0001) begin
				   STATE = ST_SLL;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b01; //
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b11;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					M13_w = 2'b01; ///////
					COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0010) begin
				  STATE = ST_SLL;
				  IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b011; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					M13_w = 2'b10; ////
					COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0011) begin
				  STATE = ST_COMMON;
				  IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					M13_w = 2'b00;
					COUNTER = 4'b0000;
				end
			  end
			  ST_SLLV: begin
				if (COUNTER == 4'b0000) begin
				   STATE = ST_SLLV;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10; //
					ALUOUT_w = 1'b0;
					ALUOp = 3'b011; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
				   COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0001) begin
				   STATE = ST_SLLV;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00; //
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0010) begin
				  STATE = ST_SLLV;
				  IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b011; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0011) begin
				  STATE = ST_COMMON;
				  IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				end
			  end
			  ST_SLT: begin
				 
			  end
			  ST_SRA: begin
				 if (COUNTER == 4'b0000) begin
				   STATE = ST_SRA;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10; //
					ALUOUT_w = 1'b0;
					ALUOp = 3'b011; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
				   COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0001) begin
				   STATE = ST_SRA;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b01; //
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0010) begin
				  STATE = ST_SRA;
				  IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b011; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0011) begin
				  STATE = ST_COMMON;
				  IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				end
			  end
			  ST_SRAV: begin
				 if (COUNTER == 4'b0000) begin
				   STATE = ST_SRAV;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10; //
					ALUOUT_w = 1'b0;
					ALUOp = 3'b011; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
				   COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0001) begin
				   STATE = ST_SRAV;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00; //
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0010) begin
				  STATE = ST_SRAV;
				  IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b011; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0011) begin
				  STATE = ST_COMMON;
				  IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				end
			  end
			  ST_SRL: begin
				 if (COUNTER == 4'b0000) begin
				   STATE = ST_SRL;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10; //
					ALUOUT_w = 1'b0;
					ALUOp = 3'b011; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
				   COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0001) begin
				   STATE = ST_SRL;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b01; //
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0010) begin
				  STATE = ST_SRL;
				  IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b011; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				end
				else if (COUNTER == 4'b0011) begin
				  STATE = ST_COMMON;
				  IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				end
			  end
			  ST_SUB: begin 
					if (COUNTER == 4'b0000) begin
					STATE = ST_SUB;
					IR_w = 1'b0; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b1;
					RegB_w = 1'b1;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
               PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0001) begin
					STATE = ST_SUB;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10; ////
					ALUOUT_w = 1'b1;
					ALUOp = 3'b010;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0010) begin
					STATE = ST_SUB;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b010; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00; //
					EPCWrite = 1'b0;
					RegDst = 2'b11;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0; //
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0011) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;//
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end 
			  ST_BREAK: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001) begin
					STATE = ST_BREAK;
					IR_w = 1'b0;
					PC_w = 1'b1; //
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b011; //
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b010; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0010) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0; //
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;			
				 end
			  end
			  ST_RTE: begin
				 if (COUNTER == 4'b0000) begin
					STATE = ST_RTE;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10; //
					ALUOUT_w = 1'b0;
					ALUOp = 3'b011; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0001) begin
					STATE = ST_RTE;
					IR_w = 1'b0;
					PC_w = 1'b1;//
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b11; //
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0010) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_ADDM: begin
				 
			  end
			  ST_ADDI: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_ADDI;
					IR_w = 1'b0; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b1;
					RegB_w = 1'b1;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
               PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_ADDI;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b100;
					ALUSrcA = 2'b10; ////
					ALUOUT_w = 1'b1;
					ALUOp = 3'b001;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101 || COUNTER == 4'b0110 || COUNTER == 4'b0111) begin
					STATE = ST_ADDI;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b010; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b01; //
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b1; //
					PCWriteCond2 = 1'b1;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b1000) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;//
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_ADDIU: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_ADDIU;
					IR_w = 1'b0; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b1;
					RegB_w = 1'b1;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
               PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_ADDIU;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b100;
					ALUSrcA = 2'b10; ////
					ALUOUT_w = 1'b1;
					ALUOp = 3'b001;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101 || COUNTER == 4'b0110 || COUNTER == 4'b0111) begin
					STATE = ST_ADDIU;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b010; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b01; //
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b1; //
					PCWriteCond2 = 1'b1;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b1000) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;//
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_BEQ: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_BEQ;
					IR_w = 1'b1; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_BEQ;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101) begin
					STATE = ST_BEQ;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b01;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b1;
					PCWriteCond2 = 1'b1;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0110) begin
					STATE = ST_COMMON;
					//mesmos sinais do de cima
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b01;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b1;
					PCWriteCond2 = 1'b1;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_BNE: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_BNE;
					IR_w = 1'b1; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_BNE;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101) begin
					STATE = ST_BNE;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b01;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b1;
					PCWriteCond2 = 1'b1;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0110) begin
					STATE = ST_COMMON;
					//mesmos sinais do de cima
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b01;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b1;
					PCWriteCond2 = 1'b1;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_BLE: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_BLE;
					IR_w = 1'b1; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_BLE;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101) begin
					STATE = ST_BLE;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b01;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b1;
					PCWriteCond2 = 1'b1;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0110) begin
					STATE = ST_COMMON;
					//mesmos sinais do de cima
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b01;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b1;
					PCWriteCond2 = 1'b1;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_BGT: begin 
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_BGT;
					IR_w = 1'b1; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_BGT;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101) begin
					STATE = ST_BGT;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b01;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b1;
					PCWriteCond2 = 1'b1;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0110) begin
					STATE = ST_COMMON;
					//mesmos sinais do de cima
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b01;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b1;
					PCWriteCond2 = 1'b1;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_SLLM: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
				   STATE = ST_SLLM;
				   IR_w = 1'b1; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
				   STATE = ST_SLLM;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101) begin
				   STATE = ST_SLLM;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b011; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b10; //
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0110) begin
				   STATE = ST_COMMON;
				   IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_LB: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_LB;
					IR_w = 1'b1; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_LB;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101) begin
					STATE = ST_LB;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b1;//
					RegWrite = 1'b0;
					MemToReg = 3'b010; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0110) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_LH: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_LH;
                    IR_w = 1'b1; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_LH;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101 || COUNTER == 4'b0110) begin
					STATE = ST_LH;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b01; //
					M3_w = 1'b0;
					MemWrite = 1'b0; //
					RegWrite = 1'b1; //
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0111) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; //
					M3_w = 1'b0;
					MemWrite = 1'b0; //
					RegWrite = 1'b0; //
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_LUI: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_LUI;
					IR_w = 1'b0; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0; // 
					MemToReg = 3'b111;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b1;
					RegB_w = 1'b1;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
               PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_LUI;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b111;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b100;
					ALUSrcA = 2'b10; ////
					ALUOUT_w = 1'b1;
					ALUOp = 3'b001;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101 || COUNTER == 4'b0110 || COUNTER == 4'b0111) begin
					STATE = ST_LUI;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b111; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b01; //
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b1; //
					PCWriteCond2 = 1'b1;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b1000) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;//
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_LW: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_LW;
					IR_w = 1'b1; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_LW;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101) begin
					STATE = ST_LW;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b1;//
					RegWrite = 1'b0;
					MemToReg = 3'b010; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0110) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_SB: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_SB;
					IR_w = 1'b1; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_SB;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101) begin
					STATE = ST_SB;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b01; // 
					M3_w = 1'b0;
					MemWrite = 1'b1; //
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0110) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_SH: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_SH;
					IR_w = 1'b1; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_SH;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101) begin
					STATE = ST_SH;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b01; //
					M3_w = 1'b0; //
					MemWrite = 1'b1; //
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0110) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_SLTI: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_SLTI;
					IR_w = 1'b1; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_SLTI;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101) begin
					STATE = ST_SLTI;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b010; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0110) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_SW: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_SW;
					IR_w = 1'b1; //
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10;//
					ALUOUT_w = 1'b0;
					ALUOp = 3'b100; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_SW;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101) begin
					STATE = ST_SW;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b01; // 
					M3_w = 1'b0;
					MemWrite = 1'b1; //
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0110) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_J: begin 
				 if (COUNTER == 4'b0000) begin
					STATE = ST_J;
					IR_w = 1'b0;
					PC_w = 1'b1; //
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b10; //
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0001) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0; //
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_JAL: begin 
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_JAL;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; // 
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b1; //
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b10; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
               		PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_JAL;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b010; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b10; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0101 || COUNTER == 4'b0110 || COUNTER == 4'b0111) begin
					STATE = ST_JAL;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b010; //
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b10; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b1000) begin
					STATE = ST_JAL;
					IR_w = 1'b0;
					PC_w = 1'b1; //
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b10; //
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b1001) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_FUNCT_EXC: begin
				 if (COUNTER == 4'b0000) begin
					STATE = ST_FUNCT_EXC;
                    IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b10; //
					ALUOUT_w = 1'b0;
					ALUOp = 3'b011; //
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0001) begin
					STATE = ST_FUNCT_EXC;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b1; //
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b11; //
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0010 || COUNTER == 4'b0011 || COUNTER == 4'b0100 || COUNTER == 4'b0101) begin
					STATE = ST_FUNCT_EXC;
					IR_w = 1'b0;
					PC_w = 1'b1; //
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b011; //
					ALUSrcA = 2'b10; //
					ALUOUT_w = 1'b0;
					ALUOp = 3'b001; //
					PCSource = 2'b11; //
					EPCWrite = 1'b1; //
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
                    //colocar sinais IntCause e CauseWrite!!!
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0110) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
			  ST_OPCODE_EXC: begin
				 if (COUNTER == 4'b0000 || COUNTER == 4'b0001 || COUNTER == 4'b0010 || COUNTER == 4'b0011) begin
					STATE = ST_OPCODE_EXC;
                    IR_w = 1'b0;
					PC_w = 1'b1; //
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b011; //
					ALUSrcA = 2'b10; //
					ALUOUT_w = 1'b0;
					ALUOp = 3'b001; //
					PCSource = 2'b11; //
					EPCWrite = 1'b1; //
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
                    //colocar o IntCause e CauseWrite
					COUNTER = COUNTER + 1;
				 end
				 else if (COUNTER == 4'b0100) begin
					STATE = ST_COMMON;
					IR_w = 1'b0;
					PC_w = 1'b0;
					IorD_w = 2'b00; 
					M3_w = 1'b0;
					MemWrite = 1'b0;
					RegWrite = 1'b0;
					MemToReg = 3'b000;
					LO_w = 1'b0;
					HI_w = 1'b0;
					M8_w = 1'b0;
					M9_w = 1'b0;
					RegA_w = 1'b0;
					RegB_w = 1'b0;
					M10_w = 2'b00;
					ALUSrcB = 3'b000;
					ALUSrcA = 2'b00;
					ALUOUT_w = 1'b0;
					ALUOp = 3'b000;
					PCSource = 2'b00;
					EPCWrite = 1'b0;
					RegDst = 2'b00;
					MDR_A_w = 1'b0;
					MDR_B_w = 1'b0;
					M1_w = 2'b00;
					PCWriteCond = 1'b0;
					PCWriteCond2 = 1'b0;
					COUNTER = 4'b0000;
				 end
			  end
		 endcase
	  end
	end


endmodule 