module MUX_1 (
	input wire [1:0] seletor, //sinal
	output wire [31:0] Data_out
);

	wire [31:0] A1;
	
	assign A1 = (seletor[0]) ? 32'd254 : 32'd253;
	assign Data_out = (seletor[1]) ? 32'd255 : A1;



endmodule 