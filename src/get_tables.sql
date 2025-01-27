--DROP FUNCTION gendoc.get_tables(aschema name, ainclude character varying[], aexclude character varying[]);

CREATE OR REPLACE FUNCTION gendoc.get_tables(
  aschema name, ainclude character varying[] DEFAULT NULL::character varying[], 
  aexclude character varying[] DEFAULT NULL::character varying[])
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/**
 * Create jsonb with all usable information about tables on schema
 * 
 * @param {name} aschema schema name
 * @param {varchar[]} ainclude include tables
 * @param {varchar[]} aexclude exclude tables
 * @returns {jsonb}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-24
 * @version 1.0
 * @since 2.0
 */
begin
  return jsonb_agg(
           jsonb_build_object(
             'schema_name', n.nspname, 'table_name', c.relname, 'description', d.description, 
             'kind', case c.relkind when 'f'::char then 'foreign' when 'r'::char then 'ordinary' when 'p'::char then 'partitioned' end,
             'owner', pg_catalog.pg_get_userbyid(c.relowner), 
             'columns', cls.columns, 'doc_data', gendoc.jsdoc_parse(description)
           )
           order by n.nspname, c.relname) as tables
    from pg_class c
         left join pg_namespace n on n.oid = c.relnamespace
         left join pg_description d on d.classoid = 'pg_class'::regclass and d.objoid = c.oid and d.objsubid = 0
         join lateral 
              (select jsonb_agg(
                        jsonb_build_object(
                          'column_no', column_no, 'column_name', column_name, 'data_type', data_type, 'nullable', nullable, 
                          'default_value', default_value, 'storage_type', storage_type, 
                          'description', description, 'foreign_key', foreign_key, 'primary_key', primary_key,
                          'doc_data', gendoc.jsdoc_parse(description)
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
   where c.relkind in ('r'::char, 'f'::char, 'p'::char)
     and n.nspname = aschema
     and (ainclude is null or c.relname = any (ainclude))
     and (aexclude is null or c.relname <> all (aexclude));
end;
$function$;

ALTER FUNCTION gendoc.get_tables(aschema name, ainclude character varying[], aexclude character varying[]) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_tables(aschema name, ainclude character varying[], aexclude character varying[]) IS 'Create jsonb with all usable information about tables on schemat';
