#import <PhotoLibrary/PLStaticWallpaperImageViewController.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoardFoundation/SBFWallpaperParallaxSettings.h>
#import <UIKit/UIKit.h>
#import "/usr/include/objc/runtime.h"
#import <libactivator/libactivator.h>

@interface RedditScreens : NSObject<LAListener>{
    
}
@end

static NSString *tweakName = @"Reddit Screens";
static NSDictionary *prefs;
static NSString *id1 = @"com.milodarling.redditscreens.sub1";
static NSString *id2 = @"com.milodarling.redditscreens.sub2";
static NSString *id3 = @"com.milodarling.redditscreens.sub3";
static NSString *id4 = @"com.milodarling.redditscreens.sub4";
static NSString *id5 = @"com.milodarling.redditscreens.sub5";
NSString *sub1;
NSString *sub2;
NSString *sub3;
NSString *sub4;
NSString *sub5;
PLWallpaperMode wallpaperMode;
NSString *imgurLink;
BOOL isNSFW;


static inline unsigned char FPWListenerName(NSString *listenerName) {
    unsigned char en;
    if ([listenerName isEqualToString:id1]) {
        en = 0;
    } else if ([listenerName isEqualToString:id2]) {
        en = 1;
    } else if ([listenerName isEqualToString:id3]) {
        en = 2;
    } else if ([listenerName isEqualToString:id4]) {
        en = 3;
    } else if ([listenerName isEqualToString:id5]) {
        en = 4;
    }
    return en;
}

@implementation RedditScreens

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //COLLECT PREFERENCES ETC
        unsigned char en = FPWListenerName(listenerName);
        NSString *subreddits[5] = { @"sub1-", @"sub2-", @"sub3-", @"sub4-", @"sub5-" };
        NSString *mode = subreddits[en];
        NSString *subreddit = [prefs objectForKey:[NSString stringWithFormat:@"%@subreddit", mode]] ?: @"No subreddit chosen";
        BOOL allowBoobies = [prefs objectForKey:[NSString stringWithFormat:@"%@allowBoobies", mode]] ? [[prefs objectForKey:[NSString stringWithFormat:@"%@allowBoobies", mode]] boolValue] : NO;
        wallpaperMode = [[prefs objectForKey:[NSString stringWithFormat:@"%@wallpaperMode", mode]] intValue] ?: 0;
    
        //PARSE URL
        subreddit = [subreddit stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSLog(@"[%@] Subreddit: %@", tweakName, subreddit);
        NSURL *blogURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.reddit.com%@.json", subreddit]];
        NSError *jsonDataError = nil;
        NSData *jsonData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:blogURL] returningResponse:nil error:&jsonDataError];
        if (jsonDataError) {
            NSLog(@"[%@] Error downloading json data: %@", tweakName, jsonDataError);
            UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@", tweakName]
                                                             message:@"We couldn't get the image :(. Perhaps you've typed in a subreddit incorrectly, or you're not connected to the internet?"
                                                            delegate:self
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil];
            [alert1 performSelector:@selector(show)
                           onThread:[NSThread mainThread]
                         withObject:nil
                      waitUntilDone:NO];
            [alert1 release];
            return;
        }
        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
        if (jsonError) {
            NSLog(@"[%@] JSON Error: %@", tweakName, jsonError);
            return;
        }
        if ([[prefs objectForKey:[NSString stringWithFormat:@"%@random", mode]] boolValue]) {
            NSMutableArray *badNumbers = [[NSMutableArray alloc]init];
            int count = 0;
            do {
                int i = arc4random_uniform(25);
                NSNumber *iInIDForm = [NSNumber numberWithInt:i];
                if ([badNumbers containsObject:iInIDForm]) {
                    continue;
                }
                imgurLink = json[@"data"][@"children"][i][@"data"][@"url"];
                isNSFW = [json[@"data"][@"children"][i][@"data"][@"over_18"] boolValue];
                [badNumbers addObject:iInIDForm];
                count++;
            } while (!(([imgurLink rangeOfString:@"imgur.com"].location != NSNotFound) && ([imgurLink rangeOfString:@"/a/"].location == NSNotFound) && (!isNSFW || allowBoobies)) || count>=25);
            [badNumbers release];
        } else {
            for (int i=0; i<25; i++) {
                imgurLink = json[@"data"][@"children"][i][@"data"][@"url"];
                isNSFW = [json[@"data"][@"children"][i][@"data"][@"over_18"] boolValue];
                if (([imgurLink rangeOfString:@"imgur.com"].location != NSNotFound) && ([imgurLink rangeOfString:@"/a/"].location == NSNotFound) && (!isNSFW || allowBoobies)) {
                    break;
                }
            }
        }
    
        if (!(([imgurLink rangeOfString:@"imgur.com"].location != NSNotFound) && ([imgurLink rangeOfString:@"/a/"].location == NSNotFound) && (!isNSFW || allowBoobies))) {
            UIAlertView *alert2 = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@", tweakName]
                                                             message:[NSString stringWithFormat:@"I didn't find any images that meet your criteria on the front page of %@.", subreddit]
                                                            delegate:self
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil];
            [alert2 performSelector:@selector(show)
                           onThread:[NSThread mainThread]
                         withObject:nil
                      waitUntilDone:NO];
            [alert2 release];
            return;
        }
    
        //Convert imgur.com links to i.imgur.com
        NSString *finalLink = @"";
        if ([imgurLink rangeOfString:@"i.imgur.com"].location == NSNotFound) {
            for (int i=0; i<[imgurLink length]; i++) {
                finalLink = [NSString stringWithFormat:@"%@%c", finalLink, [imgurLink characterAtIndex:i]];
                if ([imgurLink characterAtIndex:i] == '/' && [imgurLink characterAtIndex:i-1] == '/') {
                    finalLink = [NSString stringWithFormat:@"%@i.", finalLink];
                }
            }
            finalLink = [NSString stringWithFormat:@"%@.jpg", finalLink];
        } else {
            finalLink = imgurLink;
        }
        NSLog(@"[%@] Link: %@", tweakName, finalLink);
    
        NSURL *url = [NSURL URLWithString:finalLink];
        NSLog(@"[%@] URL: %@", tweakName, url);
        
    
        //DOWNLOAD IMAGE
        NSError *imageError = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:nil error:&imageError];
        if (imageError) {
            NSLog(@"[%@] Error downloading image: %@", tweakName, imageError);
            UIAlertView *alert3 = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@", tweakName]
                                                             message:[NSString stringWithFormat:@"There was an error downloading the image %@ from imgur. Perhaps imgur is blocked on your Internet connection? %@.", url, subreddit]
                                                            delegate:self
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil];
            [alert3 performSelector:@selector(show)
                           onThread:[NSThread mainThread]
                         withObject:nil
                      waitUntilDone:NO];
            [alert3 release];
        }
        UIImage *rawImage = [UIImage imageWithData:data];
    
        //CROP IMAGE
        CGSize screenSize = [SBFWallpaperParallaxSettings minimumWallpaperSizeForCurrentDevice];
        float ratio = screenSize.height/screenSize.width;
    
        CGRect rect;
        if ((rawImage.size.height/rawImage.size.width)>ratio) {
            rect = CGRectMake(0.0f,
                              (rawImage.size.height - rawImage.size.width*ratio) * 0.5f,
                              rawImage.size.width,
                              rawImage.size.width*ratio);
        } else {
            rect = CGRectMake((rawImage.size.width - rawImage.size.height/ratio) * 0.5f,
                              0.0f,
                              (rawImage.size.height/ratio),
                              rawImage.size.height);
        }
    
        CGImageRef imageRef = CGImageCreateWithImageInRect([rawImage CGImage], rect);
        UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
        CGImageRelease(imageRef);
    
        //SET WALLPAPER
        //isRunning = YES;
        
        PLStaticWallpaperImageViewController *wallpaperViewController = [[[PLStaticWallpaperImageViewController alloc] initWithUIImage:image] autorelease];
        wallpaperViewController.saveWallpaperData = YES;
        
        uintptr_t address = (uintptr_t)&wallpaperMode;
        object_setInstanceVariable(wallpaperViewController, "_wallpaperMode", *(PLWallpaperMode **)address);
        
        [wallpaperViewController _savePhoto];
        
        if ([[prefs objectForKey:[NSString stringWithFormat:@"%@savePhoto", mode]] boolValue])
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        NSLog(@"[%@] Releasing image :)", tweakName);
        [image release];
        
        //isRunning = NO;
        
        //completion(nil);
    });
    
}

+(void)load {
    NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
    [[LAActivator sharedInstance] registerListener:[self new] forName:id1];
    [[LAActivator sharedInstance] registerListener:[self new] forName:id2];
    [[LAActivator sharedInstance] registerListener:[self new] forName:id3];
    [[LAActivator sharedInstance] registerListener:[self new] forName:id4];
    [[LAActivator sharedInstance] registerListener:[self new] forName:id5];
    [p release];
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
    return @"Reddit Screens";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
    int en = FPWListenerName(listenerName);
    NSString *title[5] = { @"Subreddit 1", @"Subreddit 2", @"Subreddit 3", @"Subreddit 4", @"Subreddit 5" };
    return title[en];
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
    int en = FPWListenerName(listenerName);
    NSString *title[5] = { sub1, sub2, sub3, sub4, sub5 };
    return title[en];
}

- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:@"springboard", @"lockscreen", @"application", nil];
}

- (NSArray *)activator:(LAActivator *)activator requiresExclusiveAssignmentGroupsForListenerName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:nil];
}

- (NSData *)activator:(LAActivator *)activator requiresSmallIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale {
    if (*scale == 1.0) {
        return [NSData dataWithContentsOfFile:@"/Library/PreferenceBundles/RedditScreens.bundle/RedditScreens.png"];
    } else {
        return [NSData dataWithContentsOfFile:@"/Library/PreferenceBundles/RedditScreens.bundle/RedditScreens@2x.png"];
    }
}

@end
 
 static void loadPreferences() {
     [prefs release];
     CFStringRef appID = CFSTR("com.milodarling.redditscreens");
     CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
     if (!keyList) {
         NSLog(@"[%@] There's been an error getting the key list!", tweakName);
         return;
     }
     prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
     if (!prefs) {
         NSLog(@"[%@] There's been an error getting the preferences dictionary!", tweakName);
     }
     sub1 = [prefs objectForKey:@"sub1-subreddit"] ?: @"No subreddit chosen";
     sub2 = [prefs objectForKey:@"sub2-subreddit"] ?: @"No subreddit chosen";
     sub3 = [prefs objectForKey:@"sub3-subreddit"] ?: @"No subreddit chosen";
     sub4 = [prefs objectForKey:@"sub4-subreddit"] ?: @"No subreddit chosen";
     sub5 = [prefs objectForKey:@"sub5-subreddit"] ?: @"No subreddit chosen";
 }

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    if (!CFPreferencesCopyAppValue(CFSTR("hasRun"), CFSTR("com.milodarling.redditscreens"))) {
        UIAlertView *welcomeAlert = [[UIAlertView alloc] initWithTitle:@"Reddit Screens" message: @"Welcome to Reddit Screens! Please visit the settings to set your subreddits, activation methods, and more." delegate:nil cancelButtonTitle:@"Cool beans!" otherButtonTitles:nil];
        [welcomeAlert show];
        [welcomeAlert release];
        CFPreferencesSetAppValue ( CFSTR("hasRun"), kCFBooleanTrue, CFSTR("com.milodarling.redditscreens") );
    }
    %orig;
}

%end

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                NULL,
                                (CFNotificationCallback)loadPreferences,
                                CFSTR("com.milodarling.redditscreens/prefsChanged"),
                                NULL,
                                CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPreferences();
}