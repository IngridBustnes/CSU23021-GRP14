#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#include "pico/stdlib.h"
#include "hardware/pio.h"
#include "hardware/clocks.h"
#include "ws2812.pio.h"

#define IS_RGBW true        // Will use RGBW format
#define NUM_PIXELS 1        // There is 1 WS2812 device in the chain
#define WS2812_PIN 28       // The GPIO pin that the WS2812 connected to
#define alphanumeric_chars 36 // (A-Z)(0-9)


typedef struct morsecode{           // creating morsecode datatype
    char * morsecode;
    char alphanum;
}
morse;

morse alphabet[alphanumeric_chars];

/**
 * @brief Initialises the alphabhet array with Morse code representation for
 *        letters A-Z and numbers 0-9.
 * 
 */
void init_morse(){

    alphabet[0].alphanum='A';
    alphabet[1].alphanum='B';
    alphabet[2].alphanum='C';
    alphabet[3].alphanum='D';
    alphabet[4].alphanum='E';
    alphabet[5].alphanum='F';
    alphabet[6].alphanum='G';
    alphabet[7].alphanum='H';
    alphabet[8].alphanum='I';
    alphabet[9].alphanum='J';
    alphabet[10].alphanum='K';
    alphabet[11].alphanum='L';
    alphabet[12].alphanum='M';
    alphabet[13].alphanum='N';
    alphabet[14].alphanum='O';
    alphabet[15].alphanum='P';
    alphabet[16].alphanum='Q';
    alphabet[17].alphanum='R';
    alphabet[18].alphanum='S';
    alphabet[19].alphanum='T';
    alphabet[20].alphanum='U';
    alphabet[21].alphanum='V';
    alphabet[22].alphanum='W';
    alphabet[23].alphanum='X';
    alphabet[24].alphanum='Y';
    alphabet[25].alphanum='Z';
    alphabet[26].alphanum='0';
    alphabet[27].alphanum='1';
    alphabet[28].alphanum='2';
    alphabet[29].alphanum='3';
    alphabet[30].alphanum='4';
    alphabet[31].alphanum='5';
    alphabet[32].alphanum='6';
    alphabet[33].alphanum='7';
    alphabet[34].alphanum='8';
    alphabet[35].alphanum='9';

    alphabet[0].morsecode=".-";
    alphabet[1].morsecode="-...";
    alphabet[2].morsecode="-.-.";
    alphabet[3].morsecode="-..";
    alphabet[4].morsecode=".";
    alphabet[5].morsecode="..-.";
    alphabet[6].morsecode="--.";
    alphabet[7].morsecode="....";
    alphabet[8].morsecode="..";
    alphabet[9].morsecode=".---";
    alphabet[10].morsecode="-.-";
    alphabet[11].morsecode=".-..";
    alphabet[12].morsecode="--";
    alphabet[13].morsecode="-.";
    alphabet[14].morsecode="---";
    alphabet[15].morsecode=".--.";
    alphabet[16].morsecode="--.-";
    alphabet[17].morsecode=".-.";
    alphabet[18].morsecode="...";
    alphabet[19].morsecode="-";
    alphabet[20].morsecode="..-";
    alphabet[21].morsecode="...-";
    alphabet[22].morsecode=".--";
    alphabet[23].morsecode="-..-";
    alphabet[24].morsecode="-.--";
    alphabet[25].morsecode="--..";
    alphabet[26].morsecode="-----";
    alphabet[27].morsecode=".----";
    alphabet[28].morsecode="..---";
    alphabet[29].morsecode="...--";
    alphabet[30].morsecode="....-";
    alphabet[31].morsecode=".....";
    alphabet[32].morsecode="-....";
    alphabet[33].morsecode="--...";
    alphabet[34].morsecode="---..";
    alphabet[35].morsecode="----.";

}



/**
 * @brief Level #1: Individual characters with their equivalent Morse code provided.
 *        Asks the user to enter the morse code equivalent of a given alphanumeric
 *        charcter.
 * 
 * @return int 
 */
int level_1(){
    int num = rand() %36;
    printf("Enter equivalent Morse code for the following charcter:\n");
    printf("%c \n",alphabet[num].alphanum);
    printf("%s \n",alphabet[num].morsecode);
    return num;
}
/**
 * @brief Level #2: Individual characters without their equivalent Morse code provided.
 *        Same function as level_1 except without giving the morse code equivalent.
 * 
 * @return int 
 */
int level_2(){
    int num = rand() %36;
    printf("Enter equivalent Morse code for the following charcter:\n");
    printf("%c \n",alphabet[num].alphanum);
    return num;
}

int number_of_wins = 0; // Number of wins the player has achieved
int player_lives = 0; // Number of lives the player has
int level_selected = 2; // Level selected by player
int correct_ans = 0; // Number of correct answers the player has entered


int player_lives = 3;       // Player has 3 lives to start with
int correct_answers = 0;    // Player has 0 correct answers to start with
int lives_added = 0;        // Player has 0 lives added to start with
int lives_lost = 0;         // Player has 0 lives lost to start with

//Code for part 4
void print_alphanum_morse(struct morsecode *this, char *input) {

    int i = 0;
    
    //check if morse code
    while (strcmp(input, this[i]->morsecode) != 0 && i < 36) {
        i++;
    }

    char output = malloc(char);

    if (i >= 36)
        output = "?";
    else
        output = this[i]->alphanum;

    
    printf("Morse: %s\nAlphanumerical: %s\n", input, output);
    
    free(output);
}

// Code for part 7.
    // Declare watchdog functions
    void watchdog_update();

    void watchdog_enable(uint32_t delay_ms, bool pause_on_debug);

//

// Code for part 6.

    // Print screen congratulating the player
    void end_screen() {
        printf("\nCONGRATULATIONS!! ^.^ \n You've won the game!"); 
    }

    // Check if 5 correct answers have been entered by player. If yes progress to next level. Otherwise return to level 1/Welcome
    // This function will be part of level 1 - level 2 code 
    if (correct_ans == 5) {
        level_selected = 2;
        printf("YOU ARE NOW MOVING TO LEVEL X!");
    }

//



/**
 * @brief Wrapper function used to call the underlying PIO
 *        function that pushes the 32-bit RGB colour value
 *        out to the LED serially using the PIO0 block. The
 *        function does not return until all of the data has
 *        been written out.
 * 
 * @param pixel_grb The 32-bit colour value generated by urgb_u32()
 */

static inline void put_pixel(uint32_t pixel_grb) {
    pio_sm_put_blocking(pio0, 0, pixel_grb << 8u);
}


/**
 * @brief Function to generate an unsigned 32-bit composit GRB
 *        value by combining the individual 8-bit parameters for
 *        red, green and blue together in the right order.
 * 
 * @param r     The 8-bit intensity value for the red component
 * @param g     The 8-bit intensity value for the green component
 * @param b     The 8-bit intensity value for the blue component
 * @return uint32_t Returns the resulting composite 32-bit RGB value
 */
static inline uint32_t urgb_u32(uint8_t r, uint8_t g, uint8_t b) {
    return  ((uint32_t) (r) << 8)  |
            ((uint32_t) (g) << 16) |
            (uint32_t) (b);
}

// Update RGB LED colour  
void RGB_update(int number_of_lives)
{
    switch (number_of_lives)                                // Switch statement to update RGB LED colour based on number of lives remaining
    {
        case 0:                                             // If player has 0 lives remaining
            // Black
            put_pixel(urgb_u32(0x00, 0x00, 0x00));
            printf("0 lives remaining. GAME OVER");
            break;

        case 1:                                             // If player has 1 life remaining
            // Red
            put_pixel(urgb_u32(0xFF, 0x00, 0x00));
            printf("1 life remaining");
            break;

        case 2:                                             // If player has 2 lives remaining
            // Yellow
            put_pixel(urgb_u32(0xFF, 0xFF, 0x00));
            printf("2 lives remaining");
            break;

        case 3:                                             // If player has 3 lives remaining (Max)
            // Green
            put_pixel(urgb_u32(0x00, 0xFF, 0x00));
            printf("3 lives remaining");
            break;

        default:
            printf("");
            break;
    }

}

// Update player lives 
void update_lives(bool answer_entered)                          // Function to update player lives based on whether the answer entered was correct or not
{
    if (answer_entered == true)                                 // If the answer entered was correct
    {
        printf("Correct. Life Added")                           // Add a life to the player
    
        lives_added++;
        correct_answers++;
        if (player_lives == 3)                                  // If the player has 3 lives(max number of lives), do not add another life
        {
            printf("Max Lives Reached");
        }
        else                                                    // If the player has less than 3 lives, add a life
        {
            player_lives += 1;
            RGB_update(player_lives);
        }
    }
    else                                                        // If the answer entered was incorrect
    {
        printf("Incorrect. Life Lost");                         // Deduct a life from the player
        correct_answers--;
        lives_lost++;
        player_lives -= 1;
        RGB_update(player_lives);
    }
}


/**
 * @brief EXAMPLE - WS2812_RGB
 *        Simple example to initialise the NeoPixel RGB LED on
 *        the MAKER-PI-PICO and then flash it in alternating
 *        colours between red, green and blue forever using
 *        one of the RP2040 built-in PIO controllers.
 * 
 * @return int  Application return code (zero for success).
 */
int main() {
 
    // Initialise all STDIO as we will be using the GPIOs
    stdio_init_all();
 
    // Initialise the PIO interface with the WS2812 code
    PIO pio = pio0;
    uint offset = pio_add_program(pio, &ws2812_program);
    ws2812_program_init(pio, 0, offset, WS2812_PIN, 800000, IS_RGBW);

    // Code for part 7.
        watchdog_enable(0x7fffff, 1);                                           // Enable the watchdog timer 

                                                                                // After level selected and letter to be converted printed

        watchdog_update();                                                      // Update the watchdog timer	
        
                                                                                // Call asm function 
        
        watchdog_update();

        if (watchdog_caused_reboot()) {                                         // Check if watchdog timer caused a reboot 
            printf("TIMEOUT!");
        }

        if(player_lives == 0) {                                                 // If player has no lives left, end game
            printf("\nGAME OVER! YOU HAVE NO LIVES LEFT! :( \n");
            return 0;
        }
        else if(level_selected == 2 && number_of_wins == 2){                    // If player has won 2 levels, end game
            end_screen();
        }
    
    //


    // Do forever...
    while(true) {

        // Set the color to red at half intensity
        put_pixel(urgb_u32(0x7F, 0x00, 0x00));
        sleep_ms(500);

        // Set the color to green at half intensity
        put_pixel(urgb_u32(0x00, 0x7F, 0x00));
        sleep_ms(500);

        // Set the color to blue at half intensity
        put_pixel(urgb_u32(0x00, 0x00, 0x7F));
        sleep_ms(500);

    }

    // Should never get here due to the infinite while-loop.
    return 0;


}

