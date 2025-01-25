--DROP FUNCTION gendoc.get_schema(aschema name);

CREATE OR REPLACE FUNCTION gendoc.get_schema(aschema name)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/**
 * Create jsonb with all usable information about schema
 * 
 * @param {name} aschema schema name
 * @returns {jsonb}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-25
 * @version 1.0
 * @since 2.0
 */
begin
  return jsonb_build_object('schema_name', ns.nspname, 'description', des.description)
    from pg_description des
         join pg_namespace ns on des.objoid = ns.oid
   where classoid = 'pg_namespace'::regclass
     and ns.nspname = aschema;
end;
$function$;

ALTER FUNCTION gendoc.get_schema(aschema name) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_schema(aschema name) IS 'Create jsonb with all usable information about schema';
