// Урилгын токеныг шалгаж, түрээслэгчийг үзлэгийн оролцогч болгоно.
//
// Токен нь зөвхөн холбоост байдаг; санд түүний SHA-256 хэш хадгалагдана.
// Deploy: supabase functions deploy accept-invitation
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

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'missing authorization header' }, 401);

  let token: string | undefined;
  try {
    token = (await req.json())?.token;
  } catch {
    return json({ error: 'invalid body' }, 400);
  }
  if (!token || typeof token !== 'string') return json({ error: 'token required' }, 400);

  const url = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  const user = userData?.user;
  if (userError || !user) return json({ error: 'invalid session' }, 401);

  const admin = createClient(url, serviceKey);
  const tokenHash = await sha256Hex(token);

  const { data: invitation } = await admin
    .from('inspection_invitations')
    .select('id, inspection_id, status, expires_at')
    .eq('token_hash', tokenHash)
    .maybeSingle();

  if (!invitation) return json({ error: 'invitation_not_found' }, 404);
  if (invitation.status !== 'PENDING' && invitation.status !== 'ACCEPTED') {
    return json({ error: 'invitation_revoked' }, 410);
  }
  if (new Date(invitation.expires_at) < new Date()) {
    await admin
      .from('inspection_invitations')
      .update({ status: 'EXPIRED' })
      .eq('id', invitation.id);
    return json({ error: 'invitation_expired' }, 410);
  }

  const { data: inspection } = await admin
    .from('inspections')
    .select('id, property_id, created_by')
    .eq('id', invitation.inspection_id)
    .maybeSingle();
  if (!inspection) return json({ error: 'inspection_not_found' }, 404);

  // Түрээслэгчийг байрны оролцогч болгоно — RLS үүнээс хамаарна.
  await admin.from('property_members').upsert(
    {
      property_id: inspection.property_id,
      user_id: user.id,
      member_role: 'TENANT',
      invited_by: inspection.created_by,
    },
    { onConflict: 'property_id,user_id', ignoreDuplicates: true },
  );

  // Үзлэгийг тухайн хэрэглэгчид хариуцуулна.
  await admin
    .from('inspections')
    .update({ assigned_to: user.id })
    .eq('id', inspection.id);

  await admin
    .from('inspection_invitations')
    .update({
      status: 'ACCEPTED',
      accepted_by: user.id,
      accepted_at: new Date().toISOString(),
    })
    .eq('id', invitation.id);

  return json({ inspection_id: inspection.id, property_id: inspection.property_id }, 200);
});
