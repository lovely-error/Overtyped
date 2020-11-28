# Overtyped

We all love types, right? They allow us to capture errors early on and make our lifes more available to the rest of th great stuff out there.
Indeed types are neat, and the types we all probably familiar with are the part of the Hindley-Milner type system of simply typed lambda calculus with polymorphisms, but while they definetly provide help, they are not what type systems and mathematical constructivism can offer. Namely, swift's property wrapper allow us to write the programm with more rigorous requirements and thus help us capture more bugs in our code. This library relies on these constructs:

1. Hoare functions - named after Tony Hoare, these functions allow you to specify preconditions - what your code should be before it gets into function - and postconditions - what your code should be after it gets out of the function. These cheks ensure that invariants are handled properly at type level.
```
import Typee

@Function var viewTransformer =  { (view: View) -> () in
    view = HorizontalView().append(subview: view)
}
let argument = (view: Image(named: "dog.png"))
$viewTransformer.addPostcondition {$0.size.width == argument.size.width}
viewTransformer(argument)
```

2. Linear types - gracefully stolen from linear logic and adopted for formal verification, they ensure the exact path of the transition for your types to be taken. For example, a record that describes user can be specified to be mutated only after the name was assigned.
```
//if linear types were present in swift as a part of the type system,
//they could be declared as such
var somePrettyProperty: (Int -> String) = 123
someProperty = "\(someProperty)"
```
One particular usage is type transition enforcement.
```
protocol StatefulType { associatedtype State: Equatable; var currentState: State { get } }
struct File: StatefullType { enum S: Equatable {case closed, opened}; var currentState: S }
@Linear([{$0.currentState == .opened},{$0.currentState == .closed}]) 
var fileToBeOpenedAndClosed: File = File.openForModification(fileAtPath: "...")
fileToBeOpenedAndClosed.modifyContent { ... }
//and after this point file must be closed
```

3. Refined types - they are essentially type predicates, and ensure that value of a type meet requirements. For example, a name field in user record may be set to start with capital letter, and be longer than certain amount of character or not contain nonallphabetic symbols.
```
@Constrained(by: {$0 > 0 && $0 < 150}) var age: Int = 19
age = 1_000_000 //fatal error. People dont live that long yet.
```

4. Uniqueness types - you can use them only once, yeap that is all to them.
```
@Unique var rareMaterial: Antimatter = ...
use(rareMaterial) //ok
useOnceMore(rareMaterial) //opps! its gone...
```

5. Stateful types - which are represented by a state machine. Transitions are described as a directed graph and only mutations are conidered to trigger transitions.
```
@Stateful(configuration: {
    let emptyString = State(
        name: "empty string",
        predicate: { ($0 as? String)?.isEmpty ?? false })
    let nonEmptyString = State(
        name: "non empty string",
        predicate: { !(($0 as? String)?.isEmpty ?? true)})
        
    emptyString =>> nonEmptyString =>> emptyString
    
    return TransitionGraph(initialState: emptyString)
}())
var emptyHalfOfTheTime = ""
emptyHalfOfTheTime = "!"
emptyHalfOfTheTime = ""
emptyHalfOfTheTime = "!"
emptyHalfOfTheTime = "Screw it.." //obvious error
```

6. Modal types - they are the thing to allow you to listen to conditions and perform checks
```
struct Jopa {
   @Modal var name: String = "Jopa"
   init() {
      _name.nessecairily(
         after: {$0.count == 0},
         ensure: {$0.count > 0 ? .allOk : .violation},
         description: {_ in """
         After string become empty, it must later be replaced with another
         nonempty string before performing any other operations
         """},
         discard: .onCondition({$0.hasPrefix("sme")}))
      _name.nessecairily(
         after: {$0.hasPrefix("Lo")},
         ensure: {$0.hasSuffix("ki") ? .allOk : .violation},
         description: { _ in "After name start to have Lo it must always end with ki"})
   }
}
var test = Jopa()
test.name = ""
//test.name = "" //would be an error 
test.name = "smeshariki"
test.name = "" //not an error anymore. Guard is lifted.
```
