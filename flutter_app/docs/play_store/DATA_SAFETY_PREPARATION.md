# AurivaBMS Data Safety Preparation

This document prepares you for the Google Play Console Data Safety form based on actual code dependencies and configuration.

| Data Category | Collected? | Shared? | Purpose | Required? | Evidence |
|---|---|---|---|---|---|
| **Personal information** (Name, Email) | YES | YES | App functionality, Account management | YES | Auth endpoints, User settings UI |
| **Contact information** (Clients, Suppliers) | YES | YES | App functionality | YES | Client/Supplier Management API |
| **User IDs** | YES | YES | Account management | YES | Token/Auth mechanisms |
| **Authentication information** (Passwords) | YES | YES | Account management | YES | Login/Register API |
| **Financial/business information** (Invoices, Expenses) | YES | YES | App functionality | YES | Core BMS features API |
| **App activity** (Screen views, Interactions) | YES | NO | Analytics | NO | Firebase Analytics dependency |
| **Device identifiers** | YES | NO | Analytics, Notifications | NO | Firebase, OneSignal |
| **Diagnostics** (Crash logs) | YES | NO | Diagnostics | NO | Firebase Crashlytics dependency |
| **Camera/media** | YES | YES | App functionality (Attachments) | NO | Camera/Storage permissions, UI upload buttons |
| **Notifications** | YES | NO | Push messaging | NO | OneSignal/Firebase messaging |

*Note: "Shared" in this context usually refers to third parties other than your backend. If your backend (api.aurivabms.in) is processing it solely for your app's operation, Google often defines this as "Collected" rather than "Shared", but confirm against standard Play Store definitions. Analytics and Crashlytics data sent to Google/Firebase may require disclosure depending on your Firebase config.*
