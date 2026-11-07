# Campus Incident Reporting App

Flutter application for submitting and tracking campus incident reports. Firebase
Authentication manages accounts, Cloud Firestore stores user profiles and
incidents, and Firebase Storage holds optional report photos.

## Main workflows

- ALU email registration, email verification, login, and logout.
- Incident submission with category, location, description, and optional photo.
- Live report browsing with text search, category/status filters, and a details
  view showing the status history.
- Staff-only status changes, recorded with the staff member and timestamp.

The UI uses Provider for authentication and incident state. Widgets call
providers, providers coordinate asynchronous work, and services encapsulate
Firebase operations.

## Firebase setup

The Firebase project configuration is already generated for this app. Deploy the
included Firestore and Storage rules before using the app:

```shell
firebase deploy --only firestore:rules,storage
```

New accounts always receive the `student` role. To authorize a staff account,
first register and verify its ALU email, then set `role` to `staff` on that
account's `users/{uid}` document in the Firebase console. The app does not
provide a way for users to grant themselves staff access. Security rules enforce
the role for status changes and restrict incident creation to the signed-in
reporter.

## Run and validate

Run on an Android or iOS emulator or physical device:

```shell
flutter pub get
flutter run
```

Run static analysis with:

```shell
flutter analyze lib
```
