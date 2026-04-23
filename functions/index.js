const admin = require("firebase-admin");

// Initialize Firebase Admin once at the entry point
admin.initializeApp();

/**
 * Re-export functions from modular files.
 * This keeps index.js clean while maintaining the same deployment interface.
 */

const parayan = require("./parayan");
const notifications = require("./notifications");
const namjap = require("./namjap");

// Parayan Management
exports.updateParayanStatuses = parayan.updateParayanStatuses;
exports.allocateParayanAdhyays = parayan.allocateParayanAdhyays;
exports.adminAddParticipants = parayan.adminAddParticipants;
exports.claimParayanAllocation = parayan.claimParayanAllocation;

// Group Namjap Management
exports.updateNamjapStatuses = namjap.updateNamjapStatuses;

// Notifications & Reminders
exports.sendTempleNotification = notifications.sendTempleNotification;
exports.sendParayanReminders = notifications.sendParayanReminders;
exports.onTypoReportCreated = notifications.onTypoReportCreated;
