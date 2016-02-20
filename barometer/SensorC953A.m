/*
 * SensorC953A.m
 *
 * Original created by Ole Andreas Torvmark on 10/2/12.
 * Copyright (c) 2012 Texas Instruments Incorporated - http://www.ti.com/
 * ALL RIGHTS RESERVED
 */

#import "SensorC953A.h"

@implementation SensorC953A

@synthesize c1;
@synthesize c2;
@synthesize c3;
@synthesize c4;
@synthesize c5;
@synthesize c6;
@synthesize c7;
@synthesize c8;

- (id)initWithCalibrationData:(NSData *)data {

    self = [[SensorC953A alloc] init];
    
    if (self) {
        unsigned char scratchVal[16];
        
        [data getBytes:&scratchVal
                length:16];
        
        self.c1 = ((scratchVal[ 0] & 0xff) | ((scratchVal[ 1] << 8) & 0xff00));
        self.c2 = ((scratchVal[ 2] & 0xff) | ((scratchVal[ 3] << 8) & 0xff00));
        self.c3 = ((scratchVal[ 4] & 0xff) | ((scratchVal[ 5] << 8) & 0xff00));
        self.c4 = ((scratchVal[ 6] & 0xff) | ((scratchVal[ 7] << 8) & 0xff00));
        self.c5 = ((scratchVal[ 8] & 0xff) | ((scratchVal[ 9] << 8) & 0xff00));
        self.c6 = ((scratchVal[10] & 0xff) | ((scratchVal[11] << 8) & 0xff00));
        self.c7 = ((scratchVal[12] & 0xff) | ((scratchVal[13] << 8) & 0xff00));
        self.c8 = ((scratchVal[14] & 0xff) | ((scratchVal[15] << 8) & 0xff00));
    }
    
    return self;
}

- (int)calcPressure:(NSData *)data {
    if (data.length < 4) {
        
        return -0.0f;
    }
    
    char scratchVal[4];
    
    [data getBytes:&scratchVal
            length:4];
    
    int16_t temp;
    uint16_t pressure;
    
    temp     = (scratchVal[0] & 0xff) | ((scratchVal[1] << 8) & 0xff00);
    pressure = (scratchVal[2] & 0xff) | ((scratchVal[3] << 8) & 0xff00);
    
    long long tempTemp = (long long)temp;
    
    // Temperature calculation
//    long temperature = ((((long)self.c1 * (long)tempTemp)/(long)1024) + (long)((self.c2) / (long)4 - (long)16384));
//    NSLog(@"Calculation of Barometer Temperature : temperature = %ld(%lx)",temperature, temperature);

    // Barometer calculation
    long long S = self.c3 + ((self.c4 * (long long)tempTemp)/((long long)1 << 17)) + ((self.c5 * ((long long)tempTemp * (long long)tempTemp))/(long long)((long long)1 << 34));
    
    long long O = (self.c6 * ((long long)1 << 14)) + (((self.c7 * (long long)tempTemp)/((long long)1 << 3))) + ((self.c8 * ((long long)tempTemp * (long long)tempTemp))/(long long)((long long)1 << 19));
    
    long long Pa = (((S * (long long)pressure) + O) / (long long)((long long)1 << 14));
    
    return (int)((int)Pa/(int)100);
}

@end
