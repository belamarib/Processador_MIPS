module ShiftLeft2A (
	input wire [15:0] Data_in, //OFFSET
	input wire [31:0] Data_PC, //fio do PC
	output wire [31:0] Data_out
);

	wire [15:0] A1;
	wire [27:0] A2;

	assign A1 = {Data_in[13:0], 2'b00};
	assign A2 = {12'b000000000000, A1};
	assign Data_out = {Data_PC[31:28], A2};

	
endmodule 