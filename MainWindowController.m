//
//  MainWindowController.m
//  Defaulter
//
//  Created by Owen Yamauchi on 4/18/08.
//  Copyright 2008 Owen Yamauchi. All rights reserved.
//

#import "MainWindowController.h"
#import <ApplicationServices/ApplicationServices.h>

static const int SELECTED_TAG = 0xf00;
static const int UNSELECTED_TAG = 0x0;

static int bundleComparator(id o1, id o2, void *context)
{
  NSBundle *b1 = o1, *b2 = o2;
  NSString *one = [b1 displayName];  /* This method is category-ed onto NSBundle */
  NSString *two = [b2 displayName];
  
  return [one caseInsensitiveCompare:two];
}

@implementation MainWindowController

- (void)awakeFromNib
{
  appLists = [[NSMutableDictionary alloc] init];
  
  [self setupPopupMenu:[self menuForScheme:@"http"] withScheme:@"http"];
  [self setupPopupMenu:[self menuForScheme:@"mailto"] withScheme:@"mailto"];
  [self setupPopupMenu:[self menuForScheme:@"ftp"] withScheme:@"ftp"];
  [self setupPopupMenu:[self menuForScheme:@"feed"] withScheme:@"feed"];
}

- (void)dealloc
{
  [appLists release];
  [super dealloc];
}

- (NSPopUpButton *)menuForScheme:(NSString *)scheme
{
  if ([scheme isEqualToString:@"http"]) {
    return browserMenu;
  } else if ([scheme isEqualToString:@"mailto"]) {
    return emailMenu;
  } else if ([scheme isEqualToString:@"ftp"]) {
    return ftpMenu;
  } else if ([scheme isEqualToString:@"feed"]) {
    return rssMenu;
  }
  return nil;
}
            
- (void)setupPopupMenu:(NSPopUpButton *)menuButton withScheme:(NSString *)scheme
{
  NSWorkspace *ws = [NSWorkspace sharedWorkspace];
  NSArray *result =
    [[self bundlesForURLScheme:scheme] sortedArrayUsingFunction:bundleComparator
                                                        context:NULL];
  NSEnumerator *resultEnumerator = [result objectEnumerator];
  NSBundle *defaultBundle = [self defaultBundleForURLScheme:scheme];
  NSBundle *curr;
  
  NSMenu *m = [NSMenu new];
  [m setTitle:@"Select"];
  
  while ((curr = [resultEnumerator nextObject]) != nil) {
    NSMenuItem *item = [NSMenuItem new];
    
    /* Chose not to use CFBundleName key here, since some apps (NNW Lite - wtf) don't
     * have it in Info.plist.
     */
    [item setTitle:[curr displayName]];
    [item setTag:([curr isEqual:defaultBundle] ? SELECTED_TAG : UNSELECTED_TAG)];
    
    NSImage *icon = [ws iconForFile:[curr bundlePath]];
    [icon setSize:NSMakeSize(16, 16)];
    [item setImage:icon];
    
    [m addItem:item];
    [item release];
  }
  
  [menuButton setMenu:m];
  [menuButton selectItemWithTag:SELECTED_TAG];
  
  [appLists setObject:result forKey:scheme];
  
  [m release];
}

/*
 * Given a URL scheme (such as @"http"), returns an array of NSBundles, each one
 * corresponding to an application that can handle that scheme.
 */
- (NSArray *)bundlesForURLScheme:(NSString *)scheme
{
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@:", scheme]];
  NSArray *handlers = (NSArray *)LSCopyApplicationURLsForURL((CFURLRef)url,
                                                             kLSRolesAll);
  
  if (!handlers) {
    return [NSArray array];
  }
  
  NSEnumerator *handlerEnum = [handlers objectEnumerator];
  NSMutableSet *existing = [NSMutableSet set];
  NSURL *curr;
  
  while ((curr = (NSURL *)[handlerEnum nextObject]) != nil) {
    NSBundle *bundle = [NSBundle bundleWithPath:[curr path]];
    if (bundle && ![existing containsObject:bundle]) {
      [existing addObject:bundle];
    }
  }
  
  CFRelease((CFArrayRef)handlers);
  return [existing allObjects];
}

/*
 * Given a URL scheme (such as @"http"), returns an NSBundle representing the app that
 * is the default handler for that URL scheme.
 */
- (NSBundle *)defaultBundleForURLScheme:(NSString *)scheme
{
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@:", scheme]];
  CFURLRef result;
  OSStatus err;
  
  err = LSGetApplicationForURL((CFURLRef)url, /* url to get application for */
                               kLSRolesAll,   /* roles to get application for */
                               NULL,          /* FSRef; we don't want it */
                               &result);      /* pointer to answer, MUST RELEASE */
  
  if (err == noErr) {
    NSBundle *bundle = [NSBundle bundleWithPath:[(NSURL *)result path]];
    CFRelease(result);
    return bundle;
  } else {
    CFRelease(result);
    return nil;
  }
}

- (IBAction)setDefaults:(id)sender
{
  NSEnumerator *appEnumerator = [appLists keyEnumerator];
  NSString *scheme;
  
  while ((scheme = [appEnumerator nextObject]) != nil) {
    NSPopUpButton *theButton = [self menuForScheme:scheme];
    unsigned selectionIndex = [theButton indexOfSelectedItem];
    NSArray *bundles = [appLists objectForKey:scheme];
    NSBundle *selection = [bundles objectAtIndex:selectionIndex];
    OSStatus err;
    
    err = LSSetDefaultHandlerForURLScheme((CFStringRef)scheme,
                                          (CFStringRef)[selection bundleIdentifier]);
    if (err != noErr) {
      NSRunAlertPanel(@"Could not set default",
                      @"There was an error setting the default handler.",
                      nil, nil, nil);
      /* Since we couldn't change the default, we want to keep the menu's selection in
       * sync with the actual default.
       */
      [self setupPopupMenu:theButton withScheme:scheme];
    }
  }
}

- (void)windowWillClose:(NSNotification *)ignored
{
  [NSApp terminate:self];
}

@end


@implementation NSBundle (DisplayName)

- (NSString *)displayName
{
  return [[[self bundlePath] lastPathComponent] stringByDeletingPathExtension];
}

@end
