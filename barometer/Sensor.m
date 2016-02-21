//
//  Sensor.m
//  barometer
//
//  Created by Jo Brunner on 20.02.16.
//  Copyright © 2016 Mayflower. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "Sensor.h"
#import "CBHelper.h"
#import "SensorC953A.h"

@implementation Sensor {
    
    struct {
        unsigned int sensorDidUpdateState:1;
        unsigned int sensorUpdateValue:1;
    } delegateRespondsTo;
}

NSString * const NSSensorErrorDomain = @"SensorError";
CBHelper * characteristicsHelper;

// setter with caching
- (void)setDelegate:(id <SensorDelegate>)delegate {

    if (_delegate != delegate) {
        _delegate = delegate;
        delegateRespondsTo.sensorDidUpdateState = [_delegate respondsToSelector:@selector(sensorDidUpdateState:state:)];
        delegateRespondsTo.sensorUpdateValue = [_delegate respondsToSelector:@selector(sensorUpdateValue:sensorValues:)];
    }
}

- (id)init {
    
    return [self initWithDelegate:nil
              lowerProximityValue:0
              upperProximityValue:0];
}

- (id)initWithDelegate:(id<SensorDelegate>)delegate {

    return [self initWithDelegate:nil
              lowerProximityValue:0
              upperProximityValue:0];
}

- (id)initWithDelegate:(id<SensorDelegate>)delegate
   lowerProximityValue:(NSInteger)lowerProximityValue
   upperProximityValue:(NSInteger)upperProximityValue {
    
    if (self = [super init]) {

        dispatch_queue_t queue = dispatch_queue_create("de.mayflower.jo.barometer.sensor.gcq", nil);

        self.central = [[CBCentralManager alloc] initWithDelegate:self
                                                            queue:queue];
        if (delegate != nil) {
            self.delegate = delegate;
        }
        
        _lowerProximityValue = lowerProximityValue;
        _upperProximityValue = upperProximityValue;
    }
    
    return self;
}

- (void)startScan {

    NSLog(@"Start scanning for Peripherals with Services");

    [_central scanForPeripheralsWithServices:nil
                                    options:nil];
    NSDictionary *options;

    if ((_lowerProximityValue == 0) &&
        (_upperProximityValue == 0)) {
        options = nil;
    }
    else {
        options = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    }

    [_central scanForPeripheralsWithServices:nil
                                     options:options];
}

- (void)stopScan {

    [_central stopScan];
    [self putzen];
}

- (void)putzen {

    if (_connectedPeripheral.state != CBPeripheralStateConnected) {
        
        return;
    }
    
    [self deconfigureBarometer:_connectedPeripheral];
    
    [_central cancelPeripheralConnection:_connectedPeripheral];
}


#pragma mark - Configuration


- (void)configureBarometer:(CBPeripheral *)peripheral {
    
    // Konfigurieren des Barometers:
    CBUUID *serviceUUID = [CBUUID UUIDWithString:BAROMETER_SERV_UUID];
    
    CBHelper *helper = [[CBHelper alloc] initWithPeripheral:peripheral
                                              serviceCBUUID:serviceUUID];
    
    // {{{ Read calibration info from Sensor
    // say we want to calibrate sensor
    uint8_t data = 0x02;
    [helper writeCharacteristic:[CBUUID UUIDWithString:BAROMETER_CONF_UUID]
                           data:[NSData dataWithBytes:&data
                                               length:1]];
    
    // say we want to be notified with calibration value
    [helper setNotificationForCharacteristic:[CBUUID UUIDWithString:BAROMETER_DATA_UUID]
                                      enable:YES];
    
    // say we want to read calibration values
    [helper readCharacteristic:[CBUUID UUIDWithString:BAROMETER_CALI_UUID]];
    
    // delegate -peripheral:didUpdateValueForCharacteristic:error:
    // will receive a notification with calibration value
}

- (void)deconfigureBarometer:(CBPeripheral *)peripheral {
    
    CBUUID *serviceUUID        = [CBUUID UUIDWithString:BAROMETER_SERV_UUID];
    
    CBHelper *helper = [[CBHelper alloc] initWithPeripheral:peripheral
                                              serviceCBUUID:serviceUUID];
    
    // Say sensor should be disabled
    uint8_t data = 0x00;
    [helper writeCharacteristic:[CBUUID UUIDWithString:BAROMETER_CONF_UUID]
                           data:[NSData dataWithBytes:&data
                                               length:1]];
    
    // Say we don't want notifications any more
    [helper setNotificationForCharacteristic:[CBUUID UUIDWithString:BAROMETER_DATA_UUID]
                                      enable:NO];
}


#pragma mark - CBCentralManager delegate


- (void)centralManagerDidUpdateState:(CBCentralManager *)central {

    [self.delegate sensorDidUpdateState:self
                                  state:central.state];
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {

//    if (!((RSSI.integerValue == 0)  &&
//          (RSSI.integerValue == 0)) &&
//        ((RSSI.integerValue > _upperProximityValue) ||
//        (RSSI.integerValue < _lowerProximityValue))) {
//
//        return ;
//    }
    
    [_central stopScan];
    
    if (_connectedPeripheral != peripheral) {
    
        _connectedPeripheral = peripheral;

        [_central connectPeripheral:peripheral
                            options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    if (error) {
        NSLog(@"Peripheral disconnected with error: %@", [error localizedDescription]);
        [self putzen];
    }
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"Peripheral connected: %@", peripheral.identifier.UUIDString);

    NSArray *services = @[[CBUUID UUIDWithString:BAROMETER_SERV_UUID]];
    
    _connectedPeripheral.delegate = self;
    
    [_connectedPeripheral discoverServices:services];
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    
    NSLog(@"Connection to Peripheral failed: %@", peripheral.identifier.UUIDString);

    if (error) {
        [self putzen];
    }
}


#pragma mark - CBPeripheral delegate


- (void) peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error {
    
    NSLog(@"Discover characteristics for each service.");
    
    for (CBService *service in peripheral.services) {
        
        NSLog(@"Service found: %@", service.UUID);
        
        NSArray *characteristics = @[[CBUUID UUIDWithString:BAROMETER_CALI_UUID],
                                     [CBUUID UUIDWithString:BAROMETER_CONF_UUID],
                                     [CBUUID UUIDWithString:BAROMETER_DATA_UUID]];
        
        [peripheral discoverCharacteristics:characteristics
                                 forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error {
    if (error) {
        NSLog(@"Discovered characteristics with error: %@", [error localizedDescription]);
        [self putzen];

        return;
    }
    
    
    [self peripheral:peripheral configureCharacteristicsFormService:service];
}

- (void)peripheral:(CBPeripheral *)peripheral
configureCharacteristicsFormService:(CBService *)service {
    
    if ([service.UUID isEqual:[CBUUID UUIDWithString:BAROMETER_SERV_UUID]])  {
        NSLog(@"Discovered characteristics on service");
        
        [self configureBarometer:peripheral];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    NSLog(@"didUpdateNotificationStateForCharacteristic %@, error = %@", characteristic.UUID, error);
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    
    CBUUID *serviceUUID        = [CBUUID UUIDWithString:BAROMETER_SERV_UUID];
    
    CBHelper *helper = [[CBHelper alloc] initWithPeripheral:peripheral
                                              serviceCBUUID:serviceUUID];
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BAROMETER_CALI_UUID]]) {
        
        NSLog(@"write config to characteristic after calibration.");
        
        _barometerSensor = [[SensorC953A alloc] initWithCalibrationData:characteristic.value];
        
        //Issue normal operation to the device
        uint8_t data = 0x01;
        [helper writeCharacteristic:[CBUUID UUIDWithString:BAROMETER_CONF_UUID]
                               data:[NSData dataWithBytes:&data
                                                   length:1]];
    }
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BAROMETER_DATA_UUID]]) {
        
        NSLog(@"read value from characteristic");
        
        int pressure = [_barometerSensor calcPressure:characteristic.value];
        
        NSDictionary *sensorValues = @{@"pressure":[NSNumber numberWithInt:pressure]};

        [self deconfigureBarometer:_connectedPeripheral];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [_delegate sensorUpdateValue:self
                            sensorValues:sensorValues];
        });
    }
}

@end
