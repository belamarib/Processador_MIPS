module MUX_4 (
	input wire [1:0] seletor,
	input wire [4:0] Data_0,
	//29 em binario
	//31 em binario
	input wire [4:0] Data_1,
	output wire [4:0] Data_out
);
	
	wire [4:0] A1;
	wire [4:0] A2;
	
	assign A1 = (seletor[0]) ? 5'b11101 : Data_0;
	assign A2 = (seletor[0]) ? Data_1 : 5'b11111;
	assign Data_out = (seletor[1]) ? A2 : A1;


endmodule 