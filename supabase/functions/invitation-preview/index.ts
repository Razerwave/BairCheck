// Урилгын токеноор үзлэгийн бүтцийг уншиж өгнө (вэб маягтад зориулав).
//
// Токен өөрөө нэвтрэх эрхийн үүрэг гүйцэтгэнэ — нэвтэрсэн байх шаардлагагүй.
// Deploy: supabase functions deploy invitation-preview --no-verify-jwt
import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value));
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  let token: string | undefined;
  try {
    token = (await req.json())?.token;
  } catch {
    return json({ error: 'invalid body' }, 400);
  }
  if (!token) return json({ error: 'token required' }, 400);

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data: invitation } = await admin
    .from('inspection_invitations')
    .select('id, inspection_id, tenant_name, status, expires_at')
    .eq('token_hash', await sha256Hex(token))
    .maybeSingle();

  if (!invitation) return json({ error: 'invitation_not_found' }, 404);
  if (invitation.status === 'REVOKED') return json({ error: 'invitation_revoked' }, 410);
  if (new Date(invitation.expires_at) < new Date()) {
    return json({ error: 'invitation_expired' }, 410);
  }

  const { data: inspection } = await admin
    .from('inspections')
    .select(
      'id, inspection_type, status, property_id, ' +
        'properties(name, address, area_square_meters, floor), ' +
        'inspection_rooms(id, name, sort_order, ' +
        'inspection_items(id, name, condition, notes, sort_order))',
    )
    .eq('id', invitation.inspection_id)
    .maybeSingle();

  if (!inspection) return json({ error: 'inspection_not_found' }, 404);

  const rooms = (inspection.inspection_rooms ?? [])
    .sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0))
    .map((room) => ({
      id: room.id,
      name: room.name,
      items: (room.inspection_items ?? [])
        .sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0))
        .map((item) => ({
          id: item.id,
          name: item.name,
          condition: item.condition,
          notes: item.notes ?? '',
        })),
    }));

  return json(
    {
      tenant_name: invitation.tenant_name,
      already_submitted: inspection.status !== 'DRAFT',
      inspection: {
        id: inspection.id,
        type: inspection.inspection_type,
        property: inspection.properties,
      },
      rooms,
    },
    200,
  );
});
