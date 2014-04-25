//
//  MCOTemporaryFilesManager.m
//  Temporary
//
//  Created by Michael Conrads on 25/04/14.
//
//

#import "MCOTemporaryFilesManager.h"

@interface MCOTemporaryFilesManager ()
@property (nonatomic, strong, readwrite) NSTimer *timer;
@end


@implementation MCOTemporaryFilesManager

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self)
    {
        self.timeIntervalToCheck = 60 * 30; //every 30 minutes
        self.pathToTempDirectory = path;
    }
    return self;
}


- (void)deleteOutdatedFilesInTempDirectory
{
    if(self.pathToTempDirectory.length > 0)
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
                
                NSTimeInterval secondsToLive = [self secondsRemainingForFileAtPath:oneFilenameInDirectory];
                
                if(secondsToLive < ageInSeconds)
                {
                    NSLog(@"deleting folder");
                    [foldersToDelete addObject:pathOfFileInDirectory];
                }
                //NSLog(@"file/folder:%@   age: %f secondsToLife:%f",oneFilenameInDirectory,ageInSeconds,secondsToLive);
            }
            [self deleteFilesAtPaths:foldersToDelete];
        }
        else
        {
            NSLog(@"error accessing folder: %@",error);
        }
    }
    else
    {
        NSLog(@"path not set");
    }
}


- (NSTimeInterval)secondsRemainingForFileAtPath:(NSString *)filePath
{
    NSScanner *s = [NSScanner scannerWithString:filePath];
    [s scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet]
                      intoString:nil];
    
    NSString *daysToLive;
    BOOL didScanNumber =[s scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet]
                                      intoString:&daysToLive];
    
    NSTimeInterval remainingSeconds = CGFLOAT_MAX;
    if(didScanNumber)
    {
        remainingSeconds = [daysToLive intValue] * 3600 * 24;
    }
    return remainingSeconds;
}

- (void)setTimeIntervalToCheck:(NSTimeInterval)timeIntervalToCheck
{
    
    float minimumHours = 0.1 * 3600;
    if(timeIntervalToCheck < minimumHours)
    {
        timeIntervalToCheck = minimumHours;
    }
    
    _timeIntervalToCheck = timeIntervalToCheck;
    [self.timer invalidate];
    self.timer = nil;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeIntervalToCheck
                                                  target:self
                                                selector:@selector(deleteOutdatedFilesInTempDirectory)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)deleteFilesAtPaths:(NSArray *)pathsToDelete
{
    NSError *removeFileError;
    for (NSString *oneFolderToDelete in pathsToDelete) {
        
        
        [[NSFileManager defaultManager] removeItemAtPath:oneFolderToDelete
                                                   error:&removeFileError];
        if(removeFileError)
        {
            NSLog(@"error removing folder: %@", removeFileError);
        }
    }
    
}

- (NSString *)pathToTempDirectory
{
    if(_pathToTempDirectory == nil)
    {
        _pathToTempDirectory = @"";
    }
    return _pathToTempDirectory;
}

@end
