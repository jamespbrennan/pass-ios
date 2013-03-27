/*
 * Copyright 2012 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "ZXParsedResult.h"

@interface ZXCalendarParsedResult : ZXParsedResult

@property (nonatomic, retain, readonly) NSString *summary;
@property (nonatomic, retain, readonly) NSDate *start;
@property (nonatomic, readonly) BOOL startAllDay;
@property (nonatomic, retain, readonly) NSDate *end;
@property (nonatomic, readonly) BOOL endAllDay;
@property (nonatomic, retain, readonly) NSString *location;
@property (nonatomic, retain, readonly) NSString *organizer;
@property (nonatomic, retain, readonly) NSArray *attendees;
@property (nonatomic, retain, readonly) NSString *description;
@property (nonatomic, readonly) double latitude;
@property (nonatomic, readonly) double longitude;

- (id)initWithSummary:(NSString *)summary startString:(NSString *)startString endString:(NSString *)endString location:(NSString *)location
            organizer:(NSString *)organizer attendees:(NSArray *)attendees description:(NSString *)description latitude:(double)latitude longitude:(double)longitude;
+ (id)calendarParsedResultWithSummary:(NSString *)summary startString:(NSString *)startString endString:(NSString *)endString location:(NSString *)location
                            organizer:(NSString *)organizer attendees:(NSArray *)attendees description:(NSString *)description latitude:(double)latitude longitude:(double)longitude;

@end
