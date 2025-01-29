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
 * @created Wed Jan 29 2025 17:35:52 GMT+0100 (czas środkowoeuropejski standardowy)
 * @version 1.1.12
 * 
 * @param {varchar|text} str string to parse
 * @returns {jsonb}
 * @example
 * select p.proname, jsdoc_parse(p.doc) as doc, p.arguments, p.description
 *   from (select p.proname, substring(p.prosrc from '\/\*\*.*\*\/') as doc, 
 *                coalesce(pg_get_function_arguments(p.oid), '') arguments,
 *                d.description
 *           from pg_proc p
 *                join pg_namespace n on n.oid = p.pronamespace
 *                left join pg_description d on d.classoid = 'pg_proc'::regclass and d.objoid = p.oid and d.objsubid = 0
 *          where n.nspname = :scema_name
 *            and p.prokind in ('p', 'f')) p
 *  where p.doc is not null
 */
declare
  l_figures text[];
begin
  if position('/**' in str) then
    str := string_agg(substring(line from '^\s*\*\s*(.*)'), e'\n')
      from (select unnest(string_to_array(str, e'\n')) line) d
     where trim(line) not in ('/**', '*/');
  end if;
  --
  l_figures := array_agg(distinct f) from (select unnest(regexp_matches(str, '@(\w+)', 'g')) f) u;
  --
  return jsonb_object_agg(r.figure, r.object)
    from (    -- This is root description
    select 'root' as figure, to_jsonb(trim(e' \t\n\r' from r[1])) as object
      from regexp_matches(str, '^([^@]+)') r
    union all
    -- @param|arg|argument [{type}] name|[name=value] [description]
    select 'param' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from coalesce(trim(e' \t\n\r' from r[7]), trim(e' \t\n\r' from r[11]))) as "name", trim(e' \t\n\r' from r[9]) as "default", trim(e' \t\n\r' from r[13]) as "description", string_to_array(trim(e' \t\n\r' from trim(e' \t\n\r' from r[3])), '|') as "types"
              from regexp_matches(str, '@(param|arg|argument)(\s*{([^{]*)?})?((\s*\[(([^\[\=]+)\s*(\=\s*([^\[]*)?)?)?\])|(\s+([^\s@)<{}]+)))(\s*([^@]*)?)?', 'g') r) r
     where array['param', 'arg', 'argument'] && l_figures
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @property|prop [{type}] name|[name=value] [description]
    select 'property' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from coalesce(trim(e' \t\n\r' from r[7]), trim(e' \t\n\r' from r[11]))) as "name", trim(e' \t\n\r' from r[9]) as "default", trim(e' \t\n\r' from r[13]) as "description", string_to_array(trim(e' \t\n\r' from trim(e' \t\n\r' from r[3])), '|') as "types", string_to_array(trim(e' \t\n\r' from trim(e' \t\n\r' from coalesce(r[7], r[11]))), '.') as "names"
              from regexp_matches(str, '@(property|prop)[[:>:]](\s*{([^{]*)?})?((\s*\[(([^\[\=]+)\s*(\=\s*([^\[]*)?)?)?\])|(\s+([^\s@)<{}]+)))(\s*([^@]*)?)?', 'g') r) r
     where array['property', 'prop'] && l_figures
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @ignore
    select 'ignore' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(ignore)[[:>:]]\s*(\n|$)') r
     where 'ignore' = any (l_figures)
    union all
    -- @override
    select 'override' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(override)[[:>:]]\s*(\n|$)') r
     where 'override' = any (l_figures)
    union all
    -- @public
    select 'public' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(public)[[:>:]]\s*(\n|$)') r
     where 'public' = any (l_figures)
    union all
    -- @readonly
    select 'readonly' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(readonly)[[:>:]]\s*(\n|$)') r
     where 'readonly' = any (l_figures)
    union all
    -- @alias path [description]
    select 'alias' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "path", trim(e' \t\n\r' from r[5]) as "description"
              from regexp_matches(str, '@(alias)(\s+([^\s@)<{}]+))(\s*([^@]*)?)?') r) r
     where 'alias' = any (l_figures)
    union all
    -- @author author [<email@address>] [(http-page)] [- description]
    select 'author' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "author", trim(e' \t\n\r' from r[5]) as "email", trim(e' \t\n\r' from r[7]) as "page", trim(e' \t\n\r' from r[10]) as "description"
              from regexp_matches(str, '@(author)(\s+([^@\-<{\(]+))(\s*<([^<]*)>)?(\s*\(([^\(]*)\))?(\s*\-(\s*([^@]*)?)?)?', 'g') r) r
     where 'author' = any (l_figures)
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @borrows thas_namepath as this_namepath [description]
    select 'borrows' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "that", trim(e' \t\n\r' from r[5]) as "this", trim(e' \t\n\r' from r[7]) as "description"
              from regexp_matches(str, '@(borrows)(\s+([^\s@)<{}]+))\s*as\s*(\s+([^\s@)<{}]+))(\s*([^@]*)?)?') r) r
     where 'borrows' = any (l_figures)
    union all
    -- @constatnt|const {type} [name]
    select 'constant' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "name"
              from regexp_matches(str, '@(constant|const)(\s*{([^{]*)?})(\s+([^\s@)<{}]+))?') r) r
     where array['constatnt', 'const'] && l_figures
    union all
    -- @copyright some copyright text
    select 'copyright' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(copyright)(\s*([^@]*)?)') r
     where 'copyright' = any (l_figures)
    union all
    -- @deprecated some text
    select 'deprecated' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(deprecated)(\s*([^@]*)?)') r
     where 'deprecated' = any (l_figures)
    union all
    -- @deprecated
    select 'deprecated' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(deprecated)[[:>:]]\s*(\n|$)') r
     where 'deprecated' = any (l_figures)
    union all
    -- @description|desc|classdesc some description
    select 'description' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(description|desc|classdesc)[[:>:]](\s*([^@]*)?)', 'g') r
     where array['description', 'desc', 'classdesc'] && l_figures
    having array_agg(r[3]) is not null
    union all
    -- @enum {type} [name]
    select 'enum' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "name"
              from regexp_matches(str, '@(enum)(\s*{([^{]*)?})(\s+([^\s@)<{}]+))?') r) r
     where 'enum' = any (l_figures)
    union all
    -- @enum
    select 'enum' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(enum)[[:>:]]\s*(\n|$)') r
     where 'enum' = any (l_figures)
    union all
    -- @example multiline example, code, comments, etc
    select 'example' as figure, to_jsonb(array_agg(r[2])) as object
      from regexp_matches(str, '@(example)(\s*([^@]*)?)', 'g') r
     where 'example' = any (l_figures)
    having array_agg(r[2]) is not null
    union all
    -- @function|func|method name
    select 'function' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(function|func|method)[[:>:]](\s+([^\s@)<{}]+))') r
     where array['function', 'func', 'method'] && l_figures
    union all
    -- @function|func|method
    select 'function' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(function|func|method)[[:>:]]\s*(\n|$)') r
     where array['function', 'func', 'method'] && l_figures
    union all
    -- @created date
    select 'created' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(created)(\s*([^@]*)?)') r
     where 'created' = any (l_figures)
    union all
    -- @license identifier|standalone multiline text
    select 'license' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(license)(\s*([^@]*)?)') r
     where 'license' = any (l_figures)
    union all
    -- @member|var|variable {type} [name]
    select 'variable' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "name"
              from regexp_matches(str, '@(var|variable|member)[[:>:]](\s*{([^{]*)?})(\s+([^\s@)<{}]+))?') r) r
     where array['member', 'var', 'variable'] && l_figures
    union all
    -- @module
    select 'module' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(module)[[:>:]]\s*(\n|$)') r
     where 'module' = any (l_figures)
    union all
    -- @package name
    select 'package' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(package)(\s+([^\s@)<{}]+))') r
     where 'package' = any (l_figures)
    union all
    -- @private
    select 'private' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(private)[[:>:]]\s*(\n|$)') r
     where 'private' = any (l_figures)
    union all
    -- @requires module_name
    select 'requires' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(requires)(\s+([^\s@)<{}]+))', 'g') r
     where 'requires' = any (l_figures)
    having array_agg(r[3]) is not null
    union all
    -- @return|returns {type} [description]
    select 'returns' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "description", string_to_array(trim(e' \t\n\r' from trim(e' \t\n\r' from r[3])), '|') as "types"
              from regexp_matches(str, '@(returns|return)[[:>:]](\s*{([^{]*)?})(\s*([^@]*)?)?') r) r
     where array['return', 'returns'] && l_figures
    union all
    -- @see {@link namepath}|namepath [description]
    select 'see' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from coalesce(trim(e' \t\n\r' from r[4]), trim(e' \t\n\r' from r[6]))) as "path", trim(e' \t\n\r' from r[8]) as "description"
              from regexp_matches(str, '@(see)((\s*{([^{]*)?})|(\s+([^\s@)<{}]+)))(\s*([^@]*)?)?', 'g') r) r
     where 'see' = any (l_figures)
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @since version
    select 'since' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(since)(\s*([^@]*)?)') r
     where 'since' = any (l_figures)
    union all
    -- @summary description
    select 'summary' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(summary)(\s*([^@]*)?)') r
     where 'summary' = any (l_figures)
    union all
    -- @throws|exception {type} [description]
    select 'throws' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "description"
              from regexp_matches(str, '@(throws|exception)(\s*{([^{]*)?})?(\s*([^@]*)?)?', 'g') r) r
     where array['throws', 'exception'] && l_figures
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @todo text describing thing to do.
    select 'todo' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(todo)(\s*([^@]*)?)', 'g') r
     where 'todo' = any (l_figures)
    having array_agg(r[3]) is not null
    union all
    -- @tutorial {@link path}|name
    select 'tutorial' as figure, to_jsonb(array_agg(r[4])) as object
      from regexp_matches(str, '@(tutorial)((\s*{([^{]*)?})|(\s+([^\s@)<{}]+)))', 'g') r
     where 'tutorial' = any (l_figures)
    having array_agg(r[4]) is not null
    union all
    -- @variation number
    select 'variation' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(variation)[[:>:]](\s+([^\s@)<{}]+))') r
     where 'variation' = any (l_figures)
    union all
    -- @version version
    select 'version' as figure, to_jsonb(trim(e' \t\n\r' from r[3])) as object
      from regexp_matches(str, '@(version)[[:>:]](\s*([^@]*)?)') r
     where 'version' = any (l_figures)
    union all
    -- @yield|yields|next [{type}] [description]
    select 'yield' as figure, row_to_json(r)::jsonb as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "description"
              from regexp_matches(str, '@(yield|yields|next)[[:>:]](\s*{([^{]*)?})?(\s*([^@]*)?)?') r) r
     where array['yield', 'yields', 'next'] && l_figures
    union all
    -- @change|changed|changelog|modified [date|version] [<author>] [description]
    select 'change' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "date", trim(e' \t\n\r' from r[5]) as "author", trim(e' \t\n\r' from r[7]) as "description"
              from regexp_matches(str, '@(change|changed|changelog|modified)[[:>:]](\s+([^\s@)<{}]+))?(\s*<([^<]*)>)?(\s*([^@]*)?)?', 'g') r) r
     where array['change', 'changed', 'changelog', 'modified'] && l_figures
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @isue some description
    select 'isue' as figure, to_jsonb(array_agg(r[3])) as object
      from regexp_matches(str, '@(isue)(\s*([^@]*)?)', 'g') r
     where 'isue' = any (l_figures)
    having array_agg(r[3]) is not null
    union all
    -- @test
    select 'test' as figure, to_jsonb(true) as object
      from regexp_matches(str, '@(test)[[:>:]]\s*(\n|$)') r
     where 'test' = any (l_figures)
    union all
    -- @column {type} name [description]
    select 'column' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "name", trim(e' \t\n\r' from r[7]) as "description"
              from regexp_matches(str, '@(column)(\s*{([^{]*)?})?(\s+([^\s@)<{}]+))(\s*([^@]*)?)?', 'g') r) r
     where 'column' = any (l_figures)
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @table {type} name [description]
    select 'table' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "name", trim(e' \t\n\r' from r[7]) as "description"
              from regexp_matches(str, '@(table)(\s*{([^{]*)?})?(\s+([^\s@)<{}]+))(\s*([^@]*)?)?', 'g') r) r
     where 'table' = any (l_figures)
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @view {type} name [description]
    select 'view' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "type", trim(e' \t\n\r' from r[5]) as "name", trim(e' \t\n\r' from r[7]) as "description"
              from regexp_matches(str, '@(view)(\s*{([^{]*)?})?(\s+([^\s@)<{}]+))(\s*([^@]*)?)?', 'g') r) r
     where 'view' = any (l_figures)
    having jsonb_agg(row_to_json(r)::jsonb) is not null
    union all
    -- @sequence|generator name [description]
    select 'sequence' as figure, jsonb_agg(row_to_json(r)::jsonb) as object
      from (select trim(e' \t\n\r' from r[3]) as "name", trim(e' \t\n\r' from r[5]) as "description"
              from regexp_matches(str, '@(sequence|generator)(\s+([^\s@)<{}]+))(\s*([^@]*)?)?', 'g') r) r
     where array['sequence', 'generator'] && l_figures
    having jsonb_agg(row_to_json(r)::jsonb) is not null) r;
end;
$fn$;

ALTER FUNCTION gendoc.jsdoc_parse(str character varying) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.jsdoc_parse(str character varying) IS '';