#pragma once
#include "Arduino.h"
struct WireStub { void begin(){} void setClock(uint32_t){} void beginTransmission(int){} int endTransmission(bool=true){return 0;} int requestFrom(int,int){return 0;} int read(){return 0;} void write(int){} int available(){return 0;} };
extern WireStub Wire;
