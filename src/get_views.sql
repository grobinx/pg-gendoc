--DROP FUNCTION gendoc.get_views(aschema name, ainclude character varying[], aexclude character varying[]);

CREATE OR REPLACE FUNCTION gendoc.get_views(aschema name, ainclude character varying[] DEFAULT NULL::character varying[], aexclude character varying[] DEFAULT NULL::character varying[])
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/**
 * Create jsonb with all usable information about views on schema
 * 
 * @param {name} aschema schema name
 * @param {varchar[]} ainclude include views
 * @param {varchar[]} aexclude exclude views
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
             'schema_name', n.nspname, 'view_name', c.relname, 'description', d.description, 
             'kind', case c.relkind when 'v'::char then 'view' when 'm'::char then 'materialized' end,
             'owner', pg_catalog.pg_get_userbyid(c.relowner), 
             'columns', cls.columns, 'doc_data', gendoc.jsdoc_parse(description)
           )
           order by n.nspname, c.relname
         ) as tables
    from pg_class c
         left join pg_namespace n on n.oid = c.relnamespace
         left join pg_description d on d.classoid = 'pg_class'::regclass and d.objoid = c.oid and d.objsubid = 0
         join lateral 
              (select jsonb_agg(
                        jsonb_build_object(
                          'column_no', column_no, 'column_name', column_name, 'data_type', data_type, 'storage_type', storage_type, 
                          'description', description, 'doc_data', gendoc.jsdoc_parse(description)
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
   where c.relkind in ('v'::char, 'm'::char)
     and n.nspname = aschema
     and (ainclude is null or c.relname = any (ainclude))
     and (aexclude is null or c.relname <> all (aexclude));
end;
$function$;

ALTER FUNCTION gendoc.get_views(aschema name, ainclude character varying[], aexclude character varying[]) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_views(aschema name, ainclude character varying[], aexclude character varying[]) IS 'Create jsonb with all usable information about views on schema';
