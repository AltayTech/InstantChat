/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions/v2/options";
import * as admin from "firebase-admin";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

admin.initializeApp();

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

export const sendChatMessageNotification = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const chatId = event.params.chatId as string;
    const data = event.data?.data() as {
      senderId: string;
      text?: string;
      senderName?: string;
    } | undefined;
    if (!data) return;

    const chatSnap = await admin.firestore().collection("chats").doc(chatId).get();
    let participants = (chatSnap.get("participants") || []) as string[];
    if (!participants || participants.length === 0) {
      const inferred = chatId.split("_");
      if (inferred.length === 2) participants = inferred;
    }
    const targets = participants.filter((uid) => uid !== data.senderId);
    if (targets.length === 0) return;

    const usersSnap = await admin
      .firestore()
      .collection("users")
      .where("uid", "in", targets)
      .get();
    const tokens: string[] = usersSnap.docs
      .map((d) => d.get("fcmToken"))
      .filter((t: string | null | undefined) => !!t);
    if (tokens.length === 0) return;

    const title = `New message${data.senderName ? ` from ${data.senderName}` : ""}`;
    const body = data.text && data.text.trim().length > 0 ? data.text : "Sent you a message";

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: { chatId },
      android: {
        priority: "high",
        notification: { channelId: "chat_messages", sound: "default" },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: "default",
          },
        },
      },
    });
  }
);

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
