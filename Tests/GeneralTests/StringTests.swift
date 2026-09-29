// Copyright © 2026 PrankMind (Andrey Yakushev). All rights reserved.

import ScriptingCoreGeneral
import Testing

struct StringTests {
  @Test func camelCaseToSnakeCase() {
    #expect("SomeCamelCase".prm_camelCaseToSnakeCase() == "some_camel_case")
  }

  @Test func commaSeparatedArguments() {
    #expect("arc,test=v,j:q,--temp".prm_commaSeparatedArguments
            == [ "arc", "test=v", "j:q", "--temp"])
  }

  @Test func minLength() {
    #expect("temp".prm_minLength(0, suffix: "~") == "temp")
    #expect("temp".prm_minLength(4, suffix: "~") == "temp")
    #expect("temp".prm_minLength(5, suffix: "~") == "temp~")
    #expect("temp".prm_minLength(10, suffix: "~") == "temp~~~~~~")
  }

  @Test func wrapped() {
    #expect("temp".prm_wrapped(prefix: "!", suffix: "0") == "!temp0")
    #expect("temp".prm_wrapped(both: "~") == "~temp~")
  }

  @Test func apostrophed() {
    #expect("temp".prm_apostrophed == "'temp'")
    #expect("temp".prm_apostrophed.prm_apostrophed == "''temp''")
    #expect("'".prm_apostrophed == "'''")
  }

  @Test func bracketed() {
    #expect("temp".prm_bracketed == "(temp)")
    #expect("temp".prm_bracketed.prm_bracketed + "foo".prm_bracketed == "((temp))(foo)")

    #expect("temp".prm_squareBracketed == #"[temp]"#)
    #expect("temp".prm_squareBracketed.prm_squareBracketed == #"[[temp]]"#)
  }

  @Test func quoted() {
    #expect("temp".prm_quoted == #""temp""#)
    #expect("temp".prm_quoted.prm_quoted == #"""temp"""#)
  }

  @Test func simpleConversions() {
    #expect(("temp".prm_quoted + "foo".prm_apostrophed.prm_bracketed).prm_squareBracketed == #"["temp"('foo')]"#)
  }
}
