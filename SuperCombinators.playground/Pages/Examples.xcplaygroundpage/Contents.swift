
import SuperCombinators

// basic floating point parser

let digits = Pattern.characters(in: .decimalDigits)
let uint = digits.stringParser.map { Int($0)! }
let ufloat0 = uint.map(Double.init)

let ufloat1 = ("." & ufloat0).map { float -> Double in
    guard 0 < float else { return 0 }
    let power = log10(float).rounded(.down) + 1
    return float / pow(10, power)
}

let ufloat = (ufloat0.optional & ufloat1.optional)
    .test { nil != $0 || nil != $1 }
    .map { ($0 ?? 0) + ($1 ?? 0) }

let float = ufloat || ("-" & ufloat).map { -$0 }


float.parse("-.1")
float.parse("123.456")


// signed integer

let int = uint || ("-" & uint).map { -$0 }

print(int.parse("-123")! + int.parse("321")!)


// generalizing signed numbers

func signed<Signed: SignedNumber>(_ unsigned: Parser<Signed>) -> Parser<Signed> {
    return unsigned || ("-" & unsigned).map { -$0 }
}

let float1 = signed(ufloat)
let int1 = signed(uint.map { Int($0) })




let notQuote = Pattern.characters(
    notIn: CharacterSet(charactersIn: "\"")
)
let string = "\"" & notQuote.stringParser & "\""

print(string.parse("\"bla\"")!)
// prints bla




// A cell is a `String` or an `Int`
let cell = string.map { $0 as Any } || int.map { $0 as Any }
// A row is a sequence of cells separated by ","
let row = cell.separated(by: ",")
// A CSV file is a possibly empty sequence of rows with a "\n" at the end
let csv = (row & "\n")*
print(csv.parse("\"a\",1\n\"b,c\",23\n")!)
// prints [["a", 1], ["b,c", 23]]



let sum = Parser<Int>.recursive { sum in
    return (int & "+" & sum).map(+) || int
}
print(sum.parse("1+2+3")!)

