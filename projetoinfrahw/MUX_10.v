module MUX_10(
	input wire [1:0] selector,
	input wire [4:0] Data_0, //registrador B 0
	input wire [4:0] Data_1, //registrador rd 1
	input wire [4:0] Data_2, //memoria
	output wire [4:0] Data_Out
);
	
	wire [4:0] A1;
	
	assign A1 = (selector[0]) ? Data_1 : Data_0;
	assign Data_Out = (selector[1]) ? Data_2 : A1;


endmodule 