--DROP FUNCTION gendoc.get_routine_doc(aschema name, aroutine text);

CREATE OR REPLACE FUNCTION gendoc.get_routine_doc(aschema name, aroutine text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
/**
 * Function parse jsdoc data from body by identity name.
 *
 * @summary parse one routine doc
 *
 * @param {name} aschema schema name
 * @param {text} aroutine routine identity name
 * @returns {jsonb}
 *
 * @author Andrzej Kałuża
 * @created 2025-01-25
 * @version 1.0
 * @since 2.0
 */
begin
  return gendoc.jsdoc_parse(substring(pg_get_functiondef(p.oid) from '\/\*\*.*?\*\/'))
    from pg_catalog.pg_proc p
         join pg_catalog.pg_namespace n on n.oid = p.pronamespace
   where n.nspname = aschema
     and p.proname||'('||coalesce(pg_get_function_identity_arguments(p.oid), '')||')' = aroutine;
end;
$function$;

ALTER FUNCTION gendoc.get_routine_doc(aschema name, aroutine text) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.get_routine_doc(aschema name, aroutine text) IS '';
