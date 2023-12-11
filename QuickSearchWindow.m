#import "QuickSearchWindow.h"

static BOOL kDarkModeEnabled;
static NSString *kSearchEngine;

static void loadPrefs() {
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:ROOT_PATH_NS(@"/var/mobile/Library/Preferences/com.icraze.quicksearchprefs.plist")];
	kDarkModeEnabled = [prefs objectForKey:@"kDarkModeEnabled"] ? [[prefs objectForKey:@"kDarkModeEnabled"] boolValue] : YES;
	kSearchEngine = [prefs objectForKey:@"kSearchEngine"] ? [prefs objectForKey:@"kSearchEngine"] : @"Google";
}

@implementation QuickSearchWindow
-(instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		loadPrefs();
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.icraze.quicksearch-prefschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
		self.rootViewController = [[UIViewController alloc] init];
	
		[self setWindowLevel:UIWindowLevelAlert];
		[self setHidden:YES];
		[self setUserInteractionEnabled:NO];
		[self makeKeyAndVisible];
	}
	return self;
}

// Allow touches go beyond the window, even on Springboard
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	UIView *viewAtPoint = [self.rootViewController.view hitTest:point withEvent:event];
	return !viewAtPoint || (viewAtPoint == self.rootViewController.view) ? NO : YES;
}

-(void)searchText:(NSString *)text {
	// if no text is inputted, just fade/dismiss the view
	if ([text isEqualToString:@""]) {
		[self dismiss];
		return;
	}

	// dismiss the view
	[self setUserInteractionEnabled:NO];
	[self setHidden:YES];
	[searchBar removeFromSuperview];
	searchTextBox = nil;
	searchBar = nil;

	// set search engine
	NSString *searchEngineString = GOOGLE_URL;
	if ([kSearchEngine isEqualToString:@"DuckDuckGo"]) searchEngineString = DUCKDUCKGO_URL;
	else if ([kSearchEngine isEqualToString:@"Ecosia"]) searchEngineString = ECOSIA_URL;
	else if ([kSearchEngine isEqualToString:@"Bing"]) searchEngineString = BING_URL;

	// open search query
	NSString *urlString = @"";
	if ([text hasPrefix:@"www"]) { // if the text is likely to be a url, go to the url
		urlString = [NSString stringWithFormat:@"https://%@", text];
	} else if ([text hasPrefix:@"http"]) { // if the text is a url, go to the url
		urlString = [NSString stringWithFormat:@"%@", text];
	} else { // if not a url, search google for the inputted query (needs to be url encoded)
		urlString = [NSString stringWithFormat:@"%@%@", searchEngineString, [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
	}
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
}

-(void)setUp {
	[self setUpSearchBar];
	[self setUpTextBox];
	[self setUpKeyboardToolbar];

	// add subviews
	[self setUserInteractionEnabled:YES];
	[self setHidden:NO];
	[searchBar setAlpha:0];
	[searchBar addSubview:searchButton];
	[searchBar addSubview:searchTextBox];
	[self.rootViewController.view addSubview:searchBar];

	[UIView animateWithDuration:0.2f animations:^{
		[searchBar setAlpha:1];
	}];
}

-(void)setUpSearchBar {
	// setup bar
	searchBar = [[UIView alloc] initWithFrame:CGRectMake(0, 50, self.rootViewController.view.frame.size.width*0.95, 55)];
	searchBar.center = CGPointMake(self.rootViewController.view.center.x, 70);
	searchBar.backgroundColor = kDarkModeEnabled ? [UIColor colorWithRed: 0.11 green: 0.11 blue: 0.12 alpha: 1.00] : [UIColor whiteColor];
	searchBar.layer.cornerRadius = 25;
	if (@available(iOS 13.0, *)) searchBar.layer.cornerCurve = kCACornerCurveContinuous;
	else searchBar.layer.continuousCorners = YES;
	searchBar.layer.masksToBounds = YES;

	// setup bar swipe recogniser
	UISwipeGestureRecognizer *swipeRecogniser = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(searchBarWasSwipedUp)];
	swipeRecogniser.direction = UISwipeGestureRecognizerDirectionUp;
	[searchBar addGestureRecognizer:swipeRecogniser];

	// setup google button
	searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[searchButton addTarget:self action:@selector(searchButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[searchButton setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:ROOT_PATH_NS(@"/Library/Application Support/QuickSearch/%@.png"), kSearchEngine]] forState:UIControlStateNormal];
	searchButton.frame = CGRectMake(0, 50, 40, 40);
	searchButton.center = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? CGPointMake(searchBar.frame.size.width*0.95, 27.5) : CGPointMake(searchBar.frame.size.width*0.9, 27.5);
}

-(void)setUpTextBox {
	// setup text box
	searchTextBox = [[UITextField alloc] initWithFrame:CGRectMake(0, 50, self.rootViewController.view.frame.size.width*0.8, 45)];
	searchTextBox.center = CGPointMake(self.rootViewController.view.center.x*0.8, 27.5);
	searchTextBox.placeholder = @"Search";
	
	searchTextBox.textColor = kDarkModeEnabled ? [UIColor whiteColor] : [UIColor blackColor];
	searchTextBox._placeholderLabel.textColor = kDarkModeEnabled ? [UIColor whiteColor] : [UIColor blackColor];

	searchTextBox.returnKeyType = UIReturnKeyDone;
	searchTextBox.delegate = self;

	// add left padding to text box
	UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 20)];
	searchTextBox.leftView = paddingView;
	searchTextBox.leftViewMode = UITextFieldViewModeAlways;
}

-(void)setUpKeyboardToolbar {
	// setup keyboard toolbar
	UIToolbar *keyboardToolbar = [[UIToolbar alloc] init];
	[keyboardToolbar sizeToFit];
	// flex bar makes the dismiss button appear on the right
	UIBarButtonItem *flexBar = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	// setup dismiss keyboard button
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Dismiss" style:UIBarButtonItemStylePlain target:self action:@selector(hideKeyboard)];
	// add items to toolbar
	[keyboardToolbar setItems:@[flexBar, doneButton]];
	// add the toolbar to the keyboard
	[searchTextBox setInputAccessoryView:keyboardToolbar];
}

-(void)reset {
	if (searchBar.window) {
		[self dismiss];
		return;
	}

	[searchBar removeFromSuperview];
	searchTextBox = nil;
	searchBar = nil;
}

-(void)toggle {
	// only run code if the device is portrait
	// landscape support is not implemented
	if ([[[UIScreen mainScreen] valueForKey:@"_interfaceOrientation"] intValue] != 1) return;

	// remove any old instances
	if (searchBar) {
		[self reset];
		return;
	}

	[self setUp];
}

-(void)searchButtonPressed {
	[self searchText:searchTextBox.text];
	[self endEditing:YES];
}

// when the keyboard's "Done" button is pressed
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self searchText:searchTextBox.text];
	[textField resignFirstResponder];
	return YES;
}

// when "Dismiss" button is pressed above the keyboard
-(void)hideKeyboard {
	[searchTextBox resignFirstResponder];
}

// when the search bar is swiped up
-(void)searchBarWasSwipedUp {
	[UIView animateWithDuration:0.2f animations:^{
		CGRect newFrame;
		newFrame = searchBar.frame;
		newFrame.origin.y = -60;
		searchBar.frame = newFrame;
	} completion:^(BOOL finished) {
		[searchBar removeFromSuperview];
		searchTextBox = nil;
		searchBar = nil;
	}];
}

-(void)dismiss {
	// make sure that the window is visible
	if (searchBar.window == nil) return;

	[self setUserInteractionEnabled:NO];
	[UIView animateWithDuration:0.2f animations:^{
		[searchBar setAlpha:0];
	} completion:^(BOOL finished) {
		[self setHidden:YES];

		[searchBar removeFromSuperview];
		searchTextBox = nil;
		searchBar = nil;
	}];
}
@end
