//
//  MCOAppDelegate.m
//  Temporary
//
//  Created by Michael Conrads on 24/04/14.
//
//

#import "MCOAppDelegate.h"

@interface MCOAppDelegate ()
@property (nonatomic, strong, readwrite) NSStatusItem *statusItem;
@property (unsafe_unretained) IBOutlet NSPanel *preferencesPanel;

@property (weak) IBOutlet NSMenu *menu;
@property (nonatomic, strong, readwrite) NSTimer *timer;

@property (nonatomic, assign, readwrite) NSTimeInterval timeIntervalToCheck;
@property (nonatomic, strong, readwrite) NSString *pathToTempDirectory;
@end


@implementation MCOAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    self.timeIntervalToCheck = 60;
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    [self.statusItem setHighlightMode:YES];
    [self.statusItem setTitle:@"tmp"];
    [self.statusItem setToolTip:@"doing stuff..."];
    [self.statusItem setEnabled:YES];
    self.statusItem.menu = self.menu;
    
    
    
    
    self.pathToTempDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@".tmp"];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeIntervalToCheck
                                                  target:self
                                                selector:@selector(checkDirectory:)
                                                userInfo:nil
                                                 repeats:YES];
    
}

- (void)checkDirectory:(id)userInfo
{
    NSError *error;
    NSArray *filesInTmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.pathToTempDirectory
                                                                                       error:&error];
    NSDate *now = [NSDate date];
    
    NSMutableArray *foldersToDelete = [NSMutableArray array];
    
    if(error == nil)
    {
        for (NSString *oneFilenameInDirectory in filesInTmpDirectory)
        {
            NSString *pathOfFileInDirectory = [self.pathToTempDirectory stringByAppendingPathComponent:oneFilenameInDirectory];
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:pathOfFileInDirectory
                                                                                            error:&error];
            
            
            NSDate *folderAge = fileAttributes[NSFileCreationDate];
            NSTimeInterval ageInSeconds = [now timeIntervalSinceDate:folderAge];
            
            
            NSTimeInterval secondsToLive = ({
                NSScanner *s = [NSScanner scannerWithString:oneFilenameInDirectory];
                [s scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet]
                                  intoString:nil];

                NSString *daysToLive;
                [s scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet]
                              intoString:&daysToLive];
                
                [daysToLive intValue] * 3600 * 24;
            });
            
            
            
            if(secondsToLive < ageInSeconds)
            {
                NSLog(@"deleting folder");
                [foldersToDelete addObject:pathOfFileInDirectory];
            }
            NSLog(@"file/folder:%@   age: %f secondsToLife:%f",oneFilenameInDirectory,ageInSeconds,secondsToLive);
            
        }
        
        [self deleteFolders:foldersToDelete];
    }
    else
    {
        NSLog(@"error accessing folder: %@",error);
    }
}

- (void)deleteFolders:(NSArray *)foldersToDelete
{
    
    NSError *removingFolderError;
    for (NSString *oneFolderToDelete in foldersToDelete) {
        [[NSFileManager defaultManager] removeItemAtPath:oneFolderToDelete
                                                   error:&removingFolderError];
        if(removingFolderError)
        {
            NSLog(@"error removing folder: %@", removingFolderError);
        }
    }
    
}

- (IBAction)preferencesClicked:(id)sender
{
    
    
    
}

@end
