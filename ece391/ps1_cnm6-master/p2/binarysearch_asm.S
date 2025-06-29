/*
 * tab:2
 *
 * search_asm.S - Implementation of Assembly Recursive DFS
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
 * Creation Date: Fri Aug 30 2020
 * Filename:      search_asm.S
 * History:
 *    AS    1    Fri Aug 30 2020
 *        First written.
 */

.global binarySearch_asm

# Search ASM (Assembly)
# Searches for an element in a BST
# Declaration is in search.h
#
# Registers:
#   eax - Return Value
# 
binarySearch_asm:
  pushl %ebp
  movl %esp, %ebp

  #--- YOUR CODE HERE ---

  # Save registers
  pushl %ebx
  pushl %esi
  pushl %edi

  # Load registers
  movl 8(%ebp), %ebx  # arr
  movl 12(%ebp), %esi # md
  movl 16(%ebp), %edi # low
  movl 20(%ebp), %edx # high

  # low <= high
  movl %edi, %eax
  cmpl %edx, %eax
  jg .Not_found     # Jump to not found

  # mid = (low + high) / 2
  leal (%edi, %edx), %eax
  shrl $1, %eax
  movl %eax, %ecx

  # Access arr[mid], compare with md
  movl (%ebx, %ecx, 4), %eax
  cmpl %esi, %eax
  je .Equal                 # Jump to equal
  jg .Less                  # Jump to less

  # md > arr[mid]
  addl $1, %ecx
  movl %ecx, %edi
  jmp .Recursive            # Jump to recursive

.Less:
  subl $1, %ecx
  movl %ecx, %edx

.Recursive:
  # Recursive call
  pushl %edx # Save registers
  pushl %edi
  pushl %esi
  pushl %ebx
  call binarySearch_asm # Recursive call
  addl $16, %esp
  jmp .End                  # Jump to end

.Equal:
  # Element found
  movl $1, %eax
  jmp .End                  # Jump to end

.Not_found:
  # Element not found
  movl $-1, %eax

.End:
  # Restore registers
  popl %edi
  popl %esi
  popl %ebx
  leave
  ret