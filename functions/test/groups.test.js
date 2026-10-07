const chai = require("chai");
const expect = chai.expect;
const fs = require("fs");
const path = require("path");
const groups = require("../groups.js");

describe("Group names", () => {
  it("gives a group's English name, and nothing for an unknown group", () => {
    expect(groups.groupNameEn("gajanan_maharaj_seattle"))
        .to.equal("Seattle GM Parivar");
    expect(groups.groupNameEn("nope")).to.equal("");
    expect(groups.groupNameEn(undefined)).to.equal("");
    expect(groups.groupNameEn("__proto__")).to.equal("");
  });

  it("matches every group in the app's own config", () => {
    const config = JSON.parse(fs.readFileSync(
        path.join(__dirname, "../../resources/config/app_config.json"),
        "utf8"));
    const fromApp = {};
    for (const group of config.gajanan_maharaj_groups) {
      fromApp[group.id] = group.name_en;
    }
    expect(groups.GROUP_NAMES).to.deep.equal(fromApp);
  });
});
