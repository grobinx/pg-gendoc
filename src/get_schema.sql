--DROP FUNCTION gendoc.get_schema(aschema name, aoptions jsonb);

CREATE OR REPLACE FUNCTION gendoc.get_schema(aschema name, aoptions jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/**
 * Create jsonb with all usable information about schema
 * 
 * @param {name} aschema schema name
 * @param {jsonb} aoptions options
 * @returns {jsonb}
 *
 * @property {boolean} [aoptions.parse.schema_comment=false] whether the schema comment should be processed
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-25
 * @version 1.0
 * @since 2.0
 */
begin
  return jsonb_build_object(
           'schema_name', ns.nspname, 
           'description', des.description,
           'doc_data', case when coalesce((aoptions->'parse'->>'schema_comment')::boolean, false) then gendoc.jsdoc_parse(des.description) end
         )
    from pg_description des
         join pg_namespace ns on des.objoid = ns.oid
   where classoid = 'pg_namespace'::regclass
     and ns.nspname = aschema;
end;
$function$;

ALTER FUNCTION gendoc.get_schema(aschema name, aoptions jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_schema(aschema name, aoptions jsonb) IS 'Create jsonb with all usable information about schema';
