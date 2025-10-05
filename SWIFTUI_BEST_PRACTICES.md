# SwiftUI Best Practices - FridgeScanner Project

**Author:** Schema Architect & Code Auditor
**Date:** October 4, 2025
**Purpose:** Document critical patterns learned from debugging race conditions

---

## 🎯 Core Principles

1. **SwiftUI state updates are asynchronous**
2. **Never assume immediate propagation of @Published properties**
3. **Pass data directly when possible, avoid relying on bindings for critical flow**
4. **Use DispatchQueue.main.async for actions that depend on stable state**

---

## 🐛 Race Conditions We Fixed

### **Race Condition #1: Image Selection Callback**

**Location:** `CameraView.swift` - PhotoPicker & CameraCapture

**Symptom:**
- First image scan didn't process
- Had to select image twice
- Second attempt worked perfectly

**Root Cause:**
```swift
// ❌ BROKEN - Relies on binding timing
func handleImageSelected() {
    guard let image = viewModel.capturedImage else { return }  // Binding not updated yet!
    Task { await viewModel.processImage(image) }
}

// PhotoPicker sets binding and calls callback
self.parent.image = image as? UIImage
self.parent.onImageSelected()  // Called before binding propagates!
```

**Fix:**
```swift
// ✅ FIXED - Pass data directly
func handleImageSelected(_ image: UIImage) {
    Task { await viewModel.processImage(image) }
}

// PhotoPicker passes image directly
if let uiImage = image as? UIImage {
    self.parent.image = uiImage
    self.parent.onImageSelected(uiImage)  // Pass directly, no binding dependency
}
```

**Lesson:** Don't rely on `@Binding` propagation timing. Pass critical data as parameters.

---

### **Race Condition #2: Button Action State Read**

**Location:** `CameraView.swift` - "Review Ingredients" button

**Symptom:**
- Scan completes: "Found 12 ingredients!"
- Click "Review Ingredients": Empty list
- Click again: All 12 ingredients show up
- Inconsistent behavior depending on timing

**Root Cause:**
```swift
// ❌ BROKEN - Reads @Published state immediately
Button(action: proceedToIngredients) {
    Text("Review Ingredients")
}

func proceedToIngredients() {
    // viewModel.identifiedIngredients might still be empty!
    // @Published property hasn't finished propagating through view hierarchy
    onIngredientsIdentified?(viewModel.identifiedIngredients)
}
```

**Timeline of Bug:**
1. API returns: `viewModel.identifiedIngredients = [12 items]`
2. `@Published` queues view update (asynchronous)
3. View shows: "Found 12 ingredients!" (count is updated)
4. User clicks: Button fires `proceedToIngredients()`
5. **State read happens BEFORE @Published propagation completes**
6. Empty array passed to parent → Empty IngredientListView

**Fix:**
```swift
// ✅ FIXED - Defer to next run loop cycle
Button {
    DispatchQueue.main.async {
        proceedToIngredients()
    }
} label: {
    Text("Review Ingredients")
}
```

**Why This Works:**
- `DispatchQueue.main.async` defers execution to the **next run loop cycle**
- Gives SwiftUI time to complete state propagation
- Ensures `viewModel.identifiedIngredients` is fully updated
- Happens in microseconds (no user-visible delay)

**Lesson:** When actions depend on recently updated `@Published` state, defer with `DispatchQueue.main.async`.

---

## 📚 SwiftUI State Management Best Practices

### **1. Understanding @Published Property Updates**

```swift
class ViewModel: ObservableObject {
    @Published var data: [String] = []

    func loadData() {
        data = ["item1", "item2", "item3"]
        // ⚠️ WARNING: View is NOT updated yet!
        // The update is queued asynchronously
    }
}
```

**Key Points:**
- `@Published` triggers view updates **asynchronously**
- State changes are **queued**, not immediate
- Reading state immediately after setting can return **stale values**
- SwiftUI batches updates for performance

---

### **2. Pattern: Critical Actions That Depend on State**

**❌ WRONG:**
```swift
Button("Process Data") {
    // State might not be ready yet!
    processData(viewModel.items)
}
```

**✅ CORRECT:**
```swift
Button("Process Data") {
    // Defer to next run loop - ensures state is stable
    DispatchQueue.main.async {
        processData(viewModel.items)
    }
}
```

**When to Use:**
- Navigating after state update
- Passing data to child views
- Triggering actions that depend on just-updated state
- Any critical flow that reads @Published properties

---

### **3. Pattern: Passing Data to Child Views**

**❌ WRONG - Rely on bindings:**
```swift
struct ParentView: View {
    @StateObject var viewModel = MyViewModel()
    @State var showChild = false

    var body: some View {
        Button("Load & Show") {
            viewModel.loadData()
            showChild = true  // Child might see empty data!
        }
        .sheet(isPresented: $showChild) {
            ChildView(data: viewModel.data)  // Race condition!
        }
    }
}
```

**✅ CORRECT - Capture data explicitly:**
```swift
struct ParentView: View {
    @StateObject var viewModel = MyViewModel()
    @State var childData: [String] = []
    @State var showChild = false

    var body: some View {
        Button("Load & Show") {
            viewModel.loadData()
            DispatchQueue.main.async {
                childData = viewModel.data  // Capture when state is stable
                showChild = true
            }
        }
        .sheet(isPresented: $showChild) {
            ChildView(data: childData)  // Guaranteed to have data
        }
    }
}
```

---

### **4. Pattern: Callback Timing with UIViewControllerRepresentable**

**❌ WRONG - Callback before binding:**
```swift
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImageSelected: () -> Void

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        provider.loadObject(ofClass: UIImage.self) { image, _ in
            DispatchQueue.main.async {
                self.parent.image = image as? UIImage
                self.parent.onImageSelected()  // ❌ Binding not propagated yet!
            }
        }
    }
}
```

**✅ CORRECT - Pass data directly:**
```swift
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImageSelected: (UIImage) -> Void  // Takes UIImage parameter

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        provider.loadObject(ofClass: UIImage.self) { image, _ in
            DispatchQueue.main.async {
                if let uiImage = image as? UIImage {
                    self.parent.image = uiImage
                    self.parent.onImageSelected(uiImage)  // ✅ Pass directly
                }
            }
        }
    }
}
```

---

## 🔧 Common Patterns & Solutions

### **Pattern: Navigation After Data Load**

```swift
// ❌ WRONG
func loadAndNavigate() {
    viewModel.loadData()
    navigationPath.append(.detailView)  // Might navigate with empty data!
}

// ✅ CORRECT
func loadAndNavigate() {
    viewModel.loadData()
    DispatchQueue.main.async {
        navigationPath.append(.detailView)  // Data is stable now
    }
}
```

---

### **Pattern: Form Submission**

```swift
// ❌ WRONG
Button("Submit") {
    viewModel.formData = FormData(name: name, email: email)
    viewModel.submit()  // Might submit old data!
}

// ✅ CORRECT
Button("Submit") {
    let formData = FormData(name: name, email: email)
    viewModel.formData = formData
    DispatchQueue.main.async {
        viewModel.submit()  // Guaranteed to submit new data
    }
}
```

---

### **Pattern: Conditional Navigation**

```swift
// ❌ WRONG
Button("Save & Continue") {
    viewModel.save()
    if viewModel.isValid {  // Might check old state!
        navigationPath.append(.nextScreen)
    }
}

// ✅ CORRECT
Button("Save & Continue") {
    viewModel.save()
    DispatchQueue.main.async {
        if viewModel.isValid {  // Checks updated state
            navigationPath.append(.nextScreen)
        }
    }
}
```

---

## 🎓 Advanced Patterns

### **Pattern: Multiple State Updates Before Action**

```swift
// ❌ WRONG - Multiple race conditions!
Button("Process All") {
    viewModel.loadUsers()
    viewModel.loadSettings()
    viewModel.loadPreferences()
    processEverything()  // None of the data is ready!
}

// ✅ CORRECT - Wait for all state to stabilize
Button("Process All") {
    viewModel.loadUsers()
    viewModel.loadSettings()
    viewModel.loadPreferences()
    DispatchQueue.main.async {
        processEverything()  // All state is now stable
    }
}

// ✅ EVEN BETTER - Use async/await for sequential operations
Button("Process All") {
    Task {
        await viewModel.loadUsers()
        await viewModel.loadSettings()
        await viewModel.loadPreferences()
        await processEverything()  // Guaranteed order
    }
}
```

---

### **Pattern: Avoiding DispatchQueue with Task**

```swift
// ✅ GOOD - DispatchQueue
Button("Load Data") {
    viewModel.loadData()
    DispatchQueue.main.async {
        navigateToResults()
    }
}

// ✅ BETTER - Use Task with small delay
Button("Load Data") {
    viewModel.loadData()
    Task {
        try? await Task.sleep(nanoseconds: 10_000_000)  // 10ms
        navigateToResults()
    }
}

// ✅ BEST - Make viewModel method async and await it
Button("Load Data") {
    Task {
        await viewModel.loadData()
        navigateToResults()  // Guaranteed to happen after completion
    }
}
```

---

## 🚨 Common Anti-Patterns to Avoid

### **Anti-Pattern #1: Immediate State Read After Write**

```swift
// ❌ DON'T DO THIS
viewModel.data = newData
if viewModel.data.isEmpty {  // Might be checking old state!
    showError()
}

// ✅ DO THIS
let newData = generateData()
viewModel.data = newData
if newData.isEmpty {  // Check the value you just created
    showError()
}
```

---

### **Anti-Pattern #2: Nested Immediate Callbacks**

```swift
// ❌ DON'T DO THIS
func loadAndProcess() {
    loadData { data in
        self.viewModel.items = data
        self.processItems()  // Race condition!
    }
}

// ✅ DO THIS
func loadAndProcess() {
    loadData { data in
        self.viewModel.items = data
        DispatchQueue.main.async {
            self.processItems()  // State is stable
        }
    }
}
```

---

### **Anti-Pattern #3: Relying on View Update Timing**

```swift
// ❌ DON'T DO THIS
.onChange(of: viewModel.isLoading) { isLoading in
    if !isLoading {
        // Assuming data is ready - might not be!
        showResults()
    }
}

// ✅ DO THIS - Use explicit completion handlers
.onChange(of: viewModel.isLoading) { isLoading in
    if !isLoading {
        DispatchQueue.main.async {
            showResults()  // Ensure state is fully propagated
        }
    }
}

// ✅ EVEN BETTER - Use publisher/async patterns
viewModel.$isLoading
    .filter { !$0 }
    .receive(on: DispatchQueue.main)
    .sink { _ in
        showResults()
    }
```

---

## 📋 Quick Reference Checklist

**Before writing code, ask yourself:**

- [ ] Am I reading `@Published` state immediately after setting it?
- [ ] Does my button action depend on recently updated state?
- [ ] Am I passing data via callback before bindings can update?
- [ ] Is navigation happening right after data load?
- [ ] Am I triggering actions in UIViewControllerRepresentable callbacks?

**If YES to any:** Use `DispatchQueue.main.async { }` or pass data directly as parameters.

---

## 🔍 Debugging Race Conditions

**Symptoms:**
- Works on second attempt but not first
- Inconsistent behavior (sometimes works, sometimes doesn't)
- Empty data when you expect it to be populated
- Navigation shows stale data

**Diagnosis Steps:**

1. **Add debug logging:**
```swift
print("🔍 Before update: \(viewModel.items.count)")
viewModel.items = newItems
print("🔍 After update: \(viewModel.items.count)")  // Might be same!
DispatchQueue.main.async {
    print("🔍 Next cycle: \(viewModel.items.count)")  // Should be updated
}
```

2. **Check callback timing:**
```swift
// Add timestamps
print("🔍 [\(Date())] Setting state")
viewModel.data = newData
print("🔍 [\(Date())] Reading state: \(viewModel.data)")
```

3. **Verify with delay:**
```swift
// If adding DispatchQueue.main.async fixes it → race condition confirmed
```

---

## 📚 Additional Resources

**SwiftUI State Management:**
- Apple's SwiftUI State and Data Flow: https://developer.apple.com/documentation/swiftui/state-and-data-flow
- Combine Framework for reactive patterns: https://developer.apple.com/documentation/combine
- Understanding @Published: https://developer.apple.com/documentation/combine/published

**Concurrency:**
- Swift Concurrency (async/await): https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html
- DispatchQueue documentation: https://developer.apple.com/documentation/dispatch/dispatchqueue

---

## 🎯 Summary

**Golden Rules:**

1. **@Published updates are asynchronous** - Never assume immediate propagation
2. **Use DispatchQueue.main.async** when actions depend on just-updated state
3. **Pass data directly** instead of relying on binding timing
4. **When in doubt, defer** - Better safe than race condition
5. **Test edge cases** - Click buttons rapidly, test on slower devices

**Remember:** Race conditions are timing-dependent and often inconsistent. If something works "most of the time" or "on the second try," it's almost always a race condition.

---

**Last Updated:** October 4, 2025
**Status:** Living document - Update as new patterns emerge

**YARRR! 🏴‍☠️** Race conditions are no match for proper state management!
