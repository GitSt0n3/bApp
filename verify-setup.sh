#!/bin/bash
# verify-setup.sh
# Script para verificar la configuración de BarberiApp

echo "🔍 Verificando configuración de BarberiApp..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# 1. Verificar que existe env_private.dart
echo "1. Verificando archivo de configuración..."
if [ -f "lib/config/env_private.dart" ]; then
    echo -e "${GREEN}✓${NC} lib/config/env_private.dart existe"
    
    # Verificar que no tiene valores por defecto
    if grep -q "https://example.supabase.co" lib/config/env_private.dart; then
        echo -e "${YELLOW}⚠${NC} Advertencia: env_private.dart contiene valores de ejemplo"
        echo "  Por favor, actualiza con tus credenciales reales"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✓${NC} Credenciales personalizadas detectadas"
    fi
else
    echo -e "${RED}✗${NC} lib/config/env_private.dart NO existe"
    echo "  Ejecuta: cp lib/config/env_private.dart.example lib/config/env_private.dart"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 2. Verificar que env_private.dart está en .gitignore
echo "2. Verificando seguridad (gitignore)..."
if git check-ignore -q lib/config/env_private.dart 2>/dev/null; then
    echo -e "${GREEN}✓${NC} env_private.dart está correctamente ignorado por git"
else
    echo -e "${RED}✗${NC} PELIGRO: env_private.dart NO está ignorado por git"
    echo "  Tus credenciales podrían ser expuestas"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 3. Verificar que existe el archivo example
echo "3. Verificando archivos de plantilla..."
if [ -f "lib/config/env_private.dart.example" ]; then
    echo -e "${GREEN}✓${NC} env_private.dart.example existe"
else
    echo -e "${YELLOW}⚠${NC} env_private.dart.example no encontrado"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# 4. Verificar dependencias de Flutter
echo "4. Verificando dependencias..."
if [ -f "pubspec.yaml" ]; then
    echo -e "${GREEN}✓${NC} pubspec.yaml encontrado"
    if [ -d ".dart_tool" ] || [ -f "pubspec.lock" ]; then
        echo -e "${GREEN}✓${NC} Dependencias instaladas"
    else
        echo -e "${YELLOW}⚠${NC} Dependencias no instaladas"
        echo "  Ejecuta: flutter pub get"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${RED}✗${NC} pubspec.yaml no encontrado"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# 5. Verificar documentación
echo "5. Verificando documentación..."
DOCS_FOUND=0
[ -f "docs/SETUP.md" ] && DOCS_FOUND=$((DOCS_FOUND + 1))
[ -f "docs/QUICKSTART.md" ] && DOCS_FOUND=$((DOCS_FOUND + 1))
[ -f "README.md" ] && DOCS_FOUND=$((DOCS_FOUND + 1))

if [ $DOCS_FOUND -ge 2 ]; then
    echo -e "${GREEN}✓${NC} Documentación disponible ($DOCS_FOUND archivos)"
else
    echo -e "${YELLOW}⚠${NC} Documentación incompleta"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Resumen
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Todo está correcto${NC}"
    echo "  Puedes ejecutar: flutter run"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Configuración completa con $WARNINGS advertencia(s)${NC}"
    echo "  La aplicación debería funcionar, pero revisa las advertencias"
else
    echo -e "${RED}✗ Se encontraron $ERRORS error(es) y $WARNINGS advertencia(s)${NC}"
    echo "  Por favor, corrige los errores antes de ejecutar la aplicación"
    exit 1
fi
echo ""
echo "Para más información, consulta: docs/SETUP.md"
