#import "QuickSearchWindow.h"

static QuickSearchWindow *mainWindow = nil;

%hook SpringBoard
// setup the window when springboard is launched
-(void)applicationDidFinishLaunching:(id)arg1 {
	%orig;

	// create the window
	mainWindow = [[QuickSearchWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

// toggle the window when both volume buttons are pressed
-(_Bool)_handlePhysicalButtonEvent:(UIPressesEvent *)event {
	if (!mainWindow) return %orig;

	UIPress *volUp = nil;
	UIPress *volDown = nil;

	for (UIPress *press in [[event allPresses] allObjects]) {
		if (press.type == 102 && press.force == 1) { // volume up
			volUp = press;
		} else if (press.type == 103 && press.force == 1) { // volume down
			volDown = press;
		}
	}

	if (volUp && volDown) {
		[mainWindow toggle];
	}

	return %orig;
}
%end
