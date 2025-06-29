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


module  blue_circle (
    input logic Reset, frame_clk,
    input logic [9:0] Circle_X_Min, Circle_X_Max, Circle_Y_Min, Circle_Y_Max, Circle_Center_PointX, Circle_Center_PointY,
    Circular_Radius, Start_X, Start_Y,
    input logic [1:0] Movement, Direction,
    output logic [9:0]  CircleX, CircleY, CircleS
    );
    // Definitions:
    // Movement 00: Horizontal linear motion
    // Movement 01: Vertical linear motion
    // Movement 10: Box movement around a center point

    // Direction 00: Movement towards lower X values
    // Direction 01: Movement towards higher X values
    // Direction 10: Movement towards lower Y values
    // Direction 11: Movement towards higher Y values

    logic [9:0] Circle_X_Motion, Circle_Y_Motion;
    localparam [9:0] Circle_X_Step=2;      // Step size on the X axis
    localparam [9:0] Circle_Y_Step=2;      // Step size on the Y axis

    assign CircleS = 3;  // default ball size

always_ff @(posedge frame_clk or posedge Reset) begin: Move_Circle
        if (Reset) begin
            // Reset logic
                CircleY <= Start_Y;
                CircleX <= Start_X;
                unique case (Direction)
                    2'b00: begin
                        Circle_Y_Motion <= 10'd0;
                        Circle_X_Motion <= (~ (10'd1) + 1'b1);
                    end
                    2'b01: begin
                        Circle_Y_Motion <= 10'd0;
                        Circle_X_Motion <= 10'd1;
                    end
                    2'b10: begin
                        Circle_Y_Motion <= (~ (10'd1) + 1'b1);
                        Circle_X_Motion <= 10'd0;
                    end
                    2'b11: begin
                        Circle_Y_Motion <= 10'd1;
                        Circle_X_Motion <= 10'd0;
                    end
                endcase
        end
        else begin
            unique case(Movement)
                2'b00: begin
                    if ( (CircleX + CircleS) >= Circle_X_Max )  // Circle is at the Right edge, BOUNCE!
                      Circle_X_Motion <= (~ (Circle_X_Step) + 1'b1);  // 2's complement.
                    else if ( (CircleX - CircleS) <= Circle_X_Min )  // Circle is at the Left edge, BOUNCE!
                      Circle_X_Motion <= Circle_X_Step;
                    else begin
                      Circle_Y_Motion <= 10'd0;
                      Circle_X_Motion <= Circle_X_Motion;
                    end
                end
                2'b01: begin
                    if ((CircleY + CircleS) >= Circle_Y_Max )  // Ball is at the bottom edge, BOUNCE!
                        Circle_Y_Motion <= (~ (Circle_Y_Step) + 1'b1);  // 2's complement.
                    else if ((CircleY - CircleS) <= Circle_Y_Min )  // Ball is at the top edge, BOUNCE!
                        Circle_Y_Motion <= Circle_Y_Step;
                    else begin
                        Circle_X_Motion <= 10'd0;
                        Circle_Y_Motion <= Circle_Y_Motion;  // Circle is somewhere in the middle, don't bounce, just keep moving;
                    end
                end
                2'b10: begin
                    // Traveling on bottom edge then hit a right edge
                    if ((CircleY - CircleS) <= (Circle_Center_PointY - Circular_Radius) && (CircleX + CircleS) < (Circle_Center_PointX + Circular_Radius)) begin
                        Circle_X_Motion <= 10'd1;
                        Circle_Y_Motion <= 10'd0;
                    end
                    // Traveling on right edge then hit a top edge
                    else if ((CircleX + CircleS) >= (Circle_Center_PointX + Circular_Radius) && (CircleY + CircleS) < (Circle_Center_PointY + Circular_Radius)) begin
                        Circle_X_Motion <= 10'd0;
                        Circle_Y_Motion <= 10'd1;
                    end
                    // Traveling on top edge then hit a left edge
                    else if ((CircleY + CircleS) >= (Circle_Center_PointY + Circular_Radius) && (CircleX - CircleS) > (Circle_Center_PointX - Circular_Radius)) begin
                        Circle_X_Motion <= (~(10'd1) + 1'b1);
                        Circle_Y_Motion <= 10'd0;
                    end
                    // Traveling on left edge then hit a bottom edge
                    else if ((CircleX - CircleS) <= (Circle_Center_PointX - Circular_Radius) && (CircleY - CircleS) > (Circle_Center_PointY - Circular_Radius)) begin
                        Circle_X_Motion <= 10'd0;
                        Circle_Y_Motion <= (~(10'd1) + 1'b1);
                    end
                    else begin
                        Circle_X_Motion <= Circle_X_Motion;
                        Circle_Y_Motion <= Circle_Y_Motion;
                    end
                end
           endcase
            CircleY <= CircleY + Circle_Y_Motion;
            CircleX <= CircleX + Circle_X_Motion;
        end
    end
endmodule