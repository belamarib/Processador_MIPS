module MUX_13(
	input wire [1:0] selector,
	//000 -> 00
	//001 -> 01
	input wire [2:0] Data_0, // 10
	output wire [2:0] Data_out
);

	assign Data_out = (selector[0]) ? 3'b001: ((selector[1]) ? Data_out : 3'b000) ;

endmodule 