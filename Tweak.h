#import <libactivator/libactivator.h>

@interface SpringBoard : UIApplication <UITextFieldDelegate>
@end

@interface UITextField (QuickSearch)
@property (atomic, assign, readwrite) UILabel *_placeholderLabel;
@end

@interface QuickSearchWindow : UIWindow
@end

@interface SBHomeScreenViewController : UIViewController
@end

static UIView *searchBar;
static UITextField *searchTextBox;
static BOOL kDarkModeEnabled;
static BOOL kDismissWithHomeButton;
static NSString *kSearchEngine;
QuickSearchWindow *mainWindow;

@interface ActivatorListener : NSObject <LAListener>
@end

@implementation ActivatorListener
+(void)load {
	[[LAActivator sharedInstance] registerListener:[self new] forName:@"com.icraze.quicksearch"];
}

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"QuickSearchNotification" object:self userInfo:nil]];
}
@end

static void loadPrefs() {
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.icraze.quicksearchprefs.plist"];
	kDarkModeEnabled = [prefs objectForKey:@"kDarkModeEnabled"] ? [[prefs objectForKey:@"kDarkModeEnabled"] boolValue] : YES;
	kDismissWithHomeButton = [prefs objectForKey:@"kDismissWithHomeButton"] ? [[prefs objectForKey:@"kDismissWithHomeButton"] boolValue] : NO;
	kSearchEngine = [prefs objectForKey:@"kSearchEngine"] ? [prefs objectForKey:@"kSearchEngine"] : @"Google";
}
