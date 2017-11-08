//
//  SecondViewController.m
//  HelloMyBLE
//
//  Created by Ｍasqurin on 2017/7/21.
//  Copyright © 2017年 Ｍasqurin. All rights reserved.
//

#import "PeripheralViewController.h"
#import "MUIBottonlineTextField.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define SERVICE_UUID            @"8881"
#define CHARACTERISTIC_UUID     @"8882"
#define CHATROOM_NAME           @"5+1的聊天室"

@interface PeripheralViewController ()<CBPeripheralManagerDelegate>
{
    MUIBottonlineTextField *input;
    CBPeripheralManager *manager;
    CBMutableCharacteristic *myCharacteristic;
    
    NSMutableString *messageBuffer;
}
@property (weak, nonatomic) IBOutlet UIView *aaa;
@property (weak, nonatomic) IBOutlet UIButton *bbb;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@end
//模擬成裝置
@implementation PeripheralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    input = [MUIBottonlineTextField new];
    [_aaa addSubview: input];
    input.translatesAutoresizingMaskIntoConstraints = false;
    NSMutableArray <NSLayoutConstraint*>*lay = [NSMutableArray new];
    [lay addObject:[NSLayoutConstraint
                    constraintWithItem:input
                    attribute:NSLayoutAttributeLeft
                    relatedBy:NSLayoutRelationEqual
                    toItem:_aaa
                    attribute:NSLayoutAttributeLeft
                    multiplier:1.0
                    constant:0.0]];
    [lay addObject:[NSLayoutConstraint
                    constraintWithItem:input
                    attribute:NSLayoutAttributeRight
                    relatedBy:NSLayoutRelationEqual
                    toItem:_bbb
                    attribute:NSLayoutAttributeRight
                    multiplier:1.0 constant:-50.0]];
    [lay addObject:[NSLayoutConstraint
                    constraintWithItem:input
                    attribute:NSLayoutAttributeCenterX
                    relatedBy:NSLayoutRelationEqual
                    toItem:_aaa
                    attribute:NSLayoutAttributeCenterX
                    multiplier:1.0 constant:0.0]];
    [lay addObject:[NSLayoutConstraint
                    constraintWithItem:input
                    attribute:NSLayoutAttributeCenterY
                    relatedBy:NSLayoutRelationEqual
                    toItem:_aaa
                    attribute:NSLayoutAttributeCenterY
                    multiplier:1.0 constant:0.0]];
    [_aaa addConstraints:lay];
    
    manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)enableSwitchValueChanged:(id)sender {
    if ([sender isOn]) {
        [self startToAdvertise];
    }else{
        [self stopAdvertise];
    }
}

//開始廣播 播放給接收主控的訊息
-(void) startToAdvertise{
    
    CBUUID *serviceUUID = [CBUUID UUIDWithString:SERVICE_UUID];
    
    if (myCharacteristic == nil) {
        //生出characteristic
        CBUUID *characteristicUUID = [CBUUID UUIDWithString:CHARACTERISTIC_UUID];
        //prepare characteristic 屬性資訊 被中心讀取
        CBCharacteristicProperties properties =
        CBCharacteristicPropertyWrite |
        CBCharacteristicPropertyRead |
        CBCharacteristicPropertyNotify;
        //怎樣被存取 可讀可寫
        CBAttributePermissions permissions =
        CBAttributePermissionsReadable |
        CBAttributePermissionsWriteable;
        
        myCharacteristic = [[CBMutableCharacteristic alloc]
                            initWithType:characteristicUUID
                            properties:properties
                            value:nil
                            permissions:permissions];
        //prepare service
        CBMutableService *myService = [[CBMutableService alloc]
                                       initWithType:serviceUUID
                                       primary:true];
        
        myService.characteristics = @[myCharacteristic];
        [manager addService:myService];
        
        //        NSInteger i = 5;
        //        NSInteger j = i * 2;
        //        NSInteger j << 1; 同上 效能更好
        
    }
    
    //Start Advertising!
    NSArray *uuids = @[serviceUUID];//把要廣播的uuid放入array!!! 藍牙機制 可以廣播很多個service characteristic
    NSDictionary *info = @{CBAdvertisementDataLocalNameKey: CHATROOM_NAME,CBAdvertisementDataServiceUUIDsKey: uuids};
    [manager startAdvertising:info];
}

-(void) stopAdvertise{
    [manager stopAdvertising];
}

-(void) sendText:(NSString*) text
         central:(CBCentral*) central {
    
    NSArray *centrals = (central == nil) ? nil : @[central];
    NSData *data= [text dataUsingEncoding:NSUTF8StringEncoding];
    
    BOOL result = [manager updateValue:data forCharacteristic:myCharacteristic onSubscribedCentrals:centrals];
    NSLog(@"Send: %@",text);
    NSLog(@"Result: %@",(result?@"OK":@"Fail"));
    
    //keep the text
    //因為藍牙不穩定 連續發送 容易失敗 所以發送失敗的就暫存 之後再一次發送
    if (result == false) {
        messageBuffer = [NSMutableString stringWithString:text];
    }else{
        [messageBuffer appendString:text];
    }
    
}

- (IBAction)sendBtnPressed:(id)sender {
    
    if (input.text.length == 0) {
        return;
    }
    
    NSString *message = [NSString stringWithFormat:@"[%@] %@\n",CHATROOM_NAME,input.text];
    [self sendText:message central:nil];
    _logTextView.text = [NSString stringWithFormat:@"[%@] %@\n",CHATROOM_NAME,_logTextView.text];
    input.text = @"";
}

#pragma Mark - CBPeripheralManagerDelegate
-(void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    
    CBManagerState state = peripheral.state;
    
    if (state != CBManagerStatePoweredOn) {
        NSLog(@"BLE is not available. (%ld)",(long)state);
    }
    
}

//任何主控「訂閱」連入觸發方法
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    
    NSString *info = [NSString stringWithFormat:@"* Central subscribed: UUID %@,max: %lu\n",central.identifier.UUIDString,central.maximumUpdateValueLength];
    //其他主控連近裝置 裝置主人自己看見訊息
    _logTextView.text = [NSString stringWithFormat:@"%@%@",info,_logTextView.text];
    
    //say hello
    NSString *hello = [NSString stringWithFormat:@"[%@] 您好 歡迎光臨!(Total: %ld)\n",CHATROOM_NAME,myCharacteristic.subscribedCentrals.count];
    //針對近來的人發訊息
    [self sendText:hello central:central];
    NSString *someCComing = [NSString stringWithFormat:@"[%@] SomeComing!(Total: %ld)\n",CHATROOM_NAME,myCharacteristic.subscribedCentrals.count];
    //nil對全部的人發訊息
    [self sendText:someCComing central:nil];
    
}
//任何主控離線「停止訂閱」觸發方法
-(void)peripheralManager:(CBPeripheralManager *)peripheral
                 central:(CBCentral *)central
                didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    
    NSString *someCComing = [NSString stringWithFormat:@"[%@] 五狼照阿!(Total: %ld)\n",CHATROOM_NAME,myCharacteristic.subscribedCentrals.count];
    [self sendText:someCComing central:nil];
}

//準備更新訊息呼叫方法「前一筆結束後」
-(void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral{
    NSLog(@"peripheralManagerIsReadyToUpdateSubscribers.");
    
    [self sendText:messageBuffer central:nil];
    messageBuffer = nil;
}

//收到寫入請求觸發
-(void)peripheralManager:(CBPeripheralManager *)peripheral
 didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests{
    
    for (CBATTRequest *tmp in requests) {
        NSString *content = [[NSString alloc] initWithData:tmp.value encoding:NSUTF8StringEncoding];
        //裝置寫入傳來正常 廣播給所有人
        if (content != nil) {
            _logTextView.text = [NSString stringWithFormat:@"%@%@",content,_logTextView.text];
            [self sendText:content central:nil];
        }
        //重要 封包異常 回傳收到異常封包
        [manager respondToRequest:tmp withResult:CBATTErrorSuccess];//回應 避免central以為沒收到
    }
    
}

@end
