# CivicWorks Supabase setup

1. Create a Supabase project.
2. In **SQL Editor**, run `migrations/001_civicworks_security.sql`.
3. In **Authentication → Providers**, enable Email.
4. Create the first staff user in **Authentication → Users**.
5. Find that user UUID and promote it from the SQL editor:

```sql
update public.profiles
set role = 'admin'
where id = 'REAL_AUTH_USER_UUID';
```

Never commit a service-role key. The browser only uses the public anon key through `.env`.
