# AurivaBMS Permission Declaration

The following permissions are requested in the `AndroidManifest.xml` and must be justified if questioned by Google Play review.

- **INTERNET**
  - Why required: To communicate with the production API (`api.aurivabms.in`) and Firebase.
  - Feature using it: Core app functionality.
  - Play Console consideration: Standard, no special declaration needed.
  - Verification status: VERIFIED.

- **CAMERA**
  - Why required: For capturing document images (invoices, receipts, etc.) or profile pictures directly within the app.
  - Feature using it: Expenses, Profile, Invoice attachments.
  - Play Console consideration: Requires prominent disclosure and Privacy Policy link.
  - Verification status: VERIFIED.

- **READ_EXTERNAL_STORAGE / WRITE_EXTERNAL_STORAGE**
  - Why required: To save downloaded PDFs (invoices/quotations) and to upload existing files.
  - Feature using it: Invoice generation, Quotation generation, Profile picture upload.
  - Android version behavior: Used for API <= 32 (Android 12 and below). Max SDK restricted.
  - Play Console consideration: Requires prominent disclosure and Privacy Policy link.
  - Verification status: VERIFIED.

- **READ_MEDIA_IMAGES / READ_MEDIA_VIDEO**
  - Why required: Granular permission to access media files on newer devices.
  - Feature using it: Profile picture, Expense attachments.
  - Android version behavior: Used for API >= 33 (Android 13+).
  - Play Console consideration: Standard for media pickers.
  - Verification status: VERIFIED.

- **POST_NOTIFICATIONS**
  - Why required: To alert the user regarding business updates or incoming messages.
  - Feature using it: OneSignal / Firebase Push Notifications.
  - Android version behavior: Required for API >= 33 (Android 13+).
  - Play Console consideration: Must prompt user for permission at runtime.
  - Verification status: VERIFIED.

- **VIBRATE**
  - Why required: Haptic feedback for notifications or in-app actions.
  - Feature using it: Notifications system.
  - Play Console consideration: Standard, no special declaration needed.
  - Verification status: VERIFIED.
