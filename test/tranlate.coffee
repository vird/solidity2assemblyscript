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
      assert((y == 0)), "wtf");
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
      assert((y == 0)));
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
        c++;
        ++c;
        c--;
        --c;
        c = a;
        c = ~a;
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
        c++;
        ++c;
        c--;
        --c;
        c = a;
        c = ~(a);
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
        c++;
        ++c;
        c--;
        --c;
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
        c++;
        ++c;
        c--;
        --c;
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
  
  it 'a[b]', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      mapping (address => uint) balances;
      
      function forer(address owner) public returns (uint yourMom) {
        return balances[owner];
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Forer START
    let balances:PersistentMap<string,u32>;
    export function Forer__forer(owner:string):u32 {
      return balances[owner];
    };
    // Smart Contract Forer END
    ;
    """#"
    make_test text_i, text_o
  
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
      let balances:PersistentMap<string,i32>;
      export function Forer__forer(owner:string):i32 {
        balances[owner] += 1;
        return balances[owner];
      };
      // Smart Contract Forer END
      ;
    """#"
    make_test text_i, text_o
  
  it 'while', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        int i = 0;
        while(i < 5) {
          i += 1;
        }
        return i;
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Forer START
    let balances:PersistentMap<string,i32>;
    export function Forer__forer(owner:string):i32 {
      let i:i32 = 0;
      while ((i < 5)) {
        i += 1;
      } ;
      return i;
    };
    // Smart Contract Forer END
    ;
    """#"
    make_test text_i, text_o
  
  it 'for', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        int i = 0;
        for(i=2;i < 5;i++) {
          i += 1;
        }
        return i;
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Forer START
    let balances:PersistentMap<string,i32>;
    export function Forer__forer(owner:string):i32 {
      let i:i32 = 0;
      for(i = 2;(i < 5);i++) {
        i += 1;
      };
      return i;
    };
    // Smart Contract Forer END
    ;
    """#"
    make_test text_i, text_o
  
  it 'for no init and incr', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        int i = 0;
        for(;i < 5;) {
          i += 1;
          break;
        }
        return i;
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Forer START
    let balances:PersistentMap<string,i32>;
    export function Forer__forer(owner:string):i32 {
      let i:i32 = 0;
      for(;(i < 5);) {
        i += 1;
        break;
      };
      return i;
    };
    // Smart Contract Forer END
    ;
    """#"
    make_test text_i, text_o
  
  it 'continue break', ()->
    text_i = """
    pragma solidity ^0.5.11;
  
    contract Forer {
      mapping (address => int) balances;
      
      function forer(address owner) public returns (int yourMom) {
        int i = 0;
        for(i=2;i < 5;i++) {
          i += 1;
          continue;
          break;
        }
        return i;
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Forer START
    let balances:PersistentMap<string,i32>;
    export function Forer__forer(owner:string):i32 {
      let i:i32 = 0;
      for(i = 2;(i < 5);i++) {
        i += 1;
        continue;
        break;
      };
      return i;
    };
    // Smart Contract Forer END
    ;
    """#"
    make_test text_i, text_o
  
  it 'fn call', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Forer {
      function call_me(int a) public returns (int yourMom) {
        return a;
      }
      function forer(int a) public returns (int yourMom) {
        return call_me(a);
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Forer START
    export function Forer__call_me(a:i32):i32 {
      return a;
    };
    export function Forer__forer(a:i32):i32 {
      return call_me(a);
    };
    // Smart Contract Forer END
    ;
    """#"
    make_test text_i, text_o
  
  it 'struct', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Struct {
      uint public value;
      
        struct User {
            uint experience;
            uint level;
            uint dividends;
        }
      
      function ifer() public {
        User memory u = User(1, 2, 3);
        u.level = 20;
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Struct START
    let value:u32;
    export class User {
      let experience:u32;
      let level:u32;
      let dividends:u32;
    }
    ;
    export function Struct__ifer():void {
      let u:User = User(1, 2, 3);
      u.level = 20;
    };
    // Smart Contract Struct END
    ;
    """#"
    make_test text_i, text_o
  
  it 'struct in struct', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Struct {
      uint public value;
      
        struct Sub {
            uint experience;
        }
        struct User {
            Sub experience;
        }
      
      function ifer() public {
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Struct START
    let value:u32;
    export class Sub {
      let experience:u32;
    }
    ;
    export class User {
      let experience:Sub;
    }
    ;
    export function Struct__ifer():void {
      
    };
    // Smart Contract Struct END
    ;
    """#"
    make_test text_i, text_o
  
  it 'bracket tuple', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Mapper {
      function ifer() public payable {
        int a = 1;
        int b = 1;
        int c = (a+b)*b;
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Mapper START
    export function Mapper__ifer():void {
      let a:i32 = 1;
      let b:i32 = 1;
      let c:i32 = (((a + b)) * b);
    };
    // Smart Contract Mapper END
    ;
    """#"
    make_test text_i, text_o
  
  it 'typed arrays', ()->
    text_i = """
    pragma solidity ^0.5.11;

    contract Array {
        function f(uint len) public {
            uint[] memory a = new uint[](7);
            int[] memory b = new int[](1000);
            bytes memory c = new bytes(len);
            bool[] memory d = new bool[](len);
            address[] memory e = new address[](len);
            address[10] memory f;
            // address[10] memory g = new address[10];
            a[6] = 8;
        }
    }

    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Array START
    export function Array__f(len:u32):void {
      let a:UInt32Array = new UInt32Array(7);
      let b:Int32Array = new Int32Array(1000);
      let c:Uint8Array = new Uint8Array(len);
      let d:bool[] = new bool[](len);
      let e:address[] = new address[](len);
      let f:address[];
      a[6] = 8;
    };
    // Smart Contract Array END
    ;
    """#"
    make_test text_i, text_o
  
  it 'struct array', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Array {
        
        struct User {
            uint experience;
            uint level;
            uint dividends;
        }
        function f(uint len) public {
            User[] memory a = new User[](7);
        }
    }

    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Array START
    export class User {
      let experience:u32;
      let level:u32;
      let dividends:u32;
    }
    ;
    export function Array__f(len:u32):void {
      let a:User[] = new User[](7);
    };
    // Smart Contract Array END
    ;
    """#"
    make_test text_i, text_o
  
  it 'globals', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Globals {
      uint public value;
      
      function ifer() public payable returns (uint) {
        uint x = block.number;
        address y = msg.sender;
        uint z = msg.value;

        return x;
      }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Globals START
    let value:u32;
    export function Globals__ifer():u32 {
      let x:u32 = context.blockIndex();
      let y:string = context.sender();
      let z:u32 = context.attachedDeposit();
      return x;
    };
    // Smart Contract Globals END
    ;
    """#"
    make_test text_i, text_o
  
  it 'decl assign', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Array {
        uint a = 1;
        function f(uint len) public {
          uint b = 1;
        }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Array START
    let a:u32 = 1;
    export function Array__f(len:u32):void {
      let b:u32 = 1;
    };
    // Smart Contract Array END
    ;
    """#"
    make_test text_i, text_o
  
  it 'private method', ()->
    text_i = """
    pragma solidity ^0.5.11;
    
    contract Array {
        uint a = 1;
        function f(uint len) private {
          uint b = 1;
        }
    }
    """#"
    text_o = """
    import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
    // Smart Contract Array START
    let a:u32 = 1;
    function Array__f(len:u32):void {
      let b:u32 = 1;
    };
    // Smart Contract Array END
    ;
    """#"
    make_test text_i, text_o
  
