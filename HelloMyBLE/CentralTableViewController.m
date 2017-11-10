//
//  CentralTableViewController.m
//  HelloMyBLE
//
//  Created by Ｍasqurin on 2017/7/21.
//  Copyright © 2017年 Ｍasqurin. All rights reserved.
//

#import "CentralTableViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "DiscoveredItem.h"
//連線對象的識別方法
#define TARGET_UUID_PEFIX @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"//@"8882" //@"FFE1" @"DFB1" @"8882"

//搜索藍牙
@interface CentralTableViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    CBCentralManager *manager;
    
    NSMutableDictionary *allItems;
    NSDate *lastReloadDataDate;
    
    NSMutableArray *restServices;
    NSMutableString *info;
    
    //for talking support
    BOOL isTalkingMode;
    CBCharacteristic *talkingCharacteristic;
}
@end

@implementation CentralTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //可能負載重 可以建立背景給他跑
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    allItems = [NSMutableDictionary new];
//    allItems = [NSMutableDictionary dictionary];  Autorelease自動消滅的物件 new的要自己建立自己消滅「在mrc時代」 現在arc用new是比較好的選擇
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated{
    //Disconnect connection and startToScan again after return from TalkingViewController
    //talk回來後 斷線 重新掃描
    
    [super viewDidAppear: animated];
    if (talkingCharacteristic != nil) {
        [manager cancelPeripheralConnection:talkingCharacteristic.service.peripheral];
        //如果沒斷線 回源頭斷線
        talkingCharacteristic = nil;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return allItems.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView
                             dequeueReusableCellWithIdentifier:@"cell"
                             forIndexPath:indexPath];
    
    //key排序可順序拿出uuid 及其他相關資訊
    NSArray *allKeys = allItems.allKeys;// dictionary的key在沒有新物件下 allkeys順序不便
    NSString *targetUUIDString = allKeys [indexPath.row];
    DiscoveredItem *item = allItems[targetUUIDString];
    
    NSString *line1String = [NSString stringWithFormat:@"%@ RSSI:%ld",item.peripheral.name,item.lastRSSI];
    NSString *line2String = [NSString stringWithFormat:@"Last Seen:%.1f seconds ago.",[[NSDate date] timeIntervalSinceDate:item.lastSeenDate]];
    
    cell.textLabel.text = line1String;
    cell.detailTextLabel.text = line2String;
    
    return cell;
}
//點下i按鈕連接對方藍牙裝置
-(void)tableView:(UITableView *)tableView
    accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    
    [self connectWithIndexPath:indexPath];
    //不要溝通 純掃描
    isTalkingMode = false;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //要溝通前 做的事跟掃描一樣 再char做不一樣的事
    
    NSLog(@"\n=============================");
    
    [self connectWithIndexPath:indexPath];
    //如果要溝通 跟掃描做區別
    isTalkingMode = true;
}

//基於某些考量 連接動作另外做
-(void)connectWithIndexPath:(NSIndexPath*)indexPath{
    NSArray *allKeys = allItems.allKeys;                // dictionary的key在沒有新物件下 allkeys順序不便
    NSString *targetUUIDString = allKeys [indexPath.row];
    DiscoveredItem *item = allItems[targetUUIDString];
    
    [manager connectPeripheral:item.peripheral options:nil];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    //ios架構所有元件幾乎都是 key value
    //key 就是porperty value內容
    //key必須跟property一模一樣 包含大小寫
    
    if ([segue.identifier isEqualToString:@"goTalking"]) {
        id vc = segue.destinationViewController;
        [vc setValue:talkingCharacteristic forKey:@"targetCharacteristic"];
    }
    
}

- (IBAction)scanEnableValueChanged:(id)sender {
    if ([sender isOn]) {
        [self starToScan];
    }else{
        [self stopScanning];
    }
}
//連上某設備時 掃描停止 以省電 所以拉出來獨立寫 讓程式碼重複利用
-(void)starToScan{
    
    CBUUID *service1 = [CBUUID UUIDWithString:@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"];
    CBUUID *service2 = [CBUUID UUIDWithString:@"180A"];
    
    NSArray *services = @[service1,service2];
    NSDictionary *options =
        @{CBCentralManagerScanOptionAllowDuplicatesKey:@(true)};
    [manager scanForPeripheralsWithServices:services
                                    options:options];
    
}

-(void)stopScanning{
    [manager stopScan];
}

-(void)showAlert:(NSString*) message{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:ok];
    [self presentViewController:alert animated:true completion:nil];
}

#pragma mark - CBCentralDelegate Methods
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    CBManagerState state = central.state;
    if (state != CBManagerStatePoweredOn) {
        NSString *message = [NSString stringWithFormat:@"BLE is not available(error:%ld),",(long)state];
        [self showAlert:message];
    }
}
//每收到一個廣播就呼叫一次這個方法
-(void)centralManager:(CBCentralManager *)central
didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                 RSSI:(NSNumber *)RSSI{
    DiscoveredItem *existItem = allItems[peripheral.identifier.UUIDString];
    //首次廣播show log
    if (existItem == nil) {
        NSLog(@"Discover:%@,RSSI:%ld,UUID:%@,Data:%@",peripheral.name,RSSI.integerValue,peripheral.identifier,advertisementData.description);
    }
    NSDate *now = [NSDate date];
    
    //Prepare newItems
    DiscoveredItem *newItem = [DiscoveredItem new];
    newItem.peripheral = peripheral;
    newItem.lastRSSI = RSSI.integerValue;
    newItem.lastSeenDate = now;
    //Add to allItems.
    [allItems setObject:newItem
                 forKey:peripheral.identifier.UUIDString];
    // Check if we should make tableView reload data.
    if (existItem == nil ||                                     //發現新設備
        lastReloadDataDate == nil ||                            //重來沒有刷新過 沒必要存在
        [now timeIntervalSinceDate:lastReloadDataDate] > 3.0) { //上次刷新時間超過三秒
        lastReloadDataDate = now;                               //保存時間
        [self.tableView reloadData];                            //刷新畫面
    }
}
//連結裝置呼叫方法
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    NSLog(@"didconnectPeripheral: %@",peripheral.name);
    
    [self stopScanning];
    
    //Start discover services of peripheral.
    peripheral.delegate = self;
    [peripheral discoverServices:@[]];  //要求設備回報支援的services
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSString *message = [NSString stringWithFormat:@"Fail to connect: %@ (%@)",peripheral.name,error];
    [self showAlert:message];
}
//曾經成功連上又斷掉
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    [self starToScan];  //斷線後恢復掃描
}
//發現哪些可支援的services
#pragma mark - CBPeripheralDelegate Methods
-(void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error{
    if (error) {                                        //如果發現過程出包就斷線以及...
        NSLog(@"didDiscoverServices Fail: %@",error);
        [manager cancelPeripheralConnection:peripheral];
        return;     //段開後就到曾經連上又斷線
    }
    //try to discover characteristics of each service
    restServices = [NSMutableArray arrayWithArray:peripheral.services];
    CBService *service = restServices.firstObject;
    [restServices removeObjectAtIndex:0];
    
    [peripheral discoverCharacteristics:nil forService:service];//cbt 底層受限 一次發n個命令 會異常 要等第一個掃玩回報再掃第二個
    //Prepare info
    info = [NSMutableString new];
    [info appendFormat:@"*** Peripheral: %@ (%ld services)\n",peripheral.name,peripheral.services.count];
}
//發現到的services
-(void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
            error:(NSError *)error{
    if (error) {                                        //如果發現過程出包就斷線以及...
        NSLog(@"didDiscoverCharacteristicsForService Fail: %@\n",error);
        [manager cancelPeripheralConnection:peripheral];
        return;     //段開後就到曾經連上又斷線
    }
    //Collect service's informat to info
    [info appendFormat:@"** Service: %@ (%ld chars.)\n",service.UUID.UUIDString,service.characteristics.count];
    
    //collect characteristics' information to info
    for (CBCharacteristic *tmp in service.characteristics) {
        [info appendFormat:@"* Char.: %@\n",tmp.UUID.UUIDString];
        //check if it is talking mode ,and it is what we are looking for
//        NSLog(@"\n%d\n%@",isTalkingMode,tmp.UUID.UUIDString);
        
        NSLog(@"data = %@",tmp.value.description);
        
        if (isTalkingMode || tmp.value == nil) {
            
            UInt8 a = 0xE1;
            UInt8 b = 0x04;
            UInt8 c = 0x52;
            UInt8 d = 0x0B;
            UInt8 e = 0xB8;
            
            UInt8 g = ~(a + b + c + d + e) ;
            
            const char pump[] = {a,b,c,d,e,g};
            
            UInt8 read = 0xE0;
            UInt8 two = 0x02;
            UInt8 temp =0xa1;
            UInt8 j = 0xb0;
            
            const char myByteArray[] = {read,two,j,~(read+two+j)};
            
            const char tempcall[] = {read,two,temp,~(read+two+temp)};
            
            UInt8 k = 0xE1;
            UInt8 l = 0x04;
            UInt8 m = 0xaf;
            UInt8 n = 0xff;
            UInt8 o = 0xff;
            
            
            const char sensor[] = {k,l,m,n,o,~(k+l+m+n+o)};
            
            tmp.service.peripheral.delegate = self;
            //所以設定 訂閱模式 東西有資料主動通知
            [peripheral setNotifyValue:true forCharacteristic:tmp];
            
            
            
            [peripheral writeValue:[NSData dataWithBytes: sensor length:6] forCharacteristic:tmp type:CBCharacteristicWriteWithResponse];
            [peripheral writeValue:[NSData dataWithBytes: pump length:6] forCharacteristic:tmp type:CBCharacteristicWriteWithResponse];
            [peripheral writeValue:[NSData dataWithBytes: myByteArray length:4] forCharacteristic:tmp type:CBCharacteristicWriteWithResponse];
//            [peripheral writeValue:[NSData dataWithBytes: tempcall length:4] forCharacteristic:tmp type:CBCharacteristicWriteWithResponse];
            
        }
        
        
//        if (isTalkingMode && [tmp.UUID.UUIDString hasPrefix:TARGET_UUID_PEFIX]) {
//            talkingCharacteristic = tmp;
//            [self performSegueWithIdentifier:@"goTalking" sender:nil];
//            return;
//        }
        
    }
    
    //Next step?
    if (restServices.count == 0) {
        
        [self showAlert:info];
        [manager cancelPeripheralConnection:peripheral];
    }else{
        //如果還有其他service繼續掃描
        
        CBService *service = restServices.firstObject;
        [restServices removeObjectAtIndex:0];
        
        [peripheral discoverCharacteristics:nil forService:service];
    }
    
}
//訂閱
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    NSString *message;
    if (error) {
        message = error.description;
    }else{
        message = characteristic.value.description ;
    }
    
    NSLog(@"\n訂閱 %@",message);
}


//回報
-(void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
            error:(NSError *)error{
    
    NSLog(@"\n回報 %@",characteristic.value );
    
    
    if (error) {
        NSLog(@"didwriteValueForCharacteristic:%@",error);
    }
}



@end
