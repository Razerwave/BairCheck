// Хэрэглэгчийн бүртгэлийг бүрмөсөн устгана.
// App Store 5.1.1(v) болон Google Play-ийн шаардлагыг хангахад зориулсан.
//
// Deploy: supabase functions deploy delete-account
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

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'missing authorization header' }, 401);

  const url = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // 1. Хүсэлт гаргагчийг баталгаажуулна
  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  const user = userData?.user;
  if (userError || !user) return json({ error: 'invalid session' }, 401);

  const admin = createClient(url, serviceKey);

  // 2. Гадаад түлхүүрийн хамаарлын дагуу дарааллаар нь өгөгдлийг устгана.
  //    (properties.created_by гэх мэт нь `on delete restrict` тул эхэлж цэвэрлэнэ)
  const ownedInspections = await admin
    .from('inspections')
    .select('id')
    .eq('created_by', user.id);
  const inspectionIds = (ownedInspections.data ?? []).map((row) => row.id);

  if (inspectionIds.length > 0) {
    const rooms = await admin
      .from('inspection_rooms')
      .select('id')
      .in('inspection_id', inspectionIds);
    const roomIds = (rooms.data ?? []).map((row) => row.id);
    if (roomIds.length > 0) {
      const items = await admin
        .from('inspection_items')
        .select('id')
        .in('room_id', roomIds);
      const itemIds = (items.data ?? []).map((row) => row.id);
      if (itemIds.length > 0) {
        await admin.from('inspection_photos').delete().in('item_id', itemIds);
      }
    }
    await admin.from('revision_requests').delete().in('inspection_id', inspectionIds);
    await admin.from('inspection_confirmations').delete().in('inspection_id', inspectionIds);
    await admin.from('inspection_invitations').delete().in('inspection_id', inspectionIds);
  }

  await admin.from('inspection_photos').delete().eq('uploaded_by', user.id);
  await admin.from('revision_requests').delete().eq('requested_by', user.id);
  await admin.from('inspection_confirmations').delete().eq('user_id', user.id);
  await admin.from('inspections').delete().eq('created_by', user.id);
  await admin.from('property_members').delete().eq('user_id', user.id);
  await admin.from('properties').delete().eq('created_by', user.id);
  await admin.from('feedback').delete().eq('user_id', user.id);
  await admin.from('profiles').delete().eq('id', user.id);

  // 3. Хадгалалт дахь файлуудыг устгана
  for (const bucket of ['inspection-evidence', 'feedback-attachments']) {
    const listed = await admin.storage.from(bucket).list(user.id, { limit: 1000 });
    const paths = (listed.data ?? []).map((file) => `${user.id}/${file.name}`);
    if (paths.length > 0) await admin.storage.from(bucket).remove(paths);
  }

  // 4. Auth хэрэглэгчийг устгана
  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) return json({ error: deleteError.message }, 500);

  return json({ deleted: true }, 200);
});
