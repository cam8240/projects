/*
 * tab:4
 *
 * input.c - source file for input control to maze game
 *
 * "Copyright (c) 2004-2009 by Steven S. Lumetta."
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
 * Version:       5
 * Creation Date: Thu Sep  9 22:25:48 2004
 * Filename:      input.c
 * History:
 *    SL    1    Thu Sep  9 22:25:48 2004
 *        First written.
 *    SL    2    Sat Sep 12 14:34:19 2009
 *        Integrated original release back into main code base.
 *    SL    3    Sun Sep 13 03:51:23 2009
 *        Replaced parallel port with Tux controller code for demo.
 *    SL    4    Sun Sep 13 12:49:02 2009
 *        Changed init_input order slightly to avoid leaving keyboard in odd state on failure.
 *    SL    5    Sun Sep 13 16:30:32 2009
 *        Added a reasonably robust direct Tux control for demo mode.
 */

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/io.h>
#include <termio.h>
#include <termios.h>
#include <unistd.h>

#include "assert.h"
#include "input.h"
#include "maze.h"

#include "module/tuxctl-ioctl.h"

/* set to 1 and compile this file by itself to test functionality */
#define TEST_INPUT_DRIVER  1

/* set to 1 to use tux controller; otherwise, uses keyboard input */
#define USE_TUX_CONTROLLER 1

/* stores original terminal settings */
static struct termios tio_orig;

/* set variable for tux*/
#define UP_TUX 0x0010
#define DOWN_TUX 0x0020
#define LEFT_TUX 0x0040
#define RIGHT_TUX 0x0080
#define S_TUX 0x0001
#define A_TUX 0x0002
#define B_TUX 0x0004
#define C_TUX 0x0008
int fd_tux;

/* 
 * init_input
 *   DESCRIPTION: Initializes the input controller.  As both keyboard and
 *                Tux controller control modes use the keyboard for the quit
 *                command, this function puts stdin into character mode
 *                rather than the usual terminal mode.
 *   INPUTS: none
 *   OUTPUTS: none
 *   RETURN VALUE: 0 on success, -1 on failure 
 *   SIDE EFFECTS: changes terminal settings on stdin; prints an error
 *                 message on failure
 */
int init_input() {
    struct termios tio_new;

    /*
     * Set non-blocking mode so that stdin can be read without blocking
     * when no new keystrokes are available.
     */
    if (fcntl(fileno(stdin), F_SETFL, O_NONBLOCK) != 0) {
        perror("fcntl to make stdin non-blocking");
        return -1;
    }

    /*
     * Save current terminal attributes for stdin.
     */
    if (tcgetattr(fileno(stdin), &tio_orig) != 0) {
        perror ("tcgetattr to read stdin terminal settings");
        return -1;
    }

    /*
     * Turn off canonical (line-buffered) mode and echoing of keystrokes
     * to the monitor.  Set minimal character and timing parameters so as
     * to prevent delays in delivery of keystrokes to the program.
     */
    tio_new = tio_orig;
    tio_new.c_lflag &= ~(ICANON | ECHO);
    tio_new.c_cc[VMIN] = 1;
    tio_new.c_cc[VTIME] = 0;
    if (tcsetattr(fileno(stdin), TCSANOW, &tio_new) != 0) {
        perror("tcsetattr to set stdin terminal settings");
        return -1;
    }

    /* Return success. */
    return 0;
}

/* 
 * get_command
 *   DESCRIPTION: Reads a command from the input controller.  As some
 *                controllers provide only absolute input (e.g., go
 *                right), the current direction is needed as an input
 *                to this routine.
 *   INPUTS: cur_dir -- current direction of motion
 *   OUTPUTS: none
 *   RETURN VALUE: command issued by the input controller
 *   SIDE EFFECTS: drains any keyboard input
 */
cmd_t get_command(dir_t cur_dir) {
    static dir_t prev_cur = DIR_STOP; /* previous direction sent  */
    static dir_t pushed = DIR_STOP;   /* last direction pushed    */
    static unsigned int prev_tux_button = 0;  // Tracks the previous button state
#if (USE_TUX_CONTROLLER == 0) /* use keyboard control with arrow keys */
    static int state = 0;             /* small FSM for arrow keys */
#endif
    cmd_t command;
    int ch;

    /*
     * If the direction of motion has changed, forget the last
     * direction pushed.  Otherwise, it remains active.
     */
    if (prev_cur != cur_dir) {
        pushed = DIR_STOP;
        prev_cur = cur_dir;
    }
    
    /* Read all characters from stdin. */
    while ((ch = getc(stdin)) != EOF) {

    /* Backquote is used to quit the game. */
    if (ch == '`')
        return CMD_QUIT;
    
#if (USE_TUX_CONTROLLER == 0) /* use keyboard control with arrow keys */
    /*
     * Arrow keys deliver the byte sequence 27, 91, and 'A' to 'D';
     * we use a small finite state machine to identify them.
     */
    if (ch == 27)
        state = 1; 
    else if (ch == 91 && state == 1)
        state = 2;
    else {
        if (state == 2 && ch >= 'A' && ch <= 'D') {
            switch (ch) {
                case 'A': pushed = DIR_UP; break;
                case 'B': pushed = DIR_DOWN; break;
                case 'C': pushed = DIR_RIGHT; break;
                case 'D': pushed = DIR_LEFT; break;
            }
        }
        state = 0;
    }

    
#else
    unsigned int tux_button;
    ioctl(fd_tux, TUX_BUTTONS, &tux_button);
    tux_button &= 0xFF; // Assuming you're only interested in the first 8 bits for direction

    // Only act on button change
    if (tux_button != prev_tux_button) {
        prev_tux_button = tux_button; // Update the previous button state
        // Determine the direction based on the pressed button
        if (UP_TUX & tux_button) {
            pushed = DIR_UP; // Button indicates moving up
        } else if (DOWN_TUX & tux_button) {
            pushed = DIR_DOWN; // Button indicates moving down
        } else if (LEFT_TUX & tux_button) {
            pushed = DIR_LEFT; // Button indicates moving left
        } else if (RIGHT_TUX & tux_button) {
            pushed = DIR_RIGHT; // Button indicates moving right
        } else {
            pushed = DIR_STOP; // No direction button pressed
        }
    }

#endif
    }

    /*
     * Once a direction is pushed, that command remains active
     * until a turn is taken.
     */
    if (pushed == DIR_STOP)
        command = TURN_NONE;
    else
        command = (pushed - cur_dir + NUM_TURNS) % NUM_TURNS;

    return command;
}

/* 
 * shutdown_input
 *   DESCRIPTION: Cleans up state associated with input control.  Restores
 *                original terminal settings.
 *   INPUTS: none
 *   OUTPUTS: none
 *   RETURN VALUE: none 
 *   SIDE EFFECTS: restores original terminal settings
 */
void shutdown_input() {
    (void)tcsetattr(fileno(stdin), TCSANOW, &tio_orig);
}

/* 
 * display_time_on_tux
 *   DESCRIPTION: Show number of elapsed seconds as minutes:seconds
 *                on the Tux controller's 7-segment displays.
 *   INPUTS: num_seconds -- total seconds elapsed so far
 *   OUTPUTS: none
 *   RETURN VALUE: none 
 *   SIDE EFFECTS: changes state of controller's display
 */
// void display_time_on_tux(int num_seconds) {
// #if (USE_TUX_CONTROLLER != 0)
// #error "Tux controller code is not operational yet."
// #endif
// }

#if (TEST_INPUT_DRIVER == 1)
int main() {
    atexit(shutdown_input);
    // cmd_t cmd;
    // dir_t dir = DIR_UP;
    // static const char* const cmd_name[NUM_TURNS] = {
    //     "none", "right", "back", "left"
    // };
    // static const char* const dir_names[4] = {
    //     "up", "right", "down", "left"
    // };

    /* Grant ourselves permission to use ports 0-1023 */
    if (ioperm(0, 1024, 1) == -1) {
        perror("ioperm");
        return 3;
    }

    init_input();


    // Load and Initialize Tux Module
    int ret;
    fd_tux = open("/dev/ttyS0", O_RDWR | O_NOCTTY);
    int ldisc_num = N_MOUSE;
    if ((ret = ioctl(fd_tux, TIOCSETD, &ldisc_num)) == -1 || (ret = ioctl(fd_tux, TUX_INIT, 0)) == -1) {
        perror("tux initialize failed");
        return -1;
    }

    // | x | dp reset | x | LED reset | LED4 | LED3 | LED2 | LED1 |
    unsigned long tux_LED = 0x0F050000; // x.0.x.0

    sleep(2);
    ioctl(fd_tux, TUX_SET_LED, tux_LED);
    sleep(2);
    ioctl(fd_tux, TUX_SET_LED, 0x00001A2B); // x x x x
    sleep(2);
    ioctl(fd_tux, TUX_SET_LED, 0x000F1A2B); // 1 A 2 B
    sleep(2);
    ioctl(fd_tux, TUX_SET_LED, 0x0F0F1A2B); // 1.A.2.B.
    sleep(2);
    ioctl(fd_tux, TUX_SET_LED, 0x070F1A2B); // 1 A.2.B.
    sleep(2);
    ioctl(fd_tux, TUX_SET_LED, 0x010F002B); // 0 0 2 B.
    sleep(2);
    ioctl(fd_tux, TUX_SET_LED, 0x0C031A2B); // x.x.2 B
    sleep(2);
    ioctl(fd_tux, TUX_SET_LED, 0x0C001A2B); // x.x.x x
    sleep(2);

    unsigned int tux_button;
    tux_LED = 0x000F0000; // 0 0 0 0
    int ch; 

    sleep(2);
    while (1)
    {
        ch = getchar();
        if (ch == 'A') {
            break; // Exit the loop
        }
        usleep(10000);
        ioctl(fd_tux, TUX_SET_LED, tux_LED++);
        ioctl(fd_tux, TUX_BUTTONS, &tux_button);
        //Switch statement to control button print statements
        switch (tux_button & 0xFF) {
            case UP_TUX:
                printf("up\n");
                break;
            case DOWN_TUX:
                printf("down\n");
                break;
            case RIGHT_TUX:
                printf("right\n");
                break;
            case LEFT_TUX:
                printf("left\n");
                break;
            case S_TUX:
                printf("S\n");
                break;
            case A_TUX:
                printf("A\n");
                break;
            case B_TUX:
                printf("B\n");
                break;
            case C_TUX:
                printf("C\n");
                break;
            default:
                break;
        }
    }
    shutdown_input();
    return 0;
}
#endif
