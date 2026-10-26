-- Run once in Supabase: SQL Editor > New query > paste > Run.
-- The table has row level security with no policies, so the public key cannot read or write it directly.
-- The page uses the two functions below, and each needs the shared code to find its rows.
create table if not exists tri_docs (
  code text not null,
  id text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (code, id)
);
alter table tri_docs enable row level security;

create or replace function get_doc(p_code text, p_id text) returns jsonb
language sql security definer set search_path = public as $$
  select data from tri_docs where code = p_code and id = p_id;
$$;

create or replace function set_doc(p_code text, p_id text, p_data jsonb) returns void
language plpgsql security definer set search_path = public as $$
begin
  if length(p_code) < 8 then raise exception 'code too short'; end if;
  if pg_column_size(p_data) > 500000 then raise exception 'document too large'; end if;
  insert into tri_docs (code, id, data) values (p_code, p_id, p_data)
  on conflict (code, id) do update set data = excluded.data, updated_at = now();
end $$;

grant execute on function get_doc(text, text) to anon;
grant execute on function set_doc(text, text, jsonb) to anon;
