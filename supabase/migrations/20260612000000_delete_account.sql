-- SafarShare — account deletion RPC
-- Project: yersmlrpbjpbzkiawjtr (Supabase)
--
-- The app's "Delete account" flow needs a server-side cascade that an
-- ordinary authenticated user can trigger for THEIR OWN account only.
-- A plain client-side delete can't do this because:
--   * there is intentionally no DELETE policy on public.users (RLS would
--     block deleting the profile row), and
--   * rides.driver_id, bookings.passenger_id and transactions.user_id all
--     reference users with ON DELETE RESTRICT, so the dependents must be
--     removed first, in order.
--
-- This SECURITY DEFINER function runs with owner privileges (bypassing
-- RLS) but still keys everything off auth.uid(), so a caller can only ever
-- delete their own account. Replaces the never-built `delete_account`
-- edge function the client used to POST to.

begin;

create or replace function public.delete_account(p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  -- Order matters: clear everything that references public.users with
  -- ON DELETE RESTRICT before deleting the profile row itself.

  -- 1. This user's bookings as a passenger.
  delete from public.bookings where passenger_id = v_uid;

  -- 2. This user's rides as a driver. bookings.ride_id is ON DELETE
  --    CASCADE, so any passengers' bookings on these rides go too.
  delete from public.rides where driver_id = v_uid;

  -- 3. This user's transactions. (Hard-deleted in the MVP — there is no
  --    anonymisation column to repoint them to.)
  delete from public.transactions where user_id = v_uid;

  -- 4. This user's vehicles. (vehicles.owner_id is ON DELETE CASCADE, but
  --    delete explicitly so the ordering is obvious and self-documenting.)
  delete from public.vehicles where owner_id = v_uid;

  -- 5. Finally the profile row.
  delete from public.users where id = v_uid;
end;
$$;

-- Only signed-in users may call it; never anon/public. The function's own
-- auth.uid() check scopes each call to the caller's own account.
revoke all on function public.delete_account(text) from public, anon;
grant execute on function public.delete_account(text) to authenticated;

commit;
