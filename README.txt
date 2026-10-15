AETHEL COLLECTIVE — Premium Books App

FILES
- index.html: complete accounting app
- AethelMonogram.png: AETHEL monogram, browser icon and install icon
- manifest.webmanifest: installable desktop and mobile app settings
- service-worker.js: offline app-shell cache
- vercel.json: static Vercel settings
- README.txt: deployment, cloud setup and use instructions

DEPLOY TO THE CONNECTED GITHUB REPOSITORY
1. Extract the AETHEL-Vercel folder from the ZIP.
2. Copy all six files into the root of your GitHub repository, replacing the old site files.
3. Commit and push. Vercel will redeploy from the connected repository.
4. In Vercel project settings, use the repository root, Framework Preset “Other”, no Build Command, and the repository root as the output directory.

USE AS A DESKTOP OR MOBILE APP
Deploy the site over HTTPS first. On a computer, open it in Microsoft Edge or Chrome and choose the browser’s Install app option. On Android, use the browser’s Install app or Add to Home screen option. On iPhone or iPad, open the site in Safari and use Share → Add to Home Screen. Menu wording may vary by browser version.

SUPABASE SHARED BOOKS SETUP
The separate file AETHEL-Supabase-Setup.sql creates the tables, row-level access policies, workspace functions, and restore-point functions required by the app.
1. Create a Supabase project and wait for it to finish provisioning.
2. In Supabase Dashboard, open SQL Editor, create a query, paste the entire AETHEL-Supabase-Setup.sql file, and run it once.
3. In Project Settings → API, copy the Project URL and the publishable key (or legacy anon key). Never copy or use the service_role/secret key in the browser.
4. Open the deployed AETHEL app → Settings & backup → Supabase cloud sync. Save the Project URL and publishable key.
5. The first partner signs up or signs in with their own email, confirms the email if Supabase requests it, then creates the shared workspace from the browser containing the reviewed books. Download a backup first and confirm that this is the intended copy.
6. Joshvin and Rahul each create their own sign-in and confirm their email if required. The workspace owner then adds each partner using the exact email address on their Supabase account.
If Supabase says “email rate limit exceeded”, stop retrying sign-up. Check inbox/spam for a message already sent and wait for the rate limit to reset. Supabase’s built-in sender is best-effort and restricted; configure custom SMTP under Authentication → Emails → SMTP Settings for reliable confirmation emails.
7. On each partner’s device, sign in and load the shared books once. Automatic sync then resumes on that device. Concurrent edits are guarded by a revision conflict; download a backup and reconcile before loading another partner’s copy.

Each partner uses a separate sign-in. The supplied SQL restricts reads to workspace members and allows book changes through permission-checked database functions. The browser app never needs the Supabase service_role key. Cloud setup is not complete until you run the SQL against your own Supabase project and connect the app.

DATA SAFETY
This app saves a local copy in each browser. It keeps up to seven local restore points. In the shared workspace, the first update each day saves an automatic cloud restore point; partners can also create and restore manual snapshots. Download an accounting backup regularly. The offline cache stores app files only, not accounting data.

BOOKKEEPING AND NEW FEATURES
- Journal drafts from imported/reference data remain unposted until verified.
- Bank reconciliation imports statement CSVs for review and matching. Imported rows do not create journal entries; possible duplicates are flagged for review.
- Inventory supports weighted-average or FIFO costing. Confirmed receipts and issues create explicit journal entries; opening stock is not posted until entered and supported.
- Recurring expenses create reviewable journal drafts when due; schedules do not automatically post entries.
- GST is optional and is not presumed. Configure it only if the business is registered and has valid tax documents.

CHART OF ACCOUNTS AND LEDGERS
Open Administration → Chart of Accounts to create and edit journal accounts. Deleting an account with journal history archives it so posted entries and drafts remain intact. Unused custom accounts can be permanently deleted. Account changes are recorded in the chart audit history. Ledger lines open the original journal entry for editing or voiding; period-closing entries are view-only.

LEGACY SAMPLE DRAFTS
The app no longer auto-imports or offers the sample/MTR reference drafts. On startup it removes only unposted entries tagged as old sample drafts from the current local books; posted history and ordinary user-created drafts remain. If connected to Supabase, those tagged drafts are removed from the shared copy using revision-checked sync.
