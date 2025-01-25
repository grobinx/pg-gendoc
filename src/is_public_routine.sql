--DROP FUNCTION gendoc.is_public_routine(aschema name, aroutine text);

CREATE OR REPLACE FUNCTION gendoc.is_public_routine(aschema name, aroutine text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/**
 * Check is routine is set as public. If not set as public, function returns true
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
    return true;
  end if;
  --
  return coalesce((l_doc->'public')::boolean, not (l_doc->'private')::boolean, l_doc->>'access' = 'public', l_doc->>'access' != 'private');
end;
$function$;

ALTER FUNCTION gendoc.is_public_routine(aschema name, aroutine text) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.is_public_routine(aschema name, aroutine text) IS 'Check is routine is set as public. If not set as public, function returns true';
