# Workflow

## TDD Policy

**Nível: Flexível**

- Testes são recomendados para lógica de negócio complexa (cálculos de orçamento, regras financeiras)
- Não é obrigatório escrever testes antes da implementação
- Widget tests encorajados para componentes reutilizáveis
- Testes de integração recomendados para fluxos críticos (autenticação, criação de despesas)

> Este nível pode ser ajustado para "Moderado" ou "Estrito" editando este arquivo.

## Commit Strategy

**Conventional Commits** (já configurado via semantic-release)

Formato: `<type>(<scope>): <description>`

| Tipo | Uso |
|------|-----|
| `feat` | Nova funcionalidade |
| `fix` | Correção de bug |
| `chore` | Tarefas de manutenção, dependências |
| `refactor` | Refatoração sem mudança de comportamento |
| `docs` | Documentação |
| `test` | Adição ou correção de testes |
| `style` | Formatação, lint (sem mudança de lógica) |
| `perf` | Melhoria de performance |

Exemplos:
- `feat(despesas): adiciona filtro por categoria`
- `fix(auth): corrige loop de autenticação no logout`
- `chore(deps): atualiza firebase_auth para 5.4.2`

## Code Review

**Opcional / Auto-revisão OK**

- PRs podem ser mergeados pelo próprio autor
- Code review por pares recomendado para mudanças que afetam segurança ou dados financeiros
- Usar o skill `/code-review` para revisões automatizadas antes de merge

## Verification Checkpoints

**Após cada fase concluída**

Ao finalizar uma fase de uma track:
1. Executar `flutter analyze` — zero warnings/errors
2. Executar `flutter test` — todos os testes passando
3. Verificar manualmente o fluxo afetado na plataforma principal (mobile ou web)
4. Confirmar que nenhuma funcionalidade existente foi quebrada

## Task Lifecycle

```
backlog → in_progress → review → done
```

1. **backlog** — tarefa definida, aguardando início
2. **in_progress** — desenvolvimento ativo
3. **review** — implementação concluída, aguardando verificação
4. **done** — verificação aprovada, pronto para merge

## Branch Strategy

- `main` — branch principal, sempre deployável
- Feature branches: `feat/<track-id>-<short-description>`
- Fix branches: `fix/<track-id>-<short-description>`
