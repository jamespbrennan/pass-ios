//
//  NavigationViewController.m
//  Pass
//
//  Created by James Brennan on 2013-04-03.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "NavigationViewController.h"

@interface NavigationViewController ()

@end

@implementation NavigationViewController

@synthesize displayedObjects = _displayedObjects;

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self displayedObjects] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    
    //  Find out which row we're being asked for, and get the corresponding
    //  object from our internal array of displayed objects.
    //
    NSUInteger index = [indexPath row];
    NSString *text = [[self displayedObjects] objectAtIndex:index];
    
    //  Populate the cell's text label with our object's value.
    [[cell textLabel] setText:text];
    
    //  Populate the cell's detail text label.
    NSString *detailText = [NSString stringWithFormat:@"Detail text for %@.",
                            [text lowercaseString]];
    [[cell detailTextLabel] setText:detailText];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = [indexPath row];
    if ([[[self displayedObjects] objectAtIndex:index] isEqualToString:@"Logout"])
    {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate logOut];
    }
}

//  Lazily initializes array of displayed objects.
//
- (NSMutableArray *)displayedObjects
{
    if (_displayedObjects == nil)
    {
        _displayedObjects = [[NSMutableArray alloc] initWithObjects: @"Logout", nil];
    }
    
    return _displayedObjects;
}

@end
