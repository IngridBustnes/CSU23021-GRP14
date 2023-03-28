#include "hardware/regs/addressmap.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/timer.h"
#include "hardware/regs/m0plus.h"

.syntax unified                                                 @ Specify unified assembly syntax
.cpu    cortex-m0plus                                           @ Specify CPU type is Cortex M0+
.thumb                                                          @ Specify thumb assembly for RP2040
.global main_asm                                                @ Provide program starting address to the linker
.align 4                                                        @ Specify code alignment

.equ    DFLT_STATE_STRT, 1            @ Specify the value to start flashing
.equ    DFLT_STATE_STOP, 0            @ Specify the value to stop flashing
.equ    DFLT_ALARM_TIME, 1000000      @ Specify the default alarm timeout

.equ    GPIO_BTN_DN_MSK, 0x00040000   @ Bit-18 for falling-edge event on GP20
.equ    GPIO_BTN_EN_MSK, 0x00400000   @ Bit-22 for falling-edge event on GP21
.equ    GPIO_BTN_UP_MSK, 0x04000000   @ Bit-26 for falling-edge event on GP22

.equ    GPIO_BTN, 21                  @ Specify pin for button 
.equ    GPIO_BTN_EN,  21              @ Specify pin for the "enter" button
.equ    GPIO_BTN_UP,  22              @ Specify pin for the "up" button
.equ    GPIO_LED_PIN, 28              @ Specify pin for the built-in LED
.equ    GPIO_DIR_IN,   0              @ Specify input direction for a GPIO pin
.equ    GPIO_DIR_OUT,  1              @ Specify output direction for a GPIO pin

.equ    LED_VAL_ON,    1              @ Specify value that turns the LED "on"
.equ    LED_VAL_OFF,   0              @ Specify value that turns the LED "off"

.equ    GPIO_ISR_OFFSET, 0x74         @ GPIO is int #13 (vector table entry 29)
.equ    ALRM_ISR_OFFSET, 0x40         @ ALARM0 is int #0 (vector table entry 16)

.equ    SLEEP_TIME, 1000000           @ Specify the time to sleep in microseconds
.equ    DOT, 300                      @ Specify the time for a dot in microseconds

@ Entry point to the ASM portion of the program
main_asm:
    bl    init_buttons                   @ Call the subroutine to initialise the GPIO pins for the buttons
    bl    install_alrm_isr               @ Call the subroutine to install the alarm ISR into the vector table
    bl    install_button_isr             @ Call the subroutine to install the button ISR into the vector table

game_reboot:
    movs  r2, #0                         @ Set the initial state to 0
    movs  r4, #1                         @ Boolean to check if level has been selected
    bl    level_choice                   @ Call the subroutine to choose the level
    bl    player_select                  @ Call the subroutine to update that player has chosen a level

level_not_selected:
    bl    process_input                  @ Call the subroutine to check for level selected in morse code
    cmp   r4, #0                         @ Check if the level has been selected
    beq   level_not_selected             @ If not, loop back to the start of the subroutine
    bl    player_select2                 @ Call the subroutine to update that player has chosen a level

begin:
    cmp    r4, #0                        @ Check if the level has been selected  
    bne    skip                          @ If so, skip the subroutine 
    movs   r4, #1                        @ Boolean to check if level has been selected
    bl     get_level                     @ Call the subroutine to get the level
    cmp    r0, #1                        @ Check if the level is 1
    beq    level1                        @ If so, jump to the subroutine for level 1
    cmp    r0, #2                        @ Check if the level is 2
    beq    level2                        @ If so, jump to the subroutine for level 2
    cmp    r0, #-1                       @ Check if something went wrong
    beq    end                           @ If so, jump to the end of the game 

level1:
    bl      level_1                     @ Call the subroutine for level 1
    b       level_selected              @ Jump to the subroutine to update that the level has been selected

level2:
    bl      level_2                     @ Call the subroutine for level 2
    b       level_selected              @ Jump to the subroutine to update that the level has been selected

level_selected:
    movs    r5, #3                      @ Dot or dash entered
    movs    r6, #0                      @ Seconds passed

skip:
    bl      new_alarm                   @ Call the subroutine to set a new alarm
    wfi                                 @ Wait for an interrupt
    bl      retrieve_input              @ Call the subroutine to retrieve the input
    cmp     r5, #3                      @ Check if button has been pressed
    beq     skip2                       @ If not, skip the subroutine
    movs    r5, #0                      @ Reset the value to check if button has been pressed

skip2:
    bl      progress_next               @ Call the subroutine to progress to the next level
    cmp     r0, #1                      @ Check if the level has been completed
    beq     level_completed             @ If so, jump to the subroutine to update that the level has been completed
    cmp     r0, #2                      @ Check if the level has been failed
    beq     game_reboot                 @ If so, jump to the subroutine to update that the level has been failed
    b       begin                       @ Loop back to the start of the subroutine

end:
    bl      get_level                   @ Call the subroutine to get the level
    cmp     r0, #1                      @ Check if the level is 1
    beq     level1_end                  @ If so, jump to the subroutine to update that the level has been completed
    cmp     r0, #2                      @ Check if the level is 2
    beq     level2_end                  @ If so, jump to the subroutine to update that the level has been completed

level1_end:
    bl       correct_sequence           @ Call the subroutine to display the correct sequence
    movs     r0, #2                     @ Set the level to 2
    bl       set_level                  @ Call the subroutine to set the level
    b        level_end                  @ Jump to the subroutine to update that the level has been completed

level2_end:
    bl       correct_sequence           @ Call the subroutine to display the correct sequence
    movs     r0, #3                     @ Set the level to 3
    bl       set_level                  @ Call the subroutine to set the level
    b        level_end                  @ Jump to the subroutine to update that the level has been completed

level_end:
    bl      begin_game                  @ Call the subroutine to update that the game has been completed
    b       begin                       @ Loop back to the start of the subroutine

game_won:
    bl     winner                       @ Call the subroutine to display the winner message
    b      game_reboot                  @ Loop back to the start of the subroutine

game_lost:
    bl     loser                        @ Call the subroutine to display the loser message
    b      game_reboot                  @ Loop back to the start of the subroutine

@ Get the level input from the GPIO pin
process_input:
    push    {lr}                        @ Save the return address

    bl    init_input                    @ Call the subroutine to initialise the GPIO pin for the input
    movs  r5, #3                        @ Dot or dash entered
    movs  r6, #0                        @ Seconds passed

incomplete_input:
    bl    new_alarm                     @ Call the subroutine to set a new alarm
    wfi                                 @ Wait for an interrupt
    bl    retrieve_input                @ Call the subroutine to retrieve the input
    cmp   r5, #3                        @ Check if button has been pressed
    beq   skip3                         @ If not, skip the subroutine
    movs  r5, #0                        @ Reset the value to check if button has been pressed

skip3:
    cmp   r6, #2                        @ Check if the input has been completed
    bne   incomplete_input              @ If not, loop back to the start of the subroutine

    cmp   r0, #1                        @ Check if the input is a dot
    beq   level_1_input                 @ If so, jump to the subroutine to update that the input is a dot
    cmp   r0, #2                        @ Check if the input is a dash
    beq   level_2_input                 @ If so, jump to the subroutine to update that the input is a dash
    cmp   r0, #-1                       @ Check if something went wrong
    beq   invalid_input                 @ If so, jump to the subroutine to update that the input is invalid

level_1_input:
    ldr   r0, =1                        @ Load the value 1 into r0
    b     level_input_entered           @ Jump to the subroutine to update that the input has been entered

level_2_input:
    ldr   r0, =2                        @ Load the value 2 into r0
    b     level_input_entered           @ Jump to the subroutine to update that the input has been entered

invalid_input:
    bl    invalid_input_entered         @ Call the subroutine to update that the input is invalid
    b     game_reboot                   @ Loop back to the start of the subroutine

level_input_entered:
    bl    set_level                    @ Call the subroutine to set the level
    bl    init_input                   @ Call the subroutine to initialise the GPIO pin for the input
    movs  r4, #0                       @ Boolean to check if level has been selected

    pop    {pc}                        @ Return to the main function

@ Get morse code input from the GPIO pin
retrieve_input:
    push    {lr}                        @ Save the return address

    cmp     r5, #1                      @ Check if the button has been pressed
    beq     add_dot                     @ If so, jump to the subroutine to add a dot to the input
    cmp     r5, #2                      @ Check if the button has been pressed
    beq     add_dash                    @ If so, jump to the subroutine to add a dash to the input

    b       input_entered               @ Jump to the subroutine to update that the input has been entered

add_dot:
    ldr     r0, =1                      @ Load the value 1 into r0
    bl      input_handler               @ Call the subroutine to add the input to the input array
    b       input_entered               @ Jump to the subroutine to update that the input has been entered

add_dash:
    ldr     r0, =2                      @ Load the value 2 into r0
    bl      input_handler               @ Call the subroutine to add the input to the input array
    b       input_entered               @ Jump to the subroutine to update that the input has been entered

input_entered:
    pop    {pc}                        @ Return to the main function

@ Initialize the GPIO pins for the buttons
init_buttons:
    push    {lr}                                                @ Store the link register to the stack as we will call the init_btns subroutine   

    movs    r0, #GPIO_BTN                                       @ This value is the button pin on the PI PICO board
    bl      asm_gpio_init                                       @ Call the subroutine to initialise the GPIO pin specified by r0
    movs    r0, #GPIO_BTN                                       @ This value is the "enter button" pin on the PI PICO board
    movs    r1, #GPIO_DIR_IN                                    @ We want this GPIO pin to be setup as an input pin
    bl      asm_gpio_set_dir                                    @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
    movs    r0, #GPIO_BTN                                       @ This value is the button pin on the PI PICO board
    bl      asm_gpio_set_irq                                    @ Call this subroutine to enable rising and falling-edge interrupt on the pin specified by r0

    pop     {pc}                                                @ Pop the link register from the stack to the program counter

@ Set a new alarm and enable the alarm interrupt
new_alarm:
    push  {lr}                                                  @ Save the return address on the stack

    @ Get the current timer count from (TIMER_BASE + TIMER_TIMELR_OFFSET) register
    ldr   r1, =(TIMER_BASE + TIMER_TIMELR_OFFSET)               @ Get the address of the timer load register
    ldr   r2, [r1]                                              @ Load the value of the timer load register

    @ Add the time delay you want to wait for to the current timer count
    movs  r1, r5                                                @ Get the value of the alarm time
    add   r1, r1, r2                                            @ Add the value of the alarm time to the timer load register

    @ Push the updated value to (TIMER_BASE + TIMER_ALARM0_OFFSET)
    ldr   r2, =(TIMER_BASE + TIMER_ALARM0_OFFSET)               @ Get the address of the alarm register
    str   r1, [r2]                                              @ Store the value of the timer load register in the alarm register.     
    @ Enable alarm timer interrupts using the (TIMER_BASE + TIMER_INTE_OFFSET) register
    ldr   r1, =(TIMER_BASE + TIMER_INTE_OFFSET)                 @ Get the address of the alarm register. Enable the alarm
    ldr   r2, [r1]                                              @ Load the value of the alarm register
    ldr   r1, =0x1                                              @ Get the offset 
    orrs  r2, r2, r1                                            @ Set the bit in the alarm register 
    ldr   r1, =(TIMER_BASE + TIMER_INTE_OFFSET)                 @ Get the address of the alarm register
    str   r2, [r1]                                              @ Store the value of the alarm register 
    pop   {pc}   

@ Install the alarm ISR into the vector table and enable the alarm interrupt
install_alrm_isr:                               
    ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)            @ Get the address of the vector table
    ldr     r1, [r2]                                        @ Load the value of the vector table                   
    movs    r2, #ALRM_ISR_OFFSET                            @ Get the offset of the alarm ISR
    add     r2, r1                                          @ Add the offset to the base address of the vector table
    ldr     r0, =alrm_isr                                   @ Load the address of the alarm ISR
    str     r0, [r2]                                        @ Store the address of the alarm ISR in the vector table
    
    @ Disable alrm isr by writing a 1 to (PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)                                                        @ Disable ALARM0 IRQ 
    ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)       @ Get the address of the interrupt clear-pending register
    ldr     r1, [r2]                                        @ Load the value of the interrupt clear-pending register
    movs    r2, #0x1                                        @ Get the offset 
    orrs    r1, r1, r2                                      @ Set the bit in the interrupt clear-pending register
    ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)       @ Get the address of the interrupt clear-pending register
    str     r1, [r2]                                        @ Store the value of the interrupt clear-pending register
    
    @ Enable alrm isr by writing  a 1 to (PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)                                                        @ Enable ALARM0 IRQ
    ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)       @ Get the address of the interrupt set-enable register
    ldr     r1, [r2]                                        @ Load the value of the interrupt set-enable register
    movs    r2, #0x1                                        @ Get the offset
    orrs    r1, r1, r2                                      @ Set the bit in the interrupt set-enable register
    ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)       @ Get the address of the interrupt set-enable register
    str     r1, [r2]                                        @ Store the value of the interrupt set-enable register
    bx     lr                                               @ Return to the main function 

@ Service the pending interrupt from the ALARM0 TIMER
.thumb_func 
alrm_isr:
    push    {lr}                                            @ Store the link register to the stack as we will call nested subroutines

    @ Disable pending interrupt from TIMER by writing correct value to (TIMER_BASE + TIMER_INTR_OFFSET)
    ldr     r2, =(TIMER_BASE + TIMER_INTR_OFFSET)
    movs    r1, #1
    str     r1, [r2]

    cmp     r7, #0                                          @ Indicate button being held
    bne     gpio_in_progress                                @ If the button is being held, jump to the subroutine to indicate that the button is being held
    cmp     r5, #3                                          @ Indicate button being held
    beq     gpio_in_progress                                @ If the button is being held, jump to the subroutine to indicate that the button is being held                                    

    ldr     r3, =1                                          @ Get the value of 1
    add     r6, r6, r3                                      @ Increment the value of the counter

gpio_in_progress:
    pop    {pc}                                             @ Pop the link register from the stack to the program counter

@ Install the button ISR into the vector table and enable the button interrupt
install_button_isr:
    ldr    r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)             @ Get the address of the vector table
    ldr    r1, [r2]                                         @ Load the value of the vector table
    movs   r2, #GPIO_ISR_OFFSET                             @ Get the offset of the button ISR
    adds   r2, r1                                           @ Add the offset to the base address of the vector table
    ldr    r0, =gpio_isr                                    @ Load the address of the button ISR
    str    r0, [r2]                                         @ Store the address of the button ISR in the vector table
    
    @ Disable gpio isr by writing 8192 (2^13) to (PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)                                                        @ Disable BUTTON IRQ
    ldr    r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)        @ Get the address of the interrupt clear-pending register
    ldr    r1, =0x2000                                      @ Load the value of the interrupt clear-pending register
    str    r1, [r2]                                         @ Store the value of the interrupt clear-pending register
    
    @ Enable gpio isr by writing 8192 (2^13) to (PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)                                                        @ Enable BUTTON IRQ
    ldr    r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)        @ Get the address of the interrupt set-enable register
    ldr    r1, = 0x2000                                     @ Load the value of the interrupt set-enable register
    str    r1, [r2]                                         @ Store the value of the interrupt set-enable register
    
    bx     lr    
    
    b       main_asm                                            @ Infinite loop

@ Service the pending interrupt from the GPIO
@ Returns the time difference between rising and falling edge in ms in r4
.thumb_func                                                     @ Required for all interrupt service routines
gpio_isr:
    push    {lr}                                                @ Store the link register to the stack as we will call the svc_isr routine

    ldr     r6, =0                                              @ Interrupt counter

    ldr     r2, =(IO_BANK0_BASE + IO_BANK0_PROC0_INTS2_OFFSET)  @ Read the interrupt status event from the (IO_BANK0_BASE + IO_BANK0_PROC0_INTS2_OFFSET) register
    ldr     r1, [r2]                                            @ Load the value of the interrupt status event from the (IO_BANK0_BASE + IO_BANK0_PROC0_INTS2_OFFSET) register
    ldr     r0, =0x2000                                         @ Get the offset of the button ISR
    str     r0, [r2]                                            @ Clear the interrupt status event from the (IO_BANK0_BASE + IO_BANK0_PROC0_INTS2_OFFSET) register

    ldr     r2,=GPIO_BTN_RISE_MSK                               @ Detect rising edge
    cmp     r1, r2                                              @ Compare the interrupt status event with the offset of the button ISR
    beq     rising_edge                                         @ If the interrupt status event is equal to the offset of the button ISR, jump to the subroutine to indicate that the button has been pressed

    ldr     r2, =GPIO_BTN_FALL_MSK                              @ Detect falling edge
    cmp     r1, r2                                              @ Compare the interrupt status event with the offset of the button ISR                                              
    beq     falling_edge                                        @ If the interrupt status event is equal to the offset of the button ISR, jump to the subroutine to indicate that the button has been released
    b       input_entered_complete                              @ If the interrupt status event is not equal to the offset of the button ISR, jump to the subroutine to indicate that the button has been released

rising_edge: 
    ldr     r2, =(IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)        @ Disable the pending interrupt from GPIO by writing the correct value to (IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)
    ldr     r1, =GPIO_BTN_RISE_MSK                              @ Disable the pending interrupt from GPIO by writing the correct value to (IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)
    str     r1, [r2]                                            @ Disable the pending interrupt from GPIO by writing the correct value to (IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)

    bl      get_time                                            @ Get the current time in ms
    movs    r7, r0                                              @ Start time

    b       input_entered_complete                              @ If the interrupt status event is not equal to the offset of the button ISR, jump to the subroutine to indicate that the button has been released

falling_edge:
    ldr     r2, =(IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)        @ Disable the pending interrupt from GPIO by writing the correct value to (IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)
    ldr     r1, =GPIO_BTN_FALL_MSK                              @ Disable the pending interrupt from GPIO by writing the correct value to (IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)
    str     r1, [r2]                                            @ Disable the pending interrupt from GPIO by writing the correct value to (IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)
    
    bl      get_time                                            @ Get the current time in ms
    movs    r1, r7                                              @ Load the start time into r1
    bl      get_time_diff                                       @ Get the time difference between the start time and the current time in ms
    movs    r7, r0                                              @ Store the time difference between the start time and the current time in ms in r7
    bl      watchdog_update                                     @ Update the watchdog timer
    
    movs    r0, r7                                              @ Load the time difference between the start time and the current time in ms into r0
    movs    r7, #0                                              @ Reset time 
    cmp     r0, #DOT                                            @ Check if the time difference between the start time and the current time in ms is equal to DOT
    blt     input_dot                                           @ If the time difference between the start time and the current time in ms is less than DOT, jump to the subroutine to indicate that the button has been pressed for DOT ms
    bge     input_dash                                          @ If the time difference between the start time and the current time in ms is greater than or equal to DOT, jump to the subroutine to indicate that the button has been pressed for DASH ms
    b       input_entered_complete                              @ Input done 

input_dot:
    ldr    r5, =1                                               @ Load 1 into r5
    b      input_entered_complete                               @ Input done

input_dash:
    ldr    r5, =2                                               @ Load 2 into r5
    b      input_entered_complete                               @ Input done

input_entered_complete:
    pop     {pc}                                                @ Return from the interrupt service routine
    

@ Set data alignment
.data
    .align 4
