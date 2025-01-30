--DROP FUNCTION gendoc.md_view(aview jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.md_view(aview jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create one view markdown section
 *
 * @param {jsonb} aviewe view
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-29
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
  l_authors text := '';
  l_doc_data jsonb := aview->'doc_data';
begin
  l_result := l_result || e'\n\n### '||(aview->>'view_name')||' <small>('||(aview->>'kind')||')</small>';
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || e'\n\n'||replace(l_doc_data->>'root', e'\n', e'\n\n');
  elsif aview->>'description' is not null then
    l_result := l_result || e'\n\n'||replace(aview->>'description', e'\n', e'\n\n');
  end if;
  --
  l_result := l_result || e'\n\n#### '||(alocation->>'view_columns');
  l_result := l_result || e'\n\n'||
    '|'||(alocation->>'column_no_th')||'|'||(alocation->>'column_name_th')||'|'||(alocation->>'data_type_th')||
    '|'||(alocation->>'description_th')||'|'||
    e'\n|---:|----|----|----|';
  l_result := l_result || 
    string_agg(e'\n'||
      '|'||(c->>'column_no')||'|'||(c->>'column_name')||'|'||(c->>'data_type')||
      '|'||coalesce((c->>'description'), '')||'|',
    '' order by (c->>'column_no')::numeric) cols from jsonb_array_elements(aview->'columns') c;
  --
  l_result := l_result || gendoc.html_doc_data_uni(l_doc_data, alocation);
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.md_view(aview jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.md_view(aview jsonb, alocation jsonb) IS '';
