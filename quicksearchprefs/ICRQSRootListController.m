#include "ICRQSRootListController.h"
#import <Preferences/PSSpecifier.h>

@implementation ICRQSRootListController
-(id)readPreferenceValue:(PSSpecifier *)specifier {
	NSString *path = [NSString stringWithFormat:ROOT_PATH_NS(@"/var/mobile/Library/Preferences/%@.plist"), specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	NSString *path = [NSString stringWithFormat:ROOT_PATH_NS(@"/var/mobile/Library/Preferences/%@.plist"), specifier.properties[@"defaults"]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToFile:path atomically:YES];
	CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
	if (notificationName) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
}

-(NSArray *)specifiers {
	if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	return _specifiers;
}

-(void)paypal {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://paypal.me/iCrazeiOS/2.50"] options:@{} completionHandler:nil];
}

-(void)twitter {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/iCrazeiOS/"] options:@{} completionHandler:nil];
}

-(void)email {
	[UIPasteboard generalPasteboard].string = @"icrazeios@protonmail.com";
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"QuickSearch" message:@"Email copied to clipboard!" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil];
	[alert addAction:dismiss];
	[self presentViewController:alert animated:YES completion:nil];
}

-(void)github {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/iCrazeiOS/QuickSearch/"] options:@{} completionHandler:nil];
}
@end
