# QuantumCacheDB

![Logo](images/logo.png)

QuantumCacheDB is a **blazing-fast**, **secure**, and **reactive** local database for Dart and Flutter apps, built to **outperform Hive, Isar, and ObjectBox**.  
It supports **hybrid data models** (key-value + document storage), **full CRUD operations**, **encryption**, **offline-first design**, and **developer-friendly APIs**.

---

## ✨ Features

- ⚡ **Ultra-Fast Reads/Writes** (Memory-mapped + In-Memory Index + WAL)
- 🧠 **Zero-Copy Reads** & **Direct Buffer Writes**
- 🔒 **AES-256 Encryption** and Crash Recovery
- 🔥 **Reactive Streams** for real-time UI updates
- 💾 **Offline-First** + Optional Cloud Sync (future)
- 🗄️ **Hybrid Data Model** (Key-Value + Collection-Document)
- 📚 **Schema-less** with Auto-Migrations
- ⚙️ **Developer Friendly API** (Firebase-like)

---

## 🛠 CRUD API

```dart
final db = QuantumCacheDB();

// C - Create / Insert
await db.set('users/user123', {'name': 'John', 'email': 'john@example.com'});

// R - Read
var user = await db.get('users/user123');

// U - Update
await db.update('users/user123', {'email': 'new.email@example.com'});

// D - Delete
await db.delete('users/user123');

// Reactive Listen
db.on('users').listen((event) {
  print('User data changed: $event');
});
```

---

# 🚀 Phase-by-Phase Implementation Path

---

## 📦 Phase 1: Ultra-Fast Core Engine (MVP)

- [ ] Basic File-Based Binary Storage
- [ ] Memory-Managed Page Cache
- [ ] Background Isolate for IO (Write/Read Serialization)
- [ ] Basic In-Memory Key Index (Hash Table)
- [ ] Minimal API: `set(key, value)`, `get(key)`
- [ ] Add **CRUD Support**:
  - [ ] `set()`
  - [ ] `get()`
  - [ ] `update()`
  - [ ] `delete()`
- [ ] Reactive `on(key)` Streams for listening to changes

---

## ⚡ Phase 2: Extreme Performance Upgrade

- [ ] **Write-Ahead Log (WAL)** for crash-safe writes
- [ ] **Memory-Mapped File (mmap)** reads
- [ ] **Zero-Copy Reads** (no deserialize cost)
- [ ] **Bloom Filters** for fast "existence" checks
- [ ] **Write Batching** (group writes before flushing)
- [ ] **Direct Buffer Writes** (avoid object creation)
- [ ] **Optimized LRU/ARC Cache** management
- [ ] **Snapshot Read Isolation** (read while writes ongoing)

---

## 🔥 Phase 3: Advanced Database Features

- [ ] **Batch Insert / Batch Read** APIs
- [ ] **Collection + Document Model**:
  - `/collection/document`
  - `/collection/document/subcollection/document`
- [ ] **Secondary Indexes** (manual, for now)
- [ ] **Transaction Support**:
  - Begin → Set/Update/Delete → Commit/Rollback
- [ ] **Compaction** (background merging of old log files)
- [ ] **Prefetching** & **Read-Ahead Optimizations**

---

## 🛡 Phase 4: Security & Crash Recovery

- [ ] **AES-256 encryption** at rest
- [ ] **PBKDF2-HMAC key derivation** (safe passwords)
- [ ] **Data Integrity Checksums** (XXHash or CRC32C)
- [ ] **Crash Recovery** from WAL replay
- [ ] **Secure Deletes** (zero-overwrite)
- [ ] **Audit Logging** (for debugging or compliance)

---

## 🧑‍💻 Phase 5: Developer Experience & Ecosystem

- [ ] **Firebase-style API** (`collection("users").doc("123").set(data)`)
- [ ] **Full Documentation** (API, Internals, Tutorials)
- [ ] **CLI Tools**:
  - Export / Import Data
  - Inspect Database
  - Repair Corrupted DB
- [ ] **Migration Support** (schema-less, but versioning support)
- [ ] **Testing Utilities** (mock DB for unit tests)
- [ ] **Cloud Sync Adapter** (optional module)

---

# 📈 Visual Timeline

| Phase | Duration | Priority |
|:------|:---------|:---------|
| Phase 1 - MVP CRUD Engine   | 1-2 weeks | 🔥 Highest |
| Phase 2 - Performance Boost | 2 weeks | 🚀 Ultra High |
| Phase 3 - Advanced Features | 2 weeks | High |
| Phase 4 - Security          | 1 week | Medium |
| Phase 5 - DX + CLI Tools    | Parallel | Medium-High |

---

# 📦 Installation (Coming Soon)

```yaml
dependencies:
  quantum_cache_db: ^1.0.0
```

```bash
flutter pub get
```

---

# 📚 Usage Example

```dart
import 'package:quantum_cache_db/quantum_cache_db.dart';

final db = QuantumCacheDB();

// Add a document
await db.set('users/user123', {'name': 'Jane', 'email': 'jane@example.com'});

// Get a document
final user = await db.get('users/user123');

// Update a document
await db.update('users/user123', {'phone': '+1234567890'});

// Delete a document
await db.delete('users/user123');

// Listen to changes
db.on('users').listen((change) {
  print('Change detected: $change');
});
```

---

# 🛡 License

MIT License - See [LICENSE](LICENSE)
