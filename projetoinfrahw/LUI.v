module LUI (
	input wire[15:0] Data_in,
	output wire[31:0] Data_out
);

	assign Data_out = {Data_in, 16'd0};

endmodule 
