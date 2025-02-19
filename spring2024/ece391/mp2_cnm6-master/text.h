/*
 * tab:4
 *
 * text.h - font data and text to mode X conversion utility header file
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
 * Version:       2
 * Creation Date: Thu Sep  9 22:08:16 2004
 * Filename:      text.h
 * History:
 *    SL    1    Thu Sep  9 22:08:16 2004
 *        First written.
 *    SL    2    Sat Sep 12 13:40:11 2009
 *        Integrated original release back into main code base.
 */

#ifndef TEXT_H
#define TEXT_H

/* The default VGA text mode font is 8x16 pixels. */
#define FONT_WIDTH   8
#define FONT_HEIGHT  16

#define TEXT_WIDTH (FONT_WIDTH * 10) // //CALC! 10 characters in array
#define FONT_AREA TEXT_WIDTH * 8 * FONT_HEIGHT //CALC! 8 * 10 characters * 16 Area of fruit text
#define STATUS_BAR_WIDTH 320 // Set screen width
#define STATUS_BAR_HEIGHT (FONT_HEIGHT + 2) //CALC! 16 char height + 2 padding
#define TRANSPARENT_START_INDEX 64 // Start new transparent colors after current colors in palette

/* Standard VGA text font. */
extern unsigned char font_data[256][16]; //CALC! 256 characters 16 bits each

/* CALC! Creates buffer of correct size for status bar (320 screen length * (16 char height + 2 padding)) */
unsigned char buffer[5760];

/* CALC! Creates buffer of correct size for text (8 char length * 10 char * 16 char height) */
extern unsigned char destination_buffer[1280];

/* Outputs text to the status bar using a buffer */
extern void text_to_image(const char * string, unsigned char text_color, unsigned char background_color);

/* Copies a source text into a destination buffer and encodes it */
extern void copy_text(unsigned char * buffer, int fruit_count);


#endif /* TEXT_H */
