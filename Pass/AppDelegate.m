//
//  AppDelegate.m
//  Pass
//
//  Created by James Brennan on 2013-03-27.
//  Copyright (c) 2013 PassAuth. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // --- Instantate Pass to do setup before going on
    Pass *pass = [Pass sharedInstance];
    
    // --- Clear keychain on first run in case of reinstallation
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"FirstRun"]) {
        [pass firstRunCleanUp];
        
        [[NSUserDefaults standardUserDefaults] setValue:@"1strun" forKey:@"FirstRun"];
    }
    
    // --- Ensure all database tables are created
    [pass initDb];
    
    // --- Setup ViewControllers
    
    // Determine if its an iPhone or iPad
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController_iPhone" bundle:nil];
        self.scanViewController = [[ScanViewController alloc] initWithNibName:@"ScanViewController_iPhone" bundle:nil];
        self.navigationViewController = [[NavigationViewController alloc] initWithNibName:@"NavigationViewController_iPhone" bundle:nil];
    } else {
        self.loginViewController = [[LoginViewController alloc] initWithNibName:@"LoginViewController_iPad" bundle:nil];
        self.scanViewController = [[ScanViewController alloc] initWithNibName:@"ScanViewController_iPad" bundle:nil];
        self.navigationViewController = [[NavigationViewController alloc] initWithNibName:@"NavigationViewController_iPad" bundle:nil];
    }
    
    // Setup navigation controller
    self.navController = [[UINavigationController alloc] initWithRootViewController:self.scanViewController];

    // Create ViewDeck controller to allow access to basement navigation
    self.deckController = [[IIViewDeckController alloc] initWithCenterViewController:self.navController leftViewController:self.navigationViewController];

    // Show ViewDeck controller to logged in users, else login controller
    if([[pass getAPIToken] isEqualToString:@""])
    {
        self.window.rootViewController = self.loginViewController;
    } else {
        self.window.rootViewController = self.deckController;
    }
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)loggedIn
{
    self.window.rootViewController = self.deckController;
}

@end
