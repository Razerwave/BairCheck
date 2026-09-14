-- Ганц мөр: аппын төлөв. Declarative schema дотор data statement байж болохгүй тул тусад нь.
insert into public.app_status (id, maintenance, title, message)
values (true, false, '', '')
on conflict (id) do nothing;
