#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#include "pico/stdlib.h"
#include "hardware/pio.h"
#include "hardware/clocks.h"
#include "ws2812.pio.h"
#include "hardware/watchdog.h"
#include "hardware/watchdog.h"

#define IS_RGBW true  // Will use RGBW format
#define NUM_PIXELS 1  // There is 1 WS2812 device in the chain
#define WS2812_PIN 28 // The GPIO pin that the WS2812 connected to

/*                          VARIABLES                           */

int player_lives = 3;      // Number of lives the player has
int level_selected = 0;    // Level selected by player
int correct_answers = 0;   // Number of correct answers the player has entered
int incorrect_answers = 0;  // Number of incorrect answers the player has entered
int correct_sequences = 5; // Number of correct sequences the player needs to enter to win the game
char user_input[20];       // Array to store user input
int length_of_input = 0;   // Length of user input
int input_entered = 0;     // Flag to indicate if user has entered input
int select_level = false;  // Level selected by player
int input_index = 0;       // Index of user input
int levels_completed = 0;  // Number of levels completed by player
int level_3_index = 0;     // Index of level 3 word
int level_4_index = 0;     // Index of level 4 word

/*                        ARM FUNCTIONS                         */

// Declare the main assembly code entry point.
void main_asm();

// Initialise a GPIO pin – see SDK for detail on gpio_init()
void asm_gpio_init(uint pin)
{
    gpio_init(pin);
}

// Set direction of a GPIO pin – see SDK for detail on gpio_set_dir()
void asm_gpio_set_dir(uint pin, bool out)
{
    gpio_set_dir(pin, out);
}

// Get the value of a GPIO pin – see SDK for detail on gpio_get()
bool asm_gpio_get(uint pin)
{
    return gpio_get(pin);
}

// Set the value of a GPIO pin – see SDK for detail on gpio_put()
void asm_gpio_put(uint pin, bool value)
{
    gpio_put(pin, value);
}

// Enable rising and falling-edge interrupt – see SDK for detail on gpio_set_irq_enabled()
void asm_gpio_set_irq(uint pin)
{
    gpio_set_irq_enabled(pin, GPIO_IRQ_EDGE_FALL, true);
    gpio_set_irq_enabled(pin, GPIO_IRQ_EDGE_RISE, true);
}

/*                                  MORSE CODE                                  */

/**
 * @brief Initialises the alphabhet array with Morse code representation for
 *        letters A-Z and numbers 0-9.
 * @author Martha
 *
 */
#define alphanumeric_chars 36 // (A-Z)(0-9)
typedef struct morsecode
{ // Creating morsecode datatype
    char *morsecode;
    char alphanum;
    char *word;
} morse;

morse alphabet[alphanumeric_chars];

/**
 * @brief Initialises the alphabhet array with Morse code representation for
 *        letters A-Z and numbers 0-9.
 * @author Martha
 */
void init_morse()
{

    alphabet[0].alphanum = 'A';
    alphabet[1].alphanum = 'B';
    alphabet[2].alphanum = 'C';
    alphabet[3].alphanum = 'D';
    alphabet[4].alphanum = 'E';
    alphabet[5].alphanum = 'F';
    alphabet[6].alphanum = 'G';
    alphabet[7].alphanum = 'H';
    alphabet[8].alphanum = 'I';
    alphabet[9].alphanum = 'J';
    alphabet[10].alphanum = 'K';
    alphabet[11].alphanum = 'L';
    alphabet[12].alphanum = 'M';
    alphabet[13].alphanum = 'N';
    alphabet[14].alphanum = 'O';
    alphabet[15].alphanum = 'P';
    alphabet[16].alphanum = 'Q';
    alphabet[17].alphanum = 'R';
    alphabet[18].alphanum = 'S';
    alphabet[19].alphanum = 'T';
    alphabet[20].alphanum = 'U';
    alphabet[21].alphanum = 'V';
    alphabet[22].alphanum = 'W';
    alphabet[23].alphanum = 'X';
    alphabet[24].alphanum = 'Y';
    alphabet[25].alphanum = 'Z';
    alphabet[26].alphanum = '0';
    alphabet[27].alphanum = '1';
    alphabet[28].alphanum = '2';
    alphabet[29].alphanum = '3';
    alphabet[30].alphanum = '4';
    alphabet[31].alphanum = '5';
    alphabet[32].alphanum = '6';
    alphabet[33].alphanum = '7';
    alphabet[34].alphanum = '8';
    alphabet[35].alphanum = '9';

    alphabet[0].morsecode = ".-";
    alphabet[1].morsecode = "-...";
    alphabet[2].morsecode = "-.-.";
    alphabet[3].morsecode = "-..";
    alphabet[4].morsecode = ".";
    alphabet[5].morsecode = "..-.";
    alphabet[6].morsecode = "--.";
    alphabet[7].morsecode = "....";
    alphabet[8].morsecode = "..";
    alphabet[9].morsecode = ".---";
    alphabet[10].morsecode = "-.-";
    alphabet[11].morsecode = ".-..";
    alphabet[12].morsecode = "--";
    alphabet[13].morsecode = "-.";
    alphabet[14].morsecode = "---";
    alphabet[15].morsecode = ".--.";
    alphabet[16].morsecode = "--.-";
    alphabet[17].morsecode = ".-.";
    alphabet[18].morsecode = "...";
    alphabet[19].morsecode = "-";
    alphabet[20].morsecode = "..-";
    alphabet[21].morsecode = "...-";
    alphabet[22].morsecode = ".--";
    alphabet[23].morsecode = "-..-";
    alphabet[24].morsecode = "-.--";
    alphabet[25].morsecode = "--..";
    alphabet[26].morsecode = "-----";
    alphabet[27].morsecode = ".----";
    alphabet[28].morsecode = "..---";
    alphabet[29].morsecode = "...--";
    alphabet[30].morsecode = "....-";
    alphabet[31].morsecode = ".....";
    alphabet[32].morsecode = "-....";
    alphabet[33].morsecode = "--...";
    alphabet[34].morsecode = "---..";
    alphabet[35].morsecode = "----.";

    alphabet[0].word = "Dog";
    alphabet[1].word = "Cat";
    alphabet[2].word = "Board";

    alphabet[36].morsecode = "-.. --- --.";
    alphabet[37].morsecode = "-.-. .- -";
    alphabet[38].morsecode = "-... --- .- .-. -..";
}

/**
 * @brief Veryfying if the input is a valid morse code.
 * @author Ingrid
 */
void morseToAlphaNum(char *morse)
{
    bool found = false;

    for (int i = 0; i < 36; i++)
    {
        if (strcmp(alphabet[i].morsecode, morse) == 0)
        {
            printf("%c", alphabet[i].alphanum);
            found = true;
        }
    }

    for (int i = 0; i < 3; i++)
    {
        if (strcmp(alphabet[i + 36].morsecode, morse) == 0)
        {
            printf("%s", alphabet[i].word);
            found = true;
        }
    }

    if (!found)
    {
        printf("?");
    }
}

/**
 * @brief Statistics of the game
 * @author Ingrid
 */
void stats()
{
    printf("YOU HAD A TOTAL OF %d CORRECT ANSWERS!\n", correct_answers);
    printf("YOU HAD A TOTAL OF %d INCORRECT ANSWERS!\n", incorrect_answers);
    double calculation = (double)correct_answers / (double)((double)correct_answers + (double)incorrect_answers);
    double percentage = calculation * 100;
    printf("YOU HAD A SUCCESS RATE OF %f%%\n", percentage);
}

/*                              MESSAGES                                */
/**
 * @brief Welcome message
 * @author Della
 *
 */
void welcome_message()
{
    printf("* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- *\n");
    printf("|          ASSIGNMENT #2 - GROUP 14                     |\n");
    printf("* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- *\n");
    printf("|       * * * *   *               *      *     *        |\n");
    printf("|       *     *   *              * *      *   *         |\n");
    printf("|       * * * *   *             *   *      * *          |\n");
    printf("|       *         *            * * * *      *           |\n");
    printf("|       *         *           *       *     *           |\n");
    printf("|       *         *          *         *    *           |\n");
    printf("|       *         * * * *   *           *   *           |\n");
    printf("|                                                       |\n");
    printf("|   *         *    * * *    * * *     * * *    * * * *  |\n");
    printf("|   *  *   *  *  *       *  *   *    *     *   *        |\n");
    printf("|   *    *    *  *       *  * * *    *         *        |\n");
    printf("|   *         *  *       *  *  *       * * *   * * *    |\n");
    printf("|   *         *  *       *  *   *           *  *        |\n");
    printf("|   *         *  *       *  *    *    *     *  *        |\n");
    printf("|   *         *    * * *    *     *    * * *   * * * *  |\n");
    printf("* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- *\n");
    printf("|              ARE YOU READY TO PLAY ?                  |\n");
    printf("|           USE GP21 TO PICK YOUR LEVEL!                |\n");
    printf("|           \".----\" - LEVEL 1 - CHARS (EASY)            |\n");
    printf("|           \".----\" - LEVEL 2 - CHARS (MEDIUM)          |\n");
    printf("|           \"...--\" - LEVEL 3 - WORDS (HARD)            |\n");
    printf("|           \"....-\" - LEVEL 4 - WORDS (EXPERT)          |\n");
    printf("|                  GOODLUCK ! ! !                       |\n");
    printf("* -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- *\n");
}

/**
 * @brief Progress message
 * @author Faith
 *
 */
void progress_level()
{
    printf("\nLEVEL %d COMPLETED!\n", level_selected);
    stats();
    if(levels_completed <= 4){
        printf("MOVING TO LEVEL %d\n", level_selected + 1);
    }
    levels_completed++;
    correct_answers = 0;
    incorrect_answers = 0;
    
}

/**
 * @brief Winner message
 * @author Faith
 *
 */
void winner()
{
    printf("\nLEVEL %d COMPLETED!\n", level_selected);
    printf("\nCONGRATULATIONS! YOU WON!\n");
    stats();
}

/**
 * @brief Loser message
 * @author Faith
 *
 */
void loser()
{
    printf("\nCOMMISERATIONS :( YOU LOST!\n");
    stats();
}

/**
 * @brief Level choice message
 * @author Faith
 *
 */
void level_choice()
{
    printf("Please Select A Level To Play: \n");
    printf("\nLevel 1: .----");
    printf("\nLevel 2: ..---");
    printf("\nLevel 3: ...--");
    printf("\nLevel 4: ....-\n");
}

/**
 * @brief Invalid input message
 * @author Faith
 *
 */
void invalid_input_entered()
{
    printf("INCORRECT MORSE CODE\n");
}

/**
 * @brief Wrong sequence message
 * @authors Faith, Ingrid
 *
 */
void wrong_sequence()
{
    printf("\nPLAYER INPUT: %s", user_input);
    printf("\nPLAYER ALPHANUMERICAL INPUT: ");
    morseToAlphaNum(user_input);
    printf("\nCORRECT SEQUENCE: %s", alphabet[input_index].morsecode);
    player_lives--;
    printf("\nWRONG SEQUENCE! LOST A LIFE");
    printf("\n%d LIVES LEFT\n", player_lives);
}

/**
 * @brief Correct sequence message
 * @authors Faith, Ingrid
 *
 */
void correct_sequence()
{
    printf("\nPLAYER INPUT: %s", user_input);
    printf("\nPLAYER ALPHANUMERICAL INPUT: ");
    morseToAlphaNum(user_input);
    printf("\nCORRECT SEQUENCE %s", alphabet[input_index].morsecode);
    correct_answers++;
    printf("\n%d CORRECT SEQUENCES", correct_answers);
    if (player_lives < 3)
    {
        player_lives++;
        printf("\nGAINED A LIFE! PLAYER LIVES: %d", player_lives);
    }
    else
    {
        printf("\nMAX LIVES REACHED! NO LIVES GAINED\n");
    }
}

/**
 * @brief Wrong sequence message for level 3 and 4
 * @authors Faith, Ingrid, Martha
 *
 */
void wrong_sequence_level_3_and_4()
{
    printf("\nPLAYER INPUT: %s", user_input);
    printf("\nPLAYER ALPHANUMERICAL INPUT:");
    morseToAlphaNum(user_input);
    printf("\nCORRECT SEQUENCE: %s", alphabet[input_index].morsecode);
    player_lives--;
    printf("\nWRONG SEQUENCE! LOST A LIFE");
    printf("\n%d LIVES LEFT\n", player_lives);
}

/**
 * @brief Correct sequence message for level 3 and 4
 * @authors Faith, Ingrid, Martha
 *
 */
void correct_sequence_level_3_and_4()
{
    printf("\nPLAYER INPUT: %s", user_input);
    printf("\nPLAYER ALPHANUMERICAL INPUT:");
    morseToAlphaNum(user_input);
    printf("\nCORRECT SEQUENCE %s", alphabet[input_index].morsecode);
    correct_answers++;
    printf("\n%d CORRECT SEQUENCES", correct_answers);
    if (player_lives < 3)
    {
        player_lives++;
        printf("\nGAINED A LIFE! PLAYER LIVES: %d", player_lives);
    }
    else
    {
        printf("\nMAX LIVES REACHED! NO LIVES GAINED\n");
    }
}

/*                                VALIDATE ANSWERS                                      */

/**
 * @brief Validate input sequence against the correct answer
 * @author Leah
 */
int validate_input_sequence()
{
    if (strcmp(user_input, alphabet[input_index].morsecode) == 0)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

/**
 * @brief Display input message
 * @authors Faith, Martha, Della
 *
 */
void display_input()
{
    if (input_index >= 0 && input_index <= 35)
    {
        int ans = validate_input_sequence();
        if (input_entered == 1)
        {
            if (ans == 0)
            {
                wrong_sequence();
            }
            else
            {
                correct_sequence();
            }
        }
    }
    else if (input_index == 36)
    {
        if (strcmp(user_input, "-.. --- --.") == 0)
        {
            correct_sequence_level_3_and_4();
        }
        else
        {
            wrong_sequence_level_3_and_4();
        }
    }
    else if (input_index == 37)
    {
        if (strcmp(user_input, "-.-. .- -") == 0)
        {
            correct_sequence_level_3_and_4();
        }
        else
        {
            wrong_sequence_level_3_and_4();
        }
    }
    else if (input_index == 38)
    {
        if (strcmp(user_input, "-... --- .- .-. -..") == 0)
        {
            correct_sequence_level_3_and_4();
        }
        else
        {
            wrong_sequence_level_3_and_4();
        }
    }
    else
    {
        printf("\n?\n");
        printf("INCORRECT MORSE CODE\n");
    }
}

/*                            WATCHDOG TIMER                            */
/**
 * @brief Watchdog timer function
 * @author Faith
 *
 */
void watchdog_init()
{
    // Check for reboot due to watchdog timeout
    if (watchdog_caused_reboot())
    {
        printf("\n WATCHDOG TIMEOUT\n");
    }
    // Check for reboot due to watchdog enable
    if (watchdog_enable_caused_reboot())
    {
        printf("\n WATCHDOG ENABLED\n");
    }
    // Enable watchdog timer
    watchdog_enable(0x7fffff, 1);
    watchdog_update();
}

/*                                  RGB LED                                 */
/**
 * @brief Wrapper function used to call the underlying PIO
 *        function that pushes the 32-bit RGB colour value
 *        out to the LED serially using the PIO0 block. The
 *        function does not return until all of the data has
 *        been written out.
 *
 * @param pixel_grb The 32-bit colour value generated by urgb_u32()
 */

static inline void put_pixel(uint32_t pixel_grb)
{
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
static inline uint32_t urgb_u32(uint8_t r, uint8_t g, uint8_t b)
{
    return ((uint32_t)(r) << 8) |
           ((uint32_t)(g) << 16) |
           (uint32_t)(b);
}

/**
 * @brief Ensures that the RGB is blue at start of the game
 * @author Leah
 */
void start_RGB_Colour()
{
    put_pixel(urgb_u32(0x00, 0x00, 0xFF));
    // printf("The RGB LED is Blue to show the game has not started");
}

/**
 * @brief Updates the RGB LED colour based on the number of lives remaining
 * @author Leah
 */
void RGB_update(int number_of_lives)
{
    switch (number_of_lives) // Switch statement to update RGB LED colour based on number of lives remaining
    {
    case 0: // If player has 0 lives remaining
        // Black
        put_pixel(urgb_u32(0x00, 0x00, 0x00));
        // printf("\n0 lives remaining. GAME OVER\n");
        break;

    case 1: // If player has 1 life remaining
        // Red
        put_pixel(urgb_u32(0x7F, 0x00, 0x00));
        // printf("\n1 life remaining\n");
        break;

    case 2: // If player has 2 lives remaining
        // Yellow
        put_pixel(urgb_u32(0xFF, 0xFF, 0x00));
        // printf("\n2 lives remaining\n");
        break;

    case 3: // If player has 3 lives remaining (Max)
        // Green
        put_pixel(urgb_u32(0x00, 0xFF, 0x00));
        // printf("\n3 lives remaining\n");
        break;

    default:
        printf("\nSomething went wrong!\n");
        break;
    }
}

/*                                  BUTTON DURATION                                 */
/**
 * @brief Function to get the time in milliseconds since boot
 * @author Faith
 */
int get_time()
{
    absolute_time_t time = get_absolute_time();
    return to_ms_since_boot(time);
}

/**
 * @brief Function to get the time difference between two times in milliseconds
 * @author Faith
 */
int get_time_diff(int end_time, int start_time)
{
    return end_time - start_time;
}

/*                                     GAME BEGIN                                       */

/**
 * @brief Function to begin the game
 * @author Della
 */
void begin_game()
{
    start_RGB_Colour();    // Start RGB Colour
    player_lives = 3;      // Player has 3 lives to start with
    correct_answers = 0;   // Player has 0 correct answers to start with
    correct_sequences = 5; // Player needs to enter 5 correct sequences to win the game
}

/*                              LEVEL SELECT                                              */
/**
 * @brief Function to select the level of the game
 * @authors Martha, Della
 */
int level_select()
{
    // Level 1 selected .----
    if (strcmp(user_input, alphabet[27].morsecode) == 0)
    {
        printf("\nLEVEL 1\n");
        return 1;
    }
    // Level 2 selected ..---
    else if (strcmp(user_input, alphabet[28].morsecode) == 0)
    {
        printf("\nLEVEL 2\n");
        return 2;
    }
    // Level 3 selected ...--
    else if (strcmp(user_input, alphabet[29].morsecode) == 0)
    {
        printf("\nLEVEL 3\n");
        return 3;
    }
    // Level 4 selected ....-
    else if (strcmp(user_input, alphabet[30].morsecode) == 0)
    {
        printf("\nLEVEL 4\n");
        return 4;
    }

    // Level invalid
    else
    {
        printf("INVALID LEVEL");
        return 5;
    }
}

/**
 * @brief Functions to see if player can select level
 * @author Faith
 */

void player_select()
{
    select_level = 1;
}

void player_select2()
{
    select_level = 0;
}

/**
 * @brief Functions to get and set level
 * @author Faith
 */
int get_level()
{
    return level_selected;
}

void set_level(int level)
{
    level_selected = level;
}

/**
 * @brief Level #1: Individual characters with their equivalent Morse code provided.
 *        Asks the user to enter the morse code equivalent of a given alphanumeric
 *        character.
 *
 * @return int
 * @author Martha
 */
int level_1()
{
    level_selected = 1;
    int num = rand() % 36;
    input_index = num;
    printf("\nEnter Equivalent Morse Code For The Following Character:\n");
    printf("CHARACTER: %c \n", alphabet[num].alphanum);
    printf("MORSE CODE: %s \n", alphabet[num].morsecode);
    return num;
}

/**
 * @brief Level #2: Individual characters without their equivalent Morse code provided.
 *        Same function as level_1 except without giving the morse code equivalent.
 *
 * @return int
 * @author Martha
 */
int level_2()
{
    level_selected = 2;
    int num = rand() % 36;
    input_index = num;
    printf("\nEnter Equivalent Morse Code For The Following Character:\n");
    printf("CHARACTER: %c \n", alphabet[num].alphanum);
    return num;
}

/**
 * @brief Level #3: Individual words with their equivalent Morse code provided.
 *        Asks the user to enter the morse code equivalent of a given word.
 *
 * @return int
 * @author Della
 */

int level_3()
{
    level_selected = 3;
    int num = 0;
    switch (level_3_index)
    {
    case 0:
        num = 36;
        input_index = num;
        printf("\nEnter Equivalent Morse Code For The Following Word:\n");
        printf("WORD: %s \n", alphabet[0].word);
        printf("MORSE CODE: %s \n", alphabet[num].morsecode);
        level_3_index++;
        return num;
    case 1:
        num = 37;
        input_index = num;
        printf("\nEnter Equivalent Morse Code For The Following Word:\n");
        printf("WORD: %s \n", alphabet[1].word);
        printf("MORSE CODE: %s \n", alphabet[num].morsecode);
        level_3_index++;
        return num;
    case 2:
        num = 38;
        input_index = num;
        printf("\nEnter Equivalent Morse Code For The Following Word:\n");
        printf("WORD: %s \n", alphabet[2].word);
        printf("MORSE CODE: %s \n", alphabet[num].morsecode);
        level_3_index = 0;
        return num;
    }
    return num;
}

/**
 * @brief Level #4: Individual words without their equivalent Morse code provided
 *
 * @return int
 * @author Martha
 */
int level_4()
{
    level_selected = 4;
    int num = 0;
    switch (level_4_index)
    {
    case 0:
        num = 36;
        input_index = num;
        printf("\nEnter Equivalent Morse Code For The Following Word:\n");
        printf("WORD: %s \n", alphabet[0].word);
        level_4_index++;
        return num;
    case 1:
        num = 37;
        input_index = num;
        printf("\nEnter Equivalent Morse Code For The Following Word:\n");
        printf("WORD: %s \n", alphabet[1].word);
        level_4_index++;
        return num;
    case 2:
        num = 38;
        input_index = num;
        printf("\nEnter Equivalent Morse Code For The Following Word:\n");
        printf("WORD: %s \n", alphabet[2].word);
        level_4_index = 0;
        return num;
    }
    return num;
}

/**
 * @brief Progression of game based on correct answers, lives, and levels completed
 * @author Faith
 */
int progress_next()
{
    if (correct_answers == 5)
    {
        return 1;
    }
    if (player_lives == 0)
    {
        printf("\nGAME OVER\n");
        return 2;
    }
    if (levels_completed == 4)
    {
        printf("\nYOU WIN!\n");
        return 3;
    }
    return 0;
}

/*                                      INPUT HANDLING                                  */

/**
 * @brief Initialize input array and input variables
 * @author Faith
 */
void init_input()
{
    int max = 20;
    for (int i = 0; i < max; i++)
    {
        user_input[i] = '\0';
    }
    input_entered = 0;
    length_of_input = 0;
}

/**
 * @brief Handles input from player
 * @author Faith
 */
void input_handler(int player_input)
{
    // If player enters dot
    if (player_input == 1)
    {
        user_input[length_of_input] = '.';
        length_of_input++;
        printf(".");
    }
    // If player enters dash
    else if (player_input == 2)
    {
        user_input[length_of_input] = '-';
        length_of_input++;
        printf("-");
    }
    // If player enters space
    else if (player_input == 3)
    {
        user_input[length_of_input] = ' ';
        length_of_input++;
        printf(" ");
    }
    // If player enters enter (select level)
    else if (player_input == 4 && select_level == 1)
    {
        user_input[length_of_input - 1] = '\0';
        input_entered = 1;
        level_select();
    }
    // If player enters enter (input morse code)
    else if (player_input == 4 && select_level == 0)
    {
        user_input[length_of_input - 1] = '\0';
        input_entered = 1;
        display_input();
        RGB_update(player_lives);
    }
}

/**
 * @brief Validate input sequence against morse code
 * @author Leah
 */
int validate_morse_code()
{
    for (int i = 0; i < alphanumeric_chars; i++)
    {
        if (user_input == alphabet[i].morsecode)
        {
            return i;
        }
    }
    return -1;
}

int main()
{
    // Initialise all STDIO as we will be using the GPIOs
    stdio_init_all();
    init_morse();
    watchdog_init();

    // Initialise the PIO interface with the WS2812 code
    PIO pio = pio0;
    uint offset = pio_add_program(pio, &ws2812_program);
    ws2812_program_init(pio, 0, offset, WS2812_PIN, 800000, IS_RGBW);
    put_pixel(urgb_u32(0x00, 0x00, 0x7f)); // Blue

    welcome_message();
    watchdog_update();

    main_asm();

    // Should never get here due to the infinite while-loop.
    return 0;
}
