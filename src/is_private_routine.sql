--DROP FUNCTION gendoc.is_private_routine(aschema name, aroutine text);

CREATE OR REPLACE FUNCTION gendoc.is_private_routine(aschema name, aroutine text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/**
 * Check is routine is set as private. If not set as private, returns false.
 *
 * @param {name} aschema schema name
 * @param {text} aroutine routine identity name
 * @returns {boolean}
 *
 * @author Andrzej Kałuża
 * @created 2025-01-25
 * @version 1.0
 * @since 2.0
 */
declare
  l_doc jsonb;
begin
  l_doc := gendoc.get_routine_doc(aschema, aroutine);
  --
  if l_doc is null then
    return false;
  end if;
  --
  return coalesce((l_doc->'private')::boolean or l_doc->>'access' = 'private', not ((l_doc->'public')::boolean or l_doc->>'access' = 'public'));
end;
$function$;

ALTER FUNCTION gendoc.is_private_routine(aschema name, aroutine text) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.is_private_routine(aschema name, aroutine text) IS 'Check is routine is set as private. If not set as private, returns false.';