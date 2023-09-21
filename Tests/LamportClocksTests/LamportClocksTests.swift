import XCTest
@testable import LamportClocks

final class LamportClocksTests: XCTestCase {
    func testTick() throws {
        let P = LamportClocks.Process()
        XCTAssert(P.tick() == 1)
    }
    
    func testSuccessive() throws {
        let P = LamportClocks.Process()
        let p1 = P.event()
        let p2 = P.event()
        XCTAssert(p1.precedes(p2))
        XCTAssert(!p2.precedes(p1))
    }
    
    func testSend() throws {
        let P = LamportClocks.Process()
        let Q = LamportClocks.Process()
        let q1 = Q.send(to: P)
        let p1 = P.send(to: Q)
        let q2 = Q.receive()!
        let p2 = P.receive()!
        XCTAssert(p1.precedes(q2))
        XCTAssert(q1.precedes(p2))
        XCTAssert(q1.precedes(q2))
        XCTAssert(p1.precedes(p2))
        XCTAssert(p1.concurrent(with: q1))
        XCTAssert(p2.concurrent(with: q2))
    }
    
    func testTransitiveTwoNodes() throws {
        let P = LamportClocks.Process()
        let Q = LamportClocks.Process()
        let p1 = P.send(to: Q)
        let q1 = Q.receive()!
        let q2 = Q.event()
        // a --> b
        XCTAssert(p1.precedes(q1))
        // b --> c
        XCTAssert(q1.precedes(q2))
        // a --> c.
        XCTAssert(p1.precedes(q2))
    }
    
    func testTransitiveThreeNodes() throws {
        let P = LamportClocks.Process()
        let Q = LamportClocks.Process()
        let R = LamportClocks.Process()
        let p1 = P.send(to: Q)
        let q1 = Q.receive()!
        let q2 = Q.send(to: R)
        let r1 = R.receive()!
        let r2 = R.event()
        XCTAssert(p1.precedes(r2))
    }
    
    func testTransitiveThreeNodesLocalLeft() throws {
        let P = LamportClocks.Process()
        let Q = LamportClocks.Process()
        let R = LamportClocks.Process()
        let p1 = P.event()
        let p2 = P.send(to: Q)
        let q1 = Q.receive()!
        let q2 = Q.send(to: R)
        let r1 = R.receive()!
        let r2 = R.event()
        XCTAssert(p1.precedes(r2))
    }
}
