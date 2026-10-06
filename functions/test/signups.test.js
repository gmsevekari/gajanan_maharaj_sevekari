const test = require("firebase-functions-test")();
const chai = require("chai");
const sinon = require("sinon");
const expect = chai.expect;
const admin = require("firebase-admin");

describe("Sign-up Cloud Functions", () => {
  let myFunctions;
  let signups;

  before(() => {
    if (admin.initializeApp.restore) admin.initializeApp.restore();
    sinon.stub(admin, "initializeApp");

    myFunctions = require("../index.js");
    signups = require("../signups.js");
  });

  after(() => {
    sinon.restore();
    test.cleanup();
  });

  describe("normalizePhone", () => {
    it("keeps a leading + and the digits, dropping formatting", () => {
      expect(signups.normalizePhone("+1 (425) 555-1234"))
          .to.equal("+14255551234");
      expect(signups.normalizePhone("  +91-98765 43210 "))
          .to.equal("+919876543210");
    });

    it("keeps no + when there is none, and ignores a + elsewhere", () => {
      expect(signups.normalizePhone("425 555 1234")).to.equal("4255551234");
      expect(signups.normalizePhone("1+4255551234")).to.equal("14255551234");
    });

    it("returns an empty string for anything that is not text", () => {
      expect(signups.normalizePhone(undefined)).to.equal("");
      expect(signups.normalizePhone(null)).to.equal("");
      expect(signups.normalizePhone(14255551234)).to.equal("");
      expect(signups.normalizePhone("")).to.equal("");
    });
  });

  describe("planClaim", () => {
    const open = {requiresJoinCode: false};
    const entry = (id, phone, deviceId) => ({id, data: {phone, deviceId}});
    const plan = (overrides = {}) => signups.planClaim({
      signup: open,
      entries: [],
      phone: "+14255551234",
      deviceId: "device_a",
      joinCode: undefined,
      ...overrides,
    });

    it("is NOT_FOUND when no entry has that phone", () => {
      const result = plan({entries: [entry("e1", "+14255559999", null)]});

      expect(result).to.deep.equal({status: "NOT_FOUND"});
    });

    it("never matches an entry that has no phone", () => {
      const result = plan({
        entries: [entry("e1", null, null), entry("e2", "", null)],
      });

      expect(result.status).to.equal("NOT_FOUND");
    });

    it("never matches phone-less entries to a blank or non-numeric phone",
        () => {
          for (const phone of ["", "  ", "abc", undefined]) {
            const result = plan({
              phone,
              entries: [entry("e1", null, null), entry("e2", "", null)],
            });

            expect(result.status, String(phone)).to.equal("NOT_FOUND");
          }
        });

    it("claims every unclaimed entry with that phone and no others", () => {
      const result = plan({
        entries: [
          entry("e1", "+14255551234", null),
          entry("e2", "+1 (425) 555-1234", undefined),
          entry("e3", "+14255559999", null),
        ],
      });

      expect(result).to.deep.equal({
        status: "SUCCESS", count: 2, entryIds: ["e1", "e2"],
      });
    });

    it("requires the country code and number to match exactly", () => {
      const result = plan({
        entries: [
          entry("e1", "4255551234", null),
          entry("e2", "+914255551234", null),
          entry("e3", "+1425555123", null),
        ],
      });

      expect(result.status).to.equal("NOT_FOUND");
    });

    it("is ALREADY_CLAIMED when a matching entry belongs to another device",
        () => {
          const result = plan({
            entries: [entry("e1", "+14255551234", "device_b")],
          });

          expect(result).to.deep.equal({status: "ALREADY_CLAIMED"});
        });

    it("claims nothing when only some matching entries are taken", () => {
      const result = plan({
        entries: [
          entry("e1", "+14255551234", null),
          entry("e2", "+14255551234", "device_b"),
        ],
      });

      expect(result).to.deep.equal({status: "ALREADY_CLAIMED"});
    });

    it("succeeds without rewriting entries already on this device", () => {
      const result = plan({
        entries: [
          entry("e1", "+14255551234", "device_a"),
          entry("e2", "+14255551234", null),
        ],
      });

      expect(result).to.deep.equal({
        status: "SUCCESS", count: 2, entryIds: ["e2"],
      });
    });

    it("succeeds with nothing to write when all are already this device's",
        () => {
          const result = plan({
            entries: [entry("e1", "+14255551234", "device_a")],
          });

          expect(result).to.deep.equal({
            status: "SUCCESS", count: 1, entryIds: [],
          });
        });

    describe("join code", () => {
      const needsCode = {requiresJoinCode: true, joinCode: "ABC123"};
      const entries = [entry("e1", "+14255551234", null)];

      it("is INVALID_JOIN_CODE when missing or wrong", () => {
        for (const joinCode of [undefined, "", "abc123", "WRONG1"]) {
          expect(plan({signup: needsCode, entries, joinCode}))
              .to.deep.equal({status: "INVALID_JOIN_CODE"});
        }
      });

      it("is checked before anything else, even with no matching entry",
          () => {
            const result = plan({
              signup: needsCode, entries: [], joinCode: "WRONG1",
            });

            expect(result.status).to.equal("INVALID_JOIN_CODE");
          });

      it("lets the claim through when right", () => {
        const result = plan({signup: needsCode, entries, joinCode: "ABC123"});

        expect(result.status).to.equal("SUCCESS");
      });

      it("is ignored when the sign-up does not require one", () => {
        const result = plan({entries, joinCode: "anything"});

        expect(result.status).to.equal("SUCCESS");
      });
    });
  });

  describe("claimSignupEntries", () => {
    let txMock; let signupRef; let entriesRef; let signupSnapshot;
    let entrySnapshots;

    const snap = (id, data) => ({id, ref: {id}, data: () => data});
    const call = (data) => test.wrap(myFunctions.claimSignupEntries)({data});
    const validData = {
      signupId: "signup_1",
      phone: "+14255551234",
      deviceId: "device_a",
    };

    beforeEach(() => {
      signupRef = {name: "signupRef"};
      entriesRef = {name: "entriesRef"};
      signupSnapshot = {exists: true, data: () => ({requiresJoinCode: false})};
      entrySnapshots = [];

      txMock = {
        get: sinon.stub().callsFake(async (ref) => {
          if (ref === signupRef) return signupSnapshot;
          return {docs: entrySnapshots};
        }),
        update: sinon.stub(),
      };
      const signupDoc = {
        ...signupRef,
        collection: sinon.stub().withArgs("entries").returns(entriesRef),
      };
      // The function reads signupRef itself; give it back the same object.
      Object.assign(signupRef, signupDoc);

      const firestoreMock = {
        collection: sinon.stub().withArgs("signups").returns({
          doc: sinon.stub().withArgs("signup_1").returns(signupRef),
        }),
        runTransaction: sinon.stub().callsFake((fn) => fn(txMock)),
      };
      sinon.stub(admin, "firestore").get(() => {
        const f = () => firestoreMock;
        f.Timestamp = {now: () => "NOW"};
        return f;
      });
    });

    afterEach(() => {
      sinon.restore();
      sinon.stub(admin, "initializeApp");
    });

    it("returns NOT_FOUND when the sign-up does not exist", async () => {
      signupSnapshot = {exists: false};

      const result = await call(validData);

      expect(result).to.deep.equal({status: "NOT_FOUND"});
      expect(txMock.update.called).to.equal(false);
    });

    it("returns NOT_FOUND when no entry has the phone", async () => {
      entrySnapshots = [snap("e1", {phone: "+14255559999", deviceId: null})];

      const result = await call(validData);

      expect(result.status).to.equal("NOT_FOUND");
      expect(txMock.update.called).to.equal(false);
    });

    it("links every matching unclaimed entry to the device", async () => {
      entrySnapshots = [
        snap("e1", {phone: "+14255551234", deviceId: null}),
        snap("e2", {phone: "+14255551234"}),
        snap("e3", {phone: "+14255559999", deviceId: null}),
      ];

      const result = await call(validData);

      expect(result).to.deep.equal({status: "SUCCESS", count: 2});
      expect(txMock.update.callCount).to.equal(2);
      expect(txMock.update.getCall(0).args[1])
          .to.deep.equal({deviceId: "device_a", claimedAt: "NOW"});
      expect(txMock.update.getCall(0).args[0].id).to.equal("e1");
      expect(txMock.update.getCall(1).args[0].id).to.equal("e2");
    });

    it("refuses and writes nothing when an entry is on another device",
        async () => {
          entrySnapshots = [
            snap("e1", {phone: "+14255551234", deviceId: null}),
            snap("e2", {phone: "+14255551234", deviceId: "device_b"}),
          ];

          const result = await call(validData);

          expect(result).to.deep.equal({status: "ALREADY_CLAIMED"});
          expect(txMock.update.called).to.equal(false);
        });

    it("refuses a wrong join code without reading the entries", async () => {
      signupSnapshot = {
        exists: true,
        data: () => ({requiresJoinCode: true, joinCode: "ABC123"}),
      };
      entrySnapshots = [snap("e1", {phone: "+14255551234", deviceId: null})];

      const result = await call({...validData, joinCode: "WRONG1"});

      expect(result).to.deep.equal({status: "INVALID_JOIN_CODE"});
      expect(txMock.get.callCount).to.equal(1); // the sign-up only
      expect(txMock.update.called).to.equal(false);
    });

    it("accepts the right join code", async () => {
      signupSnapshot = {
        exists: true,
        data: () => ({requiresJoinCode: true, joinCode: "ABC123"}),
      };
      entrySnapshots = [snap("e1", {phone: "+14255551234", deviceId: null})];

      const result = await call({...validData, joinCode: "ABC123"});

      expect(result).to.deep.equal({status: "SUCCESS", count: 1});
    });

    it("rejects missing or malformed arguments", async () => {
      const bad = [
        {},
        {...validData, signupId: ""},
        {...validData, signupId: 5},
        {...validData, signupId: "a/b"},
        {...validData, signupId: "x".repeat(200)},
        {...validData, phone: undefined},
        {...validData, phone: "12345"},
        {...validData, phone: "+" + "1".repeat(40)},
        {...validData, deviceId: ""},
        {...validData, deviceId: 7},
        {...validData, deviceId: "x".repeat(300)},
        {...validData, joinCode: 123},
        {...validData, joinCode: "x".repeat(200)},
      ];
      for (const data of bad) {
        try {
          await call(data);
          expect.fail(`should have rejected ${JSON.stringify(data)}`);
        } catch (error) {
          expect(error.code, JSON.stringify(data)).to.equal("invalid-argument");
        }
      }
      expect(txMock.update.called).to.equal(false);
    });

    it("hides internal errors behind a generic message", async () => {
      txMock.get = sinon.stub().rejects(new Error("secret db detail"));

      try {
        await call(validData);
        expect.fail("should have thrown");
      } catch (error) {
        expect(error.code).to.equal("internal");
        expect(error.message).to.not.contain("secret");
      }
    });
  });
});
