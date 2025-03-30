"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendReminderNotification = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
exports.sendReminderNotification = functions.firestore
    .document("transferProcesses/{processId}")
    .onUpdate(async (change, context) => {
    var _a, _b;
    const newValue = change.after.data();
    const previousValue = change.before.data();
    const reminders = newValue.erinnerungen || [];
    const now = new Date();
    for (const reminder of reminders) {
        const reminderDate = admin.firestore.Timestamp.fromMillis(reminder.datum._seconds * 1000 + reminder.datum._nanoseconds / 1000000).toDate();
        const wasPreviouslyDue = (_a = previousValue.erinnerungen) === null || _a === void 0 ? void 0 : _a.some((prev) => prev.id === reminder.id && prev.datum.toDate() <= now);
        if (reminderDate <= now && !wasPreviouslyDue) {
            const mitarbeiterID = newValue.mitarbeiterID;
            if (!mitarbeiterID) {
                console.log(`Kein Mitarbeiter für Prozess ${context.params.processId} zugewiesen`);
                continue;
            }
            const userDoc = await admin.firestore().collection("users").doc(mitarbeiterID).get();
            const fcmToken = (_b = userDoc.data()) === null || _b === void 0 ? void 0 : _b.fcmToken;
            if (!fcmToken) {
                console.log(`Kein FCM-Token für Mitarbeiter ${mitarbeiterID} gefunden`);
                continue;
            }
            const message = {
                notification: {
                    title: "Transferprozess Erinnerung",
                    body: reminder.beschreibung,
                },
                data: {
                    processId: context.params.processId,
                    reminderId: reminder.id,
                    kategorie: reminder.kategorie || "Keine",
                },
                token: fcmToken,
            };
            try {
                await admin.messaging().send(message);
                console.log(`Benachrichtigung gesendet für Erinnerung: ${reminder.beschreibung}`);
            }
            catch (error) {
                console.error(`Fehler beim Senden der Benachrichtigung: ${error}`);
            }
        }
    }
});
//# sourceMappingURL=index.js.map