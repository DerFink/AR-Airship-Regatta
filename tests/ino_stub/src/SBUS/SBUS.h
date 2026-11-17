#pragma once
#include "../../Arduino.h"
struct SBUS { template<class S> SBUS(S&){} void begin(){} bool read(uint16_t*, bool*, bool*){return false;} };
