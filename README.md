# 🛍️ WatchHub Admin Panel (Flutter + Firebase)

This is the **Admin Panel** for the [WatchHub eCommerce App](https://github.com/Khurram-Devs/Watch-Hub-FlutterFire) built using **Flutter** and **Firebase (Firestore)**.  
It enables super admins and managers to manage products, orders, users, brands, categories, testimonials, and more — all in real-time.

---

## 🚀 Features

✅ Beautiful Admin Dashboard with charts & stats  
✅ Role-based Manager System (`SUPER ADMIN`, `PRODUCT MANAGER`, etc.)  
✅ Product Management (CRUD with images and specs)  
✅ Category & Brand Management  
✅ Order Management (with status updates and revenue tracking)  
✅ Testimonial Moderation  
✅ Promo Code Management  
✅ Contact Message Viewer  
✅ Notifications triggered on order status change  
✅ Firestore integrated with real-time updates  
✅ Clean, responsive UI with Flutter Material 3

---

## 🧠 Admin Roles

| Role            | Description                      | Color Tag |
| --------------- | -------------------------------- | --------- |
| SUPER ADMIN     | Full access to all features      | 🔴 Red    |
| PRODUCT MANAGER | Can manage products & categories | 🟣 Purple |
| ORDER MANAGER   | Can update order statuses        | 🟢 Teal   |
| SUPPORT MANAGER | Can handle testimonials/messages | 🟠 Orange |

---

## 🔥 Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/) and create a new project.
2. Add an Android app (or iOS if needed).
3. Download `google-services.json` and place it under `android/app/`.
4. Enable these Firebase services:
   - Firestore
   - Authentication (Email/Password)
   - Firebase Storage (if image uploads are needed — currently using ImgBB)
5. Set Firestore Rules (basic example):

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

> Customize rules as per your security model.

---

## 📁 Folder Structure

```bash
lib/
├── models/            # Data models (Product, Category, AdminModel)
├── screens/           # UI screens (Dashboard, Managers, Products, etc.)
├── services/          # Firestore interaction logic
├── widgets/           # Reusable components (tables, dialogs, cards)
├── utils/             # Helpers (formatting, timeago, etc.)
└── main.dart          # Entry point
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
  cloud_firestore:
  firebase_core:
  firebase_auth:
  timeago:
  http:
  # ...and others you use like intl, provider, etc.
```

Install them:

```bash
flutter pub get
```

---

## ▶️ How to Run

```bash
git clone https://github.com/Khurram-Devs/Watch-Hub-Admin-FlutterFire
cd Watch-Hub-Admin-Panel
flutter pub get
flutter run
```

Make sure you have:

- Flutter SDK installed
- Firebase project configured

---

## 🙋 Contribution

Contributions are welcome!  
Feel free to fork the repo, create a branch, and submit a pull request.

---

## 📄 License

This project is licensed under the MIT License.
