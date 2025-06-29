#include "i8259.h"
#include "lib.h"

/* Interrupt masks to determine which interrupts are enabled and disabled */
uint8_t master_mask; /* IRQs 0-7  */
uint8_t slave_mask;  /* IRQs 8-15 */

/* The current IRQ masks for the master and slave PICs */
#define IRQ_MASK 0xFF

uint8_t master_mask= IRQ_MASK;
uint8_t slave_mask = IRQ_MASK;


/* Initialize the 8259 PIC 
i8259_init(void)
Inputs: None
Outputs: none
Effects: Initializes the slave and master PICs by setting up control words and routing. 
         Ensures proper handling of interrupts by configuring both PICs to work together 
         correctly.
*/
void i8259_init(void) {
    // ICW1: Initialization Command Word 1. This command starts the initialization sequence
    outb(ICW1, MASTER_8259_PORT); // Send ICW1 to the master PIC command port
    outb(ICW1, SLAVE_8259_PORT);  // Send ICW1 to the slave PIC command port

    // ICW2: Initialization Command Word 2. This command sets the base address of the IRQ vectors
    outb(ICW2_MASTER, MASTER_8259_DATA); // Set vector offset for master PIC
    outb(ICW2_SLAVE, SLAVE_8259_DATA);   // Set vector offset for slave PIC

    // ICW3: Initialization Command Word 3
    // For slave PIC, it specifies the slave's identity.
    outb(ICW3_MASTER, MASTER_8259_DATA); // Tell Master PIC that slave PIC is at IRQ2
    outb(ICW3_SLAVE, SLAVE_8259_DATA);   // Tell Slave PIC its cascade identity

    // ICW4: Initialization Command Word 4
    outb(ICW4, MASTER_8259_DATA); // Set 8086/88 mode on master PIC
    outb(ICW4, SLAVE_8259_DATA);  // Set 8086/88 mode on slave PIC

    // Enable the IRQ line that connects the master PIC to the slave PIC
    enable_irq(SLAVE_IRQ_NUM); // Enable IRQ line for slave PIC on master PIC
}

/* Enable (unmask) the specified IRQ 
enable_irq(uint32_t irq_num)
Inputs: irq_num - The number of the IRQ that is to be enabled.
Outputs: none
Effects: Enables the specified IRQ by clearing its mask bit in the PIC, allowing 
         the IRQ to trigger its handler when the event occurs.
*/
void enable_irq(uint32_t irq_num) {
    if (irq_num > 15) { // Check if IRQ number is valid (0-15)
        return; // Exit if IRQ number is invalid
    }

    if (irq_num < IRQ_MASTER_MAX) { // Check if the IRQ is handled by the master PIC
        master_mask &= ~(1 << irq_num); // Clear the bit corresponding to irq_num in the master mask
        outb(master_mask, MASTER_8259_DATA); // Update the master PIC's mask register
    } else { // IRQ is handled by the slave PIC
        slave_mask &= ~(1 << (irq_num - 8)); // Clear the bit corresponding to (irq_num - 8) in the slave mask
        outb(slave_mask, SLAVE_8259_DATA); // Update the slave PIC's mask register
    }
}


/* Disable (mask) the specified IRQ 
disable_irq(uint32_t irq_num)
Inputs: irq_num - The number of the IRQ that is to be disabled. Valid IRQ numbers range from 0 to 15.
Outputs: none
Effects: Disables the IRQ specified by irq_num by setting the appropriate mask bit, 
         preventing the IRQ from being recognized by the PIC (Programmable Interrupt Controller).
*/
void disable_irq(uint32_t irq_num) {
    if (irq_num > 15) { // Check if IRQ number is valid (0-15)
        return; // Exit if IRQ number is out of range
    }

    if (irq_num < IRQ_MASTER_MAX) { // Check if the IRQ is for the master PIC
        master_mask |= (1 << irq_num); // Set the bit corresponding to irq_num in the master mask
        outb(master_mask, MASTER_8259_DATA); // Update the master PIC's mask register to disable the IRQ
    } else { // IRQ is for the slave PIC
        slave_mask |= (1 << (irq_num - 8)); // Set the bit corresponding to (irq_num - 8) in the slave mask
        outb(slave_mask, SLAVE_8259_DATA); // Update the slave PIC's mask register to disable the IRQ
    }
}


/* Send end-of-interrupt signal for the specified IRQ 
send_eoi(uint32_t irq_num)
Inputs: irq_num - The number of the IRQ for which the end-of-interrupt signal is to be sent.
Outputs: none
Effects: Sends an EOI (End of Interrupt) message to the PIC to indicate that the interrupt handling has been 
         completed, allowing other interrupts to be processed.
*/
void send_eoi(uint32_t irq_num) {
    if(irq_num > 15){ // Validate the IRQ number to ensure it's within the valid range (0-15)
        return; // Exit function if the IRQ number is invalid
    }
    if (irq_num >= IRQ_MASTER_MAX) {
        // If the IRQ number is for the slave PIC, send an EOI to both the slave and the master PIC
        outb(EOI | (irq_num - IRQ_MASTER_MAX), SLAVE_8259_PORT); // Send EOI to slave PIC adjusted for IRQs 8-15
        outb(EOI | 2, MASTER_8259_PORT);  // Send EOI to master PIC, specifically to the line connecting to the slave PIC
    } else {
        // If the IRQ number is for the master PIC, send an EOI directly to the master PIC
        outb(EOI | irq_num, MASTER_8259_PORT); // Send EOI to master PIC using the IRQ number
    }
}
