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


module  coin ( output logic [9:0]  CoinX, CoinY, CoinS,
               input logic Level1_Active, Level2_Active, Level3_Active
               );

    parameter [9:0] Coin_X_Center=320;  // Center position on the X axis
    parameter [9:0] Coin_Y_Center=240;  // Center position on the Y axis

    assign CoinS = 3;

    always_comb begin
        CoinY = Coin_Y_Center;
        CoinX = Coin_X_Center;
        if (Level2_Active) begin
            CoinY = Coin_Y_Center;
            CoinX = Coin_X_Center;
        end 
        if(Level3_Active) begin
            CoinY = Coin_Y_Center - 50;
            CoinX = Coin_X_Center - 30;
        end
    end

endmodule
