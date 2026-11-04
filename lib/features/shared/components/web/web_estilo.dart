import 'package:flutter/material.dart';

/// Cores e decorações compartilhadas pelos widgets da versão web.
const Color kWebRoxo = Color(0xFF6A1B9A);
const Color kWebTexto = Color(0xFF1A1F36);

BoxDecoration webCardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
const Color kIndigo = Color(0xFF1A237E);
