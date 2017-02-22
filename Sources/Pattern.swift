//
//  Pattern.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 09/02/2017.
//
//

/**
 Parses a prefix of a string, returning the prefix's end index on success.
*/
public final class Pattern {

    /**
     Parses a prefix of a string, returning the prefix's end index on success.
    */
    public let parsePrefix: (String) -> String.Index?

    public init(parsePrefix: @escaping (String) -> String.Index?) {
        self.parsePrefix = parsePrefix
    }
}

extension Parser {

    /**
     Creates a pattern that parses the prefix of a string using `self.parse` and ignores the value.
    */
    public var pattern: Pattern {
        return Pattern { text in
            return self.parsePrefix(text)?.suffixIndex
        }
    }

    /**
     Create a parser that parses the prefix of a string using `pattern.parse` and returns `value` as the value.
    */
    public convenience init(_ pattern: Pattern, _ value: Value) {
        self.init { text in
            guard let suffixIndex = pattern.parsePrefix(text) else { return nil }
            return Result(value: value, suffixIndex: suffixIndex)
        }
    }

    /**
     Create a parser that parses the prefix of a string using `pattern.parse` and returns `value` as the value.
     
     Returns an array of values that can be parsed by `self` given that their strings are separated by substrings matched by `separator`.
     */
    public func separated(by separator: Pattern) -> Parser<[Value]> {
        return Parser<[Value]> { text in
            guard let first = self.parsePrefix(text) else { return nil }

            let combined = separator + self

            var values = [first.value]
            var suffixIndex = first.suffixIndex

            while let next = combined.parseSuffix(of: text, after: suffixIndex) {
                values.append(next.value)
                suffixIndex = next.suffixIndex
                guard suffixIndex != text.endIndex else { break }
            }

            return ParseResult<[Value]>(value: values, suffixIndex: suffixIndex)
        }
    }
}

extension Pattern {

    /**
     Create a pattern that matches the prefix of a string if it is equal to the prefix provided.
    */
    public convenience init(prefix: String) {
        self.init { text in
            guard text.hasPrefix(prefix) else { return nil }
            let suffixIndex = text.index(text.startIndex, offsetBy: prefix.characters.count)
            return suffixIndex
        }
    }

    /**
     Create a pattern that returns the prefix composed of `count` Characters, and fails if the input is not long enough.
    */
    public convenience init(count: Int) {
        self.init { text in
            return text.index(text.startIndex, offsetBy: count, limitedBy: text.endIndex)
        }
    }

    /**
     Create a pattern that does not parse anything and never fails.
    */
    public static var pure: Pattern {
        return Pattern { text in text.startIndex }
    }

    /**
     Create a pattern that fails on any string but "".
    */
    public static var empty: Pattern {
        return Pattern { text in text.isEmpty ? text.endIndex : nil }
    }

    /**
     Create a pattern that parses using `self.parse`. If that fails, returns the whole text as suffix.
     - Note: is equivalent to `self || .pure`
    */
    public var optional: Pattern {
        return Pattern { text in self.parsePrefix(text) ?? text.startIndex }
    }
}

extension Pattern: ExpressibleByStringLiteral {

    public convenience init(stringLiteral value: String) {
        self.init(prefix: value)
    }

    public convenience init(unicodeScalarLiteral value: String) {
        self.init(prefix: value)
    }

    public convenience init(extendedGraphemeClusterLiteral value: String) {
        self.init(prefix: value)
    }
}
