-- Storage bucket-ууд: declarative schema дотор data statement байж болохгүй тул тусад нь.
-- Локал орчинд config.toml-ийн [storage.buckets.*] үүсгэдэг; энэ migration нь cloud-д зориулагдсан.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  (
    'inspection-evidence',
    'inspection-evidence',
    false,
    15728640,
    array['image/jpeg', 'image/png', 'image/heic', 'image/heif']
  ),
  (
    'feedback-attachments',
    'feedback-attachments',
    false,
    10485760,
    array['image/jpeg', 'image/png', 'image/heic', 'image/heif']
  )
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
