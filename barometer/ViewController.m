//
//  ViewController.m
//  barometer
//
//  Created by Jo Brunner on 19.02.16.
//  Copyright © 2016 Mayflower. All rights reserved.
//

#import "ViewController.h"
#import "SensorC953A.h"
#import "CBHelper.h"

#define BAROMETER_SERV_UUID @"F000AA40-0451-4000-B000-000000000000"
#define BAROMETER_DATA_UUID @"F000AA41-0451-4000-B000-000000000000"
#define BAROMETER_CONF_UUID @"F000AA42-0451-4000-B000-000000000000"
#define BAROMETER_CALI_UUID @"F000AA43-0451-4000-B000-000000000000"


@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *barometerValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *peripheralNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *peripheralIdentifierLabel;

@end

@implementation ViewController

@synthesize peripherals;

#pragma mark - ViewController

- (void)viewWillAppear:(BOOL)animated {

    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                               queue:nil];
    self.peripherals = [[NSMutableArray alloc]init];
}

- (void)viewWillDisappear:(BOOL)animated {

    // deconfigureBarometer...
}


#pragma mark - CBCentralManager delegate


-(void)centralManagerDidUpdateState:(CBCentralManager *)central {

    if (central.state != CBCentralManagerStatePoweredOn) {
        NSString *stateMessage = [NSString stringWithFormat:@"CoreBluetooth return state: %ld", (long)central.state];
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"BLE not supported!"
                                                           message:stateMessage
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        
        [alertView show];
    }
    else {
        NSLog(@"Now scan for peripherals.");

        [central scanForPeripheralsWithServices:nil
                                        options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI {

    NSLog(@"Peripheral discovered:\n%@\n%@\n", peripheral.name, peripheral.identifier.UUIDString);
    
    peripheral.delegate = self;

    [central connectPeripheral:peripheral
                       options:nil];

    if ([peripheral.identifier.UUIDString isEqualToString:BAROMETER_SERV_UUID]) {
        self.peripheralNameLabel.text = [NSString stringWithFormat:@"%@", peripheral.name];
        self.peripheralIdentifierLabel.text = [NSString stringWithFormat:@"%@", peripheral.identifier.UUIDString];
    }

    NSMutableArray *dummy = [[NSMutableArray alloc] init];
    [dummy addObject:peripheral];
    

    [self.peripherals addObject:peripheral];
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral {

    NSLog(@"Peripheral connected: %@", peripheral.identifier.UUIDString);
    NSLog(@"Discover Services/Characteristics on selected peripheral.");

    NSArray *services = @[[CBUUID UUIDWithString:BAROMETER_SERV_UUID]];

    [peripheral discoverServices:services];
}

- (void)centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    
    NSLog(@"Connection to Peripheral failed: %@", peripheral.identifier.UUIDString);
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

    [self peripheral:peripheral configureCharacteristicsFormService:service];
}


- (void)peripheral:(CBPeripheral *)peripheral
configureCharacteristicsFormService:(CBService *)service {

    if ([service.UUID isEqual:[CBUUID UUIDWithString:BAROMETER_SERV_UUID]])  {
        NSLog(@"Discovered characteristics on service");
        
        [self configureBarometer:peripheral];
    }
}

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
        
        self.barometerSensor = [[SensorC953A alloc] initWithCalibrationData:characteristic.value];
        
        //Issue normal operation to the device
        uint8_t data = 0x01;
        [helper writeCharacteristic:[CBUUID UUIDWithString:BAROMETER_CONF_UUID]
                               data:[NSData dataWithBytes:&data
                                                   length:1]];
    }
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:BAROMETER_DATA_UUID]]) {

        NSLog(@"read value from characteristic");
        
        int pressure = [self.barometerSensor calcPressure:characteristic.value];
        
        self.barometerValueLabel.text = [NSString stringWithFormat:@"%d hPa", pressure];
    }
}

@end
