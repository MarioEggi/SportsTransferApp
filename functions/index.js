import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const sendReminderNotification = functions.firestore
    .document("transferProcesses/{processId}")
    .onUpdate(async (change, context) => {
        const newValue = change.after.data() as TransferProcess;
        const previousValue = change.before.data() as TransferProcess;
        const reminders = newValue.erinnerungen || [];

        const now = new Date();

        for (const reminder of reminders) {
            const reminderDate = admin.firestore.Timestamp.fromMillis(
                reminder.datum._seconds * 1000 + reminder.datum._nanoseconds / 1000000
            ).toDate();

            const wasPreviouslyDue = previousValue.erinnerungen?.some(
                (prev) => prev.id === reminder.id && prev.datum.toDate() <= now
            );
            if (reminderDate <= now && !wasPreviouslyDue) {
                const mitarbeiterID = newValue.mitarbeiterID;
                if (!mitarbeiterID) {
                    console.log(`Kein Mitarbeiter für Prozess ${context.params.processId} zugewiesen`);
                    continue;
                }

                const userDoc = await admin.firestore().collection("users").doc(mitarbeiterID).get();
                const fcmToken = userDoc.data()?.fcmToken;

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
                } catch (error) {
                    console.error(`Fehler beim Senden der Benachrichtigung: ${error}`);
                }
            }
        }
    });

interface TransferProcess {
    id?: string;
    clientID: string;
    vereinID: string;
    status: string;
    startDatum: admin.firestore.Timestamp;
    schritte: Step[];
    erinnerungen?: Reminder[];
    hinweise?: Note[];
    transferDetails?: TransferDetails;
    mitarbeiterID?: string;
    priority?: number;
}

interface Step {
    id: string;
    typ: string;
    status: string;
    datum: admin.firestore.Timestamp;
    notizen?: string;
    erfolgschance?: number;
    checkliste?: string[];
}

interface Reminder {
    id: string;
    datum: admin.firestore.Timestamp;
    beschreibung: string;
    kategorie?: string;
}

interface Note {
    id: string;
    beschreibung: string;
    vereinsDokumente?: string[];
}

interface TransferDetails {
    id?: string;
    vonVereinID?: string;
    zuVereinID?: string;
    funktionärID?: string;
    datum: admin.firestore.Timestamp;
    ablösesumme?: number;
    isAblösefrei: boolean;
    transferdetails?: string;
}