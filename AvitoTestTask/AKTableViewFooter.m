//
//  AKTableViewFooter.m
//  AvitoTestTask
//
//  Created by Пользователь on 22.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import "AKTableViewFooter.h"

@interface AKTableViewFooter ()

@end

@implementation AKTableViewFooter

-(id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self buildView];
    }
    
    return self;
}

-(void)buildView
{
    [self setBackgroundColor:[UIColor whiteColor]];
    
    UILabel *mLbl = [[UILabel alloc]initWithFrame:CGRectZero];
    [mLbl setTextColor:[UIColor blackColor]];
    [mLbl setFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0f]];
    [mLbl setTextAlignment:NSTextAlignmentCenter];
    [self addSubview:mLbl];
    [mLbl setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self setMainLabel:mLbl];
    
    UILabel *subLbl = [[UILabel alloc]initWithFrame:CGRectZero];
    [subLbl setTextColor:[UIColor darkGrayColor]];
    [subLbl setFont:[UIFont fontWithName:@"HelveticaNeue" size:12.0f]];
    [subLbl setTextAlignment:NSTextAlignmentCenter];
    [subLbl setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:subLbl];
    [self setSubLabel:subLbl];
    
    UIButton *backBtn = [[UIButton alloc]initWithFrame:CGRectZero];
    [backBtn setBackgroundColor:[UIColor clearColor]];
    [backBtn setTitle:@"" forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(backgroundBtnClk:) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:backBtn];
    [self setBackgroundBtn:backBtn];
    
    UIActivityIndicatorView *actInd = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [actInd setHidesWhenStopped:YES];
    [actInd setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:actInd];
    [self setActivityIndicator:actInd];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(8)-[mLbl]" options:0 metrics:nil views:@{@"mLbl":mLbl}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(8)-[mLbl]-(8)-|" options:0 metrics:nil views:@{@"mLbl":mLbl}]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[mLbl]-(4)-[subLbl]" options:0 metrics:nil views:@{@"mLbl":mLbl,@"subLbl":subLbl}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(8)-[subLbl]-(8)-|" options:0 metrics:nil views:@{@"mLbl":mLbl,@"subLbl":subLbl}]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[bBtn]-|" options:0 metrics:nil views:@{@"bBtn":backBtn}]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[bBtn]-|" options:0 metrics:nil views:@{@"bBtn":backBtn}]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:actInd attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:actInd attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]];
    
}


-(void)backgroundBtnClk:(id)sender
{
    if ([self delegate])
        [[self delegate]didTapBackgroundBtnOnTableViewFooter:self];
}

-(void)startAnimatingActivityIndicator
{
    [[self activityIndicator]startAnimating];
    [[self mainLabel]setHidden:YES];
    [[self subLabel]setHidden:YES];
    [[self backgroundBtn]setEnabled:NO];
}


-(void)stopAnimatingActivityIndicator
{
    [[self activityIndicator]stopAnimating];
    [[self mainLabel]setHidden:NO];
    [[self subLabel]setHidden:NO];
    [[self backgroundBtn]setEnabled:YES];
}

@end
