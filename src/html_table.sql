--DROP FUNCTION gendoc.html_table(atable jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.html_table(atable jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create one table html section
 *
 * @param {jsonb} atable tabl
 * @param {jsonb} alocation tarnslation strings
 * @returns {text}
 * 
 * @author Andrzej Kałuża
 * @created 2025-01-27
 * @version 1.0
 * @since 2.0
 */
declare
  l_result text := '';
  l_authors text := '';
  l_doc_data jsonb := atable->'doc_data';
begin
  l_result := l_result || '<section>';
  l_result := l_result || '<a name="'||(atable->>'table_name')||'"></a>';
  l_result := l_result || '<h3>'||(atable->>'table_name')||' <small>('||(atable->>'kind')||')</small></h3>';
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || '<p>'||replace(l_doc_data->>'root', e'\n', '<br />')||'</p>';
  elsif atable->>'description' is not null then
    l_result := l_result || '<p>'||replace(atable->>'description', e'\n', '<br />')||'</p>';
  end if;
  --
  l_result := l_result || '<h4>'||(alocation->>'table_columns')||'</h4>';
  l_result := l_result || '<table>';
  l_result := l_result || 
    '<thead><tr>'||
      '<th>'||(alocation->>'column_no_th')||'</th><th>'||(alocation->>'column_name_th')||'</th><th>'||(alocation->>'data_type_th')||'</th>'||
      '<th>'||(alocation->>'default_value_th')||'</th><th>'||(alocation->>'nullable_th')||'</th>'||
      '<th>'||(alocation->>'primary_key_th')||'</th><th>'||(alocation->>'foreign_key_th')||'</th>'||
      '<th>'||(alocation->>'description_th')||'</th>'||
    '</tr></thead>';
  l_result := l_result || '<tbody>';
  l_result := l_result || 
    string_agg(
      '<tr>'||
        '<td>'||(c->>'column_no')||'</td><td>'||(c->>'column_name')||'</td><td>'||(c->>'data_type')||
        '</td><td>'||coalesce(c->>'default_value', '')||'</td><td>'||(c->>'nullable')||
        '</td><td>'||(c->>'primary_key')||'</td><td>'||(c->>'foreign_key')||
        '</td><td>'||coalesce((c->>'description'), '')||'</td>'||
      '</tr>',
    '' order by (c->>'column_no')::numeric) cols from jsonb_array_elements(atable->'columns') c;
  l_result := l_result || '</tbody></table>';
  --
  l_result := l_result || gendoc.html_doc_data_uni(l_doc_data, alocation);
  --
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.html_table(atable jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.html_table(atable jsonb, alocation jsonb) IS '';
