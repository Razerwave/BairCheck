create schema if not exists private;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  phone text,
  role text not null default 'TENANT'
    check (role in ('OWNER', 'TENANT', 'AGENT')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.properties (
  id uuid primary key,
  created_by uuid not null references auth.users (id) on delete restrict,
  name text not null check (char_length(trim(name)) between 1 and 160),
  address text not null check (char_length(trim(address)) between 1 and 500),
  furnishing_type text not null
    check (furnishing_type in (
      'UNFURNISHED',
      'PARTIALLY_FURNISHED',
      'FULLY_FURNISHED'
    )),
  area_square_meters numeric(10, 2) not null check (area_square_meters > 0),
  floor integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.property_members (
  property_id uuid not null references public.properties (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  member_role text not null check (member_role in ('OWNER', 'TENANT', 'AGENT')),
  invited_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (property_id, user_id)
);

create table public.inspections (
  id uuid primary key,
  property_id uuid not null references public.properties (id) on delete restrict,
  inspection_type text not null check (inspection_type in ('MOVE_IN', 'MOVE_OUT')),
  linked_move_in_id uuid references public.inspections (id) on delete restrict,
  status text not null default 'DRAFT'
    check (status in (
      'DRAFT',
      'REVIEW_REQUIRED',
      'REVISION_REQUESTED',
      'APPROVED',
      'PARTIALLY_CONFIRMED',
      'FINALIZED'
    )),
  fill_method text not null check (fill_method in ('SELF', 'TENANT')),
  created_by uuid not null references auth.users (id) on delete restrict,
  assigned_to uuid references auth.users (id) on delete set null,
  tenant_name text,
  tenant_phone text,
  tenant_email text,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint move_out_requires_move_in check (
    inspection_type = 'MOVE_IN' or linked_move_in_id is not null
  )
);

create table public.inspection_rooms (
  id uuid primary key,
  inspection_id uuid not null references public.inspections (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 160),
  is_custom boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.inspection_items (
  id uuid primary key,
  room_id uuid not null references public.inspection_rooms (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 160),
  is_custom boolean not null default false,
  condition text not null default 'GOOD'
    check (condition in (
      'GOOD',
      'MINOR_DAMAGE',
      'DAMAGED',
      'MISSING',
      'NOT_APPLICABLE'
    )),
  notes text not null default '',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.inspection_photos (
  id uuid primary key,
  item_id uuid not null references public.inspection_items (id) on delete cascade,
  uploaded_by uuid not null references auth.users (id) on delete restrict,
  storage_path text,
  upload_status text not null default 'PENDING'
    check (upload_status in ('PENDING', 'UPLOADING', 'UPLOADED', 'FAILED')),
  captured_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.meter_readings (
  id uuid primary key,
  inspection_id uuid not null references public.inspections (id) on delete cascade,
  meter_type text not null check (char_length(trim(meter_type)) between 1 and 100),
  reading numeric(18, 4) not null check (reading >= 0),
  unit text not null check (char_length(trim(unit)) between 1 and 30),
  notes text not null default '',
  created_at timestamptz not null default now()
);

create table public.inspection_keys (
  id uuid primary key,
  inspection_id uuid not null references public.inspections (id) on delete cascade,
  key_type text not null check (char_length(trim(key_type)) between 1 and 100),
  quantity integer not null check (quantity >= 0),
  notes text not null default '',
  created_at timestamptz not null default now()
);

create table public.revision_requests (
  id uuid primary key,
  inspection_id uuid not null references public.inspections (id) on delete cascade,
  room_id uuid references public.inspection_rooms (id) on delete set null,
  item_id uuid references public.inspection_items (id) on delete set null,
  requested_by uuid not null references auth.users (id) on delete restrict,
  request_type text not null check (request_type in ('NEW_PHOTO', 'EDIT_INFORMATION')),
  message text not null check (char_length(trim(message)) between 1 and 2000),
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.inspection_confirmations (
  inspection_id uuid not null references public.inspections (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete restrict,
  party_role text not null check (party_role in ('OWNER', 'TENANT', 'AGENT')),
  confirmed_at timestamptz not null default now(),
  primary key (inspection_id, user_id)
);

create table public.inspection_invitations (
  id uuid primary key default gen_random_uuid(),
  inspection_id uuid not null references public.inspections (id) on delete cascade,
  invited_by uuid not null references auth.users (id) on delete restrict,
  tenant_name text not null,
  phone text not null,
  email text,
  token_hash text not null unique,
  status text not null default 'PENDING'
    check (status in ('PENDING', 'ACCEPTED', 'EXPIRED', 'REVOKED')),
  expires_at timestamptz not null,
  accepted_by uuid references auth.users (id) on delete set null,
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  check (expires_at > created_at)
);

create table public.app_status (
  id boolean primary key default true check (id),
  maintenance boolean not null default false,
  title text not null default '',
  message text not null default '',
  minimum_version text,
  updated_at timestamptz not null default now()
);

create table public.feedback (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  category text not null
    check (category in ('IDEA', 'BUG', 'INSPECTION_ACT', 'BILLING', 'HELP', 'OTHER')),
  description text not null check (char_length(trim(description)) between 1 and 5000),
  attachment_path text,
  created_at timestamptz not null default now()
);

create index properties_created_by_idx on public.properties (created_by);
create index property_members_user_id_idx on public.property_members (user_id, property_id);
create index inspections_property_type_updated_idx
  on public.inspections (property_id, inspection_type, updated_at desc);
create index inspections_created_by_idx on public.inspections (created_by);
create index inspections_assigned_to_idx on public.inspections (assigned_to)
  where assigned_to is not null;
create index inspections_linked_move_in_idx on public.inspections (linked_move_in_id)
  where linked_move_in_id is not null;
create index inspection_rooms_inspection_idx
  on public.inspection_rooms (inspection_id, sort_order);
create index inspection_items_room_idx on public.inspection_items (room_id, sort_order);
create index inspection_photos_item_idx on public.inspection_photos (item_id);
create index inspection_photos_uploaded_by_idx on public.inspection_photos (uploaded_by);
create index meter_readings_inspection_idx on public.meter_readings (inspection_id);
create index inspection_keys_inspection_idx on public.inspection_keys (inspection_id);
create index revision_requests_inspection_idx
  on public.revision_requests (inspection_id, created_at desc);
create index revision_requests_room_idx on public.revision_requests (room_id)
  where room_id is not null;
create index revision_requests_item_idx on public.revision_requests (item_id)
  where item_id is not null;
create index confirmations_user_idx on public.inspection_confirmations (user_id);
create index invitations_inspection_idx on public.inspection_invitations (inspection_id);
create index invitations_pending_expiry_idx on public.inspection_invitations (expires_at)
  where status = 'PENDING';
create index feedback_user_created_idx on public.feedback (user_id, created_at desc);

create or replace function private.can_access_property(target_property_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null and (
    exists (
      select 1
      from public.properties property
      where property.id = target_property_id
        and property.created_by = (select auth.uid())
    )
    or exists (
      select 1
      from public.property_members member
      where member.property_id = target_property_id
        and member.user_id = (select auth.uid())
    )
  );
$$;

create or replace function private.can_manage_property(target_property_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null and (
    exists (
      select 1
      from public.properties property
      where property.id = target_property_id
        and property.created_by = (select auth.uid())
    )
    or exists (
      select 1
      from public.property_members member
      where member.property_id = target_property_id
        and member.user_id = (select auth.uid())
        and member.member_role in ('OWNER', 'AGENT')
    )
  );
$$;

create or replace function private.can_access_inspection(target_inspection_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (select auth.uid()) is not null and exists (
    select 1
    from public.inspections inspection
    where inspection.id = target_inspection_id
      and (
        inspection.created_by = (select auth.uid())
        or inspection.assigned_to = (select auth.uid())
        or private.can_access_property(inspection.property_id)
      )
  );
$$;

create or replace function private.can_access_storage_path(object_name text)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  inspection_id_text text;
begin
  inspection_id_text := split_part(object_name, '/', 2);
  if inspection_id_text = '' then
    return false;
  end if;
  return private.can_access_inspection(inspection_id_text::uuid);
exception when invalid_text_representation then
  return false;
end;
$$;

revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;
revoke execute on all functions in schema private from public, anon;
grant execute on function private.can_access_property(uuid) to authenticated;
grant execute on function private.can_manage_property(uuid) to authenticated;
grant execute on function private.can_access_inspection(uuid) to authenticated;
grant execute on function private.can_access_storage_path(text) to authenticated;

alter table public.profiles enable row level security;
alter table public.properties enable row level security;
alter table public.property_members enable row level security;
alter table public.inspections enable row level security;
alter table public.inspection_rooms enable row level security;
alter table public.inspection_items enable row level security;
alter table public.inspection_photos enable row level security;
alter table public.meter_readings enable row level security;
alter table public.inspection_keys enable row level security;
alter table public.revision_requests enable row level security;
alter table public.inspection_confirmations enable row level security;
alter table public.inspection_invitations enable row level security;
alter table public.feedback enable row level security;
alter table public.app_status enable row level security;

create policy profiles_select_own on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);
create policy profiles_insert_own on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) = id);
create policy profiles_update_own on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy properties_select_members on public.properties
  for select to authenticated
  using ((select private.can_access_property(id)));
create policy properties_insert_owner on public.properties
  for insert to authenticated
  with check ((select auth.uid()) = created_by);
create policy properties_update_managers on public.properties
  for update to authenticated
  using ((select private.can_manage_property(id)))
  with check ((select private.can_manage_property(id)));
create policy properties_delete_creator on public.properties
  for delete to authenticated
  using ((select auth.uid()) = created_by);

create policy property_members_select_members on public.property_members
  for select to authenticated
  using ((select private.can_access_property(property_id)));
create policy property_members_insert_managers on public.property_members
  for insert to authenticated
  with check ((select private.can_manage_property(property_id)));
create policy property_members_update_managers on public.property_members
  for update to authenticated
  using ((select private.can_manage_property(property_id)))
  with check ((select private.can_manage_property(property_id)));
create policy property_members_delete_managers on public.property_members
  for delete to authenticated
  using ((select private.can_manage_property(property_id)));

create policy inspections_select_participants on public.inspections
  for select to authenticated
  using ((select private.can_access_inspection(id)));
create policy inspections_insert_participants on public.inspections
  for insert to authenticated
  with check (
    (select auth.uid()) = created_by
    and (select private.can_access_property(property_id))
  );
create policy inspections_update_participants on public.inspections
  for update to authenticated
  using (
    (select auth.uid()) = created_by
    or (select auth.uid()) = assigned_to
    or (select private.can_manage_property(property_id))
  )
  with check (
    (select auth.uid()) = created_by
    or (select auth.uid()) = assigned_to
    or (select private.can_manage_property(property_id))
  );

create policy rooms_select_participants on public.inspection_rooms
  for select to authenticated
  using ((select private.can_access_inspection(inspection_id)));
create policy rooms_insert_participants on public.inspection_rooms
  for insert to authenticated
  with check ((select private.can_access_inspection(inspection_id)));
create policy rooms_update_participants on public.inspection_rooms
  for update to authenticated
  using ((select private.can_access_inspection(inspection_id)))
  with check ((select private.can_access_inspection(inspection_id)));
create policy rooms_delete_participants on public.inspection_rooms
  for delete to authenticated
  using ((select private.can_access_inspection(inspection_id)));

create policy items_select_participants on public.inspection_items
  for select to authenticated
  using (exists (
    select 1 from public.inspection_rooms room
    where room.id = room_id
      and (select private.can_access_inspection(room.inspection_id))
  ));
create policy items_insert_participants on public.inspection_items
  for insert to authenticated
  with check (exists (
    select 1 from public.inspection_rooms room
    where room.id = room_id
      and (select private.can_access_inspection(room.inspection_id))
  ));
create policy items_update_participants on public.inspection_items
  for update to authenticated
  using (exists (
    select 1 from public.inspection_rooms room
    where room.id = room_id
      and (select private.can_access_inspection(room.inspection_id))
  ))
  with check (exists (
    select 1 from public.inspection_rooms room
    where room.id = room_id
      and (select private.can_access_inspection(room.inspection_id))
  ));
create policy items_delete_participants on public.inspection_items
  for delete to authenticated
  using (exists (
    select 1 from public.inspection_rooms room
    where room.id = room_id
      and (select private.can_access_inspection(room.inspection_id))
  ));

create policy photos_select_participants on public.inspection_photos
  for select to authenticated
  using (exists (
    select 1
    from public.inspection_items item
    join public.inspection_rooms room on room.id = item.room_id
    where item.id = item_id
      and (select private.can_access_inspection(room.inspection_id))
  ));
create policy photos_insert_uploader on public.inspection_photos
  for insert to authenticated
  with check (
    (select auth.uid()) = uploaded_by
    and exists (
      select 1
      from public.inspection_items item
      join public.inspection_rooms room on room.id = item.room_id
      where item.id = item_id
        and (select private.can_access_inspection(room.inspection_id))
    )
  );
create policy photos_update_uploader on public.inspection_photos
  for update to authenticated
  using ((select auth.uid()) = uploaded_by)
  with check ((select auth.uid()) = uploaded_by);
create policy photos_delete_uploader on public.inspection_photos
  for delete to authenticated
  using ((select auth.uid()) = uploaded_by);

create policy meters_participants_all on public.meter_readings
  for all to authenticated
  using ((select private.can_access_inspection(inspection_id)))
  with check ((select private.can_access_inspection(inspection_id)));
create policy keys_participants_all on public.inspection_keys
  for all to authenticated
  using ((select private.can_access_inspection(inspection_id)))
  with check ((select private.can_access_inspection(inspection_id)));
create policy revisions_participants_all on public.revision_requests
  for all to authenticated
  using ((select private.can_access_inspection(inspection_id)))
  with check (
    (select private.can_access_inspection(inspection_id))
    and (select auth.uid()) = requested_by
  );
create policy confirmations_participants_select on public.inspection_confirmations
  for select to authenticated
  using ((select private.can_access_inspection(inspection_id)));
create policy confirmations_own_insert on public.inspection_confirmations
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and (select private.can_access_inspection(inspection_id))
  );
create policy invitations_managers_all on public.inspection_invitations
  for all to authenticated
  using (exists (
    select 1 from public.inspections inspection
    where inspection.id = inspection_id
      and (select private.can_manage_property(inspection.property_id))
  ))
  with check (
    (select auth.uid()) = invited_by
    and exists (
      select 1 from public.inspections inspection
      where inspection.id = inspection_id
        and (select private.can_manage_property(inspection.property_id))
    )
  );
create policy app_status_readable on public.app_status
  for select to anon, authenticated
  using (true);

create policy feedback_select_own on public.feedback
  for select to authenticated
  using ((select auth.uid()) = user_id);
create policy feedback_insert_own on public.feedback
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy inspection_storage_select_participants on storage.objects
  for select to authenticated
  using (
    bucket_id = 'inspection-evidence'
    and (select private.can_access_storage_path(name))
  );
create policy inspection_storage_insert_participants on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'inspection-evidence'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and (select private.can_access_storage_path(name))
  );
create policy inspection_storage_update_uploader on storage.objects
  for update to authenticated
  using (
    bucket_id = 'inspection-evidence'
    and owner_id = (select auth.uid()::text)
  )
  with check (
    bucket_id = 'inspection-evidence'
    and owner_id = (select auth.uid()::text)
  );
create policy inspection_storage_delete_uploader on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'inspection-evidence'
    and owner_id = (select auth.uid()::text)
  );

create policy feedback_storage_select_own on storage.objects
  for select to authenticated
  using (
    bucket_id = 'feedback-attachments'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy feedback_storage_insert_own on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'feedback-attachments'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy feedback_storage_delete_own on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'feedback-attachments'
    and owner_id = (select auth.uid()::text)
  );

revoke all on all tables in schema public from anon;
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.properties to authenticated;
grant select, insert, update, delete on public.property_members to authenticated;
grant select, insert, update on public.inspections to authenticated;
grant select, insert, update, delete on public.inspection_rooms to authenticated;
grant select, insert, update, delete on public.inspection_items to authenticated;
grant select, insert, update, delete on public.inspection_photos to authenticated;
grant select, insert, update, delete on public.meter_readings to authenticated;
grant select, insert, update, delete on public.inspection_keys to authenticated;
grant select, insert, update, delete on public.revision_requests to authenticated;
grant select, insert on public.inspection_confirmations to authenticated;
grant select, insert, update, delete on public.inspection_invitations to authenticated;
grant select, insert on public.feedback to authenticated;
grant usage on schema public to anon;
grant select on public.app_status to anon, authenticated;
grant usage, select on sequence public.feedback_id_seq to authenticated;
