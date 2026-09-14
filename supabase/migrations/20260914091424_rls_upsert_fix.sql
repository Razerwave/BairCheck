DROP POLICY "inspections_select_participants" ON "public"."inspections";

DROP POLICY "properties_select_members" ON "public"."properties";

DROP POLICY "properties_update_managers" ON "public"."properties";

CREATE POLICY "inspections_select_participants" ON "public"."inspections"
  FOR SELECT
  TO "authenticated"
  USING
    (((created_by = ( SELECT auth.uid() AS uid)) OR (assigned_to = ( SELECT auth.uid() AS uid)) OR ( SELECT private.can_access_property(inspections.property_id) AS
    can_access_property)));

CREATE POLICY "properties_select_members" ON "public"."properties"
  FOR SELECT
  TO "authenticated"
  USING (((created_by = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.property_members member
  WHERE ((member.property_id = properties.id) AND (member.user_id = ( SELECT auth.uid() AS uid)))))));

CREATE POLICY "properties_update_managers" ON "public"."properties"
  FOR UPDATE
  TO "authenticated"
  USING (((created_by = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.property_members member
  WHERE ((member.property_id = properties.id) AND (member.user_id = ( SELECT auth.uid() AS uid)) AND (member.member_role = ANY (ARRAY['OWNER'::text, 'AGENT'::text])))))))
  WITH CHECK (((created_by = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM public.property_members member
  WHERE ((member.property_id = properties.id) AND (member.user_id = ( SELECT auth.uid() AS uid)) AND (member.member_role = ANY (ARRAY['OWNER'::text, 'AGENT'::text])))))));
