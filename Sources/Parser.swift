//
//  Parser.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 09/02/2017.
//
//

public struct ParseResult<Value> {

    public let value: Value
    public let suffixIndex: String.Index

    public init(value: Value, suffixIndex: String.Index) {
        self.value = value
        self.suffixIndex = suffixIndex
    }
}

public final class Parser<Value> {

    public typealias Result = ParseResult<Value>

    public let parse: (String) -> Result?

    public init(parse: @escaping (String) -> Result?) {
        self.parse = parse
    }

    public func parseAll(_ text: String) -> Value? {
        guard let result = parse(text), text.endIndex == result.suffixIndex else { return nil }
        return result.value
    }
}

extension Parser {

    public static func pure(_ value: Value) -> Parser {
        return Parser { text in Result(value: value, suffixIndex: text.startIndex) }
    }

    public static func fail(message: String? = nil) -> Parser {
        if let message = message {
            return Parser { _ in print(message); return nil }
        } else {
            return Parser { _ in return nil }
        }
    }

    var optional: Parser<Value?> {
        return Parser<Value?> { text in
            let result = self.parse(text)
            return ParseResult<Value?>(
                value: result?.value,
                suffixIndex: result?.suffixIndex ?? text.startIndex
            )
        }
    }

    public func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Parser<NewValue> {
        return Parser<NewValue> { text in
            guard let result = self.parse(text) else { return nil }
            return ParseResult<NewValue>(
                value: transform(result.value),
                suffixIndex: result.suffixIndex
            )
        }
    }

    public func flatMap<NewValue>(_ transform: @escaping (Value) -> Parser<NewValue>) -> Parser<NewValue> {
        return Parser<NewValue> { text in
            guard let r0 = self.parse(text) else { return nil }
            return transform(r0.value).parseSuffix(of: text, after: r0.suffixIndex)
        }
    }

    public func test(_ test: @escaping (Value) -> Bool) -> Parser {
        return Parser { characters in
            guard let result = self.parse(characters), test(result.value) else { return nil }
            return result
        }
    }
}

// MARK: Apply

public func / <A, B>(lhs: Parser<A>, rhs: Parser<(A) -> B>) -> Parser<B> {
    return lhs.and(rhs).map { $1($0) }
}

public func / <A, B>(lhs: Parser<(A) -> B>, rhs: Parser<A>) -> Parser<B> {
    return lhs.and(rhs).map { $0($1) }
}
