import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'favoritos_page.dart';

class LeitorPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  LeitorPage({required this.onToggleTheme});

  @override
  _LeitorPageState createState() => _LeitorPageState();
}

class _LeitorPageState extends State<LeitorPage> {
  List<String> palavras = [];
  Set<int> favoritos = {};
  int indexAtual = 0;
  Timer? timer;
  int velocidadeMs = 500;
  Color corPalavra = Colors.white;
  bool modoAuto = false;
  bool foiParado = false;
  String? nomeArquivo;

  @override
  void initState() {
    super.initState();
    carregarProgresso();
  }

  Future<void> carregarProgresso() async {
    final prefs = await SharedPreferences.getInstance();
    indexAtual = prefs.getInt('indexAtual') ?? 0;
    setState(() {});
  }

  Future<void> salvarProgresso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('indexAtual', indexAtual);
  }

void escolherArquivo() async {
  pararLeitura();

  FilePickerResult? resultado = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['txt', 'pdf'],
    withData: true,
  );

  if (resultado == null) return;

  String conteudo = '';
  String? nome = resultado.files.single.name;

  if (kIsWeb) {
    // 👉 WEB: usa apenas bytes
    Uint8List? fileBytes = resultado.files.single.bytes;

    if (nome != null && nome.endsWith('.pdf')) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Aviso'),
          content: Text('Leitura de PDF no navegador ainda não é suportada.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
        ),
      );
      return;
    }

    if (nome != null && nome.endsWith('.txt')) {
      if (fileBytes != null) {
        conteudo = String.fromCharCodes(fileBytes);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: arquivo vazio ou sem suporte no navegador.')),
        );
        return;
      }
    }
  } else {
    // 👉 MOBILE/DESKTOP: usa apenas path
    String? path = resultado.files.single.path;

    if (path != null && path.endsWith('.pdf')) {
      PDFDoc doc = await PDFDoc.fromPath(path);
      conteudo = await doc.text;
    } else if (path != null && path.endsWith('.txt')) {
      File file = File(path);
      conteudo = await file.readAsString();
    }
  }

  if (conteudo.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao ler o arquivo.')),
    );
    return;
  }

  List<String> novasPalavras = conteudo
      .replaceAll('\n', ' \n ')
      .split(RegExp(r'\s+'))
      .where((p) => p.trim().isNotEmpty)
      .toList();

  setState(() {
    palavras = novasPalavras;
    indexAtual = 0;
    foiParado = false;
    nomeArquivo = nome;
  });

  iniciarLeitura();
}


  void iniciarLeitura() {
    if (palavras.isEmpty) return;

    pararLeitura();

    timer = Timer.periodic(Duration(milliseconds: velocidadeMs), (timer) async {
      if (indexAtual < palavras.length) {
        String palavraAtual = palavras[indexAtual];

        if (palavraAtual == '\n') {
          corPalavra = Colors.greenAccent;
        } else if (palavraAtual.endsWith('.') ||
            palavraAtual.endsWith('!') ||
            palavraAtual.endsWith('?')) {
          corPalavra = Colors.blueAccent;
        } else {
          corPalavra = Colors.white;
        }

        setState(() {});

        int pausa = velocidadeMs;
        if (palavraAtual == '\n') {
          pausa = velocidadeMs * 3;
        } else if (palavraAtual.endsWith('.') ||
            palavraAtual.endsWith('!') ||
            palavraAtual.endsWith('?')) {
          pausa = velocidadeMs * 2;
        }

        await Future.delayed(Duration(milliseconds: pausa));

        setState(() {
          indexAtual++;
        });

        await salvarProgresso();

        if (indexAtual >= palavras.length) {
          if (modoAuto) {
            indexAtual = 0;
            iniciarLeitura();
          } else {
            timer.cancel();
            setState(() {
              foiParado = true;
            });
          }
        }
      }
    });

    setState(() {
      foiParado = false;
    });
  }

  void pararLeitura() {
    timer?.cancel();
    setState(() {
      foiParado = true;
    });
  }

  void togglePlayPause() {
    if (timer != null && timer!.isActive) {
      pararLeitura();
    } else {
      iniciarLeitura();
    }
  }

  void voltar10() {
    setState(() {
      indexAtual = (indexAtual - 10).clamp(0, palavras.length - 1);
    });
  }

  void pular10() {
    setState(() {
      indexAtual = (indexAtual + 10).clamp(0, palavras.length - 1);
    });
  }

  void reiniciarLeitura() {
    setState(() {
      indexAtual = 0;
    });
    iniciarLeitura();
  }

  void alternarModoAuto() {
    setState(() {
      modoAuto = !modoAuto;
    });
  }

  void marcarFavorito() {
    setState(() {
      if (favoritos.contains(indexAtual)) {
        favoritos.remove(indexAtual);
      } else {
        favoritos.add(indexAtual);
      }
    });
  }

  void abrirTelaFavoritos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoritosPage(
          palavras: palavras,
          favoritos: favoritos,
          onSelecionar: (indice) {
            setState(() {
              indexAtual = indice;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void mudarVelocidade(double novaVelocidadeMs) {
    setState(() {
      velocidadeMs = novaVelocidadeMs.toInt();
    });

    if (timer != null && timer!.isActive) {
      iniciarLeitura();
    }
  }

  @override
  void dispose() {
    pararLeitura();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String palavraAtual = palavras.isNotEmpty && indexAtual < palavras.length
        ? palavras[indexAtual]
        : 'Selecione um arquivo';

    if (palavraAtual == '\n') {
      palavraAtual = '¶';
    }

    String contagem = palavras.isNotEmpty
        ? '${indexAtual + 1} / ${palavras.length} palavras'
        : '';

    bool isFavorito = favoritos.contains(indexAtual);

    return GestureDetector(
      onTap: togglePlayPause,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Leitor Palavra por Palavra'),
          actions: [
            IconButton(
              icon: Icon(Icons.star),
              onPressed: abrirTelaFavoritos,
            ),
            IconButton(
              icon: Icon(Icons.color_lens),
              onPressed: widget.onToggleTheme,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (nomeArquivo != null)
                Text(
                  'Arquivo: $nomeArquivo',
                  style: TextStyle(fontSize: 16, color: Colors.tealAccent),
                ),
              Expanded(
                child: Center(
                  child: Text(
                    palavraAtual,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: corPalavra,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Text(
                contagem,
                style: TextStyle(fontSize: 16, color: Colors.grey[300]),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: escolherArquivo,
                    child: Text('Escolher arquivo'),
                  ),
                  ElevatedButton(
                    onPressed: reiniciarLeitura,
                    child: Text('Reiniciar'),
                  ),
                  ElevatedButton(
                    onPressed: voltar10,
                    child: Text('← Voltar 10'),
                  ),
                  ElevatedButton(
                    onPressed: pular10,
                    child: Text('Pular 10 →'),
                  ),
                  ElevatedButton(
                    onPressed: alternarModoAuto,
                    child: Text(modoAuto ? 'Auto: ON' : 'Auto: OFF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: modoAuto ? Colors.green : Colors.grey,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: marcarFavorito,
                    child: Icon(
                      isFavorito ? Icons.star : Icons.star_border,
                      color: isFavorito ? Colors.amber : Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text('Velocidade: ${velocidadeMs}ms/palavra'),
              Slider(
                value: velocidadeMs.toDouble(),
                min: 100,
                max: 2000,
                divisions: 38,
                label: '${velocidadeMs}ms',
                onChanged: (value) {
                  mudarVelocidade(value);
                },
              ),
              SizedBox(height: 10),
              Text(
                'DICA: Toque em qualquer lugar da tela para pausar/iniciar',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
