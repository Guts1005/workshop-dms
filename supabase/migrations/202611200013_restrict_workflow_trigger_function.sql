-- Trigger-only helpers should not be callable through PostgREST RPC endpoints.
revoke all on function public.guard_work_in_progress_approval()
  from public, anon, authenticated;
