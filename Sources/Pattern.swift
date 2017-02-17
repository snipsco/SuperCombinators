//
//  Pattern.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 09/02/2017.
//
//

public final class Pattern {

    public let parse: (String) -> String.Index?

    public init(parse: @escaping (String) -> String.Index?) {
        self.parse = parse
    }
}

extension Parser {

    public var pattern: Pattern {
        return Pattern { text in
            return self.parse(text)?.suffixIndex
        }
    }

    public convenience init(_ pattern: Pattern, _ value: Value) {
        self.init { text in
            guard let suffixIndex = pattern.parse(text) else { return nil }
            return Result(value: value, suffixIndex: suffixIndex)
        }
    }

    public func separated(by separator: Pattern) -> Parser<[Value]> {
        return Parser<[Value]> { text in
            guard let first = self.parse(text) else { return nil }

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

    public convenience init(prefix: String) {
        self.init { text in
            guard text.hasPrefix(prefix) else { return nil }
            let suffixIndex = text.index(text.startIndex, offsetBy: prefix.characters.count)
            return suffixIndex
        }
    }

    public convenience init(count: Int) {
        self.init { text in
            return text.index(text.startIndex, offsetBy: count, limitedBy: text.endIndex)
        }
    }

    public static var pure: Pattern {
        return Pattern { text in text.startIndex }
    }

    public static var empty: Pattern {
        return Pattern { text in text.isEmpty ? text.endIndex : nil }
    }

    public var optional: Pattern {
        return Pattern { text in self.parse(text) ?? text.startIndex }
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
