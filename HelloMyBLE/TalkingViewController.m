//
//  TalkingViewController.m
//  HelloMyBLE
//
//  Created by Ｍasqurin on 2017/7/26.
//  Copyright © 2017年 Ｍasqurin. All rights reserved.
//

#import "TalkingViewController.h"
#import "MUIBottonlineTextField.h"

@interface TalkingViewController ()<CBPeripheralDelegate>


@property (weak, nonatomic) IBOutlet MUIBottonlineTextField *inputTextField;

@property (weak, nonatomic) IBOutlet UITextView *logTextView;




@end

@implementation TalkingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //通訊工作前置準備
    
    //ble 可以讀寫資料 可能讀不出資料
    CBPeripheral *peripheral = _targetCharacteristic.service.peripheral;
    peripheral.delegate = self;
    //所以設定 訂閱模式 東西有資料主動通知
    [peripheral setNotifyValue:true forCharacteristic:_targetCharacteristic];
    
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    CBPeripheral *peripheral = _targetCharacteristic.service.peripheral;
    [peripheral setNotifyValue:false forCharacteristic:_targetCharacteristic];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sendBtnPressed:(id)sender {
    
    // input is empty
    if (_inputTextField.text.length == 0) {
        return;
    }
    
    //dismiss keyboard
    [_inputTextField resignFirstResponder];
    
    //Prepare content to send
    NSString *content = [NSString stringWithFormat:@"[Masqurin] %@\n",_inputTextField.text];
    _inputTextField.text = @"";
    //字串轉nsdata
    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    
    //測試發送 type兩種 會不會回傳 看是否要確保要不要一定要收到
    CBCharacteristicProperties properties = _targetCharacteristic.properties;
    //屬性內有沒有不要回報 沒有的話屬性是要回報
    CBCharacteristicWriteType type = (properties & CBCharacteristicPropertyWriteWithoutResponse)? CBCharacteristicWriteWithoutResponse:CBCharacteristicWriteWithResponse;
    
    //發送訊息給裝置
    [_targetCharacteristic.service.peripheral writeValue:data
                                       forCharacteristic:_targetCharacteristic
                                                    type:type];
}

#pragma mark - CBPeripheralDelegate
//接收訂閱通知
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    NSString *message;
    if (error) {
        message = error.description;
    }else{
        message = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    }
    
    _logTextView.text = [NSString stringWithFormat:@"%@%@",message,_logTextView.text];
}

//要回報的屬性才會觸發這個方法
-(void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
            error:(NSError *)error{
    if (error) {
        NSLog(@"didwriteValueForCharacteristic:%@",error);
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
