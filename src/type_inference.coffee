Type = require 'type'
module = @

# Прим. Это система типов eth
# каждый язык, который хочет транслироваться должен сам решать как он будет преобразовывать эти типы в свои
@default_var_hash_gen = ()->
  {
    msg : (()->
      ret = new Type "struct"
      ret.field_hash['sender'] = new Type "address"
      ret.field_hash['value'] = new Type "uint"
      ret
    )()
    block : (()->
      ret = new Type "struct"
      ret.field_hash['number'] = new Type "uint"
      ret
    )()
    require : (()->
      ret = new Type "function2"
      ret.nest_list.push type_i = new Type "function"
      ret.nest_list.push type_o = new Type "function"
      type_i.nest_list.push "bool"
      type_i.nest_list.push "option<string>"
      ret
    )()
    now : new Type "uint"
  }

@default_type_hash_gen = ()->
  {
    
  }

@bin_op_ret_type_hash_list= {}
@un_op_ret_type_hash_list = {
  BOOL_NOT : [
    ['bool', 'bool']
  ]
}
# ###################################################################################################
#    type table
# ###################################################################################################
for v in "ADD SUB MUL DIV MOD POW BIT_AND BIT_OR BIT_XOR".split /\s+/g
  @bin_op_ret_type_hash_list[v] = [
    ['uint', 'uint', 'uint']
    ['int',  'int',  'int']
  ]
  @bin_op_ret_type_hash_list["ASS_#{v}"] = [
    ['uint', 'uint', 'uint']
    ['int',  'int',  'int']
  ]
for v in "EQ NE GT LT GTE LTE".split /\s+/g
  @bin_op_ret_type_hash_list[v] = [
    ['uint', 'uint', 'bool']
    ['int',  'int',  'bool']
  ]
for v in "BOOL_AND BOOL_OR".split /\s+/g
  @bin_op_ret_type_hash_list[v] = [
    ['bool', 'bool', 'bool']
  ]
for v in "MINUS BIT_NOT PRE_INCR POST_INCR PRE_DECR POST_DECR".split /\s+/g
  @un_op_ret_type_hash_list[v] = [
    ['int', 'int']
    ['uint', 'uint']
  ]
# ###################################################################################################

class Ti_context
  parent    : null
  var_hash  : {}
  type_hash : {}
  
  constructor:()->
    @var_hash = module.default_var_hash_gen()
    @type_hash= module.default_type_hash_gen()
  
  mk_nest : ()->
    ret = new Ti_context
    ret.parent = @
    ret
  
  check_id : (id)->
    return ret if ret = @var_hash[id]
    # TODO need replace to this
    if type = @type_hash[id]
      return {
        type
      }
    
    if @parent
      return @parent.check_id id
    throw new Error "can't find decl for id '#{id}'"
  
  check_type : (_type)->
    return ret if ret = @type_hash[_type]
    if @parent
      return @parent.check_type _type
    throw new Error "can't find type '#{_type}'"

class_prepare = (ctx, t)->
  ctx.type_hash[t.name] = t
  for v in t.scope.list
    switch v.constructor.name
      when "Var_decl"
        t._prepared_field2type[v.name] = v.type
      when "Fn_decl"
        # BUG внутри scope уже есть this и ему нужен тип...
        t._prepared_field2type[v.name] = v.type
  return

is_not_a_type = (type)->
  !type or type.main == 'number'

# ###################################################################################################

@gen = (ast_tree, opt)->
  # phase 1 bottom-to-top walk + type reference
  walk = (t, ctx)->
    switch t.constructor.name
      # ###################################################################################################
      #    expr
      # ###################################################################################################
      when "Var"
        t.type = ctx.check_id t.name
      
      when "Const"
        t.type
      
      when "Bin_op"
        list = module.bin_op_ret_type_hash_list[t.op]
        a = (walk(t.a, ctx) or '').toString()
        b = (walk(t.b, ctx) or '').toString()
        
        found = false
        if list
          for tuple in list
            continue if tuple[0] != a
            continue if tuple[1] != b
            found = true
            t.type = new Type tuple[2]
        
        # extra cases
        if !found
          # may produce invalid result
          if t.op == 'ASSIGN'
            t.type = t.a.type
            found = true
          else if t.op in ['EQ', 'NE']
            t.type = new Type 'bool'
            found = true
          else if t.op == 'INDEX_ACCESS'
            if t.b.type.main == 'number'
              t.b.type.main = 'uint'
            switch t.a.type.main
              when 'string'
                t.type = new Type 'string'
                found = true
              when 'map'
                key = t.a.type.nest_list[0]
                if !key.cmp t.b.type
                  throw new Error("bad index access to '#{t.a.type}' with index '#{t.b.type}'")
                t.type = t.a.type.nest_list[1]
                found = true
              when 'array'
                t.type = t.a.type.nest_list[0]
                found = true
        # if !found
          # throw new Error "unknown bin_op=#{t.op} a=#{a} b=#{b}"
        t.type
      
      when "Un_op"
        if t.op == 'NEW'
          t.type = t.a_type
          return t.type
        list = module.un_op_ret_type_hash_list[t.op]
        a = walk(t.a, ctx).toString()
        found = false
        if list
          for tuple in list
            continue if tuple[0] != a
            found = true
            t.type = new Type tuple[1]
        if t.op == 'BRACKET'
          found = true
          t.type = t.a.type
        if !found
          throw new Error "unknown un_op=#{t.op} a=#{a}"
        t.type
      
      when "Field_access"
        root_type = walk(t.t, ctx)
        
        if root_type.main == 'struct'
          field_hash = root_type.field_hash
        else
          class_decl = ctx.check_type root_type.main
          field_hash = class_decl._prepared_field2type
        
        if !field_type = field_hash[t.name]
          throw new Error "unknown field. '#{t.name}' at type '#{root_type}'. Allowed fields [#{Object.keys(field_hash).join ', '}]"
        
        # Я не понял зачем это
        # field_type = ast.type_actualize field_type, t.t.type
        t.type = field_type
        t.type
      
      when "Fn_call"
        # NOTE missing arg check
        root_type = walk t.fn, ctx
        for arg in t.arg_list
          walk arg, ctx
        if root_type?.nest_list?[0]?.nest_list?[0]?
          t.type = root_type.nest_list[0].nest_list[0]
        else
          # constructor case
          root_type
      
      # ###################################################################################################
      #    stmt
      # ###################################################################################################
      when "Var_decl"
        if t.assign_value
          walk t.assign_value, ctx
        ctx.var_hash[t.name] = t.type
        null
      
      when "Scope"
        ctx_nest = ctx.mk_nest()
        for v in t.list
          if v.constructor.name == "Class_decl"
            class_prepare ctx, v
        for v in t.list
          walk v, ctx_nest
        
        null
      
      when "Ret_multi"
        for v in t.t_list
          walk v, ctx
        null
      
      when "Class_decl"
        class_prepare ctx, t
        
        ctx_nest = ctx.mk_nest()
        # ctx_nest.var_hash["this"] = new Type t.name
        walk t.scope, ctx_nest
        t.type
      
      when "Fn_decl_multiret"
        complex_type = new Type 'function2'
        complex_type.nest_list.push t.type_i
        complex_type.nest_list.push t.type_o
        ctx.var_hash[t.name] = complex_type
        ctx_nest = ctx.mk_nest()
        for name,k in t.arg_name_list
          type = t.type_i.nest_list[k]
          ctx_nest.var_hash[name] = type
        walk t.scope, ctx_nest
        t.type
      # ###################################################################################################
      #    control flow
      # ###################################################################################################
      when "If"
        walk(t.cond, ctx)
        walk(t.t, ctx.mk_nest())
        walk(t.f, ctx.mk_nest())
        null
      
      when "While"
        walk t.cond, ctx.mk_nest()
        walk t.scope, ctx.mk_nest()
        null
      
      when "For_3pos"
        ctx = ctx.mk_nest()
        walk t.init, ctx if t.init
        walk t.cond, ctx
        walk t.incr, ctx if t.incr
        walk t.scope, ctx
        null
      
      when "Continue"
        null
      
      when "Break"
        null
      
      else
        ### !pragma coverage-skip-block ###
        p t
        throw new Error "ti phase 1 unknown node '#{t.constructor.name}'"
  walk ast_tree, new Ti_context
  
  # phase 2
  # iterable
  
  change_count = 0
  walk = (t, ctx)->
    switch t.constructor.name
      # ###################################################################################################
      #    expr
      # ###################################################################################################
      when "Var"
        t.type = ctx.check_id t.name
      
      when "Const"
        t.type
      
      when "Bin_op"
        bruteforce_a = is_not_a_type t.a.type
        bruteforce_b = is_not_a_type t.b.type
          
        list = module.bin_op_ret_type_hash_list[t.op]
        can_bruteforce = t.type?
        can_bruteforce and= bruteforce_a or bruteforce_b
        can_bruteforce and= list?
        
        if t.op == 'ASSIGN'
          if bruteforce_a and !bruteforce_b
            change_count++
            t.a.type = t.b.type
          else if !bruteforce_a and bruteforce_b
            change_count++
            t.b.type = t.a.type
        else
          if !list? and !t.type
            perr "can't type inference bin_op=  '#{t.op}' a=#{t.a.type} b=#{t.b.type}"
        
        if can_bruteforce
          a_type_list = if bruteforce_a then [] else [t.a.type.toString()]
          b_type_list = if bruteforce_b then [] else [t.b.type.toString()]
          
          refined_list = []
          cmp_ret_type = t.type.toString()
          for v in list
            continue if cmp_ret_type != v[2]
            a_type_list.push v[0] if bruteforce_a
            b_type_list.push v[1] if bruteforce_b
            refined_list.push v
          
          candidate_list = []
          for a_type in a_type_list
            for b_type in b_type_list
              for pair in refined_list
                [cmp_a_type, cmp_b_type] = pair
                continue if a_type != cmp_a_type
                continue if b_type != cmp_b_type
                candidate_list.push pair
          if candidate_list.length == 1
            change_count++
            [a_type, b_type] = candidate_list[0]
            t.a.type = new Type a_type
            t.b.type = new Type b_type
          else
            p "candidate_list=#{candidate_list.length}"
        
        walk(t.a, ctx)
        walk(t.b, ctx)
        t.type
      
      when "Un_op"
        if t.op == 'NEW'
          t.type = t.a_type
          return t.type
        # TODO bruteforce
        walk(t.a, ctx)
        t.type
      
      when "Field_access"
        root_type = walk(t.t, ctx)
        
        if root_type.main == 'struct'
          field_hash = root_type.field_hash
        else
          class_decl = ctx.check_type root_type.main
          field_hash = class_decl._prepared_field2type
        
        if !field_type = field_hash[t.name]
          throw new Error "unknown field. '#{t.name}' at type '#{root_type}'. Allowed fields [#{Object.keys(field_hash).join ', '}]"
        
        # Я не понял зачем это
        # field_type = ast.type_actualize field_type, t.t.type
        t.type = field_type
        t.type
      
      when "Fn_call"
        root_type = walk t.fn, ctx
        for arg,i in t.arg_list
          walk arg, ctx
        if root_type?.nest_list?[0]?.nest_list?[0]?
          for arg,i in t.arg_list
            expected_type = t.fn.type.nest_list[0].nest_list[i]
            if is_not_a_type arg.type
              change_count++
              arg.type = expected_type
          t.type = root_type.nest_list[0].nest_list[0]
        else
          # constructor case
          root_type
      
      # ###################################################################################################
      #    stmt
      # ###################################################################################################
      when "Var_decl"
        if t.assign_value
          if is_not_a_type t.assign_value.type
            change_count++
            t.assign_value.type = t.type
          walk t.assign_value, ctx
        ctx.var_hash[t.name] = t.type
        null
      
      when "Scope"
        ctx_nest = ctx.mk_nest()
        for v in t.list
          walk v, ctx_nest
        
        null
      
      when "Ret_multi"
        # TODO match return type
        for v in t.t_list
          walk v, ctx
        null
      
      when "Class_decl"
        class_prepare ctx, t
        
        ctx_nest = ctx.mk_nest()
        # ctx_nest.var_hash["this"] = new Type t.name
        walk t.scope, ctx_nest
        t.type
      
      when "Fn_decl_multiret"
        complex_type = new Type 'function2'
        complex_type.nest_list.push t.type_i
        complex_type.nest_list.push t.type_o
        ctx.var_hash[t.name] = complex_type
        ctx_nest = ctx.mk_nest()
        for name,k in t.arg_name_list
          type = t.type_i.nest_list[k]
          ctx_nest.var_hash[name] = type
        walk t.scope, ctx_nest
        t.type
      # ###################################################################################################
      #    control flow
      # ###################################################################################################
      when "If"
        walk(t.cond, ctx)
        walk(t.t, ctx.mk_nest())
        walk(t.f, ctx.mk_nest())
        null
      
      when "While"
        walk t.cond, ctx.mk_nest()
        walk t.scope, ctx.mk_nest()
        null
      
      when "For_3pos"
        ctx = ctx.mk_nest()
        walk t.init, ctx if t.init
        walk t.cond, ctx
        walk t.incr, ctx if t.incr
        walk t.scope, ctx
        null
      
      when "Continue"
        null
      
      when "Break"
        null
      
      else
        ### !pragma coverage-skip-block ###
        p t
        throw new Error "ti phase 2 unknown node '#{t.constructor.name}'"
      
  
  for i in [0 ... 100] # prevent infinite
    walk ast_tree, new Ti_context
    # p "phase 2 ti change_count=#{change_count}" # DEBUG
    break if change_count == 0
    change_count = 0
  
  ast_tree