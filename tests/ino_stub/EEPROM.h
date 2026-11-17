#pragma once
#include "Arduino.h"
struct EEPROMStub { uint8_t read(int){return 0;} void write(int,uint8_t){} void update(int,uint8_t){} template<class T> T& get(int, T& t){return t;} template<class T> const T& put(int, const T& t){return t;} int length(){return 1080;} };
extern EEPROMStub EEPROM;
