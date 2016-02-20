//
//  CBHelper.h
//
//  Created by Jo Brunner on 18.02.16.
//  Copyright © 2016 Jo Brunner. All rights reserved.
//

@class CBPeripheral;
@class CBUUID;
@class NSObject;

@interface CBHelper : NSObject

@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) CBUUID *serviceCBUUID;

- (id)initWithPeripheral:(CBPeripheral *)peripheral
             serviceUUID:(NSString *)serviceUUID;

- (id)initWithPeripheral:(CBPeripheral *)peripheral
           serviceCBUUID:(CBUUID *)serviceCBUUID;

- (void)writeCharacteristic:(CBUUID *)characteristicCBUUID
                       data:(NSData *)data;

- (void)readCharacteristic:(CBUUID *)characteristicCBUUID;

- (void)setNotificationForCharacteristic:(CBUUID *)characteristicCBUUID
                                  enable:(BOOL)enable;

- (bool)isCharacteristicNotifiable:(CBUUID *)characteristicCBUUID;

@end
