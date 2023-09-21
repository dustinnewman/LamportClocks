//
//  LamportClocks
//  Sample (incomplete) implementation of
//  "Time, Clocks, and the Ordering of Events in a Distributed System" (1978)
//  by Leslie Lamport
//
//  Created by Dustin Newman on 9/19/23.
//

class Event {
    var process: Process
    var from: Process?
    var to: Process?
    var time: Int
    
    init(process: Process, time: Int) {
        self.process = process
        self.time = time
    }
    
    init(process: Process, time: Int, from: Process) {
        self.process = process
        self.time = time
        self.from = from
    }
    
    init(process: Process, time: Int, to: Process) {
        self.process = process
        self.time = time
        self.to = to
    }
    
    func precedes(_ b: Event) -> Bool {
        // Definition.1 - If a and b are on the same process, then use timestamps
        if self.process.id == b.process.id {
            return self.time < b.time
        }
        // Definition.2 - a precedes b if a is the sending and b is the receipt
        if self.to?.id == b.process.id && self.process.id == b.from?.id && self.time < b.time {
            return true
        }
        // Definition.3 - Transitive precedents
        // Try to walk "across" from messages
        if let to = self.to {
            for intermediate in to.events {
                if intermediate.time > self.time && intermediate.precedes(b) {
                    return true
                }
            }
        }
        // Go "forward" through our own process events
        for intermediate in self.process.events {
            if intermediate.time > self.time && intermediate.precedes(b) {
                return true
            }
        }
        return false
    }
    
    func concurrent(with: Event) -> Bool {
        return !self.precedes(with) && !with.precedes(self)
    }
}

class Process: Identifiable {
    // Each clock starts at 0
    var clock: Int = 0
    var events: [Event] = []
    var inbox: [(Process, Int)] = []
    
    func tick() -> Int {
        clock += 1
        return clock
    }
    
    // Local event
    func event() -> Event {
        let event = Event(process: self, time: tick())
        events.append(event)
        return event
    }
    
    func send(to: Process) -> Event {
        let event = Event(process: self, time: tick(), to: to)
        events.append(event)
        to.queue(from: self, time: clock)
        return event
    }
    
    func receive() -> Event? {
        if inbox.isEmpty {
            return nil
        }
        let (from, time) = inbox.removeFirst()
        clock = max(clock, time)
        let event = Event(process: self, time: tick(), from: from)
        events.append(event)
        return event
    }
    
    func receive(from: Process) -> Event? {
        // Only receive events from a certain process
        // Helpful for forcing delays in the configuration
        if let (_, time) = inbox.first(where: { $0.0.id == from.id }) {
            clock = max(clock, time)
            let event = Event(process: self, time: tick(), from: from)
            events.append(event)
            return event
        }
        return nil
    }
    
    func queue(from: Process, time: Int) {
        inbox.append((from, time))
    }
}
