### P1 Solution

1.
- Choose the graphics mode and the desired dimensions for the main display area and the status bar. The dimensions will represent the values set in the VGA registers.
- Use the line compare register to set the boundary between the main display area and the status bar. This register divides the screen into two regions by resetting the current scan line address to 0 when the line counter matches the line compare value.
    - Bits 0-7 are set in the line compare register.
    - Bit 8 is set in the overflow register.
    - Bit 9 is set in the maximum scan line register.
- Adjust the preset row scan field to manage how the main window scrolls. This field determines how many scan lines the display is scrolled upwards. Setting this allows the top window (main display area) to scroll while keeping the bottom window (status bar) static, as the bottom window has a preset row scan value of 0.
- Use the start address high and start address low registers to set the starting address of the main window's display in VGA memory.
    - Start address high and start address low determine the starting address of the video memory to be displayed.
    - Vertical display end defines the last display line before the display starts to wrap.
- Set the offset register to specify a scan line's virtual byte width. This manages how data is fetched from memory and can affect scrolling smoothness and the division between the main and status bar regions.

Constraints:
- The windows may pan together or independently.
- There could be potential delays between I/O operations to allow compatibility across different VGA.
- The valid values for the preset row scan field are constrained by the maximum scan line field.
- The starting display memory address for the bottom window (status bar) is fixed at 0.


2.
- To change the VGA's color palette, write the index of the color being modified to the DAC address write mode register. This index specifies which of the 256 color entries is targeted for the update.
- Each RGB component is 6 bits, allowing values from 0 to 63. Sequentially write the RGB components to the DAC data register by loading the red component, then green, then blue into the palette RAM.
