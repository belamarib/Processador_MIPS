module Store_Size (
	input wire [31:0] Data_0, //mdr
	input wire [31:0] Data_1, //b
	output wire [31:0] Data_out
);

	assign Data_out = {Data_0[31:16], Data_1[15:0]};

endmodule 