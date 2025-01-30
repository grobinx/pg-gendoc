--DROP FUNCTION gendoc.get_views(aschema name, aoptions jsonb);

CREATE OR REPLACE FUNCTION gendoc.get_views(aschema name, aoptions jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/**
 * Create jsonb with all usable information about views on schema
 *
 * @summary collect information about views
 * 
 * @param {name} aschema schema name
 * @param {jsonb} aoptions options
 * @returns {jsonb}
 *
 * @property {varchar[]} aoptions.views.include include views or null if all
 * @property {varchar[]} aoptions.views.exclude exclude views or null if all
 * @property {varchar[]} aoptions.package package names or null if all 
 * @property {varchar[]} aoptions.module module names or null if all 
 * @property {boolean} [aoptions.parse.view_comment=true] parse doc table comment
 * @property {boolean} [aoptions.parse.view_column_comment=false] parse doc table column comment
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-25
 * @version 1.0
 * @since 2.0
 */
declare
  l_include varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'views'->'include') x;
  l_exclude varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'views'->'exclude') x;
  l_package varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'package') x;
  l_module varchar[] := array_agg(x) from jsonb_array_elements_text(aoptions->'module') x;
  l_view_comment boolean := coalesce((aoptions->'parse'->'view_comment')::boolean, true);
  l_column_comment boolean := coalesce((aoptions->'parse'->'view_column_comment')::boolean, false);
begin
  return jsonb_agg(
           jsonb_build_object(
             'schema_name', c.nspname, 'view_name', c.relname, 'description', c.description, 
             'kind', case c.relkind when 'v'::char then 'view' when 'm'::char then 'materialized' end,
             'columns', cls.columns, 'doc_data', c.doc_data
           )
           order by c.nspname, c.relname
         ) as tables
    from (select c.oid, n.nspname, c.relname, d.description, c.relkind,
                 case when l_view_comment then gendoc.jsdoc_parse(d.description) end doc_data
            from pg_class c
                 left join pg_namespace n on n.oid = c.relnamespace
                 left join pg_description d on d.classoid = 'pg_class'::regclass and d.objoid = c.oid and d.objsubid = 0
           where c.relkind in ('v'::char, 'm'::char)
             and n.nspname = aschema
             and (l_include is null or c.relname = any (l_include))
             and (l_exclude is null or c.relname <> all (l_exclude))) c
         join lateral 
              (select jsonb_agg(
                        jsonb_build_object(
                          'column_no', column_no, 'column_name', column_name, 'data_type', data_type, 'storage_type', storage_type, 
                          'description', description, 'doc_data', case when l_column_comment then gendoc.jsdoc_parse(description) end
                        )
                        order by column_no
                      ) as columns
                 from (select att.attname as column_name, att.attnum as column_no, 
                              case when ty.typtype = 'd'::"char" and tn.nspname <> 'public' then tn.nspname||'.' else '' end||
                                pg_catalog.format_type(ty.oid, att.atttypmod) as data_type,
                              case att.attstorage when 'x' then 'EXTENDED' when 'p' then 'PLAIN' when 'e' then 'EXTERNAL' when 'm' then 'MAIN' else '???' end as storage_type, 
                              des.description
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

ALTER FUNCTION gendoc.get_views(aschema name, aoptions jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_views(aschema name, aoptions jsonb) IS '';
