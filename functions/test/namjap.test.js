const test = require('firebase-functions-test')();
const chai = require('chai');
const sinon = require('sinon');
const expect = chai.expect;
const admin = require('firebase-admin');
const { DateTime, Settings } = require('luxon');

describe('Namjap Cloud Functions', () => {
    let myFunctions;
    let firestoreMock;

    before(() => {
        if (admin.initializeApp.restore) admin.initializeApp.restore();
        sinon.stub(admin, 'initializeApp');
        
        myFunctions = require('../index.js');
    });

    after(() => {
        sinon.restore();
        test.cleanup();
        Settings.now = () => Date.now(); // Reset luxon time
    });

    describe('updateNamjapStatuses', () => {
        let dbStub, enrollingGetStub, ongoingGetStub;

        beforeEach(() => {
            firestoreMock = {
                collection: sinon.stub(),
            };

            if (admin.app.restore) admin.app.restore();
            sinon.stub(admin, 'app').returns({
                firestore: () => firestoreMock
            });

            if (admin.firestore.restore) admin.firestore.restore();
            dbStub = sinon.stub(admin, 'firestore').returns(firestoreMock);

            enrollingGetStub = sinon.stub();
            ongoingGetStub = sinon.stub();

            // Setup for the two queries in the function
            firestoreMock.collection.withArgs('group_namjap_events').returns({
                where: sinon.stub().callsFake((field, op, value) => {
                    if (value === 'enrolling') return { get: enrollingGetStub };
                    if (value === 'ongoing') return { get: ongoingGetStub };
                    return { get: sinon.stub().resolves({ docs: [] }) };
                })
            });
        });

        afterEach(() => {
            sinon.restore();
        });

        it('should transition enrolling to ongoing if start date is reached (Seattle)', async () => {
            // Set "now" to April 23, 2026 10:00 AM Seattle
            const now = DateTime.fromISO('2026-04-23T10:00:00', { zone: 'America/Los_Angeles' });
            Settings.now = () => now.toMillis();

            const startDate = now.startOf('day'); // April 23
            const updateStub = sinon.stub().resolves();

            enrollingGetStub.resolves({
                docs: [{
                    id: 'event_seattle',
                    data: () => ({
                        startDate: { toDate: () => startDate.toJSDate() },
                        timezone: 'America/Los_Angeles',
                        status: 'enrolling'
                    }),
                    ref: { update: updateStub }
                }]
            });
            ongoingGetStub.resolves({ docs: [] });

            const wrapped = test.wrap(myFunctions.updateNamjapStatuses);
            await wrapped({});

            expect(updateStub.calledWith({ status: 'ongoing' })).to.be.true;
        });

        it('should transition enrolling to ongoing if start date is reached (India)', async () => {
            // Set "now" to April 24, 2026 02:00 AM India
            // At this time, it's still April 23 in Seattle, but April 24 in India.
            const nowIndia = DateTime.fromISO('2026-04-24T02:00:00', { zone: 'Asia/Kolkata' });
            Settings.now = () => nowIndia.toMillis();

            const startDate = nowIndia.startOf('day'); // April 24
            const updateStub = sinon.stub().resolves();

            enrollingGetStub.resolves({
                docs: [{
                    id: 'event_india',
                    data: () => ({
                        startDate: { toDate: () => startDate.toJSDate() },
                        timezone: 'Asia/Kolkata',
                        status: 'enrolling'
                    }),
                    ref: { update: updateStub }
                }]
            });
            ongoingGetStub.resolves({ docs: [] });

            const wrapped = test.wrap(myFunctions.updateNamjapStatuses);
            await wrapped({});

            expect(updateStub.calledWith({ status: 'ongoing' })).to.be.true;
        });

        it('should transition ongoing to completed if end date has passed', async () => {
            const now = DateTime.fromISO('2026-04-25T10:00:00', { zone: 'America/Los_Angeles' });
            Settings.now = () => now.toMillis();

            const endDate = now.minus({ days: 1 }).startOf('day'); // April 24
            const updateStub = sinon.stub().resolves();

            enrollingGetStub.resolves({ docs: [] });
            ongoingGetStub.resolves({
                docs: [{
                    id: 'event_completed',
                    data: () => ({
                        endDate: { toDate: () => endDate.toJSDate() },
                        timezone: 'America/Los_Angeles',
                        status: 'ongoing'
                    }),
                    ref: { update: updateStub }
                }]
            });

            const wrapped = test.wrap(myFunctions.updateNamjapStatuses);
            await wrapped({});

            expect(updateStub.calledWith({ status: 'completed' })).to.be.true;
        });

        it('should not transition enrolling if start date is in the future', async () => {
            const now = DateTime.fromISO('2026-04-23T10:00:00', { zone: 'America/Los_Angeles' });
            Settings.now = () => now.toMillis();

            const startDate = now.plus({ days: 1 }).startOf('day'); // April 24
            const updateStub = sinon.stub().resolves();

            enrollingGetStub.resolves({
                docs: [{
                    id: 'event_future',
                    data: () => ({
                        startDate: { toDate: () => startDate.toJSDate() },
                        timezone: 'America/Los_Angeles',
                        status: 'enrolling'
                    }),
                    ref: { update: updateStub }
                }]
            });
            ongoingGetStub.resolves({ docs: [] });

            const wrapped = test.wrap(myFunctions.updateNamjapStatuses);
            await wrapped({});

            expect(updateStub.called).to.be.false;
        });
    });
});
