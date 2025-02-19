/*
 * tab:4
 *
 * mazegame.c - main source file for ECE398SSL maze game (F04 MP2)
 *
 * "Copyright (c) 2004 by Steven S. Lumetta."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE AUTHOR OR THE UNIVERSITY OF ILLINOIS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT  OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, 
 * EVEN IF THE AUTHOR AND/OR THE UNIVERSITY OF ILLINOIS HAS BEEN ADVISED 
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE AUTHOR AND THE UNIVERSITY OF ILLINOIS SPECIFICALLY DISCLAIM ANY 
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE 
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND NEITHER THE AUTHOR NOR
 * THE UNIVERSITY OF ILLINOIS HAS ANY OBLIGATION TO PROVIDE MAINTENANCE, 
 * SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Author:        Steve Lumetta
 * Version:       1
 * Creation Date: Fri Sep 10 09:57:54 2004
 * Filename:      mazegame.c
 * History:
 *    SL    1    Fri Sep 10 09:57:54 2004
 *        First written.
 */

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#include "blocks.h"
#include "maze.h"
#include "modex.h"
#include "text.h"

// New Includes and Defines
#include <linux/rtc.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/io.h>
#include <termios.h>
#include <pthread.h>
#include "module/tuxctl-ioctl.h"


#define BACKQUOTE 96
#define UP        65
#define DOWN      66
#define RIGHT     67
#define LEFT      68

int press_button_flag = 0;
unsigned int tux_button;
#define UP_TUX 0x0010
#define DOWN_TUX 0x0020
#define LEFT_TUX 0x0040
#define RIGHT_TUX 0x0080
#define S_TUX 0x0001
#define A_TUX 0x0002
#define B_TUX 0x0004
#define C_TUX 0x0008

/*
 * If NDEBUG is not defined, we execute sanity checks to make sure that
 * changes to enumerations, bit maps, etc., have been made consistently.
 */
#if defined(NDEBUG)
#define sanity_check() 0
#else
static int sanity_check();
#endif


/* a few constants */
#define PAN_BORDER      5  /* pan when border in maze squares reaches 5    */
#define MAX_LEVEL       10 /* maximum level number                         */

/* outcome of each level, and of the game as a whole */
typedef enum {GAME_WON, GAME_LOST, GAME_QUIT} game_condition_t;

/* structure used to hold game information */
typedef struct {
    /* parameters varying by level   */
    int number;                  /* starts at 1...                   */
    int maze_x_dim, maze_y_dim;  /* min to max, in steps of 2        */
    int initial_fruit_count;     /* 1 to 6, in steps of 1/2          */
    int time_to_first_fruit;     /* 300 to 120, in steps of -30      */
    int time_between_fruits;     /* 300 to 60, in steps of -30       */
    int tick_usec;         /* 20000 to 5000, in steps of -1750 */
    
    /* dynamic values within a level -- you may want to add more... */
    unsigned int map_x, map_y;   /* current upper left display pixel */
} game_info_t;

static game_info_t game_info;

/* local functions--see function headers for details */
static int prepare_maze_level(int level);
static void move_up(int* ypos);
static void move_right(int* xpos);
static void move_down(int* ypos);
static void move_left(int* xpos);
static int unveil_around_player(int play_x, int play_y);
static void *rtc_thread(void *arg);
static void *keyboard_thread(void *arg);
static void *tux_thread(void *arg);
static int *tux_time(clock_t start_time, clock_t end_time, int *counter);

/* 
 * prepare_maze_level
 *   DESCRIPTION: Prepare for a maze of a given level.  Fills the game_info
 *          structure, creates a maze, and initializes the display.
 *   INPUTS: level -- level to be used for selecting parameter values
 *   OUTPUTS: none
 *   RETURN VALUE: 0 on success, -1 on failure
 *   SIDE EFFECTS: writes entire game_info structure; changes maze;
 *                 initializes display
 */
static int prepare_maze_level(int level) {
    int i; /* loop index for drawing display */
    
    /*
     * Record level in game_info; other calculations use offset from
     * level 1.
     */
    game_info.number = level--;

    /* Set per-level parameter values. */
    if ((game_info.maze_x_dim = MAZE_MIN_X_DIM + 2 * level) > MAZE_MAX_X_DIM)
        game_info.maze_x_dim = MAZE_MAX_X_DIM;
    if ((game_info.maze_y_dim = MAZE_MIN_Y_DIM + 2 * level) > MAZE_MAX_Y_DIM)
        game_info.maze_y_dim = MAZE_MAX_Y_DIM;
    if ((game_info.initial_fruit_count = 1 + level / 2) > 6)
        game_info.initial_fruit_count = 6;
    if ((game_info.time_to_first_fruit = 300 - 30 * level) < 120)
        game_info.time_to_first_fruit = 120;
    if ((game_info.time_between_fruits = 300 - 60 * level) < 60)
        game_info.time_between_fruits = 60;
    if ((game_info.tick_usec = 20000 - 1750 * level) < 5000)
        game_info.tick_usec = 5000;

    /* Initialize dynamic values. */
    game_info.map_x = game_info.map_y = SHOW_MIN;

    /* Create a maze. */
    if (make_maze(game_info.maze_x_dim, game_info.maze_y_dim, game_info.initial_fruit_count) != 0)
        return -1;
    
    /* Set logical view and draw initial screen. */
    set_view_window(game_info.map_x, game_info.map_y);
    for (i = 0; i < SCROLL_Y_DIM; i++)
        (void)draw_horiz_line (i);

    /* Return success. */
    return 0;
}

/* 
 * move_up
 *   DESCRIPTION: Move the player up one pixel (assumed to be a legal move)
 *   INPUTS: ypos -- pointer to player's y position (pixel) in the maze
 *   OUTPUTS: *ypos -- reduced by one from initial value
 *   RETURN VALUE: none
 *   SIDE EFFECTS: pans display by one pixel when appropriate
 */
static void move_up(int* ypos) {
    /*
     * Move player by one pixel and check whether display should be panned.
     * Panning is necessary when the player moves past the upper pan border
     * while the top pixels of the maze are not on-screen.
     */
    if (--(*ypos) < game_info.map_y + BLOCK_Y_DIM * PAN_BORDER && game_info.map_y > SHOW_MIN) {
        /*
         * Shift the logical view upwards by one pixel and draw the
         * new line.
         */
        set_view_window(game_info.map_x, --game_info.map_y);
        (void)draw_horiz_line(0);
    }
}

/* 
 * move_right
 *   DESCRIPTION: Move the player right one pixel (assumed to be a legal move)
 *   INPUTS: xpos -- pointer to player's x position (pixel) in the maze
 *   OUTPUTS: *xpos -- increased by one from initial value
 *   RETURN VALUE: none
 *   SIDE EFFECTS: pans display by one pixel when appropriate
 */
static void move_right(int* xpos) {
    /*
     * Move player by one pixel and check whether display should be panned.
     * Panning is necessary when the player moves past the right pan border
     * while the rightmost pixels of the maze are not on-screen.
     */
    if (++(*xpos) > game_info.map_x + SCROLL_X_DIM - BLOCK_X_DIM * (PAN_BORDER + 1) &&
        game_info.map_x + SCROLL_X_DIM < (2 * game_info.maze_x_dim + 1) * BLOCK_X_DIM - SHOW_MIN) {
        /*
         * Shift the logical view to the right by one pixel and draw the
         * new line.
         */
        set_view_window(++game_info.map_x, game_info.map_y);
        (void)draw_vert_line(SCROLL_X_DIM - 1);
    }
}

/* 
 * move_down
 *   DESCRIPTION: Move the player right one pixel (assumed to be a legal move)
 *   INPUTS: ypos -- pointer to player's y position (pixel) in the maze
 *   OUTPUTS: *ypos -- increased by one from initial value
 *   RETURN VALUE: none
 *   SIDE EFFECTS: pans display by one pixel when appropriate
 */
static void move_down(int* ypos) {
    /*
     * Move player by one pixel and check whether display should be panned.
     * Panning is necessary when the player moves past the right pan border
     * while the bottom pixels of the maze are not on-screen.
     */
    if (++(*ypos) > game_info.map_y + SCROLL_Y_DIM - BLOCK_Y_DIM * (PAN_BORDER + 1) && 
        game_info.map_y + SCROLL_Y_DIM < (2 * game_info.maze_y_dim + 1) * BLOCK_Y_DIM - SHOW_MIN) {
        /*
         * Shift the logical view downwards by one pixel and draw the
         * new line.
         */
        set_view_window(game_info.map_x, ++game_info.map_y);
        (void)draw_horiz_line(SCROLL_Y_DIM - 1);
    }
}

/* 
 * move_left
 *   DESCRIPTION: Move the player right one pixel (assumed to be a legal move)
 *   INPUTS: xpos -- pointer to player's x position (pixel) in the maze
 *   OUTPUTS: *xpos -- decreased by one from initial value
 *   RETURN VALUE: none
 *   SIDE EFFECTS: pans display by one pixel when appropriate
 */
static void move_left(int* xpos) {
    /*
     * Move player by one pixel and check whether display should be panned.
     * Panning is necessary when the player moves past the left pan border
     * while the leftmost pixels of the maze are not on-screen.
     */
    if (--(*xpos) < game_info.map_x + BLOCK_X_DIM * PAN_BORDER && game_info.map_x > SHOW_MIN) {
        /*
         * Shift the logical view to the left by one pixel and draw the
         * new line.
         */
        set_view_window(--game_info.map_x, game_info.map_y);
        (void)draw_vert_line (0);
    }
}

/* 
 * unveil_around_player
 *   DESCRIPTION: Show the maze squares in an area around the player.
 *                Consume any fruit under the player.  Check whether
 *                player has won the maze level.
 *   INPUTS: (play_x,play_y) -- player coordinates in pixels
 *   OUTPUTS: none
 *   RETURN VALUE: 1 if player wins the level by entering the square
 *                 0 if not
 *   SIDE EFFECTS: draws maze squares for newly visible maze blocks,
 *                 consumed fruit, and maze exit; consumes fruit and
 *                 updates displayed fruit counts
 */
static int unveil_around_player(int play_x, int play_y) {
    int x = play_x / BLOCK_X_DIM; /* player's maze lattice position */
    int y = play_y / BLOCK_Y_DIM;
    int i, j;            /* loop indices for unveiling maze squares */

    /* Check for fruit at the player's position. */
    (void)check_for_fruit (x, y);

    /* Unveil spaces around the player. */
    for (i = -1; i < 2; i++)
        for (j = -1; j < 2; j++)
            unveil_space(x + i, y + j);
        unveil_space(x, y - 2);
        unveil_space(x + 2, y);
        unveil_space(x, y + 2);
        unveil_space(x - 2, y);

    /* Check whether the player has won the maze level. */
    return check_for_win (x, y);
}

#ifndef NDEBUG
/* 
 * sanity_check 
 *   DESCRIPTION: Perform checks on changes to constants and enumerated values.
 *   INPUTS: none
 *   OUTPUTS: none
 *   RETURN VALUE: 0 if checks pass, -1 if any fail
 *   SIDE EFFECTS: none
 */
static int sanity_check() {
    /* 
     * Automatically detect when fruits have been added in blocks.h
     * without allocating enough bits to identify all types of fruit
     * uniquely (along with 0, which means no fruit).
     */
    if (((2 * LAST_MAZE_FRUIT_BIT) / MAZE_FRUIT_1) < NUM_FRUIT_TYPES + 1) {
        puts("You need to allocate more bits in maze_bit_t to encode fruit.");
        return -1;
    }
    return 0;
}
#endif /* !defined(NDEBUG) */

// Shared Global Variables
int quit_flag = 0;
int winner= 0;
int next_dir = UP;
int play_x, play_y, last_dir, dir;
int move_cnt = 0;
int fd;
int fd_tux;
unsigned long data;
static struct termios tio_orig;
static pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t cv = PTHREAD_COND_INITIALIZER;

/*
 * keyboard_thread
 *   DESCRIPTION: Thread that handles keyboard inputs
 *   INPUTS: none
 *   OUTPUTS: none
 *   RETURN VALUE: none
 *   SIDE EFFECTS: none
 */
static void *keyboard_thread(void *arg) {
    char key;
    int state = 0;
    // Break only on win or quit input - '`'
    while (winner == 0) {        
        // Get Keyboard Input
        key = getc(stdin);
        
        // Check for '`' to quit
        if (key == BACKQUOTE) {
            press_button_flag = 1; // Added to avoid a deadlock when using keyboard and tux
            quit_flag = 1;
            pthread_cond_signal(&cv); // Unlocks tux mutex when game ends
            break;
        }
        
        // Compare and Set next_dir
        // Arrow keys deliver 27, 91, ##
        if (key == 27) {
            state = 1;
        }
        else if (key == 91 && state == 1) {
            state = 2;
        }
        else {    
            if (key >= UP && key <= LEFT && state == 2) {
                pthread_mutex_lock(&mtx);
                switch(key) {
                    case UP:
                        next_dir = DIR_UP;
                        break;
                    case DOWN:
                        next_dir = DIR_DOWN;
                        break;
                    case RIGHT:
                        next_dir = DIR_RIGHT;
                        break;
                    case LEFT:
                        next_dir = DIR_LEFT;
                        break;
                }
                pthread_mutex_unlock(&mtx);
            }
            state = 0;
        }
    }

    return 0;
}

/*
 * tux_thread
 *   DESCRIPTION: Manages direction updates based on TUX controller input within a game, 
 *                ensuring thread safety. Waits for button press signals, updates movement 
 *                direction accordingly, and continues until game termination conditions are met
 *   INPUTS: none
 *   OUTPUTS: none
 *   RETURN VALUE: Returns NULL
 *   SIDE EFFECTS: none
 */
static void *tux_thread(void *arg){
    // Ensure that the thread continues to run until either a win condition is met or a quit command is received
    while (winner == 0 && quit_flag == 0) {
        // Lock the mutex to ensure exclusive access to shared variables
        pthread_mutex_lock(&mtx);
        // Wait for a button press signal while avoiding unnecessary wakeups
        while (!press_button_flag && winner == 0 && quit_flag == 0) {
            pthread_cond_wait(&cv, &mtx);
        }
        // Process the button press if the flag is set
        if (press_button_flag) {
            // Mask the tux_button value to determine the direction
            switch (tux_button & 0x000000F0) { // 11110000 (Button movement uses top 4 bits based on MTCP_BIOC_EVENT)
                case UP_TUX:
                    next_dir = DIR_UP;
                    break;
                case DOWN_TUX:
                    next_dir = DIR_DOWN;
                    break;
                case RIGHT_TUX:
                    next_dir = DIR_RIGHT;
                    break;
                case LEFT_TUX:
                    next_dir = DIR_LEFT;
                    break;
                default:
                    break;
            }
            // Reset the button press flag after handling
            press_button_flag = 0;
        }
        // Unlock the mutex to allow other threads to proceed
        pthread_mutex_unlock(&mtx);
    }
    
    return NULL;
}


/* some stats about how often we take longer than a single timer tick */
static int goodcount = 0;
static int badcount = 0;
static int total = 0;

// Defines a structure for representing a color with red, green, and blue components
typedef struct {
    int r; // Red component
    int g; // Green component
    int b; // Blue component
} Color;

/*
 * generate_rainbow_color
 *   DESCRIPTION: Generates a color from a predefined rainbow palette, blending it 
 *                with another color from the palette. The function cycles through 
 *                the palette, gradually modifying the color output in a cyclical 
 *                fashion to create a rainbow effect
 *   INPUTS: none
 *   OUTPUTS: none
 *   RETURN VALUE: A Color structure containing the RGB components of the generated 
 *                 rainbow color after blending the current color with another color 
 *   SIDE EFFECTS: The function uses a static variable to keep track of the current 
 *                 color index within the rainbow palette, which is updated with each call
 */
Color generate_rainbow_color() {
    static Color rainbow_colors[] = {
        {0xff, 0x00, 0x00},
        {0xff, 0x30, 0x00},
        {0xff, 0x59, 0x00},
        {0xff, 0x9d, 0x00},
        {0xff, 0xbd, 0x00},
        {0xff, 0xee, 0x00},
        {0xe5, 0xff, 0x00},
        {0xa5, 0xff, 0x00},
        {0x8c, 0xff, 0x00},
        {0x40, 0xff, 0x00},
        {0x10, 0xff, 0x00},
        {0x00, 0xff, 0x08},
        {0x00, 0xff, 0x38},
        {0x00, 0xff, 0x62},
        {0x00, 0xff, 0xae},
        {0x00, 0xff, 0xce},
        {0x00, 0xff, 0xe5},
        {0x00, 0xdf, 0xff},
        {0x00, 0xa4, 0xff},
        {0x00, 0x84, 0xff},
        {0x00, 0x40, 0xff},
        {0x1e, 0x00, 0xff},
        {0x4e, 0x00, 0xff},
        {0x77, 0x00, 0xff},
        {0xc8, 0x00, 0xff},
        {0xe2, 0x00, 0xff},
        {0xff, 0x00, 0xe6},
        {0xff, 0x00, 0xa2},
        {0xff, 0x00, 0x82},
        {0xff, 0x00, 0x5d},
        {0xff, 0x00, 0x2f},
        {0xff, 0x00, 0x0f},
    };
    static size_t current_color = 0;

    Color next_color = rainbow_colors[current_color];
    
    //CALC! Sets current color to next and then mods with size of array to loop
    current_color = (current_color + 1) % (sizeof(rainbow_colors) / sizeof(rainbow_colors[0]));

    return next_color;
}

/*
 * tux_time
 *   DESCRIPTION: Calculates elapsed time in minutes and seconds from start and end clock ticks.
 *   INPUTS: start_time, end_time - clock ticks marking the start and end of a period
 *           counter - array to store calculated minutes and seconds
 *   OUTPUTS: Populates counter[0] with minutes and counter[1] with seconds of elapsed time
 *   RETURN VALUE: Returns pointer to the counter array
 *   SIDE EFFECTS: Modifies the content of the counter array provided as input
 */
int* tux_time(clock_t start_time, clock_t end_time, int* counter) {
    if (!counter) return NULL; // Error checking for null pointer
    // Calculate elapsed time in seconds
    int elapsed_time = (int)((end_time - start_time) / CLOCKS_PER_SEC);
    // Calculate minutes and seconds from elapsed time
    int minutes = elapsed_time / 60;
    int seconds = elapsed_time % 60;
    // Assign calculated time to the counter array
    counter[0] = minutes;
    counter[1] = seconds;
    return counter; // Return the modified counter array
}

int fruit_value; // Holds the count of fruits

/*
 * rtc_thread
 *   DESCRIPTION: Thread that handles updating the screen
 *   INPUTS: none
 *   OUTPUTS: none
 *   RETURN VALUE: none
 *   SIDE EFFECTS: none
 */
static void *rtc_thread(void *arg) {
    int ticks = 0;
    int level;
    int ret;
    int open[NUM_DIRS];
    int need_redraw = 0;
    int goto_next_level = 0;

    unsigned char background_save_buffer[144]; // 12 * 12 area is size of buffer 
    unsigned char full_text_buffer[FONT_AREA]; // Holds the area of the fruit font text


    // Loop over levels until a level is lost or quit.
    for (level = 1; (level <= MAX_LEVEL) && (quit_flag == 0); level++) {
        // Prepare for the level.  If we fail, just let the player win.
        if (prepare_maze_level(level) != 0)
            break;
        goto_next_level = 0;

        // Start the player at (1,1)
        play_x = BLOCK_X_DIM;
        play_y = BLOCK_Y_DIM;

        // move_cnt tracks moves remaining between maze squares.
        // When not moving, it should be 0.
        move_cnt = 0;

        // Initialize last direction moved to up
        last_dir = DIR_UP;

        // Initialize the current direction of motion to stopped
        dir = DIR_STOP;
        next_dir = DIR_STOP;

        // Show maze around the player's original position
        (void)unveil_around_player(play_x, play_y);

        // Draw the player's block at the new position:
        // play_x, play_y: Current position of the player
        // get_player_block(last_dir): Retrieves the graphical block for the player based 
        //on the last direction the player moved
        // get_player_mask(last_dir): Retrieves the mask for the player sprite, which determines 
        // transparency and collision properties based on the last direction
        // player_mask: A buffer used internally by draw_mask_block for applying 
        // the mask onto the sprite before drawing

        // Initialize clock
        clock_t startTime;
        startTime = clock();

        //Initialize colors
        int text_color = 0x00; // Text color starts low and increments by 1 each level
        int background_color = 0x0B - level; // Background color starts high and decrements by 1 each level

        time_t start_time, end_time; // Time variables for tracking operation durations
        start_time = time(NULL); // Initializes 'startTime' to the current time

        // get first Periodic Interrupt
        ret = read(fd, &data, sizeof(unsigned long));

        // Store the current graphical content at the player's position into background_save_buffer
        hold_full_block(play_x, play_y, background_save_buffer);
        // Capture and store the graphical area for text, above the player, into full_text_buffer
        hold_full_text_block(play_x, play_y - FONT_HEIGHT, full_text_buffer);
        // Draw the player's sprite at the current position, using the appropriate block and mask for the last direction
        draw_player_block(play_x, play_y, get_player_block(last_dir), get_player_mask(last_dir)); 
        show_screen();
        // Restore the text graphical content above the player's position from full_text_buffer
        draw_full_text_block(play_x, play_y - FONT_HEIGHT, full_text_buffer);
        // Restore the original graphical content at the player's position from background_save_buffer
        draw_full_block(play_x, play_y, background_save_buffer);


        while ((quit_flag == 0) && (goto_next_level == 0)) {
            // Wait for Periodic Interrupt
            ret = read(fd, &data, sizeof(unsigned long));
            time(&end_time); // Capture the current time
            int fruit, length;
            fruit = fruit_count(); // Get the current fruit count from an external function
            length = (int)difftime(end_time, start_time); // Calculate the duration since 'startTime' in seconds

            show_status_bar(level, fruit, length, text_color, background_color); //Initialize status update
            update_level_color(level); // Set wall palette colors using the helper function

            static time_t start_fruit_time = 0;
            static int fruit_effect_active = 0;
            int new_fruit_value = check_for_fruit(play_x / BLOCK_X_DIM, play_y / BLOCK_Y_DIM);
            if (new_fruit_value != 0) {
                fruit_value = new_fruit_value; // Update the fruit value to the newly collected fruit
                fruit_effect_active = 1;       // Mark the fruit effect as active
                start_fruit_time = time(NULL); // Record the start time of the fruit effect
                need_redraw = 1;               // Indicate that the screen needs to be redrawn
            }
            // Calculate the duration since the fruit effect started, if active
            if (fruit_effect_active) {
                time_t end_fruit_time;
                time(&end_fruit_time); // Capture the current time
                int length = (int)difftime(end_fruit_time, start_fruit_time); // Calculate the duration in seconds
                
                // Fruit effect lasts for 4 seconds
                if (length >= 4) {
                    // Fruit effect duration has elapsed
                    fruit_effect_active = 0; // Deactivate the fruit effect
                }
            }
   
            // Update tick to keep track of time.  If we missed some
            // interrupts we want to update the player multiple times so
            // that player velocity is smooth
            ticks = data >> 8;    

            total += ticks;

            static unsigned int start_color_ticks = 0;
            static int color_change_active = 0;
            static unsigned int palette_ticks = 0; 
            static unsigned int next_color_change_ticks = 0; 
            #define TICKS_PER_COLOR_CHANGE 10 // Define the number of ticks after which the color should change

            // Update palette_ticks with the latest ticks value
            palette_ticks += ticks;

            // Check if the color change mechanism is not active
            if (!color_change_active) {
                // If not active, initialize the color change mechanism
                // Set start_color_ticks to the current tick count
                start_color_ticks = palette_ticks;
                next_color_change_ticks = start_color_ticks + TICKS_PER_COLOR_CHANGE;
                // Mark the color change mechanism as active
                color_change_active = 1;
            }

            if (palette_ticks >= next_color_change_ticks) {
                // Change the color
                Color player_color = generate_rainbow_color();
                set_palette(PLAYER_CENTER_COLOR, player_color.r, player_color.g, player_color.b);
                // Calculate the next target tick count for color change, adjusting for potential drift
                next_color_change_ticks += TICKS_PER_COLOR_CHANGE;
            }

            // If the system is completely overwhelmed we better slow down:
            if (ticks > 8) ticks = 8;

            if (ticks > 1) {
                badcount++;
            }
            else {
                goodcount++;
            }

            while (ticks--) {

                // Load the button status into tux_button
                ioctl(fd_tux, TUX_BUTTONS, &tux_button);
                // Directly check the button status to set press_button_flag
                if (tux_button != 0x00) {
                    press_button_flag = 1;
                } else {
                    press_button_flag = 0;
                }
                // Lock the mutex to wake up the tux thread if a button is pressed
                pthread_mutex_lock(&mtx);
                // Use the value of press_button_flag to decide whether to signal the condition variable
                if (press_button_flag == 1) {
                    pthread_cond_signal(&cv);
                }
                pthread_mutex_unlock(&mtx);

                // Lock the mutex
                pthread_mutex_lock(&mtx);

                // Check to see if a key has been pressed
                if (next_dir != dir) {
                    // Check if new direction is backwards...if so, do immediately
                    if ((dir == DIR_UP && next_dir == DIR_DOWN) ||
                        (dir == DIR_DOWN && next_dir == DIR_UP) ||
                        (dir == DIR_LEFT && next_dir == DIR_RIGHT) ||
                        (dir == DIR_RIGHT && next_dir == DIR_LEFT)) {
                        if (move_cnt > 0) {
                            if (dir == DIR_UP || dir == DIR_DOWN)
                                move_cnt = BLOCK_Y_DIM - move_cnt;
                            else
                                move_cnt = BLOCK_X_DIM - move_cnt;
                        }
                        dir = next_dir;
                    }
                }
                // New Maze Square!
                if (move_cnt == 0) {
                    // The player has reached a new maze square; unveil nearby maze
                    // squares and check whether the player has won the level.
                    if (unveil_around_player(play_x, play_y)) {
                        pthread_mutex_unlock(&mtx);
                        goto_next_level = 1;
                        break;
                    }
                
                    // Record directions open to motion.
                    find_open_directions (play_x / BLOCK_X_DIM, play_y / BLOCK_Y_DIM, open);
        
                    // Change dir to next_dir if next_dir is open 
                    if (open[next_dir]) {
                        dir = next_dir;
                    }
    
                    // The direction may not be open to motion...
                    //   1) ran into a wall
                    //   2) initial direction and its opposite both face walls
                    if (dir != DIR_STOP) {
                        if (!open[dir]) {
                            dir = DIR_STOP;
                        }
                        else if (dir == DIR_UP || dir == DIR_DOWN) {    
                            move_cnt = BLOCK_Y_DIM;
                        }
                        else {
                            move_cnt = BLOCK_X_DIM;
                        }
                    }
                }
                // Unlock the mutex
                pthread_mutex_unlock(&mtx);
        
                if (dir != DIR_STOP) {
                    // move in chosen direction
                    last_dir = dir;
                    move_cnt--;    
                    switch (dir) {
                        case DIR_UP:    
                            move_up(&play_y);    
                            break;
                        case DIR_RIGHT: 
                            move_right(&play_x); 
                            break;
                        case DIR_DOWN:  
                            move_down(&play_y);  
                            break;
                        case DIR_LEFT:  
                            move_left(&play_x);  
                            break;
                    }
                    need_redraw = 1;
                }
            }

            // Variables for minutes and seconds digits
            unsigned char minute_0, minute_1, second_0, second_1, led_mask;
            unsigned long led_time;
            // Define the decimal point location
            unsigned char decimal_location = 0x0004; // Mask of 0100 for 3rd decimal location
            // Create an array to hold time
            int elapsed_time[2];
            // Get time calculations from helper function
            tux_time(startTime, clock(), elapsed_time);
            // Calculate individual digits of minutes and seconds
            minute_1 = (unsigned char)(elapsed_time[0] / 10); // Tens digit of minutes
            minute_0 = (unsigned char)(elapsed_time[0] % 10); // Ones digit of minutes
            second_1 = (unsigned char)(elapsed_time[1] / 10); // Tens digit of seconds
            second_0 = (unsigned char)(elapsed_time[1] % 10); // Ones digit of seconds
            // Determine LED mask based on elapsed minutes (displaying all LEDs if >= 10 minutes)
            if (elapsed_time[0] >= 10) {
                led_mask = 0x000F; // Mask of 1111 for 4 LEDS
            } else {
                led_mask = 0x0007; // Bitmask 0111 for 3 LEDS
            }


            // Construct the argument for setting the LED display
            // Each location is 4 bits so second 0 shifted none, second_1 shifted once, minute_0 shifted twice
            // minute_1 shifted 3 times, led_mask shifted all 4 LEDs, decimal shifted 6 times to 3rd decimal location.
            led_time = ((unsigned long)decimal_location << 24) | ((unsigned long)led_mask << 16) | (minute_1 << 12) | (minute_0 << 8) | (second_1 << 4) | second_0;
            // Set the LEDs to display the elapsed time
            ioctl(fd_tux, TUX_SET_LED, led_time);

            // If the screen needs to be redrawn and there is an active fruit effect
            if (fruit_effect_active && need_redraw) {
                // Store the current state of the blocks and text to buffers before redrawing
                hold_full_block(play_x, play_y, background_save_buffer); // Store the old block into buffer
                // Height at 2 * font height (just to match demo)
                hold_full_text_block(play_x - TEXT_WIDTH / 2 + BLOCK_X_DIM / 2, play_y - 2 * FONT_HEIGHT, full_text_buffer);
                // Fruit value zero indexed so subtract 1
                // Height at 2 * font height (just to match demo)
                draw_full_text(play_x - TEXT_WIDTH / 2 + BLOCK_X_DIM / 2, play_y - 2 * FONT_HEIGHT, destination_buffer, full_text_buffer, fruit_value - 1);
                // Draw the player and the related text with the new fruit effect
                draw_player_block(play_x, play_y, get_player_block(last_dir), get_player_mask(last_dir));
                show_screen(); // Update the screen with the new drawings
                // After showing the updated screen, restore the previous state of the text and block
                // CALC! Centers the fruit text block around play_x and play_y so it appears where the player is on the screen
                // Height at 2 * font height (just to match demo)
                draw_full_text_block(play_x - TEXT_WIDTH / 2 + BLOCK_X_DIM / 2, play_y - 2 * FONT_HEIGHT, full_text_buffer);
                draw_full_block(play_x, play_y, background_save_buffer); // Redraw the old block in the buffer
            } else if (!fruit_effect_active && need_redraw) {
                // If the screen needs to be redrawn but there's no active fruit effect
                hold_full_block(play_x, play_y, background_save_buffer); // Store the old block into buffer
                draw_player_block(play_x, play_y, get_player_block(last_dir), get_player_mask(last_dir)); // Draw the player
                show_screen(); // Update the screen with the new drawings
                draw_full_block(play_x, play_y, background_save_buffer); // Restore the previous state of the block
            }
            need_redraw = 0;
        }    
    }
    if (quit_flag == 0) {
        press_button_flag = 1;
        winner = 1;
        pthread_cond_signal(&cv);
    }
    return 0;
}

/*
 * main
 *   DESCRIPTION: Initializes and runs the two threads
 *   INPUTS: none
 *   OUTPUTS: none
 *   RETURN VALUE: 0 on success, -1 on failure
 *   SIDE EFFECTS: none
 */
int main() {
    int ret;
    struct termios tio_new;
    unsigned long update_rate = 32; /* in Hz */

    pthread_t tid1;
    pthread_t tid2;
    pthread_t tid3;

    // Initialize RTC
    fd = open("/dev/rtc", O_RDONLY, 0);

    // Initialize Tux (discussion slides)
    fd_tux = open("/dev/ttyS0", O_RDWR | O_NOCTTY);
    
    // Enable RTC periodic interrupts at update_rate Hz
    // Default max is 64...must change in /proc/sys/dev/rtc/max-user-freq
    ret = ioctl(fd, RTC_IRQP_SET, update_rate);    
    ret = ioctl(fd, RTC_PIE_ON, 0);

    
    // Error check for tux
    int ldisc_num = N_MOUSE; //(discussion slides)
    if ((ret = ioctl(fd_tux, TIOCSETD, &ldisc_num)) == -1 || (ret = ioctl(fd_tux, TUX_INIT, 0)) == -1) {
        perror("tux initialize failed");
        return -1;
    }

    // Initialize Keyboard
    // Turn on non-blocking mode
    if (fcntl(fileno(stdin), F_SETFL, O_NONBLOCK) != 0) {
        perror("fcntl to make stdin non-blocking");
        return -1;
    }
    
    // Save current terminal attributes for stdin.
    if (tcgetattr(fileno(stdin), &tio_orig) != 0) {
        perror("tcgetattr to read stdin terminal settings");
        return -1;
    }
    
    // Turn off canonical (line-buffered) mode and echoing of keystrokes
    // Set minimal character and timing parameters so as
    tio_new = tio_orig;
    tio_new.c_lflag &= ~(ICANON | ECHO);
    tio_new.c_cc[VMIN] = 1;
    tio_new.c_cc[VTIME] = 0;
    if (tcsetattr(fileno(stdin), TCSANOW, &tio_new) != 0) {
        perror("tcsetattr to set stdin terminal settings");
        return -1;
    }

    // Perform Sanity Checks and then initialize input and display
    if ((sanity_check() != 0) || (set_mode_X(fill_horiz_buffer, fill_vert_buffer) != 0)){
        return 3;
    }

    // Create the threads
    pthread_create(&tid1, NULL, rtc_thread, NULL);
    pthread_create(&tid2, NULL, keyboard_thread, NULL);
    pthread_create(&tid3, NULL, tux_thread, NULL);
    
    // Wait for all the threads to end
    pthread_join(tid1, NULL);
    pthread_join(tid2, NULL);
    pthread_join(tid3, NULL);

    // Shutdown Display
    clear_mode_X();
    
    // Close Keyboard
    (void)tcsetattr(fileno(stdin), TCSANOW, &tio_orig);
        
    // Close RTC
    close(fd);
    // Close TUX
    close(fd_tux);

    // Print outcome of the game
    if (winner == 1) {    
        printf("You win the game! CONGRATULATIONS!\n");
    }
    else if (quit_flag == 1) {
        printf("Quitter!\n");
    }
    else {
        printf ("Sorry, you lose...\n");
    }
    // Return success
    return 0;
}
