//-------------------------------------------------------------------------
//    Color_Mapper.sv                                                    --
//    Stephen Kempf                                                      --
//    3-1-06                                                             --
//                                                                       --
//    Modified by David Kesler  07-16-2008                               --
//    Translated by Joe Meng    07-07-2013                               --
//    Modified by Zuofu Cheng   08-19-2023                               --
//                                                                       --
//    Fall 2023 Distribution                                             --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------

module color_mapper #(
    parameter [6:0] Enemies = 16
    )(
    input logic [9:0] CircleX[Enemies], CircleY[Enemies], CircleS[Enemies],
    input  logic [9:0] BallX, BallY, DrawX, DrawY, Ball_size,
    output logic [3:0]  Red, Green, Blue,
    output logic Ball_At_Border_Top, Ball_At_Border_Bottom, Ball_At_Border_Left, Ball_At_Border_Right,
    output logic Level1_End, Level2_End, Level3_End, 
    input logic Level1_Active, Level2_Active, Level3_Active, game_final, pixel_on,
    output logic CoinCollected_Level2, CoinCollected_Level3,
    input logic Wait_Before_Level1, Wait_Before_Level2, Wait_Before_Level3,
    input logic Init1_Active, Init2_Active, Enable[Enemies],
    input logic [9:0] CoinX, CoinY, CoinS,
    input logic reset_coin
);

    logic ball_on, circle_on, coin_on, coin_visible;
    logic border_on, circle_border_on, coin_border_on;
    logic on_tile, off_tile, map_on, green_on, map_border;

    localparam GAME_BOARD_BORDER = 1;
    localparam BORDER_SIZE = 1;
    localparam center_x = 320;
    localparam center_y = 240;
    
    localparam [9:0] Ball_X_Center=320;  // Center position on the X axis
    localparam [9:0] Ball_Y_Center=240;  // Center position on the Y axis

    int DistX, DistY, Size;
    assign DistX = DrawX - BallX;
    assign DistY = DrawY - BallY;
    assign Size = Ball_size;

    int tile_size = 20;
    int tile_x_index = DrawX / tile_size;
    int tile_y_index = DrawY / tile_size;

    int Circle_DistX [Enemies], Circle_DistY [Enemies], Circle_Size [Enemies];
    always_comb begin
        for(int i = 0; i < Enemies; i++) begin
            Circle_DistX[i] = DrawX - CircleX[i];
            Circle_DistY[i] = DrawY - CircleY[i];
            Circle_Size[i] = CircleS[i];
        end
    end
    
    int Coin_DistX, Coin_DistY, Coin_Size;
    assign Coin_DistX = DrawX - CoinX;
    assign Coin_DistY = DrawY - CoinY;
    assign Coin_Size = CoinS;
    
always_comb begin: Coin_on_proc
    coin_on = 1'b0;
    coin_border_on = 1'b0;
    if(Level2_Active || Level3_Active) begin
        if(coin_visible) begin
            if (((Coin_DistX * Coin_DistX) + (Coin_DistY * Coin_DistY) <= (Coin_Size * Coin_Size))) begin
                coin_on = 1'b1;
            end
            if (((Coin_DistX * Coin_DistX) + (Coin_DistY * Coin_DistY) > Coin_Size * Coin_Size && (Coin_DistX * Coin_DistX) + (Coin_DistY * Coin_DistY) <= (Coin_Size + BORDER_SIZE) * (Coin_Size + BORDER_SIZE + 2))) begin
                coin_border_on = 1'b1;
            end
        end
    end
end

always_comb begin: Circle_on_proc
    circle_on = 1'b0;
    circle_border_on = 1'b0;
    if(Level1_Active) begin
        for (int i = 0; i < 4; i++) begin
            if (((Circle_DistX[i] * Circle_DistX[i]) + (Circle_DistY[i] * Circle_DistY[i]) <= Circle_Size[i] * Circle_Size[i]) && Enable[i]) begin
                circle_on = 1'b1;
            end

            if (((Circle_DistX[i] * Circle_DistX[i]) + (Circle_DistY[i] * Circle_DistY[i]) > Circle_Size[i] * Circle_Size[i] && (Circle_DistX[i] * Circle_DistX[i]) + (Circle_DistY[i] * Circle_DistY[i]) <= (Circle_Size[i] + BORDER_SIZE) * (Circle_Size[i] + BORDER_SIZE + 2)) && Enable[i]) begin
                circle_border_on = 1'b1;
            end
        end
    end
    else if(Level2_Active) begin
        for (int i = 4; i < 16; i++) begin
            if (((Circle_DistX[i] * Circle_DistX[i]) + (Circle_DistY[i] * Circle_DistY[i]) <= Circle_Size[i] * Circle_Size[i]) && Enable[i]) begin
                circle_on = 1'b1;
            end

            if (((Circle_DistX[i] * Circle_DistX[i]) + (Circle_DistY[i] * Circle_DistY[i]) > Circle_Size[i] * Circle_Size[i] && (Circle_DistX[i] * Circle_DistX[i]) + (Circle_DistY[i] * Circle_DistY[i]) <= (Circle_Size[i] + BORDER_SIZE) * (Circle_Size[i] + BORDER_SIZE + 2)) && Enable[i]) begin
                circle_border_on = 1'b1;
            end
        end
    end
    else if(Level3_Active) begin
        for (int i = 16; i < 27; i++) begin
            if (((Circle_DistX[i] * Circle_DistX[i]) + (Circle_DistY[i] * Circle_DistY[i]) <= Circle_Size[i] * Circle_Size[i]) && Enable[i]) begin
                circle_on = 1'b1;
            end

            if (((Circle_DistX[i] * Circle_DistX[i]) + (Circle_DistY[i] * Circle_DistY[i]) > Circle_Size[i] * Circle_Size[i] && (Circle_DistX[i] * Circle_DistX[i]) + (Circle_DistY[i] * Circle_DistY[i]) <= (Circle_Size[i] + BORDER_SIZE) * (Circle_Size[i] + BORDER_SIZE + 2)) && Enable[i]) begin
                circle_border_on = 1'b1;
            end
        end
    end
end

always_comb begin: Ball_on_proc
        // Check if within the square that defines the ball (including border)
    if(Level1_Active || Level2_Active || Level3_Active) begin 
        if ((DistX <= Size) && (DistX >= -Size) && (DistY <= Size) && (DistY >= -Size)) begin
            ball_on = 1'b1;

            if ((DistX >= Size - BORDER_SIZE) || (DistX <= -Size + BORDER_SIZE) ||
                (DistY >= Size - BORDER_SIZE) || (DistY <= -Size + BORDER_SIZE)) begin
                border_on = 1'b1;
            end else begin
                border_on = 1'b0;
            end
        end
        else begin
            ball_on = 1'b0;
            border_on = 1'b0;
        end
    end else begin
        ball_on = 1'b0;
        border_on = 1'b0;
    end
end

always_comb begin
    on_tile = ((tile_x_index + tile_y_index) % 2) == 0;
    off_tile = ((tile_x_index + tile_y_index) % 2) == 1;
    map_on = 1'b0;
    green_on = 1'b0;
    map_border = 1'b0;
    if(Level1_Active) begin
        // Green start point
        if((DrawX >= center_x - tile_size*9) && 
            (DrawX < center_x - tile_size*6) && 
            (DrawY >= center_y - tile_size*3) && 
            (DrawY <= center_y + tile_size*3)) 
        begin
            map_on = 1'b1;
            green_on = 1'b1;
        end
        // Small rectangle right of start
        else if((DrawX >= center_x - tile_size*6) && 
                (DrawX <= center_x - tile_size*4)&& 
                (DrawY >= center_y + tile_size*2) && 
                (DrawY < center_y + tile_size*3))
        begin
            map_on = 1'b1;
        end
        // Big central area
        else if((DrawX >= center_x - tile_size*5) && 
                (DrawX <= center_x + tile_size*5)&& 
                (DrawY >= center_y - tile_size*2) && 
                (DrawY <= center_y + tile_size*2))
        begin
            map_on = 1'b1;
        end
        // Small rectangle left of end
        else if((DrawX >= center_x + tile_size*4) && 
                (DrawX < center_x + tile_size*6)&& 
                (DrawY >= center_y - tile_size*3) && 
                (DrawY <= center_y - tile_size*2))
        begin
            map_on = 1'b1;
        end
        // Green end point
        else if((DrawX >= center_x + tile_size*6) && 
        (DrawX <= center_x + tile_size*9)&& 
        (DrawY >= center_y - tile_size*3) && 
        (DrawY <= center_y + tile_size*3)) 
       begin
            map_on = 1'b1;
            green_on = 1'b1;
       end
    
        // Logic for drawing the border around the left green box
        if ((DrawX >= center_x - tile_size * 9 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x - tile_size * 6 + GAME_BOARD_BORDER) &&
            (DrawY >= center_y - tile_size * 3 - GAME_BOARD_BORDER) &&
            (DrawY <= center_y + tile_size * 3 + GAME_BOARD_BORDER))
        begin
            if ((DrawX <= center_x - tile_size * 9) || // Left border
                (DrawY <= center_y - tile_size * 3) || // Top border
                (DrawY >= center_y + tile_size * 3))   // Bottom border
            begin
                map_border = 1'b1;
            end
            else if ((DrawX >= center_x - tile_size * 6) &&
                     (DrawY <= (center_y + tile_size * 3 - tile_size))) //Right border with opening
            begin
                map_border = 1'b1;
            end
        end
    
        // Logic for drawing the border around the right green box
        if ((DrawX >= center_x + tile_size * 6 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x + tile_size * 9 + GAME_BOARD_BORDER) &&
            (DrawY >= center_y - tile_size * 3 - GAME_BOARD_BORDER) &&
            (DrawY <= center_y + tile_size * 3 + GAME_BOARD_BORDER))
        begin
            if ((DrawY <= center_y - tile_size * 3) || // Top border
                (DrawY >= center_y + tile_size * 3) ||   //Right border
                (DrawX >= center_x + tile_size * 9))   // Bottom border
            begin
                map_border = 1'b1;
            end
            else if ((DrawX <= center_x + tile_size * 6) &&
                    (DrawY >= (center_y - tile_size * 3 + tile_size))) // Left border with opening
            begin
                map_border = 1'b1;
            end
        end
    
        // Top-right vertical
        if ((DrawX >= center_x + tile_size * 4 - GAME_BOARD_BORDER) && 
            (DrawX <= center_x + tile_size * 4) &&
            (DrawY >= center_y - tile_size * 3 - GAME_BOARD_BORDER) && 
            (DrawY <= center_y - tile_size * 2))
        begin
            map_border = 1'b1;
        end
    
        // Bottom-left horizontal
        if ((DrawX >= center_x - tile_size * 6) && 
            (DrawX <= center_x - tile_size * 5) &&
            (DrawY >= center_y + tile_size * 2 - GAME_BOARD_BORDER) && 
            (DrawY <= center_y + tile_size * 2))
        begin
            map_border = 1'b1;
        end
    
        // Bottom-left vertical
        if ((DrawX >= center_x - tile_size * 4) && 
            (DrawX <= center_x - tile_size * 4 + GAME_BOARD_BORDER) &&
            (DrawY >= center_y + tile_size * 2) && 
            (DrawY <= center_y + tile_size * 3  + GAME_BOARD_BORDER))
        begin
            map_border = 1'b1;
        end
    
        // Top-right horizontal
        if ((DrawX >= center_x + tile_size * 5) && 
            (DrawX <= center_x + tile_size * 6) &&
            (DrawY >= center_y - tile_size * 2) && 
            (DrawY <= center_y - tile_size * 2 + GAME_BOARD_BORDER))
        begin
            map_border = 1'b1;
        end
    
        // Logic for drawing the long top horizontal line
        if ((DrawX >= center_x - tile_size * 5 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x + tile_size * 4) &&
            (DrawY >= center_y - tile_size * 2 - GAME_BOARD_BORDER) &&
            (DrawY <= center_y - tile_size * 2))
        begin
            map_border = 1'b1;
        end
    
        // Logic for drawing the long bottom horizontal line
        if ((DrawX >= center_x - tile_size * 4) &&
            (DrawX <= center_x + tile_size * 5 + GAME_BOARD_BORDER) &&
            (DrawY >= center_y + tile_size * 2) &&
            (DrawY <= center_y + tile_size * 2 + GAME_BOARD_BORDER))
        begin
            map_border = 1'b1;
        end
    
        // Logic for drawing the long left vertical line
        if ((DrawY >= center_y - tile_size * 2) &&
            (DrawY <= center_y + tile_size * 2) &&
            (DrawX >= center_x - tile_size * 5 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x - tile_size * 5))
        begin
            map_border = 1'b1;
        end
    
        // Logic for drawing the long right vertical line
        if ((DrawY >= center_y - tile_size * 2) &&
            (DrawY <= center_y + tile_size * 2) &&
            (DrawX >= center_x + tile_size * 5) &&
            (DrawX <= center_x + tile_size * 5 + GAME_BOARD_BORDER))
        begin
            map_border = 1'b1;
        end
    
        // Logic for drawing top right 2-square horizontal line
        if ((DrawY >= center_y - tile_size * 3 - GAME_BOARD_BORDER) &&
            (DrawY <= center_y - tile_size * 3) &&
            (DrawX >= center_x + tile_size * 4 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x + tile_size * 6))
        begin
            map_border = 1'b1;
        end
        // Logic for drawing bottom left 2-square horizontal line
        if ((DrawY >= center_y + tile_size * 3) &&
            (DrawY <= center_y + tile_size * 3 + GAME_BOARD_BORDER) &&
            (DrawX >= center_x - tile_size * 6) &&
            (DrawX <= center_x - tile_size * 4 + GAME_BOARD_BORDER))
        begin
            map_border = 1'b1;
        end
    end else if(Level2_Active) begin
        // Green start point
        if((DrawX >= center_x - tile_size*9) && 
            (DrawX <= center_x - tile_size*6) && 
            (DrawY >= center_y - tile_size*1) && 
            (DrawY <= center_y + tile_size*1)) 
        begin
            map_on = 1'b1;
            green_on = 1'b1;
        end
        // Big central area
        else if((DrawX >= center_x - tile_size*6) && 
                (DrawX <= center_x + tile_size*6 - GAME_BOARD_BORDER)&& 
                (DrawY >= center_y - tile_size*3) && 
                (DrawY <= center_y + tile_size*3))
        begin
            map_on = 1'b1;
        end
        // Green end point
        else if((DrawX >= center_x + tile_size*6) && 
                (DrawX <= center_x + tile_size*9)&& 
                (DrawY >= center_y - tile_size*1) && 
                (DrawY <= center_y + tile_size*1)) 
        begin
            map_on = 1'b1;
            green_on = 1'b1;
        end
        
        // Logic for drawing the border around the left green box
        if ((DrawX >= center_x - tile_size * 9 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x - tile_size * 6) &&
            (DrawY >= center_y - tile_size * 1 - GAME_BOARD_BORDER) &&
            (DrawY <= center_y + tile_size * 1 + GAME_BOARD_BORDER))
        begin
            if ((DrawX <= center_x - tile_size * 9) || // Left border
                (DrawY <= center_y - tile_size * 1) || // Top border
                (DrawY >= center_y + tile_size * 1))   // Bottom border
            begin
                map_border = 1'b1;
            end
        end
    
        // Logic for drawing the border around the right green box
        if ((DrawX >= center_x + tile_size * 6) &&
            (DrawX <= center_x + tile_size * 9 + GAME_BOARD_BORDER) &&
            (DrawY >= center_y - tile_size * 1 - GAME_BOARD_BORDER) &&
            (DrawY <= center_y + tile_size * 1 + GAME_BOARD_BORDER))
        begin
            if ((DrawY <= center_y - tile_size * 1) || // Top border
                (DrawY >= center_y + tile_size * 1) ||   //Right border
                (DrawX >= center_x + tile_size * 9))   // Bottom border
            begin
                map_border = 1'b1;
            end
        end
        // Logic for drawing the long top horizontal line
        if ((DrawX >= center_x - tile_size * 6 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x + tile_size * 6 + GAME_BOARD_BORDER) &&
            (DrawY >= center_y - tile_size * 3 - GAME_BOARD_BORDER) &&
            (DrawY <= center_y - tile_size * 3))
        begin
            map_border = 1'b1;
        end
    
        // Logic for drawing the long bottom horizontal line
        if ((DrawX >= center_x - tile_size * 6 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x + tile_size * 6 + GAME_BOARD_BORDER) &&
            (DrawY >= center_y + tile_size * 3) &&
            (DrawY <= center_y + tile_size * 3 + GAME_BOARD_BORDER))
        begin
            map_border = 1'b1;
        end
        
        // Logic for drawing the long left top vertical line
        if ((DrawY >= center_y - tile_size * 3) &&
            (DrawY <= center_y - tile_size * 1) &&
            (DrawX >= center_x - tile_size * 6 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x - tile_size * 6))
        begin
            map_border = 1'b1;
        end
    
        // Logic for drawing the long right top vertical line
        if ((DrawY >= center_y - tile_size * 3) &&
            (DrawY <= center_y - tile_size * 1) &&
            (DrawX >= center_x + tile_size * 6) &&
            (DrawX <= center_x + tile_size * 6 + GAME_BOARD_BORDER))
        begin
            map_border = 1'b1;
        end
        
        // Logic for drawing the long left bottom vertical line
        if ((DrawY >= center_y + tile_size * 1) &&
            (DrawY <= center_y + tile_size * 3) &&
            (DrawX >= center_x - tile_size * 6 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x - tile_size * 6))
        begin
            map_border = 1'b1;
        end
    
        // Logic for drawing the long right bottom vertical line
        if ((DrawY >= center_y + tile_size * 1) &&
            (DrawY <= center_y + tile_size * 3) &&
            (DrawX >= center_x + tile_size * 6) &&
            (DrawX <= center_x + tile_size * 6 + GAME_BOARD_BORDER))
        begin
            map_border = 1'b1;
        end
    end else if(Level3_Active) begin
        // Green start point
        if((DrawX >= center_x - tile_size*1) && 
            (DrawX <= center_x + tile_size*1 - GAME_BOARD_BORDER) && 
            (DrawY >= center_y - tile_size*1) && 
            (DrawY <= center_y + tile_size*1 - GAME_BOARD_BORDER)) 
        begin
            map_on = 1'b1;
            green_on = 1'b1;
        end
        // Big central area
        else if((DrawX >= center_x - tile_size*2) && 
                (DrawX <= center_x + tile_size*2)&& 
                (DrawY >= center_y - tile_size*2) && 
                (DrawY <= center_y + tile_size*2))
        begin
            map_on = 1'b1;
        end
        // Single block
        else if((DrawX >= center_x - tile_size*2) && 
                (DrawX <= center_x - tile_size*1)&& 
                (DrawY >= center_y - tile_size*3) && 
                (DrawY <= center_y - tile_size*2))
        begin
            map_on = 1'b1;
        end
        
        // Logic for drawing the long top horizontal line
        if ((DrawX >= center_x - tile_size * 1) &&
            (DrawX <= center_x + tile_size * 2 + GAME_BOARD_BORDER) &&
            (DrawY >= center_y - tile_size * 2 - GAME_BOARD_BORDER) &&
            (DrawY <= center_y - tile_size * 2))
        begin
            map_border = 1'b1;
        end
    
        // Logic for drawing the long bottom horizontal line
        if ((DrawX >= center_x - tile_size * 2 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x + tile_size * 2 + GAME_BOARD_BORDER) &&
            (DrawY >= center_y + tile_size * 2) &&
            (DrawY <= center_y + tile_size * 2 + GAME_BOARD_BORDER))
        begin
            map_border = 1'b1;
        end
        
        // Logic for drawing the long left vertical line
        if ((DrawY >= center_y - tile_size * 3) &&
            (DrawY <= center_y + tile_size * 2) &&
            (DrawX >= center_x - tile_size * 2 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x - tile_size * 2))
        begin
            map_border = 1'b1;
        end
    
        // Logic for drawing the long right vertical line
        if ((DrawY >= center_y - tile_size * 2) &&
            (DrawY <= center_y + tile_size * 2) &&
            (DrawX >= center_x + tile_size * 2) &&
            (DrawX <= center_x + tile_size * 2 + GAME_BOARD_BORDER))
        begin
            map_border = 1'b1;
        end
        
        // Logic for drawing the short vertical line
        if ((DrawY >= center_y - tile_size * 3) &&
            (DrawY <= center_y - tile_size * 2) &&
            (DrawX >= center_x - tile_size * 1) &&
            (DrawX <= center_x - tile_size * 1 + GAME_BOARD_BORDER))
        begin
            map_border = 1'b1;
        end
        // Logic for drawing the short horizontal line
        if ((DrawX >= center_x - tile_size * 2 - GAME_BOARD_BORDER) &&
            (DrawX <= center_x - tile_size * 1 + GAME_BOARD_BORDER) &&
            (DrawY >= center_y - tile_size * 3) &&
            (DrawY <= center_y - tile_size * 3 + GAME_BOARD_BORDER))
        begin
            map_border = 1'b1;
        end
    end else if(game_final) begin
        map_border = 1'b0;
    end
end


//Boundry code
always_comb begin
    Ball_At_Border_Top = 1'b0;
    Ball_At_Border_Bottom = 1'b0;
    Ball_At_Border_Left = 1'b0;
    Ball_At_Border_Right = 1'b0;
    if(Level1_Active) begin    
        //Long top checkered horizontal boundary
        if ((BallX >= center_x - tile_size * 5 - GAME_BOARD_BORDER) &&
           (BallX <= center_x + tile_size * 4 + 5) &&
           (BallY <= center_y - tile_size * 2 + 8))
        begin
            Ball_At_Border_Top = 1'b1;
        end
    
       //Long bottom checkered horizontal boundary
        if ((BallX >= center_x - tile_size * 4 - 5) &&
            (BallX <= center_x + tile_size * 5 + GAME_BOARD_BORDER) &&
            (BallY >= center_y + tile_size * 2 - 8))
        begin
            Ball_At_Border_Bottom = 1'b1;
        end
    
        //Long left checkered vertical boundary
        if ((BallY >= center_y - tile_size * 2) &&
            (BallY <= center_y + tile_size * 2 + 5) &&
            (BallX <= center_x - tile_size * 5 + 8) &&
            (BallX >= center_x - tile_size * 5 - 8))
        begin
            Ball_At_Border_Left = 1'b1;
        end
    
        //Long right checkered vertical boundary
        if ((BallY >= center_y - tile_size * 2 - 5) &&
            (BallY <= center_y + tile_size * 2) &&
            (BallX >= center_x + tile_size * 5 - 8) &&
            (BallX <= center_x + tile_size * 5 + 8))
        begin
            Ball_At_Border_Right = 1'b1;
        end
    
        // Top-right 1-square vertical
        if ((BallX <= center_x + tile_size * 4 + 8) &&
            (BallX >= center_x + tile_size * 4 - 8) &&
            (BallY >= center_y - tile_size * 3 - GAME_BOARD_BORDER) &&
            (BallY <= center_y - tile_size * 2 + 5))
        begin
            Ball_At_Border_Left = 1'b1;
        end
    
        // Bottom-left 1-square horizontal
        if ((BallX >= center_x - tile_size * 6 - 5) &&
            (BallX <= center_x - tile_size * 5 + 5) &&
            (BallY <= center_y + tile_size * 2 + 8))
        begin
            Ball_At_Border_Top = 1'b1;
        end
    
        // Bottom-left 1-square vertical
        if ((BallX >= center_x - tile_size * 4 - 8) &&
            (BallX <= center_x - tile_size * 4 + 8) &&
            (BallY >= center_y + tile_size * 2 - 5) &&
            (BallY <= center_y + tile_size * 3 + GAME_BOARD_BORDER))
        begin
            Ball_At_Border_Right = 1'b1;
        end
    
        //Top-right 1-square horizontal
        if ((BallX >= center_x + tile_size * 5 - 5) &&
            (BallX <= center_x + tile_size * 6 + 5) &&
            (BallY >= center_y - tile_size * 2 - 8))
        begin
            Ball_At_Border_Bottom = 1'b1;
        end
    
        //Top right 2-square horizontal line
        if ((BallY <= center_y - tile_size * 3 + 8) &&
            (BallX >= center_x + tile_size * 4 - GAME_BOARD_BORDER) &&
            (BallX <= center_x + tile_size * 6))
        begin
            Ball_At_Border_Top = 1'b1;
        end
        //Bottom left 2-square horizontal line
        if ((BallY >= center_y + tile_size * 3 - 8) &&
            (BallX >= center_x - tile_size * 6) &&
            (BallX <= center_x - tile_size * 4 + GAME_BOARD_BORDER))
        begin
            Ball_At_Border_Bottom = 1'b1;
        end
    
        //Left green box right side
        if ((BallX >= center_x - tile_size * 6 - 8) &&
            (BallX <= center_x - tile_size * 6 + 8) &&
            (BallY >= center_y - tile_size * 3) &&
            (BallY <= center_y + tile_size * 2 + 5))
        begin
            Ball_At_Border_Right = 1'b1;
        end
       //Left green box left side
        if ((BallX <= center_x - tile_size * 9 + 8) &&
            (BallY >= center_y - tile_size * 3) &&
            (BallY <= center_y + tile_size * 3))
        begin
            Ball_At_Border_Left = 1'b1;
        end
        //Left green box bottom
        if ((BallY >= center_y + tile_size * 3 - 8) &&
            (BallX <= center_x - tile_size * 6) &&
            (BallX >= center_x - tile_size * 9))
        begin
            Ball_At_Border_Bottom = 1'b1;
        end
        //Left green box top
        if ((BallY <= center_y - tile_size * 3 + 8) &&
            (BallX <= center_x - tile_size * 6) &&
            (BallX >= center_x - tile_size * 9))
        begin
            Ball_At_Border_Top = 1'b1;
        end
        //Right green box left side
        if ((BallX <= center_x + tile_size * 6 + 8) &&
            (BallX >= center_x + tile_size * 6 - 8) &&
            (BallY >= center_y - tile_size * 2 - 5) &&
            (BallY <= center_y + tile_size * 3))
        begin
            Ball_At_Border_Left = 1'b1;
        end
        //Right green box right side
        if ((BallX >= center_x + tile_size * 9 - 8) &&
            (BallY >= center_y - tile_size * 3) &&
            (BallY <= center_y + tile_size * 3))
        begin
            Ball_At_Border_Right = 1'b1;
        end
        //Right green box bottom
        if ((BallY >= center_y + tile_size * 3 - 8) &&
            (BallX >= center_x + tile_size * 6) &&
            (BallX <= center_x + tile_size * 9))
        begin
            Ball_At_Border_Bottom = 1'b1;
        end
        //Right green box top
        if ((BallY <= center_y - tile_size * 3 + 8) &&
            (BallX >= center_x + tile_size * 6) &&
            (BallX <= center_x + tile_size * 9))
        begin
            Ball_At_Border_Top = 1'b1;
        end
    end else if(Level2_Active) begin 
       //Left green box left side
        if ((BallX <= center_x - tile_size * 9 + 8) &&
            (BallY >= center_y - tile_size * 1) &&
            (BallY <= center_y + tile_size * 1))
        begin
            Ball_At_Border_Left = 1'b1;
        end
        //Left green box bottom
        if ((BallY >= center_y + tile_size * 1 - 8) &&
            (BallX <= center_x - tile_size * 6 + 5) &&
            (BallX >= center_x - tile_size * 9))
        begin
            Ball_At_Border_Bottom = 1'b1;
        end
        //Left green box top
        if ((BallY <= center_y - tile_size * 1 + 8) &&
            (BallX <= center_x - tile_size * 6 + 5) &&
            (BallX >= center_x - tile_size * 9))
        begin
            Ball_At_Border_Top = 1'b1;
        end
        //Right green box right side
        if ((BallX >= center_x + tile_size * 9 - 8) &&
            (BallY >= center_y - tile_size * 1) &&
            (BallY <= center_y + tile_size * 1))
        begin
            Ball_At_Border_Right = 1'b1;
        end
        //Right green box bottom
        if ((BallY >= center_y + tile_size * 1 - 8) &&
            (BallX >= center_x + tile_size * 6 - 5) &&
            (BallX <= center_x + tile_size * 9))
        begin
            Ball_At_Border_Bottom = 1'b1;
        end
        //Right green box top
        if ((BallY <= center_y - tile_size * 1 + 8) &&
            (BallX >= center_x + tile_size * 6 - 5) &&
            (BallX <= center_x + tile_size * 9))
        begin
            Ball_At_Border_Top = 1'b1;
        end
        
        //Long top checkered horizontal boundary
        if ((BallX >= center_x - tile_size * 6 - GAME_BOARD_BORDER) &&
           (BallX <= center_x + tile_size * 6) &&
           (BallY <= center_y - tile_size * 3 + 8))
        begin
            Ball_At_Border_Top = 1'b1;
        end
    
       //Long bottom checkered horizontal boundary
        if ((BallX >= center_x - tile_size * 6) &&
            (BallX <= center_x + tile_size * 6 + GAME_BOARD_BORDER) &&
            (BallY >= center_y + tile_size * 3 - 8))
        begin
            Ball_At_Border_Bottom = 1'b1;
        end
        
        //Long left top checkered vertical boundary
        if ((BallY >= center_y - tile_size * 3) &&
            (BallY <= center_y - tile_size * 1 + 5) &&
            (BallX <= center_x - tile_size * 6 + 8) &&
            (BallX >= center_x - tile_size * 6 - 8))
        begin
            Ball_At_Border_Left = 1'b1;
        end
    
        //Long right top checkered vertical boundary
        if ((BallY >= center_y - tile_size * 3) &&
            (BallY <= center_y - tile_size * 1 + 5) &&
            (BallX >= center_x + tile_size * 6 - 8) &&
            (BallX <= center_x + tile_size * 6 + 8))
        begin
            Ball_At_Border_Right = 1'b1;
        end
        
        //Long left bottom checkered vertical boundary
        if ((BallY >= center_y + tile_size * 1 - 5) &&
            (BallY <= center_y + tile_size * 3) &&
            (BallX <= center_x - tile_size * 6 + 8) &&
            (BallX >= center_x - tile_size * 6 - 8))
        begin
            Ball_At_Border_Left = 1'b1;
        end
    
        //Long right bottom checkered vertical boundary
        if ((BallY >= center_y + tile_size * 1 - 5) &&
            (BallY <= center_y + tile_size * 3) &&
            (BallX >= center_x + tile_size * 6 - 8) &&
            (BallX <= center_x + tile_size * 6 + 8))
        begin
            Ball_At_Border_Right = 1'b1;
        end       
    end else if(Level3_Active) begin 
        //Long top horizontal boundary
        if ((BallX >= center_x - tile_size * 1 - 5) &&
           (BallX <= center_x + tile_size * 2 + GAME_BOARD_BORDER) &&
           (BallY <= center_y - tile_size * 2 + 8))
        begin
            Ball_At_Border_Top = 1'b1;
        end
       //Long bottom horizontal boundary
        if ((BallX >= center_x - tile_size * 2 - GAME_BOARD_BORDER) &&
            (BallX <= center_x + tile_size * 2 + GAME_BOARD_BORDER) &&
            (BallY >= center_y + tile_size * 2 - 8))
        begin
            Ball_At_Border_Bottom = 1'b1;
        end      
        //Long left vertical boundary
        if ((BallY >= center_y - tile_size * 3) &&
            (BallY <= center_y + tile_size * 2) &&
            (BallX <= center_x - tile_size * 2 + 8) &&
            (BallX >= center_x - tile_size * 2 - 8))
        begin
            Ball_At_Border_Left = 1'b1;
        end
        //Long right vertical boundary
        if ((BallY >= center_y - tile_size * 2) &&
            (BallY <= center_y + tile_size * 2) &&
            (BallX >= center_x + tile_size * 2 - 8) &&
            (BallX <= center_x + tile_size * 2 + 8))
        begin
            Ball_At_Border_Right = 1'b1;
        end
       //Short horizontal boundary
        if ((BallX >= center_x - tile_size * 2 - GAME_BOARD_BORDER) &&
            (BallX <= center_x - tile_size * 1 + GAME_BOARD_BORDER) &&
            (BallY <= center_y - tile_size * 3 + 8))
        begin
            Ball_At_Border_Top = 1'b1;
        end      
        //Short vertical boundary
        if ((BallY >= center_y - tile_size * 3) &&
            (BallY <= center_y - tile_size * 2 + 5) &&
            (BallX >= center_x - tile_size * 2 + 8))
        begin
            Ball_At_Border_Right = 1'b1;
        end    
    end else if(game_final) begin
        Ball_At_Border_Top = 1'b1;
        Ball_At_Border_Bottom = 1'b1;
        Ball_At_Border_Left = 1'b1;
        Ball_At_Border_Right = 1'b1;
    end
end


always_comb begin
    Level1_End = 1'b0;
    Level2_End = 1'b0;
    Level3_End = 1'b0;
    if (Wait_Before_Level2 || Wait_Before_Level3 || reset_coin) begin
        CoinCollected_Level2 = 1'b0;
        CoinCollected_Level3 = 1'b0;
        coin_visible = 1'b1;
    end else begin
        if (Level1_Active) begin
            if ((BallY >= center_y - tile_size * 3 - GAME_BOARD_BORDER) &&
                (BallY <= center_y - tile_size * 2 + GAME_BOARD_BORDER) &&
                (BallX >= center_x + tile_size * 6 - 8)) 
            begin
                Level1_End = 1'b1;
            end
        end else if (Level2_Active) begin
            if (!coin_visible &&((BallX >= center_x + tile_size * 6 - 8) &&
                (BallY >= center_y - tile_size * 1 - GAME_BOARD_BORDER) &&
                (BallY <= center_y + tile_size * 1 + GAME_BOARD_BORDER))) 
            begin
                Level2_End = 1'b1;
                CoinCollected_Level2 = 1'b1;
            end 
            if (coin_visible && ((BallX >= CoinX - 9) && (BallX <= CoinX + 9) && 
                (BallY >= CoinY - 9) && (BallY <= CoinY + 9))) begin
                CoinCollected_Level2 = 1'b1;
                coin_visible = 1'b0;
            end    
        end else if (Level3_Active) begin
            if (!coin_visible && ((BallY >= center_y - tile_size * 1 - 8) &&
                (BallY <= center_y + tile_size * 1 + 8) &&
                (BallX >= center_x - tile_size * 1 - 8) &&
                (BallX <= center_x + tile_size * 1 + 8))) 
            begin
                Level3_End = 1'b1;
                CoinCollected_Level3 = 1'b1;
            end 
            if (coin_visible && ((BallX >= CoinX - 9) && (BallX <= CoinX + 9) && 
                (BallY >= CoinY - 9) && (BallY <= CoinY + 9))) begin
                CoinCollected_Level3 = 1'b1;
                coin_visible = 1'b0;
            end     
        end
    end
end

always_comb begin: RGB_Display
    // Default color
    if(Wait_Before_Level1 || Wait_Before_Level2 || Wait_Before_Level3 || 
    Init1_Active || Init2_Active) begin
        Red = 4'hb;
        Green = 4'hb;
        Blue = 4'hb;
    end else begin
        Red = 4'hb;
        Green = 4'ha;
        Blue = 4'hf;
    end
    
    if (pixel_on) begin
        // Use text color
        Red = 4'h0;
        Green = 4'h0;
        Blue = 4'h0;
    end else begin
        if (map_border) begin
            Red = 4'h0;
            Green = 4'h0;
            Blue = 4'h0;
        end else if (green_on) begin
            Red = 4'h9;
            Green = 4'he;
            Blue = 4'h9;
        end else if (on_tile & map_on) begin
            Red = 4'he;
            Green = 4'he;
            Blue = 4'hf;
        end else if (off_tile & map_on) begin
            Red = 4'ha;
            Green = 4'ha;
            Blue = 4'hf;
        end
        // Ball
        if (ball_on) begin
            // Ball color: red
            Red = 4'hf;
            Green = 4'h0;
            Blue = 4'h0;
        end
        // Circle
        if (circle_on) begin
            Red = 4'h0;
            Green = 4'h0;
            Blue = 4'hf;
        end
        // Coin
        if (coin_on) begin
            Red = 4'hf;
            Green = 4'hb;
            Blue = 4'h0;
        end
        // Border logic
        if (border_on || circle_border_on || coin_border_on) begin
            // Border color: black
            Red = 4'h0;
            Green = 4'h0;
            Blue = 4'h0;
        end
    end
end
endmodule