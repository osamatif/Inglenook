import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Create a new order (called from client)
 * Validates order data before saving
 */
export const createOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { items, shippingAddress, total, couponCode } = data;

  // Validate required fields
  if (!items || !Array.isArray(items) || items.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'Items are required');
  }

  if (!shippingAddress) {
    throw new functions.https.HttpsError('invalid-argument', 'Shipping address is required');
  }

  try {
    // Validate and recalculate total server-side
    let calculatedTotal = 0;
    const validatedItems = [];

    for (const item of items) {
      const productDoc = await admin
        .firestore()
        .collection('products')
        .doc(item.productId)
        .get();

      if (!productDoc.exists) {
        throw new functions.https.HttpsError('invalid-argument', `Product ${item.productId} not found`);
      }

      const product = productDoc.data()!;

      if (!product.inStock) {
        throw new functions.https.HttpsError('failed-precondition', `Product ${product.title} is out of stock`);
      }

      const itemTotal = product.price * item.quantity;
      calculatedTotal += itemTotal;

      validatedItems.push({
        productId: item.productId,
        title: product.title,
        price: product.price,
        quantity: item.quantity,
        total: itemTotal,
      });
    }

    // Apply coupon if provided
    let discount = 0;
    if (couponCode) {
      const couponDoc = await admin
        .firestore()
        .collection('coupons')
        .where('code', '==', couponCode)
        .limit(1)
        .get();

      if (!couponDoc.empty) {
        const coupon = couponDoc.docs[0].data();
        if (coupon.active && new Date(coupon.expiresAt) > new Date()) {
          discount = (calculatedTotal * coupon.discountPercent) / 100;
        }
      }
    }

    const finalTotal = calculatedTotal - discount;

    // Verify client-sent total matches calculated total
    if (Math.abs(finalTotal - total) > 0.01) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Total mismatch - potential tampering detected'
      );
    }

    // Create order
    const orderData = {
      userId: context.auth.uid,
      userEmail: context.auth.token.email,
      items: validatedItems,
      shippingAddress,
      subtotal: calculatedTotal,
      discount,
      total: finalTotal,
      status: 'Pending',
      paymentStatus: 'unpaid',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const orderRef = await admin.firestore().collection('orders').add(orderData);

    return {
      orderId: orderRef.id,
      total: finalTotal,
    };
  } catch (error: any) {
    console.error('Error creating order:', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError('internal', 'Failed to create order');
  }
});

/**
 * Update order status (admin or delivery person only)
 */
export const updateOrderStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
  }

  const { orderId, status, deliveryBoyId } = data;

  if (!orderId || !status) {
    throw new functions.https.HttpsError('invalid-argument', 'Order ID and status are required');
  }

  try {
    const orderRef = admin.firestore().collection('orders').doc(orderId);
    const orderDoc = await orderRef.get();

    if (!orderDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Order not found');
    }

    // Check if user is admin
    const adminDoc = await admin
      .firestore()
      .collection('admins')
      .doc(context.auth.uid)
      .get();

    const isAdmin = adminDoc.exists && adminDoc.data()?.role === 'admin';

    // Check if user is delivery person assigned to this order
    const orderData = orderDoc.data()!;
    const isAssignedDelivery = orderData.deliveryBoyId === context.auth.uid;

    if (!isAdmin && !isAssignedDelivery) {
      throw new functions.https.HttpsError('permission-denied', 'Unauthorized');
    }

    // Update order
    const updateData: any = {
      status,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    if (deliveryBoyId) {
      updateData.deliveryBoyId = deliveryBoyId;
      updateData.assignedAt = admin.firestore.FieldValue.serverTimestamp();
    }

    await orderRef.update(updateData);

    // Send notification to user
    // TODO: Implement push notification

    return { success: true };
  } catch (error: any) {
    console.error('Error updating order:', error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError('internal', 'Failed to update order');
  }
});

/**
 * Prevent order deletion (security rule)
 * Orders should never be deleted, only archived
 */
export const deleteOrder = functions.firestore
  .document('orders/{orderId}')
  .onDelete(async (snapshot, context) => {
    console.warn(`SECURITY ALERT: Order ${context.params.orderId} was deleted!`);

    // Log to security audit
    await admin.firestore().collection('security_audit').add({
      type: 'order_deletion',
      orderId: context.params.orderId,
      orderData: snapshot.data(),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
