SET local check_function_bodies = off;

CREATE SCHEMA "private";

CREATE TABLE "public"."feedback" (
  "id"              bigint                   GENERATED ALWAYS AS IDENTITY NOT NULL,
  "user_id"         uuid                     NOT NULL,
  "category"        text                     NOT NULL,
  "description"     text                     NOT NULL,
  "attachment_path" text,
  "created_at"      timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "feedback_category_check" CHECK ((category = ANY (ARRAY['IDEA'::text, 'BUG'::text, 'INSPECTION_ACT'::text, 'BILLING'::text, 'HELP'::text, 'OTHER'::text]))),
  CONSTRAINT "feedback_description_check" CHECK (((char_length(TRIM(BOTH FROM description)) >= 1) AND (char_length(TRIM(BOTH FROM description)) <= 5000))),
  CONSTRAINT "feedback_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."feedback"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."inspection_confirmations" (
  "inspection_id" uuid                     NOT NULL,
  "user_id"       uuid                     NOT NULL,
  "party_role"    text                     NOT NULL,
  "confirmed_at"  timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "inspection_confirmations_party_role_check" CHECK ((party_role = ANY (ARRAY['OWNER'::text, 'TENANT'::text, 'AGENT'::text]))),
  CONSTRAINT "inspection_confirmations_pkey" PRIMARY KEY (inspection_id, user_id)
);

ALTER TABLE "public"."inspection_confirmations"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."inspection_invitations" (
  "id"            uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "inspection_id" uuid                     NOT NULL,
  "invited_by"    uuid                     NOT NULL,
  "tenant_name"   text                     NOT NULL,
  "phone"         text                     NOT NULL,
  "email"         text,
  "token_hash"    text                     NOT NULL,
  "status"        text                     NOT NULL DEFAULT 'PENDING'::text,
  "expires_at"    timestamp with time zone NOT NULL,
  "accepted_by"   uuid,
  "accepted_at"   timestamp with time zone,
  "created_at"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "inspection_invitations_check" CHECK ((expires_at > created_at)),
  CONSTRAINT "inspection_invitations_pkey" PRIMARY KEY (id),
  CONSTRAINT "inspection_invitations_status_check" CHECK ((status = ANY (ARRAY['PENDING'::text, 'ACCEPTED'::text, 'EXPIRED'::text, 'REVOKED'::text]))),
  CONSTRAINT "inspection_invitations_token_hash_key" UNIQUE (token_hash)
);

ALTER TABLE "public"."inspection_invitations"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."inspection_items" (
  "id"         uuid                     NOT NULL,
  "room_id"    uuid                     NOT NULL,
  "name"       text                     NOT NULL,
  "is_custom"  boolean                  NOT NULL DEFAULT false,
  "condition"  text                     NOT NULL DEFAULT 'GOOD'::text,
  "notes"      text                     NOT NULL DEFAULT ''::text,
  "sort_order" integer                  NOT NULL DEFAULT 0,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "inspection_items_condition_check" CHECK ((condition = ANY (ARRAY['GOOD'::text, 'MINOR_DAMAGE'::text, 'DAMAGED'::text, 'MISSING'::text, 'NOT_APPLICABLE'::text]))),
  CONSTRAINT "inspection_items_name_check" CHECK (((char_length(TRIM(BOTH FROM name)) >= 1) AND (char_length(TRIM(BOTH FROM name)) <= 160))),
  CONSTRAINT "inspection_items_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."inspection_items"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."inspection_keys" (
  "id"            uuid                     NOT NULL,
  "inspection_id" uuid                     NOT NULL,
  "key_type"      text                     NOT NULL,
  "quantity"      integer                  NOT NULL,
  "notes"         text                     NOT NULL DEFAULT ''::text,
  "created_at"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "inspection_keys_key_type_check" CHECK (((char_length(TRIM(BOTH FROM key_type)) >= 1) AND (char_length(TRIM(BOTH FROM key_type)) <= 100))),
  CONSTRAINT "inspection_keys_pkey" PRIMARY KEY (id),
  CONSTRAINT "inspection_keys_quantity_check" CHECK ((quantity >= 0))
);

ALTER TABLE "public"."inspection_keys"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."inspection_photos" (
  "id"            uuid                     NOT NULL,
  "item_id"       uuid                     NOT NULL,
  "uploaded_by"   uuid                     NOT NULL,
  "storage_path"  text,
  "upload_status" text                     NOT NULL DEFAULT 'PENDING'::text,
  "captured_at"   timestamp with time zone NOT NULL DEFAULT now(),
  "created_at"    timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "inspection_photos_pkey" PRIMARY KEY (id),
  CONSTRAINT "inspection_photos_upload_status_check" CHECK ((upload_status = ANY (ARRAY['PENDING'::text, 'UPLOADING'::text, 'UPLOADED'::text, 'FAILED'::text])))
);

ALTER TABLE "public"."inspection_photos"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."inspection_rooms" (
  "id"            uuid                     NOT NULL,
  "inspection_id" uuid                     NOT NULL,
  "name"          text                     NOT NULL,
  "is_custom"     boolean                  NOT NULL DEFAULT false,
  "sort_order"    integer                  NOT NULL DEFAULT 0,
  "created_at"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "inspection_rooms_name_check" CHECK (((char_length(TRIM(BOTH FROM name)) >= 1) AND (char_length(TRIM(BOTH FROM name)) <= 160))),
  CONSTRAINT "inspection_rooms_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."inspection_rooms"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."inspections" (
  "id"                uuid                     NOT NULL,
  "property_id"       uuid                     NOT NULL,
  "inspection_type"   text                     NOT NULL,
  "linked_move_in_id" uuid,
  "status"            text                     NOT NULL DEFAULT 'DRAFT'::text,
  "fill_method"       text                     NOT NULL,
  "created_by"        uuid                     NOT NULL,
  "assigned_to"       uuid,
  "tenant_name"       text,
  "tenant_phone"      text,
  "tenant_email"      text,
  "submitted_at"      timestamp with time zone,
  "reviewed_at"       timestamp with time zone,
  "created_at"        timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"        timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "inspections_fill_method_check" CHECK ((fill_method = ANY (ARRAY['SELF'::text, 'TENANT'::text]))),
  CONSTRAINT "inspections_inspection_type_check" CHECK ((inspection_type = ANY (ARRAY['MOVE_IN'::text, 'MOVE_OUT'::text]))),
  CONSTRAINT "inspections_pkey" PRIMARY KEY (id),
  CONSTRAINT "inspections_status_check"
    CHECK ((status = ANY (ARRAY['DRAFT'::text, 'REVIEW_REQUIRED'::text, 'REVISION_REQUESTED'::text, 'APPROVED'::text, 'PARTIALLY_CONFIRMED'::text, 'FINALIZED'::text]))),
  CONSTRAINT "move_out_requires_move_in" CHECK (((inspection_type = 'MOVE_IN'::text) OR (linked_move_in_id IS NOT NULL)))
);

ALTER TABLE "public"."inspections"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."meter_readings" (
  "id"            uuid                     NOT NULL,
  "inspection_id" uuid                     NOT NULL,
  "meter_type"    text                     NOT NULL,
  "reading"       numeric(18,4)            NOT NULL,
  "unit"          text                     NOT NULL,
  "notes"         text                     NOT NULL DEFAULT ''::text,
  "created_at"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "meter_readings_meter_type_check" CHECK (((char_length(TRIM(BOTH FROM meter_type)) >= 1) AND (char_length(TRIM(BOTH FROM meter_type)) <= 100))),
  CONSTRAINT "meter_readings_pkey" PRIMARY KEY (id),
  CONSTRAINT "meter_readings_reading_check" CHECK ((reading >= (0)::numeric)),
  CONSTRAINT "meter_readings_unit_check" CHECK (((char_length(TRIM(BOTH FROM unit)) >= 1) AND (char_length(TRIM(BOTH FROM unit)) <= 30)))
);

ALTER TABLE "public"."meter_readings"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."profiles" (
  "id"         uuid                     NOT NULL,
  "full_name"  text                     NOT NULL,
  "phone"      text,
  "role"       text                     NOT NULL DEFAULT 'TENANT'::text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "profiles_pkey" PRIMARY KEY (id),
  CONSTRAINT "profiles_role_check" CHECK ((role = ANY (ARRAY['OWNER'::text, 'TENANT'::text, 'AGENT'::text])))
);

ALTER TABLE "public"."profiles"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."properties" (
  "id"                 uuid                     NOT NULL,
  "created_by"         uuid                     NOT NULL,
  "name"               text                     NOT NULL,
  "address"            text                     NOT NULL,
  "furnishing_type"    text                     NOT NULL,
  "area_square_meters" numeric(10,2)            NOT NULL,
  "floor"              integer                  NOT NULL,
  "created_at"         timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"         timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "properties_address_check" CHECK (((char_length(TRIM(BOTH FROM address)) >= 1) AND (char_length(TRIM(BOTH FROM address)) <= 500))),
  CONSTRAINT "properties_area_square_meters_check" CHECK ((area_square_meters > (0)::numeric)),
  CONSTRAINT "properties_furnishing_type_check" CHECK ((furnishing_type = ANY (ARRAY['UNFURNISHED'::text, 'PARTIALLY_FURNISHED'::text, 'FULLY_FURNISHED'::text]))),
  CONSTRAINT "properties_name_check" CHECK (((char_length(TRIM(BOTH FROM name)) >= 1) AND (char_length(TRIM(BOTH FROM name)) <= 160))),
  CONSTRAINT "properties_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."properties"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."property_members" (
  "property_id" uuid                     NOT NULL,
  "user_id"     uuid                     NOT NULL,
  "member_role" text                     NOT NULL,
  "invited_by"  uuid,
  "created_at"  timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "property_members_member_role_check" CHECK ((member_role = ANY (ARRAY['OWNER'::text, 'TENANT'::text, 'AGENT'::text]))),
  CONSTRAINT "property_members_pkey" PRIMARY KEY (property_id, user_id)
);

ALTER TABLE "public"."property_members"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."revision_requests" (
  "id"            uuid                     NOT NULL,
  "inspection_id" uuid                     NOT NULL,
  "room_id"       uuid,
  "item_id"       uuid,
  "requested_by"  uuid                     NOT NULL,
  "request_type"  text                     NOT NULL,
  "message"       text                     NOT NULL,
  "resolved_at"   timestamp with time zone,
  "created_at"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "revision_requests_message_check" CHECK (((char_length(TRIM(BOTH FROM message)) >= 1) AND (char_length(TRIM(BOTH FROM message)) <= 2000))),
  CONSTRAINT "revision_requests_pkey" PRIMARY KEY (id),
  CONSTRAINT "revision_requests_request_type_check" CHECK ((request_type = ANY (ARRAY['NEW_PHOTO'::text, 'EDIT_INFORMATION'::text])))
);

ALTER TABLE "public"."revision_requests"
  ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION private.can_access_inspection (
  target_inspection_id uuid
)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION private.can_access_property (
  target_property_id uuid
)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION private.can_access_storage_path (
  object_name text
)
  RETURNS boolean
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
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
$function$;

CREATE OR REPLACE FUNCTION private.can_manage_property (
  target_property_id uuid
)
  RETURNS boolean
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
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
$function$;

ALTER TABLE "public"."feedback"
  ADD CONSTRAINT "feedback_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE "public"."inspection_confirmations"
  ADD CONSTRAINT "inspection_confirmations_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE RESTRICT;

ALTER TABLE "public"."inspection_invitations"
  ADD CONSTRAINT "inspection_invitations_accepted_by_fkey" FOREIGN KEY (accepted_by) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE "public"."inspection_invitations"
  ADD CONSTRAINT "inspection_invitations_invited_by_fkey" FOREIGN KEY (invited_by) REFERENCES auth.users(id) ON DELETE RESTRICT;

ALTER TABLE "public"."inspection_photos"
  ADD CONSTRAINT "inspection_photos_item_id_fkey" FOREIGN KEY (item_id) REFERENCES public.inspection_items(id) ON DELETE CASCADE;

ALTER TABLE "public"."inspection_photos"
  ADD CONSTRAINT "inspection_photos_uploaded_by_fkey" FOREIGN KEY (uploaded_by) REFERENCES auth.users(id) ON DELETE RESTRICT;

ALTER TABLE "public"."inspection_items"
  ADD CONSTRAINT "inspection_items_room_id_fkey" FOREIGN KEY (room_id) REFERENCES public.inspection_rooms(id) ON DELETE CASCADE;

ALTER TABLE "public"."inspections"
  ADD CONSTRAINT "inspections_assigned_to_fkey" FOREIGN KEY (assigned_to) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE "public"."inspections"
  ADD CONSTRAINT "inspections_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE RESTRICT;

ALTER TABLE "public"."inspection_confirmations"
  ADD CONSTRAINT "inspection_confirmations_inspection_id_fkey" FOREIGN KEY (inspection_id) REFERENCES public.inspections(id) ON DELETE CASCADE;

ALTER TABLE "public"."inspection_invitations"
  ADD CONSTRAINT "inspection_invitations_inspection_id_fkey" FOREIGN KEY (inspection_id) REFERENCES public.inspections(id) ON DELETE CASCADE;

ALTER TABLE "public"."inspection_keys"
  ADD CONSTRAINT "inspection_keys_inspection_id_fkey" FOREIGN KEY (inspection_id) REFERENCES public.inspections(id) ON DELETE CASCADE;

ALTER TABLE "public"."inspection_rooms"
  ADD CONSTRAINT "inspection_rooms_inspection_id_fkey" FOREIGN KEY (inspection_id) REFERENCES public.inspections(id) ON DELETE CASCADE;

ALTER TABLE "public"."inspections"
  ADD CONSTRAINT "inspections_linked_move_in_id_fkey" FOREIGN KEY (linked_move_in_id) REFERENCES public.inspections(id) ON DELETE RESTRICT;

ALTER TABLE "public"."meter_readings"
  ADD CONSTRAINT "meter_readings_inspection_id_fkey" FOREIGN KEY (inspection_id) REFERENCES public.inspections(id) ON DELETE CASCADE;

ALTER TABLE "public"."profiles"
  ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE "public"."properties"
  ADD CONSTRAINT "properties_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE RESTRICT;

ALTER TABLE "public"."inspections"
  ADD CONSTRAINT "inspections_property_id_fkey" FOREIGN KEY (property_id) REFERENCES public.properties(id) ON DELETE RESTRICT;

ALTER TABLE "public"."property_members"
  ADD CONSTRAINT "property_members_invited_by_fkey" FOREIGN KEY (invited_by) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE "public"."property_members"
  ADD CONSTRAINT "property_members_property_id_fkey" FOREIGN KEY (property_id) REFERENCES public.properties(id) ON DELETE CASCADE;

ALTER TABLE "public"."property_members"
  ADD CONSTRAINT "property_members_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE "public"."revision_requests"
  ADD CONSTRAINT "revision_requests_inspection_id_fkey" FOREIGN KEY (inspection_id) REFERENCES public.inspections(id) ON DELETE CASCADE;

ALTER TABLE "public"."revision_requests"
  ADD CONSTRAINT "revision_requests_item_id_fkey" FOREIGN KEY (item_id) REFERENCES public.inspection_items(id) ON DELETE SET NULL;

ALTER TABLE "public"."revision_requests"
  ADD CONSTRAINT "revision_requests_requested_by_fkey" FOREIGN KEY (requested_by) REFERENCES auth.users(id) ON DELETE RESTRICT;

ALTER TABLE "public"."revision_requests"
  ADD CONSTRAINT "revision_requests_room_id_fkey" FOREIGN KEY (room_id) REFERENCES public.inspection_rooms(id) ON DELETE SET NULL;

CREATE INDEX confirmations_user_idx ON public.inspection_confirmations USING btree (user_id);

CREATE INDEX feedback_user_created_idx ON public.feedback USING btree (user_id, created_at DESC);

CREATE INDEX inspection_items_room_idx ON public.inspection_items USING btree (room_id, sort_order);

CREATE INDEX inspection_keys_inspection_idx ON public.inspection_keys USING btree (inspection_id);

CREATE INDEX inspection_photos_item_idx ON public.inspection_photos USING btree (item_id);

CREATE INDEX inspection_photos_uploaded_by_idx ON public.inspection_photos USING btree (uploaded_by);

CREATE INDEX inspection_rooms_inspection_idx ON public.inspection_rooms USING btree (inspection_id, sort_order);

CREATE INDEX inspections_assigned_to_idx ON public.inspections USING btree (assigned_to)
  WHERE (assigned_to IS NOT NULL);

CREATE INDEX inspections_created_by_idx ON public.inspections USING btree (created_by);

CREATE INDEX inspections_linked_move_in_idx ON public.inspections USING btree (linked_move_in_id)
  WHERE (linked_move_in_id IS NOT NULL);

CREATE INDEX inspections_property_type_updated_idx ON public.inspections USING btree (property_id, inspection_type, updated_at DESC);

CREATE INDEX invitations_inspection_idx ON public.inspection_invitations USING btree (inspection_id);

CREATE INDEX invitations_pending_expiry_idx ON public.inspection_invitations USING btree (expires_at)
  WHERE (status = 'PENDING'::text);

CREATE INDEX meter_readings_inspection_idx ON public.meter_readings USING btree (inspection_id);

CREATE INDEX properties_created_by_idx ON public.properties USING btree (created_by);

CREATE INDEX property_members_user_id_idx ON public.property_members USING btree (user_id, property_id);

CREATE INDEX revision_requests_inspection_idx ON public.revision_requests USING btree (inspection_id, created_at DESC);

CREATE INDEX revision_requests_item_idx ON public.revision_requests USING btree (item_id)
  WHERE (item_id IS NOT NULL);

CREATE INDEX revision_requests_room_idx ON public.revision_requests USING btree (room_id)
  WHERE (room_id IS NOT NULL);

CREATE POLICY "feedback_insert_own" ON "public"."feedback"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));

CREATE POLICY "feedback_select_own" ON "public"."feedback"
  FOR SELECT
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));

CREATE POLICY "confirmations_own_insert" ON "public"."inspection_confirmations"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (((( SELECT auth.uid() AS uid) = user_id) AND ( SELECT private.can_access_inspection(inspection_confirmations.inspection_id) AS can_access_inspection)));

CREATE POLICY "confirmations_participants_select" ON "public"."inspection_confirmations"
  FOR SELECT
  TO "authenticated"
  USING (( SELECT private.can_access_inspection(inspection_confirmations.inspection_id) AS can_access_inspection));

CREATE POLICY "invitations_managers_all" ON "public"."inspection_invitations"
  FOR ALL
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.inspections inspection
  WHERE ((inspection.id = inspection_invitations.inspection_id) AND ( SELECT private.can_manage_property(inspection.property_id) AS can_manage_property)))))
  WITH CHECK (((( SELECT auth.uid() AS uid) = invited_by) AND (EXISTS ( SELECT 1
   FROM public.inspections inspection
  WHERE ((inspection.id = inspection_invitations.inspection_id) AND ( SELECT private.can_manage_property(inspection.property_id) AS can_manage_property))))));

CREATE POLICY "items_delete_participants" ON "public"."inspection_items"
  FOR DELETE
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.inspection_rooms room
  WHERE ((room.id = inspection_items.room_id) AND ( SELECT private.can_access_inspection(room.inspection_id) AS can_access_inspection)))));

CREATE POLICY "items_insert_participants" ON "public"."inspection_items"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((EXISTS ( SELECT 1
   FROM public.inspection_rooms room
  WHERE ((room.id = inspection_items.room_id) AND ( SELECT private.can_access_inspection(room.inspection_id) AS can_access_inspection)))));

CREATE POLICY "items_select_participants" ON "public"."inspection_items"
  FOR SELECT
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.inspection_rooms room
  WHERE ((room.id = inspection_items.room_id) AND ( SELECT private.can_access_inspection(room.inspection_id) AS can_access_inspection)))));

CREATE POLICY "items_update_participants" ON "public"."inspection_items"
  FOR UPDATE
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.inspection_rooms room
  WHERE ((room.id = inspection_items.room_id) AND ( SELECT private.can_access_inspection(room.inspection_id) AS can_access_inspection)))))
  WITH CHECK ((EXISTS ( SELECT 1
   FROM public.inspection_rooms room
  WHERE ((room.id = inspection_items.room_id) AND ( SELECT private.can_access_inspection(room.inspection_id) AS can_access_inspection)))));

CREATE POLICY "keys_participants_all" ON "public"."inspection_keys"
  FOR ALL
  TO "authenticated"
  USING (( SELECT private.can_access_inspection(inspection_keys.inspection_id) AS can_access_inspection))
  WITH CHECK (( SELECT private.can_access_inspection(inspection_keys.inspection_id) AS can_access_inspection));

CREATE POLICY "photos_delete_uploader" ON "public"."inspection_photos"
  FOR DELETE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = uploaded_by));

CREATE POLICY "photos_insert_uploader" ON "public"."inspection_photos"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (((( SELECT auth.uid() AS uid) = uploaded_by) AND (EXISTS ( SELECT 1
   FROM (public.inspection_items item
     JOIN public.inspection_rooms room ON ((room.id = item.room_id)))
  WHERE ((item.id = inspection_photos.item_id) AND ( SELECT private.can_access_inspection(room.inspection_id) AS can_access_inspection))))));

CREATE POLICY "photos_select_participants" ON "public"."inspection_photos"
  FOR SELECT
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM (public.inspection_items item
     JOIN public.inspection_rooms room ON ((room.id = item.room_id)))
  WHERE ((item.id = inspection_photos.item_id) AND ( SELECT private.can_access_inspection(room.inspection_id) AS can_access_inspection)))));

CREATE POLICY "photos_update_uploader" ON "public"."inspection_photos"
  FOR UPDATE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = uploaded_by))
  WITH CHECK ((( SELECT auth.uid() AS uid) = uploaded_by));

CREATE POLICY "rooms_delete_participants" ON "public"."inspection_rooms"
  FOR DELETE
  TO "authenticated"
  USING (( SELECT private.can_access_inspection(inspection_rooms.inspection_id) AS can_access_inspection));

CREATE POLICY "rooms_insert_participants" ON "public"."inspection_rooms"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (( SELECT private.can_access_inspection(inspection_rooms.inspection_id) AS can_access_inspection));

CREATE POLICY "rooms_select_participants" ON "public"."inspection_rooms"
  FOR SELECT
  TO "authenticated"
  USING (( SELECT private.can_access_inspection(inspection_rooms.inspection_id) AS can_access_inspection));

CREATE POLICY "rooms_update_participants" ON "public"."inspection_rooms"
  FOR UPDATE
  TO "authenticated"
  USING (( SELECT private.can_access_inspection(inspection_rooms.inspection_id) AS can_access_inspection))
  WITH CHECK (( SELECT private.can_access_inspection(inspection_rooms.inspection_id) AS can_access_inspection));

CREATE POLICY "inspections_insert_participants" ON "public"."inspections"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (((( SELECT auth.uid() AS uid) = created_by) AND ( SELECT private.can_access_property(inspections.property_id) AS can_access_property)));

CREATE POLICY "inspections_select_participants" ON "public"."inspections"
  FOR SELECT
  TO "authenticated"
  USING (( SELECT private.can_access_inspection(inspections.id) AS can_access_inspection));

CREATE POLICY "inspections_update_participants" ON "public"."inspections"
  FOR UPDATE
  TO "authenticated"
  USING
    (((( SELECT auth.uid() AS uid) = created_by) OR (( SELECT auth.uid() AS uid) = assigned_to) OR ( SELECT private.can_manage_property(inspections.property_id) AS
    can_manage_property)))
  WITH
    CHECK
    (((( SELECT auth.uid() AS uid) = created_by) OR (( SELECT auth.uid() AS uid) = assigned_to) OR ( SELECT private.can_manage_property(inspections.property_id) AS
    can_manage_property)));

CREATE POLICY "meters_participants_all" ON "public"."meter_readings"
  FOR ALL
  TO "authenticated"
  USING (( SELECT private.can_access_inspection(meter_readings.inspection_id) AS can_access_inspection))
  WITH CHECK (( SELECT private.can_access_inspection(meter_readings.inspection_id) AS can_access_inspection));

CREATE POLICY "profiles_insert_own" ON "public"."profiles"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((( SELECT auth.uid() AS uid) = id));

CREATE POLICY "profiles_select_own" ON "public"."profiles"
  FOR SELECT
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = id));

CREATE POLICY "profiles_update_own" ON "public"."profiles"
  FOR UPDATE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = id))
  WITH CHECK ((( SELECT auth.uid() AS uid) = id));

CREATE POLICY "properties_delete_creator" ON "public"."properties"
  FOR DELETE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = created_by));

CREATE POLICY "properties_insert_owner" ON "public"."properties"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((( SELECT auth.uid() AS uid) = created_by));

CREATE POLICY "properties_select_members" ON "public"."properties"
  FOR SELECT
  TO "authenticated"
  USING (( SELECT private.can_access_property(properties.id) AS can_access_property));

CREATE POLICY "properties_update_managers" ON "public"."properties"
  FOR UPDATE
  TO "authenticated"
  USING (( SELECT private.can_manage_property(properties.id) AS can_manage_property))
  WITH CHECK (( SELECT private.can_manage_property(properties.id) AS can_manage_property));

CREATE POLICY "property_members_delete_managers" ON "public"."property_members"
  FOR DELETE
  TO "authenticated"
  USING (( SELECT private.can_manage_property(property_members.property_id) AS can_manage_property));

CREATE POLICY "property_members_insert_managers" ON "public"."property_members"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (( SELECT private.can_manage_property(property_members.property_id) AS can_manage_property));

CREATE POLICY "property_members_select_members" ON "public"."property_members"
  FOR SELECT
  TO "authenticated"
  USING (( SELECT private.can_access_property(property_members.property_id) AS can_access_property));

CREATE POLICY "property_members_update_managers" ON "public"."property_members"
  FOR UPDATE
  TO "authenticated"
  USING (( SELECT private.can_manage_property(property_members.property_id) AS can_manage_property))
  WITH CHECK (( SELECT private.can_manage_property(property_members.property_id) AS can_manage_property));

CREATE POLICY "revisions_participants_all" ON "public"."revision_requests"
  FOR ALL
  TO "authenticated"
  USING (( SELECT private.can_access_inspection(revision_requests.inspection_id) AS can_access_inspection))
  WITH CHECK ((( SELECT private.can_access_inspection(revision_requests.inspection_id) AS can_access_inspection) AND (( SELECT auth.uid() AS uid) = requested_by)));

CREATE POLICY "feedback_storage_delete_own" ON "storage"."objects"
  FOR DELETE
  TO "authenticated"
  USING (((bucket_id = 'feedback-attachments'::text) AND (owner_id = ( SELECT (auth.uid())::text AS uid))));

CREATE POLICY "feedback_storage_insert_own" ON "storage"."objects"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (((bucket_id = 'feedback-attachments'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text)));

CREATE POLICY "feedback_storage_select_own" ON "storage"."objects"
  FOR SELECT
  TO "authenticated"
  USING (((bucket_id = 'feedback-attachments'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text)));

CREATE POLICY "inspection_storage_delete_uploader" ON "storage"."objects"
  FOR DELETE
  TO "authenticated"
  USING (((bucket_id = 'inspection-evidence'::text) AND (owner_id = ( SELECT (auth.uid())::text AS uid))));

CREATE POLICY "inspection_storage_insert_participants" ON "storage"."objects"
  FOR INSERT
  TO "authenticated"
  WITH
    CHECK
    (((bucket_id = 'inspection-evidence'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text) AND ( SELECT private.can_access_storage_path(objects.name)
    AS can_access_storage_path)));

CREATE POLICY "inspection_storage_select_participants" ON "storage"."objects"
  FOR SELECT
  TO "authenticated"
  USING (((bucket_id = 'inspection-evidence'::text) AND ( SELECT private.can_access_storage_path(objects.name) AS can_access_storage_path)));

CREATE POLICY "inspection_storage_update_uploader" ON "storage"."objects"
  FOR UPDATE
  TO "authenticated"
  USING (((bucket_id = 'inspection-evidence'::text) AND (owner_id = ( SELECT (auth.uid())::text AS uid))))
  WITH CHECK (((bucket_id = 'inspection-evidence'::text) AND (owner_id = ( SELECT (auth.uid())::text AS uid))));

REVOKE ALL ON FUNCTION "private"."can_access_inspection"(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "private"."can_access_inspection"(uuid) TO "authenticated", "postgres";

REVOKE ALL ON FUNCTION "private"."can_access_property"(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "private"."can_access_property"(uuid) TO "authenticated", "postgres";

REVOKE ALL ON FUNCTION "private"."can_access_storage_path"(text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "private"."can_access_storage_path"(text) TO "authenticated", "postgres";

REVOKE ALL ON FUNCTION "private"."can_manage_property"(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "private"."can_manage_property"(uuid) TO "authenticated", "postgres";

GRANT USAGE ON SCHEMA "private" TO "authenticated";

GRANT CREATE, USAGE ON SCHEMA "private" TO "postgres";

GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."feedback" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."feedback" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."feedback" TO "service_role";

GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."inspection_confirmations" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."inspection_confirmations" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."inspection_confirmations" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."inspection_invitations" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."inspection_invitations" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."inspection_items" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."inspection_items" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."inspection_keys" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."inspection_keys" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."inspection_photos" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."inspection_photos" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."inspection_rooms" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."inspection_rooms" TO "service_role";

GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."inspections" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."inspections" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."inspections" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."meter_readings" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."meter_readings" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."profiles" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."profiles" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."properties" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."properties" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."property_members" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."property_members" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."revision_requests" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."revision_requests" TO "service_role";
