#import <Preferences/Preferences.h>
#import <Twitter/TWTweetComposeViewController.h>

static BOOL isTinted() {
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/org.thebigboss.snooscreens.list"]) {
        return YES;
    }
    return NO;
}

@interface SnooScreensListController: PSListController {
}
@end

@implementation SnooScreensListController
NSString *tweakName = @"SnooScreens";
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}
	return _specifiers;
}

-(void)loadView {
    [super loadView];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(tweetSweetNothings:)];
}

-(void)tweetSweetNothings:(id)sender {
    TWTweetComposeViewController *tweetController = [[TWTweetComposeViewController alloc] init];
    [tweetController setInitialText:@"I downloaded #SnooScreens by @JamesIscNeutron and I love it!"];
    [self.navigationController presentViewController:tweetController animated:YES completion:nil];
    [tweetController release];
}
@end

@interface SSCustomCell : PSTableCell{
    UILabel *tweakName;
    UILabel *devName;
    UILabel *piracyNotice;
}
@end

@implementation SSCustomCell
NSString *nameOfTweak = @"SnooScreens";

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];
    if (self) {
        CFPreferencesAppSynchronize(CFSTR("com.milodarling.snooscreens"));
        BOOL comicsans = !CFPreferencesCopyAppValue(CFSTR("comicsans"), CFSTR("com.milodarling.snooscreens")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("comicsans"), CFSTR("com.milodarling.snooscreens")) boolValue];
        int width = [[UIScreen mainScreen] bounds].size.width;
        CGRect frame1 = CGRectMake(0, -10, width, 60);
        CGRect frame2 = CGRectMake(0, 30, width, 60);
        //CGRect frame3 = CGRectMake(0, 50, width, 60);
        
        tweakName = [[UILabel alloc] initWithFrame:frame1];
        [tweakName setNumberOfLines:1];
        if (isTinted() || comicsans) {
            tweakName.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:40];
        } else {
            tweakName.font = [UIFont fontWithName:@"HelveticaNeue-Ultralight" size:40];
        }
        [tweakName setText:[NSString stringWithFormat:@"%@", nameOfTweak]];
        [tweakName setBackgroundColor:[UIColor clearColor]];
        tweakName.textColor = [UIColor /*colorWithRed:99.0f/255.0f green:99.0f/255.0f blue:99.0f/255.0f alpha:1.0*/blackColor];
        tweakName.textAlignment = NSTextAlignmentCenter;
        
        devName = [[UILabel alloc] initWithFrame:frame2];
        [devName setNumberOfLines:1];
        if (isTinted() || comicsans) {
            devName.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:20];
        } else {
            devName.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
        }
        [devName setText:@"by Milo Darling"];
        [devName setBackgroundColor:[UIColor clearColor]];
        devName.textColor = [UIColor grayColor];
        devName.textAlignment = NSTextAlignmentCenter;
        
        if (width<=375) {
            piracyNotice = [[UILabel alloc] initWithFrame:CGRectMake(5, 50, width-10, 80)];
            [piracyNotice setNumberOfLines:2];
            [piracyNotice setText:[SSCustomCell label]];
        } else {
            piracyNotice = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, width-10, 60)];
            [piracyNotice setNumberOfLines:1];
            [piracyNotice setText:[SSCustomCell label]];
        }
        if (isTinted() || comicsans) {
            piracyNotice.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:15];
        } else {
            piracyNotice.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
        }
        [piracyNotice setBackgroundColor:[UIColor clearColor]];
        piracyNotice.textColor = [UIColor grayColor];
        piracyNotice.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview:tweakName];
        [self addSubview:devName];
        [self addSubview:piracyNotice];
        
    }
    return self;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
    return 110.f;
}

+(NSString *) label {
    if (isTinted()) {
        return [NSString stringWithFormat:@"If you enjoy %@, please consider purchasing it in the BigBoss repository.", nameOfTweak];
    } else {
        return @"Thank you for your purchase. I hope you enjoy the tweak!";
    }
}

@end

@interface SSCreditsListController: PSListController {
}
@end
@implementation SSCreditsListController

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"credits" target:self] retain];
    }
    return _specifiers;
}

-(void)openMiloTwitter {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetbot:///user_profile/JamesIscNeutron"]];
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitterrific:///profile?screen_name=JamesIscNeutron"]];
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetings:///user?screen_name=JamesIscNeutron"]];
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=JamesIscNeutron"]];
    else
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/JamesIscNeutron"]];
}

-(void)openGitHub {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/milodarling/RedditScreens"]];
}

-(void) openMiloReddit {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.reddit.com/user/James-Isaac-Neutron"]];
}

@end

@interface Sub1ListController: PSListController {
}
@end
@implementation Sub1ListController
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"sub1" target:self] retain];
    }
    return _specifiers;
}
@end

@interface Sub2ListController: PSListController {
}
@end
@implementation Sub2ListController
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"sub2" target:self] retain];
    }
    return _specifiers;
}
@end

@interface Sub3ListController: PSListController {
}
@end
@implementation Sub3ListController
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"sub3" target:self] retain];
    }
    return _specifiers;
}
@end

@interface Sub4ListController: PSListController {
}
@end
@implementation Sub4ListController
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"sub4" target:self] retain];
    }
    return _specifiers;
}
@end

@interface Sub5ListController: PSListController {
}
@end
@implementation Sub5ListController
- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"sub5" target:self] retain];
    }
    return _specifiers;
}
@end

@interface SnooScreensDevCell : PSTableCell {
    UIImageView *_background;
    UILabel *devName;
    UILabel *devRealName;
    UILabel *jobSubtitle;
}
@end
@implementation SnooScreensDevCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])){
        UIImage *bkIm = [[UIImage alloc] initWithContentsOfFile:@"/Library/PreferenceBundles/SnooScreens.bundle/milo@2x.png"];
        _background = [[UIImageView alloc] initWithImage:bkIm];
        _background.frame = CGRectMake(10, 15, 70, 70);
        [self addSubview:_background];
        
        CGRect frame = [self frame];
        
        devName = [[UILabel alloc] initWithFrame:CGRectMake(frame.origin.x + 95, frame.origin.y + 10, frame.size.width, frame.size.height)];
        [devName setText:@"Milo Darling"];
        [devName setBackgroundColor:[UIColor clearColor]];
        [devName setTextColor:[UIColor blackColor]];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            [devName setFont:[UIFont fontWithName:@"Helvetica Light" size:30]];
        else
            [devName setFont:[UIFont fontWithName:@"Helvetica Light" size:23]];
        
        [self addSubview:devName];
        
        devRealName = [[UILabel alloc] initWithFrame:CGRectMake(frame.origin.x + 95, frame.origin.y + 30, frame.size.width, frame.size.height)];
        [devRealName setText:@"The Creator"];
        [devRealName setTextColor:[UIColor grayColor]];
        [devRealName setBackgroundColor:[UIColor clearColor]];
        [devRealName setFont:[UIFont fontWithName:@"Helvetica Light" size:15]];
        
        [self addSubview:devRealName];
        
        jobSubtitle = [[UILabel alloc] initWithFrame:CGRectMake(frame.origin.x + 95, frame.origin.y + 50, frame.size.width, frame.size.height)];
        [jobSubtitle setText:@"@JamesIscNeutron"];
        [jobSubtitle setTextColor:[UIColor grayColor]];
        [jobSubtitle setBackgroundColor:[UIColor clearColor]];
        [jobSubtitle setFont:[UIFont fontWithName:@"Helvetica Light" size:15]];
        
        [self addSubview:jobSubtitle];
    }
    return self;
}

@end

@interface SSTintedCell : PSTableCell
@end
@implementation SSTintedCell

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.textColor = [UIColor grayColor];
}

@end

// vim:ft=objc
