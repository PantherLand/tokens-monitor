# Makefile for OpenRouter Monitor
# Simple commands for common development tasks

.PHONY: help install run build test clean format lint archive release

# Default target
.DEFAULT_GOAL := help

# Variables
SCHEME = OpenRouterMonitor
CONFIGURATION = Debug
CONFIGURATION_RELEASE = Release
BUILD_DIR = .build
DERIVED_DATA = ~/Library/Developer/Xcode/DerivedData

help: ## Show this help message
	@echo "OpenRouter Monitor - Development Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make run          # Run the app in development mode"
	@echo "  make build        # Build release version"
	@echo "  make test         # Run all tests"

install: ## Install dependencies (if any)
	@echo "📦 Installing dependencies..."
	@swift package resolve
	@echo "✅ Dependencies installed"

run: ## Run the app in development mode
	@echo "🚀 Running OpenRouter Monitor..."
	@swift run

build: ## Build release version
	@echo "🔨 Building release version..."
	@swift build -c release
	@echo "✅ Build complete: $(BUILD_DIR)/release/OpenRouterMonitor"

build-debug: ## Build debug version
	@echo "🔨 Building debug version..."
	@swift build -c debug
	@echo "✅ Build complete: $(BUILD_DIR)/debug/OpenRouterMonitor"

test: ## Run tests
	@echo "🧪 Running tests..."
	@swift test

test-verbose: ## Run tests with verbose output
	@echo "🧪 Running tests (verbose)..."
	@swift test --verbose

clean: ## Clean build artifacts
	@echo "🧹 Cleaning build artifacts..."
	@swift package clean
	@rm -rf $(BUILD_DIR)
	@echo "✅ Clean complete"

format: ## Format code with swift-format (if installed)
	@echo "✨ Formatting code..."
	@if command -v swift-format >/dev/null 2>&1; then \
		find OpenRouterMonitor/Sources -name "*.swift" -exec swift-format -i {} \; ; \
		echo "✅ Code formatted"; \
	else \
		echo "⚠️  swift-format not installed. Install with: brew install swift-format"; \
	fi

lint: ## Lint code with SwiftLint (if installed)
	@echo "🔍 Linting code..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
		echo "✅ Linting complete"; \
	else \
		echo "⚠️  SwiftLint not installed. Install with: brew install swiftlint"; \
	fi

xcode: ## Open project in Xcode
	@echo "📂 Opening in Xcode..."
	@open Package.swift

archive: ## Create archive (requires Xcode project)
	@echo "📦 Creating archive..."
	@echo "⚠️  This requires a full Xcode project. See BUILD.md for details."
	@echo "Run this in Xcode: Product → Archive"

release: build ## Create release build and show location
	@echo ""
	@echo "✅ Release build complete!"
	@echo ""
	@echo "📍 Binary location:"
	@echo "   $(BUILD_DIR)/release/OpenRouterMonitor"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Test the binary"
	@echo "  2. Create DMG: make dmg (not implemented yet)"
	@echo "  3. Upload to GitHub Releases"

dev: install run ## Quick start: install dependencies and run

watch: ## Watch for changes and rebuild (requires fswatch)
	@if command -v fswatch >/dev/null 2>&1; then \
		echo "👀 Watching for changes..."; \
		fswatch -o OpenRouterMonitor/Sources | xargs -n1 -I{} make build-debug; \
	else \
		echo "⚠️  fswatch not installed. Install with: brew install fswatch"; \
	fi

setup: ## Setup development environment
	@echo "🛠️  Setting up development environment..."
	@echo ""
	@echo "Checking tools..."
	@if command -v swift >/dev/null 2>&1; then \
		echo "✅ Swift installed: $$(swift --version | head -1)"; \
	else \
		echo "❌ Swift not found"; \
	fi
	@if command -v xcodebuild >/dev/null 2>&1; then \
		echo "✅ Xcode installed: $$(xcodebuild -version | head -1)"; \
	else \
		echo "❌ Xcode not found"; \
	fi
	@echo ""
	@echo "Optional tools:"
	@if command -v swiftlint >/dev/null 2>&1; then \
		echo "✅ SwiftLint installed"; \
	else \
		echo "⚠️  SwiftLint not installed (optional)"; \
		echo "   Install: brew install swiftlint"; \
	fi
	@if command -v swift-format >/dev/null 2>&1; then \
		echo "✅ swift-format installed"; \
	else \
		echo "⚠️  swift-format not installed (optional)"; \
		echo "   Install: brew install swift-format"; \
	fi
	@echo ""
	@echo "Installing dependencies..."
	@make install
	@echo ""
	@echo "✅ Setup complete! Run 'make run' to start developing."

status: ## Show project status
	@echo "📊 Project Status"
	@echo ""
	@echo "📁 Repository:"
	@git remote get-url origin 2>/dev/null || echo "  No git remote configured"
	@echo ""
	@echo "🌿 Current branch:"
	@git branch --show-current 2>/dev/null || echo "  Not a git repository"
	@echo ""
	@echo "📝 Recent commits:"
	@git log --oneline -5 2>/dev/null || echo "  No commits yet"
	@echo ""
	@echo "🔧 Build artifacts:"
	@if [ -d "$(BUILD_DIR)" ]; then \
		du -sh $(BUILD_DIR) 2>/dev/null; \
	else \
		echo "  No build artifacts"; \
	fi

update: ## Update dependencies
	@echo "🔄 Updating dependencies..."
	@swift package update
	@echo "✅ Dependencies updated"

# Advanced targets

dmg: release ## Create DMG installer (macOS only)
	@echo "📀 Creating DMG installer..."
	@echo "⚠️  Not implemented yet. See BUILD.md for manual steps."

notarize: ## Notarize app for distribution (requires Apple Developer account)
	@echo "🔐 Notarizing app..."
	@echo "⚠️  Not implemented yet. Requires Apple Developer account."

version: ## Show version information
	@echo "OpenRouter Monitor"
	@echo ""
	@echo "Version: $$(git describe --tags --always 2>/dev/null || echo 'dev')"
	@echo "Swift: $$(swift --version | head -1)"
	@echo "Platform: $$(uname -s) $$(uname -r)"

# Development helpers

logs: ## Show application logs
	@echo "📋 Application logs..."
	@log show --predicate 'subsystem == "ai.openrouter.monitor"' --last 1h

todo: ## Show TODO items in code
	@echo "📝 TODO items:"
	@grep -r "TODO:" OpenRouterMonitor/Sources --color=always || echo "  No TODOs found!"
	@echo ""
	@echo "🐛 FIXME items:"
	@grep -r "FIXME:" OpenRouterMonitor/Sources --color=always || echo "  No FIXMEs found!"

stats: ## Show code statistics
	@echo "📊 Code Statistics"
	@echo ""
	@echo "Files:"
	@find OpenRouterMonitor/Sources -name "*.swift" | wc -l | xargs echo "  Swift files:"
	@echo ""
	@echo "Lines of code:"
	@find OpenRouterMonitor/Sources -name "*.swift" -exec wc -l {} + | tail -1 | awk '{print "  " $$1 " lines"}'
	@echo ""
	@echo "File sizes:"
	@du -sh OpenRouterMonitor/Sources | awk '{print "  Source code: " $$1}'
