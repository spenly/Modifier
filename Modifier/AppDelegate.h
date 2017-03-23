//
//  AppDelegate.h
//  Modifier
//
//  Created by spenly.jia on 2017/3/24.
//  Copyright © 2017年 spenly.jia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

