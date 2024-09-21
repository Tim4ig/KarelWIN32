#include "karel.h"
#include "internals.h"
#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

bool beepers_in_bag(void) {
  _check_karel_state();
  return _karel.beepers > 0;
}

bool front_is_clear(void) {
  _check_karel_state();

  switch (_karel.direction) {
    case NORTH:
      if (_karel.y + 1 >= _world.height || _world.data[_karel.y + 1][_karel.x] == WALL) {
        return false;
      }
      break;
    case SOUTH:
      if (_karel.y - 1 < 1 || _world.data[_karel.y - 1][_karel.x] == WALL) {
        return false;
      }
      break;
    case WEST:
      if (_karel.x - 1 < 1 || _world.data[_karel.y][_karel.x - 1] == WALL) {
        return false;
      }
      break;
    case EAST:
      if (_karel.x + 1 >= _world.width || _world.data[_karel.y][_karel.x + 1] == WALL) {
        return false;
      }
      break;
  }

  return true;
}

bool facing_north(void) {
  _check_karel_state();
  return _karel.direction == NORTH;
}

bool beepers_present(void) {
  _check_karel_state();
  return _world.data[_karel.y][_karel.x] > 0;
}

// *************************************** Basic Karel's Primitives

void step(void) {
  _check_karel_state();

  if (front_is_clear()) {
    switch (_karel.direction) {
      case NORTH:
        _karel.y += 2;
        _update(0, 1);
        break;
      case SOUTH:
        _karel.y -= 2;
        _update(0, -1);
        break;
      case WEST:
        _karel.x -= 2;
        _update(-1, 0);
        break;
      case EAST:
        _karel.x += 2;
        _update(1, 0);
        break;
    }

    _karel.steps++;
    _karel.last_command = ("STEP");
    _render();
  } else {
    _error_shut_off(("Can't move this way."));
  }
}

void turn_left(void) {
  _check_karel_state();

  _karel.direction += 90;
  if (_karel.direction > 270) {
    _karel.direction = EAST;
  }
  _karel.steps++;
  _karel.last_command = ("TURN LEFT");

  _update(0, 0);
  _render();
}

void turn_off(void) {
  _karel.last_command = ("TURN OFF");
  _render();
  _deinit();

  // if summary, then export data
  if (_summary.is_active) {
    _export_data(NULL);
  }

  // free memory
  for (int y = 0; y < _world.height; y++) {
    free(_world.data[y]);
  }
  free(_world.data);

  // credits
  if (!_summary.is_active) {
    printf(("Created by miroslav.binas@tuke.sk (c)2010, 2016, 2018-2019\n"));
  }

  exit(EXIT_SUCCESS);
}

void turn_on(const char* path) {
  // check, if we are running summary mode
  const char* mode = getenv("LIBKAREL_SUMMARY_MODE");  // set env.var. LIBKAREL_SUMMARY_MODE as true to see output as arena see
  if (mode && strcmp(mode, "true") == 0) {
    _summary.is_active = true;

    // check the type of summary mode
    char* type = getenv("LIBKAREL_SUMMARY_MODE_TYPE");  // set env.var. LIBKAREL_SUMMARY_MODE_TYPE as json to see output as arena see
    if (type && strcmp(type, "json") == 0) {
      _summary.type = type;
    }
  }

  // open file and read the world params
  FILE* fp = stdin;
  if (path != NULL) {
    fp = fopen(path, "r");
    if (fp == NULL) {
      _error_shut_off(("World file '%s' not found."), path);
    }
  }

  int row, column, count;
  char direction, block, orientation;

  if (fscanf(fp, "%d %d %d %d %c %d\n", &_world.width, &_world.height, &_karel.x, &_karel.y, &direction, &_karel.beepers) != 6) {
    _error_shut_off(("The world information are not in correct format!"));
  }

  // world correction
  _world.width = _world.width * 2 - 1;
  _world.height = _world.height * 2 - 1;

  // karel position correction
  _karel.x = _karel.x * 2 - 2;
  _karel.y = _karel.y * 2 - 2;

  // check the world dimensions
  if (_world.width > MAX_WIDTH || _world.width < 1) {
    _error_shut_off(("The world's width is outside the range [1, %d]!"), MAX_WIDTH);
  }

  if (_world.height > MAX_HEIGHT || _world.height < 1) {
    _error_shut_off(("The world's height is outside the range [1, %d]!"), MAX_HEIGHT);
  }

  // format the direction
  switch (toupper(direction)) {
    case 'S':
      _karel.direction = SOUTH;
      break;
    case 'W':
      _karel.direction = WEST;
      break;
    case 'E':
      _karel.direction = EAST;
      break;
    case 'N':
      _karel.direction = NORTH;
      break;
    default:
      _error_shut_off(("Uknown Karel's direction."));
  }

  // create empty world
  _world.data = (int**)calloc(_world.height, sizeof(int*));
  for (int y = 0; y < _world.height; y++) {
    _world.data[y] = (int*)calloc(_world.width, sizeof(int));
  }

  // load the map description
  int line = 2;
  while (fscanf(fp, "%c", &block) != EOF) {

    switch (toupper(block)) {
      case 'W': {

        // read the data
        if (fscanf(fp, "%d %d %c\n", &column, &row, &orientation) != 3) {
          _error_shut_off(("Line %d: Incorrect format."), line);
        }

        // check correct position
        if (column > _world.width || row > _world.height) {
          _error_shut_off(("Line %d: Wall position is outside the world!"), line);
        }

        // column2, is so fucking great naming. Actually there are no fucking reason to make it if he can write
        // column = column * 2 - 2; but I prefer do not modify src
        int column2 = column * 2 - 2;
        int row2 = row * 2 - 2;

        // check, if the wall is correctly positioned
        if (column2 % 2 == 1 || row2 % 2 == 1) {
          _error_shut_off(("Wrong position."));
        }

        // set walls
        switch (toupper(orientation)) {
          case 'E':
            column2++;
            break;
          case 'W':
            column2--;
            break;
          case 'N':
            row2++;
            break;
          case 'S':
            row2--;
            break;
          default:
            _error_shut_off("Unknown wall orientation '%c' on line %d in world file.", orientation, line);
        }

        _world.data[row2][column2] = WALL;

        // set vertical line
        if (column2 % 2 == 1 && row2 % 2 == 0) {
          if (row2 + 1 < _world.height) {
            _world.data[row2 + 1][column2] = WALL;
          }
          if (row2 - 1 >= 0) {
            _world.data[row2 - 1][column2] = WALL;
          }
        } else {
          // set horizontal line
          if (column2 + 1 < _world.width) {
            _world.data[row2][column2 + 1] = WALL;
          }
          if (column2 - 1 >= 0) {
            _world.data[row2][column2 - 1] = WALL;
          }
        }
        break;
      }

      case 'B': {
        if (fscanf(fp, "%d %d %d\n", &column, &row, &count) != 3) {  // rewrite with strtol
          _error_shut_off(("Line %d: Incorrect format."), line);
        }

        // check correct position
        if (column > _world.width || row > _world.height) {
          _error_shut_off(("Line %d: Beeper position is outside the world!"), line);
        }

        _world.data[row * 2 - 2][column * 2 - 2] = count;
        break;
      }

      default:
        _error_shut_off(("Unknown block character %c on line %d in world file."), block, line);
    }

    line++;
  }

  // close the file and draw the scene
  fclose(fp);

  // final initialization
  _initialize();
  _karel.last_command = ("TURN ON");
  _draw_world();
  _render();

  _karel.is_running = true;
}

void put_beeper(void) {
  _check_karel_state();

  if (_karel.beepers > 0) {
    _world.data[_karel.y][_karel.x]++;
    _karel.beepers--;
    _karel.steps++;
    _karel.last_command = ("PUT BEEPER");
    _render();
  } else {
    _error_shut_off(("Karel has no beeper to put at the corner."));
  }
}

void pick_beeper(void) {
  _check_karel_state();

  if (_world.data[_karel.y][_karel.x] > 0) {
    _world.data[_karel.y][_karel.x]--;
    _karel.beepers++;
    _karel.steps++;
    _karel.last_command = ("PICK BEEPER");
    _render();
  } else {
    _error_shut_off(("There is no beeper at the corner."));
  }
}

// *************************************** Functions
void set_step_delay(const int delay) {
  _step_delay = delay * MULTIPLIER;
}
