# Leitor Palavra por Palavra

Leitor Palavra por Palavra é um aplicativo Flutter que exibe cada palavra de um texto individualmente. É útil para praticar leitura com foco ou para aumentar a velocidade de leitura.

## Principais recursos

- Carregamento de arquivos **.txt** e **.pdf** locais.
- Exibição palavra por palavra com velocidade ajustável.
- Pausa ou retomada do avanço tocando na tela.
- Retroceda ou avance 10 palavras com botões dedicados.
- Modo automático para reiniciar a leitura ao chegar ao final.
- Alternância entre temas claro, escuro e sistema.

## Como usar

### Selecionar um arquivo
1. Toque em **Escolher arquivo**.
2. Selecione um arquivo `.txt` ou `.pdf` (leitura de PDF não é suportada no navegador).
3. O conteúdo é carregado e a leitura começa do ponto salvo, caso exista.

### Controlar a reprodução
- Toque em qualquer lugar para pausar ou iniciar.
- Use **Reiniciar** para voltar ao começo.
- Os botões **← Voltar 10** e **Pular 10 →** permitem navegar pelo texto.
- Ajuste o controle deslizante para alterar a velocidade (milissegundos por palavra).

### Alternar temas
- Toque no ícone de paleta, no canto superior direito, para alternar entre claro, escuro e sistema.

## Getting Started

Execute o aplicativo com os passos padrões do Flutter:

```bash
flutter pub get
flutter run
```

Para mais informações, consulte a [documentação do Flutter](https://docs.flutter.dev/).
