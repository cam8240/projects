`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Zuofu Cheng
//
// Create Date: 12/11/2022 10:48:49 AM
// Design Name:
// Module Name: mb_usb_hdmi_top
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
// Top level for mb_lwusb test project, copy mb wrapper here from Verilog and modify
// to SV
// Dependencies: microblaze block design
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module mb_usb_hdmi_top(
    input logic Clk,
    input logic reset_rtl_0,

    //USB signals
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,

    //UART
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,

    //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p,

    //HEX displays
    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB
    );
    localparam [6:0] Enemies = 27;

    logic [31:0] keycode0_gpio, keycode1_gpio;
    logic [7:0] keycodes_gpio[6]; // Array to hold keycodes
    logic [9:0] circleX[Enemies], circleY[Enemies], circleS[Enemies];

always_comb begin
    keycodes_gpio[0] = keycode0_gpio[7:0];   // First keycode
    keycodes_gpio[1] = keycode0_gpio[15:8];  // Second keycode
    keycodes_gpio[2] = keycode0_gpio[23:16]; // Third keycode
    keycodes_gpio[3] = keycode0_gpio[31:24]; // Fourth keycode
    keycodes_gpio[4] = 8'd0;                 // No keycode
    keycodes_gpio[5] = 8'd0;                 // No keycode
end

    logic clk_25MHz, clk_125MHz, clk, clk_100MHz;
    logic locked;
    logic [9:0] drawX, drawY, ballxsig, ballysig, ballsizesig, CoinX, CoinY, CoinS;

    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;
    logic reset_ah, reset_c, enable[Enemies];

    assign reset_ah = reset_rtl_0;


    //Keycode HEX drivers
    HexDriver HexA (
        .clk(Clk),
        .reset(reset_ah),
        .in({keycode0_gpio[31:28], keycode0_gpio[27:24], keycode0_gpio[23:20], keycode0_gpio[19:16]}),
        .hex_seg(hex_segA),
        .hex_grid(hex_gridA)
    );

    HexDriver HexB (
        .clk(Clk),
        .reset(reset_ah),
        .in({keycode0_gpio[15:12], keycode0_gpio[11:8], keycode0_gpio[7:4], keycode0_gpio[3:0]}),
        .hex_seg(hex_segB),
        .hex_grid(hex_gridB)
    );

    mb_block mb_block_i(
        .clk_100MHz(Clk),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~reset_ah), //Block designs expect active low reset, all other modules are active high
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );

    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );

    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active LOW
        .rst(reset_ah),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),

        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),

        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),
        .TMDS_CLK_N(hdmi_tmds_clk_n),
        .TMDS_DATA_P(hdmi_tmds_data_p),
        .TMDS_DATA_N(hdmi_tmds_data_n)
    );


    //Ball Module
    ball ball_instance(
        .Reset(reset_ah || reset_c),
        .frame_clk(vsync),                  //Figure out what this should be so that the ball will move
        .keycode(keycodes_gpio),    //Notice: only one keycode connected to ball by default
        .BallX(ballxsig),
        .BallY(ballysig),
        .BallS(ballsizesig),
        .Ball_At_Border_Top(Ball_At_Border_Top),
        .Ball_At_Border_Bottom(Ball_At_Border_Bottom),
        .Ball_At_Border_Left(Ball_At_Border_Left),
        .Ball_At_Border_Right(Ball_At_Border_Right),
        .Level1_Active(Level1_Active),
        .Level2_Active(Level2_Active),
        .Level3_Active(Level3_Active),
        .Wait_State1(Wait_State1),
        .Wait_State2(Wait_State2),
        .Wait_State3(Wait_State3),
        .Wait_Before_Level1(Wait_Before_Level1),
        .Wait_Before_Level2(Wait_Before_Level2),
        .Wait_Before_Level3(Wait_Before_Level3),
        .reset_coin1(reset_coin1),
        .reset_coin2(reset_coin2)
    );


    //Color Mapper Module
    color_mapper #(
        .Enemies(Enemies)
        )
        color_instance(
        .BallX(ballxsig),
        .BallY(ballysig),
        .DrawX(drawX),
        .DrawY(drawY),
        .Ball_size(ballsizesig),
        .Enable(enable),
        .Red(red),
        .Green(green),
        .Blue(blue),
        .Ball_At_Border_Top(Ball_At_Border_Top),
        .Ball_At_Border_Bottom(Ball_At_Border_Bottom),
        .Ball_At_Border_Left(Ball_At_Border_Left),
        .Ball_At_Border_Right(Ball_At_Border_Right),
        .CircleX(circleX),
        .CircleY(circleY),
        .CircleS(circleS),
        .CoinX(CoinX), 
        .CoinY(CoinY), 
        .CoinS(CoinS),
        .Level1_End(Level1_End),
        .Level2_End(Level2_End),
        .Level3_End(Level3_End),
        .Level1_Active(Level1_Active),
        .Level2_Active(Level2_Active),
        .Level3_Active(Level3_Active),
        .CoinCollected_Level2(CoinCollected_Level2),
        .CoinCollected_Level3(CoinCollected_Level3),
        .Wait_Before_Level1(Wait_Before_Level1),
        .Wait_Before_Level2(Wait_Before_Level2),
        .Wait_Before_Level3(Wait_Before_Level3),
        .game_final(game_final),
        .pixel_on(pixel_on),
        .Init1_Active(Init1_Active),
        .Init2_Active(Init2_Active),
        .reset_coin(reset_coin1 || reset_coin2)
    );

    //Game logic module
    game_logic #(
    .Enemies(Enemies)
    )
    game_logic_instance(
    .Reset(reset_ah),
    .frame_clk(vsync),
    .circleX(circleX),
    .circleY(circleY),
    .circleS(circleS),
    .Level_Active({Level3_Active, Level2_Active, Level1_Active}),
    .enable(enable)
    );

    state_machine state_logic (
        .Clk(vsync),
        .Reset(reset_ah),
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
        .game_final(game_final),
        .CoinCollected2(CoinCollected2),
        .CoinCollected3(CoinCollected3),
        .Wait_Before_Level1(Wait_Before_Level1),
        .Wait_Before_Level2(Wait_Before_Level2),
        .Wait_Before_Level3(Wait_Before_Level3),
        .Init1_Active(Init1_Active),
        .Init2_Active(Init2_Active),
        .keycode(keycodes_gpio)
        );

        text_display text(
            .DrawX(drawX),
            .DrawY(drawY),
            .Wait_Before_Level1(Wait_Before_Level1),
            .Wait_Before_Level2(Wait_Before_Level2),
            .Wait_Before_Level3(Wait_Before_Level3),
            .pixel_on(pixel_on),
            .game_final(game_final),
            .Init1_Active(Init1_Active),
            .Init2_Active(Init2_Active)
        );
        
        coin coin_instance(
            .CoinX(CoinX), 
            .CoinY(CoinY), 
            .CoinS(CoinS),
            .Level1_Active(Level1_Active), 
            .Level2_Active(Level2_Active), 
            .Level3_Active(Level3_Active)
           );

    always_comb begin: collision
        reset_c = 1'b0;
        for (int i = 0; i < Enemies; i++) begin
            if(enable[i] &&((ballxsig >= circleX[i] - 9) && (ballxsig <= circleX[i] + 9) &&
               (ballysig >= circleY[i] - 9) && (ballysig <= circleY[i] + 9))) begin
                reset_c = 1'b1;
            end
        end
    end


endmodule