//
//  Recursive.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 14/02/2017.
//
//

private final class RecursiveParser<Value> {

    private let generate: (RecursiveParser) -> (String) -> ParseResult<Value>?

    private(set) lazy var parse: (String) -> ParseResult<Value>? = self.generate(self)

    init(generateParser: @escaping (Parser<Value>) -> Parser<Value>) {
        self.generate = { rec in
            let box = Parser<Value> { [unowned rec] text in
                return rec.parse(text)
            }
            return generateParser(box).parse
        }
    }
}

extension Parser {

    public static func recursive(generateParser: @escaping (Parser) -> Parser) -> Parser {
        let rec = RecursiveParser(generateParser: generateParser)
        return Parser { text in
            return rec.parse(text)
        }
    }
}

private final class RecursivePattern {

    private let generate: (RecursivePattern) -> (String) -> String.Index?

    private(set) lazy var parse: (String) -> String.Index? = self.generate(self)

    init(generateParser: @escaping (Pattern) -> Pattern) {
        self.generate = { rec in
            let box = Pattern { [unowned rec] text in
                return rec.parse(text)
            }
            return generateParser(box).parse
        }
    }
}

extension Pattern {

    public static func recursive(generateParser: @escaping (Pattern) -> Pattern) -> Pattern {
        let rec = RecursivePattern(generateParser: generateParser)
        return Pattern { text in
            return rec.parse(text)
        }
    }
}

