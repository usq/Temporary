//
//  MCOFolderScanner.h
//  Temporary
//
//  Created by Michael Conrads on 09/05/14.
//
//

#import <Foundation/Foundation.h>

@interface MCOFolderScanner : NSObject
- (NSTimeInterval)ageOfFolderAtPath:(NSString *)folderPath;
- (void)moveToTrash:(NSString *)folderPath;
@end
