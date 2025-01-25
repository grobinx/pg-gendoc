--DROP FUNCTION gendoc.get_routines(aschema name, ainclude character varying[], aexclude character varying[]);

CREATE OR REPLACE FUNCTION gendoc.get_routines(aschema name, ainclude character varying[] DEFAULT NULL::character varying[], aexclude character varying[] DEFAULT NULL::character varying[])
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/**
 * Create jsonb with all usable information about routines on schema
 * 
 * @param {name} aschema schema name
 * @param {varchar[]} ainclude include routines
 * @param {varchar[]} aexclude exclude routines
 * @returns {jsonb}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-25
 * @version 1.0
 * @since 2.0
 */
begin
  return jsonb_agg(
           jsonb_build_object(
             'schema_name', n.nspname, 'routine_name', p.proname,
             'kind', case p.prokind when 'f'::char then 'function' when 'p'::char then 'procedure' end,
             'returns', pg_get_function_result(p.oid), 'arguments', a.arguments,
             'description', d.description, 'data_doc', gendoc.jsdoc_parse(substring(pg_get_functiondef(p.oid) from '\/\*\*.*\*\/'))
           )
           order by n.nspname, p.proname
         )
    from pg_proc p
         join pg_namespace n on n.oid = p.pronamespace
         left join pg_description d on d.classoid = 'pg_proc'::regclass and d.objoid = p.oid and d.objsubid = 0
         join lateral (
           select jsonb_agg(
                    jsonb_build_object(
                      'routine_no', r.routine_no, 'routine_name', r.routine_name, 'data_type', r.data_type, 'mode', r.mode, 'default_value', r.default_value
                    )
                  ) arguments
             from (select n as routine_no, f.proargnames[n] as routine_name, pg_catalog.format_type(f.proargtypes[n -1], -1) as data_type,
                          case f.proargmodes[n] when 'o' then 'out' when 'b' then 'in/out' else 'in' end as mode,
                          trim((regexp_split_to_array(pg_get_expr(f.proargdefaults, 0), '[\t,](?=(?:[^\'']|\''[^\'']*\'')*$)'))[case when f.pronargs -n > f.pronargdefaults then null else f.pronargdefaults -(f.pronargs -n +1) +1 end]) default_value
                     from (select f.oid, pg_catalog.generate_series(1, f.pronargs::int) n, f.*
                             from pg_catalog.pg_proc f
                            where f.oid = p.oid) f) r) a on true
   where prokind in ('f', 'p') 
     and n.nspname = aschema
     and (ainclude is null or p.proname = any (ainclude))
     and (aexclude is null or p.proname <> all (aexclude));
end;
$function$;

ALTER FUNCTION gendoc.get_routines(aschema name, ainclude character varying[], aexclude character varying[]) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_routines(aschema name, ainclude character varying[], aexclude character varying[]) IS 'Create jsonb with all usable information about functions on schema';
