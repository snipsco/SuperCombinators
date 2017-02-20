
import SuperCombinators

let digits = Pattern.characters(in: .decimalDigits)
let minus: Pattern = "-"
let int = (minus.optional + digits)
    .stringParser
    .map { Int($0)! }

print(int.parseAll("-123")! + int.parseAll("321")!)
// prints 198




let notQuote = Pattern.characters(
    notIn: CharacterSet(charactersIn: "\"")
)
let string = "\"" + notQuote.stringParser + "\""

print(string.parseAll("\"bla\"")!)
// prints bla




// A cell is a `String` or an `Int`
let cell = string.map { $0 as Any } || int.map { $0 as Any }
// A row is a sequence of cells separated by ","
let row = cell.separated(by: ",")
// A CSV file is a possibly empty sequence of rows with a "\n" at the end
let csv = (row + "\n")*
print(csv.parseAll("\"a\",1\n\"b,c\",23\n")!)
// prints [["a", 1], ["b,c", 23]]



let sum = Parser<Int>.recursive { sum in
    return (int + "+" + sum).map(+) || int
}
print(sum.parseAll("1+2+3")!)

