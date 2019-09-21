assert = require 'assert'
ast_gen             = require('../src/ast_gen')
solidity_to_ast4gen = require('../src/solidity_to_ast4gen')
type_inference      = require('../src/type_inference')
translate           = require('../src/translate')

make_test = (text_i, text_o_expected)->
  solidity_ast = ast_gen text_i, silent:true
  ast = solidity_to_ast4gen solidity_ast
  ast = type_inference.gen ast
  text_o_real = translate.gen ast
  text_o_expected = text_o_expected.trim()
  text_o_real     = text_o_real.trim()
  assert.strictEqual text_o_expected, text_o_real


describe 'translate section', ()->
  it 'empty', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Summator {
      uint public value;
      
      function test() public {
        value = 1;
      }
    }
    """
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Summator START
    let value:u32;
    export function Summator__test():void {
      value = 1;
    };
    // Smart Contract Summator END
    ;
    """#"
    make_test text_i, text_o
  
  it 'if', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Ifer {
      uint public value;
      
      function ifer() public returns (uint yourMom) {
        uint x = 5;
        uint ret = 0;
        if (x == 5) {
          ret = value + x;
        }
        else  {
          ret = 0;
        }
        return ret;
      }
    }
    """
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Ifer START
    let value:u32;
    export function Ifer__ifer():u32 {
      let x:u32 = 5;
      let ret:u32 = 0;
      if ((x == 5)) {
        ret = (value + x);
      } else {
        ret = 0;
      };
      return ret;
    };
    // Smart Contract Ifer END
    ;
    """
    make_test text_i, text_o
  
  it 'require', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Forer {
      uint public value;
      
      function forer() public returns (uint yourMom) {
        uint y = 0;
        require(y == 0, "wtf");
        return y;
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Forer START
    let value:u32;
    export function Forer__forer():u32 {
      let y:u32 = 0;
      assert(!(y == 0)), "wtf");
      return y;
    };
    // Smart Contract Forer END
    ;
    """#"
    make_test text_i, text_o
  
  it 'require no msg', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Forer {
      uint public value;
      
      function forer() public returns (uint yourMom) {
        uint y = 0;
        require(y == 0);
        return y;
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Forer START
    let value:u32;
    export function Forer__forer():u32 {
      let y:u32 = 0;
      assert(!(y == 0)));
      return y;
    };
    // Smart Contract Forer END
    ;
    """#"
    make_test text_i, text_o
  
  it 'bool ops', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Forer {
      uint public value;
      
      function forer() public returns (bool yourMom) {
        bool a;
        bool b;
        bool c;
        c = !c;
        c = a && b;
        c = a || b;
        return c;
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Forer START
    let value:u32;
    export function Forer__forer():boolean {
      let a:boolean;
      let b:boolean;
      let c:boolean;
      c = !(c);
      c = (a and b);
      c = (a or b);
      return c;
    };
    // Smart Contract Forer END
    ;
    """#"
    make_test text_i, text_o
  
  it 'uint ops', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Forer {
      uint public value;
      
      function forer() public returns (uint yourMom) {
        uint a = 0;
        uint b = 0;
        uint c = 0;
        c = a + b;
        c = a - b;
        c = a * b;
        c = a / b;
        c = a % b;
        c = a & b;
        c = a | b;
        c = a ^ b;
        c = a;
        c += a;
        c -= a;
        c *= a;
        c /= a;
        return c;
      }
    }
    """#"
    text_o = """
      import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
      // Smart Contract Forer START
      let value:u32;
      export function Forer__forer():u32 {
        let a:u32 = 0;
        let b:u32 = 0;
        let c:u32 = 0;
        c = (a + b);
        c = (a - b);
        c = (a * b);
        c = (a / b);
        c = (a % b);
        c = (a & b);
        c = (a | b);
        c = (a ^ b);
        c = a;
        c += a;
        c -= a;
        c *= a;
        c /= a;
        return c;
      };
      // Smart Contract Forer END
      ;
    """#"
    make_test text_i, text_o
  
  it 'int ops', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      int public value;
      
      function forer() public returns (int yourMom) {
        int a = 1;
        int b = 1;
        int c = 1;
        bool bb;
        c = -c;
        c = ~c;
        c = a + b;
        c = a - b;
        c = a * b;
        c = a / b;
        c = a % b;
        c = a & b;
        c = a | b;
        c = a ^ b;
        bb = a == b;
        bb = a != b;
        bb = a <  b;
        bb = a <= b;
        bb = a >  b;
        bb = a >= b;
        return c;
      }
    }
    """#"
    text_o = """
      import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
      // Smart Contract Forer START
      let value:i32;
      export function Forer__forer():i32 {
        let a:i32 = 1;
        let b:i32 = 1;
        let c:i32 = 1;
        let bb:boolean;
        c = -(c);
        c = ~(c);
        c = (a + b);
        c = (a - b);
        c = (a * b);
        c = (a / b);
        c = (a % b);
        c = (a & b);
        c = (a | b);
        c = (a ^ b);
        bb = (a == b);
        bb = (a != b);
        bb = (a < b);
        bb = (a <= b);
        bb = (a > b);
        bb = (a >= b);
        return c;
      };
      // Smart Contract Forer END
      ;
    """#"
    make_test text_i, text_o
  
  # it 'a[b]', ()->
  #   text_i = """
  #   pragma solidity ^0.5.11;
  # 
  #   contract Forer {
  #     mapping (address => uint) balances;
  #     
  #     function forer(address owner) public returns (uint yourMom) {
  #       return balances[owner];
  #     }
  #   }
  #   """#"
  #   text_o = """
  #   type state is record
  #     balances: map(address, nat);
  #   end;
  #   
  #   function forer (const owner : address; const contractStorage : state) : (nat * state) is
  #     block {
  #       skip
  #     } with ((case contractStorage.balances[owner] of | None -> 0n | Some(x) -> x end), contractStorage);
  #   
  #   function main (const dummy_int : int; const contractStorage : state) : (state) is
  #     block {
  #       skip
  #     } with (contractStorage);
  #   """
  #   make_test text_i, text_o
  # 
  it 'maps', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        balances[owner] += 1;
        return balances[owner];
      }
    }
    """#"
    text_o = """
      import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
      // Smart Contract Forer START
      let balances:new PersistentMap<address,i32>;
      export function Forer__forer(owner:address):i32 {
        balances[owner] += 1;
        return balances[owner];
      };
      // Smart Contract Forer END
      ;
    """#"
    make_test text_i, text_o
  # 
  # it 'while', ()->
  #   text_i = """
  #   pragma solidity ^0.5.11;
  # 
  #   contract Forer {
  #     mapping (address => int) balances;
  #     
  #     function forer(address owner) public returns (int yourMom) {
  #       int i = 0;
  #       while(i < 5) {
  #         i += 1;
  #       }
  #       return i;
  #     }
  #   }
  #   """#"
  #   text_o = """
  #   type state is record
  #     balances: map(address, int);
  #   end;
  #   
  #   function forer (const owner : address; const contractStorage : state) : (int * state) is
  #     block {
  #       const i : int = 0;
  #       while (i < 5) block {
  #         i := (i + 1);
  #       };
  #     } with (i, contractStorage);
  #   
  #   function main (const dummy_int : int; const contractStorage : state) : (state) is
  #     block {
  #       skip
  #     } with (contractStorage);
  #   """
  #   make_test text_i, text_o
  # 
  # it 'for', ()->
  #   text_i = """
  #   pragma solidity ^0.5.11;
  # 
  #   contract Forer {
  #     mapping (address => int) balances;
  #     
  #     function forer(address owner) public returns (int yourMom) {
  #       int i = 0;
  #       for(i=2;i < 5;i+=10) {
  #         i += 1;
  #       }
  #       return i;
  #     }
  #   }
  #   """#"
  #   text_o = """
  #   type state is record
  #     balances: map(address, int);
  #   end;
  #   
  #   function forer (const owner : address; const contractStorage : state) : (int * state) is
  #     block {
  #       const i : int = 0;
  #       i := 2;
  #       while (i < 5) block {
  #         i := (i + 1);
  #         i := (i + 10);
  #       };
  #     } with (i, contractStorage);
  #   
  #   function main (const dummy_int : int; const contractStorage : state) : (state) is
  #     block {
  #       skip
  #     } with (contractStorage);
  #   """
  #   make_test text_i, text_o
  # 
  # it 'fn call', ()->
  #   text_i = """
  #   pragma solidity ^0.5.11;
  # 
  #   contract Forer {
  #     function call_me(int a) public returns (int yourMom) {
  #       return a;
  #     }
  #     function forer(int a) public returns (int yourMom) {
  #       return call_me(a);
  #     }
  #   }
  #   """#"
  #   text_o = """
  #   type state is record
  #     
  #   end;
  #   
  #   function call_me (const a : int; const contractStorage : state) : (int * state) is
  #     block {
  #       skip
  #     } with (a, contractStorage);
  #   
  #   function forer (const a : int; const contractStorage : state) : (int * state) is
  #     block {
  #       const tmp_0 : (int * state) = call_me(a, contractStorage);
  #     } with (tmp_0, contractStorage);
  #   
  #   function main (const dummy_int : int; const contractStorage : state) : (state) is
  #     block {
  #       skip
  #     } with (contractStorage);
  #   """
  #   make_test text_i, text_o
  
