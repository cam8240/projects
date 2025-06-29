module testbench();

timeunit 10ns;
timeprecision 1ns;

logic Clk = 0;
logic reset;
logic [7:0] keycode[6];
logic frame_clk;
logic [9:0] BallX, BallY, BallS;
logic [3:0] Red, Green, Blue;
logic [9:0] DrawX, DrawY;

// Signals for state machine
logic Level1_End, Level2_End, Level3_End;
logic CoinCollected_Level2, CoinCollected_Level3;
logic Level1_Active, Level2_Active, Level3_Active;
logic Wait_State1, Wait_State2, Wait_State3;
logic Wait_Before_Level1, Wait_Before_Level2, Wait_Before_Level3;
logic Init1_Active, Init2_Active;
logic game_final; 
logic CoinCollected2, CoinCollected3;

mb_usb_hdmi_top top_level(
    .Clk(Clk),
    .reset_rtl_0(reset)
);

state_machine state_machine_inst (
    .Clk(Clk),
    .Reset(reset),
    .Level1_End(Level1_End),
    .Level2_End(Level2_End),
    .Level3_End(Level3_End),
    .CoinCollected_Level2(CoinCollected_Level2),
    .CoinCollected_Level3(CoinCollected_Level3),
    .Level1_Active(Level1_Active),
    .Level2_Active(Level2_Active),
    .Level3_Active(Level3_Active),
    .Wait_State1(Wait_State1),
    .Wait_State2(Wait_State2),
    .Wait_State3(Wait_State3),
    .Wait_Before_Level1(Wait_Before_Level1),
    .Wait_Before_Level2(Wait_Before_Level2),
    .Wait_Before_Level3(Wait_Before_Level3),
    .Init1_Active(Init1_Active),
    .Init2_Active(Init2_Active),
    .game_final(game_final),
    .CoinCollected2(CoinCollected2),
    .CoinCollected3(CoinCollected3),
    .keycode(keycode)
);

always begin : CLOCK_GENERATION
#1 Clk = ~Clk;
end

initial begin: CLOCK_INITIALIZATION
    Clk = 0;
end 

initial begin: test_vectors
    reset = 1;
    keycode = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
    frame_clk = 0;

    Level1_End = 0;
    Level2_End = 0;
    Level3_End = 0;
    CoinCollected_Level2 = 0;
    CoinCollected_Level3 = 0;
    
    #2 Init1_Active = 1;
    #2 Init1_Active = 0;
    #2 Init2_Active = 1;

    #2 reset = 0;
        
    #5 keycode[0] = 8'h1A;
    #5 keycode[1] = 8'h16;
    #5 keycode[2] = 8'h04;
    #5 keycode[3] = 8'h07;

    #10 Level1_End = 1;
    #10 Level1_End = 0;
    
    #5 keycode[0] = 8'h1A;
    #5 keycode[1] = 8'h16;
    #5 keycode[2] = 8'h04;
    #5 keycode[3] = 8'h07;

    #5 DrawX = 100; DrawY = 200;

    #5 keycode[1] = 8'h04;

    #5 keycode[0] = 8'h1A; 
    #5 DrawX = 100; DrawY = 200;

end

endmodule