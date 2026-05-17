# 🚢 BattleBoats 

A high-performance, real-time multiplayer naval combat game built with Flutter and Firebase. 

BattleBoats goes beyond standard mobile games by implementing military-grade AES encryption for secure player movements, real-time cloud syncing, and deep memory optimizations to ensure a smooth, competitive 60 FPS experience.

## ✨ Key Features

* **Real-Time Multiplayer:** Engage in live, synchronous naval battles using Firebase Cloud Firestore.
* **Encrypted Gameplay:** All boat movements and coordinate attacks are secured using AES Encryption/Decryption to prevent interception or cheating.
* **Rewarded Ads System:** Integrated Google Mobile Ads SDK, allowing players to watch short video ads in exchange for in-game coins and upgrades.
* **Push Notifications:** Keeps players engaged with background alerts for incoming challenges, match updates, and turn notifications.
* **Advanced State Management:** Efficiently handles complex grid coordinates and game states across multiple active screens.

## 🚀 Performance & Architecture

This application was heavily profiled and optimized using Flutter DevTools to ensure enterprise-level performance and minimal RAM usage:

* **Background Isolate Processing:** Cryptographic functions (AES decryption for moves) are offloaded to background isolates via `compute()`, ensuring the main UI thread is never blocked.
* **Object Pooling:** `GridPoint` and `Cell` coordinate objects are pooled and cached at startup. This reduces per-frame RAM reallocation by over 75% and eliminates Garbage Collection "jank".
* **Render Pipeline Optimization:** Strategic use of `RepaintBoundary` on static UI panels and background layers prevents unnecessary widget tree rebuilds during rapid interactive gameplay.

## 🛠️ Tech Stack

* **Frontend:** Flutter & Dart
* **Backend:** Firebase (Authentication, Cloud Firestore)
* **Monetization:** Google Mobile Ads (AdMob)
* **Cryptography:** PointyCastle (AES Encryption)
* **Tooling:** Flutter DevTools (CPU, Memory, & UI Performance Profiling)

## 📱 Screenshots
## 📱 Screenshots

<table>
  <tr>
    <td align="center"><b>Sign-In</b></td>
    <td align="center"><b>Home</b></td>
    <td align="center"><b>Stats</b></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/dffbaa2f-0c52-4c66-934c-fc2e5de07a07" alt="signin" width="220"></td>
    <td><img src="https://github.com/user-attachments/assets/7debc26f-1e94-4e06-b51d-e591f67ffd39" alt="home" width="220"></td>
    <td><img src="https://github.com/user-attachments/assets/f0fe78f1-22c7-494f-bf9f-b01a3041a626" alt="stats" width="220"></td>
  </tr>
  <tr>
    <td align="center"><b>Upgrades</b></td>
    <td align="center"><b>Friends</b></td>
    <td align="center"><b>Battle</b></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/e7b40b97-89e4-4a80-9ae3-0727ee3de716" alt="upgrades" width="220"></td>
    <td><img src="https://github.com/user-attachments/assets/c603010f-9bf2-41ca-8e3d-adf8f21a39f1" alt="friends" width="220"></td>
    <td><img src="https://github.com/user-attachments/assets/ccdde11e-0df2-4bdf-9728-14640a5c8692" alt="battle" width="220"></td>
  </tr>
</table>

## ⚙️ Local Setup & Installation

To run this project locally, ensure you have the Flutter SDK installed.

1. Clone the repository:
   ```bash
   git clone [https://github.com/YaHyA-MaTeeN/BattleBoats-Mobile_Game.git](https://github.com/YaHyA-MaTeeN/BattleBoats-Mobile_Game.git)
   ```

2. Navigate to the project directory:
   ```bash
   cd flutter_application_1
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app (ensure an emulator or physical device is connected):
   ```bash
   flutter run
   ```

## 👨‍💻 Author

**Yahya Mateen** Computer Science Student @ UET Lahore 
