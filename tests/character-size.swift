import Foundation
let suite = "test.angeling.size.\(UUID().uuidString)"
let d = UserDefaults(suiteName: suite)!
defer { d.removePersistentDomain(forName: suite) }
assert(CharacterSizing.value("angeling", defaults: d) == 1)
assert(CharacterSizing.value("chawee-majing", defaults: d) == 1.5)
CharacterSizing.set(2, for: "chawee-majing", defaults: d)
assert(CharacterSizing.value("chawee-majing", defaults: UserDefaults(suiteName: suite)!) == 2)
assert(CharacterSizing.value("angeling", defaults: d) == 1)
CharacterSizing.set(9, for: "angeling", defaults: d)
assert(CharacterSizing.value("angeling", defaults: d) == 2.5)
CharacterSizing.set(-1, for: "angeling", defaults: d)
assert(CharacterSizing.value("angeling", defaults: d) == 1)
CharacterSizing.reset("chawee-majing", defaults: d)
assert(CharacterSizing.value("chawee-majing", defaults: d) == 1.5)
assert(CharacterSizing.clamp(.nan) == 1)
print("PASS: defaults, persistence, isolation, bounds, reset, nonfinite input")
