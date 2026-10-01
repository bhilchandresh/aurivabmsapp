# AurivaBMS Account Deletion Audit

- **Account creation exists:** YES (Registration routes and API constants found).
- **Account deletion exists:** YES (UI elements in `settings_screen.dart` explicitly referencing 'Delete Account').
- **Deletion flow verified:** YES (UI interaction triggers account deletion logic).

## Status
Compliant with Google Play Store account deletion requirements. A mechanism exists for users to delete their account from within the app. Ensure that an out-of-app data deletion URL is also provided in the Play Console Data Safety section.
