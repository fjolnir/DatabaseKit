@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"s"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"s$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"s"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(ax|test)is$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1es"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(octop|vir)us$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1i"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(alias|status)$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1es"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(bu)s$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1ses"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(buffal|tomat)o$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1oes"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"([ti])um$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1a"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"sis$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"ses
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(?:([^f])fe|([lr])f)$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1$2ves"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(hive)$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1s"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"([^aeiouy]|qu)y$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1ies"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(x|ch|ss|sh)$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1es"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(matr|vert|ind)ix|ex$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1ices"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"([m|l])ouse$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1ice"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"^(ox)$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1en"
},

@{
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(quiz)$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1zes"
},


@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"s$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement":"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(n)ews$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1ews"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"([ti])a$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1um"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1\2sis"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(^analy)ses$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1sis"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"([^f])ves$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1fe"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(hive)s$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(tive)s$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"([lr])ves$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1f"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"([^aeiouy]|qu)ies$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1y"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(s)eries$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1eries"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(m)ovies$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1ovie"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(x|ch|ss|sh)es$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"([m|l])ice$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1ouse"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(bus)es$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(o)es$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(shoe)s$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(cris|ax|test)es$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1is"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(octop|vir)i$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1us"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(alias|status)es$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"^(ox)en" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(vert|ind)ices$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1ex"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(matr)ices$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1ix"
},

@{
    @"type": @"singular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"(quiz)zes$" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"$1"
},

@{
    @"type": @"irregular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"person" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"people"
},

@{
    @"type": @"irregular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"man" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"men"
},

@{
    @"type": @"irregular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"child" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"children"
},

@{
    @"type": @"irregular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"sex" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"sexes"
},

@{
    @"type": @"irregular",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"move" options:NSRegularExpressionCaseInsensitive error:NULL],
    @"replacement": @"moves"
},

@{
    @"type": @"uncountable",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"equipment" options:NSRegularExpressionCaseInsensitive error:NULL]
},
@{
    @"type": @"uncountable",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"move" options:NSRegularExpressionCaseInsensitive error:NULL]
},
@{
    @"type": @"uncountable",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"move" options:NSRegularExpressionCaseInsensitive error:NULL]
},
@{
    @"type": @"uncountable",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"move" options:NSRegularExpressionCaseInsensitive error:NULL]
},
@{
    @"type": @"uncountable",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"move" options:NSRegularExpressionCaseInsensitive error:NULL]
},
@{
    @"type": @"uncountable",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"move" options:NSRegularExpressionCaseInsensitive error:NULL]
},
@{
    @"type": @"uncountable",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"move" options:NSRegularExpressionCaseInsensitive error:NULL]
},
@{
    @"type": @"uncountable",
    @"regex": [NSRegularExpression regularExpressionWithPattern:@"move" options:NSRegularExpressionCaseInsensitive error:NULL]
}
