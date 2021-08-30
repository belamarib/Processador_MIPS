module MUX_2(
	input wire [1:0] seletor,
	input wire [31:0] Data_0, // valor de PC 00
	input wire [31:0] Data_1, // ALUOut 01
	input wire [31:0] Data_2, // ALUResult 10
	input wire [31:0] Data_3, // overflow 11
	output wire [31:0] Data_out 
);
	wire [31:0] A1;
	wire [31:0] A2;
	
	assign A1 = (seletor[0]) ? Data_1 : Data_0;
	assign A2 = (seletor[0]) ? Data_3 : Data_2;
	assign Data_out = (seletor[1]) ? A2 : A1;

endmodule 