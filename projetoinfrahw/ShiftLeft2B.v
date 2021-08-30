module ShiftLeft2B (
	input wire [31:0] Data_0,
	output wire [31:0] Data_out
);
	
	assign Data_out = Data_0 << 2;


endmodule 