-- AS-CORE live schema snapshot
-- Source project: qsiderzmnpjjvccgzels (eu-central-1)
-- Captured: 2026-11-26
-- This is an introspection-based schema snapshot, not the original migration source.
-- No application rows were exported; all 10 application tables were empty at capture time.
-- Review security policies and regional data-protection requirements before production use.

CREATE SCHEMA IF NOT EXISTS private;

CREATE TABLE IF NOT EXISTS public.clients (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  full_name text NOT NULL,
  phone text,
  email text,
  telegram_user_id text,
  notes text,
  status text DEFAULT 'active'::text NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL,
  telegram_chat_id text,
  telegram_username text,
  telegram_first_name text,
  telegram_last_name text,
  last_interaction_at timestamp with time zone
);

CREATE TABLE IF NOT EXISTS public.services (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  description text,
  duration_minutes integer NOT NULL,
  price_rub numeric NOT NULL,
  is_active boolean DEFAULT true NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.bookings (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  client_id uuid,
  service_id uuid,
  external_source text,
  external_booking_id text,
  starts_at timestamp with time zone NOT NULL,
  ends_at timestamp with time zone NOT NULL,
  status text DEFAULT 'pending'::text NOT NULL,
  price_rub numeric,
  prepayment_rub numeric DEFAULT 0 NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.visits (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  client_id uuid NOT NULL,
  booking_id uuid,
  service_id uuid,
  visited_at timestamp with time zone DEFAULT now() NOT NULL,
  duration_minutes integer,
  amount_paid_rub numeric DEFAULT 0 NOT NULL,
  notes text,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.packages (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  sessions_count integer NOT NULL,
  price_rub numeric NOT NULL,
  validity_days integer,
  is_active boolean DEFAULT true NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.client_packages (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  client_id uuid NOT NULL,
  package_id uuid NOT NULL,
  purchased_at timestamp with time zone DEFAULT now() NOT NULL,
  expires_at timestamp with time zone,
  sessions_total integer NOT NULL,
  sessions_used integer DEFAULT 0 NOT NULL,
  amount_paid_rub numeric NOT NULL,
  status text DEFAULT 'active'::text NOT NULL
);

CREATE TABLE IF NOT EXISTS public.bonus_transactions (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  client_id uuid NOT NULL,
  points integer NOT NULL,
  reason text NOT NULL,
  related_visit_id uuid,
  created_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE TABLE IF NOT EXISTS public.communication_consents (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  client_id uuid NOT NULL,
  channel text NOT NULL,
  consent_given boolean NOT NULL,
  recorded_at timestamp with time zone DEFAULT now() NOT NULL,
  source text,
  revoked_at timestamp with time zone
);

CREATE TABLE IF NOT EXISTS private.telegram_updates (
  update_id bigint NOT NULL,
  received_at timestamp with time zone DEFAULT now() NOT NULL,
  processed_at timestamp with time zone,
  status text DEFAULT 'received'::text NOT NULL,
  error_message text
);

CREATE TABLE IF NOT EXISTS private.bot_sessions (
  telegram_user_id text NOT NULL,
  chat_id text NOT NULL,
  state text NOT NULL,
  payload jsonb DEFAULT '{}'::jsonb NOT NULL,
  expires_at timestamp with time zone DEFAULT (now() + '00:30:00'::interval) NOT NULL,
  updated_at timestamp with time zone DEFAULT now() NOT NULL
);

ALTER TABLE private.bot_sessions ADD CONSTRAINT bot_sessions_pkey PRIMARY KEY (telegram_user_id);
ALTER TABLE private.telegram_updates ADD CONSTRAINT telegram_updates_pkey PRIMARY KEY (update_id);
ALTER TABLE private.telegram_updates ADD CONSTRAINT telegram_updates_status_check CHECK ((status = ANY (ARRAY['received'::text, 'processed'::text, 'failed'::text])));
ALTER TABLE public.bonus_transactions ADD CONSTRAINT bonus_transactions_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT;
ALTER TABLE public.bonus_transactions ADD CONSTRAINT bonus_transactions_pkey PRIMARY KEY (id);
ALTER TABLE public.bonus_transactions ADD CONSTRAINT bonus_transactions_points_check CHECK ((points <> 0));
ALTER TABLE public.bonus_transactions ADD CONSTRAINT bonus_transactions_related_visit_id_fkey FOREIGN KEY (related_visit_id) REFERENCES visits(id) ON DELETE SET NULL;
ALTER TABLE public.bookings ADD CONSTRAINT bookings_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT;
ALTER TABLE public.bookings ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);
ALTER TABLE public.bookings ADD CONSTRAINT bookings_prepayment_rub_check CHECK ((prepayment_rub >= (0)::numeric));
ALTER TABLE public.bookings ADD CONSTRAINT bookings_price_rub_check CHECK ((price_rub >= (0)::numeric));
ALTER TABLE public.bookings ADD CONSTRAINT bookings_service_id_fkey FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT;
ALTER TABLE public.bookings ADD CONSTRAINT bookings_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'completed'::text, 'cancelled'::text, 'no_show'::text])));
ALTER TABLE public.bookings ADD CONSTRAINT bookings_valid_time CHECK ((ends_at > starts_at));
ALTER TABLE public.client_packages ADD CONSTRAINT client_packages_amount_paid_rub_check CHECK ((amount_paid_rub >= (0)::numeric));
ALTER TABLE public.client_packages ADD CONSTRAINT client_packages_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT;
ALTER TABLE public.client_packages ADD CONSTRAINT client_packages_package_id_fkey FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE RESTRICT;
ALTER TABLE public.client_packages ADD CONSTRAINT client_packages_pkey PRIMARY KEY (id);
ALTER TABLE public.client_packages ADD CONSTRAINT client_packages_sessions_total_check CHECK ((sessions_total > 0));
ALTER TABLE public.client_packages ADD CONSTRAINT client_packages_sessions_used_check CHECK ((sessions_used >= 0));
ALTER TABLE public.client_packages ADD CONSTRAINT client_packages_status_check CHECK ((status = ANY (ARRAY['active'::text, 'completed'::text, 'expired'::text, 'cancelled'::text])));
ALTER TABLE public.client_packages ADD CONSTRAINT client_packages_usage_valid CHECK ((sessions_used <= sessions_total));
ALTER TABLE public.clients ADD CONSTRAINT clients_pkey PRIMARY KEY (id);
ALTER TABLE public.clients ADD CONSTRAINT clients_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'blocked'::text])));
ALTER TABLE public.communication_consents ADD CONSTRAINT communication_consents_channel_check CHECK ((channel = ANY (ARRAY['telegram'::text, 'whatsapp'::text, 'sms'::text, 'email'::text])));
ALTER TABLE public.communication_consents ADD CONSTRAINT communication_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT;
ALTER TABLE public.communication_consents ADD CONSTRAINT communication_consents_pkey PRIMARY KEY (id);
ALTER TABLE public.packages ADD CONSTRAINT packages_pkey PRIMARY KEY (id);
ALTER TABLE public.packages ADD CONSTRAINT packages_price_rub_check CHECK ((price_rub >= (0)::numeric));
ALTER TABLE public.packages ADD CONSTRAINT packages_sessions_count_check CHECK ((sessions_count > 0));
ALTER TABLE public.packages ADD CONSTRAINT packages_validity_days_check CHECK ((validity_days > 0));
ALTER TABLE public.services ADD CONSTRAINT services_duration_minutes_check CHECK ((duration_minutes > 0));
ALTER TABLE public.services ADD CONSTRAINT services_pkey PRIMARY KEY (id);
ALTER TABLE public.services ADD CONSTRAINT services_price_rub_check CHECK ((price_rub >= (0)::numeric));
ALTER TABLE public.visits ADD CONSTRAINT visits_amount_paid_rub_check CHECK ((amount_paid_rub >= (0)::numeric));
ALTER TABLE public.visits ADD CONSTRAINT visits_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL;
ALTER TABLE public.visits ADD CONSTRAINT visits_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT;
ALTER TABLE public.visits ADD CONSTRAINT visits_duration_minutes_check CHECK ((duration_minutes > 0));
ALTER TABLE public.visits ADD CONSTRAINT visits_pkey PRIMARY KEY (id);
ALTER TABLE public.visits ADD CONSTRAINT visits_service_id_fkey FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE RESTRICT;

CREATE INDEX bonus_transactions_client_created_at_idx ON public.bonus_transactions USING btree (client_id, created_at DESC);
CREATE INDEX bookings_client_id_idx ON public.bookings USING btree (client_id);
CREATE UNIQUE INDEX bookings_external_unique ON public.bookings USING btree (external_source, external_booking_id) WHERE ((external_source IS NOT NULL) AND (external_booking_id IS NOT NULL));
CREATE INDEX bookings_starts_at_idx ON public.bookings USING btree (starts_at);
CREATE INDEX client_packages_client_status_idx ON public.client_packages USING btree (client_id, status);
CREATE INDEX clients_phone_idx ON public.clients USING btree (phone);
CREATE INDEX clients_telegram_user_id_idx ON public.clients USING btree (telegram_user_id);
CREATE UNIQUE INDEX clients_telegram_user_id_unique ON public.clients USING btree (telegram_user_id) WHERE (telegram_user_id IS NOT NULL);
CREATE INDEX communication_consents_client_channel_idx ON public.communication_consents USING btree (client_id, channel);
CREATE INDEX visits_client_id_visited_at_idx ON public.visits USING btree (client_id, visited_at DESC);

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

CREATE TRIGGER bookings_set_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER clients_set_updated_at BEFORE UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER services_set_updated_at BEFORE UPDATE ON public.services FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bonus_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communication_consents ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.telegram_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.bot_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY service_role_only_sessions ON private.bot_sessions AS permissive FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY service_role_only_updates ON private.telegram_updates AS permissive FOR ALL TO service_role USING (true) WITH CHECK (true);

GRANT USAGE ON SCHEMA private TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA private TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
