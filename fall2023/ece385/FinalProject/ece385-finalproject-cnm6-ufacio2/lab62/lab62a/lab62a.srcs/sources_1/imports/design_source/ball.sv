//-------------------------------------------------------------------------
//    Ball.sv                                                            --
//    Viral Mehta                                                        --
//    Spring 2005                                                        --
//                                                                       --
//    Modified by Stephen Kempf 03-01-2006                               --
//                              03-12-2007                               --
//    Translated by Joe Meng    07-07-2013                               --
//    Modified by Zuofu Cheng   08-19-2023                               --
//    Fall 2023 Distribution                                             --
//                                                                       --
//    For use with ECE 385 USB + HDMI Lab                                --
//    UIUC ECE Department                                                --
//-------------------------------------------------------------------------


module  ball ( input logic Reset, frame_clk,
               input logic [7:0] keycode[6],
               input logic Ball_At_Border_Top, Ball_At_Border_Bottom, Ball_At_Border_Left, Ball_At_Border_Right,
               output logic [9:0]  BallX, BallY, BallS,
               input logic Level1_Active, Level2_Active, Level3_Active, Wait_State1, Wait_State2, Wait_State3,
               input logic Wait_Before_Level1, Wait_Before_Level2, Wait_Before_Level3,
               output logic reset_coin1, reset_coin2
               );

    logic [9:0] Ball_X_Motion, Ball_Y_Motion;

    parameter [9:0] Ball_X_Center=320;  // Center position on the X axis
    parameter [9:0] Ball_Y_Center=240;  // Center position on the Y axis
    parameter [9:0] Ball_X_Min=0;       // Leftmost point on the X axis
    parameter [9:0] Ball_X_Max=639;     // Rightmost point on the X axis
    parameter [9:0] Ball_Y_Min=0;       // Topmost point on the Y axis
    parameter [9:0] Ball_Y_Max=479;     // Bottommost point on the Y axis
    parameter [9:0] Ball_X_Step=1;      // Step size on the X axis
    parameter [9:0] Ball_Y_Step=1;      // Step size on the Y axis
    
    parameter GAME_BOARD_BORDER = 1;
    

    assign BallS = 6;
    int tile_size = 20;

always_ff @(posedge frame_clk) begin: Move_Ball
    if(Level2_Active) begin
        reset_coin1 <= 1'b0;
    end
    if(Level3_Active) begin
        reset_coin2 <= 1'b0;
    end
    
    if (Wait_Before_Level1) begin
        BallY <= Ball_Y_Center;
        BallX <= Ball_X_Center - 150;
        reset_coin1 <= 1'b0;
        reset_coin2 <= 1'b0;
    end else if(Level1_Active && Reset) begin
        BallY <= Ball_Y_Center;
        BallX <= Ball_X_Center - 150;
    end else if(Wait_State1) begin
        BallY <= Ball_Y_Center;
        BallX <= Ball_X_Center - 160;
    end else if(Level2_Active && Reset) begin
        BallY <= Ball_Y_Center;
        BallX <= Ball_X_Center - 160;
        reset_coin1 <= 1'b1;
    end else if(Wait_State2) begin
        BallY <= Ball_Y_Center;
        BallX <= Ball_X_Center;
    end else if(Level3_Active && Reset) begin
        BallY <= Ball_Y_Center;
        BallX <= Ball_X_Center;
        reset_coin2 <= 1'b1;
    end else begin
        Ball_X_Motion <= 10'd0;
        Ball_Y_Motion <= 10'd0;
        
        if(Level1_Active || Level2_Active || Level3_Active) begin    
            for (int i = 0; i < 6; i++) begin
                if (keycode[i] == 8'h1A && Ball_At_Border_Top == 1'b0) // W
                    Ball_Y_Motion <= -Ball_Y_Step;
                else if (keycode[i] == 8'h16 && Ball_At_Border_Bottom == 1'b0) // S
                    Ball_Y_Motion <= Ball_Y_Step;
                if (keycode[i] == 8'h07 && Ball_At_Border_Right == 1'b0) // D
                    Ball_X_Motion <= Ball_X_Step;
                else if (keycode[i] == 8'h04 && Ball_At_Border_Left == 1'b0) // A
                    Ball_X_Motion <= -Ball_X_Step;
            end
        end
        BallY <= BallY + Ball_Y_Motion;
        BallX <= BallX + Ball_X_Motion;  
    end
end

endmodule