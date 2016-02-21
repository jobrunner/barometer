//
//  ViewController.m
//  barometer
//
//  Created by Jo Brunner on 19.02.16.
//  Copyright © 2016 Mayflower. All rights reserved.
//

@import UIKit;
@import CoreBluetooth;

//#import <UIKit/UIKit.h>
//#import <CoreBluetooth/CoreBluetooth.h>

#import "Sensor.h"
#import "ViewController.h"


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *barometerValueLabel;

@end

@implementation ViewController

#pragma mark - ViewController


- (void)viewWillAppear:(BOOL)animated {

    
    self.barometerValueLabel.text = @"--- hPa";

    _sensor = [[Sensor alloc] initWithDelegate:self
                           lowerProximityValue:0
                           upperProximityValue:0];
    
    [_sensor startScan];
}

- (void)viewWillDisappear:(BOOL)animated {

    // deconfigureBarometer...
    [_sensor stopScan];
}


# pragma mark - Sensor delegates

- (void)sensorDidUpdateState:sensor
                       state:(CBCentralManagerState)state {

    if (state == CBCentralManagerStatePoweredOn) {

        [_sensor startScan];

        return ;
    }
    
    NSString *stateTitle   = [NSString stringWithFormat:@"Sensor"];
    NSString *stateMessage = [NSString stringWithFormat:@"Could not use Sensor Services."];
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:stateTitle
                                                       message:stateMessage
                                                      delegate:self
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles:nil];
    [alertView show];
}

- (void)sensorUpdateValue:(Sensor *)sensor
             sensorValues:(NSDictionary *)sensorValues {
    
    NSNumber * pressure = [sensorValues objectForKey:@"pressure"];

    if (pressure == nil) {
        self.barometerValueLabel.text = @"---- hPa";
    }
    else {
        self.barometerValueLabel.text = [NSString stringWithFormat:@"%@ hPa", pressure];
    }
}

@end
