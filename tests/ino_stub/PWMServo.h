#pragma once
#include "Arduino.h"
struct PWMServo { int attach(int, int=544, int=2400){return 1;} void write(int){} };
