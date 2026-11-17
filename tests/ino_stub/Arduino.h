// 2026-11-17 20:40 – Erstversion: Ersatz-Kopfdatei, damit der erzeugte Teensy-Sketch mit g++ auf Syntax/Typen geprüft werden kann (kein echter Teensy-Code)
#pragma once
#include <cstdint>
#include <cmath>
#include <cstring>
#include <cstdlib>
typedef uint8_t byte;
typedef bool boolean;
#define HIGH 1
#define LOW 0
#define OUTPUT 1
#define INPUT 0
#define INPUT_PULLUP 2
#define LED_BUILTIN 13
#define DEC 10
#define HEX 16
#define PI 3.14159265358979f
#define DEG_TO_RAD 0.0174532925f
#define RAD_TO_DEG 57.2957795f
template<class T, class L, class H> auto constrain(T x, L a, H b) -> decltype(x + a + b) { return x < a ? a : (x > b ? b : x); }
template<class T> T sq(T x) { return x * x; }
#ifndef min
template<class A, class B> auto min(A a, B b) -> decltype(a + b) { return a < b ? a : b; }
template<class A, class B> auto max(A a, B b) -> decltype(a + b) { return a > b ? a : b; }
#endif
inline long map(long x, long a, long b, long c, long d) { return (x - a) * (d - c) / (b - a) + c; }
unsigned long micros(); unsigned long millis(); void delay(unsigned long); void delayMicroseconds(unsigned int);
void pinMode(int, int); void digitalWrite(int, int); int digitalRead(int); int analogRead(int);
void analogWrite(int, int); void analogWriteFrequency(int, float); void analogWriteResolution(int);
struct SerialStub { void begin(long){} template<class T> void print(T){} template<class T> void print(T,int){} template<class T> void println(T){} template<class T> void println(T,int){} void println(){} int available(){return 0;} int read(){return -1;} void flush(){} explicit operator bool() const {return true;} };
extern SerialStub Serial, Serial1, Serial2, Serial3, Serial5;
#define F(x) (x)
// Funktionen aus den anderen Reitern des Sketches (radioComm.ino) – hier nur als Ersatz
inline void radioSetup() {}
unsigned long getRadioPWM(int ch);
