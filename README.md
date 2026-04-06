# Code Trials — Projeto de TCC | Ciência da Computação | UNIFAP

Jogo educacional de puzzles que ensina lógica de programação através de blocos visuais e código texto. Desenvolvido como Trabalho de Conclusão de Curso na Universidade Federal do Amapá (UNIFAP), em parceria com o projeto SERDE (Software Engineering: Research, Development, and Education).

## Sobre o Jogo

O jogador controla um personagem em níveis 2D estilo plataforma, montando algoritmos com comandos visuais (blocos arrastáveis) ou escrevendo pseudocódigo em português para resolver cada desafio.

### Comandos Disponíveis

| Comando | Descrição |
|---------|-----------|
| `andar()` | Personagem anda continuamente para frente |
| `virar()` | Altera a direção do personagem (180°) |
| `pular()` | Personagem pula na direção atual |
| `parar()` | Interrompe o movimento |
| `esperar(N)` | Pausa por N segundos |
| `repetir(N) { }` | Executa os comandos internos N vezes |
| `se(condição) { }` | Executa os comandos internos se a condição for verdadeira |

### Condições para o comando `se()`

- `no_chao` — Está no chão?
- `obstaculo_a_frente` — Há obstáculo à frente?
- `virado_direita` / `virado_esquerda` — Direção atual
- `buraco_a_frente` — Há um buraco à frente?

## Funcionalidades

- **8 níveis fixos** com dificuldade progressiva, introduzindo comandos gradualmente
- **Modo Infinito** com geração procedural de mapas em 3 dificuldades (Fácil, Médio, Difícil)
- **Duas formas de input**: blocos visuais (drag-and-drop) ou editor de código com pseudocódigo em português
- **Sincronização** entre blocos e código — alternar abas converte automaticamente
- **Autocomplete** no editor de código com sugestões de comandos e condições
- **Sistema de 3 estrelas** por nível (acessar objetivo, usar comando requerido, limite de comandos)
- **Feedback visual** durante execução (highlight do bloco atual + contador de passos)
- **Tutorial** integrado nos primeiros níveis
- **Obstáculos**: espinhos, plataformas móveis, plataformas que caem, elevações, buracos
- **Splash screen** com logos institucionais (SERDE, CCC, UNIFAP)

## Tecnologias

- **Godot Engine 4.6** (GDScript)
- **Geração procedural** de mapas com verificação de solvabilidade
- **Parser de pseudocódigo** customizado (tokenizer + parser recursivo)

## Estrutura do Projeto

```
ScratchPuzzle/
├── actors/          # Cena do jogador
├── assets/          # Sprites, fontes, sons, logos
├── commands/        # Cenas dos blocos de comando (Andar, Virar, etc.)
├── levels/          # 8 níveis fixos + baseLevel (layout principal)
├── prefabs/         # Plataformas, espinhos, caixas de diálogo
├── scenes/          # Menus, transições, tutorial, splash screen
├── scripts/         # Lógica do jogo
│   ├── baseLevel.gd        # Gerenciamento de níveis e UI
│   ├── dropArea.gd          # Área de execução (blocos + código)
│   ├── player.gd            # Controle do personagem
│   ├── maps.gd              # Configuração e objetivos de cada nível
│   ├── code_parser.gd       # Parser de pseudocódigo → comandos
│   ├── map_generator.gd     # Geração procedural de mapas
│   ├── draggable.gd         # Blocos de comando (drag-and-drop)
│   └── ...
└── shaders/         # Efeitos visuais (transições, tutorial)
```

## Como Executar

1. Instale o [Godot Engine 4.6+](https://godotengine.org/download)
2. Clone o repositório
3. Abra o projeto `ScratchPuzzle/project.godot` no Godot
4. Pressione F5 para executar

## Créditos

- **Universidade Federal do Amapá (UNIFAP)** — Curso de Ciência da Computação
- **Projeto SERDE** — Software Engineering: Research, Development, and Education
- **Assets**: Dark Dwellers UI Kit, Cyberpunk Platformer Tileset, Free Industrial Zone Tileset, Neon City Protagonist
- **Música**: Moonlight (chiptune)
