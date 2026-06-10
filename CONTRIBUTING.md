# Contributing to Crate Music 🎵

First off, thank you for considering contributing to Crate Music! It's people like you that make this project such a great tool.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Pull Request Process](#pull-request-process)

---

## Code of Conduct

This project and everyone participating in it is governed by respect and professionalism. By participating, you are expected to uphold this code.

---

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues. When you create a bug report, include as many details as possible:

- **Clear title and description**
- **Steps to reproduce**
- **Expected vs actual behavior**
- **Screenshots** (if applicable)
- **iOS version and device model**
- **Xcode version**

### 💡 Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Detailed explanation** of the proposed feature
- **Why this enhancement would be useful**
- **Possible implementation approach** (optional)

### 🔧 Code Contributions

1. **Fork the repository**
2. **Create a feature branch** from `main`
3. **Make your changes** following our coding standards
4. **Write or update tests** as needed
5. **Ensure all tests pass**
6. **Commit with clear messages**
7. **Push to your fork**
8. **Submit a Pull Request**

---

## Development Setup

### Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- Git

### Setup Steps

1. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/there-music.git
   cd there-music
   ```

2. Add upstream remote:
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/there-music.git
   ```

3. Install dependencies (if any)

4. Open in Xcode:
   ```bash
   open ios-there-music/Monk.xcodeproj
   ```

5. Configure API keys in `Config.swift`

---

## Coding Standards

### Swift Style Guide

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

#### Key Points:

**Naming:**
- Use clear, descriptive names
- Use camelCase for variables and functions
- Use PascalCase for types and protocols
- Prefix boolean properties with `is`, `has`, `should`

```swift
// Good
var isPlaying: Bool
func fetchUserPlaylists() async

// Bad
var playing: Bool
func getUserPlaylists() async
```

**Code Organization:**
- Use `// MARK: -` to organize code sections
- Group related functionality together
- Keep files focused on a single responsibility

```swift
// MARK: - Properties
private var player: AVPlayer?

// MARK: - Lifecycle
override func viewDidLoad() { }

// MARK: - Actions
@objc private func handlePlayPause() { }

// MARK: - Helpers
private func configurePlayer() { }
```

**SwiftUI:**
- Extract complex views into separate components
- Use computed properties for view builders
- Keep body implementations concise

```swift
// Good
var body: some View {
    VStack {
        headerView
        contentView
        footerView
    }
}

private var headerView: some View {
    // Complex header logic
}
```

**Async/Await:**
- Prefer async/await over completion handlers
- Use proper error handling with try/catch
- Mark functions as `async throws` when appropriate

```swift
func fetchTracks() async throws -> [Track] {
    let data = try await networkService.fetch()
    return try decoder.decode([Track].self, from: data)
}
```

### Architecture

- Follow **MVVM** pattern
- Use **Repository** for data layer
- Implement **Dependency Injection**
- Keep ViewModels testable

---

## Pull Request Process

### Before Submitting

1. **Update documentation** if needed
2. **Add tests** for new features
3. **Ensure all tests pass**
4. **Follow the code style guide**
5. **Update README.md** if adding features

### PR Title Format

Use clear, descriptive titles:

- `feat: Add shuffle play functionality`
- `fix: Resolve player crash on iOS 17`
- `docs: Update API documentation`
- `refactor: Improve authentication flow`
- `test: Add unit tests for PlayerViewModel`

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] All tests passing

## Screenshots (if applicable)
Add screenshots here

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
```

### Review Process

- Maintainers will review your PR within 1-2 weeks
- Address any requested changes
- Once approved, maintainers will merge your PR

---

## Testing

### Running Tests

```bash
# Unit tests
cmd + U in Xcode

# Or via command line
xcodebuild test -scheme Monk -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Writing Tests

- Write tests for new features
- Use descriptive test names: `test_playTrack_updatesPlayerState()`
- Test edge cases and error conditions
- Mock external dependencies

---

## Questions?

Feel free to:
- Open a [GitHub Discussion](https://github.com/yourusername/there-music/discussions)
- Create an [Issue](https://github.com/yourusername/there-music/issues)
- Reach out via email

---

Thank you for contributing! 🎉
