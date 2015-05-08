//
//  CmapLink.m
//  eBookReader
//
//  Created by Shang Wang on 6/14/14.
//  Copyright (c) 2014 Andreea Danielescu. All rights reserved.
//

#import "CmapLink.h"

@implementation CmapLink
@synthesize leftConceptName;
@synthesize relationName;
@synthesize rightConceptName;

- (id)initWithName:(NSString*)m_leftConceptName conceptName: (NSString*)m_rightConceptName relation: (NSString*)m_relationName{
    
    if ((self = [super init])) {
        leftConceptName=m_leftConceptName;
        rightConceptName=m_rightConceptName;
        relationName=m_relationName;
    }
    return self;
    
}

@end
