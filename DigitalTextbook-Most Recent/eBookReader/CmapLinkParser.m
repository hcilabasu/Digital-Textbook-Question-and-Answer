//
//  CmapLinkParser.m
//  eBookReader
//
//  Created by Shang Wang on 6/14/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "CmapLinkParser.h"
#import "GDataXMLNode.h"
@implementation CmapLinkParser


+ (NSString *)dataFilePath:(BOOL)forSave {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentsPath = [documentsDirectory
                               stringByAppendingPathComponent:@"CmapLinkList.xml"];
    if (forSave ||
        [[NSFileManager defaultManager] fileExistsAtPath:documentsPath]) {
        return documentsPath;
    } else {
        return [[NSBundle mainBundle] pathForResource:@"CmapLinkList" ofType:@"xml"];
    }
}

+ (CmapLinkWrapper *)loadCmapLink{
    CmapLinkWrapper *cmapLinkWrapper = [[CmapLinkWrapper alloc] init];
    NSString *filePath = [self dataFilePath:FALSE];
    NSData *xmlData = [[NSMutableData alloc] initWithContentsOfFile:filePath];
    NSError *error;
    GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:xmlData
                                                           options:0 error:&error];
    if (doc == nil) {
        NSLog(@"Thumbnail Doc Nil!\n");
        return cmapLinkWrapper;
    }
    // NSLog(@"%@", doc.rootElement);
    NSArray *partyMembers = [doc.rootElement elementsForName:@"CmapLink"];
    if([partyMembers count]==0){
        NSLog(@"Empty!!!!\n\n\n");
    }
    for (GDataXMLElement *partyMember in partyMembers) {
        NSString *leftName=@"";
        NSString *rightName=@"";
        NSString *relationName=@"";
        
        NSArray *l_name = [partyMember elementsForName:@"leftConceptName"];
        if (l_name.count > 0) {
            GDataXMLElement *nameitem = (GDataXMLElement *) [l_name objectAtIndex:0];
            leftName = nameitem.stringValue;
        } else continue;
        
        NSArray *r_name = [partyMember elementsForName:@"rightConceptName"];
        if (r_name.count > 0) {
            GDataXMLElement *titleitem = (GDataXMLElement *) [r_name objectAtIndex:0];
            rightName = titleitem.stringValue;
        } else continue;
        
        NSArray *relation_name = [partyMember elementsForName:@"relationName"];
        if (relation_name.count > 0) {
            GDataXMLElement *titleitem = (GDataXMLElement *) [relation_name objectAtIndex:0];
            relationName = titleitem.stringValue;
        } else continue;
        
        CmapLink *player = [[CmapLink alloc] initWithName:leftName conceptName:rightName relation:relationName];
        [cmapLinkWrapper.cmapLinks addObject:player];
    }
    return cmapLinkWrapper;
}


+ (void)saveCmapLink:(CmapLinkWrapper *)wrapper {
    
    GDataXMLElement * partyElement = [GDataXMLNode elementWithName:@"CmapLinkList"];
    if([wrapper.cmapLinks count]==0){
        NSLog(@"0000000!!");
    }
    
    for(CmapLink *linkItem in wrapper.cmapLinks) {
        
        GDataXMLElement * itemElement =
        [GDataXMLNode elementWithName:@"CmapLink"];
        
        GDataXMLElement * conceptNameElementLeft =
        [GDataXMLNode elementWithName:@"leftConceptName" stringValue:linkItem.leftConceptName];
        
        GDataXMLElement * conceptNameElementRight =
        [GDataXMLNode elementWithName:@"rightConceptName" stringValue:linkItem.rightConceptName];
        
        GDataXMLElement * conceptNameElementRelation =
        [GDataXMLNode elementWithName:@"relationName" stringValue:linkItem.relationName];
        [itemElement addChild:conceptNameElementLeft];
        [itemElement addChild:conceptNameElementRight];
        [itemElement addChild:conceptNameElementRelation];
        [partyElement addChild:itemElement];
        NSLog(@"Add element");
        
    }
    GDataXMLDocument *document = [[GDataXMLDocument alloc]
                                  initWithRootElement:partyElement];
    NSData *xmlData = document.XMLData;
    NSString *filePath = [self dataFilePath:TRUE];
    NSLog(@"Saving xml data to %@...", filePath);
    [xmlData writeToFile:filePath atomically:YES];
    
}

@end
