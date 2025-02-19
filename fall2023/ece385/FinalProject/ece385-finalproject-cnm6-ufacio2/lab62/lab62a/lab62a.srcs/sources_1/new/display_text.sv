module display_text (
    input logic [9:0] DrawX, DrawY,
    output logic pixel_on 
);

parameter [7:0] text[4:0] = {8'H48, 8'H45, 8'H4C, 8'H4C, 8'H4F}; // ASCII for "HELLO"

logic [10:0] sprite_addr;
logic [7:0] sprite_data;
logic [3:0] index;

font_rom ROM (.addr(sprite_addr), .data(sprite_data));

always_comb begin
        sprite_addr = (16 * text[DrawX / 8]) + DrawY[3:0]; 
        index = 7 - DrawX[2:0];
        pixel_on = sprite_data[index];
end

endmodule