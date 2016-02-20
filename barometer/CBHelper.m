//
//  CBHelper.h
//
//  Created by Jo Brunner on 18.02.16.
//  Copyright © 2016 Jo Brunner. All rights reserved.
//

@import CoreBluetooth;

#import "CBHelper.h"

@implementation CBHelper

- (id)initWithPeripheral:(CBPeripheral *)peripheral
             serviceUUID:(NSString *)serviceUUID {
 
    CBUUID *serviceCBUUID = [CBUUID UUIDWithString:serviceUUID];
    
    return [self initWithPeripheral:peripheral
               serviceCBUUID:serviceCBUUID];
}

- (id)initWithPeripheral:(CBPeripheral *)peripheral
             serviceCBUUID:(CBUUID *)serviceCBUUID {

    if (self = [super init]) {
        self.peripheral    = peripheral;
        self.serviceCBUUID = serviceCBUUID;
    }

    return self;
}

- (void)writeCharacteristic:(CBUUID *)characteristicCBUUID
                       data:(NSData *)data {
    
    for (CBService *service in self.peripheral.services) {
        if ([service.UUID isEqual:self.serviceCBUUID]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:characteristicCBUUID]) {
                    
                    [self.peripheral writeValue:data
                              forCharacteristic:characteristic
                                           type:CBCharacteristicWriteWithResponse];
                }
            }
        }
    }
}

- (void)readCharacteristic:(CBUUID *)characteristicCBUUID {
    
    for (CBService *service in self.peripheral.services) {
        if ([service.UUID isEqual:self.serviceCBUUID]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:characteristicCBUUID]) {
                    
                    [self.peripheral readValueForCharacteristic:characteristic];
                }
            }
        }
    }
}

- (void)setNotificationForCharacteristic:(CBUUID *)characteristicCBUUID
                                  enable:(BOOL)enable {
    
    for (CBService *service in self.peripheral.services ) {
        if ([service.UUID isEqual:self.serviceCBUUID]) {
            for (CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:characteristicCBUUID]) {
                    
                    [self.peripheral setNotifyValue:enable
                                  forCharacteristic:characteristic];
                }
            }
        }
    }
}

- (bool)isCharacteristicNotifiable:(CBUUID *)characteristicCBUUID {
    
    for (CBService *service in self.peripheral.services ) {
        if ([service.UUID isEqual:self.serviceCBUUID]) {
            for (CBCharacteristic *characteristic in service.characteristics ) {
                if ([characteristic.UUID isEqual:characteristicCBUUID]) {
                    
                    return (characteristic.properties & CBCharacteristicPropertyNotify) ? YES : NO;
                }
            }
        }
    }
    
    return NO;
}

@end
