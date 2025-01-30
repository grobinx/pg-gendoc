--DROP FUNCTION gendoc.get_tables(aschema name, aoptions jsonb);

CREATE OR REPLACE FUNCTION gendoc.get_tables(aschema name, aoptions jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/**
 * Create jsonb with all usable information about tables on schema
 *
 * @summary collect information about tables
 * 
 * @param {name} aschema schema name
 * @param {jsonb} aoptions options
 * @returns {jsonb}
 *
 * @property {varchar[]} aoptions.tables.include include tables or null if all
 * @property {varchar[]} aoptions.tables.exclude exclude tables or null if all
 * @property {varchar[]} aoptions.package package names or null if all 
 * @property {varchar[]} aoptions.module module names or null if all 
 * @property {boolean} [aoptions.parse.table_comment=true] parse doc table comment
 * @property {boolean} [aoptions.parse.table_column_comment=false] parse doc table column comment
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-24
 * @version 1.0
 * @since 2.0
 */
declare
  l_include varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'tables'->'include') x;
  l_exclude varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'tables'->'exclude') x;
  l_package varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'package') x;
  l_module varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'module') x;
  l_table_comment boolean := coalesce((aoptions->'parse'->'table_comment')::boolean, true);
  l_column_comment boolean := coalesce((aoptions->'parse'->'table_column_comment')::boolean, false);
begin
  return jsonb_agg(
           jsonb_build_object(
             'schema_name', c.nspname, 'table_name', c.relname, 'description', c.description, 
             'kind', case c.relkind when 'f'::char then 'foreign' when 'r'::char then 'ordinary' when 'p'::char then 'partitioned' end,
             'columns', cls.columns, 'doc_data', doc_data
           )
           order by c.nspname, c.relname) as tables
    from (select c.oid, n.nspname, c.relname, c.relkind, d.description,
                 case when l_table_comment then gendoc.jsdoc_parse(d.description) end doc_data
            from pg_class c
                 join pg_namespace n on n.oid = c.relnamespace
                 left join pg_description d on d.classoid = 'pg_class'::regclass and d.objoid = c.oid and d.objsubid = 0
           where c.relkind in ('r'::char, 'f'::char, 'p'::char)
             and n.nspname = aschema
             and (l_include is null or c.relname = any (l_include))
             and (l_exclude is null or c.relname <> all (l_exclude))) c
         join lateral 
              (select jsonb_agg(
                        jsonb_build_object(
                          'column_no', column_no, 'column_name', column_name, 'data_type', data_type, 'nullable', nullable, 
                          'default_value', default_value, 'storage_type', storage_type, 
                          'description', description, 'foreign_key', foreign_key, 'primary_key', primary_key,
                          'doc_data', case when l_column_comment then gendoc.jsdoc_parse(description) end
                        )
                        order by column_no
                      ) as columns
                 from (select att.attname as column_name, att.attnum as column_no, 
                              case when ty.typtype = 'd'::"char" and tn.nspname <> 'public' then tn.nspname||'.' else '' end||
                                case when (SELECT true FROM pg_class seq, pg_depend d WHERE seq.relkind = 'S' and d.objid=seq.oid AND d.deptype='a' and d.refobjid = att.attrelid and d.refobjsubid = att.attnum limit 1) then
                                    case att.atttypid when 23 then 'serial' when 20 then 'bigserial' else pg_catalog.format_type(ty.oid, att.atttypmod) end
                                  else pg_catalog.format_type(ty.oid, att.atttypmod)
                                end
                                as data_type,
                              att.attnotnull nullable, pg_get_expr(def.adbin, def.adrelid) as default_value,
                              case att.attstorage when 'x' then 'EXTENDED' when 'p' then 'PLAIN' when 'e' then 'EXTERNAL' when 'm' then 'MAIN' else '???' end as storage_type, 
                              des.description,
                              exists (select from pg_constraint where conrelid = att.attrelid and contype='f' and att.attnum = any(conkey)) as foreign_key,
                              exists (select from pg_constraint where conrelid = att.attrelid and contype='p' and att.attnum = any(conkey)) as primary_key
                         from pg_attribute att
                              join pg_type ty on ty.oid = atttypid
                              join pg_namespace tn on tn.oid = ty.typnamespace
                              join pg_class cl on cl.oid = att.attrelid
                              join pg_namespace na on na.oid = cl.relnamespace
                              left outer join pg_attrdef def on adrelid = att.attrelid and adnum = att.attnum
                              left outer join pg_description des on des.classoid = 'pg_class'::regclass and des.objoid = att.attrelid and des.objsubid = att.attnum
                        where att.attnum > 0
                          and cl.oid = c.oid) cols) cls on true
   where (l_package is null or c.doc_data->>'package' is null or c.doc_data->>'package' = any (l_package))
     and (l_module is null or c.doc_data->>'module' is null or c.doc_data->>'module' = any (l_module));
end;
$function$;

ALTER FUNCTION gendoc.get_tables(aschema name, aoptions jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_tables(aschema name, aoptions jsonb) IS '';
