import { initializeApp, getApps, getApp } from 'firebase/app';
import { getFirestore, Firestore } from 'firebase/firestore';
import firebaseConfig from '../../firebase-applet-config.json';

let app;
let db: Firestore;

try {
  app = !getApps().length ? initializeApp(firebaseConfig) : getApp();
  // If a specific database ID was provided during provisioning, use it; otherwise fallback to default
  const databaseId = firebaseConfig.firestoreDatabaseId && firebaseConfig.firestoreDatabaseId.trim() !== ''
    ? firebaseConfig.firestoreDatabaseId
    : '(default)';
  
  db = getFirestore(app, databaseId);
  console.log('[Firebase] Initialized with database ID:', databaseId);
} catch (err) {
  console.error('[Firebase] Initialization error:', err);
  app = !getApps().length ? initializeApp(firebaseConfig) : getApp();
  db = getFirestore(app);
}

export { app, db, firebaseConfig };
