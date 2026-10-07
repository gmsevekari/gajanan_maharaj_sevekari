/**
 * The groups' English names, for messages the server writes. The app reads
 * the same names from its bundled resources/config/app_config.json, which a
 * Cloud Function cannot; test/signupReminders.test.js fails if the two ever
 * differ, so add a group in both places.
 */
const GROUP_NAMES = {
  gajanan_maharaj_seattle: "Seattle GM Parivar",
  gajanan_gunjan: "Gajanan Gunjan",
};

/**
 * @param {*} groupId A group's id.
 * @return {string} Its English name, or "" for an unknown group.
 */
function groupNameEn(groupId) {
  if (typeof groupId !== "string") return "";
  return Object.hasOwn(GROUP_NAMES, groupId) ? GROUP_NAMES[groupId] : "";
}

exports.GROUP_NAMES = GROUP_NAMES;
exports.groupNameEn = groupNameEn;
