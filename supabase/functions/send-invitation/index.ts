// Урилгын холбоосыг түрээслэгчийн и-мэйл рүү илгээнэ.
//
// Тохируулах:
//   supabase secrets set BREVO_API_KEY=xkeysib-xxx
//   supabase secrets set EMAIL_FROM="Түлхүүр <hatnaa.cs@gmail.com>"
// Deploy: supabase functions deploy send-invitation
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { emailLayout, escapeHtml, sendEmail } from '../_shared/email.ts';

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

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'missing authorization header' }, 401);

  let payload: {
    email?: string;
    link?: string;
    tenantName?: string;
    propertyName?: string;
  };
  try {
    payload = await req.json();
  } catch {
    return json({ error: 'invalid body' }, 400);
  }
  const { email, link, tenantName = '', propertyName = '' } = payload;
  if (!email || !link) return json({ error: 'email and link required' }, 400);

  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData?.user) return json({ error: 'invalid session' }, 401);

  const greeting = tenantName.trim()
    ? `Сайн байна уу, ${escapeHtml(tenantName)}.`
    : 'Сайн байна уу.';
  const property = propertyName.trim() ? ` <b>${escapeHtml(propertyName)}</b>` : '';

  const result = await sendEmail({
    to: email,
    subject: 'Түлхүүр — байрны үзлэгийн урилга',
    html: emailLayout({
      title: 'Байрны үзлэгийн урилга',
      body: `${greeting} Танаас${property} байрны үзлэгийг бөглөхийг хүсч байна. `
        + 'Доорх товчийг дарж үзлэгээ бөглөнө үү.',
      buttonLabel: 'Үзлэг бөглөх',
      buttonUrl: link,
      footnote: 'Холбоос 7 хоногийн дараа хүчингүй болно.',
    }),
  });

  if (!result.configured) return json({ error: 'email_not_configured' }, 501);
  if (!result.sent) return json({ error: 'send_failed', detail: result.detail }, 502);
  return json({ sent: true }, 200);
});
