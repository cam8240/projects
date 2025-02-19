module game_logic #(
    parameter [6:0] Enemies = 29
    )(
    input logic Reset, frame_clk,
    input logic [2:0] Level_Active,
    output logic [9:0] circleX[Enemies], circleY[Enemies], circleS[Enemies],
    output logic enable[Enemies]
    );
    logic [9:0] circle_x_min, circle_x_max, circle_y_min, circle_y_max;
    logic [9:0] circle_center_pointx, circle_center_pointy, circular_radius;
    logic [9:0] start_x[Enemies], start_y[Enemies];
    logic [1:0] movement, direction[Enemies];
    logic reset_c;

// Set variables needed to instatiate enemies based on level
always_comb begin
    reset_c = 1'b1;
    enable = '{ default : 0};
    direction = '{ default : 2'b01};
    circle_x_min = 0;
    circle_x_max = 639;
    circle_y_min = 0;
    circle_y_max = 479;
    circle_center_pointx = 320;
    circle_center_pointy = 240;
    circular_radius = 30;
    start_x = {225, 415, 225, 415, 205, 225, 245, 265, 285, 305, 325, 345, 365, 385, 405, 425, 310, 330, 350, 350, 350, 350, 330, 310, 290, 290, 290};
    start_y = {270, 250, 230, 210, 185, 295, 185, 295, 185, 295, 185, 295, 185, 295, 185, 295, 210, 210, 210, 230, 250, 270, 270, 270, 270, 250, 230};
    unique case(Level_Active)
        3'b001: begin
            for (int i = 0; i < 4; i++) begin
                enable[i] = 1'b1;
            end
            movement = 2'b00;
            direction[1] = '0;
            direction[3] = '0;
            circle_x_min = 225;
            circle_x_max = 415;
            reset_c = 0;
        end
        3'b010: begin
            for (int i = 4; i < 16; i++) begin
                enable[i] = 1'b1;
                direction[i] = (i%2) ? 2'b10 : 2'b11;
            end
            movement = 2'b01;
            circle_y_min = 185;
            circle_y_max = 295;
            circle_x_min = 0;
            circle_x_max = 639;
            reset_c = 0;
        end
        3'b100: begin
            for (int i = 16; i < 27; i++) begin
                enable[i] = 1'b1;
            end
            direction[16] = 2'b01;
            direction[17] = 2'b01;
            direction[18] = 2'b11;
            direction[19] = 2'b11;
            direction[20] = 2'b11;
            direction[21] = 2'b00;
            direction[22] = 2'b00;
            direction[23] = 2'b00;
            direction[24] = 2'b10;
            direction[25] = 2'b10;
            direction[26] = 2'b10;
            movement = 2'b10;
            circle_y_min = 210;
            circle_y_max = 270;
            circle_x_min = 290;
            circle_x_max = 350;
            reset_c = 0;
        end
        default: begin
            for (int i = 0; i < Enemies; i++) begin
                enable[i] = 1'b0;
            end
            reset_c = 1'b1;
        end
    endcase
end

blue_circle blueinstance[Enemies-1:0](
    (Reset || reset_c),
    frame_clk,
    circle_x_min,
    circle_x_max,
    circle_y_min,
    circle_y_max,
    circle_center_pointx,
    circle_center_pointy,
    circular_radius,
    start_x,
    start_y,
    movement,
    direction,
    circleX,
    circleY,
    circleS
    );
endmodule