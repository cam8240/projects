module text_display ( 
        input logic [9:0] DrawX, DrawY,
        input logic Wait_Before_Level1, Wait_Before_Level2, Wait_Before_Level3, game_final,
        output logic pixel_on,
        input logic Init1_Active, Init2_Active
        );

logic [10:0] sprite_addr;
logic [7:0] sprite_data;
logic [3:0] index;

font_rom ROM (.addr(sprite_addr), .data(sprite_data));
//Init1_Active & Init2_Active
// ASCII values for "WORLD'S HARDEST GAME"
localparam [7:0] line1_text0[19:0] = {
    8'h45, 8'h4D, 8'h41, 8'h47, 8'h20, 8'h54, 
    8'h53, 8'h45, 8'h44, 8'h52, 8'h41, 8'h48, 8'h20, // "EMAG TSEDRAH "
    8'h53, 8'h27, 8'h44, 8'h4C, 8'h52, 8'h4F, 8'h57 // "S'DLROW"
};

// ASCII values for "(PRESS ANY KEY TO CONTINUE)"
localparam [7:0] line2_text0[26:0] = {
    8'h29, 8'h45, 8'h55, 8'h4E, 8'h49, 
    8'h54, 8'h4E, 8'h4F, 8'h43, 8'h20, 
    8'h4F, 8'h54, 8'h20, 8'h59, 8'h45, 
    8'h4B, 8'h20, 8'h59, 8'h4E, 8'h41, 
    8'h20, 8'h53, 8'h53, 8'h45, 8'h52, 
    8'h50, 8'h28 // "(EUNITNOC OT YEK YNA SSERP)"
};


localparam start_line1_x0 = 240;
localparam start_line1_y0 = 224;
localparam start_line2_x0 = 212;
localparam start_line2_y0 = 224;

localparam char_line1_length0 = 20;
localparam char_line2_length0 = 27;

//Level 1
// ASCII values for "YOU DON'T KNOW WHAT"
localparam [7:0] line1_text1[18:0] = {
    8'h54, 8'h41, 8'h48, 8'h57, 8'h20, // "TAHW "
    8'h57, 8'h4F, 8'h4E, 8'h4B, 8'h20, // "WONK "
    8'h54, 8'h27, 8'h4E, 8'h4F, 8'h44, 8'h20, // "T'NOD "
    8'h55, 8'h4F, 8'h59 // "UOY"
};
// ASCII values for "YOU'RE GETTING INTO."
localparam [7:0] line2_text1[19:0] = {
    8'h2E, 8'h4F, 8'h54, 8'h4E, 8'h49, 8'h20, // ".OTNI "
    8'h47, 8'h4E, 8'h49, 8'h54, 8'h54, 8'h45, 8'h47, 8'h20, // "GNITTEG "
    8'h45, 8'h52, 8'h27, 8'h55, 8'h4F, 8'h59 // "ER'UOY"
};


localparam start_line1_x1 = 244;
localparam start_line1_y1 = 224;
localparam start_line2_x1 = 244;
localparam start_line2_y1 = 224;

localparam char_line1_length1 = 19;
localparam char_line2_length1 = 20;

//Level 2
// ASCII values for "DON'T EVEN BOTHER"
localparam [7:0] line1_text2[16:0] = {
    8'h52, 8'h45, 8'h48, 8'h54, 8'h4F, 8'h42, 8'h20, // "REHTOB "
    8'h4E, 8'h45, 8'h56, 8'h45, 8'h20, // "NEVE "
    8'h54, 8'h27, 8'h4E, 8'h4F, 8'h44 // "T'NOD"
};

// ASCII values for "TRYING."
localparam [7:0] line2_text2[6:0] = {
    8'h2E, 8'h47, 8'h4E, 8'h49, 8'h59, 8'h52, 8'h54 // ".GNIRYT"
};

localparam start_line1_x2 = 252;
localparam start_line1_y2 = 224;
localparam start_line2_x2 = 296;
localparam start_line2_y2 = 224;

localparam char_line1_length2 = 17;
localparam char_line2_length2 = 7;

//Level 3
// ASCII values for "I CAN ALMOST"
localparam [7:0] line1_text3[11:0] = {
    8'h54, 8'h53, 8'h4F, 8'h4D, 8'h4C, 8'h41, // "TSOMLA"
    8'h20, 8'h4E, 8'h41, 8'h43, 8'h20, 8'h49  // " NAC I"
};

// ASCII values for "GUARANTEE YOU WILL"
localparam [7:0] line2_text3[17:0] = {
    8'h4C, 8'h4C, 8'h49, 8'h57, 8'h20, // "LLIW "
    8'h55, 8'h4F, 8'h59, 8'h20,        // "UOY "
    8'h45, 8'h45, 8'h54, 8'h4E, 8'h41, 8'h52, 8'h41, 8'h55, 8'h47 // "EETNARAUG"
};

// ASCII values for "FAIL."
localparam [7:0] line3_text3[4:0] = {
    8'h2E, 8'h4C, 8'h49, 8'h41, 8'h46 // ".LIAF"
};

localparam start_line1_x3 = 272;
localparam start_line1_y3 = 208;
localparam start_line2_x3 = 248;
localparam start_line2_y3 = 208;
localparam start_line3_x3 = 304;
localparam start_line3_y3 = 208;

localparam char_line1_length3 = 12;
localparam char_line2_length3 = 18;
localparam char_line3_length3 = 5;

//Level Game Over
// ASCII values for "YOU WIN!"
localparam [7:0] line1_text4[7:0] = {
    8'h21, 8'h4E, 8'h49, 8'h57, 8'h20, 8'h55, 8'h4F, 8'h59 // "!NIW UOY"
};

localparam start_line1_x4 = 288;
localparam start_line1_y4 = 224;

localparam char_line1_length4 = 8;

always_comb begin
    if (Init1_Active) begin
        if (DrawX >= start_line1_x0 && DrawX < start_line1_x0 + 8 * char_line1_length0 && DrawY >= start_line1_y0 && DrawY < start_line1_y0 + 16) begin
            sprite_addr = (16 * line1_text0[(DrawX - start_line1_x0) / 8]) + DrawY[3:0];
            index = 7 - (DrawX - start_line1_x0) % 8;
            pixel_on = sprite_data[index];
        end else begin
            pixel_on = 1'b0;
        end   
    end else if (Init2_Active) begin
        if (DrawX >= start_line1_x0 && DrawX < start_line1_x0 + 8 * char_line1_length0 && DrawY >= start_line1_y0 && DrawY < start_line1_y0 + 16) begin
            sprite_addr = (16 * line1_text0[(DrawX - start_line1_x0) / 8]) + DrawY[3:0];
            index = 7 - (DrawX - start_line1_x0) % 8;
            pixel_on = sprite_data[index];
        end else if (DrawX >= start_line2_x0 && DrawX < start_line2_x0 + 8 * char_line2_length0 && DrawY >= start_line2_y0 + 64 && DrawY < start_line2_y0 + 80) begin
            sprite_addr = (16 * line2_text0[(DrawX - start_line2_x0) / 8]) + DrawY[3:0];
            index = 7 - (DrawX - start_line2_x0) % 8;
            pixel_on = sprite_data[index];
        end else begin
            pixel_on = 1'b0;
        end
    end else if (Wait_Before_Level1) begin
        if (DrawX >= start_line1_x1 && DrawX < start_line1_x1 + 8 * char_line1_length1 && DrawY >= start_line1_y1 && DrawY < start_line1_y1 + 16) begin
            sprite_addr = (16 * line1_text1[(DrawX - start_line1_x1) / 8]) + DrawY[3:0];
            index = 7 - (DrawX - start_line1_x1) % 8;
            pixel_on = sprite_data[index];
        end else if (DrawX >= start_line2_x1 && DrawX < start_line2_x1 + 8 * char_line2_length1 && DrawY >= start_line2_y1 + 16 && DrawY < start_line2_y1 + 32) begin
            sprite_addr = (16 * line2_text1[(DrawX - start_line2_x1) / 8]) + DrawY[3:0];
            index = 7 - (DrawX - start_line2_x1) % 8;
            pixel_on = sprite_data[index];
        end else begin
            pixel_on = 1'b0;
        end
    end else if (Wait_Before_Level2) begin
        if (DrawX >= start_line1_x2 && DrawX < start_line1_x2 + 8 * char_line1_length2 && DrawY >= start_line1_y2 && DrawY < start_line1_y2 + 16) begin
            sprite_addr = (16 * line1_text2[(DrawX - start_line1_x2) / 8]) + DrawY[3:0];
            index = 7 - (DrawX - start_line1_x2) % 8;
            pixel_on = sprite_data[index];
        end else if (DrawX >= start_line2_x2 && DrawX < start_line2_x2 + 8 * char_line2_length2 && DrawY >= start_line2_y2 + 16 && DrawY < start_line2_y2 + 32) begin
            sprite_addr = (16 * line2_text2[(DrawX - start_line2_x2) / 8]) + DrawY[3:0];
            index = 7 - (DrawX - start_line2_x2) % 8;
            pixel_on = sprite_data[index];
        end else begin
            pixel_on = 1'b0;
        end
    end else if (Wait_Before_Level3) begin
        if (DrawX >= start_line1_x3 && DrawX < start_line1_x3 + 8 * char_line1_length3 && DrawY >= start_line1_y3 && DrawY < start_line1_y3 + 16) begin
            sprite_addr = (16 * line1_text3[(DrawX - start_line1_x3) / 8]) + DrawY[3:0];
            index = 7 - (DrawX - start_line1_x3) % 8;
            pixel_on = sprite_data[index];
        end else if (DrawX >= start_line2_x3 && DrawX < start_line2_x3 + 8 * char_line2_length3 && DrawY >= start_line2_y3 + 16 && DrawY < start_line2_y3 + 32) begin
            sprite_addr = (16 * line2_text3[(DrawX - start_line2_x3) / 8]) + DrawY[3:0];
            index = 7 - (DrawX - start_line2_x3) % 8;
            pixel_on = sprite_data[index];
        end else if (DrawX >= start_line3_x3 && DrawX < start_line3_x3 + 8 * char_line3_length3 && DrawY >= start_line3_y3 + 32 && DrawY < start_line3_y3 + 48) begin
            sprite_addr = (16 * line3_text3[(DrawX - start_line3_x3) / 8]) + DrawY[3:0];
            index = 7 - (DrawX - start_line3_x3) % 8;
            pixel_on = sprite_data[index];
        end else begin
            pixel_on = 1'b0;
        end
    end else if (game_final) begin
        if (DrawX >= start_line1_x4 && DrawX < start_line1_x4 + 8 * char_line1_length4 && DrawY >= start_line1_y4 && DrawY < start_line1_y4 + 16) begin
            sprite_addr = (16 * line1_text4[(DrawX - start_line1_x4) / 8]) + DrawY[3:0];
            index = 7 - (DrawX - start_line1_x4) % 8;
            pixel_on = sprite_data[index];
        end else begin
            pixel_on = 1'b0;
        end
    end else begin
        pixel_on = 1'b0;    
    end
end
endmodule