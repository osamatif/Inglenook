import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';

// Initialize Stripe - secret key stored in Firebase config
// Set with: firebase functions:config:set stripe.secret_key="sk_live_..."
const stripe = new Stripe(
  functions.config().stripe?.secret_key || 'sk_test_YOUR_KEY',
  { apiVersion: '2023-10-16' }
);

/**
 * Create a Stripe payment intent
 * Called from client app when user initiates payment
 *
 * SECURITY: This function validates:
 * - User is authenticated
 * - Order exists and belongs to user
 * - Amount matches order total
 * - Order hasn't been paid already
 */
export const createPaymentIntent = functions.https.onCall(
  async (data, context) => {
    // 1. Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be logged in to create payment'
      );
    }

    const { orderId, currency = 'usd' } = data;

    // 2. Validate input
    if (!orderId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Order ID is required'
      );
    }

    try {
      // 3. Get order from Firestore
      const orderRef = admin.firestore().collection('orders').doc(orderId);
      const orderDoc = await orderRef.get();

      if (!orderDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Order not found'
        );
      }

      const orderData = orderDoc.data()!;

      // 4. Verify order belongs to user
      if (orderData.userId !== context.auth.uid) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'This order does not belong to you'
        );
      }

      // 5. Check if order is already paid
      if (orderData.paymentStatus === 'paid') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Order has already been paid'
        );
      }

      // 6. Validate amount
      const amount = orderData.total;
      if (!amount || amount <= 0) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid order amount'
        );
      }

      // 7. Create Stripe payment intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convert to cents
        currency: currency,
        metadata: {
          orderId: orderId,
          userId: context.auth.uid,
          userEmail: context.auth.token.email || '',
        },
        description: `Inglenook Order ${orderId}`,
      });

      // 8. Store payment intent ID in order
      await orderRef.update({
        paymentIntentId: paymentIntent.id,
        paymentStatus: 'pending',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 9. Return client secret to complete payment
      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      };
    } catch (error: any) {
      // Log error
      console.error('Error creating payment intent:', error);

      // Throw appropriate error
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to create payment intent'
      );
    }
  }
);

/**
 * Verify payment completion
 * Called from client after payment succeeds
 */
export const verifyPayment = functions.https.onCall(
  async (data, context) => {
    // 1. Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be logged in'
      );
    }

    const { paymentIntentId } = data;

    if (!paymentIntentId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Payment Intent ID is required'
      );
    }

    try {
      // 2. Retrieve payment intent from Stripe
      const paymentIntent = await stripe.paymentIntents.retrieve(
        paymentIntentId
      );

      // 3. Verify payment succeeded
      if (paymentIntent.status !== 'succeeded') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Payment has not succeeded'
        );
      }

      // 4. Find order by payment intent ID
      const ordersSnapshot = await admin
        .firestore()
        .collection('orders')
        .where('paymentIntentId', '==', paymentIntentId)
        .limit(1)
        .get();

      if (ordersSnapshot.empty) {
        throw new functions.https.HttpsError(
          'not-found',
          'Order not found for this payment'
        );
      }

      const orderDoc = ordersSnapshot.docs[0];
      const orderData = orderDoc.data();

      // 5. Verify order belongs to user
      if (orderData.userId !== context.auth.uid) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Unauthorized'
        );
      }

      // 6. Update order status
      await orderDoc.ref.update({
        paymentStatus: 'paid',
        status: 'Processing',
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        orderId: orderDoc.id,
      };
    } catch (error: any) {
      console.error('Error verifying payment:', error);

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to verify payment'
      );
    }
  }
);

/**
 * Webhook handler for Stripe events
 * Automatically updates order status when payment succeeds
 *
 * Configure webhook in Stripe dashboard:
 * URL: https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/stripeWebhook
 * Events: payment_intent.succeeded, payment_intent.payment_failed
 */
export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'] as string;

  let event: Stripe.Event;

  try {
    // Verify webhook signature
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig,
      functions.config().stripe?.webhook_secret || ''
    );
  } catch (err: any) {
    console.error('Webhook signature verification failed:', err.message);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  // Handle the event
  switch (event.type) {
    case 'payment_intent.succeeded': {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;

      // Update order status
      const ordersSnapshot = await admin
        .firestore()
        .collection('orders')
        .where('paymentIntentId', '==', paymentIntent.id)
        .limit(1)
        .get();

      if (!ordersSnapshot.empty) {
        await ordersSnapshot.docs[0].ref.update({
          paymentStatus: 'paid',
          status: 'Processing',
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      break;
    }

    case 'payment_intent.payment_failed': {
      const paymentIntent = event.data.object as Stripe.PaymentIntent;

      // Update order status
      const ordersSnapshot = await admin
        .firestore()
        .collection('orders')
        .where('paymentIntentId', '==', paymentIntent.id)
        .limit(1)
        .get();

      if (!ordersSnapshot.empty) {
        await ordersSnapshot.docs[0].ref.update({
          paymentStatus: 'failed',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      break;
    }

    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.json({ received: true });
});
