import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Export all functions
export { createPaymentIntent, verifyPayment } from './payments';
export { createOrder, updateOrderStatus, deleteOrder } from './orders';
export { verifyAdminRole } from './auth';
export { sendNotification } from './notifications';
