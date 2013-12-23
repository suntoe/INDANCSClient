//
//  INDAppDelegate.m
//  INDANCSMac
//
//  Created by Indragie Karunaratne on 12/11/2013.
//  Copyright (c) 2013 Indragie Karunaratne. All rights reserved.
//

#import "INDAppDelegate.h"
#import <INDANCSClient/INDANCSClientFramework.h>

@interface INDAppDelegate () <INDANCSClientDelegate, NSUserNotificationCenterDelegate>
@property (nonatomic, strong) INDANCSClient *client;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) NSMutableArray *notifications;
@end

@implementation INDAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.notifications = [NSMutableArray array];
	self.client = [[INDANCSClient alloc] init];
	self.client.delegate = self;
	
	NSUserNotificationCenter *nc = NSUserNotificationCenter.defaultUserNotificationCenter;
	nc.delegate = self;
	
	[self.client scanForDevices:^(INDANCSClient *client, INDANCSDevice *device) {
		NSLog(@"Found device: %@", device.name);
		NSUserNotification *notification = [[NSUserNotification alloc] init];
		notification.title = @"Found iOS Device";
		notification.informativeText = [NSString stringWithFormat:@"Registered for notifications from %@", device.name];
		[nc deliverNotification:notification];
		
		[client registerForNotificationsFromDevice:device withBlock:^(INDANCSClient *c, INDANCSNotification *n) {
			switch (n.latestEventID) {
				case INDANCSEventIDNotificationAdded:
					[self.notifications insertObject:n atIndex:0];
					[self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0] withAnimation:NSTableViewAnimationSlideLeft];
					break;
				case INDANCSEventIDNotificationRemoved: {
					NSUInteger index = [self.notifications indexOfObject:n];
					if (index != NSNotFound) {
						[self.notifications removeObjectAtIndex:index];
						[self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationSlideLeft];
					}
					break;
				}
				case INDANCSEventIDNotificationModified: {
					NSUInteger index = [self.notifications indexOfObject:n];
					if (index != NSNotFound) {
						[self.notifications replaceObjectAtIndex:index withObject:n];
						[self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
					}
					break;
				}
				default:
					break;
			}
		}];
	}];
}

#pragma mark - INDANCSClientDelegate

- (void)ANCSClient:(INDANCSClient *)client device:(INDANCSDevice *)device disconnectedWithError:(NSError *)error
{
	NSLog(@"%@ disconnected with error: %@", device.name, error);
}

- (void)ANCSClient:(INDANCSClient *)client device:(INDANCSDevice *)device failedToConnectWithError:(NSError *)error
{
	NSLog(@"%@ failed to connect with error: %@", device.name, error);
}

- (void)ANCSClient:(INDANCSClient *)client serviceDiscoveryFailedForDevice:(INDANCSDevice *)device withError:(NSError *)error
{
	NSLog(@"Service discovery failed for %@ with error %@", device.name, error);
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return self.notifications.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return self.notifications[rowIndex];
}

#pragma mark - NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
	return YES;
}

@end
