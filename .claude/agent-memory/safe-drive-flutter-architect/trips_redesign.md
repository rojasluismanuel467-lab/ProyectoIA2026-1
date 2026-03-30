---
name: Trips Module Redesign
description: Rediseño completo del módulo trips: nuevos tipos, estados, impedimentos, programación, DI y páginas empresa. flutter analyze: 0 errors.
type: project
---

El módulo trips fue rediseñado de cero con el siguiente modelo de negocio:

**Enums aprobados (trip_entity.dart)**
- `TripType`: `normal`, `relocation`, `free`
- `TripStatus`: `scheduled`, `inProgress`, `pendingApproval`, `approved`, `cancelled`, `withImpediment`, `completed`
- `ImpedimentCategory`: `flatTire`, `weather`, `accident`, `mechanical`, `other`

**Campos clave en TripEntity**
- `actualStartTime` / `actualEndTime` (reemplazan `startTime`/`endTime` eliminados)
- `scheduledDepartureTime` (campo de ordenamiento de la lista)
- `impedimentCategory`, `impedimentDescription`, `impedimentReportedAt`
- `sequenceOrder` (para mostrar el nº en la lista del conductor)

**Reglas de negocio**
- Solo puede haber un viaje `inProgress` a la vez por conductor
- Un viaje `withImpediment` bloquea el inicio del siguiente viaje
- Solo la empresa puede cancelar viajes
- `endCompanyTrip` → estado `pendingApproval` (empresa debe aprobar)
- `endFreeTrip` → estado `completed` directamente
- `resolveImpediment` → retorna a `scheduled` + elimina campos de impedimento con `FieldValue.delete()`

**Archivos creados/reescritos**
Domain:
- `trip_entity.dart` (full rewrite)
- `trip_repository.dart` (15 métodos)
- `get_driver_scheduled_trips_usecase.dart` (nuevo)
- `start_free_trip_usecase.dart` (nuevo)
- `end_free_trip_usecase.dart` (nuevo)
- `report_impediment_usecase.dart` (nuevo)
- `resolve_impediment_usecase.dart` (nuevo)
- `start_trip_usecase.dart` (StartTripParams ahora toma `tripId` no `driverId`)
- `end_trip_usecase.dart` → llama `endCompanyTrip`
- `end_trip_with_zone_check_usecase.dart` (vaciado — obsoleto)
- `request_remote_closure_usecase.dart` (vaciado — obsoleto)
- `listen_to_approval_stream_usecase.dart` (vaciado — obsoleto)

Data:
- `trip_model.dart` (full rewrite)
- `trip_datasource.dart` / `trip_datasource_impl.dart` (full rewrite)
- `trip_repository_impl.dart` (full rewrite)

Company domain/data/bloc:
- `company_repository.dart` (métodos viejos removidos, 6 nuevos)
- `create_company_trip_usecase.dart`, `approve_trip_usecase.dart`, `cancel_trip_usecase.dart`, `resolve_impediment_company_usecase.dart`, `get_company_pending_trips_usecase.dart`, `get_company_impediment_trips_usecase.dart` (todos nuevos)
- `approve_trip_closure_usecase.dart`, `reject_trip_closure_usecase.dart`, `create_trip_with_destination_usecase.dart`, `get_pending_trips_usecase.dart` (vaciados — obsoletos)
- `company_datasource_impl.dart` (full rewrite)
- `company_repository_impl.dart` (full rewrite)
- `company_event.dart`: eventos nuevos `CompanyTripApproved`, `CompanyTripCancelled`, `CompanyImpedimentResolved`, `CompanyTripCreateRequested`, `CompanyPendingTripsRequested`, `CompanyImpedimentTripsRequested`; eliminados `CompanyTripClosureApproved`, `CompanyTripClosureRejected`
- `company_bloc.dart` (14 use cases, 6 nuevos handlers)
- `company_state.dart`: añadido `CompanyImpedimentTripsLoaded`

Presentation conductor:
- `trip_bloc.dart` (8 use cases, sin closure logic)
- `trip_event.dart` / `trip_state.dart` (full rewrite)
- `trip_panel_widget.dart` (full rewrite — maneja todos los estados)
- `impediment_dialog.dart` (nuevo — RadioListTile por categoría)
- `trip_map_page.dart` (full rewrite — soporta company+free trips)
- `driver_home_page.dart` (full rewrite — `_TripsTab` con 4 subvistas, mapa en índice 4)
- `end_trip_dialog.dart` (vaciado — lógica movida a `TripPanelWidget._ConfirmEndDialog`)

Presentation empresa:
- `create_trip_page.dart` (full rewrite — TabBar 4 pasos: tipo, origen, destino, horario)
- `trip_approval_detail_page.dart` (full rewrite — usa `actualStartTime`/`actualEndTime`, botones Aprobar/Cancelar)
- `company_pending_trips_page.dart` (full rewrite — 2 pestañas: pendientes + impedimentos)
- `company_driver_detail_page.dart` (actualizado — usa `actualStartTime`/`actualEndTime`, enum TripStatus correcto)
- `trip_summary_page.dart` (actualizado — usa `actualStartTime`/`actualEndTime`)

Infraestructura:
- `injection_container.dart` (full rewrite — registra todos los use cases nuevos, elimina obsoletos)

**Why:** El diseño anterior usaba un solo tipo de viaje con lógica de cierre remoto (closureRequestedAt, isOutOfZone, zona de 100m) que fue eliminado. El nuevo modelo distingue viajes programados por empresa vs libres del conductor.

**How to apply:** Nunca referenciar `startTime`, `endTime`, `closureRequestedAt`, `isOutOfZone`, `isClosureApproved` — no existen en TripEntity. Usar `actualStartTime`/`actualEndTime`. Los estados obsoletos de TripStatus (`active`, `pending`, `onBreak`) tampoco existen.
