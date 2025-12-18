# 🚀 Guía de Despliegue en Netlify

## Opción 1: Importar desde GitHub (Recomendado - Actualización Automática)

### Paso 1: Acceder a Netlify
1. Ve a **https://app.netlify.com/**
2. Inicia sesión con tu cuenta (o crea una gratis)
   - Puedes usar GitHub, GitLab, Bitbucket o Email

### Paso 2: Crear Nuevo Sitio
1. Click en el botón **"Add new site"** (arriba a la derecha)
2. Selecciona **"Import an existing project"**

### Paso 3: Conectar GitHub
1. Click en **"Deploy with GitHub"**
2. Si es la primera vez, autoriza Netlify para acceder a GitHub
3. Netlify te pedirá permisos - acepta

### Paso 4: Seleccionar Repositorio
1. Busca y selecciona **`Mon1976/rps-control-tiempos`**
   - Si no aparece, click en "Configure the Netlify app on GitHub" para dar acceso

### Paso 5: Configuración de Build
Netlify detectará automáticamente el archivo `netlify.toml` con esta configuración:

```
Branch to deploy: main
Build command: echo 'Build already completed'
Publish directory: build/web
```

**✅ NO CAMBIES NADA - La configuración es correcta**

### Paso 6: Desplegar
1. Click en **"Deploy rps-control-tiempos"**
2. Netlify comenzará el despliegue (tardará 1-2 minutos)
3. Verás el progreso en tiempo real

### Paso 7: ¡Listo!
Una vez completado:
- Netlify te dará una URL tipo: `https://random-name-123456.netlify.app`
- La aplicación estará disponible en esa URL

---

## Opción 2: Despliegue Manual (Drag & Drop)

### Método Rápido sin GitHub

1. Ve a **https://app.netlify.com/drop**
2. Arrastra la carpeta **`build/web`** a la zona de drop
3. Netlify subirá y desplegará automáticamente
4. Te dará una URL en ~30 segundos

**Ventaja**: Súper rápido
**Desventaja**: No se actualiza automáticamente con cambios en GitHub

---

## 🎨 Personalizar el Nombre del Sitio

Una vez desplegado:

1. Ve a **Site settings**
2. Click en **"Change site name"**
3. Escribe un nombre único, por ejemplo:
   - `rps-control-tiempos`
   - `rps-tiempos`
   - `control-tiempos-rps`
4. Tu URL será: `https://TU-NOMBRE.netlify.app`

---

## 🔥 Configurar Firebase para Netlify

**MUY IMPORTANTE** - Sin esto la app no funcionará:

### Paso 1: Obtener URL de Netlify
Después del despliegue, copia tu URL de Netlify (ejemplo: `https://rps-control-tiempos.netlify.app`)

### Paso 2: Autorizar Dominio en Firebase
1. Ve a **Firebase Console**: https://console.firebase.google.com/
2. Selecciona tu proyecto: **rps-claim-manager-1f250**
3. Ve a **Authentication** → **Settings** → **Authorized domains**
4. Click en **"Add domain"**
5. Pega tu URL de Netlify (sin https://)
   - Ejemplo: `rps-control-tiempos.netlify.app`
6. Click **"Add"**

**Sin este paso, Firebase bloqueará las peticiones desde Netlify**

---

## 🔄 Actualizaciones Futuras

### Si usaste Opción 1 (GitHub):
Cada vez que hagas `git push` a GitHub, Netlify automáticamente:
1. Detecta el cambio
2. Despliega la nueva versión
3. Actualiza tu sitio en ~1-2 minutos

### Si usaste Opción 2 (Manual):
Tendrás que volver a arrastrar la carpeta `build/web` a Netlify cada vez que actualices.

---

## 🌐 Dominio Personalizado (Opcional)

Si tienes un dominio propio (ejemplo: `rps.es`):

1. Ve a **Domain settings** en Netlify
2. Click **"Add custom domain"**
3. Escribe tu dominio: `tiempos.rps.es` o `control.rps.es`
4. Netlify te dará instrucciones para configurar los DNS
5. Netlify te dará SSL/HTTPS gratis automáticamente

---

## 📊 Monitoreo

Netlify te proporciona:
- ✅ Analytics de visitas
- ✅ Logs de despliegue
- ✅ Vistas previas de cada commit
- ✅ Rollback a versiones anteriores
- ✅ SSL/HTTPS automático

---

## ❓ Problemas Comunes

### "Page not found" en rutas
**Solución**: Ya está resuelto en `netlify.toml` con redirects

### Firebase no funciona
**Solución**: Verificar que autorizaste el dominio de Netlify en Firebase

### Build muy grande
**Solución**: Normal para Flutter web (30MB), Netlify lo soporta sin problemas

---

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs en Netlify Dashboard
2. Verifica la configuración de Firebase
3. Asegúrate de que `build/web` existe y tiene contenido

---

**¡Tu aplicación estará disponible públicamente en menos de 5 minutos!** 🎉
