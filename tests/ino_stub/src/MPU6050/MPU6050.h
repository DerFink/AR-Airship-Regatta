#pragma once
#include "../../Arduino.h"
#define MPU6050_GYRO_FS_250 0
#define MPU6050_GYRO_FS_500 1
#define MPU6050_GYRO_FS_1000 2
#define MPU6050_GYRO_FS_2000 3
#define MPU6050_ACCEL_FS_2 0
#define MPU6050_ACCEL_FS_4 1
#define MPU6050_ACCEL_FS_8 2
#define MPU6050_ACCEL_FS_16 3
struct MPU6050 { void initialize(){} bool testConnection(){return true;} void setFullScaleGyroRange(int){} void setFullScaleAccelRange(int){} void getMotion6(int16_t*,int16_t*,int16_t*,int16_t*,int16_t*,int16_t*){} };
