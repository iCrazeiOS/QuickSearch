#import <UIKit/UIKit.h>
#import <rootless.h>

@interface CALayer (QuickSearch)
@property (atomic, assign, readwrite) BOOL continuousCorners;
@end

@interface UITextField (QuickSearch)
@property (atomic, assign, readwrite) UILabel *_placeholderLabel;
@end

@interface QuickSearchWindow : UIWindow <UITextFieldDelegate> {
	UIView *searchBar;
	UITextField *searchTextBox;
	UIButton *searchButton;
}
-(void)dismiss;
-(void)toggle;
@end

#define GOOGLE_URL @"https://www.google.com/search?q="
#define DUCKDUCKGO_URL @"https://duckduckgo.com/?q="
#define ECOSIA_URL @"https://www.ecosia.org/search?q="
#define BING_URL @"https://www.bing.com/search?q="
