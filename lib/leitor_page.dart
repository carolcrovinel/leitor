import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? nomeArquivo;
  Timer? timer;
  int velocidadeMs = 500;
  bool foiParado = false;
  bool modoAuto = false;
  Color corPalavra = Colors.white;
  Map<String, dynamic> arquivosSalvos = {};

  @override
  void initState() {
    super.initState();
    carregarArquivosSalvos();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> carregarArquivosSalvos() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('arquivosSalvos');
    if (data != null) {
      arquivosSalvos = jsonDecode(data);
    }
  }

  Future<void> salvarArquivos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('arquivosSalvos', jsonEncode(arquivosSalvos));
  }

  Future<void> escolherArquivo() async {
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
      Uint8List? fileBytes = resultado.files.single.bytes;
      if (nome != null && nome.endsWith('.pdf')) {
        mostrarAlerta('Leitura de PDF no navegador ainda não é suportada.');
        return;
      }
      if (nome != null && nome.endsWith('.txt') && fileBytes != null) {
        conteudo = String.fromCharCodes(fileBytes);
      }
    } else {
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
      mostrarAlerta('Erro ao ler o arquivo.');
      return;
    }

    carregarConteudo(nome, conteudo);
  }

  void carregarConteudo(String? nome, String conteudo) {
    final novasPalavras = conteudo
        .replaceAll('\n', ' \n ')
        .split(RegExp(r'\s+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    int indiceSalvo = arquivosSalvos[nome]?['indexAtual'] ?? 0;

    setState(() {
      palavras = novasPalavras;
      indexAtual = indiceSalvo;
      nomeArquivo = nome;
    });

    arquivosSalvos[nome!] = {'conteudo': conteudo, 'indexAtual': indexAtual};
    salvarArquivos();
    iniciarLeitura();
  }

  void mostrarAlerta(String mensagem) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Aviso'),
        content: Text(mensagem),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
      ),
    );
  }

  void iniciarLeitura() {
    if (palavras.isEmpty) return;
    pararLeitura();

    timer = Timer.periodic(Duration(milliseconds: velocidadeMs), (_) async {
      if (indexAtual < palavras.length) {
        String palavraAtual = palavras[indexAtual];
        corPalavra = palavraAtual == '\n'
            ? Colors.greenAccent
            : (palavraAtual.endsWith('.') || palavraAtual.endsWith('!') || palavraAtual.endsWith('?'))
                ? Colors.blueAccent
                : Colors.white;

        setState(() {});
        int pausa = palavraAtual == '\n'
            ? velocidadeMs * 3
            : (palavraAtual.endsWith('.') || palavraAtual.endsWith('!') || palavraAtual.endsWith('?'))
                ? velocidadeMs * 2
                : velocidadeMs;

        await Future.delayed(Duration(milliseconds: pausa));
        setState(() {
          indexAtual++;
          arquivosSalvos[nomeArquivo!]['indexAtual'] = indexAtual;
        });
        salvarArquivos();

        if (indexAtual >= palavras.length && modoAuto) {
          indexAtual = 0;
          iniciarLeitura();
        }
      }
    });
    setState(() => foiParado = false);
  }

  void pararLeitura() {
    timer?.cancel();
    setState(() => foiParado = true);
  }

  void abrirMenuArquivos() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: arquivosSalvos.keys.map((nome) {
          return ListTile(
            title: Text(nome),
            onTap: () {
              carregarConteudo(nome, arquivosSalvos[nome]['conteudo']);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void voltar10() {
    setState(() {
      indexAtual = (indexAtual - 10).clamp(0, palavras.length - 1);
      arquivosSalvos[nomeArquivo!]['indexAtual'] = indexAtual;
    });
    salvarArquivos();
  }

  void pular10() {
    setState(() {
      indexAtual = (indexAtual + 10).clamp(0, palavras.length - 1);
      arquivosSalvos[nomeArquivo!]['indexAtual'] = indexAtual;
    });
    salvarArquivos();
  }

  void reiniciarLeitura() {
    setState(() {
      indexAtual = 0;
      arquivosSalvos[nomeArquivo!]['indexAtual'] = indexAtual;
    });
    salvarArquivos();
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

  void mudarVelocidade(double novaVelocidadeMs) {
    setState(() {
      velocidadeMs = novaVelocidadeMs.toInt();
    });
    if (timer != null && timer!.isActive) {
      iniciarLeitura();
    }
  }

  @override
  Widget build(BuildContext context) {
    String palavraAtual = palavras.isNotEmpty && indexAtual < palavras.length
        ? palavras[indexAtual]
        : 'Selecione ou carregue um arquivo';
    if (palavraAtual == '\n') palavraAtual = '¶';
    bool isFavorito = favoritos.contains(indexAtual);

    return GestureDetector(
      onTap: () => foiParado ? iniciarLeitura() : pararLeitura(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Leitor Palavra por Palavra'),
          actions: [
            IconButton(icon: Icon(Icons.menu_book), onPressed: abrirMenuArquivos),
            IconButton(icon: Icon(Icons.color_lens), onPressed: widget.onToggleTheme),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (nomeArquivo != null)
                Text('Arquivo: $nomeArquivo', style: TextStyle(fontSize: 16, color: Colors.tealAccent)),
              Expanded(
                child: Center(
                  child: Text(palavraAtual,
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: corPalavra),
                      textAlign: TextAlign.center),
                ),
              ),
              Wrap(
                spacing: 10,
                children: [
                  ElevatedButton(onPressed: escolherArquivo, child: Text('Escolher arquivo')),
                  ElevatedButton(onPressed: reiniciarLeitura, child: Text('Reiniciar')),
                  ElevatedButton(onPressed: voltar10, child: Text('← Voltar 10')),
                  ElevatedButton(onPressed: pular10, child: Text('Pular 10 →')),
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
