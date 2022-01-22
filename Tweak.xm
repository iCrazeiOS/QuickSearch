#import "Tweak.h"

@implementation QuickSearchWindow
// Allow touches go beyond the window even on Springboard
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	UIView *viewAtPoint = [self.rootViewController.view hitTest:point withEvent:event];
	return !viewAtPoint || (viewAtPoint == self.rootViewController.view) ? NO : YES;
}

-(void)searchText:(NSString *)text {
	// if no text is inputted, just fade/dismiss the view
	if ([text isEqualToString:@""]) {
		[mainWindow setUserInteractionEnabled:NO];
		[UIView animateWithDuration:0.2f animations:^{[searchBar setAlpha:0];} completion:^(BOOL finished){
			[searchBar setAlpha:0];
			[mainWindow setHidden:YES];
		}];
		return;
	}

	// dismiss the view
	[mainWindow setUserInteractionEnabled:NO];
	[mainWindow setHidden:YES];
	[searchBar removeFromSuperview];
	searchTextBox = nil;
	searchBar = nil;

	// set search engine
	NSString *searchEngineString;
	if ([kSearchEngine isEqualToString:@"Google"]) searchEngineString = @"https://www.google.com/search?q=";
	else if ([kSearchEngine isEqualToString:@"DuckDuckGo"]) searchEngineString = @"https://duckduckgo.com/?q=";
	else if ([kSearchEngine isEqualToString:@"Ecosia"]) searchEngineString = @"https://www.ecosia.org/search?q=";
	else if ([kSearchEngine isEqualToString:@"Bing"]) searchEngineString = @"https://www.bing.com/search?q=";

	// open search query
	// if the text is a url, go to the url
	if ([text hasPrefix:@"www"]) [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@", text]] options:@{} completionHandler:nil];
	else if ([text hasPrefix:@"http"]) [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", text]] options:@{} completionHandler:nil];
	// if not a url, search google for the inputted query
	else [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", searchEngineString, [text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]]] options:@{} completionHandler:nil];
}
@end


%hook SBHomeHardwareButton
- (void)singlePressUp:(id)arg1 {
	%orig;
	// make sure that the QuickSearch window is visible
	if(searchBar.window == nil || !kDismissWithHomeButton) return;

	[mainWindow setUserInteractionEnabled:NO];
	[UIView animateWithDuration:0.2f animations:^{[searchBar setAlpha:0];} completion:^(BOOL finished){
		[mainWindow setHidden:YES];
	}];
}
%end

%hook SpringBoard
-(void)applicationDidFinishLaunching:(id)arg1 {
	%orig;
	// add notification observer
	mainWindow = [[QuickSearchWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	// allocated view controller inside the window - we do not add views to windows directly
	mainWindow.rootViewController = [[UIViewController alloc] init];
	
	[mainWindow setWindowLevel:UIWindowLevelAlert];
	[mainWindow setHidden:YES];
	[mainWindow setUserInteractionEnabled:NO];
	[mainWindow makeKeyAndVisible];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupSearchBar) name:@"QuickSearchNotification" object:nil];
}

%new
-(void)setupSearchBar {
	// only run code if the device is portrait
	// too busy to mess with landscape support atm
	if ([[[UIScreen mainScreen] valueForKey:@"_interfaceOrientation"] intValue] != 1) return;
	// remove any old instances
	if (searchBar) {
		[searchBar removeFromSuperview];
		searchTextBox = nil;
		searchBar = nil;
	}

	// setup bar
	searchBar = [[UIView alloc] initWithFrame:CGRectMake(0, 50, [[[UIApplication sharedApplication] keyWindow] rootViewController].view.frame.size.width*0.95, 55)];
	searchBar.center = CGPointMake([[[UIApplication sharedApplication] keyWindow] rootViewController].view.center.x, 70);
	kDarkModeEnabled ? searchBar.backgroundColor = [UIColor colorWithRed: 0.11 green: 0.11 blue: 0.12 alpha: 1.00] : searchBar.backgroundColor = [UIColor whiteColor];
	searchBar.layer.cornerRadius = 25;
	if (@available(iOS 13.0, *)) searchBar.layer.cornerCurve = kCACornerCurveContinuous;
	else searchBar.layer.continuousCorners = YES;
	searchBar.layer.masksToBounds = YES;

	// setup bar swipe recogniser
	UISwipeGestureRecognizer *swipeRecogniser = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(searchBarWasSwipedUp)];
	swipeRecogniser.direction = UISwipeGestureRecognizerDirectionUp;
	[searchBar addGestureRecognizer:swipeRecogniser];

	// setup google button
	UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[searchButton addTarget:self action:@selector(searchButtonPressed) forControlEvents:UIControlEventTouchUpInside];
	[searchButton setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/Application Support/QuickSearch/%@.png", kSearchEngine]] forState:UIControlStateNormal];
	searchButton.frame = CGRectMake(0, 50, 40, 40);
	searchButton.center = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? CGPointMake(searchBar.frame.size.width*0.95, 27.5) : CGPointMake(searchBar.frame.size.width*0.9, 27.5);

	// setup text box
	searchTextBox = [[UITextField alloc] initWithFrame:CGRectMake(0, 50, [[[UIApplication sharedApplication] keyWindow] rootViewController].view.frame.size.width*0.8, 45)];
	searchTextBox.center = CGPointMake([[[UIApplication sharedApplication] keyWindow] rootViewController].view.center.x*0.8, 27.5);
	searchTextBox.placeholder = @"Search";
	kDarkModeEnabled ? searchTextBox.textColor = [UIColor whiteColor] : searchTextBox.textColor = [UIColor blackColor];
	kDarkModeEnabled ? searchTextBox._placeholderLabel.textColor = [UIColor whiteColor] : searchTextBox._placeholderLabel.textColor = [UIColor blackColor];
	searchTextBox.returnKeyType = UIReturnKeyDone;
	searchTextBox.delegate = self;

	// setup keyboard toolbar
	UIToolbar *keyboardToolbar = [[UIToolbar alloc] init];
	[keyboardToolbar sizeToFit];
	// flex bar makes the dismiss button appear on the right
	UIBarButtonItem *flexBar = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	// setup dismiss keyboard button
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Dismiss" style:UIBarButtonItemStylePlain target:self action:@selector(hideQuickSearchKeyboard)];
	// add items to toolbar
	[keyboardToolbar setItems:@[flexBar, doneButton]];
	// add the toolbar to the keyboard
	[searchTextBox setInputAccessoryView:keyboardToolbar];

	// add left padding to text box
	UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 20)];
	searchTextBox.leftView = paddingView;
	searchTextBox.leftViewMode = UITextFieldViewModeAlways;

	// add subviews
	[mainWindow setUserInteractionEnabled:YES];
	[mainWindow setHidden:NO];
	[searchBar setAlpha:0];
	[searchBar addSubview:searchButton];
	[searchBar addSubview:searchTextBox];
	[mainWindow.rootViewController.view addSubview:searchBar];

	[UIView animateWithDuration:0.2f animations:^{searchBar.alpha = 1;} completion:nil];
}

// when the google button is pressed
%new
-(void)searchButtonPressed {
	[mainWindow searchText:searchTextBox.text];
	[mainWindow endEditing:YES];
}

// when the keyboard's "Done" button is pressed
%new
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	[mainWindow searchText:searchTextBox.text];
	[textField resignFirstResponder];
	return YES;
}

// when "Dismiss" button is pressed above the keyboard
%new
-(void)hideQuickSearchKeyboard {
	[searchTextBox resignFirstResponder];
}

// when the search bar is swiped up
%new
-(void)searchBarWasSwipedUp {
	[UIView animateWithDuration:0.2f animations:^{
		CGRect newFrame;
		newFrame = searchBar.frame;
		newFrame.origin.y = -60;
		searchBar.frame = newFrame;
	} completion:^(BOOL finished){
		[searchBar removeFromSuperview];
		searchTextBox = nil;
		searchBar = nil;
	}];
}

%end

%hook SBHomeScreenViewController
- (void)viewDidLoad {
	%orig;

	// tap gesture recognizer
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(quicksearch_didTapToDismiss)];
	[self.view addGestureRecognizer:tapGesture];

}

%new
-(void)quicksearch_didTapToDismiss {
	[UIView animateWithDuration:0.2f animations:^{[searchBar setAlpha:0];} completion:^(BOOL finished){
		[mainWindow setHidden:YES];
		[mainWindow setUserInteractionEnabled:NO];
	}];
}
%end

%ctor {
	// load preference values
	loadPrefs();
	// add notification observer to reload preferences
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.icraze.quicksearch.prefschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	%init;
}
