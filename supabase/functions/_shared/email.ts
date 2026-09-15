// И-мэйл илгээх нэгдсэн давхарга.
//
// Тохируулсан нууц утгаас хамаарч үйлчилгээг сонгоно:
//   BREVO_API_KEY   — домэйнгүйгээр ганц хаяг баталгаажуулахад хангалттай
//   RESEND_API_KEY  — домэйн баталгаажуулсан үед
// Хоёулан нь байхгүй бол `configured: false` буцаана.
//
// Илгээгчийг EMAIL_FROM ("Түлхүүр <urilga@tulkhuur.mn>") -оор тохируулна.

export interface EmailResult {
  configured: boolean;
  sent: boolean;
  detail?: string;
}

function parseFrom(): { email: string; name: string } {
  const raw = Deno.env.get('EMAIL_FROM') ?? 'Түлхүүр <onboarding@resend.dev>';
  const match = raw.match(/^(.*?)\s*<(.+)>$/);
  return match
    ? { name: match[1].trim() || 'Түлхүүр', email: match[2].trim() }
    : { name: 'Түлхүүр', email: raw.trim() };
}

export async function sendEmail(options: {
  to: string;
  subject: string;
  html: string;
}): Promise<EmailResult> {
  const from = parseFrom();
  const brevoKey = Deno.env.get('BREVO_API_KEY');
  const resendKey = Deno.env.get('RESEND_API_KEY');

  if (brevoKey) {
    const response = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'api-key': brevoKey,
        'Content-Type': 'application/json',
        accept: 'application/json',
      },
      body: JSON.stringify({
        sender: { email: from.email, name: from.name },
        to: [{ email: options.to }],
        subject: options.subject,
        htmlContent: options.html,
      }),
    });
    return response.ok
      ? { configured: true, sent: true }
      : { configured: true, sent: false, detail: await response.text() };
  }

  if (resendKey) {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${resendKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: `${from.name} <${from.email}>`,
        to: [options.to],
        subject: options.subject,
        html: options.html,
      }),
    });
    return response.ok
      ? { configured: true, sent: true }
      : { configured: true, sent: false, detail: await response.text() };
  }

  return { configured: false, sent: false };
}

/// Аппын хэв маягтай и-мэйлийн бүрхүүл.
export function emailLayout(options: {
  title: string;
  body: string;
  buttonLabel?: string;
  buttonUrl?: string;
  footnote?: string;
}): string {
  const button = options.buttonUrl && options.buttonLabel
    ? `<a href="${options.buttonUrl}" style="display:inline-block;background:#0f766e;color:#fff;text-decoration:none;font-weight:600;padding:14px 26px;border-radius:12px">${options.buttonLabel}</a>
       <p style="color:#94a3b8;font-size:13px;line-height:1.6;margin:24px 0 0">
         Товч ажиллахгүй бол энэ холбоосыг хуулна уу:<br>
         <span style="color:#475569;word-break:break-all">${options.buttonUrl}</span>
       </p>`
    : '';
  const footnote = options.footnote
    ? `<p style="color:#94a3b8;font-size:13px;margin:20px 0 0">${options.footnote}</p>`
    : '';
  return `<!doctype html>
<html lang="mn"><body style="margin:0;background:#f8fafc;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;color:#0f172a">
  <div style="max-width:520px;margin:0 auto;padding:32px 24px">
    <div style="margin-bottom:24px">
      <span style="display:inline-block;width:9px;height:9px;border-radius:50%;background:#34d399;vertical-align:middle"></span>
      <span style="font-size:18px;font-weight:800;color:#0f766e;vertical-align:middle;margin-left:8px">Түлхүүр</span>
    </div>
    <h1 style="font-size:22px;margin:0 0 12px">${options.title}</h1>
    <p style="color:#475569;line-height:1.6;margin:0 0 20px">${options.body}</p>
    ${button}
    ${footnote}
  </div>
</body></html>`;
}

export function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
