require 'fy/codegen'
module = @

translate_type_array = (type)->
  nest = type.nest_list[0]
  switch nest.main
    when 'bool', 'address'
      p "WARNING #{nest.main}[] is probably not existing type in assemblyScript"
      "#{nest.main}[]"
    when 'int'
      'Int32Array'
    when 'uint'
      'UInt32Array'
    else
      "#{translate_type nest}[]"

translate_type = (type)->
  if type.is_user_defined
    return type.main
  switch type.main
    when 'bool'
      'boolean'
    when 'uint'
      'u32'
    when 'int'
      'i32'
    when 'address'
      'string'
    when 'map'
      "PersistentMap<#{translate_type type.nest_list[0]},#{translate_type type.nest_list[1]}>"
    when 'array'
      translate_type_array type
    when 'bytes'
      'Uint8Array'
    else
      ### !pragma coverage-skip-block ###
      pp type
      throw new Error("unknown solidity type '#{type}'")
    
    
@bin_op_name_map =
  ADD : '+'
  SUB : '-'
  MUL : '*'
  DIV : '/'
  MOD : '%'
  
  EQ : '=='
  NE : '!='
  GT : '>'
  LT : '<'
  GTE: '>='
  LTE: '<='
  
  
  BIT_AND : '&'
  BIT_OR  : '|'
  BIT_XOR : '^'
  # NOT VFERIFIED
  
  BOOL_AND: 'and'
  BOOL_OR : 'or'

@bin_op_name_cb_map =
  ASSIGN  : (a, b)-> "#{a} = #{b}"
  ASS_ADD : (a, b)-> "#{a} += #{b}"
  ASS_SUB : (a, b)-> "#{a} -= #{b}"
  ASS_MUL : (a, b)-> "#{a} *= #{b}"
  ASS_DIV : (a, b)-> "#{a} /= #{b}"
  
  INDEX_ACCESS : (a, b)->"#{a}[#{b}]"

@un_op_name_cb_map =
  MINUS   : (a)->"-(#{a})"
  BOOL_NOT: (a)->"!(#{a})"
  BIT_NOT : (a)->"~(#{a})"
  BRACKET : (a)->"(#{a})"
  # risk no bracket
  PRE_INCR: (a)->"++#{a}"
  POST_INCR: (a)->"#{a}++"
  PRE_DECR: (a)->"--#{a}"
  POST_DECR: (a)->"#{a}--"
  
  # NOTE unary plus is now disallowed
  # PLUS    : (a)->"+(#{a})"

class @Gen_context
  class_name: null
  lvalue    : false
  is_struct : false
  mk_nest : ()->
    t = new module.Gen_context
    t

@gen = (ast, opt = {})->
  ctx = new module.Gen_context
  ret = module._gen ast, opt, ctx
  
  """
  import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
  #{ret}
  """#"


@_gen = gen = (ast, opt, ctx)->
  switch ast.constructor.name
    # ###################################################################################################
    #    expr
    # ###################################################################################################
    when "Var"
      {name} = ast
      if name == 'this'
        name = 'context.contractName'
      name
    
    when "Const"
      switch ast.type.main
        when 'string'
          JSON.stringify ast.val
        else
          ast.val
    
    when 'Bin_op'
      ctx_lvalue = ctx.mk_nest()
      is_assign = 0 == ast.op.indexOf 'ASS'
      if is_assign
        ctx_lvalue.lvalue = true
      _a = gen ast.a, opt, ctx_lvalue
      _b = gen ast.b, opt, ctx
      if op = module.bin_op_name_map[ast.op]
        "(#{_a} #{op} #{_b})"
      else if cb = module.bin_op_name_cb_map[ast.op]
        cb(_a, _b, ctx, ast)
      else
        ### !pragma coverage-skip-block ###
        throw new Error "Unknown/unimplemented bin_op #{ast.op}"
    
    when "Un_op"
      if ast.op == 'NEW'
        "new #{translate_type ast.a_type}"
      else if cb = module.un_op_name_cb_map[ast.op]
        cb gen(ast.a, opt, ctx), ctx
      else
        ### !pragma coverage-skip-block ###
        throw new Error "Unknown/unimplemented un_op #{ast.op}"
    
    when "Field_access"
      t = gen ast.t, opt, ctx
      ret = "#{t}.#{ast.name}"
      if ret == 'block.number'
        ret = 'context.blockIndex()'
      if ret == 'msg.sender'
        ret = 'context.sender()'
      if ret == 'msg.value'
        ret = 'context.attachedDeposit()'
      ret
    
    when "Fn_call"
      fn = gen ast.fn, opt, ctx
      arg_list = []
      for v in ast.arg_list
        arg_list.push gen v, opt, ctx
      
      # HACK
      if fn == "require" || fn == "assert"
        aux_failtext = arg_list[1] or ""
        aux_failtext = ", #{aux_failtext}" if aux_failtext
        return """
          assert(#{arg_list[0]}#{aux_failtext})
          """
      # HACK
      if fn == "revert"
        return """
          assert(false)
          """
      if fn == "keccak256" || fn == "sha3"
        return """
          "hash(#{arg_list.join ', '})"
          """
      
      "#{fn}(#{arg_list.join ', '})"
    
    # ###################################################################################################
    #    stmt
    # ###################################################################################################
    when "Scope"
      jl = []
      for v in ast.list
        val = gen v, opt, ctx
        val += ';' unless val[val.length-1] == ';'
        jl.push val
      join_list jl, ''
    
    when "Var_decl"
      type = translate_type ast.type
      
      if ctx.is_struct
        pre = "#{ast.name}:#{type}"
      else
        pre = "let #{ast.name}:#{type}"
      
      if ast.assign_value
        val = gen ast.assign_value, opt, ctx
        "#{pre} = #{val}"
      else
        pre
    
    when "Ret_multi"
      if ast.t_list.length > 1
        throw new Error "not implemented ast.t_list.length > 1"
      
      jl = []
      for v in ast.t_list
        jl.push gen v, opt, ctx
      """
      return #{jl.join ', '}
      """
    
    when "If"
      cond = gen ast.cond, opt, ctx
      t    = gen ast.t, opt, ctx
      f    = gen ast.f, opt, ctx
      """
      if (#{cond}) {
        #{make_tab t, '  '}
      } else {
        #{make_tab f, '  '}
      }
      """
    
    when "While"
      cond = gen ast.cond, opt, ctx
      scope  = gen ast.scope, opt, ctx
      """
      while (#{cond}) {
        #{make_tab scope, '  '}
      } 
      """
    
    when "For_3pos"
      init  = if ast.init then gen ast.init, opt, ctx else ""
      cond  = gen ast.cond, opt, ctx
      incr  = if ast.incr then gen ast.incr, opt, ctx else ""
      scope = gen ast.scope, opt, ctx
      """
      for(#{init};#{cond};#{incr}) {
        #{make_tab scope, '  '}
      }
      """
    
    when "Continue"
      "continue"
    
    when "Break"
      "break"
    
    when "Class_decl"
      ctx = ctx.mk_nest()
      ctx.class_name = ast.name
      if ast.is_struct
        ctx.is_struct = true
      body = gen ast.scope, opt, ctx
      if ast.is_struct
        """
        export class #{ast.name} {
          #{make_tab body, "  "}
        }
        
        """
      else
        body = gen ast.scope, opt, ctx
        """
        // Smart Contract #{ast.name} START
        #{body}
        // Smart Contract #{ast.name} END
        
        """
    
    when "Fn_decl_multiret"
      ctx_orig = ctx
      ctx = ctx.mk_nest()
      arg_jl = []
      for v,idx in ast.arg_name_list
        arg_jl.push "#{v}:#{translate_type ast.type_i.nest_list[idx]}"
      body = gen ast.scope, opt, ctx
      prefix = ""
      prefix = "#{ctx_orig.class_name}__" if ctx_orig.class_name?
      
      if ast.type_o.nest_list.length
        o_type = translate_type ast.type_o.nest_list[0]
      else
        o_type = "void"
      
      aux_export = ""
      if ast.visibility == 'public'
        aux_export = "export "
      
      """
      #{aux_export}function #{prefix}#{ast.name}(#{arg_jl.join ', '}):#{o_type} {
        #{make_tab body, '  '}
      }
      """
      
    else
      if opt.next_gen?
        return opt.next_gen ast, opt, ctx
      ### !pragma coverage-skip-block ###
      perr ast
      throw new Error "unknown ast.constructor.name=#{ast.constructor.name}"