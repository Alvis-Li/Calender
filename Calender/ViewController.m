//
//  ViewController.m
//  Calender
//
//  Created by levy on 15/12/24.
//  Copyright © 2015年 levy. All rights reserved.
//

#import "ViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface ViewController (){
    double todayLunarDate;
    double todaySolarDate;
    
    NSInteger thisLunarYear;
    NSInteger thisLunarMonth;
    NSInteger thisLunarDay;
    
    NSInteger thisSolarYear;
    NSInteger thisSolarMonth;
    NSInteger thisSolarDay;
}
@property (strong,nonatomic)JSContext *context;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *JSPath = [[NSBundle mainBundle] pathForResource:@"calendar" ofType:@"js"];
    NSString *JSCont = [NSString stringWithContentsOfFile:JSPath encoding:NSUTF8StringEncoding error:nil];
    self.context = [JSContext new];
    [self.context evaluateScript:JSCont];
    //获取今天的农历
    NSString * todayDate = [NSString stringWithFormat:@"%@",[NSDate date]];
    NSInteger y = [[todayDate substringToIndex:4] integerValue];
    NSInteger m = [[todayDate substringWithRange:NSMakeRange(5, 2)] integerValue];
    NSInteger d = [[todayDate substringWithRange:NSMakeRange(8, 2)] integerValue];
    
    JSValue *n = [self.context[@"solar2lunar"] callWithArguments:@[@(2014),@(11),@(2)]];
    NSDictionary *dic = [NSDictionary dictionaryWithDictionary:[n toDictionary]];
    //NSLog(@"%@",dic);
    if (dic && dic[@"lYear"] && dic[@"lMonth"] && dic[@"lDay"]) {
        thisLunarYear = [dic[@"lYear"] integerValue];
        thisLunarMonth = [dic[@"lMonth"] integerValue];
        thisLunarDay = [dic[@"lDay"] integerValue];
        todayLunarDate = thisLunarYear*10000 + thisLunarMonth * 100 + thisLunarDay;
        
        thisSolarYear = [dic[@"cYear"] integerValue];
        thisSolarMonth = [dic[@"cMonth"] integerValue];
        thisSolarDay = [dic[@"cDay"] integerValue];
        todaySolarDate = thisSolarYear*10000 + thisSolarMonth*100 + thisSolarDay;
    }
    
   NSTimeInterval date = [self nextLunarBirthWithbirth:@"20140909" isLeapMonth:NO];
    NSLog(@"%.f",date);
}


-(NSTimeInterval)nextLunarBirthWithbirth:(NSString *)birth isLeapMonth:(BOOL)isLeapMonth{
    NSInteger birthMonth = [[birth substringWithRange:NSMakeRange(4, 2)] integerValue];
    NSInteger birthday = [[birth substringFromIndex:6] integerValue];
    
    JSValue *n = [self.context[@"leapMonth"] callWithArguments:@[@(thisLunarYear)]];
    if ([n toInt32] == 0) { //无闰月
        if (birthMonth > thisLunarMonth) {//未过生日
        return [self lunarToSolarWithYear:thisLunarYear month:birthMonth day:birthday];
        }else if(birthMonth < thisLunarMonth){ //已过生日
            return [self lunarToSolarWithYear:thisLunarYear+1 month:birthMonth day:birthday];
        }else if(birthMonth == thisLunarMonth){ //在同一月内
            if (birthday > thisLunarDay) {
               return [self lunarToSolarWithYear:thisLunarYear month:birthMonth day:birthday];
            }else if(birthday < thisLunarDay){
                return [self lunarToSolarWithYear:thisLunarYear+1 month:birthMonth day:birthday];
            }else if (birthday == thisLunarDay){
                return [[NSDate date] timeIntervalSince1970];
            }
        }
    }else { //有闰月
        if (birthMonth > thisLunarMonth) {//未过生日
            return [self lunarToSolarWithYear:thisLunarYear month:birthMonth day:birthday];
        }else if(birthMonth < thisLunarMonth){ //已过生日
            return [self lunarToSolarWithYear:thisLunarYear+1 month:birthMonth day:birthday];
        }else if(birthMonth == thisLunarMonth){ //在同一月内
            if([n toInt32] != birthMonth){
                
                if (birthday > thisLunarDay) {
                    return [self lunarToSolarWithYear:thisLunarYear month:birthMonth day:birthday];
                }else if(birthday < thisLunarDay){
                    return [self lunarToSolarWithYear:thisLunarYear+1 month:birthMonth day:birthday];
                }else if (birthday == thisLunarDay){
                    return [[NSDate date] timeIntervalSince1970];
                }
                
            }else{
                return [self leapLunarToSolarWithYear:thisLunarYear month:birthMonth day:birthday];
                
            }
            
        }
    }
    return 0;
}

-(NSTimeInterval)leapLunarToSolarWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day{
    double solarDateOne = 0;
    double solarDateTwo = 0;
    
    JSValue * n = [self.context[@"lunar2solar"] callWithArguments:@[@(year),@(month),@(day),@0]];
    NSDictionary * dic = [NSDictionary dictionaryWithDictionary:[n toDictionary]];
    if (dic && dic[@"cYear"] && dic[@"cMonth"] && dic[@"cDay"]) {
        solarDateOne = [dic[@"cYear"] integerValue]*10000 + [dic[@"cMonth"] integerValue]*100 + [dic[@"cDay"] integerValue];
    }
    
    n = [self.context[@"lunar2solar"] callWithArguments:@[@(year),@(month),@(day),@1]];
    dic = [NSDictionary dictionaryWithDictionary:[n toDictionary]];
    if (dic && dic[@"cYear"] && dic[@"cMonth"] && dic[@"cDay"]) {
        solarDateTwo = [dic[@"cYear"] integerValue]*10000 + [dic[@"cMonth"] integerValue]*100 + [dic[@"cDay"] integerValue];
    }
    
    if (solarDateOne && solarDateTwo) {
        if (todaySolarDate < solarDateOne && todaySolarDate < solarDateTwo) {
            return [self notificationWithString:[NSString stringWithFormat:@"%.f",solarDateOne]];
        }else if(solarDateOne < todaySolarDate && todaySolarDate < solarDateTwo){
            return [self notificationWithString:[NSString stringWithFormat:@"%.f",solarDateTwo]];
        }else if(solarDateTwo < todaySolarDate && solarDateOne < todaySolarDate){
            return [self lunarToSolarWithYear:year+1 month:month day:day];
        }else if(solarDateOne == todaySolarDate || solarDateTwo == todaySolarDate){
            return [[NSDate date] timeIntervalSince1970];
        }
    }
    return 0;
}

-(NSTimeInterval)lunarToSolarWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day{
    JSValue * n = [self.context[@"lunar2solar"] callWithArguments:@[@(year),@(month),@(day)]];
    NSDictionary * dic = [NSDictionary dictionaryWithDictionary:[n toDictionary]];
    if (dic && dic[@"cYear"] && dic[@"cMonth"] && dic[@"cDay"]) {
        double date = [dic[@"cYear"] integerValue]*10000 + [dic[@"cMonth"] integerValue]*100 + [dic[@"cDay"] integerValue];
        return [self notificationWithString:[NSString stringWithFormat:@"%.f",date]];
    }
    return 0;
}

-(NSTimeInterval)notificationWithString:(NSString *)string{
    NSDateFormatter *inputFormatter= [[NSDateFormatter alloc] init];
    [inputFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [inputFormatter setDateFormat:@"yyyyMMdd"];
    NSDate * thisYearBirthdaydate = [inputFormatter dateFromString:string];
    thisYearBirthdaydate = [thisYearBirthdaydate dateByAddingTimeInterval:60*60*9];
    return [thisYearBirthdaydate timeIntervalSince1970];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
