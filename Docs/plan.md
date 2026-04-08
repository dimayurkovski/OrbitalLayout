# OrbitalLayout — Implementation Plan

## Pre-requisites

- Swift Tools Version: 6.0, Language Modes: v5, v6
- Platforms: iOS 15+, tvOS 15+, macOS 12+
- Testing: Swift Testing framework (`@Suite`, `@Test`)
- Target: 100% test coverage per source file

---

## Task 1 (done) — Project Structure + Platform Typealiases

**Файлы:**
- `Sources/Core/OrbitalAnchor.swift`
- `Sources/Core/OrbitalRelation.swift`
- `Sources/Core/OrbitalPriority.swift`
- `Sources/Extensions/PlatformAliases.swift`

**Что сделать:**
1. Создать директории `Sources/Core/`, `Sources/Proxy/`, `Sources/Extensions/`, `Sources/Storage/`
2. Определить typealiases с `#if canImport(UIKit)` / `#elseif canImport(AppKit)`:
   - `OrbitalView` = `UIView` / `NSView`
   - `OrbitalLayoutGuide` = `UILayoutGuide` / `NSLayoutGuide`
   - `OrbitalLayoutPriority` = `UILayoutPriority` / `NSLayoutConstraint.Priority`
   - `OrbitalConstraint` = `NSLayoutConstraint`
   - `OrbitalAxis` = `NSLayoutConstraint.Axis`
3. Реализовать `OrbitalAnchor` enum (Sendable) со всеми кейсами, `#if canImport(UIKit)` для baseline
4. Реализовать `OrbitalRelation` enum (Sendable): `.equal`, `.lessOrEqual`, `.greaterOrEqual`
5. Реализовать `OrbitalPriority` enum (Sendable): `.required`, `.high`, `.low`, `.custom(Float)` + computed `layoutPriority`
6. Удалить пустой `Sources/OrbitalLayout.swift`
7. Обновить `Package.swift` — убрать `path: "Sources"` если нужно, проверить что билдится

**Тесты:** `OrbitalLayoutTests/OrbitalAnchorTests.swift`, `OrbitalLayoutTests/OrbitalRelationTests.swift`, `OrbitalLayoutTests/OrbitalPriorityTests.swift`
- OrbitalAnchor: все кейсы существуют, Hashable, baseline только на UIKit
- OrbitalRelation: все 3 кейса, Hashable
- OrbitalPriority: конвертация в `OrbitalLayoutPriority` для каждого кейса (required=1000, high=750, low=250, custom)

**Критерий завершения:** `swift build` проходит на iOS/macOS, тесты зелёные.

---

## Task 2 (done) — OrbitalDescriptor (Value Type)

**Файлы:**
- `Sources/Core/OrbitalDescriptor.swift`

**Что сделать:**
1. Определить `@MainActor public struct OrbitalDescriptor` со всеми полями:
   - `anchor`, `constant`, `relation`, `priority`, `targetView`, `targetGuide`, `targetAnchor`, `multiplier`, `label`, `signOverride`, `targetIsSelf`, `likeWasCalled`
2. Определить вложенный `enum SignOverride: Sendable` (`.offset`, `.inset`)
3. Определить протокол `@MainActor public protocol OrbitalConstraintConvertible` с `func asDescriptors() -> [OrbitalDescriptor]`
4. Conformance `OrbitalDescriptor: OrbitalConstraintConvertible` (возвращает `[self]`)
5. Определить `@MainActor public struct OrbitalDescriptorGroup: OrbitalConstraintConvertible`

**Тесты:** `OrbitalLayoutTests/OrbitalDescriptorTests.swift`
- Создание с дефолтными значениями (relation = .equal, priority = .required, constant = 0, multiplier = 1)
- Value semantics: мутация копии не влияет на оригинал
- OrbitalDescriptorGroup: `asDescriptors()` возвращает массив дескрипторов

**Критерий завершения:** struct компилируется, value semantics подтверждены тестами.

---

## Task 3 (done) — Chaining Modifiers на OrbitalDescriptor

**Файлы:**
- `Sources/Core/OrbitalDescriptor.swift` (extension)

**Что сделать:**
1. Реализовать instance-методы (non-mutating, copy-return):
   - `to(_ view:, _ anchor:)` → устанавливает `targetView`, `targetAnchor`
   - `to(_ guide:, _ anchor:)` → устанавливает `targetGuide`, `targetAnchor`
   - `orLess` (computed) → `relation = .lessOrEqual`
   - `orMore` (computed) → `relation = .greaterOrEqual`
   - `asOffset` (computed) → `signOverride = .offset`
   - `asInset` (computed) → `signOverride = .inset`
   - `priority(_ p:)` → устанавливает `priority`
   - `labeled(_ id:)` → устанавливает `label`
   - `like(_ view:, _ multiplier:)` → устанавливает `targetView`, `multiplier`, `likeWasCalled = true`
   - `like(_ view:, _ anchor:, _ multiplier:)` → + `targetAnchor`
   - `like(_ anchor:, _ multiplier:)` → `targetIsSelf = true`, `targetAnchor`, `multiplier`
2. Реализовать модификаторы на `OrbitalDescriptorGroup`:
   - `priority()`, `orLess`, `orMore`, `labeled()` — применяют ко всем дескрипторам группы

**Тесты:** `OrbitalLayoutTests/OrbitalDescriptorTests.swift` (дополнить)
- Каждый модификатор: проверить что поле установлено, оригинал не изменён
- Цепочка: `.top(8).to(view, .bottom).orMore.priority(.high).labeled("x")` — все поля корректны
- `.to()` вызванный дважды — последний побеждает
- `.like()` устанавливает `likeWasCalled`
- `OrbitalDescriptorGroup` модификаторы применяются ко всем элементам

**Критерий завершения:** все цепочки из документации компилируются и проходят тесты.

---

## Task 4 (done) — Static Factory Methods на OrbitalDescriptor

**Файлы:**
- `Sources/Core/OrbitalDescriptor.swift` (extension)

**Что сделать:**
1. Static properties (constant = 0): `.top`, `.bottom`, `.leading`, `.trailing`, `.left`, `.right`, `.width`, `.height`, `.centerX`, `.centerY`
2. Static functions (с constant): `.top(_:)`, `.bottom(_:)`, `.leading(_:)`, `.trailing(_:)`, `.left(_:)`, `.right(_:)`, `.width(_:)`, `.height(_:)`, `.centerX(_:)`, `.centerY(_:)`
3. Группы, возвращающие `OrbitalDescriptorGroup`:
   - `.edges` / `.edges(_:)` — top + bottom + leading + trailing
   - `.horizontal` / `.horizontal(_:)` — leading + trailing
   - `.vertical` / `.vertical(_:)` — top + bottom
   - `.size(_:)` — width + height (одинаковые)
   - `.size(width:height:)` — width + height (разные)
   - `.center()` / `.center(offset:)` — centerX + centerY
4. Специальные:
   - `.aspectRatio(_:)` → anchor: .width, targetIsSelf = true, targetAnchor = .height, multiplier = ratio
5. Baseline (UIKit only, `#if canImport(UIKit)`):
   - `.firstBaseline` / `.firstBaseline(_:)`, `.lastBaseline` / `.lastBaseline(_:)`

**Тесты:** `OrbitalLayoutTests/OrbitalDescriptorTests.swift` (дополнить)
- Каждый static: проверить anchor, constant, дефолтные значения
- Группы: проверить количество дескрипторов и их anchor/constant
- `.aspectRatio()`: targetIsSelf = true, targetAnchor = .height, multiplier
- `.edges(16)`: все 4 дескриптора с constant = 16

**Критерий завершения:** все factory из спеки компилируются, тесты покрывают каждый.

---

## Task 5 (done) — ConstraintStorage

**Файлы:**
- `Sources/Storage/ConstraintStorage.swift`

**Что сделать:**
1. `@MainActor final class ConstraintStorage`
2. `StorageKey: Hashable` — `anchor: OrbitalAnchor` + `relation: OrbitalRelation`
3. `private var stored: [StorageKey: OrbitalConstraint]`
4. `store(_ constraint:, for anchor:, relation:)` — деактивирует предыдущий, заменяет
5. `get(_ anchor:, relation:)` → `OrbitalConstraint?`
6. `removeAll() -> [OrbitalConstraint]` — возвращает все, очищает dict
7. Extension на `OrbitalView` — `var orbitalStorage: ConstraintStorage` через `objc_setAssociatedObject` / `objc_getAssociatedObject`

**Тесты:** `OrbitalLayoutTests/ConstraintStorageTests.swift`
- store + get: правильный constraint возвращается
- Overwrite: старый деактивирован, новый хранится
- Разные relation для одного anchor: оба сосуществуют
- get несуществующего → nil
- removeAll: возвращает все, после — пусто
- orbitalStorage на view: создаётся при первом доступе, возвращается тот же объект при повторном

**Критерий завершения:** storage полностью работает, тесты зелёные.

---

## Task 6 (done) — ConstraintFactory

**Файлы:**
- `Sources/Core/ConstraintFactory.swift`

**Что сделать:**
1. `@MainActor enum ConstraintFactory`
2. `static func make(from descriptor:, for view:) -> OrbitalConstraint`
3. Логика:
   - Resolve source anchor → NSLayoutAnchor из view
   - Resolve target (targetView/targetGuide, или superview, или self при targetIsSelf)
   - `preconditionFailure` если нет superview и target не указан
   - Infer target anchor если nil (= source anchor)
   - Валидация совместимости anchor типов (x↔x, y↔y, dim↔dim), `preconditionFailure` при несовместимости
   - Sign convention: signOverride > same-edge auto-negation > as-is
   - `#if DEBUG` warnings: negative constant для trailing/bottom/right, likeWasCalled + .to() overwrite, targetIsSelf + targetView conflict
   - Multiplier strategy: dimension → `NSLayoutDimension` API; non-dimension + multiplier ≠ 1 → `NSLayoutConstraint(item:attribute:...)` fallback
   - Set relation, priority, identifier
   - Return constraint (NOT activated)

**Тесты:** `OrbitalLayoutTests/ConstraintFactoryTests.swift`
- Простой constraint: top(16) к superview — правильные anchors, constant = 16
- Cross-view: .top(8).to(header, .bottom) — firstItem = view, secondItem = header
- Auto-negation: trailing(16) → constant = -16, bottom(16) → constant = -16
- Cross-anchor: trailing(8).to(view, .leading) → constant = +8
- .asOffset overrides auto-negation
- .asInset forces negation on cross-anchor
- Relations: orLess → .lessThanOrEqual, orMore → .greaterThanOrEqual
- Priority: .high → 750
- Multiplier: dimension → NSLayoutDimension API, non-dimension → item-based API
- Label: .labeled("x") → constraint.identifier == "x"
- preconditionFailure: no superview
- preconditionFailure: incompatible anchors (.top to .width)
- .aspectRatio: self.width = self.height * ratio
- Layout guide as target

**Критерий завершения:** factory генерирует корректные constraints для всех комбинаций из спеки.

---

## Task 7 (done) — OrbitalProxy (Core Methods)

**Файлы:**
- `Sources/Proxy/OrbitalProxy.swift`

**Что сделать:**
1. `@MainActor public final class OrbitalProxy` с `weak var view: OrbitalView?`
2. Single constraint shortcuts: `top(_:)`, `bottom(_:)`, `leading(_:)`, `trailing(_:)`, `left(_:)`, `right(_:)`, `width(_:)`, `height(_:)`, `centerX(_:)`, `centerY(_:)` — каждый создаёт descriptor, вызывает ConstraintFactory, активирует, хранит в storage, возвращает
3. `constraint(_ descriptor:)` — одиночный constraint с полным чейнингом
4. `layout(_ items: OrbitalConstraintConvertible...)` — batch: flatten descriptors, для каждого make + activate + store
5. `prepareLayout(_ items:)` — то же, но WITHOUT activation
6. Stored constraint accessors: `topConstraint`, `bottomConstraint`, etc. → `storage.get(anchor, .equal)`
7. `constraint(for anchor:, relation:)` → `storage.get(anchor, relation)`

**Тесты:** `OrbitalLayoutTests/OrbitalProxyTests.swift`
- Каждый shortcut: constraint создаётся, активен, хранится в storage
- `constraint()` с цепочкой: .top(16).to(header, .bottom).orMore.priority(.high)
- `layout()`: множественные constraints, все активны
- `prepareLayout()`: constraints созданы, НЕ активны, доступны через accessors
- Named accessors: topConstraint и т.д. возвращают правильный constraint
- constraint(for:relation:): доступ к non-equal constraints
- Overwrite: повторный layout() для того же anchor деактивирует предыдущий

**Критерий завершения:** proxy shortcuts и batch layout работают, constraints хранятся и доступны.

---

## Task 8 (done) — OrbitalProxy (Shortcuts: edges, size, center)

**Файлы:**
- `Sources/Proxy/OrbitalProxy.swift` (extension)

**Что сделать:**
1. Property shortcuts: `edges` (var), `horizontal` (var), `vertical` (var)
2. Function shortcuts: `edges(_:)`, `horizontal(_:)`, `vertical(_:)`, `size(_:)`, `size(width:height:)`, `center()`, `center(offset:)`, `aspectRatio(_:)`
3. Все вызывают `layout()` внутри с соответствующими descriptors

**Тесты:** `OrbitalLayoutTests/OrbitalProxyTests.swift` (дополнить)
- `edges`: 4 constraints (top, bottom, leading, trailing), all active
- `edges(16)`: все constants = 16 (bottom/trailing auto-negated at factory level)
- `horizontal(8)`: 2 constraints (leading, trailing)
- `vertical(8)`: 2 constraints (top, bottom)
- `size(80)`: width = 80, height = 80
- `size(width:height:)`: разные значения
- `center()`: centerX = 0, centerY = 0
- `center(offset:)`: CGPoint applied
- `aspectRatio(2)`: width = height * 2

**Критерий завершения:** все shortcuts из Section 4-6 работают корректно.

---

## Task 9 (done) — OrbitalProxy (update / remake)

**Файлы:**
- `Sources/Proxy/OrbitalProxy.swift` (extension)

**Что сделать:**
1. `update(_ items: OrbitalConstraintConvertible...)`:
   - Для каждого descriptor: найти stored constraint по anchor (relation = .equal), обновить `.constant`
   - Игнорировать relation, priority, target, label, multiplier
   - Если constraint не найден — skip (no crash)
   - `#if DEBUG` warnings: anchor skipped, non-default modifiers ignored
2. `remake(_ items: OrbitalConstraintConvertible...)`:
   - Для каждого descriptor: деактивировать existing (если есть) для anchor+relation, создать новый через ConstraintFactory, активировать, сохранить
   - Если предыдущего нет — создать новый

**Тесты:** `OrbitalLayoutTests/OrbitalProxyTests.swift` (дополнить)
- `update()`: constant изменяется, constraint тот же объект (identity)
- `update()` с группами: `.edges(24)` обновляет все 4
- `update()` несуществующего anchor: no crash
- `update()` игнорирует priority, relation модификаторы
- `remake()`: старый deactivated, новый activated, stored accessor возвращает новый
- `remake()` с другим target: новый constraint привязан к новому target
- `remake()` без предыдущего: создаёт новый

**Критерий завершения:** update/remake работают по спеке, тесты покрывают edge cases.

---

## Task 10 (done) — OrbitalProxy (hugging / compression)

**Файлы:**
- `Sources/Proxy/OrbitalProxy.swift` (extension)

**Что сделать:**
1. `hugging(_ priority:, axis:)` → `view.setContentHuggingPriority(priority.layoutPriority, for: axis)`
2. `compression(_ priority:, axis:)` → `view.setContentCompressionResistancePriority(priority.layoutPriority, for: axis)`

**Тесты:** `OrbitalLayoutTests/OrbitalProxyTests.swift` (дополнить)
- hugging(.high, .horizontal): contentHuggingPriority == .defaultHigh
- compression(.required, .vertical): compressionResistance == .required

**Критерий завершения:** content priority shortcuts работают.

---

## Task 11 (done) — OrbitalView Extensions (addSubview + constraints)

**Файлы:**
- `Sources/Extensions/OrbitalView+Orbital.swift`

**Что сделать:**
1. `var orbital: OrbitalProxy` — computed property, возвращает `OrbitalProxy(view: self)`
2. `func orbit(_ child:, _ items: OrbitalConstraintConvertible...)`:
   - `child.translatesAutoresizingMaskIntoConstraints = false`
   - `addSubview(child)`
   - `child.orbital.layout(items)` (через flatten)
3. `func orbit(_ child:, _ items: [OrbitalConstraintConvertible])` — array variant
4. `func orbit(_ children: OrbitalView..., layout: @MainActor () -> Void)`:
   - Для каждого child: `translatesAutoresizingMaskIntoConstraints = false`, `addSubview`
   - Вызвать `layout()` closure
5. `func orbit(_ children: [OrbitalView], layout: @MainActor () -> Void)` — array variant

**Тесты:** `OrbitalLayoutTests/OrbitalViewExtensionTests.swift`
- `orbit(child, .top(16))`: child is subview, translatesAutoresizing = false, constraint exists
- `orbit(child, .edges)`: 4 constraints
- `orbit(child1, child2) { ... }`: оба subviews, constraints из closure
- Array variants работают идентично

**Критерий завершения:** все overloads `orbit()` из API reference работают.

---

## Task 12 (done) — NSLayoutConstraint Extensions (activate/deactivate)

**Файлы:**
- `Sources/Extensions/OrbitalConstraint+Orbital.swift`

**Что сделать:**
1. `extension Array where Element == OrbitalConstraint`:
   - `func activate()` → `OrbitalConstraint.activate(self)`
   - `func deactivate()` → `OrbitalConstraint.deactivate(self)`

**Тесты:** `OrbitalLayoutTests/OrbitalConstraintExtensionTests.swift`
- activate(): все constraints isActive = true
- deactivate(): все constraints isActive = false

**Критерий завершения:** batch activate/deactivate работает.

---

## Task 13 (done) — Error Handling & Debug Warnings

**Файлы:**
- Проверить и дополнить `ConstraintFactory.swift`

**Что сделать:**
1. Убедиться что все `preconditionFailure` из спеки на месте:
   - No superview: `"OrbitalLayout: view must have a superview before adding constraints. Use .to() to specify an explicit target."`
   - Incompatible anchors: `"OrbitalLayout: incompatible anchor types — cannot constrain .<source> to .<target>."`
2. `#if DEBUG` print warnings:
   - Negative constant для trailing/bottom/right
   - `.like()` overwritten by `.to()`
   - `.aspectRatio()` combined with `.to()`
   - `update()` skipped anchor, non-default modifiers ignored

**Тесты:** `OrbitalLayoutTests/ErrorHandlingTests.swift`
- preconditionFailure при отсутствии superview (через expectation на precondition)
- preconditionFailure при incompatible anchors: .top to .width, .centerX to .height, .width to .leading

**Критерий завершения:** все error paths покрыты тестами.

---

## Task 14 (done) — Integration Tests

**Файлы:**
- `OrbitalLayoutTests/IntegrationTests.swift`

**Что сделать:**
Написать end-to-end тесты, повторяющие примеры из documentation:
1. Full profile layout (Section 15 requirements.md): avatar + nameLabel + bioLabel + followButton
2. Card with shadow (Example 25): вложенные orbital calls
3. Expandable panel (Example 26): layout → update → verify constants
4. Dynamic constraint swap (Example 27): layout → remake → verify new target
5. Safe area layout: .to(safeAreaLayoutGuide)
6. Mixed relations: `.width(200)` + `.width(300).orLess` coexist
7. prepareLayout → activate flow
8. Multiplier: `.width.like(superview, 0.4)`, `.height.like(.width, 0.5)`

**Критерий завершения:** все реальные сценарии из документации проходят.

---

## Task 15 (done) — Final Verification & Cleanup

**Что сделать:**
1. `swift build` на iOS, macOS, tvOS (через `swift build --destination`)
2. `swift test` — все тесты зелёные
3. Проверить Swift 6 strict concurrency — никаких warnings
4. Проверить что baseline anchors — compile-time error на macOS
5. Убедиться что все public types имеют correct access control
6. Почистить: убрать неиспользуемый код, проверить что нет TODO в production code
7. Проверить Example app компилируется с библиотекой

**Критерий завершения:** библиотека полностью готова, билдится на всех платформах, 100% test coverage.

---

## Task 16 (done) — Documentation Comments (DocC-style)

**Файлы:**
- Все файлы в `Sources/` — добавить `///` комментарии ко всем `public` типам, методам, свойствам

**Стандарт:** Apple DocC / Swift-DocC. Стиль как в SnapKit, Alamofire — краткое описание, параметры через `- Parameters:`, возврат через `- Returns:`, примеры через ` ```swift ` блоки.

**Что сделать (по файлу):**

### `PlatformAliases.swift`
- `OrbitalView`, `OrbitalLayoutGuide`, `OrbitalLayoutPriority`, `OrbitalConstraint`, `OrbitalAxis` — однострочное описание + платформенная заметка

### `OrbitalAnchor.swift`
- Тип: описание назначения, таблица групп (vertical / horizontal / dimension / baseline)
- Каждый case: однострочное описание, RTL-note для `.left`/`.right`, UIKit-note для baseline

### `OrbitalRelation.swift`
- Тип: описание + таблица значений + пример с `.orLess` / `.orMore`
- Каждый case: описание соответствующего `NSLayoutConstraint.Relation`

### `OrbitalPriority.swift`
- Тип: описание + таблица (case / raw / UIKit equivalent) + пример `.priority()`
- Каждый case: описание + сырое числовое значение
- `layoutPriority`: описание конвертации

### `OrbitalDescriptor.swift`
- Тип: описание — value type, immutable chain builders
- Все поля: doc comment (назначение поля)
- `SignOverride`: описание каждого case (`.offset`, `.inset`)
- Все static factory: пример в doc comment
- Все instance modifiers: `- Parameters:` + пример
- `OrbitalConstraintConvertible`: описание протокола
- `OrbitalDescriptorGroup`: описание назначения

### `ConstraintFactory.swift`
- Тип: внутренний, но doc comment для `make(from:for:)` — описание логики, `preconditionFailure` conditions

### `ConstraintStorage.swift`
- Тип: описание хранилища
- `store(_:for:relation:)`, `get(_:relation:)`, `removeAll()`: params + returns
- `orbitalStorage` extension: описание

### `OrbitalProxy.swift`
- Тип: главная точка входа, пример доступа (`view.orbital`)
- Все shortcut-методы (`top`, `bottom`, …): params + returns + `- Note:` о chaining
- `layout(_:)`: params + returns + behaviour (replace existing)
- `prepareLayout(_:)`: difference from `layout()`
- `update(_:)`: что игнорируется, что обновляется
- `remake(_:)`: разница с `layout()`
- `constraint(_:)`: когда использовать вместо shortcut
- `constraint(for:relation:)`: доступ к non-equal constraints
- Stored accessors (`topConstraint`, …): однострочные
- `hugging(_:axis:)`, `compression(_:axis:)`: params

### `OrbitalView+Orbital.swift`
- `orbital` property: описание + пример
- Все `orbit(_:...)` overloads: params + behaviour (addSubview + translates + constraints)
- Closure-форма: note о том, что closure вызывается после addSubview

### `OrbitalConstraint+Orbital.swift`
- `activate()`, `deactivate()`: однострочные + пример

**Тесты:** не нужны — doc comments не влияют на поведение.

**Критерий завершения:** `swift package generate-documentation` (или Xcode DocC build) генерирует документацию без предупреждений. Все `public` symbols имеют doc comment.
