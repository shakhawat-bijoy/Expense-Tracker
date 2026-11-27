# Expense Tracker

Expense tracking app for expenses, shifts, bills, budgets, debts, accounts, and money with people.

## Offline storage and synchronization

The app reads and writes data locally first, so existing and newly entered data remain available without a network connection. Android and iOS use SQLite; web uses SQLite persisted in IndexedDB. When connectivity returns, queued additions, edits, and user-requested deletions are sent to the configured backend. The app also refreshes its local cache from the backend and shows sync status in the app bar.

Synchronization requires the Node.js backend and its MongoDB connection to be available. The backend must include the `/api/sync` and `/api/sync/snapshot` routes. SQLite upgrades add only local columns and tables; they do not clear existing device records. Remote records are not deleted unless the user explicitly deletes them in the app. The web build also requires the `web/sqlite3.wasm` and `web/sqflite_sw.js` runtime assets.

To run the backend, configure its MongoDB connection in `backend/.env`, then start it from the `backend` directory with `npm start`. Set the backend URL in the app's server settings when it is not reachable at the default local address.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
