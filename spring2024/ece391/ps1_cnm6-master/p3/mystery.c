/*
 * tab:2
 *
 * mystery.c
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
 * Author:        Aamir Hasan
 * Version:       1
 * Creation Date: Sun Aug 30 2020
 * Filename:      mystery.c
 * History:
 *    AH    1    Sun Aug 30 2020
 *        First written.
 */

#include "mystery.h"

int32_t mystery_c(uint32_t opcode, uint32_t x, uint32_t y){

  //------- YOUR CODE HERE -------
  switch (opcode) { //Case statement for operations
    case 0:
        // Operation 1: Memory Access
        // Retrieves an integer value from a calculated memory address.
        // The address computed by adding 'y' multiplied by 4 to 'x'.
        return *((int32_t *)(x + y * 4)); 
    case 1:
        // Operation 2: Math
        // Computes an expression by multiplying 'y' by 8, adding 'x', and then subtracting 'y'.
        return (x + y * 8) - y;
    case 2:
        // Operation 3: Modulus Operation
        // Returns the remainder of 'x' divided by 'y'.
        return x % y;
    default:
        // Default: Invalid
        // Returns error code (0xBAD) for unrecognized opcode
        return 0xBAD;
  }
  //------------------------------
}
