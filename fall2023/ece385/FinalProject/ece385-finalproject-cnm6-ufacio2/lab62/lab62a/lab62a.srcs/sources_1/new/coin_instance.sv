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


module  coin ( input logic Reset, frame_clk,
               output logic [9:0]  CoinX, CoinY, CoinS,
               input logic Level1_End, Level2_End, Level3_End,
               input logic Level1_Active, Level2_Active, Level3_Active, Wait_State1, Wait_State2, Wait_State3, game_final,
               input logic Wait_Before_Level1, Wait_Before_Level2, Wait_Before_Level3
               );

    parameter [9:0] Coin_X_Center=320;  // Center position on the X axis
    parameter [9:0] Coin_Y_Center=240;  // Center position on the Y axis

    
    

    assign CoinS = 4;

always_ff @(posedge frame_clk) begin
    if (Level1_Active) begin
        CoinY <= Coin_Y_Center;
        CoinX <= Coin_X_Center - 150;
    end else if(Level2_Active) begin
        CoinY <= Coin_Y_Center;
        CoinX <= Coin_X_Center;
    end else if(Level3_Active) begin
        CoinY <= Coin_Y_Center;
        CoinX <= Coin_X_Center - 100;
    end else begin
        CoinY <= Coin_Y_Center;
        CoinX <= Coin_X_Center;
    end
end

endmodule