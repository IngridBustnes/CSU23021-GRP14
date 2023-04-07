#include "hardware/regs/addressmap.h"
#include "hardware/regs/io_bank0.h"
#include "hardware/regs/timer.h"
#include "hardware/regs/m0plus.h"

.syntax unified                                                 @ Specify unified assembly syntax
.cpu    cortex-m0plus                                           @ Specify CPU type is Cortex M0+
.thumb                                                          @ Specify thumb assembly for RP2040
.global main_asm                                                @ Provide program begining address to the linker
.align 4                                                        @ Specify code alignment

.equ    DFLT_STATE_STRT, 1                                      @ Specify the value to begin flashing
.equ    DFLT_STATE_STOP, 0                                      @ Specify the value to stop flashing
.equ    DFLT_ALARM_TIME, 1000000                                @ Specify the default alarm timeout
.equ    SLEEP_TIME, 5000

.equ    GPIO_BTN_EN_MSK, 0x00400000                             @ Bit-22 for rising-edge event on GP21
.equ    GPIO_BTN_DN_MSK, 0x00800000                             @ Bit-23 for falling-edge event on GP21

.equ    DOT, 255                                                @ DOT = < 255ms, DASH = > 255ms
                                                                
.equ    GPIO_BTN,  21                                           @ Specify pin for the button
.equ    GPIO_LED_PIN, 28                                        @ Specify pin for the built-in LED
.equ    GPIO_DIR_IN,   0                                        @ Specify input direction for a GPIO pin
.equ    GPIO_DIR_OUT,  1                                        @ Specify output direction for a GPIO pin

.equ    GPIO_ISR_OFFSET, 0x74                                   @ GPIO is int #13 (vector table entry 29)
.equ    ALRM_ISR_OFFSET, 0x40                                   @ ALARM0 is int #0 (vector table entry 16)

/**
    * @author Faith - Progression, Timing and Interrupts 
    * @author Leah - Input Handling and Interrupts
    * @auhtor Martha - Level 1 - 3, Input Handling
    * @author Della - Start Of Game, Level 4, Input Handling
    * @author Inrgid - Morse Code, Input Handling 
    */
 */
@ Entry point to the ASM portion of the program
main_asm:

    bl    init_buttons                                          @ Call the subroutine to initialise the GPIO pins for the buttons
    bl    install_alrm_isr                                      @ Call the subroutine to install the alarm ISR into the vector table
    bl    install_gpio_isr                                      @ Call the subroutine to install the button ISR into the vector table

@ Start game loop
game_reboot:
    movs    r2, #0
    movs    r6, #1                                              
    bl      level_choice                                        @ Display level choice
    bl      player_select                                       @ Level selected
 
level_not_selected:                                             @ Process player input until a valid level is selected
    bl      process_input                                       @ Level input 
    cmp     r6, #0                                              
    bne     level_not_selected                                  @ If level is not selected, loop back to process_input
    bl      player_select2                                      @ Level not selected

begin:                                                          @ Initialize input array and display question for selected level                
    cmp     r6, #0                                              
    bne     no_input_sequence                                                
    movs    r6, #1                                               
    bl      init_input                                                       
    bl      get_level                                           
    cmp     r0, #1
    beq     level1                                     
    cmp     r0, #2
    beq     level2
    cmp     r0, #3
    beq     level3
    cmp     r0, #4
    beq     level4
    cmp     r0, #5
    beq     end

level1:
    bl      level_1                                             @ Display level 1 question                         
    b       level_chosen

level2:
    bl      level_2                                             @ Display level 2 question
    b       level_chosen

level3:
    bl      level_3                                             @ Display level 3 question
    b       level_chosen

level4:
    bl      level_4                                             @ Display level 4 question

level_chosen:                                                   @ Process player input for selected level
    movs    r4, #3                                              @ Dot or dash
    movs    r5, #0                                              @ Number of interrupts/seconds

no_input_sequence:
    bl      new_alarm                                           @ Set the alarm
    wfi                                                         @ Wait for interrupt
    bl      retrieve_input                                      @ Store user input in input array
    cmp     r4, #3                                              @ Check for input sequence
    beq     no_input_sequence1                                  @ Skip if nothing is entered
    movs    r4, #0                                              @ Reset dot or dash

no_input_sequence1:
    bl      progress_next
    cmp     r0, #1
    beq     level_completed
    cmp     r0, #2
    beq     game_reboot
    b       begin
    @ beq     game_over
    @ cmp     r0, #3
    @ beq     game_won
    @ b       begin                                               @ Loop back to begin if input is not completed

end:
    bl        game_won

level_completed:
    bl      get_level
    cmp     r0, #1
    beq     level1_end
	
    cmp     r0, #2
    beq     level2_end

    cmp     r0, #3
    beq     level3_end

    cmp     r0, #4
    beq     level4_end
    
level1_end:
    bl      progress_level
    movs    r0, #2
    bl      set_level
    b       level_end

level2_end:
    bl      progress_level
    movs    r0, #3
    bl      set_level
    b       level_end

level3_end:
    bl      progress_level
    movs    r0, #4
    bl      set_level
    b       level_end

level4_end:
    bl      progress_level
    movs    r0, #5
    bl      set_level
    b       level_end
      
level_end:
    bl      begin_game
    b       begin

game_won:
    bl      winner
    b       game_reboot

game_over: 
    bl      loser             
    b       game_reboot

@ Set up input array and store user input
process_input:
    push    {lr}                                                    @ Save the return address             

    bl      init_input                                              @ Initialize array
    movs    r4, #3                                                  @ Dot or dash
    movs    r5, #0                                                  @ Number of interrupts/seconds
    
incomplete_input:
    bl      new_alarm                                               @ Set the alarm
    wfi                                                             @ Wait for interrupt
    bl      retrieve_input                                          @ Store user input in input array
    cmp     r4, #3                                                  @ Check for input sequence
    beq     no_input_sequence2                                      @ Skip if nothing is entered
    movs    r4, #0                                                  @ Reset dot or dash

no_input_sequence2:
    cmp     r5, #2                                                  @ Check if input is complete, if not loop back to incomplete_input
    bne     incomplete_input 
    
    cmp     r0, #1                                                  @ Input for level 1
    beq     level1_input
    cmp     r0, #2                                                  @ Input for level 2     
    beq     level_2_input
    cmp     r0, #3                                                  @ Input for level 3
    beq     level_3_input
    cmp     r0, #4                                                  @ Input for level 4
    beq     level_4_input
    
    cmp     r0, #5                                                  @ Invalid input
    beq     invalid_input

level1_input:                                                       @ Level 1 input entered in input array        
    ldr     r0, =1  
    b       level_input_entered

level_2_input:                                                      @ Level 2 input entered in input array    
    ldr     r0, =2  
    b       level_input_entered

level_3_input:                                                      @ Level 3 input entered in input array
    ldr     r0, =3  
    b       level_input_entered

level_4_input:                                                      @ Level 4 input entered in input array
    ldr     r0, =4                                
    b       level_input_entered          

invalid_input:                                                      @ Invalid input entered
    bl      invalid_input_entered
    b       game_reboot

level_input_entered:
    bl      set_level                                               @ Set level to the value in r0
    bl      init_input                                              @ Re-initialize input array
    movs    r6, #0

    pop     {pc}                                                    @ Return

@ Collect input from user in morse code and update input array
retrieve_input:
    push    {lr}                                                @ Save the return address

    cmp     r5, #1                                              @ Alarm interrupt = 1
    beq     add_space                                           @ ""

    cmp     r5, #2                                              @ Alarm interrupt = 2
    beq     enter                                               @ "enter" (sumbit input)

    cmp     r4, #1                                              @ GPIO interrupt = 1
    beq     add_dot                                             @ "."

    cmp     r4, #2                                              @ GPIO interrupt = 2
    beq     add_dash                                            @ "-"
    b       input_entered                                       

add_dot:
    ldr     r0, =1                                              @ 1 = "."
    bl      input_handler                                       @ Input += "."
    b       input_entered                                       

add_dash:
    ldr     r0, =2                                              @ 2 = "-"
    bl      input_handler                                       @ Input += "-"
    b       input_entered                                       

add_space:
    ldr     r0, =3                                              @ 3 = " "
    bl      input_handler                                       @ Input += " "
    b       input_entered                                       

enter:
    ldr     r0, =4                                              @ 4 = "enter"
    bl      input_handler                                       @ Input += "enter"
    movs    r6, #0                     

input_entered:
    pop     {pc}                                                @ Return

/*                                      INSTALL INTERRUPTS & INTERRUPT HANDLERS                                      */
@ Subroutine used to setup falling-edge interrupts
init_buttons:
    push    {lr}                                                @ Save the return address on the stack  

    movs    r0, #GPIO_BTN                                       @ This value is the button pin on the PI PICO board
    bl      asm_gpio_init                                       @ Call the subroutine to initialise the GPIO pin specified by r0
    movs    r0, #GPIO_BTN                                       @ This value is the submit input(enter) pin on the PI PICO board
    movs    r1, #GPIO_DIR_IN                                    @ We want this GPIO pin to be setup as an input pin
    bl      asm_gpio_set_dir                                    @ Call the subroutine to set the GPIO pin specified by r0 to state specified by r1
    movs    r0, #GPIO_BTN                                       @ This value is the button pin on the PI PICO board
    bl      asm_gpio_set_irq                                    @ Call this subroutine to enable rising and falling-edge interrupt on the pin specified by r0

    pop     {pc}                                                @ Return

@ Enable alarm timer interrupts and set an alarm
new_alarm:
                                                                @ Enable alarm timer interrupts using the (TIMER_BASE + TIMER_INTE_OFFSET) register
    ldr     r2, =(TIMER_BASE + TIMER_INTE_OFFSET)               @ Get the address of the alarm register. Enable the alarm 
    movs    r1, #1                                              
    str     r1, [r2]                                            @ Store the value in r1 to the address in r2    

    ldr     r2, =(TIMER_BASE + TIMER_TIMELR_OFFSET)             @ Get the address of the timer load register
    ldr     r3, [r2]
    ldr     r1, =DFLT_ALARM_TIME
    add     r1, r3                                              @ Add the time delay you want to wait for to the current timer count
    ldr     r2, =(TIMER_BASE + TIMER_ALARM0_OFFSET)             @ Push the updated value to (TIMER_BASE + TIMER_ALARM0_OFFSET)
    str     r1, [r2]
    
    bx      lr                                                  @ Exit subroutine

@ Sets up the alrm_isr in the RAM vector table and enables the correct interrupt
install_alrm_isr:
    ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)                @ Get the address of the RAM vector table using the (PPB_BASE + M0PLUS_VTOR_OFFSET) register
    ldr     r1, [r2]                                
    movs    r2, #ALRM_ISR_OFFSET                                @ Store the address of the alrm_isr handler to the correct offset for ALARM0 in the vector table
    add     r2, r1
    ldr     r0, =alrm_isr                           
    str     r0, [r2]                                

    ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)           @ Disable alrm isr by writing a 1 to (PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)
    movs    r1, #1 
    str     r1, [r2]

    ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)           @ Enable alrm isr by writing  a 1 to (PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)                                                        @ Enable ALARM0 IRQ

    movs    r1, #1 
    str     r1, [r2]

    bx      lr                                                  @ Exit subroutine

@ Service the pending interrupt from the ALARM0 TIMER
.thumb_func 
alrm_isr:
    push    {lr}                                                @ Save the return address on the stack             
    
    ldr     r2, =(TIMER_BASE + TIMER_INTR_OFFSET)               @ Disable pending interrupt from TIMER by writing correct value to (TIMER_BASE + TIMER_INTR_OFFSET)
    movs    r1, #1
    str     r1, [r2]

    cmp     r7, #0                                              @ Checking for button hold
    bne     gpio_in_progress
    cmp     r4, #3
    beq     gpio_in_progress

    ldr     r3, =1                                              @ Timer interrupts
    add     r5, r5, r3

gpio_in_progress:
    pop     {pc}                                                @ Return

@ Install the button ISR into the vector table and enable the button interrupt
install_gpio_isr:
    ldr     r2, =(PPB_BASE + M0PLUS_VTOR_OFFSET)                @ Get the address of the RAM vector table using the (PPB_BASE + M0PLUS_VTOR_OFFSET) register
    ldr     r1, [r2]                                            
    movs    r2, #GPIO_ISR_OFFSET                                @ Store the address of the gpio_isr handler to the correct offset for GPIO in the vector table
    add     r2, r1
    ldr     r0, =gpio_isr                           
    str     r0, [r2]                                

    ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)           @ Disable the GPIO IRQ by writing the correct value to (PPB_BASE + M0PLUS_NVIC_ICPR_OFFSET)
    ldr     r1, =0x2000           
    str     r1, [r2]            

    ldr     r2, =(PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)           @ Enable the GPIO IRQ by writing the correct value to (PPB_BASE + M0PLUS_NVIC_ISER_OFFSET)
    ldr     r1, =0x2000           
    str     r1, [r2]

    bx      lr                                                  @ Exit subroutine

@ BUTTON interrupt service handler routine
.thumb_func                                                     
gpio_isr:
    push    {lr}                                                @ Save the return address on the stack

    ldr     r5, =0                                              @ Interrupt counter reset

    ldr     r2, =(IO_BANK0_BASE + IO_BANK0_PROC0_INTS2_OFFSET)  @ Get the address of the interrupt status register
    ldr     r1, [r2]
    ldr     r0, =0x2000
    str     r0, [r2]

    ldr     r2,=GPIO_BTN_EN_MSK
    cmp     r1, r2                                              @ Check if rising edge interrupt
    beq     rising_edge

    ldr     r2, =GPIO_BTN_DN_MSK
    cmp     r1, r2                                              @ Check if falling edge interrupt
    beq     falling_edge
    b       input_entered_complete

rising_edge: 
    ldr     r2, =(IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)        @ Disable the pending interrupt from GPIO by writing the correct value to (IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)
    ldr     r1, =GPIO_BTN_EN_MSK
    str     r1, [r2]

    bl      get_time
    movs    r7, r0                                              @ Time stored in r7

    b       input_entered_complete

falling_edge:
    ldr     r2, =(IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)        @ Disable the pending interrupt from GPIO by writing the correct value to (IO_BANK0_BASE + IO_BANK0_INTR2_OFFSET)
    ldr     r1, =GPIO_BTN_DN_MSK
    str     r1, [r2]
    
    bl      get_time
    movs    r1, r7                                              @ start_time
    bl      get_time_diff
    movs    r7, r0
    bl      watchdog_update
    
    movs    r0, r7
    movs    r7, #0                                              @ Time reset
    cmp     r0, #DOT                                            @ < 255ms = DOT, > 255ms = DASH
    blt     input_dot                                           
    bge     input_dash                                               
    b       input_entered_complete                                           

input_dot:
    ldr     r4, =1                                              @ 1 = "."
    b       input_entered_complete

input_dash:
    ldr     r4, =2                                              @ 2 = "-"

input_entered_complete:

    pop     {pc}                                                @ Exit ISR   

@ Set data alignment
.data
    .align 4
