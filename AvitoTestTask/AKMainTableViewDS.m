//
//  AKMainTableViewDS.m
//  AvitoTestTask
//
//  Created by Пользователь on 21.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import "AKMainTableViewDS.h"
#import "AKUserCell.h"
#import "AKCoreDataController.h"
#import "User+AKUser.h"
#import "AKTableViewFooter.h"
#import "AKDatabase.h"

NSString *const USER_CELL_IDENTIFIER = @"AKUserCell";
NSString *const CACHE_NAME = @"CACHE_NAME";

@interface AKMainTableViewDS ()<NSFetchedResultsControllerDelegate,AKTableViewFooterDelegate>
{
    __weak AKTableViewFooter *tableViewFooter;
    
}

@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic,strong) NSNumber *isLastUserReceived;
@property (nonatomic,strong) NSNumber *isUpdatingError;
@property (nonatomic,strong) NSNumber *isUpdating;


@end


@implementation AKMainTableViewDS

-(id)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter]removeObserver:self name:NSManagedObjectContextDidSaveNotification  object:[[AKCoreDataController share]masterManagedObjectContext]];
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(masterManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:[[AKCoreDataController share]masterManagedObjectContext]];
    }
    
    return self;
}

-(void)masterManagedObjectContextDidSave:(NSNotification*)notification
{
    [[self managedObjectContext]mergeChangesFromContextDidSaveNotification:notification];
    
}

-(void)setMainTV:(UITableView *)mainTV
{
    _mainTV = mainTV;
    if (_mainTV)
    {
        [_mainTV registerClass:[AKUserCell class] forCellReuseIdentifier:USER_CELL_IDENTIFIER];
        AKTableViewFooter *footer = [self createFooterView];
        [_mainTV setTableFooterView:footer];
        [footer startAnimatingActivityIndicator];
        tableViewFooter = footer;
        
        [_mainTV setDataSource:self];
        [_mainTV setDelegate:self];
        
    }
}

-(NSManagedObjectContext*)managedObjectContext
{
    if (!_managedObjectContext)
        _managedObjectContext = [[AKCoreDataController share]newManagedObjectContext];
    
    return _managedObjectContext;
}

-(AKTableViewFooter *)createFooterView
{
    AKTableViewFooter *footer = [[AKTableViewFooter alloc]initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 60.0f)];
    
    [footer setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [footer setDelegate:self];
    
    return footer;
}

-(void)updateNextUsersAfter:(User*)lastUser
{
    if ([self isUpdating])
        return;
    
    [self setIsUpdating:@YES];
    [self setIsUpdatingError:nil];
    [self setIsLastUserReceived:nil];
    
    [self updateFooterView];
    
    __weak AKMainTableViewDS *weakSelf = self;
    [[AKDatabase share]updateUsersSinceUser:lastUser withCompletion:^(BOOL isLastUsers, NSArray *users, NSError *error) {
        
        AKMainTableViewDS *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        
        [strongSelf setIsUpdating:nil];
        
        if (isLastUsers)
            [strongSelf setIsLastUserReceived:@YES];
        
        if (error)
            [strongSelf setIsUpdatingError:@YES];
        
        [strongSelf updateFooterView];
    }];
}

-(void)updateFooterView
{
    if ([self isUpdating]&& [[self isUpdating]boolValue]){
        [tableViewFooter startAnimatingActivityIndicator];
    }else if ([self isUpdatingError] && [[self isUpdatingError]boolValue]){
        [tableViewFooter stopAnimatingActivityIndicator];
        [[tableViewFooter mainLabel]setText:@"Не удалось загрузить"];
        
        [[tableViewFooter subLabel]setTextColor:[[self mainTV]tintColor]];
        [[tableViewFooter subLabel]setText:@"Нажмите, чтобы повторить"];
    }else if ([self isLastUserReceived] && [[self isLastUserReceived]boolValue]){
        [tableViewFooter stopAnimatingActivityIndicator];
        [[tableViewFooter backgroundBtn]setEnabled:NO];
        [[tableViewFooter mainLabel]setText:[NSString stringWithFormat:@"Пользователей: %ld",(unsigned long)[[self.fetchedResultsController fetchedObjects] count]]];
        
        [[tableViewFooter subLabel]setHidden:YES];
    }
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 122;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 0.0f;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0f;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return nil;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSUInteger resNumber = [[self.fetchedResultsController sections][section] numberOfObjects];
    
    if (resNumber ==0 && ![self isUpdatingError])
    {
        [self updateNextUsersAfter:nil];
    }
    
    return resNumber;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    AKUserCell *cell = [tableView dequeueReusableCellWithIdentifier:USER_CELL_IDENTIFIER forIndexPath:indexPath];
    
    if (!cell)
    {
        cell = [[AKUserCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:USER_CELL_IDENTIFIER];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    if (indexPath.item == ([[self.fetchedResultsController fetchedObjects]count]-1))
        [self updateNextUsersAfter:[self.fetchedResultsController objectAtIndexPath:indexPath]];
    
    return cell;
}

- (void)configureCell:(AKUserCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    User *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [cell setUser:user];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    [NSFetchedResultsController deleteCacheWithName:CACHE_NAME];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:[self currentFetchRequest] managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:CACHE_NAME];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    
    if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        
    }
    
    return _fetchedResultsController;
}

-(NSFetchRequest*)currentFetchRequest
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:[self managedObjectContext]];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *predicate;
    
    [fetchRequest setPredicate:predicate];
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"u_id" ascending:YES];

    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    return fetchRequest;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.mainTV beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.mainTV insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.mainTV deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.mainTV;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(AKUserCell*)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.mainTV endUpdates];
}


#pragma mark - AKTableViewFooterDelegate
-(void)didTapBackgroundBtnOnTableViewFooter:(AKTableViewFooter *)footer
{
    if (footer != tableViewFooter)
        return;
    
    if ([self isUpdatingError] && [[self isUpdatingError]boolValue])
    {
        User *lastUser;
        
        if ([[self.fetchedResultsController fetchedObjects] count]>0)
            lastUser = [[self.fetchedResultsController fetchedObjects] lastObject];
        
        [self updateNextUsersAfter:lastUser];
    }
}

@end
