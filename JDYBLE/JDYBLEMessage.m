//
//  JDYBLEMessage.m
//  JDYBLE
//
//  Created by zqf on 16/6/13.
//  Copyright © 2016年 zengqingfu. All rights reserved.
//

#define kMPOSServiceUUID @"49535343-FE7D-4AE5-8FA9-9FAFD205E455"
#define kMPOSWriteUUID @"49535343-8841-43F4-A8D4-ECBE34729BB3"
#define kMPOSNofifyUUID @"49535343-1E4D-4BD9-BA61-23C647249616"

#import "JDYBLEMessage.h"

@interface JDYBLEMessage()

@property (nonatomic, readonly)CBPeripheral *peripheral;
//UUID
@property (nonatomic, strong)CBUUID *mPosServiceUUID;
@property (nonatomic, strong)CBUUID *mPosNofifyUUID;
@property (nonatomic, strong)CBUUID *mPosWriteUUID;

//特征值
@property (nonatomic, strong)CBCharacteristic *mPosNotifyCharacteristic;
@property (nonatomic, strong)CBCharacteristic *mPosWriteCharacteristic;

//block
@property (nonatomic, copy)void (^receivePeripheralMessageBlock)(NSData *data, NSError *error);
@property (nonatomic, copy)void (^sendMessageCompleteBlock)(NSError *error);

@end
@implementation JDYBLEMessage
- (instancetype)init {
    self = [super init];
    if (self) {
        self.mPosServiceUUID = [CBUUID UUIDWithString:kMPOSServiceUUID];
        self.mPosNofifyUUID  = [CBUUID UUIDWithString:kMPOSNofifyUUID];
        self.mPosWriteUUID   = [CBUUID UUIDWithString:kMPOSWriteUUID];
    }
    return self;
}

- (void)sendData:(NSData *)data type:(CBCharacteristicWriteType) type sendMessageCompleteBlock:(void (^)(NSError *))block {
    if (_mPosWriteCharacteristic) {
        self.sendMessageCompleteBlock = block;
        [_peripheral writeValue:data forCharacteristic:_mPosWriteCharacteristic type:type];
    }
}

- (void)setReceiveMessageBlock:(void (^)(NSData *data, NSError *error))block {
    self.receivePeripheralMessageBlock = block;
}

#pragma mark --pravate--
- (void)foundService {
    [self whenDisconnectBT];
    [_peripheral discoverServices:@[_mPosServiceUUID]];
}

- (void)whenDisconnectBT {
    _canReceiveData = NO;
    _canSendData = NO;
    _mPosNotifyCharacteristic = nil;
    _mPosWriteCharacteristic = nil;
}

#pragma mark --peripheraldelegate
//------peripheraldelegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    for (CBService *service in peripheral.services) {
        if ([service.UUID.data isEqualToData:_mPosServiceUUID.data]) {
            [_peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

//发现特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic *c in service.characteristics) {
        if ([c.UUID.data isEqualToData:_mPosNofifyUUID.data]) {
            self.mPosNotifyCharacteristic = c;
            [_peripheral setNotifyValue:YES forCharacteristic:c];
            _canReceiveData = YES;
            continue;
        }else if ([c.UUID.data isEqualToData:_mPosWriteUUID.data]) {
            self.mPosWriteCharacteristic = c;
            _canSendData= YES;
            continue;
        }
    }
}

//接收订阅消息
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (_receivePeripheralMessageBlock) {
        _receivePeripheralMessageBlock(characteristic.value, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (_sendMessageCompleteBlock) {
        _sendMessageCompleteBlock(error);
    }
}
@end