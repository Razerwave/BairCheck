REVOKE ALL ON TABLE "public"."feedback" FROM "anon";

REVOKE ALL ON TABLE "public"."inspection_confirmations" FROM "anon";

REVOKE ALL ON TABLE "public"."inspection_invitations" FROM "anon";

REVOKE ALL ON TABLE "public"."inspection_items" FROM "anon";

REVOKE ALL ON TABLE "public"."inspection_keys" FROM "anon";

REVOKE ALL ON TABLE "public"."inspection_photos" FROM "anon";

REVOKE ALL ON TABLE "public"."inspection_rooms" FROM "anon";

REVOKE ALL ON TABLE "public"."inspections" FROM "anon";

REVOKE ALL ON TABLE "public"."meter_readings" FROM "anon";

REVOKE ALL ON TABLE "public"."profiles" FROM "anon";

REVOKE ALL ON TABLE "public"."properties" FROM "anon";

REVOKE ALL ON TABLE "public"."property_members" FROM "anon";

REVOKE ALL ON TABLE "public"."revision_requests" FROM "anon";

CREATE TABLE "public"."app_status" (
  "id"              boolean                  NOT NULL DEFAULT true,
  "maintenance"     boolean                  NOT NULL DEFAULT false,
  "title"           text                     NOT NULL DEFAULT ''::text,
  "message"         text                     NOT NULL DEFAULT ''::text,
  "minimum_version" text,
  "updated_at"      timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "app_status_id_check" CHECK (id),
  CONSTRAINT "app_status_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."app_status"
  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "app_status_readable" ON "public"."app_status"
  FOR SELECT
  TO "anon", "authenticated"
  USING (true);

REVOKE ALL ON TABLE "public"."app_status" FROM "anon";

GRANT SELECT ON TABLE "public"."app_status" TO "anon";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."app_status" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."app_status" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."app_status" TO "service_role";
