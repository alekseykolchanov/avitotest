//
//  AKUserCell.h
//  AvitoTestTask
//
//  Created by Пользователь on 21.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import <UIKit/UIKit.h>
@class User;

@interface AKUserCell : UITableViewCell

@property (nonatomic,strong) User *user;


@property (nonatomic,weak) UIImageView *userAvatarIV;
@property (nonatomic,weak) UILabel *userLoginLbl;

@end
