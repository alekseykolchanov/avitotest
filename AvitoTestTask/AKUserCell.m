//
//  AKUserCell.m
//  AvitoTestTask
//
//  Created by Пользователь on 21.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import "AKUserCell.h"
#import "User+AKUser.h"
#import "AKDatabase.h"

@interface AKUserCell ()
{
    
}

@property (nonatomic,weak) UIImageView *userAvatarIV;
@property (nonatomic,weak) UILabel *userLoginLbl;

@end

@implementation AKUserCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]){
        [self setSelectionStyle:UITableViewCellSelectionStyleGray];
        [self buildView];
    }
    
    return self;
}

-(void)buildView
{
    UILabel *mLbl = [[UILabel alloc]initWithFrame:CGRectZero];
    [mLbl setTextColor:[UIColor blackColor]];
    [mLbl setFont:[UIFont fontWithName:@"HelveticaNeue" size:16.0f]];
    [mLbl setTextAlignment:NSTextAlignmentRight];
    [self.contentView addSubview:mLbl];
    [mLbl setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setUserLoginLbl:mLbl];
    
    UIImageView *mIV = [[UIImageView alloc]initWithFrame:CGRectZero];
    [mIV setBackgroundColor:[UIColor colorWithWhite:0.95f alpha:1.0f]];
    mIV.layer.borderColor = [UIColor colorWithWhite:0.95f alpha:1.0f].CGColor;
    mIV.layer.borderWidth = 0.5f;
    [self.contentView addSubview:mIV];
    [mIV setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setUserAvatarIV:mIV];
    
    [[self contentView]addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(15)-[mIV(==92)]" options:0 metrics:nil views:@{@"mIV":mIV}]];
    [[self contentView]addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[mIV(==92)]-(15)-|" options:0 metrics:nil views:@{@"mIV":mIV}]];
    
    [[self contentView]addConstraint:[NSLayoutConstraint constraintWithItem:mLbl attribute:NSLayoutAttributeBaseline relatedBy:NSLayoutRelationEqual toItem:mIV attribute:NSLayoutAttributeBottom multiplier:1.0f constant:0.0f]];
    //[[self contentView]addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[mLbl]-(15)-|" options:0 metrics:nil views:@{@"mLbl":mLbl}]];
    [[self contentView]addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=15)-[mLbl]-(15)-[mIV]" options:0 metrics:nil views:@{@"mLbl":mLbl,@"mIV":mIV}]];
}

-(void)prepareForReuse
{
    [[self userAvatarIV]setImage:nil];
    [[self userLoginLbl]setText:@""];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


-(void)setUser:(User *)user
{
    _user = user;
    
    if (_user)
    {
        [[self userLoginLbl]setText:[_user login]];
        
        if ([_user image_data]){
            [[self userAvatarIV]setImage:[UIImage imageWithData:[_user image_data]]];
        }else if ([_user avatar_url]){
            __weak AKUserCell *weakSelf = self;
            [[AKDatabase share]updateImageForUser:_user withCompletion:^(UIImage *image, int userId, NSError *error) {
                
                AKUserCell *strongSelf = weakSelf;
                if (!strongSelf)
                    return;
                
                if (![strongSelf user] || ![[strongSelf user]u_id] || [[[strongSelf user]u_id]intValue]!=userId)
                    return;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[strongSelf userAvatarIV]setImage:image];
                });
                
            }];
        }
    }
    
}
@end
