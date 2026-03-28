const admin = require("firebase-admin");

// Initialize Firebase Admin once at the entry point
admin.initializeApp();

/**
 * Re-export functions from modular files.
 * This keeps index.js clean while maintaining the same deployment interface.
 */

const parayan = require("./parayan");
const notifications = require("./notifications");

// Parayan Management
exports.updateParayanStatuses = parayan.updateParayanStatuses;
exports.allocateParayanAdhyays = parayan.allocateParayanAdhyays;
exports.adminAddParticipants = parayan.adminAddParticipants;

// Notifications & Reminders
exports.sendTempleNotification = notifications.sendTempleNotification;
exports.sendParayanReminders = notifications.sendParayanReminders;
