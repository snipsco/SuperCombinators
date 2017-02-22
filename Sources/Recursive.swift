//
//  Recursive.swift
//  SuperCombinators
//
//  Created by Alexandre Lopoukhine on 14/02/2017.
//
//

private final class RecursiveParser<Value> {

    private let generate: (RecursiveParser) -> (String) -> ParseResult<Value>?

    private(set) lazy var parsePrefix: (String) -> ParseResult<Value>? = self.generate(self)

    init(generateParser: @escaping (Parser<Value>) -> Parser<Value>) {
        self.generate = { rec in
            let box = Parser<Value> { [unowned rec] text in
                return rec.parsePrefix(text)
            }
            return generateParser(box).parsePrefix
        }
    }
}

extension Parser {

    /**
     Creates a `Parser` for a recursive grammar.
     
     - Note: Within the scope of the closure, the input parser's `parse` method is not defined, and will crash if called.
    */
    public static func recursive(generateParser: @escaping (Parser) -> Parser) -> Parser {
        let rec = RecursiveParser(generateParser: generateParser)
        return Parser { text in
            return rec.parsePrefix(text)
        }
    }
}

private final class RecursivePattern {

    private let generate: (RecursivePattern) -> (String) -> String.Index?

    private(set) lazy var parsePrefix: (String) -> String.Index? = self.generate(self)

    init(generateParser: @escaping (Pattern) -> Pattern) {
        self.generate = { rec in
            let box = Pattern { [unowned rec] text in
                return rec.parsePrefix(text)
            }
            return generateParser(box).parsePrefix
        }
    }
}

extension Pattern {

    /**
     Creates a `Pattern` for a recursive grammar.

     - Note: Within the scope of the closure, the input pattern's `parse` method is not defined, and will crash if called.
     */
    public static func recursive(generateParser: @escaping (Pattern) -> Pattern) -> Pattern {
        let rec = RecursivePattern(generateParser: generateParser)
        return Pattern { text in
            return rec.parsePrefix(text)
        }
    }
}

