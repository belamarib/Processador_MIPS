module FunctToShift (
	input wire [5:0] Data_0,
	output wire [2:0] Data_out
);

//000 faz nada
//001 load no registrador: deve ser um sinal de controle
//010 shift a esquerda n vezes sll -> 0000 00
													//  01
//011 shift a direita logico n vezes srl -> 0000 10
//100 shift a direita aritmetico n vezes sra -> 0000 11
//101 rotação a direita n vezes -> n tem na especificação
//110 rotação a esquerda n vezes -> n tem na especificação

// sllv	000100 
// sll 	000000 
// srl	000010 
// sra	000011 ok
// srav	000111 ok
// sllm (opcode)

	assign Data_out = (Data_0[0]) ? 3'b100 : (Data_0[1] ? 3'b011 : 3'b010);
	

endmodule 