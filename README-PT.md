# PBasic m6502

Interpretador BASIC de inteiros para o microprocessador MOS 6502.

## Destaques

- Dialeto BASIC de inteiros completo projetado para o processador MOS Technology 6502
- Uso compacto de memória cabendo inteiramente em 64 KiB de espaço de endereçamento
- REPL interativo com prompt, edição de linha e relatório de erros de sintaxe
- Conjunto abrangente de comandos incluindo LET, PRINT, IF, GOTO, GOSUB, RETURN, INPUT, LIST, RUN, NEW, FREE, REM, END e EXIT
- Aritmética de inteiros com sinal de 32 bits para expressões e armazenamento de variáveis
- Funções matemáticas e utilitárias embutidas incluindo ABS e números pseudoaleatórios via RND
- Gerenciador de memória de programa em lista encadeada eficiente com inserção e exclusão dinâmica de linhas
- Suporte a execução e verificação headless através do emulador Mojave m6502

## Pré-requisitos

- **cc65** (`ca65` e `ld65`) — necessário para montar e linkar os arquivos-fonte; instale via `apt install cc65`
- **mojave** — emulador opcional necessário para executar e testar; instale a partir do [Mojave](https://github.com/carlos/mojave)

## Instalação

### Compilar a partir do código

A partir de uma cópia deste repositório:

```bash
make build
```

O binário plano resultante será gerado em `bin/pbasic.bin`.

## Uso

### REPL Interativo

Inicie o ambiente BASIC interativo no emulador Mojave:

```bash
make run
```

Ou invoque o Mojave diretamente:

```bash
mojave --machine m6502 --load-bin bin/pbasic.bin@0000
```

## Estrutura do Projeto

```
pbasic-m6502/
├── .make/                  # Scripts de build e configuração do linker
│   ├── build.sh
│   ├── pbasic.cfg
│   └── test.sh
├── bin/                    # Binários compilados
│   └── pbasic.bin
├── demos/                  # Programas BASIC de exemplo
├── specs/                  # Especificações arquiteturais e de funcionalidades
├── src/                    # Arquivos-fonte em assembly 6502
│   ├── defs.inc
│   └── main.s
├── Makefile
├── README-PT.md
└── README.md
```

## Desenvolvimento

Execute testes e verificações:

```bash
make test
```

Limpe artefatos de compilação:

```bash
make clean
```

## Licença

Este projeto está licenciado sob a licença MIT - consulte o arquivo [LICENSE](LICENSE) para obter detalhes.
