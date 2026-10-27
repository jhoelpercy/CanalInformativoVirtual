// Autor: Jhoel Percy Gonzales Herrera
// Funcion: pantalla de Configuracion: PIN, huella, region, tema y Acerca de.
import 'package:flutter/material.dart';
import '../models/region.dart';
import '../services/biometric_service.dart';
import '../state/app_state.dart';
import 'about_screen.dart';

/// Pantalla de Configuracion / Acerca de: opciones generales de la app.
/// Incluye el formulario para cambiar el codigo de bloqueo y la gestion
/// del desbloqueo por huella digital segun la disponibilidad del dispositivo.
class SettingsScreen extends StatefulWidget {
  final AppState appState;
  const SettingsScreen({super.key, required this.appState});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresca el estado de la huella al ingresar a Configuracion
    // por si el usuario registro o borro huellas en Ajustes del celular.
    widget.appState.actualizarEstadoBiometria();
  }

  void _abrirFormularioCodigo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _FormularioCambiarCodigo(appState: widget.appState),
    );
  }

  /// Dialogo para elegir de que region se muestran las noticias.
  void _elegirRegion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Region de las noticias'),
        children: Region.lista
            .map(
              (r) => ListTile(
                leading: Icon(
                  r.id == widget.appState.region.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: const Color(0xFF1F6FB2),
                ),
                title: Text(r.nombre),
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.appState.cambiarRegion(r);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  /// Dialogo para elegir el tema visual: claro, oscuro o el del sistema.
  void _elegirTema(BuildContext context) {
    const opciones = [
      (ThemeMode.system, 'Segun el sistema', Icons.brightness_auto),
      (ThemeMode.light, 'Claro', Icons.light_mode_outlined),
      (ThemeMode.dark, 'Oscuro', Icons.dark_mode_outlined),
    ];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Tema de la aplicacion'),
        children: opciones
            .map(
              (o) => ListTile(
                leading: Icon(o.$3),
                title: Text(o.$2),
                trailing: widget.appState.modoTema == o.$1
                    ? const Icon(Icons.check, color: Color(0xFF1F6FB2))
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  widget.appState.cambiarTema(o.$1);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  String _nombreTema(ThemeMode modo) {
    switch (modo) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Segun el sistema';
    }
  }

  void _mostrarInfoSinHuella(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.fingerprint, size: 48, color: Colors.orange),
        title: const Text('Configurar huella digital'),
        content: const Text(
          'Tu celular cuenta con lector biometrico, pero aun no tienes ninguna '
          'huella registrada en los Ajustes de tu telefono.\n\n'
          'Pasos para activarla:\n'
          '1. Abre la app de "Ajustes" o "Configuración" de tu celular.\n'
          '2. Ingresa a la seccion "Seguridad", "Pantalla de bloqueo" o "Biometria".\n'
          '3. Registra tu huella digital.\n'
          '4. Regresa a esta app y podras usarla para ingresar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _construirOpcionBiometria(AppState appState) {
    const azul = Color(0xFF1F6FB2);

    if (appState.estadoBiometria == EstadoBiometria.disponible) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SwitchListTile(
          secondary: const Icon(Icons.fingerprint, color: azul),
          title: const Text('Desbloqueo con huella digital'),
          subtitle: Text(
            appState.usarBiometria
                ? 'Activo: se solicita tu huella al abrir la aplicacion'
                : 'Inactivo: solo se usara el codigo PIN de 4 digitos',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          ),
          value: appState.usarBiometria,
          onChanged: (valor) => appState.alternarUsarBiometria(valor),
        ),
      );
    }

    if (appState.estadoBiometria == EstadoBiometria.sinRegistrar) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: const Icon(Icons.fingerprint, color: Colors.orange),
          title: const Text('Huella digital'),
          subtitle: Text(
            'Sin huella registrada en tu celular. Toca para ver ayuda.',
            style: TextStyle(fontSize: 12.5, color: Colors.orange.shade800),
          ),
          trailing: const Icon(Icons.info_outline, color: Colors.orange),
          onTap: () => _mostrarInfoSinHuella(context),
        ),
      );
    }

    // Caso: EstadoBiometria.noSoportado
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(Icons.fingerprint_outlined, color: Colors.grey.shade400),
        title: Text(
          'Huella digital',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        subtitle: Text(
          'Este dispositivo no cuenta con sensor biometrico',
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final sugerida = widget.appState.categoriaSugerida;
        final opciones = [
          ('Cambiar codigo de bloqueo', Icons.lock_outline, () => _abrirFormularioCodigo(context)),
          (
            'Region de noticias: ${widget.appState.region.nombre}',
            Icons.public,
            () => _elegirRegion(context),
          ),
          (
            'Tema: ${_nombreTema(widget.appState.modoTema)}',
            Icons.palette_outlined,
            () => _elegirTema(context),
          ),
          (
            'Categoria preferida: ${sugerida?.nombre ?? "Aun no definida"}',
            Icons.star_outline,
            () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Categoria preferida'),
                  content: Text(
                    sugerida == null
                        ? 'Todavia no hay suficiente historial. Entra al menos 2 veces a una '
                            'categoria y la app la sugerira en Inicio.'
                        : 'Es la categoria que mas consultas: ${sugerida.nombre}. '
                            'Se muestra una noticia destacada de ella en la pantalla de Inicio.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              );
            },
          ),
          ('Politica de almacenamiento offline', Icons.cloud_off_outlined, () {
            showDialog(
              context: context,
              builder: (_) => const AlertDialog(
                title: Text('Almacenamiento offline'),
                content: Text(
                  'Se guardan hasta 20 noticias por categoria, con una '
                  'vigencia de 7 dias. Los favoritos no tienen limite de '
                  'tiempo y se conservan hasta un maximo de 200.',
                ),
              ),
            );
          }),
          (
            'Acerca de la aplicacion',
            Icons.info_outline,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ];

        return Scaffold(
          appBar: AppBar(title: const Text('Configuracion')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCEBF7),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1F6FB2), width: 2),
                      ),
                      child: const Icon(Icons.newspaper, color: Color(0xFF1F6FB2), size: 34),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Canal Informativo Virtual',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Version 1.1.0',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _construirOpcionBiometria(widget.appState),
              ...opciones.map(
                (op) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(op.$2, color: Colors.grey.shade700),
                    title: Text(op.$1),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: op.$3,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Formulario de cambio de codigo, con validacion antes de guardar.
class _FormularioCambiarCodigo extends StatefulWidget {
  final AppState appState;
  const _FormularioCambiarCodigo({required this.appState});

  @override
  State<_FormularioCambiarCodigo> createState() => _FormularioCambiarCodigoState();
}

class _FormularioCambiarCodigoState extends State<_FormularioCambiarCodigo> {
  final _controladorNuevo = TextEditingController();
  final _controladorConfirmar = TextEditingController();
  String? _mensajeError;
  bool _guardando = false;

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final error = await widget.appState.cambiarCodigo(
      _controladorNuevo.text.trim(),
      _controladorConfirmar.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _mensajeError = error;
    });
    if (error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Codigo de bloqueo actualizado correctamente.')),
      );
    }
  }

  @override
  void dispose() {
    _controladorNuevo.dispose();
    _controladorConfirmar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar codigo de bloqueo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controladorNuevo,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nuevo codigo (4 digitos)'),
          ),
          TextField(
            controller: _controladorConfirmar,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmar nuevo codigo'),
          ),
          if (_mensajeError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _mensajeError!,
                style: const TextStyle(color: Colors.red, fontSize: 12.5),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
