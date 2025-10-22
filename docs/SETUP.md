# Configuración del Entorno BarberiApp

Este documento describe cómo configurar el entorno de desarrollo para BarberiApp.

## Requisitos Previos

- Flutter SDK (3.7.2 o superior)
- Cuenta en Supabase (https://supabase.com)
- Cuenta en Google Cloud Console (para OAuth)

## Configuración de Variables de Entorno

### 1. Archivo de Configuración Privada

El archivo `lib/config/env_private.dart` contiene las credenciales sensibles de la aplicación. Este archivo está excluido del control de versiones por seguridad.

#### Pasos para configurar:

1. **Crear el archivo de configuración**
   ```bash
   cp lib/config/env_private.dart.example lib/config/env_private.dart
   ```

2. **Obtener credenciales de Supabase**
   - Ve a https://app.supabase.com
   - Selecciona tu proyecto o crea uno nuevo
   - Ve a Settings > API
   - Copia:
     - Project URL → `supabaseUrl`
     - Project API keys > anon public → `supabaseAnonKey`

3. **Obtener credenciales de Google OAuth**
   - Ve a https://console.cloud.google.com
   - Crea un proyecto o selecciona uno existente
   - Habilita la API de Google Sign-In
   - Ve a "Credentials" (Credenciales)
   - Crea credenciales OAuth 2.0:
     - **Web Client ID**: Para la aplicación web
     - **iOS Client ID**: Para la aplicación iOS (opcional si no soportas iOS)

4. **Editar `lib/config/env_private.dart`**
   Reemplaza los valores de ejemplo con tus credenciales reales:
   ```dart
   class EnvPrivate {
     static const String supabaseUrl = 'https://tu-proyecto.supabase.co';
     static const String supabaseAnonKey = 'tu-anon-key-real';
     static const String webClientId = 'tu-client-id-web.apps.googleusercontent.com';
     static const String iosClientId = 'tu-client-id-ios.apps.googleusercontent.com';
   }
   ```

## Instalación y Ejecución

### 1. Instalar dependencias
```bash
flutter pub get
```

### 2. Generar archivos de localización
```bash
flutter gen-l10n
```

### 3. Ejecutar la aplicación
```bash
# Para Android/iOS
flutter run

# Para web
flutter run -d chrome

# Para Linux
flutter run -d linux

# Para Windows
flutter run -d windows

# Para macOS
flutter run -d macos
```

## Estructura de la Aplicación

BarberiApp es una aplicación multiplataforma de Flutter que conecta clientes con barberías y barberos a domicilio.

### Características principales:
- Autenticación con Google OAuth
- Gestión de barberías y barberos
- Sistema de reservas de turnos
- Localización y mapas
- Soporte para servicios a domicilio
- Internacionalización (ES/EN)

### Arquitectura:
- **Screens**: Pantallas de la aplicación
- **Services**: Servicios de backend (Supabase, autenticación, geolocalización)
- **Models**: Modelos de datos
- **Widgets**: Componentes reutilizables
- **Core**: Estilos, colores y configuración compartida

## Solución de Problemas

### Error: "Cannot find EnvPrivate"
- Asegúrate de haber creado el archivo `lib/config/env_private.dart` con las credenciales correctas.

### Error de autenticación de Google
- Verifica que los Client IDs sean correctos
- Asegúrate de haber habilitado la API de Google Sign-In en Google Cloud Console
- Configura correctamente las URLs de redirección autorizadas

### Error de conexión a Supabase
- Verifica que la URL y la clave anon sean correctas
- Asegúrate de que tu proyecto de Supabase esté activo

## Seguridad

⚠️ **IMPORTANTE**: 
- NUNCA subas el archivo `lib/config/env_private.dart` a git
- NUNCA compartas tus credenciales de Supabase o Google OAuth públicamente
- El archivo ya está incluido en `.gitignore` para protección adicional

## Más Información

Para más detalles sobre la implementación, consulta:
- `Ideas.txt`: Ideas y características planificadas
- `docs/links.md`: Enlaces a archivos clave del proyecto
