# RPS Control de Tiempos

Aplicación profesional de gestión y análisis de tiempos de trabajo desarrollada en Flutter para RPS Administración de Fincas.

## 🎯 Características Principales

### ⏱️ Registro de Tiempos
- **Temporizador Digital en Tiempo Real** - Reloj HH:MM:SS con diseño profesional
- **Registro Manual** - Añadir actividades pasadas con fecha y hora específica
- **Edición de Registros** - Modificar registros existentes
- **Eliminación con Confirmación** - Deslizar para eliminar con diálogo de seguridad

### 📊 Dashboard Analítico
- **Gráficas Interactivas** - Barras y sectores con colores vibrantes
- **Filtros Avanzados** - Por fecha, categoría, tipo y comunidad
- **Filtros Rápidos** - Hoy, Esta Semana, Este Mes, Último Mes, Último Trimestre
- **Análisis por Comunidad** - Top 10 comunidades con más horas dedicadas
- **Conclusiones Automáticas** - 5 insights inteligentes basados en los datos

### 📄 Exportación de Reportes
- **PDF Profesional** - Informes con gráficas, tablas y conclusiones automáticas
- **Exportar CSV** - Datos filtrados compatibles con Excel
- **Importar CSV** - Carga masiva de registros históricos

### 🏢 Gestión
- **Comunidades** - Crear, editar y eliminar comunidades
- **Categorías** - Crear, editar y eliminar categorías personalizadas
- **Categorías Predefinidas** - 17 categorías comunes protegidas

## 🛠️ Tecnologías

- **Flutter 3.35.4** - Framework de desarrollo multiplataforma
- **Dart 3.9.2** - Lenguaje de programación
- **Firebase Firestore** - Base de datos en tiempo real
- **Cloud Firestore** - Almacenamiento de datos
- **PDF Generation** - Generación de reportes PDF
- **FL Chart** - Gráficas interactivas
- **Intl** - Internacionalización y formato de fechas

## 📱 Capturas de Pantalla

### Pantalla de Inicio
Diseño sencillo y operativo con lista vertical de acciones principales.

### Temporizador
Reloj digital grande con colores dinámicos (azul en reposo, verde activo) y formulario completo.

### Dashboard Analítico
Gráficas de barras y sectores, filtros avanzados y exportación a PDF/CSV.

### Gestión de Comunidades y Categorías
Listas limpias con opciones de crear, editar y eliminar.

## 🚀 Instalación

### Requisitos Previos
- Flutter SDK 3.35.4 o superior
- Dart SDK 3.9.2 o superior
- Cuenta de Firebase configurada
- Android Studio / VS Code

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/TU_USUARIO/rps-control-tiempos.git
cd rps-control-tiempos
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar Firebase**
- Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
- Descargar `google-services.json` y colocarlo en `android/app/`
- Crear archivo `lib/firebase_options.dart` con la configuración

4. **Compilar para Web**
```bash
flutter build web --release
```

5. **Compilar para Android**
```bash
flutter build apk --release
```

## 🔥 Configuración de Firebase

### Colecciones Requeridas
- `registros_tiempo` - Registros de actividades
- `comunidades` - Lista de comunidades
- `categorias` - Categorías personalizadas (opcional)

### Reglas de Seguridad (Desarrollo)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**⚠️ IMPORTANTE**: Para producción, implementar reglas de seguridad basadas en autenticación.

## 📊 Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada y pantalla principal
├── firebase_options.dart              # Configuración de Firebase
├── models/
│   └── registro_tiempo.dart           # Modelo de datos
├── screens/
│   ├── temporizador_screen.dart       # Temporizador en tiempo real
│   ├── add_edit_registro_screen.dart  # Crear/editar registros
│   ├── registros_screen.dart          # Lista de registros
│   ├── dashboard_mejorado_screen.dart # Dashboard analítico
│   ├── import_screen.dart             # Importar CSV
│   ├── gestion_comunidades_screen.dart # Gestión de comunidades
│   └── gestion_categorias_screen.dart  # Gestión de categorías
└── services/
    └── pdf_generator.dart             # Generación de PDFs
```

## 🎨 Paleta de Colores

- **Verde** (#00C853) - Temporizador / Acciones positivas
- **Azul** (#1976D2) - Comunidades / Principal
- **Morado** (#7B1FA2) - Categorías / Dashboard
- **Naranja** (#FF6F00) - Registros / Edición
- **Rojo** (#D32F2F) - Eliminación / Alertas

## 👤 Autor

**Ramón Paz Señoráns**
- CEO y Administrador de Fincas Colegiado
- RPS Administración de Fincas
- Totana, Región de Murcia

## 📄 Licencia

Este proyecto es propiedad de RPS Administración de Fincas.

## 🤝 Soporte

Para soporte o consultas, contactar a través de RPS Administración de Fincas.

---

**Desarrollado con ❤️ para RPS Administración de Fincas**
