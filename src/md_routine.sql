--DROP FUNCTION gendoc.md_routine(aroutine jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.md_routine(aroutine jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Create one routine markdown section
 *
 * @param {jsonb} atable tabl
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
  l_doc_data jsonb := aroutine->'doc_data';
begin
  l_result := l_result || e'\n\n### '||(aroutine->>'routine_name')||' <small>('||(aroutine->>'kind')||')</small>';
  l_result := l_result || 
    e'\n\n<code>'||(aroutine->>'routine_name')||'('||
      coalesce((select string_agg(x->>'argument_name'||case when jsonb_typeof(x->'default_value') != 'null' then '<sup>'||(alocation->>'opt_sup')||'</sup>' else '' end, ', ')
         from jsonb_array_elements(aroutine->'arguments') x), '')||
      ')</code> → <code>'||(aroutine->>'returns_type')||'</code>';
  --
  if l_doc_data->>'root' is not null then
    l_result := l_result || e'\n\n'||replace(l_doc_data->>'root', e'\n', e'\n\n');
  elsif aroutine->>'description' is not null then
    l_result := l_result || e'\n\n'||replace(aroutine->>'description', e'\n', e'\n\n');
  end if;
  --
  l_result := l_result || gendoc.md_doc_data_param(l_doc_data, aroutine->'arguments', alocation);
  l_result := l_result || gendoc.md_doc_data_prop(l_doc_data, alocation);
  l_result := l_result || gendoc.md_doc_data_uni(l_doc_data, alocation);
  --
  if l_doc_data->'column' then
    l_result := l_result || e'\n\n#### '||(alocation->>'columns');
    l_result := l_result || e'\n\n'
        '|'||(alocation->>'name_th')||'|'||(alocation->>'data_type_th', '')||
        '|'||(alocation->>'description_th', '')||'|'||
        '|---:|----|----|';
    l_result := l_result || 
      string_agg(e'\n'||
          '|'||coalesce(c->>'name', '')||'|'||coalesce(c->>'type', '')||
          '|'||coalesce(c->>'description', '')||'|',
      '') cols from jsonb_array_elements(l_doc_data->'column') c;
  end if;
  --
  if aroutine->>'returns' != 'void' then
    l_result := l_result || e'\n\n#### '||(alocation->>'returns');
    if l_doc_data->'returns'->>'description' is not null then
      l_result := l_result || e'\n\n'||(l_doc_data->'returns'->>'description');
    end if;
    l_result := l_result || e'\n\n> **'||(alocation->>'data_type')||'** `'||coalesce(aroutine->>'returns', l_doc_data->'returns'->>'type')||'`';
  end if;
  --raise debug '% %', (aroutine->>'routine_name'), length(l_result);
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.md_routine(aroutine jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.md_routine(aroutine jsonb, alocation jsonb) IS '';
