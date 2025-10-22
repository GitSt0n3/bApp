# BarberiApp

Una aplicación Flutter multiplataforma que conecta clientes con barberías y barberos a domicilio.

## Características

- 🔐 Autenticación con Google OAuth
- 💈 Gestión de barberías y barberos
- 📅 Sistema de reservas de turnos
- 🗺️ Localización y mapas interactivos
- 🏠 Soporte para servicios a domicilio
- 🌍 Internacionalización (Español/Inglés)

## Configuración del Entorno

Antes de ejecutar la aplicación, debes configurar las variables de entorno necesarias.

**👉 [Ver Guía Completa de Configuración](docs/SETUP.md)**

### Configuración Rápida

1. Copia el archivo de ejemplo:
   ```bash
   cp lib/config/env_private.dart.example lib/config/env_private.dart
   ```

2. Edita `lib/config/env_private.dart` con tus credenciales de:
   - Supabase (URL y Anon Key)
   - Google OAuth (Client IDs)

3. Instala las dependencias:
   ```bash
   flutter pub get
   ```

4. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## Estructura del Proyecto

```
lib/
├── config/          # Configuración (credenciales)
├── core/            # Estilos, colores y componentes base
├── models/          # Modelos de datos
├── screens/         # Pantallas de la aplicación
├── services/        # Servicios (auth, backend, geolocalización)
├── widgets/         # Widgets reutilizables
└── main.dart        # Punto de entrada
```

## Tecnologías Utilizadas

- **Framework**: Flutter 3.7.2+
- **Backend**: Supabase
- **Autenticación**: Google Sign-In
- **Navegación**: GoRouter
- **Mapas**: flutter_map
- **Internacionalización**: flutter_localizations

## Documentación Adicional

- [Guía de Configuración Completa](docs/SETUP.md)
- [Enlaces a Archivos Clave](docs/links.md)
- [Ideas y Roadmap](Ideas.txt)

## Recursos de Flutter

Para ayuda con el desarrollo de Flutter:

- [Lab: Escribe tu primera app Flutter](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Ejemplos útiles de Flutter](https://docs.flutter.dev/cookbook)
- [Documentación en línea](https://docs.flutter.dev/)

## Licencia

Este es un proyecto privado. Todos los derechos reservados.
