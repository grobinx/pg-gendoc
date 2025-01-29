--DROP FUNCTION gendoc.get_routines(aschema name, aoptions jsonb);

CREATE OR REPLACE FUNCTION gendoc.get_routines(aschema name, aoptions jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/**
 * Create jsonb with all usable information about routines on schema
 * 
 * @param {name} aschema schema name
 * @param {jsonb} aoptions options
 * @returns {jsonb}
 *
 * @property {varchar[]} aoptions.routines.include include routines or null if all
 * @property {varchar[]} aoptions.routines.exclude exclude routines or null if all
 * @property {varchar[]} aoptions.package package names or null if all and if aoptions.parse.routine_body set to true
 * @property {varchar[]} aoptions.module module names or null if all and if aoptions.parse.routine_body set to true
 * @property {boolean} [aoptions.parse.routine_body=true] parse body for search documentation if plpgsql, otherwise the comment will be processed
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-25
 * @version 1.0
 * @since 2.0
 */
declare
  l_include varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'routines'->'include') x;
  l_exclude varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'routines'->'exclude') x;
  l_package varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'package') x;
  l_module varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'module') x;
  l_parse_body boolean := coalesce((aoptions->'parse'->'routine_body')::boolean, true);
begin
  return jsonb_agg(
           jsonb_build_object(
             'schema_name', p.nspname, 'routine_name', p.proname,
             'kind', case p.prokind when 'f'::char then 'function' when 'p'::char then 'procedure' end,
             'returns', pg_get_function_result(p.oid), 'returns_type', pg_catalog.format_type(p.prorettype, null),
             'arguments', coalesce(a.arguments, '[]'),
             'description', p.description, 'doc_data', p.doc_data,
             'identity_name', p.proname||'('||coalesce(pg_get_function_identity_arguments(p.oid), '')||')',
             'language', p.lanname
           )
           order by p.nspname, p.proname
         )
    from (select p.oid, n.nspname, p.proname, p.prokind, p.prorettype, d.description, l.lanname,
                 case 
                   when l_parse_body then 
                     case when l.lanname = 'plpgsql' then gendoc.jsdoc_parse(substring(p.prosrc from '\/\*\*.*\*\/'))
                          else gendoc.jsdoc_parse(d.description)
                     end
                 end doc_data
            from pg_proc p
                 join pg_namespace n on n.oid = p.pronamespace
                 join pg_language l on l.oid = p.prolang
                 left join pg_description d on d.classoid = 'pg_proc'::regclass and d.objoid = p.oid and d.objsubid = 0
           where p.prokind in ('f', 'p') 
             and n.nspname = aschema
             and (l_include is null or p.proname = any (l_include))
             and (l_exclude is null or p.proname <> all (l_exclude))) p
         join lateral (
           select jsonb_agg(
                    jsonb_build_object(
                      'argument_no', r.argument_no, 'argument_name', r.argument_name, 'data_type', r.data_type, 'mode', r.mode, 'default_value', r.default_value
                    )
                  ) arguments
             from (select n as argument_no, f.proargnames[n] as argument_name, pg_catalog.format_type(f.proargtypes[n -1], -1) as data_type,
                          case f.proargmodes[n] when 'o' then 'out' when 'b' then 'in/out' else 'in' end as mode,
                          trim((regexp_split_to_array(pg_get_expr(f.proargdefaults, 0), '[\t,](?=(?:[^\'']|\''[^\'']*\'')*$)'))[case when f.pronargs -n > f.pronargdefaults then null else f.pronargdefaults -(f.pronargs -n +1) +1 end]) default_value
                     from (select f.oid, pg_catalog.generate_series(1, f.pronargs::int) n, f.*
                             from pg_catalog.pg_proc f
                            where f.oid = p.oid) f) r) a on true
   where (l_package is null or p.doc_data->>'package' is null or p.doc_data->>'package' = any (l_package))
     and (l_module is null or p.doc_data->>'module' is null or p.doc_data->>'module' = any (l_module));
end;
$function$;

ALTER FUNCTION gendoc.get_routines(aschema name, aoptions jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_routines(aschema name, aoptions jsonb) IS 'Create jsonb with all usable information about functions on schema';
