//
//  ViewController.h
//  barometer
//
//  Created by Jo Brunner on 19.02.16.
//  Copyright © 2016 Mayflower. All rights reserved.
//

// #import <UIKit/UIKit.h>
// #import <CoreBluetooth/CoreBluetooth.h>
// #import "Sensor.h"

@class UIViewController;
@class SensorDelegate;
@class Sensor;

@interface ViewController : UIViewController <SensorDelegate>

@property (strong, nonatomic) Sensor *sensor;

@end

