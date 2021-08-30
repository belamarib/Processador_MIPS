module MUX_7(
	input	wire [2:0] selector,
	input	wire [31:0] Data_0, //saída de B 000
	input 	wire [31:0] Data_1, //saída de shift left 001
	input	wire [31:0] Data_2, //saída de MDR 010
	//numero 4 011
	input	wire [31:0] Data_3, //saída de signextend 100
	output	wire [31:0] Data_Out
);
	wire [31:0] A1;
	wire [31:0] A2;
	wire [31:0] A3;

	assign A1 = (selector[0]) ? Data_1 : Data_0; //x0x
	assign A2 = (selector[0]) ? 32'd4 : Data_2; //x1x
	
	

	assign A3 = (selector[1]) ? A2 : A1; //0xx

	assign Data_Out = (selector[2]) ? Data_3 : A3;


endmodule