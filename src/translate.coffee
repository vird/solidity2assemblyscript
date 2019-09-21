require 'fy/codegen'
module = @

translate_type = (type)->
  switch type.main
    when 't_bool'
      'boolean'
    when 't_uint256'
      'u32'
    when 't_int256'
      'i32'
    when 't_address'
      'address'
    when 'map'
      "new PersistentMap<#{translate_type type.nest_list[0]},#{translate_type type.nest_list[1]}>" 
    else
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
  # NOT VFERIFIED
  PLUS    : (a)->"+(#{a})"

class @Gen_context
  class_name: null
  var_hash : {}
  fn_hash  : {}
  constructor : ()->
    @var_hash = {}
  
  mk_nest : ()->
    t = new module.Gen_context
    t

@gen = (ast, opt = {})->
  ctx = new module.Gen_context
  ret = module._gen ast, opt, ctx
  
  """
  import { context, storage, logging, collections, PersistentMap } from "near-runtime-ts";
  import { context, storage, near, collections } from "./near";

  #{ret}
  """#"


@_gen = gen = (ast, opt, ctx)->
  switch ast.constructor.name
    # ###################################################################################################
    #    expr
    # ###################################################################################################
    when "Var"
      {name} = ast
      name
    
    when "Const"
      switch ast.type.main
        when 'string'
          JSON.stringify ast.val
        else
          ast.val
    
    when 'Bin_op'
      _a = gen ast.a, opt, ctx
      _b = gen ast.b, opt, ctx
      if op = module.bin_op_name_map[ast.op]
        "(#{_a} #{op} #{_b})"
      else if cb = module.bin_op_name_cb_map[ast.op]
        cb(_a, _b, ctx, ast)
      else
        throw new Error "Unknown/unimplemented bin_op #{ast.op}"
    
    when "Un_op"
      if cb = module.un_op_name_cb_map[ast.op]
        cb gen(ast.a, opt, ctx), ctx
      else
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
      if fn == "require"
        aux_failtext = arg_list[1] or ""
        aux_failtext = ", #{aux_failtext}" if aux_failtext
        return """
          assert(!#{arg_list[0]})#{aux_failtext})
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
    
    when "Class_decl"
      ctx = ctx.mk_nest()
      ctx.class_name = ast.name
      
      body = gen ast.scope, opt, ctx
      jl = []
      for k,v of ctx.var_hash
        jl.push "#{k} : #{translate_type v.type}"
      for k,v of ctx.fn_hash
        jl.push "#{k} : #{translate_type v.type}"

      if ast.is_struct
        """
        export class #{ast.name} {
          #{make_tab body, "  "}
        }
        """
      else
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
        ctx.var_hash[v] = {
          _is_arg : true
          type : type = ast.type_i.nest_list[idx]
        }
        arg_jl.push "#{v}:#{translate_type type}"
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