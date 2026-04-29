const test = require("firebase-functions-test")();
const chai = require("chai");
const sinon = require("sinon");
const expect = chai.expect;
const admin = require("firebase-admin");
const {DateTime, Settings} = require("luxon");

describe("Parayan Cloud Functions", () => {
  let myFunctions;
  let firestoreMock;

  before(() => {
    // Prepare firestoreMock early
    firestoreMock = {
      collection: sinon.stub(),
      batch: sinon.stub(),
    };

    // Stub admin.initializeApp so it doesn't try to connect to real Firebase
    if (admin.initializeApp.restore) admin.initializeApp.restore();
    sinon.stub(admin, "initializeApp");

    // Stub admin.app() to return a mock app to satisfy internal checks
    if (admin.app.restore) admin.app.restore();
    sinon.stub(admin, "app").returns({
      firestore: () => firestoreMock,
    });
    myFunctions = require("../index.js");
  });

  after(() => {
    sinon.restore();
    test.cleanup();
    Settings.now = () => Date.now(); // Reset luxon time
  });

  describe("updateParayanStatuses", () => {
    let allocatedGetStub; let ongoingGetStub;

    beforeEach(() => {
      firestoreMock = {
        collection: sinon.stub(),
      };

      if (admin.firestore.restore) admin.firestore.restore();
      sinon.stub(admin, "firestore").returns(firestoreMock);

      allocatedGetStub = sinon.stub();
      ongoingGetStub = sinon.stub();

      firestoreMock.collection.withArgs("parayan_events").returns({
        where: sinon.stub().callsFake((field, op, value) => {
          if (value === "allocated") return {get: allocatedGetStub};
          if (value === "ongoing") return {get: ongoingGetStub};
          return {get: sinon.stub().resolves({docs: []})};
        }),
      });
    });

    it("should transition allocated to ongoing if start time is reached",
        async () => {
          const now = DateTime.fromISO("2026-04-25T11:30:00",
              {zone: "Asia/Kolkata"});
          Settings.now = () => now.toMillis();

          const startDate = now;
          const updateStub = sinon.stub().resolves();

          allocatedGetStub.resolves({
            docs: [{
              id: "p1",
              data: () => ({
                startDate: {toDate: () => startDate.toJSDate()},
                timezone: "Asia/Kolkata",
                status: "allocated",
              }),
              ref: {update: updateStub},
            }],
          });
          ongoingGetStub.resolves({docs: []});

          const wrapped = test.wrap(myFunctions.updateParayanStatuses);
          await wrapped({});

          expect(updateStub.calledWith({status: "ongoing"})).to.be.true;
        });

    it("should NOT transition allocated if start time is in future",
        async () => {
          const now = DateTime.fromISO("2026-04-25T11:29:00",
              {zone: "Asia/Kolkata"});
          Settings.now = () => now.toMillis();

          const startDate = now.plus({minutes: 1});
          const updateStub = sinon.stub().resolves();

          allocatedGetStub.resolves({
            docs: [{
              id: "p2",
              data: () => ({
                startDate: {toDate: () => startDate.toJSDate()},
                timezone: "Asia/Kolkata",
                status: "allocated",
              }),
              ref: {update: updateStub},
            }],
          });
          ongoingGetStub.resolves({docs: []});

          const wrapped = test.wrap(myFunctions.updateParayanStatuses);
          await wrapped({});

          expect(updateStub.called).to.be.false;
        });

    it("should transition ongoing to completed after end time has passed",
        async () => {
          const now = DateTime.fromISO("2026-04-25T12:00:00",
              {zone: "America/Los_Angeles"});
          Settings.now = () => now.toMillis();

          const endDate = now.minus({minutes: 1});
          const updateStub = sinon.stub().resolves();

          allocatedGetStub.resolves({docs: []});
          ongoingGetStub.resolves({
            docs: [{
              id: "p3",
              data: () => ({
                endDate: {toDate: () => endDate.toJSDate()},
                timezone: "America/Los_Angeles",
                status: "ongoing",
              }),
              ref: {update: updateStub},
            }],
          });

          const wrapped = test.wrap(myFunctions.updateParayanStatuses);
          await wrapped({});

          expect(updateStub.calledWith({status: "completed"})).to.be.true;
        });

    it("should delay transition for gajanan_gunjan by 2 days",
        async () => {
          const now = DateTime.fromISO("2026-04-25T12:00:00",
              {zone: "America/Los_Angeles"});
          Settings.now = () => now.toMillis();

          // End date is 1 day ago (less than 2 days delay)
          const endDate = now.minus({days: 1});
          const updateStub = sinon.stub().resolves();

          allocatedGetStub.resolves({docs: []});
          ongoingGetStub.resolves({
            docs: [{
              id: "p_gunjan",
              data: () => ({
                endDate: {toDate: () => endDate.toJSDate()},
                timezone: "America/Los_Angeles",
                status: "ongoing",
                groupId: "gajanan_gunjan",
              }),
              ref: {update: updateStub},
            }],
          });

          const wrapped = test.wrap(myFunctions.updateParayanStatuses);
          await wrapped({});

          // Should NOT be completed yet
          expect(updateStub.called).to.be.false;

          // Move time forward past 2 days from endDate
          // endDate was now - 1 day, so we need to move past now + 1 day
          const later = now.plus({days: 1, minutes: 1});
          Settings.now = () => later.toMillis();

          await wrapped({});
          expect(updateStub.calledWith({status: "completed"})).to.be.true;
        });
  });

  describe("claimParayanAllocation", () => {
    let whereStub; let getStub; let batchMock;

    beforeEach(() => {
      batchMock = {
        update: sinon.stub(),
        commit: sinon.stub().resolves(),
      };

      firestoreMock = {
        collection: sinon.stub(),
        batch: sinon.stub().returns(batchMock),
      };

      // Stub admin.firestore property accessor or method
      sinon.stub(admin, "firestore").returns(firestoreMock);

      const participantsCollectionMock = {
        where: sinon.stub(),
        doc: sinon.stub(),
      };

      const eventDocMock = {
        collection: sinon.stub().withArgs("participants")
            .returns(participantsCollectionMock),
      };

      const eventsCollectionMock = {
        doc: sinon.stub().returns(eventDocMock),
      };

      firestoreMock.collection.withArgs("parayan_events")
          .returns(eventsCollectionMock);

      whereStub = participantsCollectionMock.where;
      getStub = sinon.stub();
      whereStub.returns({get: getStub});
    });

    afterEach(() => {
      if (admin.firestore.restore) admin.firestore.restore();
    });

    it("should return NOT_FOUND if no participant found with phone",
        async () => {
          getStub.resolves({empty: true});

          const wrapped = test.wrap(myFunctions.claimParayanAllocation);
          const result = await wrapped({
            data: {
              eventId: "event_123",
              phone: "+911234567890",
              deviceId: "device_abc",
            },
          });

          expect(result.status).to.equal("NOT_FOUND");
          expect(result.message).to.contain("No participant found");
        });

    it("should return CONFLICT if device is linked and overwrite is false",
        async () => {
          getStub.resolves({
            empty: false,
            forEach: (cb) => {
              cb({
                id: "p1",
                data: () => ({
                  name: "User A",
                  deviceId: "other_device",
                  phone: "+911234567890",
                }),
              });
            },
          });

          const wrapped = test.wrap(myFunctions.claimParayanAllocation);
          const result = await wrapped({
            data: {
              eventId: "event_123",
              phone: "+911234567890",
              deviceId: "device_abc",
              overwrite: false,
            },
          });

          expect(result.status).to.equal("CONFLICT");
          expect(result.message).to.contain("already linked to another device");
        });

    it("should return SUCCESS and update records if overwrite is true",
        async () => {
          getStub.resolves({
            empty: false,
            forEach: (cb) => {
              cb({
                id: "p1",
                data: () => ({
                  name: "User A",
                  deviceId: "other_device",
                  phone: "+911234567890",
                  assignedAdhyays: [5],
                }),
              });
            },
          });

          const wrapped = test.wrap(myFunctions.claimParayanAllocation);
          const result = await wrapped({
            data: {
              eventId: "event_123",
              phone: "+911234567890",
              deviceId: "device_abc",
              overwrite: true,
            },
          });

          expect(result.status).to.equal("SUCCESS");
          expect(result.participants[0].name).to.equal("User A");
          expect(batchMock.update.calledOnce).to.be.true;
          expect(batchMock.commit.calledOnce).to.be.true;
        });

    it("should handle multi-record claim for family members",
        async () => {
          // Mock two participants for the same phone number
          getStub.resolves({
            empty: false,
            forEach: (cb) => {
              cb({
                id: "p1",
                data: () => ({
                  name: "Member 1",
                  phone: "+911234567890",
                  assignedAdhyays: [1],
                }),
              });
              cb({
                id: "p2",
                data: () => ({
                  name: "Member 2",
                  phone: "+911234567890",
                  assignedAdhyays: [2],
                }),
              });
            },
          });

          const wrapped = test.wrap(myFunctions.claimParayanAllocation);
          const result = await wrapped({
            data: {
              eventId: "event_123",
              phone: "+911234567890",
              deviceId: "device_abc",
            },
          });

          expect(result.status).to.equal("SUCCESS");
          expect(result.participants).to.have.lengthOf(2);
          expect(batchMock.update.calledTwice).to.be.true;
          expect(batchMock.commit.calledOnce).to.be.true;
        });

    it("should return MISSING fields if required arguments omitted",
        async () => {
          const wrapped = test.wrap(myFunctions.claimParayanAllocation);

          try {
            await wrapped({data: {eventId: "e1"}});
            expect.fail("Should have thrown HttpsError");
          } catch (error) {
            expect(error.code).to.equal("invalid-argument");
          }
        });
  });
});
