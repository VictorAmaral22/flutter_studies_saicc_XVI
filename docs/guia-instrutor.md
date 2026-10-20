# Guia do Instrutor — SAICC XVI

Documento interno para quem vai ministrar o mini-curso.

---

## Objetivos de aprendizagem

Ao final das 2h, o participante deve ser capaz de:

1. Explicar o papel do Dart e do Flutter no desenvolvimento mobile
2. Distinguir `StatelessWidget` e `StatefulWidget`
3. Separar UI de lógica com `ChangeNotifier`
4. Aplicar um tema Material 3 a partir de uma cor semente
5. Implementar um CRUD simples de tarefas em Flutter
6. Ajustar layout básico para telas largas

---

## Como apresentar os slides

Arquivo: [`slides.md`](./slides.md) (formato [Marp](https://marp.app/)).

Opções:

```bash
# Extensão Marp no VS Code / Cursor → Export PDF ou HTML
# Ou CLI:
npx @marp-team/marp-cli docs/slides.md --pdf -o docs/slides.pdf
npx @marp-team/marp-cli docs/slides.md --html -o docs/slides.html
```

Mantenha a parte teórica **≤ 45 min**. O valor do mini-curso está no hands-on.

---

## Setup da sala / lab

Antes do evento:

- [ ] Ubuntu: **sudo** em [`scripts/linux/install-lab.sh`](../scripts/linux/install-lab.sh) (preferir `--system`)
- [ ] Windows: PowerShell **como Administrador** em [`scripts/windows/install-lab.ps1`](../scripts/windows/install-lab.ps1) (preferir `-System`)
- [ ] macOS: **sudo** em [`scripts/macos/install-lab.sh`](../scripts/macos/install-lab.sh) (preferir `--system`)
- [ ] SDK exigido pelo Flutter: **API 36** + **BuildTools 28.0.3**
- [ ] Confirmar KVM + `saicc-emulator` sobe sem travar
- [ ] Emuladores Android **ou** `flutter run -d chrome` / device físico
- [ ] Projetor com Hot Reload visível
- [ ] Link do repositório e do [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/)
- [ ] Código final clonável (`todo_app/`)

Guia do lab: [`scripts/linux/README.md`](../scripts/linux/README.md), [`scripts/windows/README.md`](../scripts/windows/README.md), [`scripts/macos/README.md`](../scripts/macos/README.md).

Comando útil no começo:

```bash
flutter doctor
flutter devices
saicc-emulator &   # AVD leve do lab
```

---

## Estratégia pedagógica

1. **Mostre o app final** nos primeiros minutos (motivação)
2. Conceitos curtos → código imediatamente depois
3. Em cada etapa do hands-on: *objetivo → código → rodar → explicar*
4. Se a turma avançar rápido, acrescente:
   - filtros (todas / pendentes / concluídas)
   - persistência com `shared_preferences`
   - animações com `AnimatedList`
5. Se a turma estiver lenta, pule polish e foque em CRUD + tema

---

## Pontos que costumam gerar dúvida

| Dúvida | Resposta curta |
|--------|----------------|
| “Por que `const`?” | Otimização de rebuild; widget imutável em compile-time |
| “Onde fica o HTML/CSS?” | Não existe; UI é árvore de Widgets em Dart |
| “`setState` não basta?” | Basta para estado local; compartilhado → notifier |
| “Preciso de Provider?” | Não neste curso; APIs nativas bastam |
| “Por que `List.unmodifiable`?” | Encapsulamento: UI não muta a lista direto |
| Hot Reload não aplica | Use Hot Restart após mudar `main` / enums / init |

---

## Troubleshooting rápido

```bash
flutter clean && flutter pub get
flutter run -d chrome          # se Android falhar
flutter config --enable-web
killall -9 dart 2>/dev/null    # processo travado (Linux)
```

Licenças Android:

```bash
flutter doctor --android-licenses
```

---

## Critérios de “sucesso” do hands-on

O aluno concluiu se o app:

- [ ] Abre com tema Material 3 customizado
- [ ] Adiciona tarefa via bottom sheet / dialog
- [ ] Marca como concluída (checkbox ou tap)
- [ ] Remove tarefa
- [ ] Mostra empty state quando a lista está vazia
- [ ] Em tela larga, conteúdo não estica infinitamente (`maxWidth`)

---

## Mensagem de encerramento sugerida

> Flutter é um framework declarativo: você descreve a UI, o framework reconstrói o que mudou.  
> Separar modelo, estado e widgets é o hábito que mais escala.  
> Continuem explorando persistência, navegação e testes — a base de hoje já é suficiente para o próximo passo.
|
