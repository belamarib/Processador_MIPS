module Load_Size(
	input wire [31:0] Data_in,
	output wire [31:0] Data_out

);

	assign Data_out = {16'b000000000000000, Data_in[15:0]};



endmodule 