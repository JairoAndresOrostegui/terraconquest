# Terra Conquest

Terra Conquest es una aplicación Flutter conectada a Firebase para administrar y jugar partidas de estrategia por turnos. El jugador inicia sesión, elige una partida disponible, crea o entra a su imperio y gestiona ciudades, recursos, tropas, héroes, eventos y rankings. La lógica sensible del juego vive en Cloud Functions para mantener validaciones y cambios de estado en el backend.

## Cómo funciona

La app arranca en `lib/main.dart`. Primero inicializa Firebase con `DefaultFirebaseOptions.currentPlatform` y luego escucha el estado de autenticación de Firebase Auth:

- Si no hay sesión, muestra `LoginScreen`.
- Si hay sesión, muestra `HomePartidasScreen`.
- Mientras Firebase resuelve la sesión, muestra una pantalla de carga.

El flujo principal del jugador es:

1. Registrarse o iniciar sesión.
2. Ver partidas con estado `futura` o `activa`.
3. Crear un imperio si la partida permite registro, o entrar al imperio existente.
4. Gestionar el imperio desde el dashboard: recursos, ciudades, ejército, héroes, eventos y ranking.

## Estructura del proyecto

```text
lib/
  main.dart
  config/
    firebase_options.dart
  models/
    modelos Dart para documentos de Firestore
  services/
    acceso a Firestore, Firebase Auth y Cloud Functions
  screens/
    login_screen.dart
    admin/
      pantallas de administración de partidas, regiones y terrenos
    game/
      pantallas del jugador: partidas, imperio, ciudades, tropas, héroes, eventos y rankings

functions/
  src/
    Cloud Functions TypeScript con la lógica transaccional del juego
  lib/
    salida compilada de TypeScript

assets/
  images/
    TerraConquestLogo.png
```

## Cliente Flutter

El cliente está separado en pantallas, servicios y modelos.

Los modelos de `lib/models` convierten documentos de Firestore a objetos Dart como `PartidaModel`, `ImperioModel`, `CiudadModel`, `HeroeModel`, `RegionModel`, `TerrenoModel` y modelos de tropas/rankings.

Los servicios de `lib/services` encapsulan el acceso a Firebase:

- `auth_service.dart`: registro, login y documento de usuario en `usuarios`.
- `partida_service.dart`: lista partidas disponibles y busca el imperio del usuario.
- `imperio_service.dart`: llama la función `crearImperio`.
- `dashboard_imperio_service.dart`: observa el imperio y sus ciudades en tiempo real.
- `ciudad_service.dart`: llama funciones para fundar ciudad, mejorar edificios y cambiar impuestos.
- `tropas_service.dart`: consulta y mueve tropas.
- `heroes_service.dart`: mercado de héroes, compra y asignación/retiro de tropas.
- `ranking_service.dart` y `eventos_service.dart`: rankings y noticias/eventos de partida.
- Servicios `admin_*`: administración de partidas, regiones, terrenos y herramientas de paso de día.

Las pantallas usan `StreamBuilder` para datos en vivo de Firestore y `FutureBuilder` para consultas puntuales. Las acciones que modifican reglas importantes del juego se envían a Cloud Functions.

## Backend Firebase

El backend usa Firebase Auth, Cloud Firestore y Cloud Functions.

Firestore guarda datos principales en colecciones como:

- `usuarios`
- `razas`
- `terrenos`
- `tropas`
- `catalogos`
- `catalogoCanjesFama`
- `partidas`

Dentro de cada documento de `partidas` se usan subcolecciones para el estado de juego:

- `imperios`
- `ciudades`
- `regiones`
- `heroes`
- `heroesMercado`
- `eventos`
- `rankingsImperios`
- `control`
- `pasosDiaLogs`

Las Cloud Functions están en `functions/src` y se exportan desde `functions/src/index.ts`. Entre las funciones principales están:

- `crearImperio`: crea el imperio inicial del usuario y su primera ciudad.
- `fundarCiudad`: crea nuevas ciudades para un imperio.
- `mejorarEdificio`: valida costos y mejora edificios.
- `cambiarImpuestosCiudad`: actualiza impuestos y recalcula efectos sociales.
- `obtenerTropasDisponibles` y `moverTropasCiudad`: consulta y movimiento de tropas.
- `comprarHeroe`, `asignarTropasHeroe`, `quitarTropasHeroe`: flujo de héroes y tropas asignadas.
- `pasarDiaPartida`: ejecuta el avance manual de día.
- `pasarDiaAutomatico`: procesa partidas programadas.
- `desbloquearPasoDia`: libera el bloqueo del paso de día si quedó tomado.
- `seedDatosIniciales`: crea datos base de prueba como razas, tropas, terrenos y una partida inicial.

La función `pasarDiaPartida` delega el trabajo a `core/procesarPasoDia.ts`, donde se recalculan producción, recursos, estados sociales, eventos, rankings y logs del día. Las funciones administrativas verifican que el usuario autenticado tenga `rol: "admin"` en `usuarios`.

## Administración

Las pantallas de administración permiten:

- Crear, editar y eliminar partidas.
- Configurar regiones por partida.
- Administrar terrenos globales.
- Ejecutar herramientas de partida como pasar día, desbloquear paso de día y crear datos iniciales.

El registro normal crea usuarios con `rol: "jugador"`. Para usar funciones administrativas, el documento del usuario en `usuarios/{uid}` debe tener `rol: "admin"`.

## Configuración

El proyecto Firebase configurado en `firebase.json` es `terra-conquest-a7026`. La configuración de FlutterFire está en `lib/config/firebase_options.dart`.

Dependencias principales del cliente:

- Flutter SDK `^3.7.2`
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `cloud_functions`
- `provider`
- `flame`
- `google_fonts`
- `flutter_svg`
- `intl`
- `image_picker`
- `firebase_storage`
- `file_picker`

Las funciones usan Node `>=20`, TypeScript, `firebase-admin` y `firebase-functions`.

## Comandos útiles

Instalar dependencias Flutter:

```bash
flutter pub get
```

Analizar el código Flutter:

```bash
flutter analyze
```

Ejecutar tests Flutter:

```bash
flutter test
```

Ejecutar la app:

```bash
flutter run
```

Instalar dependencias de Cloud Functions:

```bash
cd functions
npm install
```

Compilar Cloud Functions:

```bash
cd functions
npm run build
```

Levantar emulador de Functions:

```bash
cd functions
npm run serve
```

Desplegar Cloud Functions:

```bash
cd functions
npm run deploy
```

## Estado actual

El proyecto está en una etapa activa de desarrollo. Varias pantallas de juego ya están conectadas a Firestore y Cloud Functions, mientras que algunas opciones del menú lateral del imperio todavía muestran mensajes de "se implementará más adelante".
