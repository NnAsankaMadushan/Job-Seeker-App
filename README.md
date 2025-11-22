# Job Seeker App 🚀

A complete Flutter mobile application with **Firebase backend** for connecting job seekers with job providers.

## ✨ Features

### 🔍 For Job Seekers
- Browse available jobs in real-time
- Apply for jobs with custom messages
- Track application status (Pending/Accepted/Rejected)
- Real-time chat with job providers
- Search and filter jobs
- Profile management with image upload

### 💼 For Job Providers
- Post job opportunities with complete details
- Review job applications
- Accept/reject applicants
- Real-time messaging with job seekers
- Manage all posted jobs
- Track job status

### 🎯 General Features
- Firebase Authentication (Email/Password)
- Cloud Firestore real-time database
- Firebase Storage for images
- Beautiful Material Design 3 UI
- Smooth animations
- Offline support
- Real-time updates

## 📱 Screenshots

[Add screenshots here]

## 🏗️ Architecture

```
lib/
├── models/              # Data models
├── services/            # Firebase services
│   ├── firebase_auth_service.dart
│   ├── firebase_job_service.dart
│   └── firebase_chat_service.dart
├── Screens/             # UI screens
└── main.dart
```

## 🚀 Quick Start

### 1. Clone and Install

```bash
git clone <your-repo>
cd chatting_app
flutter pub get
```

### 2. Set up Firebase

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure Firebase
flutterfire configure
```

Select your Firebase project and platforms (Android/iOS).

### 3. Enable Firebase Services

Go to [Firebase Console](https://console.firebase.google.com/):

- ✅ **Authentication** → Enable Email/Password
- ✅ **Firestore Database** → Create database

### 4. Setup Cloudinary

Follow the [Cloudinary Setup Guide](CLOUDINARY_SETUP.md) to configure image uploads.

Quick steps:
1. Create free account at [Cloudinary](https://cloudinary.com)
2. Get your Cloud Name and create an upload preset
3. Update `lib/services/cloudinary_service.dart` with your credentials

### 5. Update main.dart

Uncomment Firebase initialization in `lib/main.dart`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 6. Run the App

```bash
flutter run
```

## 📦 Dependencies

```yaml
# Firebase
firebase_core: ^3.8.1
firebase_auth: ^5.3.4
cloud_firestore: ^5.6.1

# Image Upload
cloudinary_public: ^0.21.0

# UI & Features
image_picker: ^1.0.7
image_cropper: ^8.0.2
flutter_animate: ^4.0.1
permission_handler: ^11.0.1
intl: ^0.19.0
```

## 🔥 Firebase Collections

### Users
```javascript
users/{userId}
  - name: string
  - email: string
  - phone: string
  - userType: "Job Seeker" | "Job Provider"
  - location: string
  - profileImage: string
```

### Jobs
```javascript
jobs/{jobId}
  - title: string
  - description: string
  - location: string
  - date: timestamp
  - budget: number
  - providerId: string
  - status: "available" | "in_progress" | "completed"
```

### Applications
```javascript
applications/{applicationId}
  - jobId: string
  - applicantId: string
  - message: string
  - status: "pending" | "accepted" | "rejected"
```

### Conversations
```javascript
conversations/{conversationId}/messages/{messageId}
  - senderId: string
  - content: string
  - timestamp: timestamp
```

## 🔒 Security Rules

See `FIREBASE_SETUP.md` for production-ready security rules.

## 🏃‍♂️ User Flow

### Job Seeker Flow
1. Register → Select "Job Seeker"
2. Browse available jobs
3. Apply with message
4. Chat with job provider
5. Track application status

### Job Provider Flow
1. Register → Select "Job Provider"
2. Post new job listing
3. Review applications
4. Accept/reject applicants
5. Chat with job seekers

## 🛠️ Build Configuration

- **Gradle**: 8.9
- **Android Gradle Plugin**: 8.7.3
- **Kotlin**: 2.1.0
- **Min SDK**: 21
- **Target SDK**: 34

## 📱 Build for Release

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🐛 Troubleshooting

### Firebase Not Initialized
```bash
flutterfire configure
```

### Build Errors
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
```

### Permission Issues
Check AndroidManifest.xml and Info.plist for required permissions.

## 📚 Documentation

- [Firebase Setup Guide](FIREBASE_SETUP.md) - Complete Firebase configuration
- [Cloudinary Setup Guide](CLOUDINARY_SETUP.md) - Image upload configuration
- [Quick Start Guide](QUICK_START.md) - 10-minute setup guide
- [Flutter Documentation](https://flutter.dev/docs)
- [FlutterFire Docs](https://firebase.flutter.dev/)

## 🎯 Future Enhancements

- [ ] Push notifications
- [ ] Payment integration
- [ ] Job recommendations (AI/ML)
- [ ] Rating system
- [ ] Dark mode
- [ ] Multi-language support

## 📄 License

MIT License

## 👥 Contributors

Built with ❤️ using Flutter & Firebase

---

**Need help?** Check [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed Firebase configuration.
