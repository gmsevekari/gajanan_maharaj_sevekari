const test = require('firebase-functions-test')();
const chai = require('chai');
const sinon = require('sinon');
const expect = chai.expect;
const admin = require('firebase-admin');

describe('Parayan Cloud Functions', () => {
    let myFunctions;
    let adminInitStub;
    let firestoreMock;

    before(() => {
        // Prepare firestoreMock early
        firestoreMock = {
            collection: sinon.stub(),
            batch: sinon.stub()
        };

        // Stub admin.initializeApp so it doesn't try to connect to real Firebase
        sinon.stub(admin, 'initializeApp');
        // Stub admin.app() to return a mock app to satisfy internal checks
        sinon.stub(admin, 'app').returns({
            firestore: () => firestoreMock
        });
        myFunctions = require('../index.js');
    });

    after(() => {
        sinon.restore();
        test.cleanup();
    });

    describe('claimParayanAllocation', () => {
        let dbStub, collectionStub, docStub, whereStub, getStub, batchMock;

        beforeEach(() => {
            batchMock = {
                update: sinon.stub(),
                commit: sinon.stub().resolves()
            };

            firestoreMock = {
                collection: sinon.stub(),
                batch: sinon.stub().returns(batchMock)
            };

            // Stub admin.firestore property accessor or method
            dbStub = sinon.stub(admin, 'firestore').returns(firestoreMock);

            const participantsCollectionMock = {
                where: sinon.stub(),
                doc: sinon.stub()
            };

            const eventDocMock = {
                collection: sinon.stub().withArgs('participants').returns(participantsCollectionMock)
            };

            const eventsCollectionMock = {
                doc: sinon.stub().returns(eventDocMock)
            };

            firestoreMock.collection.withArgs('parayan_events').returns(eventsCollectionMock);
            
            whereStub = participantsCollectionMock.where;
            getStub = sinon.stub();
            whereStub.returns({ get: getStub });
        });

        afterEach(() => {
            dbStub.restore();
        });

        it('should return NOT_FOUND if no participant found with phone number', async () => {
            getStub.resolves({ empty: true });

            const wrapped = test.wrap(myFunctions.claimParayanAllocation);
            const result = await wrapped({
                data: {
                    eventId: 'event_123',
                    phone: '+911234567890',
                    deviceId: 'device_abc'
                }
            });

            expect(result.status).to.equal('NOT_FOUND');
            expect(result.message).to.contain('No participant found');
        });

        it('should return CONFLICT if another device is already linked and overwrite is false', async () => {
            getStub.resolves({
                empty: false,
                forEach: (cb) => {
                    cb({
                        id: 'p1',
                        data: () => ({ 
                            name: 'User A', 
                            deviceId: 'other_device',
                            phone: '+911234567890' 
                        })
                    });
                }
            });

            const wrapped = test.wrap(myFunctions.claimParayanAllocation);
            const result = await wrapped({
                data: {
                    eventId: 'event_123',
                    phone: '+911234567890',
                    deviceId: 'device_abc',
                    overwrite: false
                }
            });

            expect(result.status).to.equal('CONFLICT');
            expect(result.message).to.contain('already linked to another device');
        });

        it('should return SUCCESS and update records if overwrite is true when conflict exists', async () => {
            getStub.resolves({
                empty: false,
                forEach: (cb) => {
                    cb({
                        id: 'p1',
                        data: () => ({ 
                            name: 'User A', 
                            deviceId: 'other_device',
                            phone: '+911234567890',
                            assignedAdhyays: [5]
                        })
                    });
                }
            });

            const wrapped = test.wrap(myFunctions.claimParayanAllocation);
            const result = await wrapped({
                data: {
                    eventId: 'event_123',
                    phone: '+911234567890',
                    deviceId: 'device_abc',
                    overwrite: true
                }
            });

            expect(result.status).to.equal('SUCCESS');
            expect(result.participants[0].name).to.equal('User A');
            expect(batchMock.update.calledOnce).to.be.true;
            expect(batchMock.commit.calledOnce).to.be.true;
        });

        it('should handle multi-record claim for family members sharing a phone number', async () => {
            // Mock two participants for the same phone number
            getStub.resolves({
                empty: false,
                forEach: (cb) => {
                    cb({
                        id: 'p1',
                        data: () => ({ 
                            name: 'Member 1', 
                            phone: '+911234567890',
                            assignedAdhyays: [1]
                        })
                    });
                    cb({
                        id: 'p2',
                        data: () => ({ 
                            name: 'Member 2', 
                            phone: '+911234567890',
                            assignedAdhyays: [2]
                        })
                    });
                }
            });

            const wrapped = test.wrap(myFunctions.claimParayanAllocation);
            const result = await wrapped({
                data: {
                    eventId: 'event_123',
                    phone: '+911234567890',
                    deviceId: 'device_abc'
                }
            });

            expect(result.status).to.equal('SUCCESS');
            expect(result.participants).to.have.lengthOf(2);
            expect(batchMock.update.calledTwice).to.be.true;
            expect(batchMock.commit.calledOnce).to.be.true;
        });

        it('should return MISSING fields if required arguments are omitted', async () => {
            const wrapped = test.wrap(myFunctions.claimParayanAllocation);
            
            try {
                await wrapped({ data: { eventId: 'e1' } });
                expect.fail('Should have thrown HttpsError');
            } catch (error) {
                expect(error.code).to.equal('invalid-argument');
            }
        });
    });
});
