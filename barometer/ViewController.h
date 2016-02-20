//
//  ViewController.h
//  barometer
//
//  Created by Jo Brunner on 19.02.16.
//  Copyright © 2016 Mayflower. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
@class SensorC953A;

@interface ViewController : UIViewController  <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong,nonatomic) NSMutableArray *peripherals;

@property (strong,nonatomic) SensorC953A *barometerSensor;

@end

