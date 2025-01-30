--DROP FUNCTION gendoc.html_doc_data_uni(adoc_data jsonb, alocation jsonb);

CREATE OR REPLACE FUNCTION gendoc.html_doc_data_uni(adoc_data jsonb, alocation jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
/**
 * Creates a collection of uniwersal information from doc_data
 *
 * @summary create uniwersal for all obejcts information
 *
 * @param {jsonb} adoc_data tabl
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
begin
  if adoc_data is not null then
    l_result := l_result || '<dl>';
    if adoc_data->'author' is not null then
      l_result := l_result || '<dt>'||(alocation->>'author')||'</dt>';
      l_result := l_result || '<dd>';
      l_result := l_result || '<ul>';
      l_result := l_result || 
        string_agg(
          '<li>'||
            coalesce(c->>'author', '')||
            coalesce(' &lt;'||(c->>'email')||'&gt;', '')||
            coalesce(' ('||(c->>'page')||')', '')||
            coalesce(' - '||(c->>'description'), '')||
          '</li>', 
        '') from jsonb_array_elements(adoc_data->'author') c;
      l_result := l_result || '</ul>';
      l_result := l_result || '</dd>';
    end if;
    if adoc_data->'version' is not null then
      l_result := l_result || '<dt>'||(alocation->>'version')||'</dt><dd>'||(adoc_data->>'version')||'</dd>';
    end if;
    if adoc_data->'since' is not null then
      l_result := l_result || '<dt>'||(alocation->>'since')||'</dt><dd>'||(adoc_data->>'since')||'</dd>';
    end if;
    if adoc_data->'created' is not null then
      l_result := l_result || '<dt>'||(alocation->>'created')||'</dt><dd>'||(adoc_data->>'created')||'</dd>';
    end if;
    if adoc_data->'package' is not null then
      l_result := l_result || '<dt>'||(alocation->>'package')||'</dt><dd>'||(adoc_data->>'package')||'</dd>';
    end if;
    if adoc_data->'module' is not null then
      l_result := l_result || '<dt>'||(alocation->>'module')||'</dt><dd>'||(adoc_data->>'module')||'</dd>';
    end if;
    if adoc_data->'public' is not null then
      l_result := l_result || '<dt>'||(alocation->>'public')||'</dt><dd>'||(adoc_data->>'public')||'</dd>';
    end if;
    if adoc_data->'private' is not null then
      l_result := l_result || '<dt>'||(alocation->>'private')||'</dt><dd>'||(adoc_data->>'private')||'</dd>';
    end if;
    if adoc_data->'readonly' is not null then
      l_result := l_result || '<dt>'||(alocation->>'readonly')||'</dt><dd>'||(adoc_data->>'readonly')||'</dd>';
    end if;
    if adoc_data->'alias' is not null then
      l_result := l_result || '<dt>'||(alocation->>'alias')||'</dt><dd>'||(adoc_data->>'alias')||'</dd>';
    end if;
    if adoc_data->'deprecated' is not null then
      l_result := l_result || '<dt>'||(alocation->>'deprecated')||'</dt><dd>'||(adoc_data->>'deprecated')||'</dd>';
    end if;
    if adoc_data->'function' is not null then
      l_result := l_result || '<dt>'||(alocation->>'function')||'</dt><dd>'||(adoc_data->>'function')||'</dd>';
    end if;
    if adoc_data->'variation' is not null then
      l_result := l_result || '<dt>'||(alocation->>'variation')||'</dt><dd>'||(adoc_data->>'variation')||'</dd>';
    end if;
    if adoc_data->'test' is not null then
      l_result := l_result || '<dt>'||(alocation->>'test')||'</dt><dd>'||(adoc_data->>'test')||'</dd>';
    end if;
    if adoc_data->'requires' is not null then
      l_result := l_result || 
        '<dt>'||(alocation->>'requires')||'</dt>'||
        '<dd>'||
          (select '<ul>'||string_agg('<li>'||x||'</li>', '')||'</ul>' from jsonb_array_elements_text(adoc_data->'requires') x)||
        '</dd>';
    end if;
    if adoc_data->'see' is not null then
      l_result := l_result || 
        '<dt>'||(alocation->>'see')||'</dt>'||
        '<dd>'||
          (select '<ul>'||string_agg('<li>'||(x->>'path')||coalesce(' '||(x->>'description'), '')||'</li>', '')||'</ul>' from jsonb_array_elements(adoc_data->'see') x)||
        '</dd>';
    end if;
    if adoc_data->'tutorial' is not null then
      l_result := l_result || 
        '<dt>'||(alocation->>'tutorial')||'</dt>'||
        '<dd>'||
          (select '<ul>'||string_agg('<li>'||x||'</li>', '')||'</ul>' from jsonb_array_elements_text(adoc_data->'tutorial') x)||
        '</dd>';
    end if;
    --
    l_result := l_result || '</dl>';
    --
    if adoc_data->'isue' is not null then
      l_result := l_result || 
        '<h4>'||(alocation->>'isue')||'</h4>'||
        '<p>'||
          (select string_agg(x, '<br />') from jsonb_array_elements_text(adoc_data->>'isue') x)||
        '</p>';
    end if;
    --
    if adoc_data->'todo' is not null then
      l_result := l_result || 
        '<h4>'||(alocation->>'todo')||'</h4>'||
        '<p>'||
          (select string_agg(x, '<br />') from jsonb_array_elements_text(adoc_data->'todo') x)||
        '</p>';
    end if;
    --
    if adoc_data->'example' is not null then
      l_result := l_result || 
        '<h4>'||(alocation->>'example')||'</h4>'||
          (select string_agg('<code><pre>'||trim(e'[ \r\n]+$' from x)||'</pre></code>', '') from jsonb_array_elements_text(adoc_data->'example') x);
    end if;
    --
    if adoc_data->'change' is not null then
      l_result := l_result || 
        '<h4>'||(alocation->>'changes')||'</h4>'||
        '<ul>'||
        (select string_agg(
                  '<li>'||
                    coalesce((x->>'date'), '')||
                    coalesce(' '||(x->>'author'), '')||
                    coalesce(' - '||(x->>'description'), '')||
                  '</li>', '')
           from jsonb_array_elements(adoc_data->'change') x)||
        '</ul>';
    end if;
    --
    if adoc_data->'summary' is not null then
      l_result := l_result || '<h4>'||(alocation->>'summary')||'</h4><p>'||(adoc_data->>'summary')||'</p>';
    end if;
  end if;
  --
  return l_result;
end;
$function$;

ALTER FUNCTION gendoc.html_doc_data_uni(adoc_data jsonb, alocation jsonb) OWNER TO gendoc;
COMMENT ON FUNCTION gendoc.html_doc_data_uni(adoc_data jsonb, alocation jsonb) IS '';
