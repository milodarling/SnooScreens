#import <PhotoLibrary/PLStaticWallpaperImageViewController.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoardFoundation/SBFWallpaperParallaxSettings.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "libactivator.h"
#import <AssetsLibrary/AssetsLibrary.h>
#define DEBUG
#import "DebugLog.h"

@interface SnooScreens : NSObject<LAListener>{
    int listenerCount;
    PLWallpaperMode wallpaperMode;
    NSString *imgurLink;
    BOOL isNSFW;
}
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event;
@end

SnooScreens *listener;

static NSString *const settingsPath = @"/var/mobile/Library/Preferences/com.milodarling.snooscreens.plist";
static NSString *const tweakName = @"SnooScreens";
//static NSDictionary *prefs;




static inline int FPWListenerName(NSString *listenerName) {
    int en;
    en = [[listenerName substringFromIndex:31] intValue];
    return en;
}

@implementation SnooScreens

-(id)init {
    if (self=[super init]) {
        listenerCount = 0;
        [self updateListeners];
    }
    return self;
}

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {
    // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
        //COLLECT PREFERENCES ETC
        int en = FPWListenerName(listenerName);
        NSString *mode = [NSString stringWithFormat:@"sub%d-", en];
        NSNumber *obj = [prefs objectForKey:[NSString stringWithFormat:@"%@enabled", mode]];
        BOOL enabled = obj ? [obj boolValue] : YES;
        if (!enabled) {
            [event setHandled:NO];
            return;
        }
        [event setHandled:YES];
        NSString *subreddit = [prefs objectForKey:[NSString stringWithFormat:@"%@subreddit", mode]] ?: @"No subreddit chosen";
        BOOL allowBoobies = [[prefs objectForKey:[NSString stringWithFormat:@"%@allowBoobies", mode]] boolValue];
        wallpaperMode = [[prefs objectForKey:[NSString stringWithFormat:@"%@wallpaperMode", mode]] intValue] ?: 0;

        //PARSE URL
        subreddit = [subreddit stringByReplacingOccurrencesOfString:@" " withString:@""];
        DebugLogC(@"Subreddit: %@", subreddit);
        NSURL *blogURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.reddit.com%@.json", subreddit]];
        NSError *jsonDataError = nil;
        NSData *jsonData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:blogURL] returningResponse:nil error:&jsonDataError];
        if (jsonDataError) {
            DebugLogC(@"Error downloading json data: %@", jsonDataError);
            UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"SnooScreens"
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
        int arrayLength = [json[@"data"][@"children"] count];
        if (arrayLength == 0) {
            UIAlertView *noSubredditAlert = [[UIAlertView alloc] initWithTitle:@"SnooScreens"
                                                             message:@"It appears the subreddit you've entered doesn't exist."
                                                            delegate:self
                                                   cancelButtonTitle:@"Ok"
                                                   otherButtonTitles:nil];
            [noSubredditAlert performSelector:@selector(show)
                           onThread:[NSThread mainThread]
                         withObject:nil
                      waitUntilDone:NO];
            [noSubredditAlert release];
            return;
        }
        if ([[prefs objectForKey:[NSString stringWithFormat:@"%@random", mode]] boolValue]) {
            NSMutableArray *badNumbers = [[NSMutableArray alloc] init];
            int count = 0;
            do {
                int i = arc4random_uniform(arrayLength);
                NSNumber *iInIDForm = [NSNumber numberWithInt:i];
                if ([badNumbers containsObject:iInIDForm]) {
                    continue;
                }
                imgurLink = json[@"data"][@"children"][i][@"data"][@"url"];
                isNSFW = [json[@"data"][@"children"][i][@"data"][@"over_18"] boolValue];
                [badNumbers addObject:iInIDForm];
                count++;
            } while (!(([imgurLink rangeOfString:@"imgur.com"].location != NSNotFound) && ([imgurLink rangeOfString:@"/a/"].location == NSNotFound) && (!isNSFW || allowBoobies) && ![[prefs objectForKey:@"currentRedditLink"] isEqualToString:imgurLink]) && count<arrayLength);
            [badNumbers release];
        } else {
            for (int i=0; i<arrayLength; i++) {
                imgurLink = json[@"data"][@"children"][i][@"data"][@"url"];
                isNSFW = [json[@"data"][@"children"][i][@"data"][@"over_18"] boolValue];
                if (([imgurLink rangeOfString:@"imgur.com"].location != NSNotFound) && ([imgurLink rangeOfString:@"/a/"].location == NSNotFound) && (!isNSFW || allowBoobies) && ![[prefs objectForKey:@"currentRedditLink"] isEqualToString:imgurLink]) {
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
        //save as a preference so we don't reuse the same image.
        [self setPreferenceObject:imgurLink forKey:@"currentRedditLink"];
        DebugLogC(@"Final link: %@", [prefs objectForKey:@"currentRedditLink"]);

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
        DebugLogC(@"Link: %@", finalLink);
        NSURL *url = [NSURL URLWithString:finalLink];
        DebugLogC(@"URL: %@", url);
        [self setPreferenceObject:finalLink forKey:@"currentWallpaper"];
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
        UIImage *image = [[[UIImage alloc] initWithCGImage:imageRef] autorelease];
        CGImageRelease(imageRef);

        //SET WALLPAPER
        NSLog(@"[SnooScreens] Setting wallpaper");
        PLStaticWallpaperImageViewController *wallpaperViewController = [[[PLStaticWallpaperImageViewController alloc] initWithUIImage:image] autorelease];
        wallpaperViewController.saveWallpaperData = YES;

        uintptr_t address = (uintptr_t)&wallpaperMode;
        object_setInstanceVariable(wallpaperViewController, "_wallpaperMode", *(PLWallpaperMode **)address);

        [wallpaperViewController _savePhoto];

        if ([[prefs objectForKey:[NSString stringWithFormat:@"%@savePhoto", mode]] boolValue]) {
            UIImageWriteToSavedPhotosAlbum(rawImage, nil, nil, nil);
        }
        //NSLog(@"[%@] Releasing image :)", tweakName);
        //[image release];

        //isRunning = NO;

        //completion(nil);
        [self loadPrefs];
    // });

}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
    return @"SnooScreens";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
    int en = FPWListenerName(listenerName);
    return [NSString stringWithFormat:@"Subreddit %d", en];
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
    int en = FPWListenerName(listenerName);
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
    return [prefs objectForKey:[NSString stringWithFormat:@"sub%d-subreddit", en]] ?: @"No subreddit chosen";
}

- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:@"springboard", @"lockscreen", @"application", nil];
}

- (NSArray *)activator:(LAActivator *)activator requiresExclusiveAssignmentGroupsForListenerName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:nil];
}

- (NSData *)activator:(LAActivator *)activator requiresSmallIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale {
    if (*scale == 1.0) {
        return [NSData dataWithContentsOfFile:@"/Library/PreferenceBundles/SnooScreens.bundle/SnooScreens.png"];
    } else {
        return [NSData dataWithContentsOfFile:@"/Library/PreferenceBundles/SnooScreens.bundle/SnooScreens@2x.png"];
    }
}

-(void)setPreferenceObject:(id)object forKey:(NSString *)key {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:settingsPath];
    [dict setObject:object forKey:key];
    [dict writeToFile:settingsPath atomically:YES];
}

-(void)updateListeners {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (listenerCount) {
        for (int i=1; i<=listenerCount; i++) {
            [[LAActivator sharedInstance] unregisterListenerWithName:[NSString stringWithFormat:@"com.milodarling.snooscreens.sub%d", i]];
        }
    }
    [self loadPrefs]; //gets new count value
    for (int i=1; i<=listenerCount; i++) {
        [[LAActivator sharedInstance] registerListener:self forName:[NSString stringWithFormat:@"com.milodarling.snooscreens.sub%d", i]];
    }
    [pool drain];
}

-(void)loadPrefs {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
    listenerCount = [[prefs objectForKey:@"count"] intValue];
}

@end

static void loadPreferences() {
    [listener loadPrefs];
}

static void updateListeners() {
    [listener updateListeners];
}

%ctor {
    listener = [[SnooScreens alloc] init];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)loadPreferences,
                                    CFSTR("com.milodarling.snooscreens/prefsChanged"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)updateListeners,
                                    CFSTR("com.milodarling.snooscreens/updateListeners"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}
