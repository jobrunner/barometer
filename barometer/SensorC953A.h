/*
 * SensorC953A.h
 *
 * Original created by Ole Andreas Torvmark on 10/2/12.
 * Copyright (c) 2012 Texas Instruments Incorporated - http://www.ti.com/
 * ALL RIGHTS RESERVED
 */

#import <Foundation/Foundation.h>

@interface  SensorC953A: NSObject

///Calibration values unsigned
@property UInt16 c1;
@property UInt16 c2;
@property UInt16 c3;
@property UInt16 c4;

///Calibration values signed
@property int16_t c5;
@property int16_t c6;
@property int16_t c7;
@property int16_t c8;

- (id)initWithCalibrationData:(NSData *)data;
- (int)calcPressure:(NSData *)data;

@end
