#pragma once

#include <stdbool.h>

/**
 * Arithmetic cycle
 * Macro loop() represents the arithmetic cycle. The parameter defines the number of loops.
 */
#define loop(COUNT) for (size_t __loop_cntr = 0; __loop_cntr < COUNT; __loop_cntr++)

// *************************************** Primitives

/**
 * Moves Karel one step forward
 * If there is wall or Karel is at the border of the world, he will be turned
 * off automatically.
 */
void step(void);

/**
 * Turns Karel 90 degrees left
 */
void turn_left(void);

/**
 * Initializes the world of Karel the Robot
 * Function has one parameter, which defines the location of world file. If
 * the file doesn't exist, program will be terminated with error message. If
 * NULL is given instead of path, then input file is read from standard input.
 * @param path location of the world file or NULL if world file will be entered from stdin
 */
void turn_on(const char* path);

/**
 * Terminates Karel's program
 */
void turn_off(void);

/**
 * Puts beeper at the current world position, if Karol has some
 */
void put_beeper(void);

/**
 * Picks beeper from current position if there is any and puts it to Karol's bag
 */
void pick_beeper(void);

// *************************************** Sensors

/**
 * Checks, if there are beepers present at the corner
 * @return true, if there are beepers, false otherwise
 */
bool beepers_present(void);

/**
 * Checks, if there are any beepers in the bag
 * @return true, if there are some, false otherwise
 */
bool beepers_in_bag(void);

/**
 * Checks, if front of Karel is clear to go
 * @return true, if clear, false otherwise
 */
bool front_is_clear(void);

/**
 * Checks, if Karel is facing north
 * @return true, if yes, false otherwise
 */
bool facing_north(void);

// *************************************** Functions

/**
 * Sets the delay of one step
 * @param delay the delay in millis
 */
void set_step_delay(int delay);
