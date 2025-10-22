# Inicio Rápido - BarberiApp

## ⚡ Configuración Express (5 minutos)

### 1. Prerequisitos
- [ ] Flutter instalado (3.7.2+)
- [ ] Cuenta en Supabase
- [ ] Cuenta en Google Cloud Console (para OAuth)

### 2. Configurar Variables de Entorno

```bash
# 1. Crear archivo de configuración
cp lib/config/env_private.dart.example lib/config/env_private.dart

# 2. Editar con tus credenciales
# Abre lib/config/env_private.dart y reemplaza:
# - supabaseUrl: Tu URL de Supabase
# - supabaseAnonKey: Tu clave anon de Supabase
# - webClientId: Tu Client ID Web de Google
# - iosClientId: Tu Client ID iOS de Google (opcional)
```

### 3. Instalar Dependencias

```bash
flutter pub get
```

### 4. Ejecutar la Aplicación

```bash
# Android/iOS
flutter run

# Web
flutter run -d chrome

# Desktop (Linux/Windows/macOS)
flutter run -d linux
flutter run -d windows
flutter run -d macos
```

## 🔑 Obtener Credenciales

### Supabase
1. Ve a https://app.supabase.com
2. Selecciona/crea tu proyecto
3. Ve a Settings > API
4. Copia "Project URL" y "anon public key"

### Google OAuth
1. Ve a https://console.cloud.google.com
2. Crea/selecciona un proyecto
3. Habilita "Google Sign-In API"
4. Ve a Credentials > Create Credentials > OAuth 2.0 Client ID
5. Crea credenciales para:
   - Web application (obligatorio)
   - iOS (opcional, solo si soportas iOS)

## 📚 Más Información

Para configuración detallada, ver [SETUP.md](SETUP.md)

## ❓ Problemas Comunes

### Error: "Cannot find EnvPrivate"
✅ Asegúrate de haber creado `lib/config/env_private.dart`

### Error de autenticación de Google
✅ Verifica los Client IDs en Google Cloud Console
✅ Configura las URLs de redirección autorizadas

### Error de conexión a Supabase
✅ Verifica URL y clave anon en tu dashboard de Supabase
