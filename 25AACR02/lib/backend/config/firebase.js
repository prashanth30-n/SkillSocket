const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
// Can use either service account file or environment variables

let firebaseApp = null;

try {
  // Check if Firebase is already initialized
  if (!admin.apps.length) {
    let credential;
    
    // Try to use environment variables first (recommended for production)
    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
      credential = admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'), // Handle newlines in private key
      });
      console.log('🔥 Using Firebase environment variables');
    } else {
      // Fallback to service account file (for local development)
      try {
        const serviceAccount = require('./firebase-service-account.json');
        credential = admin.credential.cert(serviceAccount);
        console.log('🔥 Using Firebase service account file');
      } catch (fileError) {
        console.log('⚠️ Firebase service account file not found');
        throw new Error('No Firebase credentials found. Please set environment variables or add service account file.');
      }
    }
    
    firebaseApp = admin.initializeApp({
      credential,
      projectId: process.env.FIREBASE_PROJECT_ID
    });
    
    console.log('✅ Firebase Admin SDK initialized successfully');
  } else {
    firebaseApp = admin.app();
  }
} catch (error) {
  console.log('⚠️ Firebase Admin SDK not initialized:', error.message);
  console.log('📝 To enable push notifications:');
  console.log('1. Create a Firebase project at https://console.firebase.google.com');
  console.log('2. Generate a service account key (Settings > Service Accounts > Generate new private key)');
  console.log('3. Either:');
  console.log('   a) Place the key as config/firebase-service-account.json, OR');
  console.log('   b) Set environment variables: FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY');
  console.log('4. Update projectId in config/firebase.js');
  console.log('5. Enable Firebase Cloud Messaging in your Firebase project');
}

module.exports = {
  admin,
  firebaseApp,
  isInitialized: () => firebaseApp !== null
};
