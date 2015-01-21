//
//  AKMainTableViewDS.h
//  AvitoTestTask
//
//  Created by Пользователь on 21.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AKMainTableViewDS : NSObject<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,weak) UITableView *mainTV;

@end
