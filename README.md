# Eurus Lab

A personal research journal and thought recorder. The site provides public read access and a single authenticated editor.

**Website:** https://euruswu.github.io/eurus-lab/

## Features

- Mindstream: chronological entries and topic filtering.
- Thought Recorder: plain-text entries with server-generated timestamps, displayed in UTC+8.
- Trails: parent-linked continuations that also appear in the main timeline.
- Entry editing, deletion and tag management.
- Projects: project descriptions, repository links and associated thoughts.
- Vision and Eurus: editable text pages.
- Persistent storage and cross-device access.
- Dark and light themes, responsive layout and an installable web app manifest.

## Stack

Vanilla HTML, CSS and JavaScript, Supabase (PostgreSQL and Auth), GitHub Pages. No build step is required. Database writes are restricted to the configured owner by row-level security and column-level grants.

## Setup & Deployment

1. Create a Supabase project.
2. Run `supabase/schema.sql` in the SQL Editor of the new project.
3. In Authentication > Users, create an email/password user for the owner. Disable public sign-ups in the Auth settings.
4. Copy that user's UUID and run the following statement in the SQL Editor, replacing the placeholder:

   ```sql
   insert into public.lab_owner(id) values ('YOUR-AUTH-USER-UUID');
   ```

5. Set `url` and `key` in `config.js` to the project URL and publishable key (or legacy anon key). Do not use a secret or service role key.
6. In the GitHub repository's Settings > Pages, select Deploy from a branch, then `main` and `/ (root)`.

Use the Sign in control in the footer to access the editor.

## Local development

```sh
python3 -m http.server 8000
```

Open http://localhost:8000/. A configured Supabase project is required for persistent records. Service worker registration requires HTTPS in the current implementation.

## Files

- `index.html`, `style.css`, `app.js`: site layout, styles and application logic.
- `config.js`: public Supabase connection settings.
- `supabase/schema.sql`: initial schema and access policies.
- `manifest.webmanifest`, `sw.js`, `icon.svg`: web app configuration and assets.

## Data

Thoughts, projects and page content are stored in PostgreSQL. Editing a thought does not alter its creation timestamp. Deleting a thought retains its direct continuations as independent roots. Records require a network connection; offline publishing is not supported.
