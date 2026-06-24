import 'package:flutter/material.dart';

/// Banner de encabezado reutilizado en Home (Actividad) e Historial.
/// Centraliza color y estilo para que nunca se desincronicen,
/// y evita que un texto largo agrande la caja (alto fijo + ellipsis).
class BannerHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const BannerHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  static const Color startColor = Color(0xFF0A0A0A);
  static const Color accentColor = Color(0xFFFF6B00);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 76, // alto fijo: la caja nunca crece sin importar el texto
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: startColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: accentColor, size: 32),
        ],
      ),
    );
  }
}
