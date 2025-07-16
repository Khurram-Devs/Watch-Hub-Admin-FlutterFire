
# ⌚️ WatchHub – Premium Watch Shopping App

**WatchHub** is a modern, luxurious shopping app built using **Flutter** and **Firebase**, offering a responsive and elegant interface for browsing and purchasing premium watches from top global brands. Designed with scalability and customization in mind, it includes real-time Firestore data, a rich product catalog, user authentication, cart/wishlist logic, invoice generation, and a complete profile/order system.

---

## 🚀 Features

### ✅ Completed

#### 🔐 Authentication
- Email/Password sign up and login
- Google Sign-In
- Forgot password with email recovery
- Auth-aware header with dynamic login/profile dropdown
- Firestore user document creation on sign up (`usersProfile/{uid}`)

#### 🏠 Home & Layout
- Fully responsive (Web, Tablet, Mobile)
- `AppHeader`, `NavDrawer`, `FooterWidget` used across all screens
- Carousel banners, promotional sections
- Infinite brand logos scroller (auto-looping)
- Search bar with real-time suggestions

#### 🛍️ Product Catalog
- Firestore-based dynamic catalog (`products` & `categories`)
- Grid/List view toggles
- Sort by: Price, Rating, Newest
- Filter by Brand, Type, and Price Range
- Pagination / infinite scroll

#### 📄 Product Detail Page
- Route-based navigation (`/product/:id`) with dynamic Firestore fetch
- Multi-image gallery
- Pricing with discount badge and strikethrough original price
- Specifications, average rating, FAQs, and reviews
- Related products section
- Add to Cart & Wishlist buttons with stock awareness

#### 🛒 Cart
- Firestore-backed cart per user: `usersProfile/{uid}/cart/{productId}`
- Quantity selector with real-time Firestore sync
- Out-of-stock items automatically removed
- Cart summary panel with:
  - Subtotal
  - Tax (15%)
  - Flat shipping ($25)
- 'Proceed to Checkout' button

#### ❤️ Wishlist
- Firestore-based wishlist (`usersProfile/{uid}/wishlist`)
- Favorite icon toggle in product listings
- Uses `ProductListItem` layout for display
- Wishlist tab accessible in Profile page

#### 💳 Checkout
- Uses Firestore cart subcollection data
- Address form + saved address selector from Firestore
- Payment method selector: Cash on Delivery (Stripe placeholder)
- Promo code validation from `promoCode` collection
  - Checks for `usedTimes <= limit`
  - Discount applied in real-time
  - `usedTimes` incremented after order
- Itemized order summary: cart items, promo, subtotal, tax, shipping, total
- Order saved under `usersProfile/{uid}/orders/{orderId}`

#### ✅ Order Success Screen
- Displays order ID, summary, total, delivery & payment info
- Linked from Checkout via route `/order-success/:orderId`
- Branded, responsive UI

#### 👤 Profile Page (Modular Tabs)
- **Profile**:
  - Editable fields: name, phone, avatar URL (real-time updates)
- **Address Book**:
  - Add/Remove addresses (`usersProfile/{uid}/addresses`)
- **Wishlist**:
  - View wishlist items, remove/move-to-cart (placeholder)
- **Orders**:
  - Shows all user orders with real-time Firestore sync
  - Includes product titles, amounts, and status
  - Cancelable if pending
  - PDF invoice download

#### 🧾 PDF Invoice
- Includes buyer info, product details, pricing, shipping, total
- Syncfusion PDF generator
- Saved to Downloads folder (Web/Desktop support)

#### 🎨 Theming & Design
- WatchHub theme using:
  - Fonts: `PlayfairDisplay`, `Lato`
  - Palette: Emerald, Golden, Onyx
- Theme switcher via `ThemeProvider`
- Reusable widgets for layout & product display

---

## 🔧 Tech Stack

| Tech                   | Description                                       |
|------------------------|---------------------------------------------------|
| Flutter                | Cross-platform UI toolkit                         |
| Firebase Auth          | Email/Password + Google Sign-In                   |
| Cloud Firestore        | Products, Users, Cart, Wishlist, Orders, etc.     |
| GoRouter               | Declarative navigation with nested/tab routes     |
| Provider               | State management (lightweight)                    |
| Syncfusion PDF         | Invoice generation with customization             |
| Google Fonts           | Typography via `PlayfairDisplay`, `Lato`          |
| Flutter Native Splash  | Branded splash screen                             |

---

## 📁 Firestore Structure

```
products/
{productId} → title, price, stock, images, discountPercentage, specs, brandName

categories/
{categoryId} → name, type, iconUrl

promoCode/
{code} → discountPercentage, usedTimes, limit

usersProfile/
  {uid}/
    wishlist/ → List<DocumentReference>
    cart/{productId} → productRef, quantity, addedAt
    addresses/{addressId} → name, street, city, zip, country, phone
    orders/{orderId} → items[], total, status, createdAt, paymentMethod, shippingInfo
```

---

## 🛠️ How to Run Locally

> Requires Flutter 3.7.0+

```bash
# Clone the repository
git clone https://github.com/Khurram-Devs/Watch-Hub-FlutterFire.git
cd Watch-Hub-FlutterFire

# Install dependencies
flutter pub get

# Run
flutter run
```

---

## 🔐 Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Enable:

   * Authentication → Email/Password
   * Authentication → Google
   * Firestore Database
3. Download Firebase config:

   * Android: `google-services.json` → `android/app/`
   * iOS: `GoogleService-Info.plist` → `ios/Runner/`
4. (Optional) Set Firestore rules to allow authenticated access.

---

## 📦 Coming Soon

* 🧾 Stripe payment (test/live mode)
* 🧑‍💼 Admin dashboard (orders, product upload, coupons)
* 📲 APK release on GitHub
* 🌐 CDN-hosted images via imgbb or Cloudflare Images
* 🖼️ Zoomable product image lightbox (web/mobile)
* 🔔 Notification system for order updates (FCM)

---

## 📄 License

This project is **currently unlicensed**. You may view or contribute, but commercial use is not permitted.

---

## 🌟 Show Your Support

If you find WatchHub helpful or inspiring, give the repo a ⭐ on GitHub and share your feedback. Contributions, suggestions, or improvements are always welcome!

---

> **Note:** This README file was generated with the help of AI and may not be fully accurate. Please review and update as needed.