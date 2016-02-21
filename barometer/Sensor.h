//
//  Sensor.h
//  barometer
//
//  Created by Jo Brunner on 20.02.16.
//  Copyright © 2016 Mayflower. All rights reserved.
//

@class CBCentralManagerDelegate;
@class CBPeripheralDelegate;
@class SensorC953A;

@protocol SensorDelegate;

@interface Sensor : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (weak, nonatomic) id<SensorDelegate> delegate;

@property (strong, nonatomic) CBCentralManager *central;
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;

@property (strong,nonatomic) NSMutableArray *peripherals;
@property (strong,nonatomic) SensorC953A *barometerSensor;

@property NSInteger lowerProximityValue;
@property NSInteger upperProximityValue;


- (id)init;

- (id)initWithDelegate:(id<SensorDelegate>)delegate;

- (id)initWithDelegate:(id<SensorDelegate>)delegate
   lowerProximityValue:(NSInteger)lowerProximityValue
   upperProximityValue:(NSInteger)upperProximityValue;

- (void)startScan;

- (void)stopScan;

@end

@protocol SensorDelegate <NSObject>

@optional

- (void)sensorDidUpdateState:(Sensor *)sensor state:(CBCentralManagerState)state;

- (void)sensorUpdateValue:(Sensor *)sensor sensorValues:(NSDictionary *)sensorValues;
//- (void)sensorReadyForScan:(Sensor *)sensor;
//- (void)sensor:(Sensor *)sensor didStopSending:(id)item;
//- (void)sensor:(Sensor *)sensor didFinishLoadingItem:(id)item;
//- (void)test:(Sensor *)sensor didFailWithError:(NSError *)error;

@end