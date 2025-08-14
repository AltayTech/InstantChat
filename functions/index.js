const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

exports.sendChatNotification = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const chatId = context.params.chatId;
    const senderId = data.senderId;
    const text = typeof data.text === 'string' ? data.text : '';

    if (!chatId || !senderId) {
      return null;
    }

    const parts = chatId.split('_');
    if (parts.length !== 2) {
      return null;
    }
    const [uidA, uidB] = parts;
    const recipientId = senderId === uidA ? uidB : uidA;

    try {
      const [recipientDoc, senderDoc] = await Promise.all([
        db.collection('users').doc(recipientId).get(),
        db.collection('users').doc(senderId).get(),
      ]);

      const token = recipientDoc.get('fcmToken');
      if (!token) {
        return null;
      }

      const senderName = senderDoc.get('name') || 'New message';
      const notification = {
        title: senderName,
        body: text.length > 0 ? text : 'Sent you a message',
      };

      const message = {
        token,
        notification,
        data: {
          chatId,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'chat_messages',
          },
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: false,
              sound: 'default',
            },
          },
        },
      };

      await admin.messaging().send(message);
      return null;
    } catch (err) {
      console.error('sendChatNotification error', err);
      return null;
    }
  });


