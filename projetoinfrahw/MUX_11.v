module MUX_11(
    input wire [1:0] selector,
    input wire [31:0] Data_0, //pega PC + 4
    input wire [31:0] Data_1, //pega endereço do ALUOut
    input wire [31:0] Data_2, //pega endereço do jump
    input wire [31:0] Data_3, //pega endereço de EPC
    output wire [31:0] Data_out
);

wire [31:0] A1;
wire [31:0] A2;

assign A2 = (selector[0]) ? Data_1 : Data_0;
assign A1 = (selector[0]) ? Data_3 : Data_2;
assign Data_out = (selector[1]) ? A1 : A2;


endmodule 