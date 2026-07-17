import AppIntents
import XCTest

@testable import Runner

/// The Siri capture contract, exercised end to end in a simulator: the
/// background App Intents must leave well-formed queue records the Dart
/// drain can turn into rows. No App Group in the test host, so
/// BridgePaths falls back to the app container — same code path as a
/// pre-Phase-6 install.
final class CaptureQueueTests: XCTestCase {

  override func setUpWithError() throws {
    try? FileManager.default.removeItem(at: BridgePaths.pendingDir)
  }

  private func pendingFiles() throws -> [URL] {
    (try? FileManager.default.contentsOfDirectory(
      at: BridgePaths.pendingDir, includingPropertiesForKeys: nil)) ?? []
  }

  private func readRecord(_ url: URL) throws -> [String: Any] {
    let data = try Data(contentsOf: url)
    return try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  func testEnqueueWritesWellFormedRecord() throws {
    let id = try CaptureQueue.enqueue(
      type: "expense",
      fields: ["amountCents": 1250, "text": "coffee"])

    let files = try pendingFiles()
    XCTAssertEqual(files.count, 1)
    let file = files[0]

    // Epoch-prefixed name: the drain's stable ordering contract.
    let name = file.lastPathComponent
    XCTAssertTrue(name.hasSuffix("-\(id).json"), "got \(name)")
    XCTAssertNotNil(Int(name.split(separator: "-")[0]))
    // Atomic tmp+rename leaves no droppings.
    XCTAssertFalse(name.hasSuffix(".tmp"))

    let record = try readRecord(file)
    XCTAssertEqual(record["v"] as? Int, 1)
    XCTAssertEqual(record["id"] as? String, id)
    XCTAssertEqual(record["source"] as? String, "siri")
    XCTAssertEqual(record["type"] as? String, "expense")
    let fields = try XCTUnwrap(record["fields"] as? [String: Any])
    // Money is INTEGER CENTS by contract — never a double.
    XCTAssertEqual(fields["amountCents"] as? Int, 1250)
    XCTAssertEqual(fields["text"] as? String, "coffee")
    XCTAssertNotNil(record["createdAt"] as? String)
  }

  func testEnqueueCarriesNotificationBlock() throws {
    _ = try CaptureQueue.enqueue(
      type: "reminder",
      fields: ["text": "water"],
      notification: (id: 42, armed: true))

    let record = try readRecord(try pendingFiles()[0])
    let notification = try XCTUnwrap(record["notification"] as? [String: Any])
    XCTAssertEqual(notification["id"] as? Int, 42)
    XCTAssertEqual(notification["armed"] as? Bool, true)
  }

  func testRemovePendingDeletesExactlyThatRecord() throws {
    let keep = try CaptureQueue.enqueue(type: "idea", fields: ["text": "a"])
    let drop = try CaptureQueue.enqueue(type: "idea", fields: ["text": "b"])

    XCTAssertTrue(CaptureQueue.removePending(id: drop))
    XCTAssertFalse(CaptureQueue.removePending(id: "no-such-id"))

    let names = try pendingFiles().map(\.lastPathComponent)
    XCTAssertEqual(names.count, 1)
    XCTAssertTrue(names[0].contains(keep))
  }

  func testEntityStoreMissingFileIsAbsentNotFatal() throws {
    try? FileManager.default.removeItem(at: BridgePaths.entitiesFile)
    XCTAssertNil(EntityStore.load())
  }
}

/// The intents themselves, driven through perform() exactly as Siri
/// drives them — parameter validation, queue writes, cents math.
final class BackgroundIntentTests: XCTestCase {

  override func setUpWithError() throws {
    try? FileManager.default.removeItem(at: BridgePaths.pendingDir)
  }

  private func onlyRecord() throws -> [String: Any] {
    let files = try FileManager.default.contentsOfDirectory(
      at: BridgePaths.pendingDir, includingPropertiesForKeys: nil)
    XCTAssertEqual(files.count, 1)
    let data = try Data(contentsOf: files[0])
    return try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  func testLogExpenseEnqueuesCentsAndCategory() async throws {
    var intent = LogExpenseBackgroundIntent()
    intent.amount = 12.50
    intent.note = "coffee beans"
    intent.category = BudgetCategoryEntity(id: "cat-1", name: "Groceries")

    _ = try await intent.perform()

    let record = try onlyRecord()
    XCTAssertEqual(record["type"] as? String, "expense")
    let fields = try XCTUnwrap(record["fields"] as? [String: Any])
    XCTAssertEqual(fields["amountCents"] as? Int, 1250)
    XCTAssertEqual(fields["categoryId"] as? String, "cat-1")
    XCTAssertEqual(fields["categoryName"] as? String, "Groceries")
    XCTAssertEqual(fields["text"] as? String, "coffee beans")
  }

  func testLogExpenseRejectsZeroAndWritesNothing() async throws {
    var intent = LogExpenseBackgroundIntent()
    intent.amount = 0

    do {
      _ = try await intent.perform()
      XCTFail("zero amount must throw")
    } catch {
      // Expected: bad input never reaches the queue.
    }
    let files = (try? FileManager.default.contentsOfDirectory(
      at: BridgePaths.pendingDir, includingPropertiesForKeys: nil)) ?? []
    XCTAssertTrue(files.isEmpty)
  }

  func testCheckHabitEnqueuesHabitLog() async throws {
    var intent = CheckHabitBackgroundIntent()
    intent.habit = HabitEntity(id: "h-1", name: "Stretch")

    _ = try await intent.perform()

    let record = try onlyRecord()
    XCTAssertEqual(record["type"] as? String, "habitLog")
    let fields = try XCTUnwrap(record["fields"] as? [String: Any])
    XCTAssertEqual(fields["habitId"] as? String, "h-1")
    XCTAssertEqual(fields["habitName"] as? String, "Stretch")
    XCTAssertEqual(fields["value"] as? Int, 1)
  }

  func testAddReminderEnqueuesScheduleAndNotificationBlock() async throws {
    var intent = AddReminderBackgroundIntent()
    intent.text = "Drink water"
    intent.when = nil // defaults to a daily 9:00 nudge

    _ = try await intent.perform()

    let record = try onlyRecord()
    XCTAssertEqual(record["type"] as? String, "reminder")
    let fields = try XCTUnwrap(record["fields"] as? [String: Any])
    XCTAssertEqual(fields["text"] as? String, "Drink water")
    XCTAssertEqual(fields["hour"] as? Int, 9)
    XCTAssertEqual(fields["minute"] as? Int, 0)
    XCTAssertNil(fields["oneShotDateIso"]) // daily, not one-shot

    // The provisional-notification handshake always travels with the
    // record; armed may be false in the test host (no notification
    // permission), which is exactly the "open the app once" path.
    let notification = try XCTUnwrap(record["notification"] as? [String: Any])
    let id = try XCTUnwrap(notification["id"] as? Int)
    XCTAssertTrue(id > 0 && id <= 0x7FFF_FFFF)
    XCTAssertNotNil(notification["armed"] as? Bool)
  }

  func testParkIdeaTrimsAndRejectsEmpty() async throws {
    var intent = ParkIdeaBackgroundIntent()
    intent.idea = "   "
    do {
      _ = try await intent.perform()
      XCTFail("blank idea must throw")
    } catch {}

    intent.idea = "  build a birdhouse  "
    _ = try await intent.perform()
    let record = try onlyRecord()
    let fields = try XCTUnwrap(record["fields"] as? [String: Any])
    XCTAssertEqual(fields["text"] as? String, "build a birdhouse")
  }
}
