//
//  ALStringInflector.m
//  patchwork
//
//  Created by Alex Lee on 27/10/2016.
//  Copyright © 2016 Alex Lee. All rights reserved.
//

#import "ALStringInflector.h"
#import "UtilitiesHeader.h"
#import "NSString+Helper.h"
#import "ALLogger.h"
#import "ALLock.h"


@implementation NSString (ALStringInflector)

- (NSString *)singularize {
    return [[ALStringInflector defaultInflector] singularize:self];
}

- (NSString *)pluralize {
    return [[ALStringInflector defaultInflector] pluralize:self];
}

@end



@interface ALStringInflectorRule : NSObject
@property(PROP_ATOMIC_DEF, strong) NSRegularExpression  *regExp;
@property(PROP_ATOMIC_DEF, copy)   NSString             *replacement;
@end

@implementation ALStringInflectorRule

+ (instancetype)ruleWithPattern:(NSString *)pattern replacement:(NSString *)replacement {
    if (pattern == nil || replacement == nil) {
        return nil;
    }
    ALStringInflectorRule *rule = [[self alloc] init];
    NSError *error              = nil;
    NSRegularExpression *regexp = [NSRegularExpression
                                   regularExpressionWithPattern:pattern
                                   options:NSRegularExpressionAnchorsMatchLines | NSRegularExpressionCaseInsensitive |
                                   NSRegularExpressionUseUnicodeWordBoundaries
                                   error:&error];
    if (regexp == nil) {
        ALLogError(@"%@", error);
        return nil;
    }
    
    rule.regExp = regexp;
    rule.replacement = replacement;
    return rule;
}

- (BOOL)evaluate:(NSMutableString *)inputString {
    return [self.regExp replaceMatchesInString:inputString
                                       options:0
                                         range:NSMakeRange(0, inputString.length)
                                  withTemplate:self.replacement] > 0;
}

@end

@implementation ALStringInflector {
    NSMutableArray<ALStringInflectorRule *>     *_pluralRules;
    NSMutableArray<ALStringInflectorRule *>     *_singularRules;
    NSMutableSet<NSString *>                    *_uncountables;
    NSMutableDictionary<NSString *, NSString *> *_irregulars;
}

+ (instancetype)defaultInflector {
    static ALStringInflector *instance = nil;
    static_gcd_semaphore(sem, 1)
    with_gcd_semaphore(sem, DISPATCH_TIME_FOREVER, ^{
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self addENUSPluralizationRules];
    }
    return self;
}

- (NSString *)singularize:(NSString *)string {
    if ([_uncountables containsObject:string]) {
        return string;
    }
    
    NSArray *irregularSingulars = [_irregulars allKeysForObject:string];
    if ([irregularSingulars count] > 0) {
        return [irregularSingulars lastObject];
    }
    
    __block NSMutableString *mutableString = [string mutableCopy];
    [_singularRules enumerateObjectsUsingBlock:^(ALStringInflectorRule * _Nonnull rule, NSUInteger idx, BOOL * _Nonnull stop) {
        *stop = [rule evaluate:mutableString];
    }];
    return mutableString;
}

- (NSString *)pluralize:(NSString *)string {
    if ([_uncountables containsObject:string]) {
        return string;
    }
    
    NSString *irregularPlural = [_irregulars objectForKey:string];
    if (irregularPlural != nil) {
        return irregularPlural;
    }
    
    __block NSMutableString *mutableString = [string mutableCopy];
    [_pluralRules enumerateObjectsUsingBlock:^(ALStringInflectorRule * _Nonnull rule, NSUInteger idx, BOOL * _Nonnull stop) {
        *stop = [rule evaluate:mutableString];
    }];
    
    return mutableString;
}


- (void)addPluralRule:(NSString *)pattern replacement:(NSString *)replacement {
    [_uncountables removeObject:pattern];
    [_uncountables removeObject:replacement];

    ALStringInflectorRule *rule = [ALStringInflectorRule ruleWithPattern:pattern replacement:replacement];
    if (rule == nil) {
        return;
    }
    [_pluralRules addObject:rule];
}

- (void)addSingularRule:(NSString *)pattern replacement:(NSString *)replacement {
    [_uncountables removeObject:pattern];
    
    ALStringInflectorRule *rule = [ALStringInflectorRule ruleWithPattern:pattern replacement:replacement];
    if (rule == nil) {
        return;
    }
    [_singularRules addObject:rule];
}

- (void)addIrregularWithSingular:(NSString *)singular plural:(NSString *)plural {
    if (isEmptyString(singular) || isEmptyString(plural)) {
        return;
    }
    [_irregulars setObject:plural forKey:singular];
    [_irregulars setObject:[plural capitalizedString] forKey:[singular capitalizedString]];
}

- (void)addUncountable:(NSString *)word {
    [_uncountables addObject:word];
}

#pragma mark -
- (void)addENUSPluralizationRules {
    ///
    _singularRules = [NSMutableArray array];
    [self addSingularRule:@"(database)s$" replacement:@"$1"];
    [self addSingularRule:@"(quiz)zes$" replacement:@"$1"];
    [self addSingularRule:@"(matr)ices$" replacement:@"$1ix"];
    [self addSingularRule:@"(vert|ind)ices$" replacement:@"$1ex"];
    [self addSingularRule:@"^(ox)en" replacement:@"$1"];
    [self addSingularRule:@"(alias|status)(es)?$" replacement:@"$1"];
    [self addSingularRule:@"(octop|vir)(us|i)$" replacement:@"$1us"];
    [self addSingularRule:@"^(a)x[ie]s$" replacement:@"$1xis"];
    [self addSingularRule:@"(cris|test)(is|es)$" replacement:@"$1is"];
    [self addSingularRule:@"(shoe)s$" replacement:@"$1"];
    [self addSingularRule:@"(o)es$" replacement:@"$1"];
    [self addSingularRule:@"(bus)(es)?$" replacement:@"$1"];
    [self addSingularRule:@"^(m|l)ice$" replacement:@"$1ouse"];
    [self addSingularRule:@"(x|ch|ss|sh)es$" replacement:@"$1"];
    [self addSingularRule:@"(m)ovies$" replacement:@"$1ovie"];
    [self addSingularRule:@"(s)eries$" replacement:@"$1eries"];
    [self addSingularRule:@"([^aeiouy]|qu)ies$" replacement:@"$1y"];
    [self addSingularRule:@"([lr])ves$" replacement:@"$1f"];
    [self addSingularRule:@"(tive)s$" replacement:@"$1"];
    [self addSingularRule:@"(hive)s$" replacement:@"$1"];
    [self addSingularRule:@"([^f])ves$" replacement:@"$1fe"];
    [self addSingularRule:@"([ti])a$" replacement:@"$1um"];
    [self addSingularRule:@"(n)ews$" replacement:@"$1ews"];
    [self addSingularRule:@"(ss)$" replacement:@"$1"];
    [self addSingularRule:@"s$" replacement:@""];
    
    ///
    _pluralRules = [NSMutableArray array];
    [self addPluralRule:@"(quiz)$" replacement:@"$1zes"];
    [self addPluralRule:@"^(oxen)$" replacement:@"$1"];
    [self addPluralRule:@"^(ox)$" replacement:@"$1en"];
    [self addPluralRule:@"^(m|l)ice$" replacement:@"$1ice"];
    [self addPluralRule:@"^(m|l)ouse$" replacement:@"$1ice"];
    [self addPluralRule:@"(matr|vert|ind)(?:ix|ex)$" replacement:@"$1ices"];
    [self addPluralRule:@"(x|ch|ss|sh)$" replacement:@"$1es"];
    [self addPluralRule:@"([^aeiouy]|qu)y$" replacement:@"$1ies"];
    [self addPluralRule:@"(hive)$" replacement:@"$1s"];
    [self addPluralRule:@"(?:([^f])fe|([lr])f)$" replacement:@"$1$2ves"];
    [self addPluralRule:@"sis$" replacement:@"ses"];
    [self addPluralRule:@"([ti])a$" replacement:@"$1a"];
    [self addPluralRule:@"([ti])um$" replacement:@"$1a"];
    [self addPluralRule:@"(buffal|tomat)o$" replacement:@"$1oes"];
    [self addPluralRule:@"(bu)s$" replacement:@"$1ses"];
    [self addPluralRule:@"(alias|status)$" replacement:@"$1es"];
    [self addPluralRule:@"(octop|vir)i$" replacement:@"$1i"];
    [self addPluralRule:@"(octop|vir)us$" replacement:@"$1i"];
    [self addPluralRule:@"^(ax|test)is$" replacement:@"$1es"];
    [self addPluralRule:@"s$" replacement:@"s"];
    [self addPluralRule:@"$" replacement:@"s"];
    
    ///
    _irregulars = [NSMutableDictionary dictionary];
    [self addIrregularWithSingular:@"person" plural:@"people"];
    [self addIrregularWithSingular:@"man" plural:@"men"];
    [self addIrregularWithSingular:@"child" plural:@"children"];
    [self addIrregularWithSingular:@"sex" plural:@"sexes"];
    [self addIrregularWithSingular:@"move" plural:@"moves"];
    [self addIrregularWithSingular:@"cow" plural:@"cattle"];
    [self addIrregularWithSingular:@"zombie" plural:@"zombies"];
    
    ///
    _uncountables = [NSMutableSet set];
    [self addUncountable:@"equipment"];
    [self addUncountable:@"information"];
    [self addUncountable:@"rice"];
    [self addUncountable:@"money"];
    [self addUncountable:@"species"];
    [self addUncountable:@"series"];
    [self addUncountable:@"fish"];
    [self addUncountable:@"sheep"];
    [self addUncountable:@"jeans"];
}

@end


