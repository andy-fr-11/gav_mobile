#!/usr/bin/env node
// Usage:
// node scripts/create_firebase_admin.js --serviceAccount=./serviceAccountKey.json --email=admin@example.com --password=YourPass123 --displayName="Admin"

const fs = require('fs');
const path = require('path');

function parseArgs() {
  const args = {};
  process.argv.slice(2).forEach(arg => {
    const m = arg.match(/^--([a-zA-Z0-9_-]+)=(.*)$/);
    if (m) args[m[1]] = m[2];
  });
  return args;
}

async function main() {
  const args = parseArgs();
  const serviceAccountPath = args.serviceAccount;
  const email = args.email;
  const password = args.password;
  const displayName = args.displayName || 'Administrator';

  if (!serviceAccountPath || !email || !password) {
    console.error('Missing required args. See top of file for usage.');
    process.exit(2);
  }

  const admin = require('firebase-admin');

  const absPath = path.isAbsolute(serviceAccountPath)
    ? serviceAccountPath
    : path.join(process.cwd(), serviceAccountPath);

  if (!fs.existsSync(absPath)) {
    console.error('Service account file not found:', absPath);
    process.exit(2);
  }

  const serviceAccount = require(absPath);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });

  try {
    const userRecord = await admin.auth().createUser({
      email,
      emailVerified: true,
      password,
      displayName,
      disabled: false,
    });

    // Set admin custom claim
    await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });

    // Also create a Firestore user document in 'users' collection matching the app model
    const firestore = admin.firestore();
    const uid = userRecord.uid;
    const names = displayName.split(' ');
    const prenom = names.length > 0 ? names[0] : 'Admin';
    const nom = names.length > 1 ? names.slice(1).join(' ') : 'User';

    const userDoc = {
      nom: nom,
      prenom: prenom,
      sexe: '',
      dateNaissance: admin.firestore.Timestamp.fromDate(new Date(1990, 0, 1)),
      telephone: '',
      email: email,
      photo: '',
      role: 'admin',
      statut: 'actif',
      adresse: '',
      createdAt: admin.firestore.Timestamp.fromDate(new Date()),
    };

    await firestore.collection('users').doc(uid).set(userDoc);

    console.log('User created successfully:');
    console.log('  uid:', uid);
    console.log('  email:', userRecord.email);
    console.log('  password:', password);
    console.log('  firestore document: users/%s', uid);
    console.log('\nImportant: delete or secure the service account file after use.');
  } catch (err) {
    console.error('Error creating user:', err.message || err);
    process.exit(1);
  }
}

main();
