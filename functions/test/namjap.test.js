const test = require("firebase-functions-test")();
const chai = require("chai");
const sinon = require("sinon");
const expect = chai.expect;
const admin = require("firebase-admin");
const {DateTime, Settings} = require("luxon");

describe("Namjap Cloud Functions", () => {
  let myFunctions;
  let firestoreMock;

  before(() => {
    if (admin.initializeApp.restore) admin.initializeApp.restore();
    sinon.stub(admin, "initializeApp");

    myFunctions = require("../index.js");
  });

  after(() => {
    sinon.restore();
    test.cleanup();
    Settings.now = () => Date.now(); // Reset luxon time
  });

  describe("updateNamjapStatuses", () => {
    let enrollingGetStub; let ongoingGetStub;

    beforeEach(() => {
      firestoreMock = {
        collection: sinon.stub(),
      };

      if (admin.app.restore) admin.app.restore();
      sinon.stub(admin, "app").returns({
        firestore: () => firestoreMock,
      });

      if (admin.firestore.restore) admin.firestore.restore();
      sinon.stub(admin, "firestore").returns(firestoreMock);

      enrollingGetStub = sinon.stub();
      ongoingGetStub = sinon.stub();

      firestoreMock.collection.withArgs("group_namjap_events").returns({
        where: sinon.stub().callsFake((field, op, value) => {
          if (value === "enrolling") return {get: enrollingGetStub};
          if (value === "ongoing") return {get: ongoingGetStub};
          return {get: sinon.stub().resolves({docs: []})};
        }),
      });
    });

    afterEach(() => {
      sinon.restore();
    });

    it("should transition enrolling to ongoing if start time is reached",
        async () => {
          // Set "now" to April 25, 2026 11:30 AM IST
          const now = DateTime.fromISO("2026-04-25T11:30:00",
              {zone: "Asia/Kolkata"});
          Settings.now = () => now.toMillis();

          const startDate = now; // Exactly 11:30 AM
          const updateStub = sinon.stub().resolves();

          enrollingGetStub.resolves({
            docs: [{
              id: "event_1",
              data: () => ({
                startDate: {toDate: () => startDate.toJSDate()},
                timezone: "Asia/Kolkata",
                status: "enrolling",
              }),
              ref: {update: updateStub},
            }],
          });
          ongoingGetStub.resolves({docs: []});

          const wrapped = test.wrap(myFunctions.updateNamjapStatuses);
          await wrapped({});

          expect(updateStub.calledWith({status: "ongoing"})).to.be.true;
        });

    it("should NOT transition enrolling if start time is not reached",
        async () => {
          // Set "now" to April 25, 2026 11:29 AM IST
          const now = DateTime.fromISO("2026-04-25T11:29:00",
              {zone: "Asia/Kolkata"});
          Settings.now = () => now.toMillis();

          const startDate = now.plus({minutes: 1}); // Scheduled for 11:30 AM
          const updateStub = sinon.stub().resolves();

          enrollingGetStub.resolves({
            docs: [{
              id: "event_2",
              data: () => ({
                startDate: {toDate: () => startDate.toJSDate()},
                timezone: "Asia/Kolkata",
                status: "enrolling",
              }),
              ref: {update: updateStub},
            }],
          });
          ongoingGetStub.resolves({docs: []});

          const wrapped = test.wrap(myFunctions.updateNamjapStatuses);
          await wrapped({});

          expect(updateStub.called).to.be.false;
        });

    it("should transition ongoing to completed after end time has passed",
        async () => {
          // Set "now" to April 25, 2026 12:00 PM
          const now = DateTime.fromISO("2026-04-25T12:00:00",
              {zone: "America/Los_Angeles"});
          Settings.now = () => now.toMillis();

          const endDate = now.minus({minutes: 1}); // Ended at 11:59 AM
          const updateStub = sinon.stub().resolves();

          enrollingGetStub.resolves({docs: []});
          ongoingGetStub.resolves({
            docs: [{
              id: "event_3",
              data: () => ({
                endDate: {toDate: () => endDate.toJSDate()},
                timezone: "America/Los_Angeles",
                status: "ongoing",
              }),
              ref: {update: updateStub},
            }],
          });

          const wrapped = test.wrap(myFunctions.updateNamjapStatuses);
          await wrapped({});

          expect(updateStub.calledWith({status: "completed"})).to.be.true;
        });

    it("should NOT transition ongoing to completed if end time is NOW",
        async () => {
          const now = DateTime.fromISO("2026-04-25T12:00:00",
              {zone: "America/Los_Angeles"});
          Settings.now = () => now.toMillis();

          const endDate = now; // Ends exactly at 12:00 PM
          const updateStub = sinon.stub().resolves();

          enrollingGetStub.resolves({docs: []});
          ongoingGetStub.resolves({
            docs: [{
              id: "event_4",
              data: () => ({
                endDate: {toDate: () => endDate.toJSDate()},
                timezone: "America/Los_Angeles",
                status: "ongoing",
              }),
              ref: {update: updateStub},
            }],
          });

          const wrapped = test.wrap(myFunctions.updateNamjapStatuses);
          await wrapped({});

          // Should only complete AFTER endDate
          expect(updateStub.called).to.be.false;
        });
  });
});
