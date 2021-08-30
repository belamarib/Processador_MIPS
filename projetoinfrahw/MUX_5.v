module MUX_5 (
	input wire [2:0] selector,
	input wire [31:0] Data_0, //loadsize 000
	input wire [31:0] Data_1, //LO 001 
	input wire [31:0] Data_2, //ALUOUT 010
	input wire [31:0] Data_3, //Reg de Deslocamento; 011
	input wire [31:0] Data_4, //HI 100
	//227									 101
	//243  								 110
	input wire [31:0] Data_5, //111
	output wire [31:0] Data_out
);
	
	wire [31:0] A1;
	wire [31:0] A2;
	wire [31:0] A3;
	wire [31:0] A4;
	wire [31:0] A5;
	wire [31:0] A6;
	

	assign A1 = (selector[0]) ? Data_1 : Data_0; //se ultimo bit de selector for 1, A1 <- Data_1
	assign A2 = (selector[0]) ? Data_3 : Data_2;
	
	assign A3 = (selector[0]) ? 32'd227 : Data_4;
	assign A4 = (selector[0]) ? Data_5 : 32'd243;
	
	assign A5 = (selector[1]) ? A2 : A1;
	assign A6 = (selector[1]) ? A4 : A3;
	
	assign Data_out = (selector[2]) ? A6 : A5;

endmodule 