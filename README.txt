AETHEL COLLECTIVE — Premium Books App

FILES
- index.html: complete accounting app
- AethelMonogram.png: current AETHEL monogram, browser icon and install icon
- manifest.webmanifest: installable desktop and mobile app settings
- service-worker.js: offline app-shell cache
- vercel.json: static Vercel settings

DEPLOY TO THE CONNECTED GITHUB REPOSITORY
1. Extract the AETHEL-Vercel folder from the ZIP.
2. Copy all six files into the root of your GitHub repository, replacing the old site files.
3. Commit and push. Vercel will redeploy from the connected repository.
4. In Vercel project settings, use the repository root, Framework Preset “Other”, no Build Command, and the repository root as the output directory.

USE AS A DESKTOP OR MOBILE APP
Deploy the site over HTTPS first. On a computer, open it in Microsoft Edge or Chrome and choose the browser’s Install app option. On Android, use the browser’s Install app or Add to Home screen option. On iPhone or iPad, open the site in Safari and use Share → Add to Home Screen. Menu wording may vary by browser version. The installed app opens in a standalone AETHEL-branded window.

MOBILE AND DESKTOP
The app adjusts its workspace for desktop and phone screens. On phones, swipe the bottom navigation strip sideways to reach every section.

DATA STORAGE
Book data is saved in browser local storage on the current device. It does not sync between users or devices. Use Settings → Download backup regularly. The offline cache stores the app files only; it does not replace or back up accounting data.

MTR DATA
Imported account names and transaction descriptions are in the app as drafts. Confirm each date, amount, and account split against the original books before posting.
