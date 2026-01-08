import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Send push notification to user
 */
export const sendNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  // Verify sender is admin
  const adminDoc = await admin
    .firestore()
    .collection('admins')
    .doc(context.auth.uid)
    .get();

  if (!adminDoc.exists || adminDoc.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Only admins can send notifications');
  }

  const { userId, title, body, data: notificationData } = data;

  if (!userId || !title || !body) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'User ID, title, and body are required'
    );
  }

  try {
    // Get user's FCM token
    const userDoc = await admin.firestore().collection('users').doc(userId).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'User has no FCM token registered'
      );
    }

    // Send notification
    const message = {
      notification: {
        title,
        body,
      },
      data: notificationData || {},
      token: fcmToken,
    };

    const response = await admin.messaging().send(message);

    // Store notification in database
    await admin.firestore().collection('notifications').add({
      userId,
      title,
      body,
      data: notificationData,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      messageId: response,
    });

    return { success: true, messageId: response };
  } catch (error: any) {
    console.error('Error sending notification:', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError('internal', 'Failed to send notification');
  }
});

/**
 * Send notification when order status changes
 */
export const notifyOrderStatusChange = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only send if status actually changed
    if (before.status === after.status) {
      return;
    }

    const userId = after.userId;

    // Get user's FCM token
    const userDoc = await admin.firestore().collection('users').doc(userId).get();

    if (!userDoc.exists) {
      console.log('User not found for notification');
      return;
    }

    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log('User has no FCM token');
      return;
    }

    // Create notification message
    const statusMessages: Record<string, string> = {
      Processing: 'Your order is being prepared',
      'Out for Delivery': 'Your order is on the way!',
      Delivered: 'Your order has been delivered',
      Cancelled: 'Your order has been cancelled',
    };

    const message = {
      notification: {
        title: 'Order Status Update',
        body: statusMessages[after.status] || `Order status: ${after.status}`,
      },
      data: {
        orderId: context.params.orderId,
        status: after.status,
        type: 'order_status',
      },
      token: fcmToken,
    };

    try {
      await admin.messaging().send(message);
      console.log(`Notification sent to user ${userId} for order ${context.params.orderId}`);
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  });
