--DROP FUNCTION gendoc.jsdoc_parse(str character varying);

create or replace function jsdoc_parse(str varchar)
  returns jsonb
  language plpgsql
  stable
as $fn$
/**
 * Function parse jsdoc and returns jsonb structure<br />
 * Function remove comment characters from string.
 * 
 * @author cmtdoc parser (https://github.com/grobinx/cmtdoc-parser)
 * @created Sat Jan 25 2025 21:22:31 GMT+0100 (czas środkowoeuropejski standardowy)
 * @version 1.1.9
 * 
 * @param {varchar|text} str string to parse
 * @returns {jsonb}
 * @example
 * select p.proname, jsdoc_parse(p.doc) as doc, p.arguments, p.description
 *   from (select p.proname, substring(pg_get_functiondef(p.oid) from '\/\*\*.*\*\/') as doc, 
 *                coalesce(pg_get_function_arguments(p.oid), '') arguments,
 *                d.description
 *           from pg_proc p
 *                join pg_namespace n on n.oid = p.pronamespace
 *                left join pg_description d on d.classoid = 'pg_proc'::regclass and d.objoid = p.oid and d.objsubid = 0
 *          where n.nspname = :scema_name
 *            and p.prokind in ('p', 'f')) p
 *  where p.doc is not null
 */
begin
  if position('/**' in str) then
    str := string_agg(substring(line from '^\s*\*\s*(.*)'), e'\n')
      from (select unnest(string_to_array(str, e'\n')) line) d
     where trim(line) not in ('/**', '*/');
  end if;
  --
  return jsonb_object_agg(r.figure, r.object)
    from (    -- This is root description
    select 'root' as figure, to_jsonb(r[1]) as object
      from regexp_matches(str, '^([^@]+)') r
    union all
    -- @param|arg|argument [{type}] name|[name=value] [description]
    select 'param' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select r[3] as "type", coalesce(r[7], r[11]) as "name", r[9] as "default", r[13] as "description", string_to_array(trim(r[3]), '|') as "types"
              from regexp_matches(str, '@(param|arg|argument)(\s*{([^{]*)?})?((\s*\[(([^\[\=]+)\s*(\=\s*([^\[]*)?)?)?\])|(\s+([^\s@)<{}]+)))(\s*([^@]*)?)?', 'g') r) r
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @property|prop [{type}] name|[name=value] [description]
    select 'property' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select r[3] as "type", coalesce(r[7], r[11]) as "name", r[9] as "default", r[13] as "description", string_to_array(trim(r[3]), '|') as "types"
              from regexp_matches(str, '@(property|prop)[[:>:]](\s*{([^{]*)?})?((\s*\[(([^\[\=]+)\s*(\=\s*([^\[]*)?)?)?\])|(\s+([^\s@)<{}]+)))(\s*([^@]*)?)?', 'g') r) r
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @async
    select 'async' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(async)[[:>:]]') r
    union all
    -- @generator
    select 'generator' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(generator)[[:>:]]') r
    union all
    -- @global
    select 'global' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(global)[[:>:]]') r
    union all
    -- @hideconstructor
    select 'hideconstructor' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(hideconstructor)[[:>:]]') r
    union all
    -- @ignore
    select 'ignore' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(ignore)[[:>:]]') r
    union all
    -- @inner
    select 'inner' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(inner)[[:>:]]') r
    union all
    -- @instance
    select 'instance' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(instance)[[:>:]]') r
    union all
    -- @override
    select 'override' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(override)[[:>:]]') r
    union all
    -- @public
    select 'public' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(public)[[:>:]]') r
    union all
    -- @readonly
    select 'readonly' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(readonly)[[:>:]]') r
    union all
    -- @static
    select 'static' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(static)[[:>:]]') r
    union all
    -- @abstract|virtual
    select 'abstract' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(abstract|virtual)[[:>:]]') r
    union all
    -- @access package|private|protected|public
    select 'access' as figure, to_jsonb(r[2]) as object
      from regexp_matches(str, '@(access)\s+(package|private|protected|public)[[:>:]]') r
    union all
    -- @alias path [description]
    select 'alias' as figure, row_to_json(r)::jsonb as object
      from (select r[3] as "path", r[5] as "description"
              from regexp_matches(str, '@(alias)(\s+([^\s@)<{}]+))(\s*([^@]*)?)?') r) r
    union all
    -- @augments|extends path [description]
    select 'augments' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select r[3] as "path", r[5] as "description"
              from regexp_matches(str, '@(augments|extends)(\s+([^\s@)<{}]+))(\s*([^@]*)?)?', 'g') r) r
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @author author [<email@address>] [(http-page)] [- description]
    select 'author' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select r[3] as "author", r[5] as "email", r[7] as "page", r[10] as "description"
              from regexp_matches(str, '@(author)(\s+([^@\-<{\(]+))(\s*<([^<]*)>)?(\s*\(([^\(]*)\))?(\s*\-(\s*([^@]*)?)?)?', 'g') r) r
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @borrows thas_namepath as this_namepath [description]
    select 'borrows' as figure, row_to_json(r)::jsonb as object
      from (select r[3] as "that", r[5] as "this", r[7] as "description"
              from regexp_matches(str, '@(borrows)(\s+([^\s@)<{}]+))\s*as\s*(\s+([^\s@)<{}]+))(\s*([^@]*)?)?') r) r
    union all
    -- @class|constructor [{type}] name
    select 'class' as figure, row_to_json(r)::jsonb as object
      from (select r[3] as "type", r[5] as "name"
              from regexp_matches(str, '@(constructor|class)(\s*{([^{]*)?})?(\s+([^\s@)<{}]+))') r) r
    union all
    -- @class|constructor
    select 'class' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(constructor|class)[[:>:]]') r
    union all
    -- @constatnt|const {type} [name]
    select 'constant' as figure, row_to_json(r)::jsonb as object
      from (select r[3] as "type", r[5] as "name"
              from regexp_matches(str, '@(constant|const)(\s*{([^{]*)?})(\s+([^\s@)<{}]+))?') r) r
    union all
    -- @constructs name
    select 'constructs' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(constructs)(\s+([^\s@)<{}]+))') r
    union all
    -- @constructs
    select 'constructs' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(constructs)[[:>:]]') r
    union all
    -- @copyright some copyright text
    select 'copyright' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(copyright)(\s*([^@]*)?)') r
    union all
    -- @default|defaultvalue value
    select 'default' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(default|defaultvalue)[[:>:]](\s+([^\s@)<{}]+))') r
    union all
    -- @default|defaultvalue
    select 'default' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(default|defaultvalue)[[:>:]]') r
    union all
    -- @deprecated some text
    select 'deprecated' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(deprecated)(\s*([^@]*)?)') r
    union all
    -- @deprecated
    select 'deprecated' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(deprecated)[[:>:]]') r
    union all
    -- @description|desc|classdesc some description
    select 'description' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(description|desc|classdesc)[[:>:]](\s*([^@]*)?)', 'g') r
    having array_agg(r[3]) is not null
    union all
    -- @enum {type} [name]
    select 'enum' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(enum)(\s*{([^{]*)?})(\s+([^\s@)<{}]+))?') r
    union all
    -- @enum
    select 'enum' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(enum)[[:>:]]') r
    union all
    -- @event event_name
    select 'event' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(event)(\s+([^\s@)<{}]+))', 'g') r
    having array_agg(r[3]) is not null
    union all
    -- @example multiline example, code, comments, etc
    select 'example' as figure, to_jsonb(array_agg(r[2])) as object
      from regexp_matches(str, '@(example)(\s*([^@]*)?)', 'g') r
    having array_agg(r[2]) is not null
    union all
    -- @exports name
    select 'exports' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(exports)(\s+([^\s@)<{}]+))') r
    union all
    -- @external|host name_of_external
    select 'external' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(external|host)(\s+([^\s@)<{}]+))') r
    union all
    -- @file some description
    select 'file' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(file|fileoverview|overview)[[:>:]](\s*([^@]*)?)') r
    union all
    -- @fires|emits event_name
    select 'event' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(fires|emits)(\s+([^\s@)<{}]+))', 'g') r
    having array_agg(r[3]) is not null
    union all
    -- @function|func|method name
    select 'function' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(function|func|method)[[:>:]](\s+([^\s@)<{}]+))') r
    union all
    -- @function|func|method
    select 'function' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(function|func|method)[[:>:]]') r
    union all
    -- @implements {type}
    select 'implements' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(implements)(\s*{([^{]*)?})') r
    union all
    -- @interface name
    select 'interface' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(interface)(\s+([^\s@)<{}]+))') r
    union all
    -- @interface
    select 'true' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(interface)[[:>:]]') r
    union all
    -- @created date
    select 'created' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(created)(\s*([^@]*)?)') r
    union all
    -- @kind class|constant|event|external|file|function|member|mixin|module|namespace|typedef
    select 'kind' as figure, to_jsonb(r[2]) as object
      from regexp_matches(str, '@(kind)\s+(class|constant|event|external|file|function|member|mixin|module|namespace|typedef)[[:>:]]') r
    union all
    -- @lends path
    select 'lends' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(lends)(\s+([^\s@)<{}]+))') r
    union all
    -- @license identifier|standalone multiline text
    select 'license' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(license)(\s*([^@]*)?)') r
    union all
    -- @listens event_name
    select 'listens' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(listens)(\s+([^\s@)<{}]+))', 'g') r
    having array_agg(r[3]) is not null
    union all
    -- @member|var|variable {type} [name]
    select 'variable' as figure, row_to_json(r)::jsonb as object
      from (select r[3] as "type", r[5] as "name"
              from regexp_matches(str, '@(var|variable|member)[[:>:]](\s*{([^{]*)?})(\s+([^\s@)<{}]+))?') r) r
    union all
    -- @memberof[!] name
    select 'memberof' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(memberof|memberof!)(\s+([^\s@)<{}]+))') r
    union all
    -- @mixes other_object_path
    select 'mixes' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(mixes)(\s+([^\s@)<{}]+))') r
    union all
    -- @mixin name
    select 'mixin' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(mixin)(\s+([^\s@)<{}]+))') r
    union all
    -- @mixin
    select 'mixin' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(mixin)[[:>:]]') r
    union all
    -- @module name
    select 'module' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(module)(\s+([^\s@)<{}]+))') r
    union all
    -- @module
    select 'module' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(module)[[:>:]]') r
    union all
    -- @namespace name
    select 'namespace' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(namespace)(\s+([^\s@)<{}]+))') r
    union all
    -- @namespace
    select 'namespace' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(namespace)[[:>:]]') r
    union all
    -- @name name
    select 'name' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(name)(\s+([^\s@)<{}]+))') r
    union all
    -- @package {type}
    select 'package' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(package)(\s*{([^{]*)?})') r
    union all
    -- @package
    select 'package' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(package)[[:>:]]') r
    union all
    -- @private {type}
    select 'private' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(private)(\s*{([^{]*)?})') r
    union all
    -- @private
    select 'private' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(private)[[:>:]]') r
    union all
    -- @protected {type}
    select 'protected' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(protected)(\s*{([^{]*)?})') r
    union all
    -- @protected
    select 'protected' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(protected)[[:>:]]') r
    union all
    -- @requires module_name
    select 'requires' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(requires)(\s+([^\s@)<{}]+))', 'g') r
    having array_agg(r[3]) is not null
    union all
    -- @return|returns {type} [description]
    select 'returns' as figure, row_to_json(r)::jsonb as object
      from (select r[3] as "type", r[5] as "description", string_to_array(trim(r[3]), '|') as "types"
              from regexp_matches(str, '@(returns|return)[[:>:]](\s*{([^{]*)?})(\s*([^@]*)?)?') r) r
    union all
    -- @see {@link namepath}|namepath [description]
    select 'see' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select coalesce(r[4], r[6]) as "path", r[8] as "description"
              from regexp_matches(str, '@(see)((\s*{([^{]*)?})|(\s+([^\s@)<{}]+)))(\s*([^@]*)?)?', 'g') r) r
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @since version
    select 'since' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(since)(\s*([^@]*)?)') r
    union all
    -- @summary description
    select 'summary' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(summary)(\s*([^@]*)?)') r
    union all
    -- @this namePath
    select 'this' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(this)(\s+([^\s@)<{}]+))') r
    union all
    -- @throws|exception {type} [description]
    select 'throws' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select r[3] as "type", r[5] as "description"
              from regexp_matches(str, '@(throws|exception)(\s*{([^{]*)?})?(\s*([^@]*)?)?', 'g') r) r
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @todo text describing thing to do.
    select 'todo' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(todo)(\s*([^@]*)?)', 'g') r
    having array_agg(r[3]) is not null
    union all
    -- @typedef [{type}] name
    select 'typedef' as figure, row_to_json(r)::jsonb as object
      from (select r[3] as "type", r[5] as "name"
              from regexp_matches(str, '@(typedef)[[:>:]](\s*{([^{]*)?})?(\s+([^\s@)<{}]+))') r) r
    union all
    -- @tutorial {@link path}|name
    select 'tutorial' as figure, to_jsonb(array_agg(r[4])) as object
      from regexp_matches(str, '@(tutorial)((\s*{([^{]*)?})|(\s+([^\s@)<{}]+)))', 'g') r
    having array_agg(r[4]) is not null
    union all
    -- @type {type}
    select 'type' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(type)[[:>:]](\s*{([^{]*)?})') r
    union all
    -- @variation number
    select 'variation' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(variation)[[:>:]](\s+([^\s@)<{}]+))') r
    union all
    -- @version version
    select 'version' as figure, to_jsonb(r[3]) as object
      from regexp_matches(str, '@(version)[[:>:]](\s*([^@]*)?)') r
    union all
    -- @yield|yields|next [{type}] [description]
    select 'yield' as figure, row_to_json(r)::jsonb as object
      from (select r[3] as "type", r[5] as "description"
              from regexp_matches(str, '@(yield|yields|next)[[:>:]](\s*{([^{]*)?})?(\s*([^@]*)?)?') r) r
    union all
    -- @change|changed|changelog|modified [date] [<author>] [description]
    select 'change' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select r[3] as "date", r[5] as "author", r[7] as "description"
              from regexp_matches(str, '@(change|changed|changelog|modified)[[:>:]](\s+([^\s@)<{}]+))?(\s*<([^<]*)>)?(\s*([^@]*)?)?', 'g') r) r
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @isue some description
    select 'isue' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(isue)(\s*([^@]*)?)', 'g') r
    having array_agg(r[3]) is not null
    union all
    -- @figure|form name([parameters]) [description]
    select 'figure' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select r[2] as "figure", r[7] as "description"
              from regexp_matches(str, '@(figure|form)((\s+([^\s@)<{}]+))(\s*\(([^\(]*)\)))(\s*([^@]*)?)?', 'g') r) r
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @template [{type}] name[, name, ...] [- description]
    select 'template' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select r[3] as "type", r[5] as "name", r[8] as "description", string_to_array(trim(r[3]), '|') as "types", string_to_array(trim(r[5]), ',') as "names"
              from regexp_matches(str, '@(template)(\s*{([^{]*)?})?(\s+([^@\-<{\(]+))(\s*\-(\s*([^@]*)?)?)?', 'g') r) r
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @callback name
    select 'callback' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(callback)(\s+([^\s@)<{}]+))', 'g') r
    having array_agg(r[3]) is not null
    union all
    -- @test
    select 'test' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(test)[[:>:]]') r
    union all
    -- @column {type} name [description]
    select 'column' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select r[3] as "type", r[5] as "name", r[7] as "description"
              from regexp_matches(str, '@(column)(\s*{([^{]*)?})?(\s+([^\s@)<{}]+))(\s*([^@]*)?)?', 'g') r) r
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @table {type} name [description]
    select 'table' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select r[3] as "type", r[5] as "name", r[7] as "description"
              from regexp_matches(str, '@(table)(\s*{([^{]*)?})?(\s+([^\s@)<{}]+))(\s*([^@]*)?)?', 'g') r) r
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @sequence|generator name [description]
    select 'sequence' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select r[3] as "name", r[5] as "description"
              from regexp_matches(str, '@(sequence|generator)(\s+([^\s@)<{}]+))(\s*([^@]*)?)?', 'g') r) r
    having jsonb_agg(row_to_json(r)::jsonb) is not null) r;
end;
$fn$;

ALTER FUNCTION gendoc.jsdoc_parse(str character varying) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.jsdoc_parse(str character varying) IS '';