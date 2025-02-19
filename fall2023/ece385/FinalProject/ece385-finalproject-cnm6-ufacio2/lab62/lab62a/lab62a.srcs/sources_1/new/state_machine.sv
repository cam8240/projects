module state_machine (
    input logic Clk, Reset,
    input logic Level1_End, Level2_End, Level3_End, 
    input logic CoinCollected_Level2, CoinCollected_Level3,
    output logic Level1_Active, Level2_Active, Level3_Active,
    output logic Wait_State1, Wait_State2, Wait_State3,
    output logic Wait_Before_Level1, Wait_Before_Level2, Wait_Before_Level3,
    output logic Init1_Active, Init2_Active,
    output logic game_final, 
    output logic CoinCollected2, CoinCollected3,
    input logic [7:0] keycode[6]
);

    // States including the new wait states before each level and game over
    enum logic [3:0] { 
        INIT1, INIT2, LEVEL1, WAIT_STATE1, LEVEL2, WAIT_STATE2, LEVEL3, WAIT_STATE3, GAME_OVER,
        NEW_WAIT_BEFORE_LEVEL1, NEW_WAIT_BEFORE_LEVEL2, NEW_WAIT_BEFORE_LEVEL3
    } curr_state, next_state;

    parameter CLK_FREQ = 300;

    logic [15:0] counter;

    // State transitions with clock and reset
    always_ff @ (posedge Clk or posedge Reset) begin
        if (Reset) begin
            curr_state <= INIT1;
        end else begin
            if (curr_state == NEW_WAIT_BEFORE_LEVEL1 || 
                curr_state == NEW_WAIT_BEFORE_LEVEL2 || 
                curr_state == NEW_WAIT_BEFORE_LEVEL3 ||
                curr_state == INIT1) begin
                if (counter < CLK_FREQ) begin
                    counter <= counter + 1;
                end else begin
                    counter <= 0;
                    curr_state <= next_state;
                end
            end else begin
                curr_state <= next_state;
                counter <= 0;
            end
        end
    end

    // Determine the next state
    always_comb begin
        case (curr_state)
            INIT1:
                if (counter >= CLK_FREQ) next_state = INIT2;
                else next_state = INIT1;

            INIT2:
                if (keycode[0] != 8'h00) next_state = NEW_WAIT_BEFORE_LEVEL1;
                else next_state = INIT2;

                
            NEW_WAIT_BEFORE_LEVEL1:
                if (counter >= CLK_FREQ) next_state = LEVEL1;
                else next_state = NEW_WAIT_BEFORE_LEVEL1;

            LEVEL1:
                if (Level1_End) next_state = NEW_WAIT_BEFORE_LEVEL2;
                else next_state = LEVEL1;

            NEW_WAIT_BEFORE_LEVEL2:
                if (counter >= CLK_FREQ) next_state = WAIT_STATE1;
                else next_state = NEW_WAIT_BEFORE_LEVEL2;

            LEVEL2:
                if (Level2_End && CoinCollected_Level2) next_state = NEW_WAIT_BEFORE_LEVEL3;
                else next_state = LEVEL2;

            NEW_WAIT_BEFORE_LEVEL3:
                if (counter >= CLK_FREQ) next_state = WAIT_STATE2;
                else next_state = NEW_WAIT_BEFORE_LEVEL3;

            LEVEL3:
                if (Level3_End && CoinCollected_Level3) next_state = WAIT_STATE3;
                else next_state = LEVEL3;

            GAME_OVER:
                next_state = GAME_OVER;

            WAIT_STATE1: next_state = LEVEL2;
            WAIT_STATE2: next_state = LEVEL3;
            WAIT_STATE3: next_state = GAME_OVER;

            default: next_state = INIT1;
        endcase
    end

    // Set active signals for each state
    always_comb begin
        Init1_Active = (curr_state == INIT1);
        Init2_Active = (curr_state == INIT2);
        Level1_Active = (curr_state == LEVEL1);
        Level2_Active = (curr_state == LEVEL2);
        Level3_Active = (curr_state == LEVEL3);
        Wait_State1 = (curr_state == WAIT_STATE1);
        Wait_State2 = (curr_state == WAIT_STATE2);
        Wait_State3 = (curr_state == WAIT_STATE3);
        Wait_Before_Level1 = (curr_state == NEW_WAIT_BEFORE_LEVEL1);
        Wait_Before_Level2 = (curr_state == NEW_WAIT_BEFORE_LEVEL2);
        Wait_Before_Level3 = (curr_state == NEW_WAIT_BEFORE_LEVEL3);
        game_final = (curr_state == GAME_OVER);
        CoinCollected2 = CoinCollected_Level2;
        CoinCollected3 = CoinCollected_Level3;
    end
endmodule