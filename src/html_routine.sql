--DROP FUNCTION gendoc.html_routine(aroutine jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.html_routine(aroutine jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create one routine html section
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
  l_doc_data jsonb := aroutine->'doc_data';
begin
  l_result := l_result || '<section>';
  l_result := l_result || '<a name="'||(aroutine->>'routine_name')||'"></a>';
  l_result := l_result || '<h3>'||(aroutine->>'routine_name')||' <small>('||(aroutine->>'kind')||')</small></h3>';
  l_result := l_result || 
    '<code>'||(aroutine->>'routine_name')||'('||
      coalesce((select string_agg(x->>'argument_name'||case when jsonb_typeof(x->'default_value') != 'null' then '<sup>'||(alocation->>'opt_sup')||'</sup>' else '' end, ', ')
         from jsonb_array_elements(aroutine->'arguments') x), '')||
      ') <span>→ '||(aroutine->>'returns_type')||
    '</code>';
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || '<p>'||replace(l_doc_data->>'root', e'\n', '<br />')||'</p>';
  elsif aroutine->>'description' is not null then
    l_result := l_result || '<p>'||replace(aroutine->>'description', e'\n', '<br />')||'</p>';
  end if;
  --
  --raise debug '% %', (aroutine->>'routine_name'), length(l_result);
  l_result := l_result || gendoc.html_doc_data_param(l_doc_data, aroutine->'arguments', alocation);
  l_result := l_result || gendoc.html_doc_data_prop(l_doc_data, alocation);
  l_result := l_result || gendoc.html_doc_data_uni(l_doc_data, alocation);
  --
  if l_doc_data->'column' then
    l_result := l_result || '<h4>'||(alocation->>'columns')||'</h4>';
    l_result := l_result || '<table>';
    l_result := l_result || 
      '<thead><tr>'||
        '<th>'||(alocation->>'name_th')||'</th><th>'||(alocation->>'data_type_th', '')||'</th>'||
        '<th>'||(alocation->>'description_th', '')||'</th>'||
      '</tr></thead>';
    l_result := l_result || '<tbody>';
    l_result := l_result || 
      string_agg(
        '<tr>'||
          '<td>'||coalesce(c->>'name', '')||'</td><td>'||coalesce(c->>'type', '')||'</td>'||
          '<td>'||coalesce(c->>'description', '')||'</td>'||
        '</tr>',
      '') cols from jsonb_array_elements(l_doc_data->'column') c;
    l_result := l_result || '</tbody></table>';
  end if;
  --
  if aroutine->>'returns' != 'void' then
    l_result := l_result || '<h4>'||(alocation->>'returns')||'</h4>';
    if l_doc_data->'returns'->>'description' is not null then
      l_result := l_result || '<p>'||replace(l_doc_data->'returns'->>'description', e'\n', '<br />')||'</p>';
    end if;
    l_result := l_result || '<dl><dt>'||(alocation->>'data_type')||'</dt><dd><code>'||coalesce(aroutine->>'returns', l_doc_data->'returns'->>'type')||'</code></dd></dl>';
  end if;
  --
  l_result := l_result || '</section>';
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.html_routine(aroutine jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.html_routine(aroutine jsonb, alocation jsonb) IS '';
