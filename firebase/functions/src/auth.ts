import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Verify if user has admin role
 * Used by client apps before showing admin features
 */
export const verifyAdminRole = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    return { isAdmin: false };
  }

  try {
    const adminDoc = await admin
      .firestore()
      .collection('admins')
      .doc(context.auth.uid)
      .get();

    const isAdmin = adminDoc.exists && adminDoc.data()?.role === 'admin';

    // Set custom claim for faster future checks
    if (isAdmin) {
      await admin.auth().setCustomUserClaims(context.auth.uid, {
        admin: true,
      });
    }

    return {
      isAdmin,
      role: adminDoc.data()?.role || 'user',
    };
  } catch (error) {
    console.error('Error verifying admin role:', error);
    return { isAdmin: false };
  }
});

/**
 * Create admin user (can only be called by existing admin)
 */
export const createAdmin = functions.https.onCall(async (data, context) => {
  // Verify caller is admin
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const callerAdminDoc = await admin
    .firestore()
    .collection('admins')
    .doc(context.auth.uid)
    .get();

  if (!callerAdminDoc.exists || callerAdminDoc.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can create admins');
  }

  const { email, password, name } = data;

  if (!email || !password || !name) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email, password, and name are required'
    );
  }

  try {
    // Create user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });

    // Set custom claims
    await admin.auth().setCustomUserClaims(userRecord.uid, {
      admin: true,
    });

    // Add to admins collection
    await admin.firestore().collection('admins').doc(userRecord.uid).set({
      email,
      name,
      role: 'admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: context.auth.uid,
    });

    return {
      uid: userRecord.uid,
      email: userRecord.email,
    };
  } catch (error: any) {
    console.error('Error creating admin:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
