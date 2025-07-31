# Complaints Collection App

A cross-platform mobile application built using Flutter that allows users to submit complaints with metadata and optional image attachments. Designed for **offline-first usage** with seamless synchronization using PowerSync, and backed by MongoDB Atlas and AWS S3.

---

## Features

- **Offline-first data capture** with automatic sync
- **Attach images** with complaints
- **Cloud storage** for media using AWS S3
- **Real-time sync** with backend via PowerSync
- **Cross-platform support** (Android & iOS)

---

## Technology Stack

| Technology      | Purpose                                                                 |
|-----------------|-------------------------------------------------------------------------|
| **Flutter**     | UI toolkit for building cross-platform apps                             |
| **PowerSync**   | Real-time sync and offline data persistence                             |
| **MongoDB Atlas** | Cloud NoSQL database for storing complaint metadata                    |
| **AWS S3**      | Scalable storage for complaint images                                    |

---

## App Structure

```
lib/
│
├── models/           # Data models
├── screens/          # UI screens (form, submission, success, etc.)
├── services/         # API and image upload logic
├── sync/             # PowerSync config, schema, setup
└── main.dart         # App entry point
```

---

## How It Works

1. User fills out a complaint form: **name, email, phone, comment**
2. An image is optionally attached using Flutter’s `image_picker`
3. The image is uploaded to **AWS S3** and its URL is returned
4. Metadata including the image URL is saved locally using **PowerSync**
5. If online, data syncs with **MongoDB Atlas**; if offline, it syncs when the connection resumes

---

## Security

- Data is stored in **MongoDB Atlas**, protected by IP whitelisting and access controls
- Images uploaded to **AWS S3** are stored securely, optionally with signed URLs
- PowerSync ensures **data integrity** during sync operations

---

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/subbupost628008-byte/DataCollection.git
   cd DataCollection
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

4. Configure PowerSync and AWS credentials as needed in environment files or secure config.

---
