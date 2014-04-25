//
//  MCOTemporaryFilesManager.h
//  Temporary
//
//  Created by Michael Conrads on 25/04/14.
//
//

#import <Foundation/Foundation.h>

@interface MCOTemporaryFilesManager : NSObject
@property (nonatomic, strong, readwrite) NSString *pathToTempDirectory;
@property (nonatomic, assign, readwrite) NSTimeInterval timeIntervalToCheck;

- (void)deleteOutdatedFilesInTempDirectory;
- (instancetype)initWithPath:(NSString *)path;
@end
