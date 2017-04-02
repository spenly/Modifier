//
//  ViewController.m
//  Modifier
//
//  Created by spenly.jia on 2017/3/24.
//  Copyright © 2017年 spenly.jia. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *numInputTextField;
@property (strong, nonatomic) HKHealthStore *healthStore;
@property (weak, nonatomic) IBOutlet UITextView *operationLogTextView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.numInputTextField.delegate = self;
    [self isHealthDataAvailable];
    self.operationLogTextView.text = @"Just input steps number you want\nThen press RETURN";
}

#pragma mark - 获取健康权限
- (void)isHealthDataAvailable{
    if ([HKHealthStore isHealthDataAvailable]) {
        self.healthStore = [[HKHealthStore alloc]init];
        NSSet *writeDataTypes = [self dataTypesToWrite];
        NSSet *readDataTypes = [self dataTypesToRead];
        [self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError *error) {
            if (!success) {
                NSString * msg = [NSString stringWithFormat:@"You didn't allow to read & write & share your health data. Error shows: %@", error];
                [self showMessage:msg];
                return;
            }
        }];
    }
}

#pragma mark - 设置写入权限
- (NSSet *)dataTypesToWrite {
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    return [NSSet setWithObjects:stepType, nil];
}

#pragma mark - 设置读取权限
- (NSSet *)dataTypesToRead {
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    return [NSSet setWithObjects:stepType, nil];
}


#pragma mark - 获取步数 刷新界面
- (void)getStepsFromHealthKit{
    HKQuantityType *stepType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    [self fetchSumOfSamplesTodayForType:stepType unit:[HKUnit countUnit] completion:^(double stepCount, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString * msg = [NSString stringWithFormat:@"## Steps number updates to %.f",stepCount];
            [self showMessage:msg];
        });
    }];
}

#pragma mark - 读取HealthKit数据
- (void)fetchSumOfSamplesTodayForType:(HKQuantityType *)quantityType unit:(HKUnit *)unit completion:(void (^)(double, NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSamplesToday];
    
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        HKQuantity *sum = [result sumQuantity];
        if (completionHandler) {
            double value = [sum doubleValueForUnit:unit];
            completionHandler(value, error);
        }
    }];
    [self.healthStore executeQuery:query];
}

#pragma mark - NSPredicate数据模型
- (NSPredicate *)predicateForSamplesToday {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *now = [NSDate date];
    NSDate *startDate = [calendar startOfDayForDate:now];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}


#pragma mark - 添加步数
- (void)addstepWithStepNum:(double)stepNum {
    HKQuantitySample *stepCorrelationItem = [self stepCorrelationWithStepNum:stepNum];
    [self.healthStore saveObject:stepCorrelationItem withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                [self.view endEditing:YES];
                NSString * msg = [NSString stringWithFormat:@"#Add number success."];
                [self showMessage:msg];
                [self getStepsFromHealthKit];
            }else {
                NSString * msg = [NSString stringWithFormat:@"#Add number failed."];
                [self showMessage:msg];
                return ;
            }
    }];
}

#pragma Mark - 获取HKQuantitySample数据模型
- (HKQuantitySample *)stepCorrelationWithStepNum:(double)stepNum {
    NSDate *endDate = [NSDate date];
    NSDate *startDate = [NSDate dateWithTimeInterval:-300 sinceDate:endDate];
    
    HKQuantity *stepQuantityConsumed = [HKQuantity quantityWithUnit:[HKUnit countUnit] doubleValue:stepNum];
    HKQuantityType *stepConsumedType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    NSString *strName = [[UIDevice currentDevice] name];
    NSString *strModel = [[UIDevice currentDevice] model];
    NSString *strSysVersion = [[UIDevice currentDevice] systemVersion];
    NSString *localeIdentifier = [[NSLocale currentLocale] localeIdentifier];
    
    HKDevice *device = [[HKDevice alloc] initWithName:strName manufacturer:@"Apple" model:strModel hardwareVersion:strModel firmwareVersion:strModel softwareVersion:strSysVersion localIdentifier:localeIdentifier UDIDeviceIdentifier:localeIdentifier];
    
    HKQuantitySample *stepConsumedSample = [HKQuantitySample quantitySampleWithType:stepConsumedType quantity:stepQuantityConsumed startDate:startDate endDate:endDate device:device metadata:nil];
    
    return stepConsumedSample;
}

- (void) showMessage:(NSString *) msg{
    if (![msg isEqualToString:@""]){
        msg = [NSString stringWithFormat:@"%@\n%@",self.operationLogTextView.text, msg];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.operationLogTextView.text=msg;
        });
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:self.numInputTextField]){
        NSString * snum = self.numInputTextField.text;
        int inum = [snum intValue];
        if (inum > 0) {
            NSString * msg = [NSString stringWithFormat:@"#Input value: %i", inum];
            [self showMessage:msg];
            [self addstepWithStepNum:inum];
            [self.numInputTextField endEditing:YES];
        }
    }
    return NO;
}


@end
