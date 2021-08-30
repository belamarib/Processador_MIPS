module MUX_3(
    input wire selector,
    input wire [31:0] Data_0, // 0 vem do registrador B
    input wire [31:0] Data_1, // 1 vem do StoreSize
    output wire [31:0] Data_out
);

assign Data_out = (selector) ? Data_1 : Data_0;

endmodule 