import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

/// Tarjeta de detalle con formato de publicación. Es el formato estándar de
/// todas las vistas de detalle (escuela, operativo, mi escuela):
/// cabecera con avatar + menú ⋯, franja destacada, acciones y datos.
class DetailPostCard extends StatelessWidget {
  const DetailPostCard({
    super.key,
    this.showAvatar = true,
    this.avatarLetter = '',
    required this.title,
    this.subtitle = '',
    this.trailing,
    this.menuEntries = const [],
    this.onMenuSelected,
    this.bannerIcon,
    this.bannerTop,
    this.bannerChips = const <dynamic>[],
    this.bannerBottom,
    this.actions = const <Widget>[],
    this.body,
  });

  /// Muestra el avatar circular con la inicial. En modo minimalista
  /// (ej. filas de alumnos) se oculta.
  final bool showAvatar;

  /// Letra del avatar circular (ej. inicial del nombre).
  final String avatarLetter;

  /// Título (ej. nombre de la escuela u operativo).
  final String title;

  /// Subtítulo (ej. `CUE • localidad` o `fecha • lugar`).
  final String subtitle;

  /// Opciones del menú ⋯ (ej. editar / eliminar). Si está vacío no hay menú.
  final List<PostMenuEntry> menuEntries;

  /// Se llama con el `value` de la opción elegida.
  final ValueChanged<String>? onMenuSelected;

  /// Widget al final de la cabecera (ej. badge de estado).
  final Widget? trailing;

  /// Ícono grande de la franja destacada. Si es null y no hay chips,
  /// la franja no se muestra (modo minimalista).
  final IconData? bannerIcon;

  /// Widget opcional en la cabecera de la franja destacada (ej. selector de asistencia).
  final Widget? bannerTop;

  /// Etiquetas sobre la franja destacada (puede ser String o Widget).
  final List<dynamic> bannerChips;

  /// Widget al pie de la franja destacada (ej. botones de acción dentro del panel).
  final Widget? bannerBottom;

  /// Fila de acciones (usar [PostActionButton]).
  final List<Widget> actions;

  /// Datos del pie (filas de dato).
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final inicial = avatarLetter.trim().isEmpty
        ? '?'
        : avatarLetter.trim()[0].toUpperCase();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera del post.
          Row(
            children: [
              if (showAvatar) ...[
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primario,
                  child: Text(inicial,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blanco)),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.subtitulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: AppTypography.texto.copyWith(
                              fontSize: 12,
                              color:
                                  AppColors.texto.withValues(alpha: 0.6))),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
              if (menuEntries.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.texto),
                  onSelected: onMenuSelected,
                  itemBuilder: (_) => [
                    for (final e in menuEntries)
                      PopupMenuItem(
                        value: e.value,
                        child: Row(
                          children: [
                            Icon(e.icon, size: 18, color: e.color),
                            const SizedBox(width: 8),
                            Text(e.label,
                                style: TextStyle(color: e.color)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (bannerIcon != null || bannerTop != null || bannerChips.isNotEmpty || bannerBottom != null) ...[
            const SizedBox(height: AppSpacing.md),
            // Franja destacada (la "foto" del post): color clarito sólido,
            // igual que los campos de los formularios.
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.campo,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bannerIcon != null)
                    Icon(bannerIcon, size: 36, color: AppColors.primario),
                  if (bannerIcon != null && (bannerTop != null || bannerChips.isNotEmpty || bannerBottom != null))
                    const SizedBox(height: AppSpacing.sm),
                  ?bannerTop,
                  if (bannerTop != null && (bannerChips.isNotEmpty || bannerBottom != null))
                    const SizedBox(height: AppSpacing.sm),
                  if (bannerChips.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final chip in bannerChips)
                          chip is Widget ? chip : PostChip(chip.toString()),
                      ],
                    ),
                  if (bannerBottom != null) ...[
                    if (bannerChips.isNotEmpty || bannerTop != null || bannerIcon != null)
                      const SizedBox(height: AppSpacing.sm),
                    bannerBottom!,
                  ],
                ],
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: actions,
            ),
          ],
          if (body != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            body!,
          ],
        ],
      ),
    );
  }
}

/// Opción del menú ⋯ de [DetailPostCard].
class PostMenuEntry {
  const PostMenuEntry({
    required this.value,
    required this.label,
    required this.icon,
    this.color = AppColors.texto,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
}

/// Etiqueta pequeña sobre la franja destacada.
class PostChip extends StatelessWidget {
  const PostChip(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primario.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primario)),
    );
  }
}

/// Botón de acción compacto de las tarjetas de detalle. Todos comparten alto
/// y bordes (mismo formato que [AppButton]).
class PostActionButton extends StatelessWidget {
  const PostActionButton({
    super.key,
    required this.icono,
    required this.texto,
    required this.colorFondo,
    required this.colorTexto,
    required this.onPressed,
  });

  final IconData icono;
  final String texto;
  final Color colorFondo;
  final Color colorTexto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        icon: Icon(icono, size: 16, color: colorTexto),
        label: Text(texto,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorFondo,
          foregroundColor: colorTexto,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.boton),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
