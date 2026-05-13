# Budget Tracker

Native macOS budgeting app built with SwiftUI. Features dashboard analytics, transaction tracking, budget categories, AI-powered budget planning, recurring transactions, and CSV/JSON import.

## Features

- 📊 **Dashboard** — Monthly income, total spent, balance, and transaction count at a glance
- 💸 **Transactions** — Add, edit, categorize income and expenses
- 📋 **Budget Planner** — AI-assisted budget questionnaire with personalized plans
- 🔁 **Recurring Transactions** — Subscriptions, rent, salary, and repeating items
- 📁 **File Import** — Import transactions from CSV and JSON
- 📈 **Export Reports** — Generate CSV, JSON, and text reports
- ⚙️ **Settings** — Customizable categories, income mode, emergency fund tracking, AI tier
- 🌗 **Light & Dark Mode** — Native macOS theming

## Tech Stack

- **Swift 5** + **SwiftUI**
- **macOS 14+** (Sonoma)
- **Swift Package Manager**

## Build

```bash
swift build
.build/debug/BudgetTrackerMac
```

## Architecture

```
Sources/BudgetTrackerMac/
├── BudgetTrackerApp.swift     # @main entry point
├── AIService.swift             # AI integration for budget recommendations
├── Models/                     # Data models (Transaction, Budget, etc.)
├── Views/                      # SwiftUI views
│   ├── DashboardView.swift
│   ├── TransactionsView.swift
│   ├── BudgetPlannerView.swift
│   ├── RecurringTransactionsView.swift
│   ├── ExportReportsView.swift
│   ├── QuestionnaireView.swift
│   └── SettingsView.swift
├── Utils/                      # Helpers (formatters, etc.)
└── Resources/                  # Assets (icons, images)
```

## License

MIT © Daniel Bates · [batesai.org](https://batesai.org)
