-- All application mutations require an authenticated workshop member.
revoke all on function public.create_application(
  text, text, text, text, text, text, text, boolean, integer, integer, text,
  timestamptz, jsonb
) from public, anon;
grant execute on function public.create_application(
  text, text, text, text, text, text, text, boolean, integer, integer, text,
  timestamptz, jsonb
) to authenticated;

revoke all on function public.record_condition_signoff(
  uuid, text[], text, text, text, boolean, timestamptz, text
) from public, anon;
grant execute on function public.record_condition_signoff(
  uuid, text[], text, text, text, boolean, timestamptz, text
) to authenticated;
