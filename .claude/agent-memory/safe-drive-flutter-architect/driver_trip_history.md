---
name: driver_trip_history
description: Historial de viajes del conductor implementado como índice 5 del IndexedStack en DriverHomePage; TripBloc ampliado con GetDriverTripHistoryUseCase.
type: project
---

Implementación completa del historial de viajes del conductor (marzo 2026).

**Archivos creados:**
- `lib/features/trips/domain/usecases/get_driver_trip_history_usecase.dart`
- `lib/features/driver/presentation/pages/driver_trip_history_page.dart`

**Archivos modificados:**
- `trip_datasource.dart` / `trip_datasource_impl.dart` — método `getDriverTripHistory` (filtra approved/cancelled/completed, ordena por actualEndTime desc, límite 50)
- `trip_repository.dart` / `trip_repository_impl.dart` — delegación al datasource
- `trip_event.dart` — evento `LoadDriverTripHistory(driverId)`
- `trip_state.dart` — estados `TripHistoryLoading`, `TripHistoryLoaded(trips)`, `TripHistoryError(message)`
- `trip_bloc.dart` — parámetro `getDriverTripHistoryUseCase` + handler `_onLoadDriverTripHistory`
- `injection_container.dart` — `GetDriverTripHistoryUseCase` registrado como `lazySingleton`
- `driver_home_page.dart` — nuevo parámetro en TripBloc constructor, índice 5 = `DriverTripHistoryPage`, item "Historial de Viajes" en Drawer (entre Mi Perfil y Divider)

**Decisiones de diseño:**
- No se usa un BLoC separado; se reutiliza el TripBloc con estados propios de historial (`TripHistoryLoading/Loaded/Error`) para no interferir con el flujo de viajes activos.
- `buildWhen` en `DriverTripHistoryPage` filtra solo los estados de historial.
- `initState` de `DriverTripHistoryPage` dispara `LoadDriverTripHistory` para cargar al entrar a la pestaña.
- La implementación Firestore hace 3 consultas (una por status) porque Firestore no soporta `whereIn` sobre el campo status con múltiples valores y `orderBy` en otro campo sin índice compuesto. Los resultados se ordenan en memoria.
- flutter analyze: 0 errors tras la implementación.

**Why:** Requisito de historial de viajes del conductor, integrado como tab nativo en IndexedStack para evitar navegación con go_router.
**How to apply:** Si se añaden más estados terminados a TripStatus, actualizar la lista `statuses` en `getDriverTripHistory` del datasource.
