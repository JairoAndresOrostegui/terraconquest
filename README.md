# Terra Conquest

Terra Conquest es una app Flutter conectada a Firebase para administrar y jugar partidas de estrategia por turnos. El cliente usa Firebase Auth, Cloud Firestore, Cloud Functions, Firebase Storage y Firebase Hosting.

## Ruta Principal

La app arranca en:

```text
lib/main.dart
```

Flujo actual:

```text
Firebase Auth -> HomePartidasScreen -> juego o administracion
```

Si no hay sesion, se muestra `LoginScreen`. Para desarrollo se puede activar auto-login con:

```bash
flutter run -d chrome --dart-define=DEV_AUTO_LOGIN=true
```

## Administracion

La ruta correcta para empezar a pulir el panel admin es:

```text
lib/screens/admin/admin_dashboard_screen.dart
```

Flujo desde la app:

```text
HomePartidasScreen -> menu Administracion -> AdminDashboardScreen
```

Secciones admin actuales:

- `Partidas`: funcional. Crear, editar, eliminar y administrar regiones de partidas.
- `Terrenos`: funcional. Administrar catalogo global de terrenos.
- `Regiones`: funcional. Administrar bonos regionales y terrenos permitidos por region.
- `Razas`: pendiente.
- `Tropas`: pendiente.
- `Usuarios`: pendiente.
- `Heroes`: pendiente.
- `Mapas`: pendiente. Asignacion visual y distribucion territorial.

Modelo territorial esperado:

```text
Terrenos -> Regiones -> Partidas
```

Un terreno es catalogo global y tiene bonos propios. Una region es catalogo global, tiene bonos propios y define que terrenos puede contener. Una partida define sus reglas particulares y luego debe seleccionar que regiones estaran disponibles.

Roles actuales:

- `jugador`: entra al flujo normal de partidas e imperios.
- `admin`: ve el acceso a administracion.
- `administrador`: tambien se acepta como admin por compatibilidad.

## Estructura

```text
lib/
  config/
    firebase_options.dart
  models/
    modelos de documentos Firestore
  services/
    acceso a Auth, Firestore y Functions
  screens/
    login_screen.dart
    admin/
      admin_dashboard_screen.dart
      partidas/
      terrenos/
    game/
      pantallas de partidas, imperio, ciudades, tropas, heroes, eventos y rankings

functions/
  src/
    Cloud Functions TypeScript
```

## Firebase

Proyecto activo:

```text
terraconquest-d7a39
```

Hosting:

```text
https://terraconquest-d7a39.web.app
```

Firestore usa colecciones principales como `usuarios`, `partidas`, `razas`, `terrenos`, `tropas`, `catalogos` y subcolecciones de partida como `imperios`, `ciudades`, `regiones`, `heroes`, `eventos`, `rankingsImperios`, `control` y `pasosDiaLogs`.

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build web
```

Cloud Functions:

```bash
cd functions
npm install
npm run build
firebase deploy --only functions --project terraconquest-d7a39
```

Deploy web/reglas:

```bash
flutter build web
firebase deploy --only hosting,firestore --project terraconquest-d7a39
```
