# Possibili Miglioramenti - WorkDbDart

Analisi effettuata il 2026-02-01

---

## Alta Priorita

### 1. Sicurezza Singleton Pattern
**File:** `packages/work_db/lib/src/client_work_db.dart`

Il singleton ignora i parametri dopo la prima istanziazione:
```dart
static ClientWorkDb getInstance(IWorkFileSystem workDbInternal) {
  _instance ??= ClientWorkDb._(workDbInternal);  // Parametro ignorato dopo prima chiamata
  return _instance!;
}
```
**Raccomandazione:** Documentare chiaramente il comportamento o validare che il parametro sia coerente con l'istanza esistente.

---

### 2. Custom Exceptions
**File:** `packages/work_db/lib/src/client_work_db.dart`

Uso di `Exception` generico invece di eccezioni custom:
```dart
throw Exception('Item with id "${input.id}" already exists');
```

**Raccomandazione:** Creare classi di eccezione dedicate:
```dart
class ItemAlreadyExistsException implements Exception {
  final String id;
  final String collection;
  ItemAlreadyExistsException({required this.id, required this.collection});
}

class ItemNotFoundException implements Exception {
  final String id;
  final String collection;
  ItemNotFoundException({required this.id, required this.collection});
}
```

---

### 3. Timestamp Inconsistenti tra Implementazioni

Comportamento diverso tra le tre implementazioni:
| Implementazione | Comportamento Timestamp |
|-----------------|------------------------|
| `MemoryWorkDb` | Mantiene timestamp creazione |
| `IoWorkDb` | Usa tempo modifica file |
| `WebWorkDb` | Nessun timestamp |

**Raccomandazione:** Documentare nell'interfaccia `IWorkDb` il comportamento atteso o standardizzare tra implementazioni.

---

### 4. Setup CI/CD
**Stato attuale:** Nessun workflow GitHub Actions configurato

**Raccomandazione:** Creare i seguenti workflow:
- `.github/workflows/test.yml` - Test automatici su PR
- `.github/workflows/analyze.yml` - Analisi codice statico
- `.github/workflows/publish.yml` - Pubblicazione su pub.dev

---

## Media Priorita

### 5. Rimuovere Commenti `// IA`
**File:** `packages/work_db/lib/src/factories/work_db_factory.dart`

Circa 100+ commenti `// IA` che aggiungono rumore al codice senza valore informativo.

---

### 6. Aggiornare Esempi nel README
**File:** `packages/work_db/README.md` e `example/example.dart`

Riferimenti a metodi factory deprecati (`WorkDbFactory.forIo`, `WorkDbFactory.forWeb`, etc.)

**Raccomandazione:** Aggiornare al nuovo pattern:
```dart
// Vecchio (deprecato)
final db = WorkDbFactory.forIo(dataPath: './data');

// Nuovo
final db = WorkDbFactory().create(IoWorkDbFactoryInput(dataPath: './data'));
```

---

### 7. Discrepanza Licenza
- `pubspec.yaml` dichiara licenza MIT
- File `LICENSE` contiene LGPL v3

**Raccomandazione:** Allineare la licenza dichiarata con il file LICENSE effettivo.

---

### 8. URL Repository Placeholder
**File:** `melos.yaml`

```yaml
repository: https://github.com/your-repo/work_db_dart  # Placeholder
```

**Raccomandazione:** Aggiornare con URL reale del repository GitHub.

---

### 9. Header Duplicato CHANGELOG
**File:** `packages/work_db/CHANGELOG.md`

Header duplicato nelle prime righe del file.

---

## Bassa Priorita

### 10. Operazioni Async Non Necessarie
**File:** `packages/work_db/lib/src/implementations/memory_work_db.dart`

Metodi sincroniper natura wrappati in Future inutilmente:
```dart
Future<bool> exist(String path) async {
  return _storage.containsKey(path);  // Nessuna operazione async
}
```

---

### 11. Centralizzare Gestione Path

Logica di normalizzazione path duplicata in ogni implementazione. Creare utility condivisa.

---

### 12. Migliorare Type Safety
**File:** `packages/work_db/lib/src/types.dart`

```dart
typedef JsonValue = dynamic;  // Riduce type safety
```

**Raccomandazione:** Considerare `typedef JsonValue = Object?;`

---

### 13. Test Logging
**File:** `packages/work_db_test/lib/src/test_utility.dart`

Uso di `print()` per debug output invece di logger strutturato.

---

### 14. Workflow Pubblicazione

Aggiungere script melos e workflow per release automatiche su pub.dev.

---

## Riepilogo

| Priorita | Numero Miglioramenti |
|----------|---------------------|
| Alta | 4 |
| Media | 5 |
| Bassa | 5 |
| **Totale** | **14** |

---

## Note

Il progetto e complessivamente ben strutturato con:
- Architettura pulita (Clean Architecture + Strategy Pattern)
- 202 test tutti passanti
- Documentazione completa
- Dipendenze minimali (solo `path` package)
