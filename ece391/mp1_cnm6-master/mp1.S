# This program is a set of commands for managing blinking characters on a 
# text-mode video display in a Linux kernel module. It allows adding, removing, 
# finding, and synchronizing blinking characters at specified locations on the 
# screen. Functionality includes dynamic memory allocation for managing character 
# attributes, manipulation of video memory for visuals, and linked list operations 
# for tracking multiple blinking characters.


.data					# section declaration

        # Useful offset constants for accessing members of a 
        # struct mp1_blink_struct structure
        LOCATION   = 0    
        ON_CHAR    = 2
        OFF_CHAR   = 3 
        ON_LENGTH  = 4
        OFF_LENGTH = 6
        COUNTDOWN  = 8
        STATUS     = 10
        NEXT       = 12

        STRUCT_SIZE = 16

# Pointer to head of list (initialized to NULL)
mp1_list_head:
        .long   0

.text					# section declaration

# Export the function symbol names

.global mp1_rtc_tasklet
.global mp1_ioctl

# void mp1_poke(void);
#
# Interface: Register-based arguments (not C-style)
#    Inputs: %cl  - The byte you wish to write
#            %eax - Offset from the start of video memory that you wish
#                   to write to
#   Outputs: Text-mode video screen is written to at location %eax with
#            the byte in %cl
# Registers: Clobbers EDX
mp1_poke:
        
	movl    vmem_base_addr(,1),%edx
	movb    %cl,(%edx,%eax,1)
	ret


# void mp1_rtc_tasklet(unsigned long);
#
# Interface: Register-based arguments (not C-style)
#    Inputs: None
#   Outputs: Updates the text-mode video screen based on the list of blinking
#            locations, toggling their display between two characters at specified
#            intervals. Sets %eax to -1 on error, or 0 on success.
# Registers: %esi for list traversal, %eax for general purpose, and %edx
#            indirectly via mp1_poke. Saves and restores %ebp, %ebx, %esi, %edi.
mp1_rtc_tasklet:
    # Start a new stack frame and save callee-saved registers
    pushl %ebp
    movl %esp, %ebp
    pushl %ebx
    pushl %esi
    pushl %edi

    # Load the head of the list into %esi
    movl mp1_list_head, %esi

    # Check if the list is empty
    testl %esi, %esi
    jz tasklet_end  # Jump to the end if list is empty

tasklet_loop:
    # Decrement the countdown
    movw COUNTDOWN(%esi), %ax
    subw $1, %ax
    movw %ax, COUNTDOWN(%esi)

    # Check if countdown has reached zero
    testw %ax, %ax
    jnz next_element  # If countdown is not zero move to the next element

    # Toggle the status
    movw STATUS(%esi), %ax
    xorw $1, %ax  # Toggle between 0 and 1
    movw %ax, STATUS(%esi)

    # Update the countdown based on the new status
    cmpw $0, %ax
    je set_off_length
    movw ON_LENGTH(%esi), %ax
    jmp set_countdown

set_off_length:
    movw OFF_LENGTH(%esi), %ax

set_countdown:
    movw %ax, COUNTDOWN(%esi)

    # Update the character on the screen based on status
    xorl %eax, %eax
    movw LOCATION(%esi), %ax
    # Error handling for location values
    cmpw $1999, %ax         # Compare location with 1999, screen of size (25 rows * 80 columns - 1 = 1999)
    ja tasklet_error
    cmpw $0, %ax
    jb tasklet_error

    movzwl %ax, %eax
    shll $1, %eax  # Multiply the location by 2 for the correct offset
    cmpw $0, STATUS(%esi)
    je put_off_char
    movb ON_CHAR(%esi), %cl
    jmp call_poke

put_off_char:
    movb OFF_CHAR(%esi), %cl

call_poke:
    call mp1_poke

next_element:
    # Move to the next element in the list
    movl NEXT(%esi), %esi
    testl %esi, %esi
    jnz tasklet_loop  # If next is not NULL continue the loop

    jmp tasklet_success

tasklet_error:
        movl $-1, %eax             # Set %eax to -1 to indicate error
        jmp tasklet_end            # Jump to cleanup

tasklet_success:
        xorl %eax, %eax            # Set %eax to 0 to indicate success using xor

tasklet_end:
        # Restore callee-saved registers and end the stack frame
        popl %edi
        popl %esi
        popl %ebx
        leave
        ret


# The jump_table is an array of pointers to functions. It contains addresses 
# of functions, allowing for function lookup and call execution without conditional logic. 
# The table's index correlates with the ioctl command number
jump_table: # Memory table of function addresses
    .long mp1_ioctl_add
    .long mp1_ioctl_remove
    .long mp1_ioctl_find
    .long mp1_ioctl_sync


# int mp1_ioctl(unsigned long arg, unsigned long cmd);
#
# Interface: Stack-based arguments (C-style)
#    Inputs: cmd - The command number, accessed from the stack at 8(%esp).
#   Outputs: Returns -1 if cmd is outside the range 0 to 3, indicating an
#            invalid command. Otherwise, jumps to a function based on cmd
#            without a direct return value from this function.
# Registers: %eax for loading cmd and calculating jump address. Does
#            not save any callee-saved registers as it does not call any
#            function directly that might modify them.
mp1_ioctl:
    # Load the command number into a register by shifting two stack locations ahead
    movl 8(%esp), %eax

    # Check if the cmd is within 0 to 3
    cmpl $3, %eax
    ja invalid_cmd  # Jump to invalid_cmd if cmd is greater than 3

    # Calculate the address to jump to cmd * 4
    movl jump_table(, %eax, 4), %eax

    # Jump to the function address
    jmp *%eax
    ret

invalid_cmd:
    # Return -1
    movl $-1, %eax
    ret


# int mp1_ioctl_add(unsigned long arg);
#
# Interface: Stack-based arguments (C-style)
#    Inputs: arg - A pointer to a user-space mp1_blink_struct, accessed from the stack.
#   Outputs: Returns -1 on error (allocation failure, invalid pointer, copy failure, or invalid location).
#            Otherwise, adds a new blinking location to the linked list and immediately updates the display.
# Registers: %ebp for stack frame, %esi for newly allocated structure pointer, and %ebx as callee-saved.
#            %eax is used for general purpose calculations and function call results.
# Callee-saved registers (%ebp, %ebx, %esi) are preserved. %eax can be modified.
mp1_ioctl_add:
    pushl %ebp
    movl %esp, %ebp 
    pushl %ebx              # Save ebx
    pushl %esi              # Save esi

    # Allocate memory for new struct
    pushl $STRUCT_SIZE
    call mp1_malloc
    addl $4, %esp           # Clean up stack (pop)
    movl %eax, %esi         # Save pointer to new struct in %esi
    testl %esi, %esi        # Check if allocation was successful
    jz alloc_failure        # Jump to alloc_failure if allocation failed

    movl 8(%ebp), %eax      # Load user-space pointer (arg) into %eax
    testl %eax, %eax        # Check if pointer is NULL
    jz invalid_pointer      # Jump to error handling if pointer is NULL

    # Copy from user-space structure to newly allocated memory
    pushl $STRUCT_SIZE
    pushl %eax              # User-space pointer
    pushl %esi              # Newly allocated memory pointer
    call mp1_copy_from_user
    addl $12, %esp          # Clean up stack (equivalent to three pushes above)
    testl %eax, %eax        # Check if copy was successful
    jnz copy_failure        # Jump to copy_failure if copy failed

    # Check if location is valid (before inserting into linked list and visual update)
    xorl %eax, %eax
    movw LOCATION(%esi), %ax
    cmpw $1999, %ax         # Compare location with max valid value (25 rows * 80 columns - 1 = 1999)
    ja location_failure     # If location is above valid range, jump to failure
    cmpw $0, %ax            # Compare location with min valid value
    jb location_failure     # If location is below valid range, jump to failure

    # Set countdown and status fields
    movw ON_LENGTH(%esi), %ax
    movw %ax, COUNTDOWN(%esi)
    movw $1, STATUS(%esi)

    # Insert structure at head of linked list
    movl mp1_list_head, %eax
    movl %eax, NEXT(%esi)
    movl %esi, mp1_list_head

    # Display character using mp1_poke
    movzwl LOCATION(%esi), %eax # Zero-extend location to EAX for correct offset
    shll $1, %eax               # Multiply location by 2 for byte offset in video memory
    movb ON_CHAR(%esi), %cl     # Load on character for display
    call mp1_poke               # Update display

    xorl %eax, %eax             # Clear %eax
    jmp end_add                 # Skip to end, avoiding failure cleanup

alloc_failure:
    jmp end_add                 # If allocation fails, no need to free, just go to end

invalid_pointer:
copy_failure:
location_failure:
    pushl %esi                  # Push pointer to allocated memory
    call mp1_free               # Free the allocated memory
    addl $4, %esp               # Clean up stack (pop)
    movl $-1, %eax              # Indicate failure, return -1

end_add:
    popl %esi                   # Restore esi
    popl %ebx                   # Restore ebx
    leave                       # Restore ebp and esp
    ret                         # Return to caller


# int mp1_ioctl_remove(unsigned long arg);
#
# Interface: Stack-based arguments (C-style)
#    Inputs: arg - The location to be removed, accessed from the stack at 8(%ebp).
#   Outputs: Returns -1 if the location is invalid or not found in the list. Returns 0 for successful removal.
# Registers: %ebp for stack frame, %ebx for storing arg (location), %esi for current list element,
#            %edi for previous list element, and %edx for comparisons. Saves and restores %ebp, %ebx, %esi, %edi.
#            %eax is used for function call results and return values.
# Callee-saved registers (%ebp, %ebx, %esi, %edi) are preserved. %eax can be modified.
mp1_ioctl_remove:
    pushl %ebp
    movl %esp, %ebp
    pushl %ebx
    pushl %esi
    pushl %edi

    movl 8(%ebp), %ebx          # Load arg (location) into %ebx

    # Validate location against bounds
    cmpw $1999, %bx
    ja remove_invalid
    cmpw $0, %bx
    jb remove_invalid

    call find_function_loop  # Call the helper function

    testl %eax, %eax
    jz remove_not_found           # Element not found

    # Element found in %eax, previous element (if any) in %edx
    movl NEXT(%eax), %ecx
    testl %edx, %edx               # Check if the previous element exists (is not NULL)
    jz remove_from_head
    movl %ecx, NEXT(%edx)          # Update the previous element's next pointer to skip over the current element
    jmp remove_free

remove_from_head:
    movl %ecx, mp1_list_head       # If removing the head element, update the list head to the next element

remove_free:
    pushl %eax
    call mp1_free
    addl $4, %esp             # Clean up stack (pop)
    xorl %eax, %eax
    jmp remove_end

remove_invalid:
    movl $-1, %eax             # Invalid location
    jmp remove_end

remove_not_found:
    movl $-1, %eax             # Element not found
    jmp remove_end

remove_end:
    popl %edi
    popl %esi
    popl %ebx
    leave
    ret


# int mp1_ioctl_find(unsigned long arg);
#
# Interface: Stack-based arguments (C-style)
#    Inputs: arg - A pointer to a user-space mp1_blink_struct, indicating the location to find, accessed from 
#            the stack at 8(%ebp).
#   Outputs: Returns -1 on error (allocation failure, invalid pointer, location out of bounds, or copy failure).
#            On success, copies the found mp1_blink_struct to user-space and returns 0.
# Registers: %ebp for stack frame, %ebx for user-space pointer, %esi for kernel-space memory allocation,
#            %edi for list traversal, and %edx for comparisons. Saves and restores %ebp, %ebx, %esi, %edi.
#            %eax is used for function call results and return values.
# Callee-saved registers (%ebp, %ebx, %esi, %edi) are preserved. %eax can be modified.
mp1_ioctl_find:
    pushl %ebp                  # Save base pointer
    movl %esp, %ebp             # Set base pointer
    pushl %ebx                  # Save ebx
    pushl %esi                  # Save esi
    pushl %edi                  # Save edi

    # Allocate kernel space memory
    pushl $STRUCT_SIZE
    call mp1_malloc
    addl $4, %esp               # Clean up stack (pop)
    movl %eax, %esi             # Store malloc ptr in esi
    testl %esi, %esi
    jz find_fail_d              # Jump to error handling if malloc fails

    # Copy from user-space to allocated memory
    movl 8(%ebp), %ebx          # Load user-space pointer into ebx
    testl %ebx, %ebx
    jz find_fail                # Jump to error handling if null pointer
    pushl $STRUCT_SIZE
    pushl %ebx                  # User-space pointer
    pushl %esi                  # Kernel-space (malloc'd) pointer
    call mp1_copy_from_user
    addl $12, %esp              # Clean up stack (equivalent to three pushes)
    testl %eax, %eax
    jnz find_fail               # Jump to error handling if copy fails

    # Validate location
    xorl %eax, %eax
    movw LOCATION(%esi), %ax
    cmpw $1999, %ax             # Compare location with 1999
    ja find_fail                # Jump to error handling if location too high
    cmpw $0, %ax
    jb find_fail                # Jump to error handling if location too low

    # Search the list for the specified location
    movl mp1_list_head, %edi    # Load head of list
find_loop:
    testl %edi, %edi
    jz find_fail                # If end of list, jump to error
    xorl %edx, %edx
    movw LOCATION(%edi), %dx    # Load location of current element
    cmpw %ax, %dx
    jne find_next               # If not equal move to next element

    # Ensure no overlap between source and destination
    cmpl %ebx, %edi             
    je find_fail                # Jump to error handling if overlap detected

    # Found the structure and copy to user-space
    pushl $STRUCT_SIZE
    pushl %edi                  # Found structure pointer
    pushl %ebx                  # User-space pointer
    call mp1_copy_to_user
    addl $12, %esp              # Clean up stack (equivalent to three pushes)
    testl %eax, %eax
    jnz find_fail               # If copy failed, jump to error

    pushl %esi                  # Free the allocated memory before success return
    call mp1_free
    addl $4, %esp               # Clean up stack (pop)

    xorl %eax, %eax             # Return 0 for success
    jmp find_end

find_next:
    movl NEXT(%edi), %edi       # Move to next element in the list
    jmp find_loop               # Continue loop

find_fail:
    pushl %esi
    call mp1_free
    addl $4, %esp               # Clean up stack

find_fail_d:
    movl $-1, %eax              # Return -1 for error

find_end:
    popl %edi                   # Restore edi
    popl %esi                   # Restore esi
    popl %ebx                   # Restore ebx
    leave
    ret


# int mp1_ioctl_sync(unsigned long arg);
#
# Interface: Stack-based arguments (C-style)
#    Inputs: arg - Packed argument containing two 16-bit locations: the upper 16 bits for the first location
#            and the lower 16 bits for the second location, accessed from the stack at 8(%ebp).
#   Outputs: Returns -1 on error (location out of bounds or not found). On success, synchronizes the toggle
#            attributes of the second location to match those of the first and returns 0.
# Registers: %ebp for stack frame, %eax for argument unpacking, %ebx for the second location, %esi and %edi
#            for list traversal, and %edx for comparisons. Saves and restores %ebp, %ebx, %esi, %edi.
#            %eax is used for return values.
# Callee-saved registers (%ebp, %ebx, %esi, %edi) are preserved. %eax can be modified.
mp1_ioctl_sync:
    pushl %ebp                  # Save base pointer
    movl %esp, %ebp             # Set base pointer
    pushl %ebx                  # Save ebx
    pushl %esi                  # Save esi
    pushl %edi                  # Save edi

    movl 8(%ebp), %ebx          # Load arg (packed two locations) into %ebx

    # Extract the first location from upper 16 bits of %ebx
    movl %ebx, %eax
    shrl $16, %eax              # Shift right to get the first location into the lower 16 bits
    movl %eax, %ebx             # Prepare %ebx for find_function_loop call

    call find_function_loop  # Find the first element
    testl %eax, %eax
    jz sync_error               # Element not found, jump to error
    pushl %eax                  # Save the address of the first element for later use

    # Extract the second location from lower 16 bits of the original argument
    movl 8(%ebp), %eax          # Reload arg
    andl $0xFFFF, %eax          # Mask to get the second location
    movl %eax, %ebx             # Prepare %ebx for find_function_loop call

    call find_function_loop  # Find the second element
    testl %eax, %eax
    jz sync_error_second        # Element not found, jump to error handling for second
    movl %eax, %edi             # Store the address of the second element in %edi

    # Synchronize attributes from the first element (on stack) to the second (%edi)
    popl %esi                   # Retrieve address of the first element
    # Now %esi points to the first element and %edi points to the second element
    
    # Synchronize the attributes
    movw ON_LENGTH(%esi), %cx   # Copy ON_LENGTH
    movw %cx, ON_LENGTH(%edi)
    movw OFF_LENGTH(%esi), %cx  # Copy OFF_LENGTH
    movw %cx, OFF_LENGTH(%edi)
    movw COUNTDOWN(%esi), %cx   # Copy COUNTDOWN
    movw %cx, COUNTDOWN(%edi)
    movb STATUS(%esi), %cl      # Copy STATUS
    movb %cl, STATUS(%edi)

    xorl %eax, %eax             # Return 0 for success
    jmp sync_end

sync_error_second:
    popl %esi                   # Correct stack from saved first element address if second not found

sync_error:
    movl $-1, %eax              # Error, return -1

sync_end:
    popl %edi                   # Restore edi
    popl %esi                   # Restore esi
    popl %ebx                   # Restore ebx
    leave
    ret


# Searches for an element by its location (helper function).
# Input: Location in %ebx
# Output: Address of the element in %eax, Address of the previous element in %edx
find_function_loop:
    pushl %ebp
    movl %esp, %ebp
    pushl %ebx            # Save ebx
    pushl %esi            # Save esi (current element)
    pushl %edi            # Save edi (previous element)

    movl mp1_list_head, %esi    # Start with the head of the list
    xorl %edi, %edi             # Previous element is NULL initially

find_loop_helper:
    testl %esi, %esi
    jz find_not_found           # End of list, element not found

    # Check if the current element's location matches
    xorl %edx, %edx
    movw LOCATION(%esi), %dx    # Load the location of the current element into %dx
    cmpw %bx, %dx
    je find_found               # Element found

    # Move to the next element
    movl %esi, %edi             # Update previous element
    movl NEXT(%esi), %esi       # Move to the next element
    jmp find_loop_helper

find_found:
    movl %esi, %eax             # Element found, return its address in %eax
    movl %edi, %edx             # Return previous element's address in %edx
    jmp find_cleanup

find_not_found:
    xorl %eax, %eax             # Element not found, return NULL in %eax
    xorl %edx, %edx             # No previous element exists

find_cleanup:
    popl %edi
    popl %esi
    popl %ebx
    leave
    ret

.end
