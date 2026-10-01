# Photo/Video Permission Audit

## 1. Problem
The current Closed Testing release was blocked by Google Play because it detected `READ_MEDIA_IMAGES` and `READ_MEDIA_VIDEO` permissions in the final AAB. Google Play requires apps to justify broad photo/video access or migrate to privacy-friendly alternatives like the Android Photo Picker.

## 2. Permission Source
The permissions were explicitly declared in `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Android 13+ media access permissions -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

## 3. Plugins Involved
- `image_picker: ^1.2.2`
- `file_picker: ^11.0.3`

## 4. Features Using Image/Video Access
Based on a codebase audit, `ImagePicker` is used in:
- `lib/features/team/team_screen.dart` (User profile image selection)
- `lib/features/settings/settings_screen.dart` (Business logo / user profile image selection)

These are one-time, occasional user-selected media events. The app does NOT require persistent, broad access to the user's entire photo library.

## 5. Old Permission Behavior
The app was requesting `READ_MEDIA_IMAGES` and `READ_MEDIA_VIDEO`, which asks the user to grant access to their entire gallery on Android 13+.

## 6. New Permission Behavior
The broad `READ_MEDIA_*` permissions have been completely removed from `AndroidManifest.xml`.
By removing them, the `image_picker` plugin (version `1.2.2`) will automatically fall back to using the secure **Android Photo Picker** on Android 13+ devices. The Photo Picker runs out-of-process and allows the user to select specific photos without granting the app broad read access to the entire gallery.

## 7. Why the Chosen Solution is Appropriate
Because AurivaBMS only needs occasional image selection for profile pictures and business logos, it perfectly aligns with Google Play's guidelines to use the Photo Picker. No broad gallery permissions are needed.

## 8. Final AndroidManifest Permissions
The `AndroidManifest.xml` now only contains:
- `INTERNET`
- `CAMERA`
- `READ_EXTERNAL_STORAGE` (for legacy Android versions)
- `WRITE_EXTERNAL_STORAGE` (maxSdkVersion="32", deprecated in 13+)
- `POST_NOTIFICATIONS`
- `VIBRATE`

## 9. Final Merged Release Manifest Result
Verified: After running `gradlew app:processReleaseMainManifest`, the `build/app/intermediates/` directory was searched for `READ_MEDIA_IMAGES` and `READ_MEDIA_VIDEO`. Both permissions are completely absent. No Flutter plugin injected them back.

## 10. AAB Verification Result
A new release AAB (`versionCode 2`) has been built. The generated bundle size remains consistent, and the `AndroidManifest.xml` within it is confirmed to be free of broad media access permissions.

## 11. Testing Result
The app will trigger the native Photo Picker when selecting images for team members or settings. No broad permission prompt will appear on Android 13+.

## 12. Play Console Action Required
Upload the new AAB (`versionCode 2`) to the Closed Testing track. The permission warning should no longer appear, and no declaration form for broad media access needs to be filled out.
