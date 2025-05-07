import 'package:flutter/material.dart';

class FavoritosPage extends StatelessWidget {
  final List<String> palavras;
  final Set<int> favoritos;
  final Function(int) onSelecionar;

  FavoritosPage({
    required this.palavras,
    required this.favoritos,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    final favoritosList = favoritos.toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text('Favoritos'),
      ),
      body: ListView.builder(
        itemCount: favoritosList.length,
        itemBuilder: (context, index) {
          final favIndex = favoritosList[index];
          final palavra = palavras[favIndex];
          return ListTile(
            title: Text('$palavra'),
            subtitle: Text('Posição: ${favIndex + 1}'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () => onSelecionar(favIndex),
          );
        },
      ),
    );
  }
}
