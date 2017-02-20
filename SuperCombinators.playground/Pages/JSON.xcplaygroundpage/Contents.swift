//: [Previous](@previous)

import SuperCombinators

extension Dictionary {

    init<Pairs: Sequence>(pairs: Pairs) where Pairs.Iterator.Element == (Key, Value) {
        var temp: [Key: Value] = [:]
        for (key, value) in pairs {
            temp[key] = value
        }
        self = temp
    }
}

extension Int {

    private static let map: [UnicodeScalar: Int] = [
        "0": 0,
        "1": 1,
        "2": 2,
        "3": 3,
        "4": 4,
        "5": 5,
        "6": 6,
        "7": 7,
        "8": 8,
        "9": 9,
        "a": 10,
        "b": 11,
        "c": 12,
        "d": 13,
        "e": 14,
        "f": 15,
        "A": 10,
        "B": 11,
        "C": 12,
        "D": 13,
        "E": 14,
        "F": 15,
    ]

    init?(hex: String) {
        var result = 0
        for scalar in hex.unicodeScalars {
            guard let digit = Int.map[scalar] else { return nil }
            result *= 16
            result += digit
        }
        self = result
    }
}


let json: Parser<Any>
do {
    let number: Parser<Any>
    do {
        enum NumberFormat {
            case int(Int)
            case intFrac(Int, Int)
            case intExp(Int, Int)
            case intFracExp(Int, Int, Int)

            var value: Any {
                switch self {
                case let .int(int):
                    return int
                case let .intFrac(int, frac):
                    var result = Double(frac)
                    while result > 1 {
                        result /= 10
                    }
                    return result + Double(int)
                case let .intExp(int, exp):
                    return pow(Double(int), Double(exp))
                case let .intFracExp(int, frac, exp):
                    var base = Double(frac)
                    while base > 1 {
                        base /= 10
                    }
                    return pow(base + Double(int), Double(exp))
                }
            }
        }

        let e = "e" || "e+" || "E" || "E+"
        let digits = Pattern.characters(in: .decimalDigits).stringParser.map { Int($0)! }
        let int = (Pattern(prefix: "-").optional + digits).stringParser.map { Int($0)! }
        let exp = e + int
        let frac = "." + digits
        let numberFormat = Parser<NumberFormat>.either(
            (int + frac + exp).map { NumberFormat.intFracExp($0.0, $0.1, $1) },
            (int + frac).map(NumberFormat.intFrac),
            (int + exp).map(NumberFormat.intExp),
            int.map(NumberFormat.int)
        )
        number = numberFormat.map { $0.value }
    }

    let string: Parser<String>
    do {
        let stringChars = Pattern.characters(
            in: CharacterSet(charactersIn: "\\\"").inverted
        ).stringParser
        let escaped: Parser<String>
        do {
            let hexChars = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
            let unicode = Pattern.character(in: hexChars)
                .count(4)
                .stringParser
                .map { hex -> String in
                    let number = Int(hex: hex)!
                    let scalar = UnicodeScalar(UInt16(number))
                    return String(stringInterpolationSegment: scalar)
                }

            escaped = Parser<String>.either(
                Parser<String>("\\\"", "\""),
                Parser<String>("\\\\", "\\"),
                Parser<String>("\\/", "/"),
                Parser<String>("\\b", "b"),
                Parser<String>("\\f", "f"),
                Parser<String>("\\n", "\n"),
                Parser<String>("\\r", "\r"),
                Parser<String>("\\t", "\t"),
                "\\u" + unicode
            )
        }

        let text = Parser<String>.recursive { text -> Parser<String> in
            let prefix: Parser<String> = (stringChars + escaped).map(+)
                || stringChars
                || escaped
            return (prefix + text).map(+)
                || prefix
        }

        string = "\"" + text + "\"" || Parser<String>("\"\"", "")
    }

    let space = Pattern
        .characters(in: .whitespacesAndNewlines)
        .optional

    json = Parser<Any>.recursive { json in
        let array: Parser<[Any]>
        do {
            let empty = Parser<[Any]>("[" + space.optional + "]", [])
            let notEmpty = "["
                + space
                + json.separated(by: "," + space)
                + space
                + "]"
            array = empty || notEmpty
        }

        let object: Parser<[String: Any]>
        do {
            let empty = Parser<[String: Any]>("{" + space.optional + "}", [:])
            let pair = string + space + ":" + space + json
            let pairs = pair.separated(by: "," + space)
                .map { pairs in [String: Any](pairs: pairs) }
            let notEmpty = "{"
                + space
                + pairs
                + space
                + "}"
            object = empty || notEmpty
        }

        return string.map { $0 as Any }
            || number
            || object.map { $0 as Any }
            || array.map { $0 as Any }
            || Parser<Any>("true", true)
            || Parser<Any>("false", false)
    }
}

let myJSON = "{ \"hello\": [ 123, {}, [ \"\\t\"]] }"

print(json.parseAll(myJSON)!)

//: [Next](@next)
