// Sources/NewDocs/Network/RateLimiter.swift
import Foundation

actor RateLimiter {
  private let limit: Int
  private var timestamps: [Date] = []

  init(limit: Int) {
    self.limit = limit
  }

  func waitIfNeeded() async {
    let now = Date()
    let oneMinuteAgo = now.addingTimeInterval(-60)

    // Remove old timestamps
    timestamps.removeAll { $0 <= oneMinuteAgo }

    if timestamps.count >= limit, let oldest = timestamps.first {
      let waitTime = 60 - now.timeIntervalSince(oldest) + 1
      if waitTime > 0 {
        try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
      }
    }

    timestamps.append(now)
  }
}
