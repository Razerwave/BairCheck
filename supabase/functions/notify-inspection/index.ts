// Үзлэгийн төлөв өөрчлөгдөхөд нөгөө талд и-мэйл мэдэгдэл илгээнэ.
//
// body: { inspection_id, event }
//   event = 'submitted'          → эзэмшигчид (түрээслэгч бөглөж дуусгасан)
//         | 'revision_requested' → түрээслэгчид (эзэмшигч засвар хүссэн)
//         | 'approved'           → түрээслэгчид (эзэмшигч зөвшөөрсөн)
//
// Deploy: supabase functions deploy notify-inspection
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

const appUrl = Deno.env.get('APP_URL') ?? 'https://tulkhuur.netlify.app';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'missing authorization header' }, 401);

  let payload: { inspection_id?: string; event?: string };
  try {
    payload = await req.json();
  } catch {
    return json({ error: 'invalid body' }, 400);
  }
  const { inspection_id: inspectionId, event } = payload;
  if (!inspectionId || !event) {
    return json({ error: 'inspection_id and event required' }, 400);
  }

  const url = Deno.env.get('SUPABASE_URL')!;
  const userClient = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  const sender = userData?.user;
  if (userError || !sender) return json({ error: 'invalid session' }, 401);

  const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

  const { data: inspection } = await admin
    .from('inspections')
    .select(
      'id, inspection_type, created_by, assigned_to, tenant_email, tenant_name, '
        + 'properties(name)',
    )
    .eq('id', inspectionId)
    .maybeSingle();
  if (!inspection) return json({ error: 'inspection_not_found' }, 404);

  // Зөвхөн оролцогч мэдэгдэл илгээх эрхтэй.
  if (inspection.created_by !== sender.id && inspection.assigned_to !== sender.id) {
    return json({ error: 'forbidden' }, 403);
  }

  // Хүлээн авагчийг тодорхойлно.
  let recipient: string | null = null;
  if (event === 'submitted') {
    const { data } = await admin.auth.admin.getUserById(inspection.created_by);
    recipient = data?.user?.email ?? null;
  } else if (inspection.assigned_to) {
    const { data } = await admin.auth.admin.getUserById(inspection.assigned_to);
    recipient = data?.user?.email ?? inspection.tenant_email ?? null;
  } else {
    recipient = inspection.tenant_email ?? null;
  }
  if (!recipient) return json({ error: 'recipient_not_found' }, 404);

  const property = escapeHtml(
    (inspection.properties as { name?: string } | null)?.name ?? 'байр',
  );
  const typeLabel = inspection.inspection_type === 'MOVE_OUT'
    ? 'Гарах үеийн үзлэг'
    : 'Орох үеийн үзлэг';

  const templates: Record<string, { subject: string; title: string; body: string }> = {
    submitted: {
      subject: 'Түлхүүр — үзлэг шалгуулахаар ирлээ',
      title: 'Үзлэг шалгуулахаар ирлээ',
      body: `<b>${property}</b> байрны ${typeLabel} бөглөгдөж дууслаа. `
        + 'Аппаа нээж шалгаад зөвшөөрөх эсвэл засвар хүснэ үү.',
    },
    revision_requested: {
      subject: 'Түлхүүр — үзлэгт засвар хүсэлт ирлээ',
      title: 'Засварын хүсэлт ирлээ',
      body: `<b>${property}</b> байрны ${typeLabel} дээр засвар хийхийг хүссэн байна. `
        + 'Аппаа нээж хүсэлтийг шалгана уу.',
    },
    approved: {
      subject: 'Түлхүүр — үзлэг зөвшөөрөгдлөө',
      title: 'Үзлэг зөвшөөрөгдлөө',
      body: `<b>${property}</b> байрны ${typeLabel} зөвшөөрөгдлөө. `
        + 'Хоёр тал баталгаажуулсны дараа хүлээлцэх акт бэлэн болно.',
    },
  };
  const template = templates[event];
  if (!template) return json({ error: 'unknown_event' }, 400);

  const result = await sendEmail({
    to: recipient,
    subject: template.subject,
    html: emailLayout({
      title: template.title,
      body: template.body,
      buttonLabel: 'Аппыг нээх',
      buttonUrl: appUrl,
    }),
  });

  if (!result.configured) return json({ error: 'email_not_configured' }, 501);
  if (!result.sent) return json({ error: 'send_failed', detail: result.detail }, 502);
  return json({ sent: true }, 200);
});
