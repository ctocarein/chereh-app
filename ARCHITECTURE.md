# Chereh App — Architecture

## Stack
| Couche | Outil |
|---|---|
| State management | Riverpod (+ riverpod_generator) |
| Navigation | go_router (guards par rôle) |
| HTTP | Dio (+ AuthInterceptor Sanctum Bearer) |
| DB locale | Drift (SQLite, offline-first) |
| Token sécurisé | flutter_secure_storage |
| Réseau detect | connectivity_plus |
| Modèles | freezed + json_serializable |

## Structure `lib/`

```
lib/
├── core/
│   ├── api/            ← Dio client, interceptors, ApiException
│   ├── auth/           ← AuthState, AuthNotifier, AuthTokenStorage
│   ├── db/             ← AppDatabase (Drift) + tables/
│   ├── router/         ← go_router avec redirect par rôle
│   ├── sync/           ← SyncQueueService (offline mutations queue)
│   └── theme/          ← AppTheme (Material 3, vert Chereh)
│
├── features/
│   ├── auth/
│   │   ├── data/datasources/   ← AuthRemoteDatasource
│   │   └── presentation/       ← LoginScreen
│   │
│   ├── beneficiary/            ← Flux évaluation patient
│   ├── field_agent/            ← Gestion bénéficiaires, visites
│   └── ambassador/             ← Referrals, badges
│
└── shared/
    ├── widgets/        ← Composants communs
    ├── models/         ← Modèles partagés
    └── extensions/     ← Extensions Dart
```

## Flux Auth

```
App start → AuthNotifier.build()
  → token en secure storage ?
    Oui → GET /auth/me → AuthStateAuthenticated(user)
    Non → AuthStateUnauthenticated
  → go_router redirect vers /login ou home selon rôle
```

## Rôles → Routes

| Rôle API | UserRole | Route home |
|---|---|---|
| `Beneficiary` | `UserRole.beneficiary` | `/beneficiary` |
| `FieldAgent` | `UserRole.fieldAgent` | `/field-agent` |
| `Ambassador` | `UserRole.ambassador` | `/ambassador` |

## Offline First — Pattern

1. **Lecture** : Drift local en premier, sync en arrière-plan
2. **Écriture connecté** : API direct + mise à jour Drift
3. **Écriture offline** : `SyncQueueService.enqueue()` → Drift
4. **Reconnexion** : `SyncQueueService.flush()` rejoue la queue

## Code Generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

Génère :
- `*.g.dart` — Riverpod providers + JSON serialization + Drift
- `*.freezed.dart` — classes immutables

## API Base URL

Défini dans `lib/core/api/api_client.dart` → `kBaseUrl`
