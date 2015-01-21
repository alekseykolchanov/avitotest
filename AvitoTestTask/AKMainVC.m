//
//  AKMainVC.m
//  AvitoTestTask
//
//  Created by Пользователь on 21.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import "AKMainVC.h"
#import "AKMainTableViewDS.h"

@interface AKMainVC ()
{
    AKMainTableViewDS *mainDS;
}

@end

@implementation AKMainVC

-(id)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style])
    {
        [self.tableView setBackgroundColor:[UIColor whiteColor]];
        [self.tableView setAllowsSelection:NO];
    }
    
    return self;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = NO;
    
    mainDS = [AKMainTableViewDS new];
    [mainDS setMainTV:self.tableView];
    
}







@end
